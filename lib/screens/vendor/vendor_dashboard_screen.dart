import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';
import 'product_edit_screen.dart';

/// Full vendor dashboard with 3 tabs: Orders, Menu/Products, Store Settings.
class VendorDashboardScreen extends ConsumerStatefulWidget {
  final Vendor vendor;
  const VendorDashboardScreen({super.key, required this.vendor});

  @override
  ConsumerState<VendorDashboardScreen> createState() =>
      _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.vendor.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primaryDark)),
            Text(
            widget.vendor.type == ServiceType.groceries
                  ? 'Groceries'
                  : widget.vendor.type == ServiceType.food
                      ? 'Fast Food'
                      : widget.vendor.type == ServiceType.liquor
                          ? 'Liquor'
                          : widget.vendor.type == ServiceType.cab
                              ? 'Cab / Rides'
                              : 'Laundry',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: const [
          SignOutIconButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Orders'),
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Menu'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersTab(vendor: widget.vendor),
          _MenuTab(vendor: widget.vendor),
          _SettingsTab(vendor: widget.vendor),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ORDERS TAB
// ---------------------------------------------------------------------------

class _OrdersTab extends ConsumerWidget {
  final Vendor vendor;
  const _OrdersTab({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream =
        ref.watch(firestoreServiceProvider).watchVendorOrders(vendor.id);

    return StreamBuilder<List<KgoroOrder>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const KgoroLoader();
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No orders yet',
            subtitle: 'New orders will appear here in real time.',
          );
        }

        // Group by status for better UX
        final newOrders =
            orders.where((o) => o.status == OrderStatus.pending).toList();
        final activeOrders = orders
            .where((o) =>
                o.status == OrderStatus.matched ||
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.pickedUp ||
                o.status == OrderStatus.onTheWay)
            .toList();
        final doneOrders = orders
            .where((o) =>
                o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (newOrders.isNotEmpty) ...[
              _groupHeader('🔔 New Orders', AppColors.warning),
              ...newOrders.map((o) => _OrderCard(order: o, vendorId: vendor.id)),
              const SizedBox(height: 16),
            ],
            if (activeOrders.isNotEmpty) ...[
              _groupHeader('🚀 In Progress', AppColors.primary),
              ...activeOrders.map((o) => _OrderCard(order: o, vendorId: vendor.id)),
              const SizedBox(height: 16),
            ],
            if (doneOrders.isNotEmpty) ...[
              _groupHeader('✅ Completed / Cancelled', AppColors.success),
              ...doneOrders.map((o) => _OrderCard(order: o, vendorId: vendor.id)),
            ],
          ],
        );
      },
    );
  }

  Widget _groupHeader(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      );
}

class _OrderCard extends ConsumerWidget {
  final KgoroOrder order;
  final String vendorId;
  const _OrderCard({required this.order, required this.vendorId});

  static const _nextStatus = {
    OrderStatus.pending: OrderStatus.accepted,
    OrderStatus.accepted: OrderStatus.pickedUp,
    OrderStatus.pickedUp: OrderStatus.onTheWay,
    OrderStatus.onTheWay: OrderStatus.delivered,
  };

  static const _nextLabel = {
    OrderStatus.pending: 'Mark as Preparing',
    OrderStatus.accepted: 'Ready for pickup',
    OrderStatus.pickedUp: 'Out for delivery',
    OrderStatus.onTheWay: 'Mark Delivered',
  };

  static const _statusLabel = {
    OrderStatus.pending: 'New',
    OrderStatus.matched: 'Matched',
    OrderStatus.accepted: 'Preparing',
    OrderStatus.pickedUp: 'Ready',
    OrderStatus.onTheWay: 'On the way',
    OrderStatus.delivered: 'Delivered',
    OrderStatus.cancelled: 'Cancelled',
  };

  static const _statusColor = {
    OrderStatus.pending: AppColors.warning,
    OrderStatus.matched: AppColors.primaryLight,
    OrderStatus.accepted: AppColors.primary,
    OrderStatus.pickedUp: AppColors.primary,
    OrderStatus.onTheWay: AppColors.success,
    OrderStatus.delivered: AppColors.success,
    OrderStatus.cancelled: AppColors.error,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = _nextStatus[order.status];
    final nextLabel = _nextLabel[order.status];
    final statusLabel = _statusLabel[order.status] ?? 'Unknown';
    final statusColor = _statusColor[order.status] ?? AppColors.textMuted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDark),
                ),
                StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} item(s) · R${order.total.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            Text(
              'Drop-off: ${order.dropoffArea}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ...order.items.map(
              (i) => Text(
                '  • ${i['name']} × ${i['qty']}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            if (next != null && nextLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(firestoreServiceProvider)
                      .updateOrderStatus(order.id, next),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(nextLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MENU / PRODUCTS TAB
// ---------------------------------------------------------------------------

class _MenuTab extends ConsumerWidget {
  final Vendor vendor;
  const _MenuTab({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsStream =
        ref.watch(firestoreServiceProvider).watchVendorProducts(vendor.id);

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const KgoroLoader();
        }
        final products = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProductEditScreen(vendorId: vendor.id, product: null),
              ),
            ),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Product',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          body: products.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_rounded,
                  title: 'No products yet',
                  subtitle: 'Tap the + button below to add your first product.',
                )
              : Column(
                  children: [
                    // CSV import hint bar
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBDD6F5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Have many products? Import a CSV (name, price, qty, sku).',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showCsvImport(context, ref, vendor.id),
                            child: const Text('Import',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _ProductTile(product: products[i], vendorId: vendor.id),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showCsvImport(
      BuildContext context, WidgetRef ref, String vendorId) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste CSV data',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            const Text(
              'Format: name, category, price, quantity, sku (one per line)\n'
              'Example: Bread, Bakery, 15.99, 50, SKU001',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste CSV rows here…',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _importCsv(ctrl.text.trim(), ref, vendorId, context);
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCsv(String csv, WidgetRef ref, String vendorId,
      BuildContext context) async {
    if (csv.isEmpty) return;
    final lines = csv
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    int imported = 0;
    for (final line in lines) {
      final parts = line.split(',').map((p) => p.trim()).toList();
      if (parts.length < 3) continue;
      final name = parts[0];
      final category = parts.length > 1 ? parts[1] : '';
      final price = double.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
      final qty = int.tryParse(parts.length > 3 ? parts[3] : '0') ?? 0;
      final sku = parts.length > 4 ? parts[4] : null;
      if (name.isEmpty) continue;
      await ref.read(firestoreServiceProvider).addProduct(vendorId, {
        'name': name,
        'category': category,
        'price': price,
        'quantity': qty,
        'imageUrl': '',
        if (sku != null) 'sku': sku,
        'lowStockThreshold': 5,
      });
      imported++;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported product(s).')),
      );
    }
  }
}

class _ProductTile extends ConsumerWidget {
  final Product product;
  final String vendorId;
  const _ProductTile({required this.product, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: product.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product.imageUrl, fit: BoxFit.cover),
                )
              : const Icon(Icons.image_rounded,
                  color: AppColors.primaryLight, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 14)),
            ),
            if (product.isLowStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Low stock',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            if (!product.inStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Out of stock',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        subtitle: Text(
          'R${product.price.toStringAsFixed(2)} · Qty: ${product.quantity}'
          '${product.sku != null ? ' · SKU: ${product.sku}' : ''}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          onSelected: (action) {
            if (action == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductEditScreen(
                      vendorId: vendorId, product: product),
                ),
              );
            } else if (action == 'delete') {
              _confirmDelete(context, ref);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(firestoreServiceProvider)
                  .deleteProduct(vendorId, product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SETTINGS TAB
// ---------------------------------------------------------------------------

class _SettingsTab extends ConsumerStatefulWidget {
  final Vendor vendor;
  const _SettingsTab({required this.vendor});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late bool _isOpen;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;
  File? _bannerFile;

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _bannerFile = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    _isOpen = widget.vendor.isOpen;
    _phoneController.text = widget.vendor.contactPhone ?? '';
    _addressController.text = widget.vendor.address ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String newImageUrl = widget.vendor.imageUrl;

      if (_bannerFile != null) {
        final ref = FirebaseStorage.instance
            .ref('vendors/${widget.vendor.id}/banner.jpg');
        await ref.putFile(_bannerFile!);
        newImageUrl = await ref.getDownloadURL();
      }

      await ref.read(firestoreServiceProvider).updateVendorSettings(
        widget.vendor.id,
        {
          'isOpen': _isOpen,
          'contactPhone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'imageUrl': newImageUrl,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open / Closed toggle
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              title: const Text('Store open',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark)),
              subtitle: Text(
                _isOpen
                    ? 'Customers can currently order from you.'
                    : 'Your store is hidden from customers.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              value: _isOpen,
              activeThumbColor: AppColors.success,
              onChanged: (v) => setState(() => _isOpen = v),
            ),
          ),
          const SizedBox(height: 20),

          // Banner upload
          const Text('Store Banner Image',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickBanner,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBDD6F5)),
                image: _bannerFile != null
                    ? DecorationImage(
                        image: FileImage(_bannerFile!),
                        fit: BoxFit.cover,
                      )
                    : (widget.vendor.imageUrl.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(widget.vendor.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (_bannerFile != null || widget.vendor.imageUrl.isNotEmpty)
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            color: AppColors.primary, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Upload banner image',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Contact number',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_rounded),
              hintText: '0XX XXX XXXX',
            ),
          ),
          const SizedBox(height: 20),

          const Text('Physical address',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.map_rounded),
              hintText: 'Street address / stand number',
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4))
                : const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
