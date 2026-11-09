import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const Color backgroundColor = Color(0xFF101827);
  static const Color cardColor = Color(0xFF1C293B);
  static const Color accentColor = Color(0xFF19C37D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daily Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF126B52), Color(0xFF173D50)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.task_alt, color: Colors.white, size: 35),
                SizedBox(height: 12),
                Text(
                  'Complete Daily Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Complete available activities and earn eligible rewards.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Available Tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _taskCard(
            icon: Icons.person,
            title: 'Complete Your Profile',
            description: 'Keep your account information updated.',
            status: 'Coming Soon',
          ),
          _taskCard(
            icon: Icons.share,
            title: 'Invite Friends',
            description: 'Invite friends using your referral link.',
            status: 'Coming Soon',
          ),
          _taskCard(
            icon: Icons.quiz,
            title: 'Daily Quiz',
            description: 'Answer questions and test your knowledge.',
            status: 'Open Quiz',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _taskCard(
            icon: Icons.calendar_today,
            title: 'Daily Check-in',
            description: 'Visit the app regularly.',
            status: 'Coming Soon',
          ),
          const SizedBox(height: 18),
          const Text(
            'Note: Rewards are not active yet. Task completion and reward '
            'verification will be connected to the secure server later.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget _taskCard({
    required IconData icon,
    required String title,
    required String description,
    required String status,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            child: Text(
              status,
              style: const TextStyle(
                color: accentColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
