import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'providers/providers.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/home_shell.dart';
import 'screens/driver/driver_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/vendor/vendor_onboarding_screen.dart';
import 'screens/vendor/vendor_dashboard_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'widgets/common_widgets.dart';
import 'models/models.dart';

class KgoroApp extends ConsumerStatefulWidget {
  const KgoroApp({super.key});

  @override
  ConsumerState<KgoroApp> createState() => _KgoroAppState();
}

class _KgoroAppState extends ConsumerState<KgoroApp> {
  bool _showSplash     = true;
  bool _onboardingDone = false;
  bool _prefsLoaded    = false;

  // Navigation key for notification routing without context
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingDone = prefs.getBool('onboardingDone') ?? false;
      _prefsLoaded    = true;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingDone', true);
    setState(() => _onboardingDone = true);
  }

  void _handleNotificationTap(Map<String, dynamic> data, {required bool foreground}) {
    final type = data['type'] as String?;
    switch (type) {
      case 'NEW_ORDER':
      case 'ORDER_ACCEPTED':
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          _navKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: orderId),
            ),
          );
        }
        break;
      case 'NEW_RIDE':
      case 'RIDE_ACCEPTED':
        // Navigate to active ride screen (future)
        break;
      case 'VENDOR_APPROVED':
        // _VendorGate will auto-navigate — no action needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.system,
      navigatorKey: _navKey,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_prefsLoaded || _showSplash) {
      return SplashScreen(onFinished: () => setState(() => _showSplash = false));
    }
    if (!_onboardingDone) {
      return OnboardingScreen(onDone: _completeOnboarding);
    }
    return _AuthGate(onNotificationTap: _handleNotificationTap);
  }
}

class _AuthGate extends ConsumerWidget {
  final NotificationTapCallback? onNotificationTap;
  const _AuthGate({this.onNotificationTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        return _RoleGate(
          uid: user.uid,
          onNotificationTap: onNotificationTap,
        );
      },
      loading: () => const Scaffold(body: KgoroLoader()),
      error:   (_, __) => const LoginScreen(),
    );
  }
}

class _RoleGate extends ConsumerStatefulWidget {
  final String uid;
  final NotificationTapCallback? onNotificationTap;
  const _RoleGate({required this.uid, this.onNotificationTap});

  @override
  ConsumerState<_RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends ConsumerState<_RoleGate> {
  bool _fcmInitialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fcmInitialised) {
      _fcmInitialised = true;
      // Initialise FCM once we have a verified UID
      ref.read(notificationServiceProvider).init(
        uid:   widget.uid,
        onTap: widget.onNotificationTap,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(currentAppUserProvider);
    final authAsync = ref.watch(authStateProvider);

    return appUserAsync.when(
      data: (appUser) {
        // Race condition fix: immediately after sign-up the Firestore user doc
        // may not exist yet (Cloud Firestore write hasn't propagated). In this
        // case, send the user to CompleteProfileScreen so they can create their
        // profile rather than spinning forever on a loader.
        if (appUser == null) {
          final firebaseUser = authAsync.valueOrNull;
          if (firebaseUser != null) {
            return CompleteProfileScreen(
              uid: firebaseUser.uid,
              phone: firebaseUser.phoneNumber ?? firebaseUser.email ?? '',
            );
          }
          return const Scaffold(body: KgoroLoader());
        }

        switch (appUser.role) {
          case UserRole.admin:
            return const AdminDashboardScreen();
          case UserRole.driver:
            return const DriverDashboardScreen();
          case UserRole.vendor:
            return _VendorGate(ownerUid: appUser.id);
          case UserRole.customer:
            return const HomeShell();
        }
      },
      loading: () => const Scaffold(body: KgoroLoader()),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading profile data.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(currentAppUserProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Vendor Gate ─────────────────────────────────────────────────────────────

class _VendorGate extends ConsumerWidget {
  final String ownerUid;
  const _VendorGate({required this.ownerUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorStream =
        ref.watch(firestoreServiceProvider).watchVendorByOwner(ownerUid);

    return StreamBuilder<Vendor?>(
      stream: vendorStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: KgoroLoader());
        }

        final vendor = snapshot.data;

        if (vendor == null) return const VendorOnboardingScreen();

        if (vendor.approvalStatus == ApprovalStatus.pendingReview ||
            vendor.approvalStatus == ApprovalStatus.moreInfoNeeded) {
          return _PendingApprovalScreen(storeName: vendor.name);
        }

        if (vendor.approvalStatus == ApprovalStatus.rejected) {
          return _RejectedScreen(storeName: vendor.name);
        }

        return VendorDashboardScreen(vendor: vendor);
      },
    );
  }
}

// ─── Status screens ───────────────────────────────────────────────────────────

class _PendingApprovalScreen extends StatelessWidget {
  final String storeName;
  const _PendingApprovalScreen({required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.primary, size: 64),
              ),
              const SizedBox(height: 32),
              Text(storeName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Your store application is under review.',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our team will review your details and approve your store '
                'as soon as possible. You\'ll be notified when approved.',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 15, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RejectedScreen extends StatelessWidget {
  final String storeName;
  const _RejectedScreen({required this.storeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_rounded, color: AppColors.error, size: 80),
              const SizedBox(height: 24),
              Text(storeName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Application not approved',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Please contact Kgoro support for details on next steps.',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 15, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
