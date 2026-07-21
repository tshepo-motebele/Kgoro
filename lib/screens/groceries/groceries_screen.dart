import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
            return const KgoroLoader();
          }
          final vendors = snapshot.data ?? [];
          if (vendors.isEmpty) {
            return const EmptyState(
              icon: Icons.local_grocery_store_outlined,
              title: 'No grocery shops yet',
              subtitle:
                  'Local shops in Thaba Nchu are being onboarded. Check back soon, or ask your favourite shop to sign up.',
            );
          }
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.veld.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  image: vendor.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(vendor.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vendor.imageUrl.isEmpty
                    ? const Icon(Icons.storefront_rounded, color: AppColors.veld)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(vendor.localArea,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.naledi),
                        Text(' ${vendor.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}
