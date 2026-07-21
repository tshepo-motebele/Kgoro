import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'complete_profile_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  const OtpScreen(
      {super.key, required this.verificationId, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await ref.read(authServiceProvider).confirmOtp(
            verificationId: widget.verificationId,
            smsCode: _codeController.text.trim(),
          );
      if (!mounted) return;
      final firestore = ref.read(firestoreServiceProvider);
      final existing = await firestore.watchUser(credential.user!.uid).first;
      if (!mounted) return;
      if (existing == null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            uid: credential.user!.uid,
            phone: widget.phoneNumber,
          ),
        ));
      } else {
        // main.dart's auth listener will route to Home automatically.
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _error = 'Incorrect code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify number')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We sent a code to ${widget.phoneNumber}',
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                errorText: _error,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 22, letterSpacing: 6),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
