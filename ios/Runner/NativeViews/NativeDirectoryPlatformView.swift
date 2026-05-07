import Flutter
import SwiftUI
import UIKit

// MARK: - Directory Factory

class NativeDirectoryViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeDirectoryPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args as? [String: Any])
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeDirectoryPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<DirectoryView>
    private let viewModel: DirectoryViewModel
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        let channelName = "ppulse/native-directory/\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewModel = DirectoryViewModel(channel: channel, args: args)

        let view = DirectoryView(viewModel: viewModel)
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

// MARK: - Employee Detail Factory

class NativeEmployeeDetailViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        NativeEmployeeDetailPlatformView(frame: frame, viewId: viewId, messenger: messenger, args: args as? [String: Any])
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeEmployeeDetailPlatformView: NSObject, FlutterPlatformView {
    private let hostingController: UIHostingController<EmployeeDetailView>
    private let viewModel: DirectoryViewModel
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]?) {
        let channelName = "ppulse/native-employee-detail/\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewModel = DirectoryViewModel(channel: channel, args: args)

        let view = EmployeeDetailView(viewModel: viewModel)
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
