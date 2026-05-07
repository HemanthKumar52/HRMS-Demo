import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native_ios_views.dart';

/// Wraps a Dart screen with its native iOS equivalent.
/// On iOS: shows the native SwiftUI view.
/// On Android: shows the Dart widget.
///
/// Handles the MethodChannel communication:
/// - Swift→Dart navigation calls
/// - Data updates from Dart→Swift
///
/// Usage in any screen:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return IOSScreenWrapper(
///     iosViewType: NativeViewTypes.attendance,
///     iosParams: _buildIOSParams(),
///     onNavigate: (screen) => _navigateTo(screen),
///     dartChild: _buildDartUI(),
///   );
/// }
/// ```
class IOSScreenWrapper extends StatefulWidget {
  final String iosViewType;
  final Map<String, dynamic>? iosParams;
  final void Function(String screen, Map<String, dynamic>? args)? onNavigate;
  final void Function(MethodChannel channel)? onChannelReady;
  final Widget dartChild;

  const IOSScreenWrapper({
    super.key,
    required this.iosViewType,
    this.iosParams,
    this.onNavigate,
    this.onChannelReady,
    required this.dartChild,
  });

  @override
  State<IOSScreenWrapper> createState() => _IOSScreenWrapperState();
}

class _IOSScreenWrapperState extends State<IOSScreenWrapper> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    if (!shouldUseNativeIOS) return widget.dartChild;

    return NativeIOSView(
      viewType: widget.iosViewType,
      creationParams: widget.iosParams,
      onChannelReady: (channel) {
        _channel = channel;
        widget.onChannelReady?.call(channel);
      },
      onNativeCall: _handleNativeCall,
    );
  }

  void _handleNativeCall(MethodCall call) {
    switch (call.method) {
      case 'navigate':
        final args = call.arguments as Map?;
        final screen = args?['screen'] as String? ?? '';
        widget.onNavigate?.call(screen, args?.cast<String, dynamic>());
        break;
      case 'openProfile':
        widget.onNavigate?.call('profile', null);
        break;
      case 'cancel':
      case 'dismiss':
        Navigator.of(context).maybePop();
        break;
      case 'logout':
        widget.onNavigate?.call('logout', null);
        break;
      case 'startCamera':
      case 'captureAndVerify':
        // Forward camera commands to Dart camera logic
        widget.onNavigate?.call(
          call.method,
          call.arguments as Map<String, dynamic>?,
        );
        break;
    }
  }

  /// Send data update to native view
  void updateNativeData(Map<String, dynamic> data) {
    _channel?.invokeMethod('updateData', data);
  }
}
