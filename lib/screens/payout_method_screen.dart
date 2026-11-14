
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutMethodScreen extends StatefulWidget {
  const PayoutMethodScreen({super.key});

  @override
  State<PayoutMethodScreen> createState() =>
      _PayoutMethodScreenState();
}

class _PayoutMethodScreenState extends State<PayoutMethodScreen> {
  static const Color green = Color(0xFF103D30);
  static const Color accent = Color(0xFF16845C);

  final bankNameController = TextEditingController();
  final holderController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  bool loading = true;
  bool savingBank = false;
  bool savingUpi = false;

  String? savedBank;
  String? savedUpi;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get bankRef =>
      FirebaseFirestore.instance
          .collection('payout_methods')
          .doc(uid)
          .collection('methods')
          .doc('bank');

  DocumentReference<Map<String, dynamic>> get upiRef =>
      FirebaseFirestore.instance
          .collection('payout_methods')
          .doc(uid)
          .collection('methods')
          .doc('upi');

  @override
  void initState() {
    super.initState();
    loadMethods();
  }

  Future<void> loadMethods() async {
    try {
      final results = await Future.wait([
        bankRef.get(),
        upiRef.get(),
      ]);

      if (!mounted) return;

      if (results[0].exists) {
        final data = results[0].data()!;
        bankNameController.text = data['bankName'] ?? '';
        holderController.text = data['accountHolderName'] ?? '';
        accountController.text = data['accountNumber'] ?? '';
        ifscController.text = data['ifsc'] ?? '';
        savedBank = 'Bank Account saved';
      }

      if (results[1].exists) {
        final data = results[1].data()!;
        upiController.text = data['upiId'] ?? '';
        savedUpi = 'UPI ID saved';
      }
    } catch (e) {
      showMessage('Unable to load payout details. Check Firestore Rules.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveBank() async {
    final bankName = bankNameController.text.trim();
    final holder = holderController.text.trim();
    final account = accountController.text.trim();
    final ifsc = ifscController.text.trim().toUpperCase();

    if (bankName.isEmpty ||
        holder.isEmpty ||
        account.isEmpty ||
        ifsc.isEmpty) {
      showMessage('Please fill in all bank details');
      return;
    }

    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(account)) {
      showMessage('Enter a valid bank account number');
      return;
    }

    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
      showMessage('Enter a valid IFSC code');
      return;
    }

    setState(() => savingBank = true);

    try {
      await bankRef.set({
        'methodType': 'bank',
        'bankName': bankName,
        'accountHolderName': holder,
        'accountNumber': account,
        'ifsc': ifsc,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        savedBank = 'Bank Account saved';
      });

      showMessage('Bank Account saved successfully');
    } catch (e) {
      showMessage('Bank details could not be saved. Check Firestore Rules.');
    } finally {
      if (mounted) {
        setState(() => savingBank = false);
      }
    }
  }

  Future<void> saveUpi() async {
    final upi = upiController.text.trim();

    if (!RegExp(
      r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z0-9.-]{2,64}$',
    ).hasMatch(upi)) {
      showMessage('Enter a valid UPI ID');
      return;
    }

    setState(() => savingUpi = true);

    try {
      await upiRef.set({
        'methodType': 'upi',
        'upiId': upi,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        savedUpi = 'UPI ID saved';
      });

      showMessage('UPI ID saved successfully');
    } catch (e) {
      showMessage('UPI ID could not be saved. Check Firestore Rules.');
    } finally {
      if (mounted) {
        setState(() => savingUpi = false);
      }
    }
  }

  @override
  void dispose() {
    bankNameController.dispose();
    holderController.dispose();
    accountController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7F4),
        appBar: AppBar(
          title: const Text('Payout Methods'),
          backgroundColor: green,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.account_balance),
                text: 'Bank Account',
              ),
              Tab(
                icon: Icon(Icons.phone_android),
                text: 'PhonePe / UPI',
              ),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  bankForm(),
                  upiForm(),
                ],
              ),
      ),
    );
  }

  Widget bankForm() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(
          Icons.account_balance,
          color: accent,
          size: 55,
        ),
        const SizedBox(height: 12),
        const Text(
          'Add Bank Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your own bank account details for INR withdrawals.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),

        field(
          'Bank Name',
          bankNameController,
          Icons.account_balance,
        ),
        field(
          'Account Holder Name',
          holderController,
          Icons.person_outline,
        ),
        field(
          'Account Number',
          accountController,
          Icons.numbers,
          keyboardType: TextInputType.number,
        ),
        field(
          'IFSC Code',
          ifscController,
          Icons.code,
        ),

        if (savedBank != null)
          statusMessage(savedBank!),

        const SizedBox(height: 15),

        saveButton(
          label: 'Save Bank Account',
          loading: savingBank,
          onPressed: saveBank,
        ),
      ],
    );
  }

  Widget upiForm() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Icon(
          Icons.account_balance_wallet,
          color: accent,
          size: 55,
        ),
        const SizedBox(height: 12),
        const Text(
          'Add PhonePe / UPI ID',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: green,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your own UPI ID to receive INR withdrawals.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 25),

        field(
          'UPI ID',
          upiController,
          Icons.alternate_email,
          hint: 'example@upi',
        ),

        if (savedUpi != null)
          statusMessage(savedUpi!),

        const SizedBox(height: 20),

        saveButton(
          label: 'Save UPI ID',
          loading: savingUpi,
          onPressed: saveUpi,
        ),
      ],
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: accent),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget statusMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget saveButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
