import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 1400), onFinished);
    return Scaffold(
      backgroundColor: AppColors.mountain,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.naledi,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.terrain_rounded,
                  color: AppColors.mountain, size: 48),
            ),
            const SizedBox(height: 22),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
