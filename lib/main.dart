import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'firebase_options.dart';

/// FCM background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Keep minimal — don't access UI here. Store in local DB if needed.
  debugPrint('[FCM] Background message: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before anything else
  await dotenv.load(fileName: '.env');

  // Initialise Firebase
  // NOTE: firebase_options.dart must be generated with `flutterfire configure`
  // using your own Firebase project credentials. See BUILD_INSTRUCTIONS.md.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Crashlytics global error handler ─────────────────────────────────────────
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Analytics ─────────────────────────────────────────────────────────────────
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // ── FCM background handler (must register before runApp) ─────────────────────
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  runApp(const ProviderScope(child: KgoroApp()));
}
