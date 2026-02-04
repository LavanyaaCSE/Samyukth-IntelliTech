import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔐 Attempting to sign in with email: $email');
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('✅ Sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unknown error during sign in: $e');
      throw 'An unknown error occurred: $e';
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String fullName, String recoveryPin) async {
    try {
      print('📝 Attempting to sign up with email: $email');
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Update display name and save PIN to Firestore
      if (result.user != null) {
        await result.user!.updateDisplayName(fullName);
        
        final firestore = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'intellitrain',
        );
        
        await firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email,
          'fullName': fullName,
          'recoveryPin': recoveryPin,
          'role': 0, // Default role
          'plan': 0, // Default plan
          'createdAt': FieldValue.serverTimestamp(),
        });

        await result.user!.reload(); 
        print('👤 Profile and Recovery PIN created for: $fullName');
      }

      print('✅ Sign up successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unknown error during sign up: $e');
      throw 'An unknown error occurred: $e';
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Signing out...');
      // Sign out from Google Sign-In if user was signed in with Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print('✅ Signed out from Google');
      }
      // Sign out from Firebase
      await _auth.signOut();
      print('✅ Signed out from Firebase');
    } catch (e) {
      print('❌ Error during sign out: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      print('🔍 Attempting Google Sign-In');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('⚠️ Google Sign-In was cancelled by user');
        throw 'Google Sign-In aborted.';
      }

      print('✅ Google user obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in with Google credential');
      final result = await _auth.signInWithCredential(credential);
      print('✅ Google Sign-In successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Error during Google Sign-In: $e');
      throw e.toString();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw 'User not found';

    try {
      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') throw 'The current password you entered is incorrect.';
      throw _handleAuthException(e);
    }
  }

  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? recoveryPin,
    String? college,
    String? degree,
    String? currentYear,
    String? passedOutYear,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoURL != null) await user.updatePhotoURL(photoURL);
        
        final firestore = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'intellitrain',
        );
        
        await firestore.collection('users').doc(user.uid).set({
          if (displayName != null) 'fullName': displayName,
          if (recoveryPin != null) 'recoveryPin': recoveryPin,
          if (college != null) 'college': college,
          if (degree != null) 'degree': degree,
          if (currentYear != null) 'currentYear': currentYear,
          if (passedOutYear != null) 'passedOutYear': passedOutYear,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (address != null) 'address': address,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'This operation is sensitive and requires recent authentication. Please log in again before retrying this action.';
      }
      throw _handleAuthException(e);
    }
  }

  Future<Map<String, dynamic>?> getFullProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'intellitrain',
      );
      
      final doc = await firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Error fetching full profile: $e');
      return null;
    }
  }

  Future<String?> getRecoveryPin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'intellitrain',
      );
      
      final doc = await firestore.collection('users').doc(user.uid).get();
      return doc.data()?['recoveryPin'] as String?;
    } catch (e) {
      print('Error fetching recovery PIN: $e');
      return null;
    }
  }

  Future<bool> verifyRecoveryPin(String email, String pin) async {
    try {
      final firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'intellitrain',
      );
      
      final snapshot = await firestore.collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (snapshot.docs.isEmpty) return false;
      
      final userData = snapshot.docs.first.data();
      return userData['recoveryPin'] == pin;
    } catch (e) {
      return false;
    }
  }

  Future<void> updatePasswordWithPin(String email, String newPassword) async {
    // Note: In a production app, this would be a Cloud Function.
    // For this prototype, we guide the user to their profile once logged in.
    // But since they are logged out, we'll use confirmPasswordReset style
    // or simulate a successful reset for the UI demo.
    print('Password reset requested via PIN for $email');
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is failing format validation.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      default:
        return e.message ?? 'An error occurred during authentication.';
    }
  }
}
