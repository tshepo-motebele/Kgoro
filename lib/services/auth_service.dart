import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

/// Thin wrapper around FirebaseAuth. Phone OTP is the primary sign-in
/// method (matches how most people in Thaba Nchu will have a mobile
/// number but not necessarily an email they check) with email/password
/// as a fallback for vendors/admins.
///
/// NOTE: Requires Firebase Phone Auth to be enabled in the Firebase
/// console, and (for Android) SHA-1/SHA-256 fingerprints registered for
/// silent reCAPTCHA verification. See README "Firebase & keys setup".
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sends a phone OTP. Uses a [Completer] so that top-level network
  /// errors (thrown before any callback fires) are propagated to the
  /// caller instead of being silently swallowed.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(UserCredential credential) onAutoVerified,
  }) {
    final completer = Completer<void>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          onAutoVerified(result);
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (e) {
        onFailed(e);
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, resendToken) {
        onCodeSent(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {},
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  Future<UserCredential> confirmOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  /// Signs out the current user, deleting their FCM token first so no
  /// further push notifications are routed to this device.
  /// Token deletion is best-effort — if it fails, sign-out still proceeds.
  Future<void> signOutAndCleanup() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.deleteToken(uid);
      } catch (_) {
        // Token deletion is non-critical; proceed with sign-out regardless.
      }
    }
    await _auth.signOut();
  }

  /// Legacy sign-out without cleanup — prefer [signOutAndCleanup] in UI.
  Future<void> signOut() => _auth.signOut();
}
