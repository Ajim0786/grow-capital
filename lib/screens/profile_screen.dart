
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);
  static const Color background = Color(0xFFF3F7F4);

  final ImagePicker picker = ImagePicker();

  bool uploading = false;
  bool savingAddress = false;

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not available';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> uploadProfilePicture(String uid) async {
    if (uploading) return;

    try {
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (pickedImage == null) return;

      setState(() => uploading = true);

      final file = File(pickedImage.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(uid)
          .child('profile.jpg');

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'photoUrl': imageUrl,
      });

      showMessage('Profile picture updated successfully');
    } catch (e) {
      showMessage('Picture upload failed. Check Storage Rules.');
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Future<void> editAddress(
    String uid,
    String currentAddress,
  ) async {
    final controller = TextEditingController(
      text: currentAddress,
    );

    final newAddress = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Address'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 250,
          decoration: const InputDecoration(
            hintText: 'House, Street, Village, District, State, PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newAddress == null) return;

    if (newAddress.isEmpty) {
      showMessage('Please enter your full address');
      return;
    }

    try {
      setState(() => savingAddress = true);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'address': newAddress,
      });

      showMessage('Address updated successfully');
    } catch (e) {
      showMessage('Address update failed. Check Firestore Rules.');
    } finally {
      if (mounted) {
        setState(() => savingAddress = false);
      }
    }
  }

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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load profile.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data?.data() ?? {};

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

          final photoUrl =
              (data['photoUrl'] ?? user.photoURL ?? '').toString();

          final isComplete = fullName.trim().isNotEmpty &&
              email.trim().isNotEmpty &&
              mobile.trim().isNotEmpty &&
              address.trim().isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 15),

                // PROFILE PHOTO
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundColor: green,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Material(
                      color: accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: uploading
                            ? null
                            : () => uploadProfilePicture(user.uid),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (uploading) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 6),
                  const Text('Uploading picture...'),
                ],

                const SizedBox(height: 12),

                Text(
                  fullName.isEmpty ? 'Customer' : fullName,
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

                const SizedBox(height: 25),

                // PROFILE COMPLETION
                Card(
                  child: ListTile(
                    leading: Icon(
                      isComplete
                          ? Icons.verified
                          : Icons.info_outline,
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
                      isComplete ? '100%' : 'Incomplete',
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
                  referralCode.isEmpty
                      ? 'Not available'
                      : referralCode,
                ),

                // ADDRESS
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: accent,
                    ),
                    title: const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    subtitle: Text(
                      address.isEmpty ? 'Add your address' : address,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                    trailing: savingAddress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.edit, color: accent),
                    onTap: savingAddress
                        ? null
                        : () => editAddress(user.uid, address),
                  ),
                ),

                profileItem(
                  Icons.calendar_today,
                  'Account Created',
                  formatDate(data['createdAt']),
                ),

                const SizedBox(height: 25),

                // LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 50,
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
            ),
          );
        },
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
