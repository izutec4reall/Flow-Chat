import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await UserService().updateOnlineStatus(uid, false);
    }
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use Firebase Auth popup (avoids OAuth origin & People API issues)
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        // Android/iOS: use GoogleSignIn native plugin
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: e.toString(),
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a user-friendly error message from a FirebaseAuthException
  /// Returns a translation key for the error.
  static String getErrorKey(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'errUserNotFound';
        case 'wrong-password': return 'errWrongPassword';
        case 'email-already-in-use': return 'errEmailInUse';
        case 'weak-password': return 'errWeakPassword';
        case 'invalid-email': return 'errInvalidEmail';
        case 'too-many-requests': return 'errTooManyRequests';
      case 'network-request-failed': return 'errNetwork';
      case 'invalid-credential': return 'errInvalidCredential';
      case 'google-sign-in-failed': return 'errGoogleSignInFailed';
      case 'sign_in_canceled': return 'errGoogleSignInCanceled';
      default: return 'errUnknown';
      }
    }
    return 'errUnknown';
  }
}

