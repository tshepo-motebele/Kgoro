import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

/// Add or edit a single product.
/// Pass [product] == null to add a new one; pass an existing [Product] to edit.
class ProductEditScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final Product? product;

  const ProductEditScreen(
      {super.key, required this.vendorId, required this.product});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _skuController = TextEditingController();
  final _thresholdController = TextEditingController();

  bool _loading = false;
  File? _imageFile;

  bool get _isEdit => widget.product != null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.product!;
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(2);
      _categoryController.text = p.category;
      _quantityController.text = p.quantity.toString();
      _skuController.text = p.sku ?? '';
      _thresholdController.text = p.lowStockThreshold.toString();
    } else {
      _thresholdController.text = '5';
      _quantityController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _skuController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String imageUrl = widget.product?.imageUrl ?? '';

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref('vendors/${widget.vendorId}/products/${const Uuid().v4()}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final data = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'category': _categoryController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'sku': _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        'lowStockThreshold':
            int.tryParse(_thresholdController.text.trim()) ?? 5,
        'imageUrl': imageUrl,
      };

      final svc = ref.read(firestoreServiceProvider);
      if (_isEdit) {
        await svc.updateProduct(widget.vendorId, widget.product!.id, data);
      } else {
        await svc.addProduct(widget.vendorId, data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBDD6F5)),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : (widget.product?.imageUrl.isNotEmpty == true)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(widget.product!.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: (_imageFile != null || widget.product?.imageUrl.isNotEmpty == true)
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
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_rounded,
                              color: AppColors.primary, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Add photo (optional)',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            _field('Product name', _nameController,
                hint: 'e.g. White Bread 700g',
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Required'),
            const SizedBox(height: 16),

            _field('Category', _categoryController,
                hint: 'e.g. Bakery, Beverages, Dairy'),
            const SizedBox(height: 16),

            _field('Price (R)', _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hint: '0.00',
                validator: (v) {
              final n = double.tryParse(v ?? '');
              return n != null && n >= 0 ? null : 'Enter a valid price';
            }),
            const SizedBox(height: 16),

            _field('Stock quantity', _quantityController,
                keyboardType: TextInputType.number,
                hint: '0',
                validator: (v) {
              final n = int.tryParse(v ?? '');
              return n != null && n >= 0 ? null : 'Enter a valid quantity';
            }),
            const SizedBox(height: 16),

            _field('Low-stock threshold', _thresholdController,
                keyboardType: TextInputType.number,
                hint: '5',
                helperText:
                    'Show "Low stock" badge when quantity drops to this level'),
            const SizedBox(height: 16),

            _field('SKU / Barcode (optional)', _skuController,
                hint: 'e.g. SKU001'),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4))
                  : Text(_isEdit ? 'Save Changes' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? helperText,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint, helperText: helperText),
            validator: validator,
          ),
        ],
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${widget.product!.name}" from your menu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(firestoreServiceProvider).deleteProduct(
                    widget.vendorId,
                    widget.product!.id,
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
