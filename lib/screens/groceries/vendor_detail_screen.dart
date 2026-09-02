import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import '../checkout/cart_screen.dart';

class VendorDetailScreen extends ConsumerWidget {
  final Vendor vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use watch so the FAB re-renders when cart changes
    final cart = ref.watch(cartProvider);
    final cartTotal = cart.fold<double>(0, (sum, c) => sum + c.subtotal);
    final productsStream =
        ref.watch(firestoreServiceProvider).watchVendorProducts(vendor.id);

    return Scaffold(
      appBar: AppBar(title: Text(vendor.name)),
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroShimmerList();
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products listed',
              subtitle: 'This vendor has not added any products yet.',
              lottieUrl: 'https://assets9.lottiefiles.com/packages/lf20_x62chj8y.json',
            );
          }

          // Group products by category, preserving insertion order
          final categories = products.map((p) => p.category).toSet().toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Vendor banner ───────────────────────────────────────────
              Hero(
                tag: 'vendor_image_${vendor.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: AppColors.veld.withValues(alpha: 0.12),
                    child: vendor.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: vendor.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                size: 48,
                                color: AppColors.veld),
                          )
                        : const Icon(Icons.storefront_rounded,
                            size: 48, color: AppColors.veld),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Product sections ────────────────────────────────────────
              for (final category in categories) ...[
                SectionHeader(
                    title: category.isNotEmpty ? category : 'Products'),
                ...products
                    .where((p) => p.category == category)
                    .map((p) => _ProductRow(product: p)),
              ],
              const SizedBox(height: 100), // space for FAB
            ],
          );
        },
      ),
      // ── Cart FAB — reactive via ref.watch above ──────────────────────────
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.mountain,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartScreen(vendor: vendor),
                ),
              ),
              icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
              label: Text(
                'View cart · R${cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final matches = cart.where((c) => c.product.id == product.id);
    final inCart = matches.isEmpty ? null : matches.first;

    final outOfStock = !product.inStock;

    return Opacity(
      opacity: outOfStock ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // ── Product image ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: const Color(0xFFF3EEE6),
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.image_not_supported_rounded,
                            color: AppColors.muted),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name & price ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (outOfStock)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.muted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'R${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            // ── Add / stepper ──────────────────────────────────────────────
            if (outOfStock)
              const SizedBox.shrink()
            else if (inCart == null)
              OutlinedButton(
                onPressed: () =>
                    ref.read(cartProvider.notifier).addProduct(product),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(72, 36)),
                child: const Text('Add'),
              )
            else
              Row(
                children: [
                  _MiniStepperButton(
                    icon: Icons.remove_rounded,
                    onTap: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(product.id, inCart.quantity - 1),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${inCart.quantity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _MiniStepperButton(
                    icon: Icons.add_rounded,
                    onTap: () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(product.id, inCart.quantity + 1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniStepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.mountainTint,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.mountain.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: AppColors.mountain),
      ),
    );
  }
}
