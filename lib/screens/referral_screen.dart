
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Program'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load referral details'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          final referralCode = data?['referralCode']?.toString() ?? '';

          if (referralCode.isEmpty) {
            return const Center(
              child: Text('Referral code not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people_alt,
                          size: 45,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          referralCode,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: referralCode),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Referral code copied'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(
                                    'Join GROW CAPITAL using my referral code: '
                                    '$referralCode\n\n'
                                    'Register in the app and enter this code.',
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Referral Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('referredByUid', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, membersSnapshot) {
                    if (membersSnapshot.hasError) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Members could not be loaded. '
                            'Please check Firestore permissions.',
                          ),
                        ),
                      );
                    }

                    if (!membersSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final members = membersSnapshot.data!.docs;

                    if (members.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No referral members yet.',
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.groups,
                              color: Colors.blue,
                              size: 32,
                            ),
                            title: const Text('Total Invites'),
                            trailing: Text(
                              '${members.length}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...members.map((member) {
                          final memberData = member.data();
                          final name =
                              memberData['fullName']?.toString() ??
                              'New Member';

                          final createdAt = memberData['createdAt'];
                          String dateText = 'Date unavailable';

                          if (createdAt is Timestamp) {
                            final date = createdAt.toDate();
                            dateText =
                                '${date.day}/${date.month}/${date.year}';
                          }

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(name),
                              subtitle: Text('Joined: $dateText'),
                              trailing: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.orange,
                                    size: 22,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
