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
    final cart = ref.watch(cartProvider);
    final productsStream = ref.watch(firestoreServiceProvider).watchVendorProducts(vendor.id);

    return Scaffold(
      appBar: AppBar(title: Text(vendor.name)),
      body: StreamBuilder<List<Product>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KgoroLoader();
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products listed',
              subtitle: 'This vendor has not added any products yet.',
            );
          }

          final categories = products.map((p) => p.category).toSet().toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final category in categories) ...[
                SectionHeader(title: category.isNotEmpty ? category : 'Products'),
                ...products
                    .where((p) => p.category == category)
                    .map((p) => _ProductRow(product: p)),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
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
                'View cart · R${ref.read(cartProvider.notifier).total.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('R${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          if (inCart == null)
            OutlinedButton(
              onPressed: () => ref.read(cartProvider.notifier).addProduct(product),
              style: OutlinedButton.styleFrom(minimumSize: const Size(72, 36)),
              child: const Text('Add'),
            )
          else
            Row(
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(product.id, inCart.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.mountain,
                ),
                Text('${inCart.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .updateQuantity(product.id, inCart.quantity + 1),
                  icon: const Icon(Icons.add_circle_rounded),
                  color: AppColors.mountain,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
