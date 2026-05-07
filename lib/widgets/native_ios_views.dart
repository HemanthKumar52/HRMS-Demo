import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a native SwiftUI view on iOS via PlatformView, or returns null on Android.
/// Usage: if (Platform.isIOS) return NativeIOSView(viewType: 'ppulse/native-dashboard', ...);

class NativeIOSView extends StatefulWidget {
  final String viewType;
  final Map<String, dynamic>? creationParams;
  final void Function(MethodChannel channel)? onChannelReady;

  const NativeIOSView({
    super.key,
    required this.viewType,
    this.creationParams,
    this.onChannelReady,
  });

  @override
  State<NativeIOSView> createState() => _NativeIOSViewState();
}

class _NativeIOSViewState extends State<NativeIOSView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return const Center(child: Text('Native view only available on iOS'));
    }

    return UiKitView(
      viewType: widget.viewType,
      creationParams: widget.creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onCreated,
    );
  }

  void _onCreated(int viewId) {
    final channelName = '${widget.viewType}/$viewId';
    _channel = MethodChannel(channelName);

    // Handle calls from Swift → Dart
    _channel!.setMethodCallHandler(_handleNativeCall);

    widget.onChannelReady?.call(_channel!);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    // Subclasses or parent widgets handle specific calls
    // via onChannelReady callback
    return null;
  }
}

/// Helper to check if we should use native iOS views
bool get shouldUseNativeIOS {
  try {
    return Platform.isIOS;
  } catch (_) {
    return false;
  }
}
