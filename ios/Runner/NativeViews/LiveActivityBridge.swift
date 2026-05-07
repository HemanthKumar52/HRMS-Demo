import Flutter
import UIKit

// MARK: - Live Activity Bridge
// Bridges Flutter live_activities calls to native ActivityKit (iOS 16.1+)
// Handles: attendance punch, leave tracking, shift reminders, payroll alerts

// Note: Full ActivityKit requires a Widget Extension target. This bridge
// provides the MethodChannel interface and data models. The Widget Extension
// (PPulseWidgets) must be added as a separate target in Xcode.

struct AttendanceLiveData {
    let userName: String
    let punchInTime: String
    let elapsedMinutes: Int
    let status: String // "active", "break", "overtime"
}

struct LeaveLiveData {
    let leaveType: String
    let startDate: String
    let endDate: String
    let status: String // "pending", "approved", "rejected"
    let approverName: String
}

// MARK: - Flutter Bridge

class LiveActivityMethodChannelHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.ppulse.hrms_demo/ios_live_activity",
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {

            // ── Attendance Live Activity ──
            case "startAttendanceLiveActivity":
                let args = call.arguments as? [String: Any] ?? [:]
                let data = AttendanceLiveData(
                    userName: args["userName"] as? String ?? "",
                    punchInTime: args["punchInTime"] as? String ?? "",
                    elapsedMinutes: args["elapsedMinutes"] as? Int ?? 0,
                    status: args["status"] as? String ?? "active"
                )
                startAttendanceActivity(data: data)
                result(nil)

            case "updateAttendanceLiveActivity":
                let args = call.arguments as? [String: Any] ?? [:]
                updateAttendanceActivity(
                    elapsedMinutes: args["elapsedMinutes"] as? Int ?? 0,
                    status: args["status"] as? String ?? "active"
                )
                result(nil)

            case "endAttendanceLiveActivity":
                endAttendanceActivity()
                result(nil)

            // ── Leave Live Activity ──
            case "startLeaveLiveActivity":
                let args = call.arguments as? [String: Any] ?? [:]
                let data = LeaveLiveData(
                    leaveType: args["leaveType"] as? String ?? "",
                    startDate: args["startDate"] as? String ?? "",
                    endDate: args["endDate"] as? String ?? "",
                    status: args["status"] as? String ?? "pending",
                    approverName: args["approverName"] as? String ?? ""
                )
                startLeaveActivity(data: data)
                result(nil)

            case "updateLeaveLiveActivity":
                let args = call.arguments as? [String: Any] ?? [:]
                updateLeaveActivity(status: args["status"] as? String ?? "pending")
                result(nil)

            case "endLeaveLiveActivity":
                endLeaveActivity()
                result(nil)

            // ── Dynamic Island Toast ──
            case "showDynamicIslandToast":
                let args = call.arguments as? [String: Any] ?? [:]
                showDynamicIslandToast(
                    title: args["title"] as? String ?? "",
                    icon: args["icon"] as? String ?? "checkmark.circle.fill",
                    color: args["color"] as? String ?? "3B82F6"
                )
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

// MARK: - ActivityKit Stubs
// These become real implementations when the Widget Extension is added.

private func startAttendanceActivity(data: AttendanceLiveData) {
    if #available(iOS 16.1, *) {
        // ActivityKit.request() requires Widget Extension target
        // For now, show a local notification as fallback
        showLocalNotification(
            title: "Checked In",
            body: "\(data.userName) punched in at \(data.punchInTime)"
        )
    }
}

private func updateAttendanceActivity(elapsedMinutes: Int, status: String) {
    if #available(iOS 16.1, *) {
        // Activity.update() — requires Widget Extension
    }
}

private func endAttendanceActivity() {
    if #available(iOS 16.1, *) {
        // Activity.end() — requires Widget Extension
    }
}

private func startLeaveActivity(data: LeaveLiveData) {
    if #available(iOS 16.1, *) {
        showLocalNotification(
            title: "Leave Request",
            body: "\(data.leaveType): \(data.startDate) - \(data.endDate) (\(data.status))"
        )
    }
}

private func updateLeaveActivity(status: String) {
    if #available(iOS 16.1, *) {
        // Activity.update()
    }
}

private func endLeaveActivity() {
    if #available(iOS 16.1, *) {
        // Activity.end()
    }
}

// MARK: - Dynamic Island Toast (iOS 16+ devices with Dynamic Island)

private func showDynamicIslandToast(title: String, icon: String, color: String) {
    // On devices with Dynamic Island (iPhone 14 Pro+), this could use
    // ActivityKit compact/expanded presentations.
    // Fallback: show native toast
    ToastPresenter.shared.show(message: title, style: .info, duration: 2.0)
}

// MARK: - Local Notification Helper

private func showLocalNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil // Immediate
    )

    UNUserNotificationCenter.current().add(request)
}
