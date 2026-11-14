
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  final db = FirebaseFirestore.instance;

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // =====================================
  // UPDATE ADDRESS
  // =====================================

  Future<void> editAddress(
    String uid,
    String currentAddress,
  ) async {
    final controller = TextEditingController(
      text: currentAddress,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Address'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your full address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;

    try {
      await db.collection('users').doc(uid).update({
        'address': result,
      });
      message('Address updated successfully');
    } catch (e) {
      message('Address update failed: $e');
    }
  }

  // =====================================
  // SAVE BANK ACCOUNT
  // =====================================

  Future<void> editBankAccount(
    String uid,
    Map<String, dynamic>? existing,
  ) async {
    final bankName = TextEditingController(
      text: existing?['bankName']?.toString() ?? '',
    );

    final holderName = TextEditingController(
      text: existing?['accountHolderName']?.toString() ?? '',
    );

    final accountNumber = TextEditingController(
      text: existing?['accountNumber']?.toString() ?? '',
    );

    final ifsc = TextEditingController(
      text: existing?['ifsc']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bank Account Details'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: bankName,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Enter bank name'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: holderName,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty
                          ? 'Enter account holder name'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(value)) {
                      return 'Enter a valid account number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ifsc,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim().toUpperCase() ?? '';
                    if (!RegExp(
                      r'^[A-Z]{4}0[A-Z0-9]{6}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid IFSC code';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);

              try {
                await db
                    .collection('payout_methods')
                    .doc(uid)
                    .collection('methods')
                    .doc('bank')
                    .set({
                  'methodType': 'bank',
                  'bankName': bankName.text.trim(),
                  'accountHolderName': holderName.text.trim(),
                  'accountNumber': accountNumber.text.trim(),
                  'ifsc': ifsc.text.trim().toUpperCase(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                message('Bank account saved successfully');
              } catch (e) {
                message('Bank account save failed: $e');
              }
            },
            child: const Text('Save Bank Account'),
          ),
        ],
      ),
    );

    bankName.dispose();
    holderName.dispose();
    accountNumber.dispose();
    ifsc.dispose();
  }

  // =====================================
  // SAVE UPI ID
  // =====================================

  Future<void> editUpi(
    String uid,
    Map<String, dynamic>? existing,
  ) async {
    final controller = TextEditingController(
      text: existing?['upiId']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PhonePe / UPI Details'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'example@upi',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (!RegExp(
                r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z0-9.-]{2,64}$',
              ).hasMatch(value)) {
                return 'Enter a valid UPI ID';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);

              try {
                await db
                    .collection('payout_methods')
                    .doc(uid)
                    .collection('methods')
                    .doc('upi')
                    .set({
                  'methodType': 'upi',
                  'upiId': controller.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                message('UPI ID saved successfully');
              } catch (e) {
                message('UPI save failed: $e');
              }
            },
            child: const Text('Save UPI ID'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  // =====================================
  // LOGOUT
  // =====================================

  Future<void> logout() async {
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
  }

  // =====================================
  // PROFILE SCREEN
  // =====================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    final userRef = db.collection('users').doc(user.uid);

    final bankRef = db
        .collection('payout_methods')
        .doc(user.uid)
        .collection('methods')
        .doc('bank');

    final upiRef = db
        .collection('payout_methods')
        .doc(user.uid)
        .collection('methods')
        .doc('upi');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile'),
            );
          }

          if (!profileSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = profileSnapshot.data!.data() ?? {};

          final fullName =
              (data['fullName'] ?? user.displayName ?? '').toString();

          final email =
              (data['email'] ?? user.email ?? '').toString();

          final mobile =
              (data['mobileNumber'] ?? '').toString();

          final referralCode =
              (data['referralCode'] ?? '').toString();

          final address =
              (data['address'] ?? '').toString();

          final isComplete = fullName.isNotEmpty &&
              email.isNotEmpty &&
              mobile.isNotEmpty &&
              address.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SizedBox(height: 15),

              const CircleAvatar(
                radius: 55,
                backgroundColor: green,
                child: Icon(
                  Icons.person,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 14),

              Center(
                child: Text(
                  fullName.isEmpty ? 'Customer' : fullName,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ),

              const Center(
                child: Text(
                  'GROW CAPITAL MEMBER',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: ListTile(
                  leading: Icon(
                    isComplete ? Icons.verified : Icons.info_outline,
                    color: isComplete ? accent : Colors.orange,
                  ),
                  title: const Text(
                    'Profile Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isComplete
                        ? 'Your profile is complete'
                        : 'Please complete your profile by adding your address',
                  ),
                  trailing: Text(
                    isComplete ? 'Complete' : 'Incomplete',
                    style: TextStyle(
                      color: isComplete ? accent : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              profileItem(
                Icons.person_outline,
                'Full Name',
                fullName.isEmpty ? 'Not available' : fullName,
              ),

              profileItem(
                Icons.email_outlined,
                'Gmail Address',
                email.isEmpty ? 'Not available' : email,
              ),

              profileItem(
                Icons.phone_android,
                'Mobile Number',
                mobile.isEmpty ? 'Not available' : mobile,
              ),

              profileItem(
                Icons.card_giftcard,
                'Referral Code',
                referralCode.isEmpty ? 'Not available' : referralCode,
              ),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: accent,
                  ),
                  title: const Text('Address'),
                  subtitle: Text(
                    address.isEmpty ? 'Add your address' : address,
                  ),
                  trailing: const Icon(Icons.edit, color: accent),
                  onTap: () => editAddress(user.uid, address),
                ),
              ),

              profileItem(
                Icons.calendar_today,
                'Account Created',
                formatDate(data['createdAt']),
              ),

              const SizedBox(height: 25),

              // =================================
              // PAYOUT METHODS
              // =================================

              const Text(
                'Withdrawal Methods',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Add your Bank Account and PhonePe UPI ID. '
                'You can choose either method when requesting a withdrawal.',
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // BANK ACCOUNT CARD

              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: bankRef.snapshots(),
                builder: (context, snapshot) {
                  final bank = snapshot.data?.data();

                  final hasBank = snapshot.hasData &&
                      snapshot.data!.exists;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: accent,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Bank Account',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: green,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Divider(),

                          if (snapshot.hasError)
                            const Text('Unable to load bank details')
                          else if (!snapshot.hasData)
                            const LinearProgressIndicator()
                          else if (!hasBank)
                            const Text(
                              'No bank account added yet.',
                              style: TextStyle(color: Colors.black54),
                            )
                          else ...[
                            infoRow(
                              'Bank',
                              bank?['bankName']?.toString() ?? '',
                            ),
                            infoRow(
                              'Account Holder',
                              bank?['accountHolderName']?.toString() ?? '',
                            ),
                            infoRow(
                              'Account Number',
                              '•••• ${_lastFour(bank?['accountNumber'])}',
                            ),
                            infoRow(
                              'IFSC',
                              bank?['ifsc']?.toString() ?? '',
                            ),
                          ],

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: snapshot.hasData
                                  ? () => editBankAccount(user.uid, bank)
                                  : null,
                              icon: const Icon(Icons.edit),
                              label: Text(
                                hasBank
                                    ? 'Edit Bank Account'
                                    : 'Add Bank Account',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // UPI CARD

              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: upiRef.snapshots(),
                builder: (context, snapshot) {
                  final upi = snapshot.data?.data();

                  final hasUpi = snapshot.hasData &&
                      snapshot.data!.exists;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.phone_android,
                                color: accent,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'PhonePe / UPI',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: green,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Divider(),

                          if (snapshot.hasError)
                            const Text('Unable to load UPI details')
                          else if (!snapshot.hasData)
                            const LinearProgressIndicator()
                          else if (!hasUpi)
                            const Text(
                              'No UPI ID added yet.',
                              style: TextStyle(color: Colors.black54),
                            )
                          else
                            infoRow(
                              'UPI ID',
                              upi?['upiId']?.toString() ?? '',
                            ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: snapshot.hasData
                                  ? () => editUpi(user.uid, upi)
                                  : null,
                              icon: const Icon(Icons.edit),
                              label: Text(
                                hasUpi ? 'Edit UPI ID' : 'Add UPI ID',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('LOGOUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  String _lastFour(dynamic value) {
    final account = value?.toString() ?? '';
    if (account.length <= 4) return account;
    return account.substring(account.length - 4);
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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
            child: SelectableText(
              value,
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget profileItem(
    IconData icon,
    String title,
    String value,
  ) {
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
