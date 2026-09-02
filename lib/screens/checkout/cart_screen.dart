import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/pricing_service.dart';
import '../../widgets/common_widgets.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  final Vendor vendor;
  const CartScreen({super.key, required this.vendor});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String? _dropoffArea;
  bool _placing = false;
  bool _ageConfirmed = false; // 18+ check for liquor orders

  bool get _isLiquorOrder => widget.vendor.type == ServiceType.liquor;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your cart')),
        body: const KgoroEmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          message: 'Add some items from the menu and they will appear here.',
        ),
      );
    }

    // Compute subtotal reactively from the watched cart
    final subtotal = cart.fold<double>(0, (sum, c) => sum + c.subtotal);

    final dropoffCoords = AppConstants.areaCoordinates[_dropoffArea] ??
        [AppConstants.townCentreLat, AppConstants.townCentreLng];
    final dropoffLat = dropoffCoords[0];
    final dropoffLng = dropoffCoords[1];

    final deliveryFee = _dropoffArea == null
        ? 0.0
        : PricingService.estimateDeliveryFee(
            type: widget.vendor.type,
            vendorLat: widget.vendor.lat,
            vendorLng: widget.vendor.lng,
            dropoffLat: dropoffLat,
            dropoffLng: dropoffLng,
          );
    final total = subtotal + deliveryFee;

    final bool canCheckout = !_placing &&
        _dropoffArea != null &&
        (!_isLiquorOrder || _ageConfirmed);

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: cart.length,
              itemBuilder: (context, i) {
                final item = cart[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'R${item.product.price.toStringAsFixed(2)} each',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // ── Quantity stepper ──────────────────────────────
                        Row(
                          children: [
                            _StepperButton(
                              icon: Icons.remove_rounded,
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(item.product.id, item.quantity - 1),
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                            _StepperButton(
                              icon: Icons.add_rounded,
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(item.product.id, item.quantity + 1),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // ── Line total ────────────────────────────────────
                        Text(
                          'R${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Colors.white,
              border: const Border(
                  top: BorderSide(color: Color(0xFFE2ECFB))),
            ),
            child: Column(
              children: [
                // ── Dropoff area picker ─────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _dropoffArea,
                  decoration: const InputDecoration(
                    labelText: 'Deliver to which area?',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  items: AppConstants.localAreas
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _dropoffArea = v),
                ),

                // ── Liquor age-verification (§7.4 / South African law) ──
                if (_isLiquorOrder) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _ageConfirmed,
                          activeColor: AppColors.primary,
                          onChanged: (v) =>
                              setState(() => _ageConfirmed = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 13, height: 1.5),
                                children: [
                                  TextSpan(
                                    text:
                                        'I confirm that I am 18 years or older. ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark),
                                  ),
                                  TextSpan(
                                    text:
                                        'The sale of alcohol to persons under 18 is prohibited in South Africa (Liquor Act 59 of 2003).',
                                    style: TextStyle(
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                _priceRow('Subtotal', subtotal),
                _priceRow(
                  'Delivery fee',
                  deliveryFee,
                  note: _dropoffArea == null ? '(select area)' : null,
                ),
                const Divider(),
                _priceRow('Total', total, bold: true),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: canCheckout
                      ? () => _placeOrder(subtotal, deliveryFee, total,
                          dropoffLat, dropoffLng)
                      : null,
                  child: _placing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Place order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double value,
      {bool bold = false, String? note}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: style),
              if (note != null) ...[
                const SizedBox(width: 4),
                Text(note,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ],
          ),
          Text('R${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Future<void> _placeOrder(double subtotal, double deliveryFee, double total,
      double dropoffLat, double dropoffLng) async {
    setState(() => _placing = true);
    final cart = ref.read(cartProvider);
    final user = ref.read(currentAppUserProvider).value;

    final orderData = {
      'customerId': user?.id ?? 'demo',
      'type': widget.vendor.type.index,
      'vendorId': widget.vendor.id,
      'items': cart
          .map((c) => {
                'productId': c.product.id,
                'name': c.product.name,
                'qty': c.quantity,
                'price': c.product.price,
              })
          .toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'dropoffArea': _dropoffArea,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'status': OrderStatus.pending.index,
      'createdAt': DateTime.now().toIso8601String(),
      if (_isLiquorOrder) 'ageVerified': true,
    };

    try {
      final ref2 = await ref.read(firestoreServiceProvider).createOrder(orderData);
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              OrderConfirmationScreen(orderId: ref2.id, total: total),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not place order. Check your connection.')),
        );
      }
    }
  }
}

// ── Small stepper button ──────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mountainTint,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.mountain),
        ),
      ),
    );
  }
}
