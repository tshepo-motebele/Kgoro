import 'package:flutter/material.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  int _page = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.storefront_rounded,
      accent: Color(0xFF198754),
      title: 'Groceries, Food & Rides',
      body:
          'Everything you need from local Thaba Nchu shops and kitchens — delivered to your door.',
    ),
    _SlideData(
      icon: Icons.local_bar_rounded,
      accent: Color(0xFF6B3FA0),
      title: 'Liquor Delivered Responsibly',
      body:
          'Order your favourite drinks from local licensed stores. You must be 18+ and will be age-verified at delivery.',
    ),
    _SlideData(
      icon: Icons.local_taxi_rounded,
      accent: Color(0xFFB9681E),
      title: 'Rides Around Town',
      body:
          'Need to get somewhere? Book a cab from verified local drivers in Thaba Nchu — fast and fair.',
    ),
    _SlideData(
      icon: Icons.handshake_rounded,
      accent: AppColors.mountain,
      title: 'Earn with Kgoro',
      body:
          'No experience needed. Walk, cycle, or drive. Our fair-match system spreads jobs across all drivers equally.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _iconScale = CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack);
    _iconFade = CurvedAnimation(parent: _iconController, curve: Curves.easeIn);
    _iconController.forward();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _iconController.reset();
    _iconController.forward();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand mark
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.mountainTint,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/images/kgoro_logo_blue.png'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Kgoro',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.mountain,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  // Skip — quiet but tappable
                  GestureDetector(
                    onTap: widget.onDone,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.mountainTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.mountain,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => _SlideView(
                  data: _slides[i],
                  iconScale: _iconScale,
                  iconFade: _iconFade,
                  isCurrent: i == _page,
                ),
              ),
            ),

            // ── Dots + counter ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(_slides.length, (i) {
                    final active = _page == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.mountain : AppColors.line,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                  const SizedBox(width: 14),
                  Text(
                    '${_page + 1} of ${_slides.length}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── CTA button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(
                    _page == _slides.length - 1 ? 'Get started' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ),

            // Trust line on last slide
            if (_page == _slides.length - 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Built for local customers, stores, and drivers.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  const _SlideData({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });
}

class _SlideView extends StatelessWidget {
  final _SlideData data;
  final Animation<double> iconScale;
  final Animation<double> iconFade;
  final bool isCurrent;

  const _SlideView({
    required this.data,
    required this.iconScale,
    required this.iconFade,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon — scale + fade, no emoji
          FadeTransition(
            opacity: iconFade,
            child: ScaleTransition(
              scale: iconScale,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: Icon(data.icon, size: 76, color: data.accent),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(height: 14),

          // Body
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
