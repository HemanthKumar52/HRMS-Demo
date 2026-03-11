import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

class _FaceVerificationDialogState extends State<FaceVerificationDialog> {
  bool _isVerifying = false;
  bool _isVerified = false;

  void _startVerification() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _isVerified = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.read<AppProvider>().togglePunch();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera preview placeholder
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: _isVerified
                      ? AppColors.success
                      : _isVerifying
                          ? AppColors.primary
                          : Colors.grey[300]!,
                  width: 3,
                ),
              ),
              child: Center(
                child: _isVerifying
                    ? const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      )
                    : _isVerified
                        ? const Icon(Icons.check_circle,
                            color: AppColors.success, size: 60)
                        : Icon(Icons.face,
                            color: Colors.grey[400], size: 60),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isVerified
                  ? 'Verified!'
                  : _isVerifying
                      ? 'Verifying...'
                      : 'Face Verification',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _isVerified
                  ? 'Punch recorded successfully'
                  : 'Position your face within the circle',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_isVerifying && !_isVerified)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
