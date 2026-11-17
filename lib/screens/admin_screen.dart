
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  final searchController = TextEditingController();

  late TabController tabs;

  bool loading = true;
  bool allowed = false;
  String searchText = '';

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 7, vsync: this);
    verifyAdmin();
  }

  Future<void> verifyAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        loading = false;
        allowed = false;
      });
      return;
    }

    try {
      final doc = await db.collection('admins').doc(user.uid).get();

      if (!mounted) return;

      setState(() {
        allowed = doc.exists && doc.data()?['role'] == 'admin';
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        allowed = false;
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    tabs.dispose();
    super.dispose();
  }

  void notify(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String dateText(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate().toLocal();
      return '${d.day}/${d.month}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return 'Not available';
  }

  Future<void> changeStatus(
    String collection,
    String id,
    String status,
  ) async {
    try {
      await db.collection(collection).doc(id).update({
        'status': status,
      });
      notify('Status updated: $status');
    } catch (e) {
      notify('Update failed: $e');
    }
  }

  Future<void> updateReferral(String uid, String status) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    try {
      await db.collection('users').doc(uid).update({
        'referralStatus': status,
        'referralVerifiedAt': FieldValue.serverTimestamp(),
        'referralVerifiedBy': admin.uid,
      });
      notify('Referral $status');
    } catch (e) {
      notify('Referral update failed: $e');
    }
  }

  Future<void> reviewBonus(String uid, String decision) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    if (uid == admin.uid) {
      notify('Admin account cannot receive Welcome Bonus');
      return;
    }

    final bonusRef = db.collection('bonus_requests').doc(uid);
    final walletRef = db.collection('wallets').doc(uid);
    final historyRef = walletRef
        .collection('transactions')
        .doc('welcome_bonus_$uid');

    try {
      await db.runTransaction((transaction) async {
        final bonusSnapshot = await transaction.get(bonusRef);

        if (!bonusSnapshot.exists) {
          throw Exception('Bonus request not found');
        }

        final bonus = bonusSnapshot.data()!;

        if (bonus['status'] != 'pending') {
          throw Exception('Already reviewed');
        }

        if (bonus['uid'] != uid || bonus['amount'] != 50) {
          throw Exception('Invalid bonus request');
        }

        if (decision == 'rejected') {
          transaction.update(bonusRef, {'status': 'rejected'});
          return;
        }

        final walletSnapshot = await transaction.get(walletRef);
        final historySnapshot = await transaction.get(historyRef);

        if (historySnapshot.exists) {
          throw Exception('Bonus already credited');
        }

        final wallet = walletSnapshot.data() ?? {};

        final balance = wallet['balance'] is num
            ? (wallet['balance'] as num).toDouble()
            : 0.0;

        final earned = wallet['totalEarned'] is num
            ? (wallet['totalEarned'] as num).toDouble()
            : 0.0;

        transaction.set(
          walletRef,
          {
            'uid': uid,
            'balance': balance + 50,
            'totalEarned': earned + 50,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(historyRef, {
          'type': 'welcome_bonus',
          'title': 'Welcome Bonus',
          'amount': 50,
          'status': 'credited',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(bonusRef, {'status': 'approved'});
      });

      notify(decision == 'approved'
          ? '₹50 Welcome Bonus credited'
          : 'Bonus rejected');
    } catch (e) {
      notify('Bonus action failed: $e');
    }
  }

  Future<void> markPaid(String requestId) async {
    final controller = TextEditingController();

    final utr = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'UTR / Payment Reference',
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
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (utr == null || utr.isEmpty) return;

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    final ref = db.collection('withdrawal_requests').doc(requestId);

    try {
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists ||
            snapshot.data()?['status'] != 'approved') {
          throw Exception('Request is not approved');
        }

        transaction.update(ref, {
          'status': 'paid',
          'utr': utr,
          'paidAt': FieldValue.serverTimestamp(),
          'paidBy': admin.uid,
        });
      });

      notify('Payment marked as paid');
    } catch (e) {
      notify('Payment update failed: $e');
    }
  }

  Future<void> replyTicket(String id, String oldReply) async {
    final controller = TextEditingController(text: oldReply);

    final reply = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reply to Customer'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write your reply',
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
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reply == null || reply.isEmpty) return;

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    try {
      await db.collection('support_tickets').doc(id).update({
        'adminReply': reply,
        'repliedAt': FieldValue.serverTimestamp(),
        'repliedBy': admin.uid,
        'status': 'replied',
      });
      notify('Reply saved');
    } catch (e) {
      notify('Reply failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(
          child: Text(
            'Access Denied\nAdmin permission required',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GROW CAPITAL ADMIN'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people), text: 'Customers'),
            Tab(icon: Icon(Icons.wallet), text: 'Withdraw'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Premium'),
            Tab(icon: Icon(Icons.support_agent), text: 'Support'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Bonus'),
            Tab(icon: Icon(Icons.group), text: 'Referrals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          dashboardTab(),
          customersTab(),
          withdrawalsTab(),
          premiumTab(),
          supportTab(),
          bonusTab(),
          referralsTab(),
        ],
      ),
    );
  }

  // DASHBOARD
  Widget dashboardTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').snapshots(),
      builder: (context, users) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('withdrawal_requests').snapshots(),
          builder: (context, withdrawals) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('premium_memberships').snapshots(),
              builder: (context, premium) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db.collection('support_tickets').snapshots(),
                  builder: (context, support) {
                    if (users.hasError ||
                        withdrawals.hasError ||
                        premium.hasError ||
                        support.hasError) {
                      return errorView(
                        'Dashboard unavailable. Check Firestore Rules.',
                      );
                    }

                    if (!users.hasData ||
                        !withdrawals.hasData ||
                        !premium.hasData ||
                        !support.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final withdrawalDocs = withdrawals.data!.docs;

                    final pending = withdrawalDocs
                        .where((d) => d.data()['status'] == 'pending')
                        .length;

                    final approved = withdrawalDocs
                        .where((d) => d.data()['status'] == 'approved')
                        .length;

                    final paid = withdrawalDocs
                        .where((d) => d.data()['status'] == 'paid')
                        .length;

                    final activePremium = premium.data!.docs
                        .where((d) => d.data()['status'] == 'active')
                        .length;

                    final openTickets = support.data!.docs
                        .where((d) =>
                            d.data()['status'] != 'replied' &&
                            d.data()['status'] != 'closed')
                        .length;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Business Overview',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        statCard(
                          'Total Customers',
                          '${users.data!.docs.length}',
                          Icons.people,
                        ),
                        statCard(
                          'Pending Withdrawals',
                          '$pending',
                          Icons.hourglass_top,
                        ),
                        statCard(
                          'Approved - Not Paid',
                          '$approved',
                          Icons.check_circle_outline,
                        ),
                        statCard(
                          'Paid Withdrawals',
                          '$paid',
                          Icons.payments,
                        ),
                        statCard(
                          'Active Premium Customers',
                          '$activePremium',
                          Icons.workspace_premium,
                        ),
                        statCard(
                          'Open Support Tickets',
                          '$openTickets',
                          Icons.support_agent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Withdrawal target: within 24 hours of request. '
                          'Overdue pending requests are highlighted.',
                          style: TextStyle(color: Colors.deepOrange),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: accent, size: 30),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // CUSTOMER SEARCH
  Widget customersTab() {
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
              hintText: 'Search Gmail, mobile, name or UID',
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
            stream: db.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return errorView('Unable to load customers');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final value = [
                  doc.id,
                  data['email'],
                  data['fullName'],
                  data['mobileNumber'],
                  data['referralCode'],
                ].join(' ').toLowerCase();

                return value.contains(searchText);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('No customers found'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(data['fullName'] ?? 'No name'),
                      subtitle: Text(
                        '${data['email'] ?? 'No Gmail'}\n'
                        '${data['mobileNumber'] ?? 'No mobile'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showCustomerDetails(doc.id, data),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void showCustomerDetails(String uid, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                detail('UID', uid),
                detail('Name', user['fullName']),
                detail('Gmail', user['email']),
                detail('Mobile', user['mobileNumber']),
                detail('Address', user['address']),
                detail('Referral Code', user['referralCode']),
                detail('Referred By Code', user['referredByCode']),
                detail('Referred By UID', user['referredByUid']),
                detail('Referral Status', user['referralStatus']),
                detail('Registration', dateText(user['createdAt'])),
                const Divider(),
                const Text(
                  'Wallet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: db.collection('wallets').doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }

                    final wallet = snapshot.data!.data() ?? {};

                    return Column(
                      children: [
                        detail('Balance', money(wallet['balance'])),
                        detail('Total Earned', money(wallet['totalEarned'])),
                      ],
                    );
                  },
                ),
                const Divider(),
                const Text(
                  'Bank / UPI Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db
                      .collection('payout_methods')
                      .doc(uid)
                      .collection('methods')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Payout details unavailable.');
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Text('No payout method saved.');
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        final isUpi = data['methodType'] == 'upi';

                        return Card(
                          child: ListTile(
                            title: Text(isUpi ? 'UPI Details' : 'Bank Details'),
                            subtitle: Text(
                              isUpi
                                  ? 'UPI: ${data['upiId'] ?? ''}'
                                  : 'Bank: ${data['bankName'] ?? ''}\n'
                                      'Holder: ${data['accountHolderName'] ?? ''}\n'
                                      'Account: ${data['accountNumber'] ?? ''}\n'
                                      'IFSC: ${data['ifsc'] ?? ''}',
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget detail(String title, dynamic value) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: const TextStyle(color: Colors.grey),
      ),
      subtitle: SelectableText(
        value == null || value.toString().isEmpty
            ? 'Not available'
            : value.toString(),
      ),
    );
  }

  // WITHDRAWALS
  Widget withdrawalsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('withdrawal_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorView('Withdrawal data unavailable. Check Rules.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];

          final aTime = aDate is Timestamp
              ? aDate.millisecondsSinceEpoch
              : 0;
          final bTime = bDate is Timestamp
              ? bDate.millisecondsSinceEpoch
              : 0;

          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('No withdrawal requests yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final status = data['status'] ?? 'pending';
            final createdAt = data['createdAt'];

            final overdue = createdAt is Timestamp &&
                status == 'pending' &&
                DateTime.now().difference(createdAt.toDate()).inHours >= 24;

            return Card(
              color: overdue ? Colors.orange.shade50 : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            money(data['amount']),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            overdue ? 'OVER 24 HOURS' : status.toString(),
                          ),
                        ),
                      ],
                    ),
                    Text('Request ID: ${doc.id}'),
                    Text('Customer UID: ${data['uid'] ?? 'Unknown'}'),
                    Text('Method: ${data['methodType'] ?? 'Unknown'}'),
                    Text('Requested: ${dateText(createdAt)}'),
                    if (data['problem'] != null)
                      Text('Customer note: ${data['problem']}'),
                    if (data['utr'] != null)
                      Text('UTR: ${data['utr']}'),
                    const SizedBox(height: 10),
                    if (status == 'pending')
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => changeStatus(
                              'withdrawal_requests',
                              doc.id,
                              'approved',
                            ),
                            child: const Text('Approve'),
                          ),
                          OutlinedButton(
                            onPressed: () => changeStatus(
                              'withdrawal_requests',
                              doc.id,
                              'on_hold',
                            ),
                            child: const Text('Hold'),
                          ),
                          TextButton(
                            onPressed: () => changeStatus(
                              'withdrawal_requests',
                              doc.id,
                              'rejected',
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    if (status == 'approved')
                      ElevatedButton.icon(
                        onPressed: () => markPaid(doc.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Paid'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // PREMIUM
  Widget premiumTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('premium_memberships').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorView('Premium data unavailable. Check Rules.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No Premium records found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  color: Colors.orange,
                ),
                title: Text(data['email'] ?? data['uid'] ?? doc.id),
                subtitle: Text(
                  'UID: ${data['uid'] ?? doc.id}\n'
                  'Status: ${data['status'] ?? 'Unknown'}\n'
                  'Plan: ${data['plan'] ?? 'Not set'}\n'
                  'Start: ${dateText(data['startAt'])}\n'
                  'End: ${dateText(data['endAt'])}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => changeStatus(
                    'premium_memberships',
                    doc.id,
                    value,
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'active',
                      child: Text('Set Active'),
                    ),
                    PopupMenuItem(
                      value: 'expired',
                      child: Text('Set Expired'),
                    ),
                    PopupMenuItem(
                      value: 'cancelled',
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // SUPPORT
  Widget supportTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('support_tickets').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorView('Support data unavailable. Check Rules.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No customer complaints yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['subject'] ??
                          data['category'] ??
                          'Customer Issue',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Ticket ID: ${doc.id}'),
                    Text('Customer UID: ${data['uid'] ?? 'Unknown'}'),
                    Text('Category: ${data['category'] ?? 'General'}'),
                    Text('Date: ${dateText(data['createdAt'])}'),
                    const SizedBox(height: 8),
                    Text(data['message'] ?? 'No message'),
                    const Divider(),
                    Text('Status: ${data['status'] ?? 'open'}'),
                    if ((data['adminReply'] ?? '').toString().isNotEmpty)
                      Text('Admin Reply: ${data['adminReply']}'),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => replyTicket(
                          doc.id,
                          data['adminReply'] ?? '',
                        ),
                        icon: const Icon(Icons.reply),
                        label: const Text('Reply'),
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
  }

  // BONUS
  Widget bonusTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('bonus_requests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorView('Unable to load bonus requests.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No Welcome Bonus requests.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final uid = data['uid']?.toString() ?? doc.id;
            final status = data['status'] ?? 'pending';
            final isSelf =
                uid == FirebaseAuth.instance.currentUser?.uid;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '₹50 Welcome Bonus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Customer UID: $uid'),
                    Text('Date: ${dateText(data['createdAt'])}'),
                    Text('Status: $status'),
                    if (status == 'pending' && !isSelf)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => reviewBonus(
                                uid,
                                'approved',
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => reviewBonus(
                                uid,
                                'rejected',
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    if (isSelf)
                      const Text(
                        'Admin account is not eligible.',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // REFERRALS
  Widget referralsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorView('Unable to load referrals.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final referrals = snapshot.data!.docs.where((doc) {
          final value = doc.data()['referredByUid'];
          return value != null && value.toString().isNotEmpty;
        }).toList();

        final pending = referrals.where((doc) {
          final status = doc.data()['referralStatus'];
          return status != 'verified' && status != 'rejected';
        }).toList();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: summaryCard('Total', '${referrals.length}'),
                ),
                Expanded(
                  child: summaryCard('Pending', '${pending.length}'),
                ),
                Expanded(
                  child: summaryCard(
                    'Verified',
                    '${referrals.where((d) => d.data()['referralStatus'] == 'verified').length}',
                  ),
                ),
              ],
            ),
            Expanded(
              child: pending.isEmpty
                  ? const Center(child: Text('No pending referrals'))
                  : ListView.builder(
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final doc = pending[index];
                        final data = doc.data();

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['fullName'] ?? 'No name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Text('Gmail: ${data['email'] ?? ''}'),
                                Text(
                                  'Used Code: ${data['referredByCode'] ?? ''}',
                                ),
                                Text(
                                  'Referrer UID: ${data['referredByUid'] ?? ''}',
                                ),
                                Text(
                                  'Joined: ${dateText(data['createdAt'])}',
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => updateReferral(
                                          doc.id,
                                          'verified',
                                        ),
                                        child: const Text('Verify'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => updateReferral(
                                          doc.id,
                                          'rejected',
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget summaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget errorView(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
