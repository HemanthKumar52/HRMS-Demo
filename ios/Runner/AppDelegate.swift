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

    let messenger = registrar.messenger()

    // Face verification (existing)
    registrar.register(
      NativeAttendanceViewFactory(messenger: messenger),
      withId: "ppulse/native-attendance-checkin"
    )

    // Dashboard
    registrar.register(
      NativeDashboardViewFactory(messenger: messenger),
      withId: "ppulse/native-dashboard"
    )

    // Settings
    registrar.register(
      NativeSettingsViewFactory(messenger: messenger),
      withId: "ppulse/native-settings"
    )

    // Profile
    registrar.register(
      NativeProfileViewFactory(messenger: messenger),
      withId: "ppulse/native-profile"
    )

    // Login
    registrar.register(
      NativeLoginViewFactory(messenger: messenger),
      withId: "ppulse/native-login"
    )
  }
}
