import Flutter
import SwiftUI
import UIKit

// MARK: - Factory

class NativeHRDashboardViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeHRDashboardPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args as? [String: Any])
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

// MARK: - Platform View

class NativeHRDashboardPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<HRDashboardView>
    private let viewModel: HRViewModel
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        let channelName = "ppulse/native-hr-dashboard/\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewModel = HRViewModel(channel: channel, args: args)

        let view = HRDashboardView(viewModel: viewModel)
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
        case "updateData":
            DispatchQueue.main.async {
                self.viewModel.update(from: args ?? [:])
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
