import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Face enrollment screen — user captures their face to enable face check-in.
class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

enum _EnrollState { checking, notEnrolled, camera, processing, success, error }

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  _EnrollState _state = _EnrollState.checking;
  String _message = '';
  CameraController? _cameraController;
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _checkEnrollment();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
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

  Future<void> _startCamera() async {
    setState(() => _state = _EnrollState.camera);

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras found');

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _EnrollState.error;
          _message = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _state = _EnrollState.processing;
      _message = 'Processing face...';
    });

    try {
      final file = await _cameraController!.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      unawaited(File(file.path).delete().catchError((_) => File(file.path)));

      await _cameraController?.dispose();
      _cameraController = null;

      await ApiService.enrollFaceSelf(base64Image);

      if (mounted) {
        setState(() {
          _state = _EnrollState.success;
          _message = 'Face enrolled successfully!';
          _isEnrolled = true;
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _EnrollState.error;
          _message = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Camera preview or status icon
              ClipOval(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: _buildPreview(isDark),
                ),
              ),

              const SizedBox(height: 24),

              // Status message
              Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _state == _EnrollState.error
                      ? AppColors.danger
                      : _state == _EnrollState.success
                      ? AppColors.success
                      : isDark
                      ? Colors.white70
                      : Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 8),

              // Guidelines
              if (_state == _EnrollState.camera) ...[
                const SizedBox(height: 8),
                _guideline(Icons.wb_sunny_outlined, 'Good lighting'),
                _guideline(Icons.face, 'Neutral expression'),
                _guideline(Icons.visibility_off, 'No sunglasses or mask'),
              ],

              const Spacer(),

              // Action button
              _buildButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    if (_state == _EnrollState.camera &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    if (_state == _EnrollState.processing) {
      return Container(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_state == _EnrollState.success) {
      return Container(
        color: AppColors.success.withAlpha(30),
        child: const Center(
          child: Icon(Icons.check_circle, size: 80, color: AppColors.success),
        ),
      );
    }

    if (_state == _EnrollState.error) {
      return Container(
        color: AppColors.danger.withAlpha(30),
        child: const Center(
          child: Icon(Icons.error_outline, size: 80, color: AppColors.danger),
        ),
      );
    }

    return Container(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          _isEnrolled ? Icons.face_retouching_natural : Icons.face,
          size: 80,
          color: _isEnrolled ? AppColors.success : Colors.grey,
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
            onPressed: _capture,
            icon: const Icon(Icons.camera),
            label: const Text('Capture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
