
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final userSubscriptionProvider = StreamProvider<SubscriptionPlan>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(SubscriptionPlan.free);
  
  return ref.watch(subscriptionServiceProvider).getSubscriptionStream(user.uid);
});

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'intellitrain',
  );

  CollectionReference get _usersCollection => _firestore.collection('users');

  Stream<SubscriptionPlan> getSubscriptionStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return SubscriptionPlan.free;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['plan'] == null) return SubscriptionPlan.free;
      return SubscriptionPlan.values[data['plan']];
    });
  }

  Future<void> upgradeToPro(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'plan': SubscriptionPlan.pro.index,
      });
    } catch (e) {
      // If document doesn't exist, create it (should not happen with regular auth flow but just in case)
      await _usersCollection.doc(uid).set({
        'plan': SubscriptionPlan.pro.index,
      }, SetOptions(merge: true));
    }
  }
}
