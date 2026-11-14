
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quiz_screen.dart';
import 'tasks_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  late Future<bool> adminFuture;

  @override
  void initState() {
    super.initState();
    adminFuture = checkAdmin();
  }

  Future<bool> checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<void> openTelegram(String link) async {
    try {
      await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) showMessage('Unable to open Telegram');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void openQuiz() => openPage(const QuizScreen());
  void openTasks() => openPage(const TasksScreen());
  void openReferral() => openPage(const ReferralScreen());
  void openProfile() => openPage(const ProfileScreen());
  void openWallet() => openPage(const WalletScreen());
  void openAdmin() => openPage(const AdminScreen());

  void selectNavigation(int index) {
    setState(() => selectedIndex = index);

    if (index == 1) {
      openTasks();
    } else if (index == 2) {
      openWallet();
    } else if (index == 3) {
      openProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text(
          'GROW CAPITAL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          FutureBuilder<bool>(
            future: adminFuture,
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Admin Panel',
                onPressed: openAdmin,
                icon: const Icon(Icons.admin_panel_settings),
              );
            },
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [green, Color(0xFF176B50)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE REWARDS',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '₹0.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn • Complete Tasks • Grow',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 18),
                    Text(
                      '✓ FREE TO JOIN • NO DEPOSIT REQUIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GROW CAPITAL PREMIUM',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text('Optional membership • ₹49/month'),
                    SizedBox(height: 5),
                    Text(
                      'Free access and withdrawal remain available.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Explore Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: activityCard(
                      Icons.quiz_outlined,
                      'Daily Quiz',
                      'Learn & Practice',
                      openQuiz,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.task_alt,
                      'Tasks',
                      'Daily Activities',
                      openTasks,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: activityCard(
                      Icons.people_outline,
                      'Referral',
                      'Invite Friends',
                      openReferral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.account_balance_wallet_outlined,
                      'My Wallet',
                      'Reward History',
                      openWallet,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Telegram Community',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openTelegram(
                    'https://t.me/growcapital_support2',
                  ),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Official Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => openTelegram(
                    'https://t.me/growcapital_support1',
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Personal Customer Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Video Advertisement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 125,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 42,
                      color: accent,
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Video Advertisement Area',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Advertisement will appear here',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Rewards are subject to verification, eligibility '
                      'and available funds. No reward is guaranteed. '
                      'No deposit is required.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'GROW CAPITAL • Learn • Engage • Grow',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: selectNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget activityCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 19,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: accent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// ADMIN PANEL - CUSTOMERS, REFERRALS, WELCOME BONUS
// ======================================================

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  Future<bool> verifyAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      return doc.exists && doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  void showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // REFERRAL APPROVAL
  Future<void> updateReferral(
    BuildContext context,
    String memberId,
    String status,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .update({
        'referralStatus': status,
        'referralVerifiedBy': user.uid,
        'referralVerifiedAt': FieldValue.serverTimestamp(),
      });

      showMessage(
        context,
        status == 'verified'
            ? 'Referral verified successfully'
            : 'Referral rejected',
      );
    } catch (e) {
      showMessage(context, 'Referral update failed: $e');
    }
  }

  // WELCOME BONUS APPROVE / REJECT
  Future<void> reviewBonus(
    BuildContext context,
    String userId,
    String decision,
  ) async {
    final admin = FirebaseAuth.instance.currentUser;

    if (admin == null) {
      showMessage(context, 'Admin login required');
      return;
    }

    if (decision != 'approved' && decision != 'rejected') {
      showMessage(context, 'Invalid decision');
      return;
    }

    final db = FirebaseFirestore.instance;

    final bonusRef = db
        .collection('bonus_requests')
        .doc(userId);

    final walletRef = db
        .collection('wallets')
        .doc(userId);

    // Fixed transaction ID prevents duplicate bonus entries.
    final transactionRef = walletRef
        .collection('transactions')
        .doc('welcome_bonus_$userId');

    try {
      await db.runTransaction((transaction) async {
        // Read every document before writing.
        final bonusSnapshot =
            await transaction.get(bonusRef);

        final walletSnapshot =
            await transaction.get(walletRef);

        final historySnapshot =
            await transaction.get(transactionRef);

        if (!bonusSnapshot.exists) {
          throw Exception('Bonus request not found');
        }

        final bonusData = bonusSnapshot.data()!;

        if (bonusData['uid'] != userId ||
            bonusData['amount'] != 50) {
          throw Exception('Invalid bonus request');
        }

        if (bonusData['status'] != 'pending') {
          throw Exception('This request has already been reviewed');
        }

        if (decision == 'approved') {
          // Never credit the same bonus twice.
          if (historySnapshot.exists) {
            throw Exception('Welcome Bonus was already credited');
          }

          final walletData =
              walletSnapshot.data() ?? <String, dynamic>{};

          final oldBalance = walletData['balance'] is num
              ? (walletData['balance'] as num).toDouble()
              : 0.0;

          final oldEarned = walletData['totalEarned'] is num
              ? (walletData['totalEarned'] as num).toDouble()
              : 0.0;

          // Update bonus request.
          transaction.update(bonusRef, {
            'status': 'approved',
          });

          // Add ₹50 to customer wallet.
          transaction.set(
            walletRef,
            {
              'balance': oldBalance + 50,
              'totalEarned': oldEarned + 50,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // Add one transaction history entry.
          transaction.set(transactionRef, {
            'amount': 50,
            'title': 'Welcome Bonus',
            'status': 'approved',
            'type': 'welcome_bonus',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Reject without adding money.
          transaction.update(bonusRef, {
            'status': 'rejected',
          });
        }
      });

      showMessage(
        context,
        decision == 'approved'
            ? '₹50 Welcome Bonus approved and credited'
            : 'Welcome Bonus request rejected',
      );
    } catch (e) {
      showMessage(context, 'Bonus review failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: verifyAdmin(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin Panel'),
            ),
            body: const Center(
              child: Text('Access denied'),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Panel'),
              backgroundColor: green,
              foregroundColor: Colors.white,
              bottom: const TabBar(
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    icon: Icon(Icons.people),
                    text: 'Customers',
                  ),
                  Tab(
                    icon: Icon(Icons.verified_user),
                    text: 'Referrals',
                  ),
                  Tab(
                    icon: Icon(Icons.card_giftcard),
                    text: 'Welcome Bonus',
                  ),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _CustomersTab(),
                _ReferralsTab(),
                _WelcomeBonusTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// CUSTOMERS TAB
// ======================================================

class _CustomersTab extends StatelessWidget {
  const _CustomersTab();

  static const Color green = Color(0xFF103D30);

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load customers'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final customers = snapshot.data!.docs;

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL CUSTOMERS',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${customers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: customers.isEmpty
                  ? const Center(
                      child: Text('No customers found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final data = customers[index].data();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['fullName']?.toString() ??
                                      'Not available',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _AdminInfo(
                                  'Gmail',
                                  data['email']?.toString() ??
                                      'Not available',
                                ),
                                _AdminInfo(
                                  'Mobile',
                                  data['mobileNumber']?.toString() ??
                                      'Not available',
                                ),
                                _AdminInfo(
                                  'Referral Code',
                                  data['referralCode']?.toString() ??
                                      'Not available',
                                ),
                                _AdminInfo(
                                  'Registration Date',
                                  formatDate(data['createdAt']),
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
}

// ======================================================
// REFERRALS TAB
// ======================================================

class _ReferralsTab extends StatelessWidget {
  const _ReferralsTab();

  static const Color green = Color(0xFF103D30);

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Unable to load referrals'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final referrals = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          return data['referredByUid'] != null &&
              data['referredByUid'].toString().isNotEmpty;
        }).toList();

        final pending = referrals.where((doc) {
          final status = doc.data()['referralStatus'];
          return status != 'verified' && status != 'rejected';
        }).toList();

        final verified = referrals.where((doc) {
          return doc.data()['referralStatus'] == 'verified';
        }).length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summary(
                    'Total',
                    '${referrals.length}',
                  ),
                ),
                Expanded(
                  child: _summary(
                    'Pending',
                    '${pending.length}',
                  ),
                ),
                Expanded(
                  child: _summary(
                    'Verified',
                    '$verified',
                  ),
                ),
              ],
            ),
            Expanded(
              child: pending.isEmpty
                  ? const Center(
                      child: Text('No pending referrals'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final doc = pending[index];
                        final data = doc.data();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['fullName']?.toString() ??
                                      'Not available',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _AdminInfo(
                                  'Gmail',
                                  data['email']?.toString() ??
                                      'Not available',
                                ),
                                _AdminInfo(
                                  'Used Code',
                                  data['referredByCode']?.toString() ??
                                      'Not available',
                                ),
                                _AdminInfo(
                                  'Referrer UID',
                                  data['referredByUid']?.toString() ??
                                      '',
                                ),
                                _AdminInfo(
                                  'Joined',
                                  formatDate(data['createdAt']),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            const AdminScreen()
                                                .updateReferral(
                                          context,
                                          doc.id,
                                          'verified',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Verify'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            const AdminScreen()
                                                .updateReferral(
                                          context,
                                          doc.id,
                                          'rejected',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
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
}

// ======================================================
// WELCOME BONUS TAB
// ======================================================

class _WelcomeBonusTab extends StatelessWidget {
  const _WelcomeBonusTab();

  static const Color green = Color(0xFF103D30);

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bonus_requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Unable to load bonus requests. '
                'Please check Admin Firestore permissions.',
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

        final requests = snapshot.data!.docs;

        final pending = requests.where((doc) {
          return doc.data()['status'] == 'pending';
        }).length;

        final approved = requests.where((doc) {
          return doc.data()['status'] == 'approved';
        }).length;

        final rejected = requests.where((doc) {
          return doc.data()['status'] == 'rejected';
        }).length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _summary(
                    'Total',
                    '${requests.length}',
                  ),
                ),
                Expanded(
                  child: _summary(
                    'Pending',
                    '$pending',
                  ),
                ),
                Expanded(
                  child: _summary(
                    'Approved',
                    '$approved',
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rejected: $rejected',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            Expanded(
              child: requests.isEmpty
                  ? const Center(
                      child: Text('No Welcome Bonus requests yet'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final doc = requests[index];
                        final data = doc.data();

                        final userId =
                            data['uid']?.toString() ?? doc.id;

                        final status =
                            data['status']?.toString() ?? 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      color: Color(0xFF16845C),
                                      size: 28,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '₹50 Welcome Bonus',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const Divider(),

                                _AdminInfo(
                                  'Customer UID',
                                  userId,
                                ),
                                _AdminInfo(
                                  'Amount',
                                  '₹${data['amount'] ?? 50}',
                                ),
                                _AdminInfo(
                                  'Request Date',
                                  formatDate(data['createdAt']),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    const Text(
                                      'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: status == 'approved'
                                            ? Colors.green
                                            : status == 'rejected'
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),

                                if (status == 'pending') ...[
                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              const AdminScreen()
                                                  .reviewBonus(
                                            context,
                                            userId,
                                            'approved',
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle,
                                          ),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              const AdminScreen()
                                                  .reviewBonus(
                                            context,
                                            userId,
                                            'rejected',
                                          ),
                                          icon: const Icon(Icons.cancel),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
}

// ======================================================
// COMMON ADMIN WIDGETS
// ======================================================

class _AdminInfo extends StatelessWidget {
  const _AdminInfo(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$title:',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _summary(String title, String value) {
  return Card(
    margin: const EdgeInsets.all(5),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 5,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF103D30),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
