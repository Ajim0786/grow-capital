
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
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isRegister = false;
  bool loading = false;
  bool hidePassword = true;

  static const Color green = Color(0xFF176B50);

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

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

      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
        showMessage('Enter a valid 10-digit Indian mobile number');
        return;
      }

      if (password != confirmPassword) {
        showMessage('Passwords do not match');
        return;
      }
    }

    setState(() => loading = true);

    try {
      if (isRegister) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = credential.user!;

        await user.updateDisplayName(name);

        final referralCode = 'GROW-${user.uid}';

        final batch = FirebaseFirestore.instance.batch();

        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final referralDoc = FirebaseFirestore.instance
            .collection('referral_codes')
            .doc(referralCode);

        batch.set(userDoc, {
          'uid': user.uid,
          'fullName': name,
          'mobileNumber': mobile,
          'email': email,
          'referralCode': referralCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.set(referralDoc, {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

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
          message = 'This email is already registered. Please login.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
      }

      showMessage(message);
    } on FirebaseException catch (e) {
      showMessage(
        'Account created, but profile saving failed: ${e.message ?? e.code}',
      );
    } catch (e) {
      showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim().toLowerCase();

    if (email.isEmpty || !email.contains('@')) {
      showMessage('Enter your Gmail address first');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showMessage('Password reset link sent to your email');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Unable to send reset email');
    }
  }

  InputDecoration fieldDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 75,
                  color: green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'GROW CAPITAL',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isRegister
                      ? 'Create your free account'
                      : 'Login to your account',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 30),

                if (isRegister) ...[
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: fieldDecoration(
                      'Full Name',
                      Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: fieldDecoration(
                      'Mobile Number',
                      Icons.phone_android,
                    ).copyWith(
                      counterText: '',
                      prefixText: '+91 ',
                    ),
                  ),
                  const SizedBox(height: 15),
                ],

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: fieldDecoration(
                    'Gmail Address',
                    Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: fieldDecoration(
                    'Password',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),

                if (isRegister) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: hidePassword,
                    decoration: fieldDecoration(
                      'Confirm Password',
                      Icons.lock_reset,
                    ),
                  ),
                ],

                if (!isRegister) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: green),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isRegister ? 'CREATE ACCOUNT' : 'LOGIN',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

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
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Free to join • No deposit required',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mobile number is saved but not OTP verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
