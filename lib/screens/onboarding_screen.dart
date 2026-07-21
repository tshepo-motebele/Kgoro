import 'package:flutter/material.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _controller = PageController();
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  int _page = 0;

  final _slides = const [
    _SlideData(
      icon: Icons.storefront_rounded,
      color: Color(0xFF0052CC),
      title: 'Groceries, Food & Rides',
      body: 'Everything you need from local Thaba Nchu shops and kitchens — delivered to your door.',
      badge: '🛒',
    ),
    _SlideData(
      icon: Icons.local_bar_rounded,
      color: Color(0xFF6B3FA0),
      title: 'Liquor Delivered Responsibly',
      body: 'Order your favourite drinks from local licensed liquor stores. You must be 18+ and will be age-verified at delivery.',
      badge: '🍺',
    ),
    _SlideData(
      icon: Icons.local_taxi_rounded,
      color: Color(0xFFFF991F),
      title: 'Rides Around Town',
      body: 'Need to get somewhere? Book a cab from verified local drivers in Thaba Nchu, fast and fair.',
      badge: '🚕',
    ),
    _SlideData(
      icon: Icons.handshake_rounded,
      color: Color(0xFF00875A),
      title: 'Earn with Kgoro',
      body: 'No experience needed. Walk, cycle, or drive. Our fair-match system spreads jobs across all drivers equally.',
      badge: '💰',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);
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

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mountain.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: AppColors.mountain, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text('Kgoro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.mountain, letterSpacing: -0.5)),
                    ],
                  ),
                  TextButton(
                    onPressed: widget.onDone,
                    child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => _SlideView(
                  data: _slides[i],
                  iconScale: _iconScale,
                  isCurrent: i == _page,
                ),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? slide.color : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: slide.color,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    widget.onDone();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Text(
                  _page == _slides.length - 1 ? "Let's get started!" : 'Next',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String badge;
  const _SlideData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.badge,
  });
}

class _SlideView extends StatelessWidget {
  final _SlideData data;
  final Animation<double> iconScale;
  final bool isCurrent;
  const _SlideView({required this.data, required this.iconScale, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: iconScale,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(data.icon, size: 72, color: data.color),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Text(data.badge, style: const TextStyle(fontSize: 28)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text(data.body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5)),
        ],
      ),
    );
  }
}
