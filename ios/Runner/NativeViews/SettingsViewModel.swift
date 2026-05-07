import SwiftUI
import Flutter

class SettingsViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var userName: String = "User"
    @Published var userEmail: String = ""
    @Published var userInitials: String = "U"
    @Published var darkMode: Bool = false
    @Published var appLockEnabled: Bool = false
    @Published var notificationsEnabled: Bool = true
    @Published var appVersion: String = "1.0.0"

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let name = data["userName"] as? String {
            userName = name
            let parts = name.split(separator: " ")
            userInitials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        }
        if let email = data["userEmail"] as? String { userEmail = email }
        if let dark = data["darkMode"] as? Bool { darkMode = dark }
        if let lock = data["appLockEnabled"] as? Bool { appLockEnabled = lock }
        if let notif = data["notificationsEnabled"] as? Bool { notificationsEnabled = notif }
        if let ver = data["appVersion"] as? String { appVersion = ver }
    }

    func navigate(_ screen: String) {
        channel?.invokeMethod("navigate", arguments: ["screen": screen])
    }
}
