
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? verificationId;
  bool loading = false;

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.length != 10) {
      showMessage('Enter a valid 10 digit mobile number');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          showMessage(error.message ?? 'OTP verification failed');
        },
        codeSent: (id, token) {
          setState(() {
            verificationId = id;
          });
          showMessage('OTP sent successfully');
        },
        codeAutoRetrievalTimeout: (id) {
          verificationId = id;
        },
      );
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyOTP() async {
    if (verificationId == null || otpController.text.trim().length != 6) {
      showMessage('Enter the 6 digit OTP');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Invalid OTP');
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 75,
                color: Color(0xFF176B50),
              ),
              const SizedBox(height: 15),
              const Text(
                'GROW CAPITAL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF176B50),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Login with your mobile number'),
              const SizedBox(height: 35),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
              ),
              if (verificationId != null) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : verificationId == null
                          ? sendOTP
                          : verifyOTP,
                  child: loading
                      ? const CircularProgressIndicator()
                      : Text(
                          verificationId == null
                              ? 'SEND OTP'
                              : 'VERIFY OTP',
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Free to join • No deposit required',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
