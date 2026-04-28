import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';

/// WFH face-verification dialog with **inline live camera preview** and
/// **auto-capture** after a short countdown.
///
/// Stages, all rendered inside the same circular avatar:
///   • idle      → static face icon, "Verify" button enabled
///   • preview   → live front-camera feed, countdown ring
///   • capturing → progress spinner overlay
///   • verifying → progress spinner
///   • verified  → green check
///   • failed    → red X + horizontal damped-sine shake + heavy haptic
class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

enum _Stage { idle, preview, capturing, verifying, verified, failed }

class _FaceVerificationDialogState extends State<FaceVerificationDialog>
    with SingleTickerProviderStateMixin {
  static const _ringDiameter = 200.0;
  static const _autoCaptureDelay = Duration(milliseconds: 1500);

  _Stage _stage = _Stage.idle;
  String _statusMessage = 'Position your face within the circle';
  String? _errorCode;

  CameraController? _cameraController;
  Future<void>? _initFuture;
  Timer? _captureTimer;
  Timer? _frameSampleTimer;
  final List<String> _extraFrames =
      []; // base64 frames for multi-frame liveness

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
    _captureTimer?.cancel();
    _frameSampleTimer?.cancel();
    _shakeController.dispose();
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    final c = _cameraController;
    _cameraController = null;
    _initFuture = null;
    if (c != null) {
      try {
        await c.dispose();
      } catch (_) {}
    }
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
      _stage = _Stage.preview;
      _statusMessage = 'Hold still — capturing in 1.5 s';
      _errorCode = null;
    });

    try {
      // Pick the front camera (fall back to first available).
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw CameraException('no_cameras', 'No cameras found on device');
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset
            .medium, // good enough for face recognition, much faster than high
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      _initFuture = controller.initialize();
      await _initFuture;

      if (!mounted) {
        await _disposeCamera();
        return;
      }
      setState(() {});

      // Sample 2 extra frames during the preview for multi-frame liveness.
      _extraFrames.clear();
      _frameSampleTimer = Timer.periodic(const Duration(milliseconds: 400), (
        _,
      ) async {
        if (_extraFrames.length >= 2 || _cameraController == null) {
          _frameSampleTimer?.cancel();
          return;
        }
        try {
          final snap = await _cameraController!.takePicture();
          final bytes = await File(snap.path).readAsBytes();
          _extraFrames.add(base64Encode(bytes));
          unawaited(
            File(snap.path).delete().catchError((_) => File(snap.path)),
          );
        } catch (_) {}
      });

      // Auto-capture the primary frame after the hold-still window.
      _captureTimer = Timer(_autoCaptureDelay, _captureAndVerify);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _statusMessage = _cameraErrorMessage(e);
      });
      _triggerFailureFeedback();
      await _disposeCamera();
    }
  }

  Future<void> _captureAndVerify() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!mounted) return;

    setState(() {
      _stage = _Stage.capturing;
      _statusMessage = 'Capturing…';
    });

    try {
      final shot = await controller.takePicture();
      await _disposeCamera();

      if (!mounted) return;
      setState(() {
        _stage = _Stage.verifying;
        _statusMessage = 'Verifying…';
      });

      _frameSampleTimer?.cancel();
      final provider = context.read<AppProvider>();
      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);
      // Best-effort cleanup of the temp file.
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));

      final err = await provider.facePunchIn(b64, extraFrames: _extraFrames);
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
    } catch (e) {
      if (!mounted) return;
      await _disposeCamera();
      setState(() {
        _stage = _Stage.failed;
        _statusMessage = 'Could not capture image';
      });
      _triggerFailureFeedback();
    }
  }

  String _humanMessage(String code) {
    switch (code) {
      case 'LOCATION_REQUIRED':
        return 'Enable location permission in Settings — required for check-in.';
      case 'GEOFENCE_OFFICE':
        return "You're at the office — please clock in via biometric.";
      case 'WFH_OUT_OF_ZONE':
        return 'You are not within an authorized WFH location.';
      case 'FACE_MISMATCH':
        return 'Face does not match this account.';
      case 'FACE_VERIFICATION_FAILED':
        return 'Unknown user — verification failed.';
      case 'BIOMETRIC_PUNCH_ACTIVE':
        return 'Already clocked in via biometric device.';
      default:
        return 'Clock in failed. Please try again.';
    }
  }

  String _cameraErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('denied')) {
      return 'Camera permission denied. Enable it in Settings.';
    }
    if (s.contains('no_cameras') || s.contains('no cameras')) {
      return 'No camera available on this device.';
    }
    return 'Could not start the camera.';
  }

  // ── Visuals ──────────────────────────────────────────────────────────────

  Color _ringColor() {
    switch (_stage) {
      case _Stage.verified:
        return AppColors.success;
      case _Stage.failed:
        return AppColors.danger;
      case _Stage.capturing:
      case _Stage.verifying:
      case _Stage.preview:
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

  Widget _ringContent() {
    switch (_stage) {
      case _Stage.idle:
        return Icon(Icons.face, color: Colors.grey[400], size: 70);
      case _Stage.preview:
        // Live front-camera feed clipped into the circle.
        final controller = _cameraController;
        if (controller == null || !controller.value.isInitialized) {
          return SizedBox(
            width: 50,
            height: 50,
            child: isApplePlatform
                ? const CupertinoActivityIndicator(radius: 16)
                : const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3.5,
                  ),
          );
        }
        return ClipOval(
          child: SizedBox(
            width: _ringDiameter,
            height: _ringDiameter,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? _ringDiameter,
                height: controller.value.previewSize?.width ?? _ringDiameter,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      case _Stage.capturing:
      case _Stage.verifying:
        return SizedBox(
          width: 50,
          height: 50,
          child: isApplePlatform
              ? const CupertinoActivityIndicator(radius: 16)
              : const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3.5,
                ),
        );
      case _Stage.verified:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 90,
        );
      case _Stage.failed:
        return const Icon(Icons.cancel, color: AppColors.danger, size: 90);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy =
        _stage == _Stage.capturing ||
        _stage == _Stage.verifying ||
        _stage == _Stage.preview;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated avatar circle.
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeOffset(_shakeController.value), 0),
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: _ringDiameter,
                height: _ringDiameter,
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
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Center(
                      key: ValueKey(_stage),
                      child: _ringContent(),
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
                _Stage.preview => 'Hold Still',
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
                      child: Text(
                        _stage == _Stage.failed ? 'Try Again' : 'Verify',
                      ),
                    ),
                  ),
                ],
              ),
            // Reserved for future telemetry / detail-screen handoff.
            if (_errorCode != null) const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
