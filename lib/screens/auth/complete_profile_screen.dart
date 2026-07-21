import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/residency_service.dart';
import '../../widgets/common_widgets.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String phone;
  const CompleteProfileScreen({super.key, required this.uid, required this.phone});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedArea;
  bool _loading = false;
  bool _locating = false;
  Position? _position;
  ResidencyCheckResult? _residencyResult;

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _position = pos;
        _locating = false;
      });
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedArea == null) {
      if (_selectedArea == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your local area')),
        );
      }
      return;
    }
    setState(() => _loading = true);

    final result = ResidencyVerificationService.evaluateForCustomer(
      deviceLat: _position?.latitude,
      deviceLng: _position?.longitude,
      selectedLocalArea: _selectedArea!,
    );
    setState(() => _residencyResult = result);

    final user = AppUser(
      id: widget.uid,
      fullName: _nameController.text.trim(),
      phone: widget.phone,
      localArea: _selectedArea!,
      homeLat: _position?.latitude,
      homeLng: _position?.longitude,
      isResidencyVerified: result.level == ResidencyCheckLevel.strong,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).upsertUser(user);
    setState(() => _loading = false);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kgoro is only for Thaba Nchu residents. We confirm this with your location and area — vendors and drivers go through extra checks.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Full name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedArea,
                decoration: const InputDecoration(
                  labelText: 'Your area in Thaba Nchu',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: AppConstants.localAreas
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedArea = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _locating ? null : _detectLocation,
                icon: Icon(_position == null
                    ? Icons.my_location_rounded
                    : Icons.check_circle_rounded),
                label: Text(_locating
                    ? 'Detecting…'
                    : _position == null
                        ? 'Confirm my location'
                        : 'Location confirmed'),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirming your location speeds up delivery and helps us verify you\'re in the service area.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4),
                      )
                    : const Text('Finish sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
