
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    final walletRef = FirebaseFirestore.instance
        .collection('wallets')
        .doc(user.uid);

    final bonusRef = FirebaseFirestore.instance
        .collection('welcome_bonus_requests')
        .doc(user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: walletRef.snapshots(),
        builder: (context, walletSnapshot) {
          if (walletSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load wallet'),
            );
          }

          if (walletSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final wallet = walletSnapshot.data?.data() ?? {};

          final balance = (wallet['balance'] as num?) ?? 0;
          final totalEarned = (wallet['totalEarned'] as num?) ?? 0;
          final pendingRewards =
              (wallet['pendingRewards'] as num?) ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [green, accent],
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
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'GROW CAPITAL REWARDS WALLET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: summaryCard(
                        'Total Earned',
                        '₹${totalEarned.toStringAsFixed(2)}',
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: summaryCard(
                        'Pending',
                        '₹${pendingRewards.toStringAsFixed(2)}',
                        Icons.pending_actions,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'Welcome Bonus',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  stream: bonusRef.snapshots(),
                  builder: (context, bonusSnapshot) {
                    final bonus = bonusSnapshot.data?.data();
                    final status =
                        bonus?['status']?.toString() ?? 'Not received';

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2E9),
                          child: Icon(
                            Icons.card_giftcard,
                            color: accent,
                          ),
                        ),
                        title: const Text('₹50 Welcome Bonus'),
                        subtitle: Text('Status: $status'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: walletRef
                      .collection('transactions')
                      .orderBy(
                        'createdAt',
                        descending: true,
                      )
                      .limit(20)
                      .snapshots(),
                  builder: (context, transactionSnapshot) {
                    if (transactionSnapshot.hasError) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Transaction history is not available yet.',
                          ),
                        ),
                      );
                    }

                    if (transactionSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final transactions =
                        transactionSnapshot.data?.docs ?? [];

                    if (transactions.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: transactions.map((doc) {
                        final item = doc.data();
                        final amount =
                            (item['amount'] as num?) ?? 0;
                        final title =
                            item['title']?.toString() ??
                                item['type']?.toString() ??
                                'Reward';
                        final date = item['createdAt'];

                        String dateText = 'Date unavailable';

                        if (date is Timestamp) {
                          final d = date.toDate();
                          dateText =
                              '${d.day}/${d.month}/${d.year}';
                        }

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt_long,
                              color: accent,
                            ),
                            title: Text(title),
                            subtitle: Text(dateText),
                            trailing: Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Rewards are subject to verification and approval. '
                  'No deposit is required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget summaryCard(
    String title,
    String amount,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amount,
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
