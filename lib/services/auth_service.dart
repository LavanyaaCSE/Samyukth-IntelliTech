import 'package:firebase_auth/firebase_auth.dart';
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

  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      print('📝 Attempting to sign up with email: $email');
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Update display name
      if (result.user != null) {
        await result.user!.updateDisplayName(fullName);
        await result.user!.reload(); // Reload user to get updated info
        print('👤 Display name updated to: $fullName');
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
