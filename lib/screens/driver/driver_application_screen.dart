import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/residency_service.dart';
import '../../widgets/common_widgets.dart';

class DriverApplicationScreen extends ConsumerStatefulWidget {
  const DriverApplicationScreen({super.key});

  @override
  ConsumerState<DriverApplicationScreen> createState() =>
      _DriverApplicationScreenState();
}

class _DriverApplicationScreenState
    extends ConsumerState<DriverApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  VehicleType _vehicle = VehicleType.footOrBicycle;
  XFile? _idDocument;
  XFile? _proofOfAddress;
  Position? _position;
  bool _submitting = false;
  ResidencyCheckResult? _result;

  Future<void> _pickImage(bool isIdDoc) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      if (isIdDoc) {
        _idDocument = picked;
      } else {
        _proofOfAddress = picked;
      }
    });
  }

  Future<void> _detectLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _position = pos);
  }

  Future<String?> _uploadFile(XFile file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(await file.readAsBytes());
      return ref.getDownloadURL();
    } catch (_) {
      return null; // Storage may not be configured yet in demo mode.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idDocument == null || _proofOfAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both documents')),
      );
      return;
    }

    setState(() => _submitting = true);

    final result = ResidencyVerificationService.evaluateForDriverApplication(
      deviceLat: _position?.latitude,
      deviceLng: _position?.longitude,
      idNumber: _idController.text.trim(),
      hasProofOfAddress: _proofOfAddress != null,
      hasIdDocument: _idDocument != null,
      voucherCount: 0, // vouches are added later by other users
    );
    setState(() => _result = result);

    final user = ref.read(currentAppUserProvider).value;
    if (user == null) {
      setState(() => _submitting = false);
      return;
    }

    final idUrl = await _uploadFile(
        _idDocument!, 'drivers/${user.id}/id_document.jpg') ?? '';
    final poaUrl = await _uploadFile(
        _proofOfAddress!, 'drivers/${user.id}/proof_of_address.jpg') ?? '';

    final profile = DriverProfile(
      userId: user.id,
      vehicleType: _vehicle,
      idNumber: _idController.text.trim(),
      idDocumentUrl: idUrl,
      proofOfAddressUrl: poaUrl,
      approvalStatus: result.passesForDriverApplication
          ? ApprovalStatus.pendingReview
          : ApprovalStatus.moreInfoNeeded,
      appliedAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).submitDriverApplication(profile);
    setState(() => _submitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Application submitted'),
          content: Text(result.passesForDriverApplication
              ? "Thanks! Your application is now with our team for review. We'll notify you once it's approved."
              : "We've received your application, but we need more information before we can review it. See notes on your driver dashboard."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vehicle type', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: VehicleType.values.map((v) {
                  return ChoiceChip(
                    label: Text(v.label),
                    selected: _vehicle == v,
                    onSelected: (_) => setState(() => _vehicle = v),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'South African ID number',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => Validators.isValidSAId(v ?? '')
                    ? null
                    : 'Enter a valid 13-digit SA ID number',
              ),
              const SizedBox(height: 16),
              _UploadTile(
                label: 'ID document photo',
                file: _idDocument,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 10),
              _UploadTile(
                label: 'Proof of address (municipal bill, ward letter, etc.)',
                file: _proofOfAddress,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _detectLocation,
                icon: Icon(_position == null
                    ? Icons.my_location_rounded
                    : Icons.check_circle_rounded),
                label: Text(_position == null
                    ? 'Confirm current location'
                    : 'Location confirmed'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFFF6F3EE),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Residency check',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        ..._result!.notes.map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(n, style: const TextStyle(fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.4),
                      )
                    : const Text('Submit application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onTap;
  const _UploadTile({required this.label, required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null ? Colors.green : const Color(0xFFE0DAD2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: file != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? '$label — uploaded' : label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
