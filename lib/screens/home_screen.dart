
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'quiz_screen.dart';
import 'tasks_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';

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
    final uri = Uri.parse(link);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) return;
      showMessage('Unable to open Telegram');
    }
  }

  void openQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizScreen(),
      ),
    );
  }

  void openTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TasksScreen(),
      ),
    );
  }

  void openReferral() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReferralScreen(),
      ),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void openAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminScreen(),
      ),
    );
  }

  void selectNavigation(int index) {
    setState(() => selectedIndex = index);

    if (index == 1) {
      openTasks();
    } else if (index == 2) {
      showMessage('Wallet is coming soon');
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
                      () => showMessage('Wallet is coming soon'),
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

// --------------------------------------------------
// ADMIN PANEL - CUSTOMER MANAGEMENT
// --------------------------------------------------

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

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
    return FutureBuilder<bool>(
      future: _verifyAdmin(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Panel')),
            body: const Center(
              child: Text('Access denied'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Panel'),
            backgroundColor: green,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Unable to load customers. Check Firestore Rules.',
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
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Customer Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

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

                              final name =
                                  data['fullName']?.toString() ??
                                  'Not available';

                              final email =
                                  data['email']?.toString() ??
                                  'Not available';

                              final mobile =
                                  data['mobileNumber']?.toString() ??
                                  'Not available';

                              final referralCode =
                                  data['referralCode']?.toString() ??
                                  'Not available';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      _info('Gmail', email),
                                      _info('Mobile', mobile),
                                      _info('Referral Code', referralCode),
                                      _info(
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
          ),
        );
      },
    );
  }

  Future<bool> _verifyAdmin() async {
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

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              '$title:',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
