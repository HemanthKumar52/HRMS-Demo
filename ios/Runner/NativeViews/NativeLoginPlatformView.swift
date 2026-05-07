import Flutter
import SwiftUI
import UIKit

// MARK: - Factory

class NativeLoginViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeLoginPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args as? [String: Any])
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Platform View

class NativeLoginPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<LoginView>
    private let viewModel: LoginViewModel
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        let channelName = "ppulse/native-login/\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewModel = LoginViewModel(channel: channel)

        let view = LoginView(viewModel: viewModel)
        hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = frame

        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    func view() -> UIView { hostingController.view }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "loginResult":
            DispatchQueue.main.async {
                let success = args?["success"] as? Bool ?? false
                let error = args?["error"] as? String
                if success {
                    self.viewModel.onLoginSuccess()
                } else {
                    self.viewModel.onLoginFailed(error: error ?? "Login failed")
                }
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
