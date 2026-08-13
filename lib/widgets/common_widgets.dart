import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KgoroStatusPill
// Use for open/closed, order status, approval state, residency verification.
// Color communicates category; label and icon communicate the exact meaning.
// ─────────────────────────────────────────────────────────────────────────────

class KgoroStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const KgoroStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusPill — legacy alias kept so existing screens don't break
// ─────────────────────────────────────────────────────────────────────────────

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) =>
      KgoroStatusPill(label: label, color: color, icon: icon);
}

// ─────────────────────────────────────────────────────────────────────────────
// ResidencyBadge
// ─────────────────────────────────────────────────────────────────────────────

class ResidencyBadge extends StatelessWidget {
  final bool verified;
  final bool pending;
  const ResidencyBadge({super.key, required this.verified, this.pending = false});

  @override
  Widget build(BuildContext context) {
    if (verified) {
      return const KgoroStatusPill(
        label: 'Residency verified',
        color: AppColors.veld,
        icon: Icons.verified_rounded,
      );
    }
    if (pending) {
      return const KgoroStatusPill(
        label: 'Verification in progress',
        color: AppColors.clay,
        icon: Icons.hourglass_top_rounded,
      );
    }
    return const KgoroStatusPill(
      label: 'Verification needed',
      color: AppColors.error,
      icon: Icons.warning_amber_rounded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KgoroPrimaryButton
// Loading-aware button — prevents double-submit, spinner replaces icon.
// ─────────────────────────────────────────────────────────────────────────────

class KgoroPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;

  const KgoroPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              )
            : null,
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
        label: Text(loading ? 'Please wait…' : label),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KgoroEmptyState
// Empty states always explain why and offer a next step.
// ─────────────────────────────────────────────────────────────────────────────

class KgoroEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? lottieUrl;

  const KgoroEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.lottieUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieUrl != null)
              Lottie.network(lottieUrl!, width: 140, height: 140, fit: BoxFit.contain)
            else
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.mountainTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.mountain, size: 36),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Legacy alias ─────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? lottieUrl;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.lottieUrl});

  @override
  Widget build(BuildContext context) => KgoroEmptyState(
        icon: icon,
        title: title,
        message: subtitle,
        lottieUrl: lottieUrl,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KgoroErrorBanner
// Inline error with optional retry action.
// ─────────────────────────────────────────────────────────────────────────────

class KgoroErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const KgoroErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.ink, height: 1.4, fontSize: 13.5),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.ink,
                ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: AppColors.mountain, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KgoroLoader — animated shimmer loader
// ─────────────────────────────────────────────────────────────────────────────

class KgoroLoader extends StatefulWidget {
  const KgoroLoader({super.key});
  @override
  State<KgoroLoader> createState() => _KgoroLoaderState();
}

class _KgoroLoaderState extends State<KgoroLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.mountain.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: AppColors.mountain, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading…',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroGradientHeader — home screen hero (mountain green gradient)
// ─────────────────────────────────────────────────────────────────────────────

class HeroGradientHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final Widget? trailing;
  const HeroGradientHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF174A3A), Color(0xFF1F6B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_rounded,
                        color: Colors.white.withValues(alpha: 0.7), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ActiveOrderCard — shown on home when an order is in progress
// ─────────────────────────────────────────────────────────────────────────────

class ActiveOrderCard extends StatelessWidget {
  final String status;
  final String destination;
  final VoidCallback onTrack;

  const ActiveOrderCard({
    super.key,
    required this.status,
    required this.destination,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174A3A), Color(0xFF1F6B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.mountain.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTrack,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your order is in progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$status · $destination',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Track',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DocumentUploadTile — for driver application doc uploads
// ─────────────────────────────────────────────────────────────────────────────

class DocumentUploadTile extends StatelessWidget {
  final String title;
  final String helper;
  final bool uploaded;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.helper,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = uploaded ? AppColors.veld : AppColors.mountain;
    return Semantics(
      button: true,
      label: uploaded ? '$title uploaded. Tap to replace.' : '$title. $helper',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: uploaded ? AppColors.veld.withValues(alpha: 0.07) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded ? AppColors.veld : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Text(
                      uploaded ? 'Uploaded · Tap to replace' : helper,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedServiceCard — service tile with press animation
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int index;

  const AnimatedServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.index,
  });

  @override
  State<AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<AnimatedServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0,
        upperBound: 0.05);
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredFadeSlide(
      index: widget.index,
      child: Semantics(
        button: true,
        label: '${widget.title}. ${widget.subtitle}',
        child: GestureDetector(
          onTapDown: (_) => _press.forward(),
          onTapUp: (_) {
            _press.reverse();
            widget.onTap();
          },
          onTapCancel: () => _press.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StaggeredFadeSlide — entrance animation for list items
// ─────────────────────────────────────────────────────────────────────────────

class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredFadeSlide({super.key, required this.child, required this.index});

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KgoroShimmerList — used for lists of stores, orders, etc.
// ─────────────────────────────────────────────────────────────────────────────

class KgoroShimmerList extends StatelessWidget {
  final int itemCount;
  const KgoroShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlight = isDark ? Colors.grey[700]! : Colors.grey[50]!;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white, // Needs to be opaque for Shimmer to paint over
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
