import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../theme/app_theme.dart';

/// Real-time face quality feedback from on-device ML Kit analysis.
class FaceGuideStatus {
  final bool faceDetected;
  final bool faceRightSize;
  final bool faceFrontal;
  final bool eyesOpen;
  final bool brightEnough;
  final bool stable;
  final String guidance;

  const FaceGuideStatus({
    this.faceDetected = false,
    this.faceRightSize = false,
    this.faceFrontal = false,
    this.eyesOpen = false,
    this.brightEnough = false,
    this.stable = false,
    this.guidance = 'Position your face in the circle',
  });

  bool get allGood =>
      faceDetected && faceRightSize && faceFrontal && eyesOpen && brightEnough;
}

/// Callback when face guide status changes.
typedef FaceGuideCallback = void Function(FaceGuideStatus status);

/// Analyzes camera frames using ML Kit and provides real-time guidance.
class FaceGuideAnalyzer {
  final FaceGuideCallback onStatusChanged;
  final FaceDetector _detector;

  bool _isProcessing = false;
  int _stableFrames = 0;
  static const _stableThreshold = 3;

  // Track previous face position for stability detection
  Rect? _prevFaceBounds;

  FaceGuideAnalyzer({required this.onStatusChanged})
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // eyes open probability
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

  void dispose() {
    _detector.close();
  }

  /// Process a camera image frame. Call from CameraController.startImageStream.
  Future<void> processImage(CameraImage image, CameraDescription camera) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _detector.processImage(inputImage);
      final status = _analyzeFaces(faces, image.width, image.height);
      onStatusChanged(status);
    } catch (_) {
      // Silently ignore frame processing errors
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    final plane = image.planes.first;
    final rotation = _rotationFromSensorOrientation(camera.sensorOrientation);

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromSensorOrientation(int orientation) {
    switch (orientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  FaceGuideStatus _analyzeFaces(List<Face> faces, int imgWidth, int imgHeight) {
    if (faces.isEmpty) {
      _stableFrames = 0;
      _prevFaceBounds = null;
      return const FaceGuideStatus(
        guidance: 'No face detected — look at the camera',
      );
    }

    if (faces.length > 1) {
      _stableFrames = 0;
      return const FaceGuideStatus(
        faceDetected: true,
        guidance: 'Multiple faces detected — only one person please',
      );
    }

    final face = faces.first;
    final bbox = face.boundingBox;

    // 1. Face detected
    const faceDetected = true;

    // 2. Face right size — face should be 4-65% of frame
    final faceArea = (bbox.width * bbox.height) / (imgWidth * imgHeight);
    final faceRightSize = faceArea >= 0.04 && faceArea <= 0.65;
    final faceTooSmall = faceArea < 0.04;
    final faceTooLarge = faceArea > 0.65;

    // 4. Face frontal — head euler angles within tolerance
    final yaw = face.headEulerAngleY ?? 0; // left/right
    final pitch = face.headEulerAngleX ?? 0; // up/down
    final faceFrontal = yaw.abs() < 20 && pitch.abs() < 20;

    // 5. Eyes open
    final leftEye = face.leftEyeOpenProbability ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final eyesOpen = leftEye > 0.4 && rightEye > 0.4;

    // 6. Brightness — we approximate from face detection confidence
    // ML Kit doesn't give brightness directly, so we treat it as OK if face is detected
    const brightEnough = true;

    // 7. Stability — face hasn't moved much in consecutive frames
    bool stable = false;
    if (_prevFaceBounds != null) {
      final dx = (bbox.center.dx - _prevFaceBounds!.center.dx).abs();
      final dy = (bbox.center.dy - _prevFaceBounds!.center.dy).abs();
      final movement = (dx + dy) / imgWidth;
      if (movement < 0.03) {
        _stableFrames++;
        stable = _stableFrames >= _stableThreshold;
      } else {
        _stableFrames = 0;
      }
    }
    _prevFaceBounds = bbox;

    // Build guidance message — show the most important issue first
    String guidance;
    if (faceTooSmall) {
      guidance = 'Move closer to the camera';
    } else if (faceTooLarge) {
      guidance = 'Move further from the camera';
    } else if (!faceFrontal) {
      if (yaw.abs() >= pitch.abs()) {
        guidance = yaw > 0
            ? 'Turn your head slightly left'
            : 'Turn your head slightly right';
      } else {
        guidance = pitch > 0
            ? 'Lower your chin slightly'
            : 'Raise your chin slightly';
      }
    } else if (!eyesOpen) {
      guidance = 'Open your eyes';
    } else if (!stable) {
      guidance = 'Hold still…';
    } else {
      guidance = 'Perfect — hold still';
    }

    return FaceGuideStatus(
      faceDetected: faceDetected,
      faceRightSize: faceRightSize,
      faceFrontal: faceFrontal,
      eyesOpen: eyesOpen,
      brightEnough: brightEnough,
      stable: stable,
      guidance: guidance,
    );
  }
}

/// Visual overlay widget showing face quality indicators.
class FaceGuideIndicators extends StatelessWidget {
  final FaceGuideStatus status;

  const FaceGuideIndicators({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (!status.faceDetected) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(status.faceRightSize, 'Size'),
          const SizedBox(width: 16),
          _dot(status.faceFrontal, 'Frontal'),
          const SizedBox(width: 16),
          _dot(status.eyesOpen, 'Eyes'),
          const SizedBox(width: 16),
          _dot(status.stable, 'Stable'),
        ],
      ),
    );
  }

  Widget _dot(bool ok, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? AppColors.success : Colors.grey.shade500,
            boxShadow: ok
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ok ? AppColors.success : Colors.grey.shade500,
            fontWeight: ok ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
