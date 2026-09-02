import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'vendor_detail_screen.dart';

class GroceriesScreen extends ConsumerWidget {
  const GroceriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsStream =
        ref.watch(firestoreServiceProvider).watchVendorsByType(ServiceType.groceries);

    return Scaffold(
      appBar: AppBar(title: const Text('Groceries')),
      body: StreamBuilder<List<Vendor>>(
        stream: vendorsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroShimmerList();
          }
          final unsorted = snapshot.data ?? [];
          if (unsorted.isEmpty) {
            return const EmptyState(
              icon: Icons.local_grocery_store_outlined,
              title: 'No grocery shops yet',
              subtitle:
                  'Local shops in Thaba Nchu are being onboarded. Check back soon, or ask your favourite shop to sign up.',
              lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_x62chj8y.json',
            );
          }

          // Sort: open stores first, then alphabetically within each group
          final vendors = [...unsorted]
            ..sort((a, b) {
              if (a.isOpen == b.isOpen) {
                return a.name.compareTo(b.name);
              }
              return a.isOpen ? -1 : 1;
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _VendorCard(vendor: vendors[i]),
          );
        },
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isClosed = !vendor.isOpen;

    return Opacity(
      opacity: isClosed ? 0.62 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isClosed
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${vendor.name} is currently closed.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            : () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => VendorDetailScreen(vendor: vendor)),
                ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Store image ─────────────────────────────────────────
                Hero(
                  tag: 'vendor_image_${vendor.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.veld.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: vendor.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: vendor.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.veld),
                            )
                          : const Icon(Icons.storefront_rounded,
                              color: AppColors.veld),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Name + area + rating ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vendor.localArea,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.naledi),
                          Text(
                            ' ${vendor.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Open/closed pill ────────────────────────────────────
                StatusPill(
                  label: vendor.isOpen ? 'Open' : 'Closed',
                  color: vendor.isOpen ? AppColors.success : AppColors.muted,
                  icon: vendor.isOpen
                      ? Icons.check_circle_rounded
                      : Icons.do_not_disturb_on_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
