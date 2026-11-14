
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

  String money(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return '0.00';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      createWelcomeBonusRequest();
    });
  }

  // CREATE ONE-TIME WELCOME BONUS REQUEST
  Future<void> createWelcomeBonusRequest() async {
    if (isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      isSubmitting = true;
      requestError = null;
    });

    final db = FirebaseFirestore.instance;
    final bonusRef =
        db.collection('bonus_requests').doc(user.uid);

    try {
      await db.runTransaction((transaction) async {
        final existing = await transaction.get(bonusRef);

        // Existing request means no duplicate request.
        if (existing.exists) return;

        transaction.set(bonusRef, {
          'uid': user.uid,
          'amount': 50,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          requestError =
              'Request failed: ${e.code} - ${e.message ?? ''}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          requestError = 'Request failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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

    final db = FirebaseFirestore.instance;

    final walletRef =
        db.collection('wallets').doc(user.uid);

    final bonusRef =
        db.collection('bonus_requests').doc(user.uid);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: walletRef.snapshots(),
        builder: (context, walletSnapshot) {
          if (walletSnapshot.hasError) {
            return errorView(
              'Unable to load wallet data. '
              'Please check your Firestore Rules.',
            );
          }

          if (!walletSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final walletData =
              walletSnapshot.data!.data() ?? {};

          final balance = walletData['balance'] ?? 0;
          final earned = walletData['totalEarned'] ?? 0;

          return StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: bonusRef.snapshots(),
            builder: (context, bonusSnapshot) {
              if (bonusSnapshot.hasError) {
                return errorView(
                  'Unable to load Welcome Bonus status. '
                  'Please check Firestore Rules.',
                );
              }

              if (!bonusSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final bonusExists =
                  bonusSnapshot.data!.exists;

              final bonusData =
                  bonusSnapshot.data!.data() ?? {};

              final bonusStatus =
                  bonusData['status']?.toString() ??
                      'not_requested';

              final pendingBonus =
                  bonusExists && bonusStatus == 'pending'
                      ? 50
                      : 0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AVAILABLE BALANCE
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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

                  const Text(
                    'Welcome Bonus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: green,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // WELCOME BONUS CARD
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            bonusMessage(
                              bonusStatus,
                              bonusExists,
                            ),
                            style: const TextStyle(
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          statusBadge(
                            bonusStatus,
                            bonusExists,
                          ),

                          if (isSubmitting) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 6),
                            const Text(
                              'Submitting request...',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // REQUEST ERROR AND RETRY
                  if (requestError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      requestError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : createWelcomeBonusRequest,
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

                  StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
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
                              child: Text(
                                'No transactions yet',
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: transactions.map((doc) {
                          final item = doc.data();

                          final amount =
                              item['amount'] ?? 0;

                          final title =
                              item['title']?.toString() ??
                                  'Reward';

                          final status =
                              item['status']?.toString() ??
                                  'pending';

                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor:
                                    Color(0xFFE3F3EB),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: accent,
                                ),
                              ),
                              title: Text(title),
                              subtitle: Text(
                                status.toUpperCase(),
                              ),
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

                  // WITHDRAWAL INFORMATION
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
                          'Bank Account and PhonePe UPI '
                          'withdrawal will be available after '
                          'the secure payout and Admin approval '
                          'system is configured.',
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
          );
        },
      ),
    );
  }

  // BONUS MESSAGE
  String bonusMessage(String status, bool exists) {
    if (!exists) {
      return 'Your ₹50 Welcome Bonus request has not '
          'been submitted yet.';
    }

    switch (status) {
      case 'pending':
        return 'Your ₹50 Welcome Bonus request has been '
            'submitted. It will be added to your available '
            'balance only after Admin approval.';

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

  // BONUS STATUS BADGE
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
        Icon(
          icon,
          color: color,
          size: 19,
        ),
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

  // STATISTICS CARD
  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
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

  // ERROR VIEW
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
