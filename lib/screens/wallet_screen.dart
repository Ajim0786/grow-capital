
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  String money(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first'),
        ),
      );
    }

    final walletRef = FirebaseFirestore.instance
        .collection('wallets')
        .doc(user.uid);

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
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load wallet data. '
                  'Please check Firestore Rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final balance = data['balance'] ?? 0;
          final pending = data['pendingRewards'] ?? 0;
          final earned = data['totalEarned'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      green,
                      Color(0xFF176B50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
                      style: TextStyle(
                        color: Colors.white70,
                      ),
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

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      'Pending Rewards',
                      '₹${money(pending)}',
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
                      const Text(
                        'The Welcome Bonus is subject to verification. '
                        'It will be added to your available balance '
                        'only after Admin approval.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Colors.orange,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Admin verification required',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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
                    .orderBy(
                      'createdAt',
                      descending: true,
                    )
                    .limit(30)
                    .snapshots(),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.hasError) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Transaction history is not available.',
                        ),
                      ),
                    );
                  }

                  if (!transactionSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final transactions =
                      transactionSnapshot.data!.docs;

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

                      final amount = item['amount'] ?? 0;
                      final title =
                          item['title']?.toString() ?? 'Reward';
                      final status =
                          item['status']?.toString() ?? 'pending';

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
                          title: Text(title),
                          subtitle: Text(status.toUpperCase()),
                          trailing: Text(
                            '₹${money(amount)}',
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

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: accent,
                      size: 30,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'INR Withdrawals',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bank Account and PhonePe UPI withdrawal '
                      'will be available after the secure payout '
                      'and Admin approval system is configured.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: accent,
              size: 25,
            ),
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
}
