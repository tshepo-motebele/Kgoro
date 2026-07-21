import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/pricing_service.dart';
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
    final subtotal = ref.read(cartProvider.notifier).total;
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
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (context, i) {
                      final item = cart[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.product.name),
                        subtitle: Text('Qty ${item.quantity}'),
                        trailing: Text('R${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFE2ECFB))),
                  ),
                  child: Column(
                    children: [
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
                      _priceRow('Delivery fee', deliveryFee),
                      const Divider(),
                      _priceRow('Total', total, bold: true),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: canCheckout
                            ? () => _placeOrder(subtotal, deliveryFee, total, dropoffLat, dropoffLng)
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

  Widget _priceRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('R${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Future<void> _placeOrder(
      double subtotal, double deliveryFee, double total, double dropoffLat, double dropoffLng) async {
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
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not place order. Check your connection.')),
      );
    }
  }
}
