import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let registry = engineBridge.pluginRegistry
    GeneratedPluginRegistrant.register(with: registry)

    // ── Register native iOS platform views ──────────────────────────────
    // Use a unique key that doesn't collide with GeneratedPluginRegistrant.
    guard let registrar = registry.registrar(forPlugin: "PPulseNativeViewsPlugin")
    else { return }

    let attendanceFactory = NativeAttendanceViewFactory(messenger: registrar.messenger())
    registrar.register(attendanceFactory, withId: "ppulse/native-attendance-checkin")
  }
}
