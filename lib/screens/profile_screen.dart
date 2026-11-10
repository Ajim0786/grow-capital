
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile. Check connection or permissions.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 15),
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: green,
                  child: Icon(
                    Icons.person,
                    size: 55,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['fullName'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const Text(
                  'GROW CAPITAL MEMBER',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 28),
                profileItem(
                  Icons.person_outline,
                  'Full Name',
                  data['fullName'] ?? 'Not available',
                ),
                profileItem(
                  Icons.email_outlined,
                  'Gmail Address',
                  data['email'] ?? user.email ?? 'Not available',
                ),
                profileItem(
                  Icons.phone_android,
                  'Mobile Number',
                  data['mobileNumber'] ?? 'Not available',
                ),
                profileItem(
                  Icons.card_giftcard,
                  'Referral Code',
                  data['referralCode'] ?? 'Not available',
                ),
                profileItem(
                  Icons.calendar_today,
                  'Account Created',
                  formatDate(data['createdAt']),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                false,
                              ),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                dialogContext,
                                true,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileItem(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: accent),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
      ),
    );
  }
}
