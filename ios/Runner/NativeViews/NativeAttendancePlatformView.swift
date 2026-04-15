import Flutter
import SwiftUI
import UIKit

// MARK: - FlutterPlatformViewFactory

/// Registered as "ppulse/native-attendance-checkin" in AppDelegate.
/// Flutter creates this view via UiKitView with that viewType.
class NativeAttendanceViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        NativeAttendancePlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            args: args as? [String: Any]
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - FlutterPlatformView

/// Wraps the SwiftUI AttendanceCheckInView inside a UIHostingController
/// and exposes it as a Flutter platform view.
class NativeAttendancePlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<AttendanceCheckInView>
    private let viewModel: AttendanceCheckInViewModel
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        // Per-view MethodChannel (unique ID so multiple instances don't clash).
        let channelName = "ppulse/native-attendance-checkin/\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

        viewModel = AttendanceCheckInViewModel(channel: channel)

        // Apply any creation params from Flutter.
        if let userName = args?["userName"] as? String {
            viewModel.subtitle = "Welcome, \(userName)"
        }

        let swiftUIView = AttendanceCheckInView(viewModel: viewModel)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = frame

        super.init()

        // Listen for method calls FROM Flutter → Swift.
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleFlutterCall(call, result: result)
        }
    }

    func view() -> UIView {
        hostingController.view
    }

    // MARK: - Flutter → Swift calls

    private func handleFlutterCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "verificationSuccess":
            viewModel.onVerificationSuccess()
            result(nil)

        case "verificationFailed":
            let args = call.arguments as? [String: Any]
            let code = args?["code"] as? String ?? "UNKNOWN"
            let msg = args?["message"] as? String ?? "Verification failed"
            viewModel.onVerificationFailed(errorCode: code, message: msg)
            result(nil)

        case "updateStatus":
            let args = call.arguments as? [String: Any]
            if let title = args?["title"] as? String {
                DispatchQueue.main.async { self.viewModel.statusTitle = title }
            }
            if let msg = args?["message"] as? String {
                DispatchQueue.main.async { self.viewModel.statusMessage = msg }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
