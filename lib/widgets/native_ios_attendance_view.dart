import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../screens/home/face_verification_dialog.dart';
import '../theme/app_theme.dart';

/// Native iOS attendance check-in view.
///
/// On iOS: renders a SwiftUI-based platform view via UiKitView with
/// MethodChannel bridge for camera capture + backend verification.
///
/// On Android: falls back to the existing Flutter [FaceVerificationDialog].
class NativeAttendanceCheckIn extends StatelessWidget {
  const NativeAttendanceCheckIn({super.key});

  /// Show the attendance check-in — picks native iOS or Flutter fallback.
  static Future<void> show(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _IOSNativeCheckInSheet(),
      );
    } else {
      await showDialog(
        context: context,
        builder: (_) => const FaceVerificationDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inline usage — same conditional.
    if (!kIsWeb && Platform.isIOS) {
      return const _IOSNativeCheckInSheet();
    }
    return const FaceVerificationDialog();
  }
}

// ─── iOS Native Sheet ─────────────────────────────────────────────────────

class _IOSNativeCheckInSheet extends StatefulWidget {
  const _IOSNativeCheckInSheet();

  @override
  State<_IOSNativeCheckInSheet> createState() => _IOSNativeCheckInSheetState();
}

class _IOSNativeCheckInSheetState extends State<_IOSNativeCheckInSheet> {
  static const _viewType = 'ppulse/native-attendance-checkin';
  MethodChannel? _channel;
  CameraController? _cameraController;
  final List<String> _extraFrames = [];

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('$_viewType/$viewId');
    _channel!.setMethodCallHandler(_handleNativeCall);
  }

  /// Handle calls FROM Swift → Flutter.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'startCamera':
        await _startCamera();
        return null;

      case 'captureAndVerify':
        await _captureAndVerify();
        return null;

      case 'cancel':
        await _disposeCamera();
        if (mounted) Navigator.pop(context);
        return null;

      case 'dismiss':
        await _disposeCamera();
        if (mounted) Navigator.pop(context);
        return null;

      default:
        throw PlatformException(code: 'NOT_IMPLEMENTED', message: call.method);
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
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

      // Capture 2 extra frames for liveness during the countdown.
      _extraFrames.clear();
      Timer.periodic(const Duration(milliseconds: 400), (timer) async {
        if (_extraFrames.length >= 2 || _cameraController == null) {
          timer.cancel();
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
    } catch (e) {
      _channel?.invokeMethod('verificationFailed', {
        'code': 'CAMERA_ERROR',
        'message': 'Could not start camera: $e',
      });
    }
  }

  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _channel?.invokeMethod('verificationFailed', {
        'code': 'CAMERA_ERROR',
        'message': 'Camera not ready',
      });
      return;
    }

    try {
      final shot = await _cameraController!.takePicture();
      await _disposeCamera();

      final bytes = await File(shot.path).readAsBytes();
      final b64 = base64Encode(bytes);
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));

      if (!mounted) return;
      final provider = context.read<AppProvider>();
      final err = await provider.facePunchIn(b64, extraFrames: _extraFrames);

      if (err == null || err == 'ALREADY_PUNCHED_IN') {
        _channel?.invokeMethod('verificationSuccess', null);
      } else {
        _channel?.invokeMethod('verificationFailed', {
          'code': err,
          'message': _humanMessage(err),
        });
      }
    } catch (e) {
      _channel?.invokeMethod('verificationFailed', {
        'code': 'VERIFY_ERROR',
        'message': 'Verification failed: $e',
      });
    }
  }

  String _humanMessage(String code) {
    switch (code) {
      case 'LOCATION_REQUIRED':
        return 'Enable location permission in Settings.';
      case 'GEOFENCE_OFFICE':
        return "You're at the office — use biometric punch.";
      case 'WFH_OUT_OF_ZONE':
        return 'Not in an authorized WFH location.';
      case 'FACE_MISMATCH':
        return 'Face does not match this account.';
      case 'FACE_VERIFICATION_FAILED':
        return 'Unknown user — verification failed.';
      case 'BIOMETRIC_PUNCH_ACTIVE':
        return 'Already checked in via biometric.';
      default:
        return 'Check in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: UiKitView(
          viewType: _viewType,
          creationParams: {
            'userName': provider.userName.split(' ').first,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      ),
    );
  }
}
