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

    // Attendance Screen (calendar/history)
    registrar.register(
      NativeAttendanceScreenViewFactory(messenger: messenger),
      withId: "ppulse/native-attendance-screen"
    )

    // Requests
    registrar.register(
      NativeRequestsViewFactory(messenger: messenger),
      withId: "ppulse/native-requests"
    )

    // Payslip
    registrar.register(
      NativePayslipViewFactory(messenger: messenger),
      withId: "ppulse/native-payslip"
    )

    // Admin Panel
    registrar.register(
      NativeAdminPanelViewFactory(messenger: messenger),
      withId: "ppulse/native-admin-panel"
    )

    // Manager
    registrar.register(
      NativeManagerViewFactory(messenger: messenger),
      withId: "ppulse/native-manager"
    )

    // Shell (Tab Container)
    registrar.register(
      NativeShellViewFactory(messenger: messenger),
      withId: "ppulse/native-shell"
    )

    // Splash
    registrar.register(
      NativeSplashViewFactory(messenger: messenger),
      withId: "ppulse/native-splash"
    )

    // Onboarding
    registrar.register(
      NativeOnboardingViewFactory(messenger: messenger),
      withId: "ppulse/native-onboarding"
    )

    // Directory
    registrar.register(
      NativeDirectoryViewFactory(messenger: messenger),
      withId: "ppulse/native-directory"
    )

    // Employee Detail
    registrar.register(
      NativeEmployeeDetailViewFactory(messenger: messenger),
      withId: "ppulse/native-employee-detail"
    )

    // HR Dashboard
    registrar.register(
      NativeHRDashboardViewFactory(messenger: messenger),
      withId: "ppulse/native-hr-dashboard"
    )
  }
}
