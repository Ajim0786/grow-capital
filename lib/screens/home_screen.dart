
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> openTelegram(String link) async {
    final uri = Uri.parse(link);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open Telegram')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please try again')),
      );
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 6),
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
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
                    Row(
                      children: [
                        Icon(Icons.verified_user,
                            color: Colors.white70, size: 17),
                        SizedBox(width: 7),
                        Text(
                          'FREE TO JOIN • NO DEPOSIT REQUIRED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    Text(
                      'Optional membership • ₹49/month',
                      style: TextStyle(fontSize: 15),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.task_alt,
                      'Tasks',
                      'Daily Activities',
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: activityCard(
                      Icons.account_balance_wallet_outlined,
                      'My Wallet',
                      'Reward History',
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                  label: const Text('Personal Customer Support'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                      'Rewards are subject to verification, '
                      'eligibility and available funds. '
                      'No reward is guaranteed. No deposit is required.',
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
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
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
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
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
    );
  }
}
