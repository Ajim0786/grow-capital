
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
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadReferralCode();
  }

  Future<void> loadReferralCode() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      final firestore = FirebaseFirestore.instance;

      final userRef = firestore.collection('users').doc(user.uid);

      final code = 'GROW-${user.uid}';

      final codeRef =
          firestore.collection('referral_codes').doc(code);

      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final codeSnapshot = await transaction.get(codeRef);

        if (userSnapshot.exists) {
          final savedCode =
              userSnapshot.data()?['referralCode'];

          if (savedCode != code) {
            throw Exception('Referral code verification failed.');
          }
        } else {
          transaction.set(userRef, {
            'uid': user.uid,
            'referralCode': code,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (codeSnapshot.exists) {
          final savedUid = codeSnapshot.data()?['uid'];

          if (savedUid != user.uid) {
            throw Exception('Referral code already belongs to another user.');
          }
        } else {
          transaction.set(codeRef, {
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (mounted) {
        setState(() {
          referralCode = code;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  void copyCode() {
    final code = referralCode;
    if (code == null) return;

    Clipboard.setData(ClipboardData(text: code));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  void shareCode() {
    final code = referralCode;
    if (code == null) return;

    Share.share(
      'Join GROW CAPITAL!\n'
      'Use my referral code: $code\n'
      'Download the GROW CAPITAL app and enter '
      'this code during registration.',
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
                          onPressed: loadReferralCode,
                          child: const Text('TRY AGAIN'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
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
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
                    Row(
                      children: [
                        Expanded(
                          child: statCard(
                            Icons.people_outline,
                            'Total Invites',
                            '0',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: statCard(
                            Icons.verified_user_outlined,
                            'Verified',
                            '0',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    statCard(
                      Icons.account_balance_wallet_outlined,
                      'Referral Rewards',
                      '₹0.00',
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
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history,
                            color: accent,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No referrals yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Referral tracking will be connected '
                            'in the next step.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
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
    );
  }

  static Widget statCard(
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
}
