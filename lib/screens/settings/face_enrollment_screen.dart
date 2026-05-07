import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/platform_adaptive.dart';
import '../../widgets/face_guide_overlay.dart';
import '../../widgets/face_scanner_painters.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

enum _EnrollState { checking, notEnrolled, camera, processing, success, error }

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with TickerProviderStateMixin {
  static const _ringDiameter = 220.0;
  static const _scannerSize = 260.0;

  _EnrollState _state = _EnrollState.checking;
  String _message = '';
  CameraController? _cameraController;
  CameraDescription? _cameraDesc;
  bool _isEnrolled = false;

  late final AnimationController _scanController;
  late final AnimationController _pulseController;

  // ML Kit real-time face guide
  FaceGuideAnalyzer? _faceGuide;
  FaceGuideStatus _guideStatus = const FaceGuideStatus();
  Timer? _autoCaptureTimer;
  int _goodFrameCount = 0;
  static const _autoCaptureTrigger = 8; // ~8 good frames (~1.5s)

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkEnrollment();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _autoCaptureTimer?.cancel();
    _faceGuide?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startScanAnimation() {
    _scanController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopScanAnimation() {
    _scanController.stop();
    _pulseController.stop();
  }

  Future<void> _checkEnrollment() async {
    _isEnrolled = await ApiService.isFaceEnrolled();
    if (mounted) {
      setState(() {
        _state = _EnrollState.notEnrolled;
        _message = _isEnrolled
            ? 'Your face is already enrolled. You can re-enroll to update it.'
            : 'Enroll your face to enable face check-in.';
      });
    }
  }

  Future<bool> _showConsentDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            const Text('Biometric Consent'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your face data will be used for attendance verification.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            Text(
              'By proceeding you agree that:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 8),
            _ConsentBullet(
              'Your facial features will be converted to a mathematical embedding',
            ),
            _ConsentBullet('No raw photos are stored — only numerical data'),
            _ConsentBullet('Data is used solely for attendance verification'),
            _ConsentBullet(
              'You can delete your face data at any time from Settings',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _startCamera() async {
    // Show consent dialog on first enrollment
    if (!_isEnrolled) {
      final consented = await _showConsentDialog();
      if (!consented) return;
    }

    setState(() {
      _state = _EnrollState.camera;
      _message = 'Position your face in the circle';
      _goodFrameCount = 0;
    });
    _startScanAnimation();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras found');

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraDesc = front;

      _cameraController = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _cameraController!.initialize();

      // Start ML Kit face guide
      _faceGuide = FaceGuideAnalyzer(
        onStatusChanged: (status) {
          if (!mounted || _state != _EnrollState.camera) return;
          setState(() {
            _guideStatus = status;
            _message = status.guidance;
          });
          // Auto-capture when conditions are good
          if (status.allGood && status.stable) {
            _goodFrameCount++;
            if (_goodFrameCount >= _autoCaptureTrigger) {
              _capture();
            }
          } else {
            _goodFrameCount = 0;
          }
        },
      );

      await _cameraController!.startImageStream((image) {
        _faceGuide?.processImage(image, _cameraDesc!);
      });

      if (mounted) setState(() {});
    } catch (e) {
      _stopScanAnimation();
      if (mounted) {
        setState(() {
          _state = _EnrollState.error;
          _message = _cameraErrorMessage(e);
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (_state == _EnrollState.processing) return; // prevent double capture

    HapticFeedback.mediumImpact();

    // Stop image stream before taking picture
    try {
      await _cameraController!.stopImageStream();
    } catch (_) {}

    setState(() {
      _state = _EnrollState.processing;
      _message = 'Scanning face…';
    });

    try {
      final frames = <String>[];
      for (var i = 0; i < 3; i++) {
        if (_cameraController == null) break;
        final file = await _cameraController!.takePicture();
        final bytes = await File(file.path).readAsBytes();
        frames.add(base64Encode(bytes));
        unawaited(File(file.path).delete().catchError((_) => File(file.path)));
        if (i < 2) await Future.delayed(const Duration(milliseconds: 500));
      }

      await _cameraController?.dispose();
      _cameraController = null;
      _faceGuide?.dispose();
      _faceGuide = null;

      if (frames.isEmpty) throw Exception('No frames captured');

      setState(() => _message = 'Processing face…');

      await ApiService.enrollFaceSelf(
        frames.first,
        extraFrames: frames.skip(1).toList(),
      );

      _stopScanAnimation();
      if (mounted) {
        setState(() {
          _state = _EnrollState.success;
          _message = 'Face enrolled successfully!';
          _isEnrolled = true;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _stopScanAnimation();
      _faceGuide?.dispose();
      _faceGuide = null;
      if (mounted) {
        setState(() {
          _state = _EnrollState.error;
          _message = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _deleteFaceData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Face Data?'),
        content: const Text(
          'This will permanently remove your enrolled face data. You will need to re-enroll to use face check-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteFaceEnrollment();
      if (mounted) {
        setState(() {
          _isEnrolled = false;
          _state = _EnrollState.notEnrolled;
          _message = 'Face data deleted. Enroll again to use face check-in.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message =
              'Failed to delete: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  String _cameraErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission') || s.contains('denied')) {
      return 'Camera permission denied. Enable it in Settings.';
    }
    if (s.contains('no cameras')) return 'No camera available on this device.';
    return 'Could not start the camera.';
  }

  bool get _isScanning =>
      _state == _EnrollState.camera || _state == _EnrollState.processing;

  Widget _buildScannerRing(bool isDark) {
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
              color: _guideStatus.allGood
                  ? AppColors.success
                  : const Color(0xFF3B82F6),
            ),

          if (_isScanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) => CustomPaint(
                size: const Size(_scannerSize, _scannerSize),
                painter: ScannerArcPainter(
                  progress: _scanController.value,
                  color: _guideStatus.allGood
                      ? AppColors.success
                      : const Color(0xFF3B82F6),
                ),
              ),
            ),

          if (_isScanning)
            SizedBox(
              width: _scannerSize - 10,
              height: _scannerSize - 10,
              child: CustomPaint(
                painter: CornerBracketPainter(
                  color: _guideStatus.allGood
                      ? AppColors.success
                      : const Color(0xFF3B82F6),
                ),
              ),
            ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _ringDiameter,
            height: _ringDiameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _state == _EnrollState.success
                  ? AppColors.success.withValues(alpha: 0.10)
                  : _state == _EnrollState.error
                  ? AppColors.danger.withValues(alpha: 0.10)
                  : _isScanning
                  ? Colors.transparent
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              border: Border.all(
                color: _state == _EnrollState.success
                    ? AppColors.success
                    : _state == _EnrollState.error
                    ? AppColors.danger
                    : _isScanning
                    ? (_guideStatus.allGood
                          ? AppColors.success.withValues(alpha: 0.6)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.4))
                    : Colors.grey.shade400,
                width: _isScanning ? 2 : 3,
              ),
              boxShadow: _state == _EnrollState.success
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : _state == _EnrollState.error
                  ? [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(child: _buildContent(isDark)),
          ),

          if (_state == _EnrollState.processing)
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

  Widget _buildContent(bool isDark) {
    if (_state == _EnrollState.camera &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return SizedBox(
        width: _ringDiameter,
        height: _ringDiameter,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width:
                _cameraController!.value.previewSize?.height ?? _ringDiameter,
            height:
                _cameraController!.value.previewSize?.width ?? _ringDiameter,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    if (_state == _EnrollState.processing) {
      return const Center(
        child: Icon(
          Icons.face_retouching_natural,
          size: 70,
          color: Color(0xFF3B82F6),
        ),
      );
    }

    if (_state == _EnrollState.success) {
      return const Center(
        child: Icon(Icons.check_circle, size: 90, color: AppColors.success),
      );
    }

    if (_state == _EnrollState.error) {
      return const Center(
        child: Icon(Icons.error_outline, size: 80, color: AppColors.danger),
      );
    }

    return Center(
      child: Icon(
        _isEnrolled ? Icons.face_retouching_natural : Icons.face,
        size: 80,
        color: _isEnrolled ? AppColors.success : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final scanColor = _guideStatus.allGood
        ? AppColors.success
        : const Color(0xFF3B82F6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        centerTitle: true,
        actions: [
          if (_isEnrolled &&
              _state != _EnrollState.camera &&
              _state != _EnrollState.processing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Delete face data',
              onPressed: _deleteFaceData,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              _buildScannerRing(isDark),

              const SizedBox(height: 20),

              // Title
              Text(
                _state == _EnrollState.camera
                    ? 'Position Your Face'
                    : _state == _EnrollState.processing
                    ? 'Scanning…'
                    : _state == _EnrollState.success
                    ? 'Enrolled!'
                    : _state == _EnrollState.error
                    ? 'Enrollment Failed'
                    : 'Face Enrollment',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _state == _EnrollState.error
                      ? AppColors.danger
                      : _state == _EnrollState.success
                      ? AppColors.success
                      : _isScanning
                      ? scanColor
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              // Guidance message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _message,
                  key: ValueKey(_message),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _state == _EnrollState.error
                        ? AppColors.danger
                        : _state == _EnrollState.success
                        ? AppColors.success
                        : _guideStatus.allGood && _isScanning
                        ? AppColors.success
                        : isDark
                        ? Colors.white70
                        : Colors.grey.shade700,
                  ),
                ),
              ),

              // Face quality indicators
              if (_state == _EnrollState.camera &&
                  _guideStatus.faceDetected) ...[
                const SizedBox(height: 16),
                FaceGuideIndicators(status: _guideStatus),
              ],

              // Guidelines when camera is active but no face detected
              if (_state == _EnrollState.camera &&
                  !_guideStatus.faceDetected) ...[
                const SizedBox(height: 16),
                _guideline(Icons.wb_sunny_outlined, 'Ensure good lighting'),
                _guideline(Icons.face, 'Neutral expression, no mask'),
                _guideline(Icons.straighten, 'Keep face centered'),
              ],

              const Spacer(),

              _buildButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    switch (_state) {
      case _EnrollState.checking:
        return const SizedBox.shrink();
      case _EnrollState.notEnrolled:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startCamera,
            icon: const Icon(Icons.camera_alt),
            label: Text(_isEnrolled ? 'Re-enroll Face' : 'Enroll Face'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      case _EnrollState.camera:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (_guideStatus.allGood || _guideStatus.faceDetected)
                ? _capture
                : null,
            icon: const Icon(Icons.camera),
            label: Text(
              _guideStatus.allGood
                  ? 'Capture Now'
                  : 'Waiting for good position…',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _guideStatus.allGood
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade400,
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      case _EnrollState.processing:
        return const SizedBox.shrink();
      case _EnrollState.success:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Done'),
          ),
        );
      case _EnrollState.error:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              _cameraController?.dispose();
              _cameraController = null;
              _startCamera();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
    }
  }

  Widget _guideline(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ConsentBullet extends StatelessWidget {
  final String text;
  const _ConsentBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
