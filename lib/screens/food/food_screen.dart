import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../groceries/vendor_detail_screen.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsStream =
        ref.watch(firestoreServiceProvider).watchVendorsByType(ServiceType.food);

    return Scaffold(
      appBar: AppBar(title: const Text('Food')),
      body: StreamBuilder<List<Vendor>>(
        stream: vendorsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroLoader();
          }
          final vendors = snapshot.data ?? [];
          if (vendors.isEmpty) {
            return const EmptyState(
              icon: Icons.ramen_dining_outlined,
              title: 'No kitchens yet',
              subtitle:
                  'Local kitchens and takeaways in Thaba Nchu are being onboarded. Check back soon!',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = vendors[i];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: v)),
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
                            color: AppColors.mountain.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            image: v.imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(v.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: v.imageUrl.isEmpty
                              ? const Icon(Icons.ramen_dining_rounded, color: AppColors.mountain)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(v.localArea,
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: v.isOpen ? 'Open' : 'Closed',
                          color: v.isOpen ? AppColors.success : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
