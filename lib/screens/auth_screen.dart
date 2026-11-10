
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

  bool isRegister = true;
  bool loading = false;
  bool obscurePassword = true;

  final Color green = const Color(0xFF17B650);

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submit() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
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

      if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
        showMessage('Enter a valid 10 digit mobile number');
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
        final uid = user.uid;
        final referralCode = 'GROW-$uid';

        final batch = FirebaseFirestore.instance.batch();

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid);

        final referralRef = FirebaseFirestore.instance
            .collection('referral_codes')
            .doc(referralCode);

        batch.set(userRef, {
          'uid': uid,
          'fullName': name,
          'mobileNumber': phone,
          'email': email,
          'referralCode': referralCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.set(referralRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (mounted) {
          showMessage('Registration successful!');
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          showMessage('Login successful!');
        }
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
