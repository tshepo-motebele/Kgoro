import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'driver_application_screen.dart';

class BecomeDriverIntroScreen extends StatelessWidget {
  const BecomeDriverIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earn with Kgoro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A real income opportunity for Thaba Nchu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'Kgoro was built to create work for local people — including those without formal qualifications. You don\'t need a car to start.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
            const _Requirement(
              icon: Icons.directions_walk_rounded,
              title: 'Any way you can move',
              body: 'On foot, bicycle, motorbike, car or bakkie — we match jobs to what you have.',
            ),
            const _Requirement(
              icon: Icons.badge_outlined,
              title: 'Proof you live in Thaba Nchu',
              body: 'A valid SA ID and proof of address (municipal bill, Kgotla/ward letter, or similar).',
            ),
            const _Requirement(
              icon: Icons.groups_rounded,
              title: 'Two people to vouch for you',
              body: 'Ask two verified Kgoro users from your area to vouch for your application — this speeds up approval.',
            ),
            const _Requirement(
              icon: Icons.balance_rounded,
              title: 'Fair job matching',
              body: 'Our system shares jobs across all active drivers instead of only the busiest few — everyone gets a real chance to earn.',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverApplicationScreen()),
              ),
              child: const Text('Start application'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Requirement({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.naledi.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mountain, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
