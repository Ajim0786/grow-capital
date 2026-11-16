
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quiz_screen.dart';
import 'tasks_screen.dart';
import 'referral_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'admin_screen.dart';

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
      final uri = Uri.parse(link);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        showMessage('Unable to open Telegram');
      }
    } catch (_) {
      showMessage('Unable to open Telegram');
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
    setState(() {
      selectedIndex = index;
    });

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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
                icon: const Icon(
                  Icons.admin_panel_settings,
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              showMessage('No new notifications');
            },
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

              // AVAILABLE REWARDS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      green,
                      Color(0xFF176B50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE REWARDS',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
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
                      style: TextStyle(
                        color: Colors.white70,
                      ),
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

              // PREMIUM
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
                    Text(
                      'Optional membership • ₹49/month',
                    ),
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

              // ACTIVITIES
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

              // TELEGRAM
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
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
                  label: const Text(
                    'Personal Customer Support',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // VIDEO ADVERTISEMENT
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
                  border: Border.all(
                    color: Colors.black12,
                  ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
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

              // IMPORTANT INFORMATION
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

      // BOTTOM NAVIGATION
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

  // ACTIVITY CARD
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
              Icon(
                icon,
                size: 32,
                color: accent,
              ),
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
