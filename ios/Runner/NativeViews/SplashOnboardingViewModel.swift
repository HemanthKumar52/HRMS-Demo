import SwiftUI
import Flutter

// MARK: - Data Models

struct PermissionRequest: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let description: String
    let icon: String
    var isGranted: Bool
}

// MARK: - ViewModel

class SplashOnboardingViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var currentScreen: String = "splash" // "splash", "onboarding"
    @Published var isDeveloperMode: Bool = false
    @Published var permissions: [PermissionRequest] = []

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        setupDefaultPermissions()
        if let args = args { update(from: args) }
    }

    private func setupDefaultPermissions() {
        permissions = [
            PermissionRequest(key: "camera", title: "Camera", description: "Required for face verification during attendance check-in", icon: "camera.fill", isGranted: false),
            PermissionRequest(key: "location", title: "Location", description: "Required for geofence-based attendance verification", icon: "location.fill", isGranted: false),
            PermissionRequest(key: "notifications", title: "Notifications", description: "Stay updated with approvals and announcements", icon: "bell.fill", isGranted: false),
        ]
    }

    func update(from data: [String: Any]) {
        if let screen = data["screen"] as? String { currentScreen = screen }
        if let dev = data["isDeveloperMode"] as? Bool { isDeveloperMode = dev }

        if let permStatus = data["permissions"] as? [String: Bool] {
            for (index, perm) in permissions.enumerated() {
                if let granted = permStatus[perm.key] {
                    permissions[index].isGranted = granted
                }
            }
        }
    }

    func requestPermission(_ permission: PermissionRequest) {
        HapticManager.shared.light()
        channel?.invokeMethod("requestPermission", arguments: ["key": permission.key])
    }

    func continueToApp() {
        HapticManager.shared.medium()
        channel?.invokeMethod("navigate", arguments: ["screen": "login"])
    }

    func openSettings() {
        HapticManager.shared.medium()
        channel?.invokeMethod("openSettings", arguments: nil)
    }
}
