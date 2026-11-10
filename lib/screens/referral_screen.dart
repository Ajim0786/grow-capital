
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  static const Color background = Color(0xFF101827);
  static const Color cardColor = Color(0xFF1C293B);
  static const Color accent = Color(0xFF19C37D);

  String? referralCode;
  String? errorMessage;

  bool loading = true;
  int totalInvites = 0;
  int verifiedReferrals = 0;

  List<Map<String, dynamic>> referralMembers = [];

  @override
  void initState() {
    super.initState();
    loadReferralData();
  }

  Future<void> loadReferralData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      final db = FirebaseFirestore.instance;

      // Load current user's referral code.
      final userSnapshot =
          await db.collection('users').doc(user.uid).get();

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      final code =
          userSnapshot.data()?['referralCode']?.toString();

      if (code == null || code.isEmpty) {
        throw Exception('Referral code not found.');
      }

      // Verify ownership of referral code.
      final codeSnapshot =
          await db.collection('referral_codes').doc(code).get();

      if (!codeSnapshot.exists ||
          codeSnapshot.data()?['uid'] != user.uid) {
        throw Exception('Referral code verification failed.');
      }

      // Find users who registered with this user's referral code.
      final membersSnapshot = await db
          .collection('users')
          .where('referredByUid', isEqualTo: user.uid)
          .get();

      final members = membersSnapshot.docs.map((doc) {
        final data = doc.data();

        return <String, dynamic>{
          'name': data['fullName'] ?? 'GROW CAPITAL Member',
          'email': data['email'] ?? '',
          'createdAt': data['createdAt'],
          'verified': data['verified'] == true,
        };
      }).toList();

      members.sort((a, b) {
        final dateA = a['createdAt'];
        final dateB = b['createdAt'];

        final timeA = dateA is Timestamp
            ? dateA.toDate()
            : DateTime(2000);

        final timeB = dateB is Timestamp
            ? dateB.toDate()
            : DateTime(2000);

        return timeB.compareTo(timeA);
      });

      if (!mounted) return;

      setState(() {
        referralCode = code;
        referralMembers = members;
        totalInvites = members.length;
        verifiedReferrals =
            members.where((m) => m['verified'] == true).length;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> copyCode() async {
    final code = referralCode;
    if (code == null) return;

    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied successfully!'),
      ),
    );
  }

  Future<void> shareCode() async {
    final code = referralCode;
    if (code == null) return;

    await Share.share(
      'Join GROW CAPITAL!\n\n'
      'Use my referral code: $code\n\n'
      'Download the GROW CAPITAL app and enter '
      'this code during registration.',
    );
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return 'Date unavailable';
  }

  Widget statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 27),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget referralHistory() {
    if (referralMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.history, color: accent, size: 42),
            SizedBox(height: 12),
            Text(
              'No referrals yet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'New members who register using your '
              'referral code will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      );
    }

    return Column(
      children: referralMembers.map((member) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF126B52),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Joined: ${formatDate(member['createdAt'])}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                member['verified'] == true
                    ? Icons.verified
                    : Icons.pending_outlined,
                color: member['verified'] == true
                    ? accent
                    : Colors.orangeAccent,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Referral Program',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : loadReferralData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: accent),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 45,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: loadReferralData,
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReferralData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF126B52),
                              Color(0xFF173D50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.people_alt,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Invite Friends & Grow Together',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 9),
                            Text(
                              'Share your unique referral code '
                              'with friends.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Your Referral Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                referralCode ?? '',
                                style: const TextStyle(
                                  color: accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: copyCode,
                              icon: const Icon(
                                Icons.copy,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: shareCode,
                          icon: const Icon(Icons.share),
                          label: const Text('Share Referral Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Referral Statistics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 13),
                      statCard(
                        Icons.people_outline,
                        'Total Invites',
                        totalInvites.toString(),
                      ),
                      const SizedBox(height: 12),
                      statCard(
                        Icons.verified_user_outlined,
                        'Verified Referrals',
                        verifiedReferrals.toString(),
                      ),
                      const SizedBox(height: 12),
                      statCard(
                        Icons.account_balance_wallet_outlined,
                        'Referral Rewards',
                        'Not active',
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'Referral History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      referralHistory(),
                      const SizedBox(height: 20),
                      const Text(
                        'Referral rewards are not active yet. '
                        'Verification and reward rules will be '
                        'implemented separately.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
