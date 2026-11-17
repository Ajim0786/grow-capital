
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawalAdminTab extends StatefulWidget {
  const WithdrawalAdminTab({super.key});

  @override
  State<WithdrawalAdminTab> createState() =>
      _WithdrawalAdminTabState();
}

class _WithdrawalAdminTabState extends State<WithdrawalAdminTab> {
  final db = FirebaseFirestore.instance;
  final searchController = TextEditingController();

  String searchText = '';
  bool processing = false;

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  final List<String> rejectReasons = [
    'Profile name and account holder name do not match.',
    'Wrong UPI ID / Bank Details.',
    'Invalid IFSC or Account Number.',
    'Payment details could not be verified.',
    'Duplicate withdrawal request.',
    'Incomplete account details.',
    'Suspicious account details.',
    'Other verification issue.',
  ];

  String money(dynamic value) {
    final n = value is num ? value.toDouble() : 0.0;
    return '₹${n.toStringAsFixed(2)}';
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> copyText(String value) async {
    if (value.isEmpty) {
      message('Nothing to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    message('Copied');
  }

  Future<String?> selectRejectReason() async {
    String selected = rejectReasons.first;
    final noteController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reject Withdrawal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select the reason. Customer will see this message.',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selected,
                      isExpanded: true,
                      items: rejectReasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(
                            reason,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selected = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Reject Reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional note (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final note = noteController.text.trim();
                    final fullReason = note.isEmpty
                        ? selected
                        : '$selected\nAdmin note: $note';
                    Navigator.pop(dialogContext, fullReason);
                  },
                  child: const Text('Submit Reject'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();
    return result;
  }

  Future<void> reviewRequest(
    String requestId,
    String decision,
  ) async {
    if (processing) return;

    String? reason;

    if (decision == 'rejected') {
      reason = await selectRejectReason();
      if (reason == null) return;
    }

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    setState(() => processing = true);

    final requestRef =
        db.collection('withdrawal_requests').doc(requestId);

    try {
      await db.runTransaction((transaction) async {
        final requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('Withdrawal request not found');
        }

        final request = requestSnapshot.data()!;
        final currentStatus =
            request['status']?.toString() ?? 'pending';

        if (decision == 'approved' || decision == 'on_hold') {
          if (currentStatus != 'pending' &&
              currentStatus != 'on_hold') {
            throw Exception('Request already reviewed');
          }

          transaction.update(requestRef, {
            'status': decision,
            'reviewedBy': admin.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });
          return;
        }

        if (decision == 'rejected') {
          if (currentStatus != 'pending' &&
              currentStatus != 'on_hold' &&
              currentStatus != 'approved') {
            throw Exception('Request cannot be rejected');
          }

          final uid = request['uid']?.toString() ?? '';
          final amount = request['amount'];

          if (uid.isEmpty || amount is! num || amount <= 0) {
            throw Exception('Invalid request information');
          }

          final walletRef = db.collection('wallets').doc(uid);
          final walletSnapshot =
              await transaction.get(walletRef);

          final alreadyRefunded =
              request['refunded'] == true;

          if (alreadyRefunded) {
            throw Exception('Refund already processed');
          }

          // Refund only requests whose amount was reserved.
          if (request['reserved'] == true) {
            if (!walletSnapshot.exists) {
              throw Exception('Customer wallet not found');
            }

            final wallet = walletSnapshot.data()!;
            final balance = wallet['balance'] is num
                ? (wallet['balance'] as num).toDouble()
                : 0.0;

            transaction.update(walletRef, {
              'balance': balance + amount.toDouble(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            final transactionRef = walletRef
                .collection('transactions')
                .doc('withdrawal_refund_$requestId');

            transaction.set(transactionRef, {
              'type': 'withdrawal_refund',
              'title': 'Withdrawal Refund',
              'amount': amount,
              'status': 'credited',
              'requestId': requestId,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          transaction.update(requestRef, {
            'status': 'rejected',
            'rejectionReason': reason,
            'rejectedBy': admin.uid,
            'rejectedAt': FieldValue.serverTimestamp(),
            'refunded': request['reserved'] == true,
            'refundAt': request['reserved'] == true
                ? FieldValue.serverTimestamp()
                : null,
          });
        }
      });

      message(decision == 'rejected'
          ? 'Request rejected. Refund processed if amount was reserved.'
          : 'Request status updated: $decision');
    } catch (e) {
      message('Action failed: $e');
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> markPaid(String requestId) async {
    final controller = TextEditingController();

    final utr = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Test Payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Test UTR / Reference',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Confirm Test Paid'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (utr == null || utr.isEmpty) return;

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    setState(() => processing = true);

    final requestRef =
        db.collection('withdrawal_requests').doc(requestId);

    try {
      await db.runTransaction((transaction) async {
        final requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('Request not found');
        }

        final request = requestSnapshot.data()!;

        if (request['status'] != 'approved') {
          throw Exception('Only approved requests can be paid');
        }

        if (request['paidBalanceDeducted'] == true) {
          throw Exception('Balance already deducted');
        }

        final uid = request['uid']?.toString() ?? '';
        final amount = request['amount'];

        if (uid.isEmpty || amount is! num || amount <= 0) {
          throw Exception('Invalid request amount or customer');
        }

        final walletRef = db.collection('wallets').doc(uid);
        final walletSnapshot =
            await transaction.get(walletRef);

        if (!walletSnapshot.exists) {
          throw Exception('Customer wallet not found');
        }

        final wallet = walletSnapshot.data()!;
        final balance = wallet['balance'] is num
            ? (wallet['balance'] as num).toDouble()
            : 0.0;

        // Legacy test request: it was not reserved earlier.
        // Deduct it once when marking this test request paid.
        if (request['reserved'] != true &&
            balance < amount.toDouble()) {
          throw Exception('Insufficient wallet balance');
        }

        if (request['reserved'] != true) {
          transaction.update(walletRef, {
            'balance': balance - amount.toDouble(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final historyRef = walletRef
            .collection('transactions')
            .doc('withdrawal_paid_$requestId');

        transaction.set(historyRef, {
          'type': 'withdrawal',
          'title': 'Test Withdrawal',
          'amount': amount,
          'status': 'paid',
          'requestId': requestId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(requestRef, {
          'status': 'paid',
          'utr': utr,
          'paidAt': FieldValue.serverTimestamp(),
          'paidBy': admin.uid,
          'paidBalanceDeducted': true,
          'reserved': false,
        });
      });

      message('Test Paid saved. Wallet balance updated.');
    } catch (e) {
      message('Payment update failed: $e');
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Widget copyRow(String label, String value) {
    final safeValue = value.isEmpty ? 'Not available' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $safeValue',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (value.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => copyText(value),
              icon: const Icon(Icons.copy, size: 18),
            ),
        ],
      ),
    );
  }

  Widget customerDetails(String uid, String methodType) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final user = userSnapshot.data!.data() ?? {};

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db
              .collection('payout_methods')
              .doc(uid)
              .collection('methods')
              .doc(methodType)
              .snapshots(),
          builder: (context, payoutSnapshot) {
            final payout = payoutSnapshot.data?.data() ?? {};

            final name =
                user['fullName']?.toString() ?? 'No name';
            final email =
                user['email']?.toString() ?? 'No email';
            final mobile =
                user['mobileNumber']?.toString() ?? 'No mobile';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text(
                  'CUSTOMER DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                copyRow('Name', name),
                copyRow('Email', email),
                copyRow('Mobile', mobile),
                copyRow('UID', uid),
                const Divider(),
                Text(
                  methodType == 'upi'
                      ? 'UPI PAYMENT DETAILS'
                      : 'BANK PAYMENT DETAILS',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                if (methodType == 'upi') ...[
                  copyRow(
                    'UPI ID',
                    payout['upiId']?.toString() ?? '',
                  ),
                ] else ...[
                  copyRow(
                    'Account Holder',
                    payout['accountHolderName']?.toString() ?? '',
                  ),
                  copyRow(
                    'Bank',
                    payout['bankName']?.toString() ?? '',
                  ),
                  copyRow(
                    'Account Number',
                    payout['accountNumber']?.toString() ?? '',
                  ),
                  copyRow(
                    'IFSC',
                    payout['ifsc']?.toString() ?? '',
                  ),
                ],
                if (payoutSnapshot.hasError)
                  const Text(
                    'Unable to load payout details.',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchText = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search name, mobile, Gmail or UID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() => searchText = '');
                },
                icon: const Icon(Icons.clear),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('withdrawal_requests').snapshots(),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.hasError) {
                return const Center(
                  child: Text('Withdrawal data unavailable.'),
                );
              }

              if (!requestSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: db.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final users = {
                    for (final doc in userSnapshot.data!.docs)
                      doc.id: doc.data()
                  };

                  final docs = requestSnapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final uid = data['uid']?.toString() ?? '';
                    final user = users[uid] ?? {};

                    final searchable = [
                      uid,
                      user['fullName'],
                      user['email'],
                      user['mobileNumber'],
                      doc.id,
                    ].join(' ').toLowerCase();

                    return searchable.contains(searchText);
                  }).toList();

                  docs.sort((a, b) {
                    final at = a.data()['createdAt'];
                    final bt = b.data()['createdAt'];

                    final aTime = at is Timestamp
                        ? at.millisecondsSinceEpoch
                        : 0;
                    final bTime = bt is Timestamp
                        ? bt.millisecondsSinceEpoch
                        : 0;

                    return bTime.compareTo(aTime);
                  });

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No withdrawal requests found.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final status =
                          data['status']?.toString() ?? 'pending';
                      final uid =
                          data['uid']?.toString() ?? '';
                      final method =
                          data['methodType']?.toString() ?? 'upi';
                      final user = users[uid] ?? {};

                      final name =
                          user['fullName']?.toString() ?? 'No name';

                      final isReserved = data['reserved'] == true;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      money(data['amount']),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: green,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(status.toUpperCase()),
                                  ),
                                ],
                              ),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Requested: ${data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate().toLocal() : 'Not available'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text('Method: ${method.toUpperCase()}'),
                              Text(
                                'Balance reserved: ${isReserved ? 'Yes' : 'No'}',
                              ),
                              customerDetails(uid, method),
                              if (data['rejectionReason'] != null) ...[
                                const Divider(),
                                const Text(
                                  'REJECTION REASON',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  data['rejectionReason'].toString(),
                                ),
                              ],
                              if (data['utr'] != null)
                                Text('UTR: ${data['utr']}'),
                              const SizedBox(height: 10),
                              if (status == 'pending' ||
                                  status == 'on_hold')
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: processing
                                          ? null
                                          : () => reviewRequest(
                                                doc.id,
                                                'approved',
                                              ),
                                      child: const Text('Approve'),
                                    ),
                                    OutlinedButton(
                                      onPressed: processing
                                          ? null
                                          : () => reviewRequest(
                                                doc.id,
                                                'on_hold',
                                              ),
                                      child: const Text('Hold'),
                                    ),
                                    TextButton(
                                      onPressed: processing
                                          ? null
                                          : () => reviewRequest(
                                                doc.id,
                                                'rejected',
                                              ),
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              if (status == 'approved')
                                ElevatedButton.icon(
                                  onPressed: processing
                                      ? null
                                      : () => markPaid(doc.id),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Mark Test Paid'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
