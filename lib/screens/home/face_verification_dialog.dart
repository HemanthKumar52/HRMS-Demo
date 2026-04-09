import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';

/// WFH face-verification dialog.
///
/// Captures a selfie via the system camera, sends it base64-encoded to the
/// backend `/attendance/face-punch-in` endpoint, and reflects the result
/// inside the small avatar circle:
///   • Verifying  → spinner, primary ring
///   • Verified   → green check, success ring
///   • Failed     → red X, danger ring + horizontal shake animation + haptic
class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

enum _Stage { idle, capturing, verifying, verified, failed }

class _FaceVerificationDialogState extends State<FaceVerificationDialog>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  _Stage _stage = _Stage.idle;
  String _statusMessage = 'Position your face within the circle';
  String? _errorCode;

  // ── Shake animation ──────────────────────────────────────────────────────
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  /// Damped sine wave: amplitude * sin(2πfreq·t) * (1 - t)
  double _shakeOffset(double t) {
    if (t == 0) return 0;
    const amplitude = 14.0;
    const frequency = 4.0;
    return amplitude * math.sin(frequency * 2 * math.pi * t) * (1 - t);
  }

  void _triggerFailureFeedback() {
    HapticFeedback.heavyImpact();
    unawaited(_shakeController.forward(from: 0));
  }

  // ── Verification flow ────────────────────────────────────────────────────
  Future<void> _startVerification() async {
    setState(() {
      _stage = _Stage.capturing;
      _statusMessage = 'Opening camera…';
      _errorCode = null;
    });

    try {
      final XFile? shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (shot == null) {
        if (!mounted) return;
        setState(() {
          _stage = _Stage.idle;
          _statusMessage = 'Position your face within the circle';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _stage = _Stage.verifying;
        _statusMessage = 'Verifying…';
      });

      final provider = context.read<AppProvider>();
      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);

      final err = await provider.facePunchIn(b64);

      if (!mounted) return;
      if (err == null || err == 'ALREADY_PUNCHED_IN') {
        HapticFeedback.lightImpact();
        setState(() {
          _stage = _Stage.verified;
          _statusMessage = 'Punch recorded successfully';
        });
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          _stage = _Stage.failed;
          _errorCode = err;
          _statusMessage = _humanMessage(err);
        });
        _triggerFailureFeedback();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _statusMessage = 'Could not capture image';
      });
      _triggerFailureFeedback();
    }
  }

  String _humanMessage(String code) {
    switch (code) {
      case 'GEOFENCE_OFFICE':
        return "You're at the office — please punch in via biometric.";
      case 'WFH_OUT_OF_ZONE':
        return 'You are not within an authorized WFH location.';
      case 'FACE_MISMATCH':
        return 'Face does not match this account.';
      case 'FACE_VERIFICATION_FAILED':
        return 'Unknown user — verification failed.';
      case 'BIOMETRIC_PUNCH_ACTIVE':
        return 'Already punched in via biometric device.';
      default:
        return 'Punch in failed. Please try again.';
    }
  }

  Color _ringColor() {
    switch (_stage) {
      case _Stage.verified:
        return AppColors.success;
      case _Stage.failed:
        return AppColors.danger;
      case _Stage.capturing:
      case _Stage.verifying:
        return AppColors.primary;
      case _Stage.idle:
        return Colors.grey.shade300;
    }
  }

  Color _ringFill() {
    switch (_stage) {
      case _Stage.verified:
        return AppColors.success.withValues(alpha: 0.10);
      case _Stage.failed:
        return AppColors.danger.withValues(alpha: 0.10);
      default:
        return AppColors.primary.withValues(alpha: 0.08);
    }
  }

  Widget _ringChild() {
    switch (_stage) {
      case _Stage.capturing:
      case _Stage.verifying:
        return const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3.5,
          ),
        );
      case _Stage.verified:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 80,
        );
      case _Stage.failed:
        return const Icon(
          Icons.cancel,
          color: AppColors.danger,
          size: 80,
        );
      case _Stage.idle:
        return Icon(Icons.face, color: Colors.grey[400], size: 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _stage == _Stage.capturing || _stage == _Stage.verifying;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circle (shakes horizontally on failure).
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeOffset(_shakeController.value), 0),
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ringFill(),
                  border: Border.all(color: _ringColor(), width: 3),
                  boxShadow: _stage == _Stage.failed
                      ? [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : _stage == _Stage.verified
                          ? [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_stage),
                      child: _ringChild(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              switch (_stage) {
                _Stage.verified => 'Verified!',
                _Stage.verifying => 'Verifying…',
                _Stage.capturing => 'Capturing…',
                _Stage.failed => 'Verification Failed',
                _Stage.idle => 'Face Verification',
              },
              style: theme.textTheme.titleLarge?.copyWith(
                color: _stage == _Stage.failed
                    ? AppColors.danger
                    : _stage == _Stage.verified
                        ? AppColors.success
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!busy && _stage != _Stage.verified)
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
                      child: Text(_stage == _Stage.failed ? 'Try Again' : 'Verify'),
                    ),
                  ),
                ],
              ),
            // Keep the unused-field warning quiet — _errorCode is reserved
            // for telemetry / future detail-screen handoff.
            if (_errorCode != null) const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
