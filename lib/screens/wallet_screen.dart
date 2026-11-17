
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  bool isSubmitting = false;
  String? requestError;

  final amountController = TextEditingController();

  String money(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);
    return '0.00';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createWelcomeBonusRequest();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ONE-TIME WELCOME BONUS REQUEST
  Future<void> createWelcomeBonusRequest() async {
    if (isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isSubmitting = true;
      requestError = null;
    });

    final ref = FirebaseFirestore.instance
        .collection('bonus_requests')
        .doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) return;

        transaction.set(ref, {
          'uid': user.uid,
          'amount': 50,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          requestError = 'Request failed: ${e.code}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          requestError = 'Request failed: $e';
        });
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // SUBMIT WITHDRAWAL REQUEST
  Future<void> submitWithdrawal({
    required String methodType,
    required double amount,
    required double balance,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (amount <= 0 || amount > balance) {
      showMessage('Enter a valid amount within your available balance.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final db = FirebaseFirestore.instance;

      // Check for an existing pending request.
      final existing = await db
          .collection('withdrawal_requests')
          .where('uid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        showMessage('You already have a pending withdrawal request.');
        return;
      }

      // Verify the saved payout method exists.
      final payoutRef = db
          .collection('payout_methods')
          .doc(user.uid)
          .collection('methods')
          .doc(methodType);

      final payout = await payoutRef.get();

      if (!payout.exists) {
        showMessage('Selected payment method is not available.');
        return;
      }

      await db.collection('withdrawal_requests').add({
        'uid': user.uid,
        'amount': amount,
        'methodType': methodType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      amountController.clear();

      if (mounted) Navigator.pop(context);
      showMessage('Withdrawal request submitted successfully.');
    } on FirebaseException catch (e) {
      showMessage('Request failed: ${e.code}. Check Firestore Rules.');
    } catch (e) {
      showMessage('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // OPEN WITHDRAWAL FORM
  Future<void> openWithdrawal(double balance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;

    try {
      final bankRef = db
          .collection('payout_methods')
          .doc(user.uid)
          .collection('methods')
          .doc('bank');

      final upiRef = db
          .collection('payout_methods')
          .doc(user.uid)
          .collection('methods')
          .doc('upi');

      final results = await Future.wait([
        bankRef.get(),
        upiRef.get(),
      ]);

      final bank = results[0];
      final upi = results[1];

      if (!bank.exists && !upi.exists) {
        showMessage(
          'Please save your Bank Account or UPI in Profile first.',
        );
        return;
      }

      String selectedMethod = bank.exists ? 'bank' : 'upi';
      amountController.clear();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final bankData = bank.data() ?? {};
              final upiData = upi.data() ?? {};

              final accountNumber =
                  bankData['accountNumber']?.toString() ?? '';

              final lastFour = accountNumber.length >= 4
                  ? accountNumber.substring(accountNumber.length - 4)
                  : accountNumber;

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 22,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Request Withdrawal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Available balance: ₹${money(balance)}'),
                      const SizedBox(height: 18),

                      const Text(
                        'Select Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      if (bank.exists)
                        RadioListTile<String>(
                          value: 'bank',
                          groupValue: selectedMethod,
                          title: const Text('Bank Account'),
                          subtitle: Text(
                            'Account ending: $lastFour',
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                selectedMethod = value;
                              });
                            }
                          },
                        ),

                      if (upi.exists)
                        RadioListTile<String>(
                          value: 'upi',
                          groupValue: selectedMethod,
                          title: const Text('UPI / PhonePe'),
                          subtitle: Text(
                            upiData['upiId']?.toString() ?? '',
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                selectedMethod = value;
                              });
                            }
                          },
                        ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Withdrawal Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Maximum available: ₹${money(balance)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Your request will be reviewed by Admin. '
                        'Payment is not automatic.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  final amount = double.tryParse(
                                    amountController.text.trim(),
                                  );

                                  if (amount == null) {
                                    showMessage('Enter a valid amount.');
                                    return;
                                  }

                                  submitWithdrawal(
                                    methodType: selectedMethod,
                                    amount: amount,
                                    balance: balance,
                                  );
                                },
                          icon: const Icon(Icons.send),
                          label: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : 'Submit Withdrawal Request',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      showMessage('Unable to load payment methods: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final db = FirebaseFirestore.instance;
    final walletRef = db.collection('wallets').doc(user.uid);
    final bonusRef = db.collection('bonus_requests').doc(user.uid);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: walletRef.snapshots(),
        builder: (context, walletSnapshot) {
          if (walletSnapshot.hasError) {
            return errorView('Unable to load wallet data. Check Rules.');
          }

          if (!walletSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final walletData = walletSnapshot.data!.data() ?? {};
          final balance = walletData['balance'] ?? 0;
          final earned = walletData['totalEarned'] ?? 0;

          final balanceNumber =
              balance is num ? balance.toDouble() : 0.0;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: bonusRef.snapshots(),
            builder: (context, bonusSnapshot) {
              if (bonusSnapshot.hasError) {
                return errorView('Unable to load Welcome Bonus status.');
              }

              if (!bonusSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bonusExists = bonusSnapshot.data!.exists;
              final bonusData = bonusSnapshot.data!.data() ?? {};
              final bonusStatus =
                  bonusData['status']?.toString() ?? 'not_requested';

              final pendingBonus =
                  bonusExists && bonusStatus == 'pending' ? 50 : 0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AVAILABLE BALANCE
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [green, Color(0xFF176B50)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AVAILABLE BALANCE',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${money(balance)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your approved rewards',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'GROW CAPITAL • INR WALLET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // WALLET SUMMARY
                  Row(
                    children: [
                      Expanded(
                        child: statCard(
                          'Pending Rewards',
                          '₹${money(pendingBonus)}',
                          Icons.hourglass_top,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: statCard(
                          'Total Earned',
                          '₹${money(earned)}',
                          Icons.emoji_events_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // WITHDRAWAL
                  const Text(
                    'Withdraw Rewards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: accent,
                            size: 34,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bank Account / PhonePe UPI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your saved payment method and '
                            'submit a withdrawal request for Admin review.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () => openWithdrawal(balanceNumber),
                              icon: const Icon(Icons.arrow_upward),
                              label: const Text('Request Withdrawal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // WITHDRAWAL REQUEST HISTORY
                  const Text(
                    'My Withdrawal Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: db
                        .collection('withdrawal_requests')
                        .where('uid', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Unable to load withdrawal requests. '
                              'Check Firestore Rules.',
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs.toList();

                      docs.sort((a, b) {
                        final at = a.data()['createdAt'];
                        final bt = b.data()['createdAt'];

                        if (at is Timestamp && bt is Timestamp) {
                          return bt.compareTo(at);
                        }
                        return 0;
                      });

                      if (docs.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(
                              child: Text('No withdrawal requests yet.'),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final status =
                              data['status']?.toString() ?? 'pending';

                          final method = data['methodType'] == 'bank'
                              ? 'Bank Account'
                              : 'UPI / PhonePe';

                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.account_balance_wallet),
                              ),
                              title: Text('₹${money(data['amount'])}'),
                              subtitle: Text(
                                '$method • ${status.toUpperCase()}',
                              ),
                              trailing: Icon(
                                status == 'paid'
                                    ? Icons.check_circle
                                    : status == 'rejected'
                                        ? Icons.cancel
                                        : Icons.hourglass_top,
                                color: status == 'paid'
                                    ? Colors.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // WELCOME BONUS
                  const Text(
                    'Welcome Bonus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: accent,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '₹50 Welcome Bonus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bonusMessage(bonusStatus, bonusExists),
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          statusBadge(bonusStatus, bonusExists),
                          if (isSubmitting) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (requestError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      requestError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    TextButton.icon(
                      onPressed:
                          isSubmitting ? null : createWelcomeBonusRequest,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry request'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // TRANSACTION HISTORY
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: walletRef
                        .collection('transactions')
                        .orderBy('createdAt', descending: true)
                        .limit(30)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Transaction history is not available.',
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final transactions = snapshot.data!.docs;

                      if (transactions.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No transactions yet'),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: transactions.map((doc) {
                          final item = doc.data();

                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE3F3EB),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: accent,
                                ),
                              ),
                              title: Text(
                                item['title']?.toString() ?? 'Reward',
                              ),
                              subtitle: Text(
                                item['status']?.toString().toUpperCase() ??
                                    'PENDING',
                              ),
                              trailing: Text(
                                '₹${money(item['amount'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: green,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String bonusMessage(String status, bool exists) {
    if (!exists) {
      return 'Your ₹50 Welcome Bonus request has not been submitted yet.';
    }

    switch (status) {
      case 'pending':
        return 'Your ₹50 Welcome Bonus request has been submitted. '
            'It will be added to your available balance only after Admin approval.';
      case 'approved':
        return 'Your Welcome Bonus has been approved. '
            'Please check your available balance.';
      case 'rejected':
        return 'Your Welcome Bonus request was rejected. '
            'Please contact customer support if you need help.';
      default:
        return 'Welcome Bonus status: $status';
    }
  }

  Widget statusBadge(String status, bool exists) {
    String label;
    Color color;
    IconData icon;

    if (!exists) {
      label = 'Request not submitted';
      color = Colors.blue;
      icon = Icons.hourglass_empty;
    } else if (status == 'pending') {
      label = 'Pending Admin Approval';
      color = Colors.orange;
      icon = Icons.pending_actions;
    } else if (status == 'approved') {
      label = 'Bonus Approved';
      color = Colors.green;
      icon = Icons.verified;
    } else if (status == 'rejected') {
      label = 'Request Rejected';
      color = Colors.red;
      icon = Icons.cancel_outlined;
    } else {
      label = status.toUpperCase();
      color = Colors.blueGrey;
      icon = Icons.info_outline;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 25),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
