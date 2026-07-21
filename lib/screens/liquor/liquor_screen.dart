import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../groceries/vendor_detail_screen.dart';

class LiquorScreen extends ConsumerStatefulWidget {
  const LiquorScreen({super.key});
  @override
  ConsumerState<LiquorScreen> createState() => _LiquorScreenState();
}

class _LiquorScreenState extends ConsumerState<LiquorScreen> {
  bool _ageVerified = false;

  @override
  void initState() {
    super.initState();
    // Show verification dialog on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAgeVerification();
    });
  }

  Future<void> _showAgeVerification() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AgeVerificationDialog(),
    );
    if (result == true) {
      setState(() => _ageVerified = true);
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsStream =
        ref.watch(firestoreServiceProvider).watchVendorsByType(ServiceType.liquor);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A1A7A), Color(0xFF6B3FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('18+ Verified', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.local_bar_rounded, color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Liquor Stores',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
                              Text('Local licensed stores, delivered',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: !_ageVerified
                ? const SizedBox()
                : StreamBuilder<List<Vendor>>(
                    stream: vendorsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const KgoroLoader();
                      }
                      final vendors = snapshot.data ?? [];
                      if (vendors.isEmpty) {
                        return const EmptyState(
                          icon: Icons.local_bar_outlined,
                          title: 'No liquor stores yet',
                          subtitle: 'Licensed liquor stores in Thaba Nchu are being onboarded. Check back soon!',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vendors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => StaggeredFadeSlide(
                          index: i,
                          child: _LiquorVendorCard(vendor: vendors[i]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Age Verification Dialog ─────────────────────────────────────────────────

class _AgeVerificationDialog extends StatelessWidget {
  const _AgeVerificationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top graphic
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A1A7A), Color(0xFF6B3FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.local_bar_rounded, color: Colors.white, size: 52),
                  SizedBox(height: 10),
                  Text('18+', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  Text('Age Verification Required', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  const Text(
                    'This section contains alcoholic beverages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You must be 18 years or older to access this section. By continuing, you confirm that you are of legal drinking age.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3FA0),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('I am 18 or older — Continue',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('I am under 18 — Go back',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Liquor Vendor Card ───────────────────────────────────────────────────────

class _LiquorVendorCard extends StatelessWidget {
  final Vendor vendor;
  const _LiquorVendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFEBECF0)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6B3FA0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                image: vendor.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(vendor.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: vendor.imageUrl.isEmpty
                  ? const Icon(Icons.local_bar_rounded,
                      color: Color(0xFF6B3FA0))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(vendor.localArea,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFF991F)),
                      Text(' ${vendor.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            StatusPill(
              label: vendor.isOpen ? 'Open' : 'Closed',
              color: vendor.isOpen ? AppColors.success : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
