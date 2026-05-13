import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native iOS views disabled — unified Flutter UI on all platforms.
bool get shouldUseNativeIOS => false;

/// Registry of all native iOS view type IDs
class NativeViewTypes {
  static const dashboard = 'ppulse/native-dashboard';
  static const settings = 'ppulse/native-settings';
  static const profile = 'ppulse/native-profile';
  static const login = 'ppulse/native-login';
  static const faceVerify = 'ppulse/native-attendance-checkin';
  static const attendance = 'ppulse/native-attendance-screen';
  static const requests = 'ppulse/native-requests';
  static const payslip = 'ppulse/native-payslip';
  static const adminPanel = 'ppulse/native-admin-panel';
  static const manager = 'ppulse/native-manager';
  static const shell = 'ppulse/native-shell';
  static const splash = 'ppulse/native-splash';
  static const onboarding = 'ppulse/native-onboarding';
  static const directory = 'ppulse/native-directory';
  static const employeeDetail = 'ppulse/native-employee-detail';
  static const hrDashboard = 'ppulse/native-hr-dashboard';
}

/// Shows a native SwiftUI view on iOS via PlatformView.
/// On Android, shows [androidFallback] widget.
class NativeIOSView extends StatefulWidget {
  final String viewType;
  final Map<String, dynamic>? creationParams;
  final void Function(MethodChannel channel)? onChannelReady;
  final void Function(MethodCall call)? onNativeCall;

  const NativeIOSView({
    super.key,
    required this.viewType,
    this.creationParams,
    this.onChannelReady,
    this.onNativeCall,
  });

  @override
  State<NativeIOSView> createState() => _NativeIOSViewState();
}

class _NativeIOSViewState extends State<NativeIOSView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    return UiKitView(
      viewType: widget.viewType,
      creationParams: widget.creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
    );
  }

  void _onCreated(int viewId) {
    _channel = MethodChannel('${widget.viewType}/$viewId');
    _channel!.setMethodCallHandler(_handleNativeCall);
    widget.onChannelReady?.call(_channel!);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    widget.onNativeCall?.call(call);
    return null;
  }

  /// Send data to native view
  void updateData(Map<String, dynamic> data) {
    _channel?.invokeMethod('updateData', data);
  }
}

/// Convenience: wraps a screen with native iOS fallback.
/// Usage:
/// ```dart
/// return AdaptiveScreen(
///   iosViewType: NativeViewTypes.dashboard,
///   iosParams: {'userName': 'Admin'},
///   onNativeCall: _handleNativeCall,
///   androidBuilder: (context) => DartDashboardScreen(),
/// );
/// ```
class AdaptiveScreen extends StatelessWidget {
  final String iosViewType;
  final Map<String, dynamic>? iosParams;
  final void Function(MethodChannel channel)? onChannelReady;
  final void Function(MethodCall call)? onNativeCall;
  final WidgetBuilder androidBuilder;

  const AdaptiveScreen({
    super.key,
    required this.iosViewType,
    this.iosParams,
    this.onChannelReady,
    this.onNativeCall,
    required this.androidBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldUseNativeIOS) {
      return NativeIOSView(
        viewType: iosViewType,
        creationParams: iosParams,
        onChannelReady: onChannelReady,
        onNativeCall: onNativeCall,
      );
    }
    return androidBuilder(context);
  }
}

/// iOS-native toast via MethodChannel
class IOSToast {
  static const _channel = MethodChannel('com.ppulse.hrms_demo/ios_toast');

  static Future<void> show({
    required String message,
    String style = 'info', // success, error, warning, info
    double duration = 2.5,
  }) async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('showToast', {
      'message': message,
      'style': style,
      'duration': duration,
    });
  }
}

/// iOS-native security via MethodChannel
class IOSSecurity {
  static const _channel = MethodChannel('com.ppulse.hrms_demo/ios_security');

  static Future<bool> isJailbroken() async {
    if (!shouldUseNativeIOS) return false;
    return await _channel.invokeMethod<bool>('isJailbroken') ?? false;
  }

  static Future<bool> isDeveloperMode() async {
    if (!shouldUseNativeIOS) return false;
    return await _channel.invokeMethod<bool>('isDeveloperMode') ?? false;
  }

  static Future<String> getBiometricType() async {
    if (!shouldUseNativeIOS) return 'none';
    return await _channel.invokeMethod<String>('getBiometricType') ?? 'none';
  }

  static Future<void> enableScreenshotProtection() async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('enableScreenshotProtection');
  }

  static Future<void> disableScreenshotProtection() async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('disableScreenshotProtection');
  }

  static Future<bool> keychainSet(String key, String value) async {
    if (!shouldUseNativeIOS) return false;
    return await _channel.invokeMethod<bool>('keychainSet', {
          'key': key,
          'value': value,
        }) ??
        false;
  }

  static Future<String?> keychainGet(String key) async {
    if (!shouldUseNativeIOS) return null;
    return await _channel.invokeMethod<String>('keychainGet', {'key': key});
  }

  static Future<bool> keychainDelete(String key) async {
    if (!shouldUseNativeIOS) return false;
    return await _channel.invokeMethod<bool>('keychainDelete', {'key': key}) ??
        false;
  }
}

/// iOS Live Activity bridge
class IOSLiveActivity {
  static const _channel = MethodChannel(
    'com.ppulse.hrms_demo/ios_live_activity',
  );

  static Future<void> startAttendance({
    required String userName,
    required String punchInTime,
  }) async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('startAttendanceLiveActivity', {
      'userName': userName,
      'punchInTime': punchInTime,
      'elapsedMinutes': 0,
      'status': 'active',
    });
  }

  static Future<void> updateAttendance({
    required int elapsedMinutes,
    String status = 'active',
  }) async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('updateAttendanceLiveActivity', {
      'elapsedMinutes': elapsedMinutes,
      'status': status,
    });
  }

  static Future<void> endAttendance() async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('endAttendanceLiveActivity');
  }

  static Future<void> showDynamicIslandToast({
    required String title,
    String icon = 'checkmark.circle.fill',
    String color = '3B82F6',
  }) async {
    if (!shouldUseNativeIOS) return;
    await _channel.invokeMethod('showDynamicIslandToast', {
      'title': title,
      'icon': icon,
      'color': color,
    });
  }
}
