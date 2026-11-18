import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';

class RateOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String vendorName;
  const RateOrderScreen({super.key, required this.orderId, required this.vendorName});

  @override
  ConsumerState<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends ConsumerState<RateOrderScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(firestoreServiceProvider).submitOrderRating(
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit rating: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate your order')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How was your order from ${widget.vendorName}?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.naledi,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = star),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Optional comment',
                hintText: 'Tell us more about your experience',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit rating'),
            ),
          ],
        ),
      ),
    );
  }
}
