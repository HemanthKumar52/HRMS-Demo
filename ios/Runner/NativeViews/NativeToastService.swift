import SwiftUI
import UIKit
import Flutter

// MARK: - iOS Native Toast System
// Replaces Flutter SnackBars with native iOS-style toasts
// Supports: success, error, warning, info styles
// Uses native blur, haptics, and spring animations

enum ToastStyle {
    case success, error, warning, info

    var backgroundColor: Color {
        switch self {
        case .success: return Color(hex: "10B981")
        case .error: return Color(hex: "EF4444")
        case .warning: return Color(hex: "F59E0B")
        case .info: return Color(hex: "3B82F6")
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .error: return .error
        case .warning: return .warning
        case .info: return .success
        }
    }
}

// MARK: - Toast View (SwiftUI)

struct ToastView: View {
    let message: String
    let style: ToastStyle
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Glass effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .fill(style.backgroundColor.opacity(0.85))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: style.backgroundColor.opacity(0.3), radius: 12, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Presenter (UIKit-based for overlay)

class ToastPresenter {
    static let shared = ToastPresenter()
    private init() {}

    private var currentWindow: UIWindow?

    func show(message: String, style: ToastStyle, duration: TimeInterval = 2.5) {
        DispatchQueue.main.async {
            // Haptic
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(style.hapticType)

            // Create overlay window
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }

            let window = UIWindow(windowScene: scene)
            window.windowLevel = .statusBar + 1
            window.backgroundColor = .clear
            window.isUserInteractionEnabled = true

            let hostingController = UIHostingController(rootView: ToastOverlayView(
                message: message,
                style: style,
                onDismiss: { [weak self] in
                    self?.dismiss()
                }
            ))
            hostingController.view.backgroundColor = .clear
            window.rootViewController = hostingController
            window.makeKeyAndVisible()

            self.currentWindow = window

            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.dismiss()
            }
        }
    }

    private func dismiss() {
        UIView.animate(withDuration: 0.3) {
            self.currentWindow?.alpha = 0
        } completion: { _ in
            self.currentWindow?.isHidden = true
            self.currentWindow = nil
        }
    }
}

// MARK: - Toast Overlay (full-screen transparent with toast at top)

struct ToastOverlayView: View {
    let message: String
    let style: ToastStyle
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack {
            if isVisible {
                ToastView(message: message, style: style, isPresented: Binding(
                    get: { self.isVisible },
                    set: { if !$0 { self.onDismiss() } }
                ))
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 50) // Below status bar
            }
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Flutter Method Channel for Toast

class ToastMethodChannelHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.ppulse.hrms_demo/ios_toast",
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "showToast":
                let args = call.arguments as? [String: Any]
                let message = args?["message"] as? String ?? ""
                let styleStr = args?["style"] as? String ?? "info"
                let duration = args?["duration"] as? Double ?? 2.5

                let style: ToastStyle
                switch styleStr {
                case "success": style = .success
                case "error": style = .error
                case "warning": style = .warning
                default: style = .info
                }

                ToastPresenter.shared.show(message: message, style: style, duration: duration)
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
