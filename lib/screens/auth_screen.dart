
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final referralController = TextEditingController();

  bool isRegister = true;
  bool loading = false;
  bool obscurePassword = true;

  final Color green = const Color(0xFF17B650);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final Random random = Random();

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String makePrefix(String name) {
    final letters = name.toUpperCase().replaceAll(
      RegExp(r'[^A-Z]'),
      '',
    );

    if (letters.length < 3) return 'USER';

    return letters.substring(
      0,
      min(4, letters.length),
    );
  }

  String makeReferralCode(String prefix) {
    final number = 100 + random.nextInt(900);
    return '$prefix$number';
  }

  Future<bool> saveNewAccount({
    required String uid,
    required String name,
    required String phone,
    required String email,
    required String prefix,
    required String? referredByCode,
    required String? referredByUid,
  }) async {
    for (int attempt = 0; attempt < 50; attempt++) {
      final code = makeReferralCode(prefix);

      final userRef = db.collection('users').doc(uid);
      final ownCodeRef = db.collection('referral_codes').doc(code);

      final success = await db.runTransaction<bool>((transaction) async {
        final existingCode = await transaction.get(ownCodeRef);

        if (existingCode.exists) {
          return false;
        }

        if (referredByCode != null) {
          final referrerRef = db
              .collection('referral_codes')
              .doc(referredByCode);

          final referrerSnapshot = await transaction.get(referrerRef);

          if (!referrerSnapshot.exists ||
              referrerSnapshot.data()?['uid'] != referredByUid) {
            throw Exception('Referral code is no longer valid');
          }

          if (referredByUid == uid) {
            throw Exception('You cannot use your own referral code');
          }
        }

        final userData = <String, dynamic>{
          'uid': uid,
          'fullName': name,
          'mobileNumber': phone,
          'email': email,
          'referralCode': code,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (referredByCode != null && referredByUid != null) {
          userData['referredByCode'] = referredByCode;
          userData['referredByUid'] = referredByUid;
        }

        transaction.set(userRef, userData);

        transaction.set(ownCodeRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (success) return true;
    }

    return false;
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final enteredReferral = referralController.text.trim().toUpperCase();

    if (email.isEmpty || !email.contains('@')) {
      showMessage('Enter a valid Gmail address');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    if (isRegister) {
      if (name.isEmpty) {
        showMessage('Enter your full name');
        return;
      }

      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
        showMessage('Enter a valid 10 digit mobile number');
        return;
      }

      if (password != confirmPassword) {
        showMessage('Passwords do not match');
        return;
      }

      if (enteredReferral.isNotEmpty &&
          !RegExp(r'^[A-Z]{3,5}[0-9]{3}$')
              .hasMatch(enteredReferral)) {
        showMessage('Enter a valid referral code');
        return;
      }
    }

    setState(() => loading = true);

    try {
      if (isRegister) {
        String? referredByUid;

        // Validate the referral code before creating the account.
        if (enteredReferral.isNotEmpty) {
          final referralSnapshot = await db
              .collection('referral_codes')
              .doc(enteredReferral)
              .get();

          if (!referralSnapshot.exists) {
            showMessage('Referral code does not exist');
            return;
          }

          referredByUid = referralSnapshot.data()?['uid'] as String?;

          if (referredByUid == null) {
            showMessage('Invalid referral code');
            return;
          }
        }

        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user!;
        await user.updateDisplayName(name);

        final saved = await saveNewAccount(
          uid: user.uid,
          name: name,
          phone: phone,
          email: email,
          prefix: makePrefix(name),
          referredByCode:
              enteredReferral.isEmpty ? null : enteredReferral,
          referredByUid: referredByUid,
        );

        if (!saved) {
          showMessage(
            'Account created, but referral code could not be generated. '
            'Please contact support before registering again.',
          );
          return;
        }

        showMessage('Registration successful!');
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        showMessage('Login successful!');
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This Gmail is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid Gmail address';
          break;
        case 'weak-password':
          message = 'Please use a stronger password';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect Gmail or password';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection';
          break;
        default:
          message = e.message ?? 'Authentication failed';
      }

      showMessage(message);
    } on FirebaseException catch (e) {
      showMessage('Database error: ${e.message ?? e.code}');
    } catch (e) {
      showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      showMessage('Enter your Gmail address first');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
      showMessage('Password reset link sent to your Gmail');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Could not send reset link');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    bool password = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: password && obscurePassword,
        maxLength: maxLength,
        textCapitalization: label == 'Referral Code'
            ? TextCapitalization.characters
            : TextCapitalization.none,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: green),
          ),
          suffixIcon: password
              ? IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1715),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 75,
                color: green,
              ),
              const SizedBox(height: 15),
              Text(
                'GROW CAPITAL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isRegister ? 'Create Your Account' : 'Welcome Back',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),

              if (isRegister) ...[
                inputField('Full Name', nameController),
                inputField(
                  'Mobile Number',
                  phoneController,
                  keyboard: TextInputType.phone,
                  maxLength: 10,
                ),
                inputField(
                  'Referral Code (Optional)',
                  referralController,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Text(
                      'You can edit or remove this code before registration.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],

              inputField(
                'Gmail Address',
                emailController,
                keyboard: TextInputType.emailAddress,
              ),

              inputField(
                'Password',
                passwordController,
                password: true,
              ),

              if (isRegister)
                inputField(
                  'Confirm Password',
                  confirmPasswordController,
                  password: true,
                ),

              if (!isRegister)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: loading ? null : forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: green),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          isRegister ? 'REGISTER' : 'LOGIN',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        setState(() {
                          isRegister = !isRegister;
                        });
                      },
                child: Text(
                  isRegister
                      ? 'Already have an account? Login'
                      : 'New user? Create an account',
                  style: TextStyle(color: green),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Free to join • No deposit required',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
