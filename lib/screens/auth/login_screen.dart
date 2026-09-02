import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/kgoro_logo_blue.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                tabs: [
                  Tab(text: 'Log In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _LoginForm(),
                    _SignUpForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();
  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ref.read(authServiceProvider).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // Success is handled by authState provider reloading in main shell.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authErrorMessage(e.code))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign in. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email. Please sign up.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Sign in failed: ${code.replaceAll('-', ' ')}.';
    }
  }

  Future<void> _showForgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: emailCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password reset email sent. Check your inbox.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your details to log into your account.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email or Phone',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (v) => v != null && v.isNotEmpty ? null : 'Required field',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v != null && v.isNotEmpty ? null : 'Required field',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm();
  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;

  bool _isPhone(String value) =>
      value.startsWith('+') || RegExp(r'^0[6-8]\d').hasMatch(value);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final contact = _contactController.text.trim();

    if (_isPhone(contact)) {
      // ── Phone sign-up flow ─────────────────────────────────────────────
      // Normalise: South African numbers starting with 0 become +27...
      final e164 = contact.startsWith('+')
          ? contact
          : '+27${contact.substring(1)}';
      try {
        await ref.read(authServiceProvider).sendOtp(
          phoneNumber: e164,
          onCodeSent: (verificationId) {
            if (!mounted) return;
            setState(() => _loading = false);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _OtpScreen(
                  verificationId: verificationId,
                  fullName: _nameController.text.trim(),
                  phone: e164,
                ),
              ),
            );
          },
          onFailed: (e) {
            if (!mounted) return;
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_phoneErrorMessage(e.code))),
            );
          },
          onAutoVerified: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not send verification code. Check your number.')),
          );
        }
      }
    } else {
      // ── Email sign-up flow ──────────────────────────────────────────────
      try {
        final credential = await ref.read(authServiceProvider).registerWithEmail(
              contact,
              _passwordController.text,
            );
        if (credential.user != null) {
          final newUser = AppUser(
            id: credential.user!.uid,
            fullName: _nameController.text.trim(),
            phone: '',
            localArea: 'Thaba Nchu Town Centre',
            role: UserRole.customer,
            createdAt: DateTime.now(),
          );
          await ref.read(firestoreServiceProvider).upsertUser(newUser);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_emailErrorMessage(e.code))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to create account. Please try again.')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String _emailErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Sign up failed: ${code.replaceAll('-', ' ')}.';
    }
  }

  String _phoneErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format +27820000000.';
      case 'too-many-requests':
        return 'Too many verification attempts. Try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try email sign-up instead.';
      default:
        return 'Phone verification failed: ${code.replaceAll('-', ' ')}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create an account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'Join ${AppConstants.appName} to get started.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBDD6F5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1E6FDB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All accounts start as Customer. Switch to Driver or Vendor from the app after sign-up.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0D2C54)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => v != null && v.isNotEmpty ? null : 'Required field',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Email or Phone (+27...)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
                helperText: 'For phone, use format +27820000000',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required field';
                if (!v.contains('@')) {
                  // Phone validation
                  final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
                  if (!phoneRegex.hasMatch(v)) {
                    return 'Must be valid E.164 format (e.g. +27...)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v != null && v.length >= 6 ? null : 'Minimum 6 characters',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'By signing up, you agree to our Terms of Service.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── OTP verification screen ───────────────────────────────────────────────────

class _OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String fullName;
  final String phone;
  const _OtpScreen({
    required this.verificationId,
    required this.fullName,
    required this.phone,
  });

  @override
  ConsumerState<_OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<_OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code from your SMS.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await ref.read(authServiceProvider).confirmOtp(
            verificationId: widget.verificationId,
            smsCode: code,
          );
      if (credential.user != null) {
        final newUser = AppUser(
          id: credential.user!.uid,
          fullName: widget.fullName,
          phone: widget.phone,
          localArea: 'Thaba Nchu Town Centre',
          role: UserRole.customer,
          createdAt: DateTime.now(),
        );
        await ref.read(firestoreServiceProvider).upsertUser(newUser);
      }
      // authStateProvider fires — app will navigate automatically
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'invalid-verification-code'
                  ? 'Incorrect code. Check the SMS and try again.'
                  : 'Verification failed: ${e.code.replaceAll("-", " ")}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code sent to ${widget.phone}',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                prefixIcon: Icon(Icons.sms_rounded),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4))
                  : const Text('Verify & Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
