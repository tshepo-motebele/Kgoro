import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles all FCM push notification setup on the client side:
///   1. Request permission (iOS/Android 13+)
///   2. Get token and save it to /fcm_tokens/{uid}
///   3. Listen for foreground messages and show an in-app banner
///   4. Handle notification tap routing (background + terminated)
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db  = FirebaseFirestore.instance;

  /// Call once after the user has signed in.
  Future<void> init({required String uid, NotificationTapCallback? onTap}) async {
    // ── 1. Request permission ──────────────────────────────────────────────────
    if (!kIsWeb) {
      final settings = await _fcm.requestPermission(
        alert:      true,
        badge:      true,
        sound:      true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] User denied notifications');
        return;
      }
    }

    // iOS foreground presentation
    if (!kIsWeb && Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // ── 2. Save token ──────────────────────────────────────────────────────────
    try {
      // Note: On Web, this requires a vapidKey to be passed and a firebase-messaging-sw.js file.
      // We wrap in try-catch to ensure the app doesn't crash on startup if FCM isn't fully configured.
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      debugPrint('[FCM] Failed to get token (push notifications may not work): $e');
    }

    // Refresh on token rotation
    try {
      _fcm.onTokenRefresh.listen((t) => _saveToken(uid, t));

      // ── 3. Foreground messages ─────────────────────────────────────────────────
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[FCM] Foreground: ${message.notification?.title}');
        if (onTap != null) onTap(message.data, foreground: true);
      });

      // ── 4. Background tap (app was in background, user tapped notification) ────
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (onTap != null) onTap(message.data, foreground: false);
      });

      // ── 5. Terminated tap (app was closed, user tapped notification) ───────────
      final initial = await _fcm.getInitialMessage();
      if (initial != null && onTap != null) {
        onTap(initial.data, foreground: false);
      }
    } catch (e) {
      debugPrint('[FCM] Failed to initialize message listeners: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('fcm_tokens').doc(uid).set({
      'token':     token,
      'updatedAt': DateTime.now().toIso8601String(),
      'platform':  kIsWeb ? 'web' : Platform.operatingSystem,
    }, SetOptions(merge: true));
  }
}

/// Callback signature: receives the notification data map and whether the
/// app was in the foreground when it arrived.
typedef NotificationTapCallback = void Function(
  Map<String, dynamic> data, {
  required bool foreground,
});

/// Provider so screens can access the service.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);
