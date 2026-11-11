
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeBonusService {
  static const int bonusAmount = 50;

  static Future<void> createWelcomeBonus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final firestore = FirebaseFirestore.instance;

    final bonusRef = firestore
        .collection('welcome_bonus_requests')
        .doc(user.uid);

    await firestore.runTransaction((transaction) async {
      final existingBonus = await transaction.get(bonusRef);

      // Prevent duplicate welcome bonus
      if (existingBonus.exists) {
        return;
      }

      transaction.set(bonusRef, {
        'uid': user.uid,
        'email': user.email,
        'amount': bonusAmount,
        'type': 'welcome_bonus',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
      });
    });
  }
}
