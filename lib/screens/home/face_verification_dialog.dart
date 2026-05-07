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
import '../../widgets/face_guide_overlay.dart';
import '../../widgets/face_scanner_painters.dart';

/// WFH face-verification dialog with real-time ML Kit face guidance,
/// scanner animation, and auto-capture when conditions are optimal.
class FaceVerificationDialog extends StatefulWidget {
  const FaceVerificationDialog({super.key});

  @override
  State<FaceVerificationDialog> createState() => _FaceVerificationDialogState();
}

enum _Stage { idle, preview, capturing, verifying, verified, failed }

class _FaceVerificationDialogState extends State<FaceVerificationDialog>
    with TickerProviderStateMixin {
  static const _ringDiameter = 200.0;
  static const _scannerSize = 230.0;

  _Stage _stage = _Stage.idle;
  String _statusMessage = 'Position your face within the circle';
  String? _errorCode;

  CameraController? _cameraController;
  CameraDescription? _cameraDesc;
  final List<String> _extraFrames = [];

  // Animations
  late final AnimationController _shakeController;
  late final AnimationController _scanController;
  late final AnimationController _pulseController;

  // ML Kit real-time face guide
  FaceGuideAnalyzer? _faceGuide;
  FaceGuideStatus _guideStatus = const FaceGuideStatus();
  int _goodFrameCount = 0;
  static const _autoCaptureTrigger = 6; // ~6 good frames (~1s)
  Timer? _frameSampleTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _frameSampleTimer?.cancel();
    _shakeController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _faceGuide?.dispose();
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    final c = _cameraController;
    _cameraController = null;
    if (c != null) {
      try {
        await c.dispose();
      } catch (_) {}
    }
  }

  void _startScanAnimation() {
    _scanController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopScanAnimation() {
    _scanController.stop();
    _pulseController.stop();
  }

  double _shakeOffset(double t) {
    if (t == 0) return 0;
    return 14.0 * math.sin(4.0 * 2 * math.pi * t) * (1 - t);
  }

  void _triggerFailureFeedback() {
    HapticFeedback.heavyImpact();
    _stopScanAnimation();
    unawaited(_shakeController.forward(from: 0));
  }

  // ── Verification flow ────────────────────────────────────────────────────

  Future<void> _startVerification() async {
    setState(() {
      _stage = _Stage.preview;
      _statusMessage = 'Look directly into the camera';
      _errorCode = null;
      _goodFrameCount = 0;
      _guideStatus = const FaceGuideStatus();
    });
    _startScanAnimation();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw CameraException('no_cameras', 'No cameras found');

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraDesc = front;

      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      _cameraController = controller;
      await controller.initialize();

      if (!mounted) {
        await _disposeCamera();
        return;
      }

      // Start ML Kit face guide
      _faceGuide = FaceGuideAnalyzer(
        onStatusChanged: (status) {
          if (!mounted || _stage != _Stage.preview) return;
          setState(() {
            _guideStatus = status;
            _statusMessage = status.guidance;
          });
          if (status.allGood && status.stable) {
            _goodFrameCount++;
            if (_goodFrameCount >= _autoCaptureTrigger) {
              _captureAndVerify();
            }
          } else {
            _goodFrameCount = 0;
          }
        },
      );

      // Collect extra frames for liveness while streaming
      _extraFrames.clear();
      _frameSampleTimer = Timer.periodic(const Duration(milliseconds: 800), (
        _,
      ) async {
        if (_extraFrames.length >= 2 ||
            _cameraController == null ||
            _stage != _Stage.preview) {
          _frameSampleTimer?.cancel();
          return;
        }
        try {
          // Stop stream, take picture, restart stream
          await _cameraController!.stopImageStream();
          final snap = await _cameraController!.takePicture();
          final bytes = await File(snap.path).readAsBytes();
          _extraFrames.add(base64Encode(bytes));
          unawaited(
            File(snap.path).delete().catchError((_) => File(snap.path)),
          );
          await _cameraController!.startImageStream((image) {
            _faceGuide?.processImage(image, _cameraDesc!);
          });
        } catch (_) {}
      });

      await controller.startImageStream((image) {
        _faceGuide?.processImage(image, _cameraDesc!);
      });

      if (mounted) setState(() {});
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
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (_stage == _Stage.capturing || _stage == _Stage.verifying) return;
    if (!mounted) return;

    _frameSampleTimer?.cancel();

    // Stop image stream first
    try {
      await _cameraController!.stopImageStream();
    } catch (_) {}

    setState(() {
      _stage = _Stage.capturing;
      _statusMessage = 'Scanning face…';
    });

    try {
      final shot = await _cameraController!.takePicture();
      await _disposeCamera();
      _faceGuide?.dispose();
      _faceGuide = null;

      if (!mounted) return;
      setState(() {
        _stage = _Stage.verifying;
        _statusMessage = 'Verifying identity…';
      });

      final provider = context.read<AppProvider>();
      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));

      final err = await provider.facePunchIn(b64, extraFrames: _extraFrames);
      if (!mounted) return;

      _stopScanAnimation();

      if (err == null || err == 'ALREADY_PUNCHED_IN') {
        HapticFeedback.lightImpact();
        setState(() {
          _stage = _Stage.verified;
          _statusMessage = 'Check in recorded successfully';
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
      _stopScanAnimation();
      await _disposeCamera();
      _faceGuide?.dispose();
      _faceGuide = null;
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
        return "You're at the office — please check in via biometric.";
      case 'WFH_OUT_OF_ZONE':
        return 'You are not within an authorized WFH location.';
      case 'FACE_MISMATCH':
        return 'Face does not match this account.';
      case 'FACE_VERIFICATION_FAILED':
        return 'Unknown user — verification failed.';
      case 'BIOMETRIC_PUNCH_ACTIVE':
        return 'Already checked in via biometric device.';
      default:
        return 'Clock in failed. Please try again.';
    }
  }

  String _cameraErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('denied'))
      return 'Camera permission denied.';
    if (s.contains('no_cameras') || s.contains('no cameras'))
      return 'No camera available.';
    return 'Could not start the camera.';
  }

  // ── Visuals ──────────────────────────────────────────────────────────────

  bool get _isScanning =>
      _stage == _Stage.preview ||
      _stage == _Stage.capturing ||
      _stage == _Stage.verifying;

  Color get _scanColor => _guideStatus.allGood && _stage == _Stage.preview
      ? AppColors.success
      : const Color(0xFF3B82F6);

  Widget _ringContent() {
    switch (_stage) {
      case _Stage.idle:
        return Icon(Icons.face, color: Colors.grey[400], size: 70);
      case _Stage.preview:
        final controller = _cameraController;
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
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
        return const Icon(
          Icons.face_retouching_natural,
          color: Color(0xFF3B82F6),
          size: 70,
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

  Widget _buildScannerRing() {
    return SizedBox(
      width: _scannerSize,
      height: _scannerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isScanning)
            PulsingGlowRing(
              animation: _pulseController,
              diameter: _scannerSize,
              color: _scanColor,
            ),

          if (_isScanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) => CustomPaint(
                size: const Size(_scannerSize, _scannerSize),
                painter: ScannerArcPainter(
                  progress: _scanController.value,
                  color: _scanColor,
                ),
              ),
            ),

          if (_isScanning)
            SizedBox(
              width: _scannerSize - 10,
              height: _scannerSize - 10,
              child: CustomPaint(
                painter: CornerBracketPainter(color: _scanColor),
              ),
            ),

          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeOffset(_shakeController.value), 0),
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _ringDiameter,
              height: _ringDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _stage == _Stage.idle
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : _stage == _Stage.verified
                    ? AppColors.success.withValues(alpha: 0.10)
                    : _stage == _Stage.failed
                    ? AppColors.danger.withValues(alpha: 0.10)
                    : Colors.transparent,
                border: Border.all(
                  color: _isScanning
                      ? _scanColor.withValues(alpha: 0.4)
                      : _stage == _Stage.verified
                      ? AppColors.success
                      : _stage == _Stage.failed
                      ? AppColors.danger
                      : Colors.grey.shade300,
                  width: _isScanning ? 2 : 3,
                ),
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
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Center(key: ValueKey(_stage), child: _ringContent()),
                ),
              ),
            ),
          ),

          if (_stage == _Stage.capturing || _stage == _Stage.verifying)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) => CustomPaint(
                size: const Size(_ringDiameter, _ringDiameter),
                painter: SweepLinePainter(
                  progress: _scanController.value,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
        ],
      ),
    );
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
      child: SizedBox(
        width: _scannerSize + 50,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildScannerRing(),
              const SizedBox(height: 16),

              Text(
                switch (_stage) {
                  _Stage.verified => 'Verified!',
                  _Stage.verifying => 'Verifying…',
                  _Stage.capturing => 'Scanning…',
                  _Stage.preview =>
                    _guideStatus.allGood ? 'Perfect!' : 'Hold Still',
                  _Stage.failed => 'Verification Failed',
                  _Stage.idle => 'Face Verification',
                },
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _stage == _Stage.failed
                      ? AppColors.danger
                      : _stage == _Stage.verified
                      ? AppColors.success
                      : _guideStatus.allGood && _stage == _Stage.preview
                      ? AppColors.success
                      : _isScanning
                      ? const Color(0xFF3B82F6)
                      : null,
                ),
              ),

              const SizedBox(height: 6),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _statusMessage,
                  key: ValueKey(_statusMessage),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Face quality indicators during preview
              if (_stage == _Stage.preview && _guideStatus.faceDetected) ...[
                const SizedBox(height: 12),
                FaceGuideIndicators(status: _guideStatus),
              ],

              const SizedBox(height: 20),

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
              if (_errorCode != null) const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
