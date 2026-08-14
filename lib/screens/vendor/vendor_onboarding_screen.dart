import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

/// Collects store details and creates the vendor doc with
/// approvalStatus: pendingReview, linked to the signed-in user.
class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  ServiceType _serviceType = ServiceType.groceries;
  String _localArea = AppConstants.localAreas.first;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentAppUserProvider).value;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      // Attempt to geocode the typed address into real coordinates.
      // Falls back to town-centre pin if geocoding fails or address is empty.
      double lat = AppConstants.townCentreLat;
      double lng = AppConstants.townCentreLng;
      final address = _addressController.text.trim();
      if (address.isNotEmpty) {
        try {
          final results = await locationFromAddress(
            '$address, $_localArea, Thaba Nchu, Free State, South Africa',
          );
          if (results.isNotEmpty) {
            lat = results.first.latitude;
            lng = results.first.longitude;
          }
        } catch (_) {
          // No network, address not found, or geocoder unavailable —
          // silently fall back to town-centre pin.
        }
      }

      final data = {
        'name': _nameController.text.trim(),
        'type': _serviceType.index,
        'imageUrl': '',
        'localArea': _localArea,
        'address': address,
        'contactPhone': _phoneController.text.trim(),
        'lat': lat,
        'lng': lng,
        'isOpen': false,
        'rating': 5.0,
        'approvalStatus': ApprovalStatus.pendingReview.index,
        'ownerId': user.id,
        'openingHours': <String, String>{},
        'isChainBrand': false,
        'submittedAt': DateTime.now().toIso8601String(),
      };
      await ref.read(firestoreServiceProvider).submitVendorApplication(data);
      final updatedUser = user.copyWith(role: UserRole.vendor);
      await ref.read(firestoreServiceProvider).upsertUser(updatedUser);
      // _RoleGate will now re-watch and show the pending screen automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [SignOutIconButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Register your store',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in your details and we\'ll review your application.',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Store name
                _sectionLabel('Store name'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Mama\'s Spaza, Jwayelane General',
                    prefixIcon: Icon(Icons.store_rounded),
                  ),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 20),

                // Service type
                _sectionLabel('Type of store'),
                _ServiceTypeSelector(
                  selected: _serviceType,
                  onChanged: (t) => setState(() => _serviceType = t),
                ),
                const SizedBox(height: 20),

                // Local area
                _sectionLabel('Local area'),
                DropdownButtonFormField<String>(
                  initialValue: _localArea,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  items: AppConstants.localAreas
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) =>
                      v != null ? setState(() => _localArea = v) : null,
                ),
                const SizedBox(height: 20),

                // Physical address
                _sectionLabel('Physical address (optional)'),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Street address / stand number',
                    prefixIcon: Icon(Icons.map_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Contact phone
                _sectionLabel('Contact number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '0XX XXX XXXX',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Required',
                ),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Submit Application'),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Your store will be reviewed by our team. You\'ll '
                    'get access as soon as it\'s approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Theme.of(context).textTheme.titleSmall?.color ?? AppColors.primaryDark,
          ),
        ),
      );
}

class _ServiceTypeSelector extends StatelessWidget {
  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;

  const _ServiceTypeSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (ServiceType.groceries, Icons.shopping_basket_rounded, 'Groceries'),
      (ServiceType.food, Icons.fastfood_rounded, 'Fast Food'),
      (ServiceType.liquor, Icons.local_bar_rounded, 'Liquor'),
      (ServiceType.laundry, Icons.local_laundry_service_rounded, 'Laundry'),
    ];
    return Row(
      children: options.map((opt) {
        final (type, icon, label) = opt;
        final isSelected = selected == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFDFE1E6),
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
