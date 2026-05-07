import SwiftUI
import Flutter

// MARK: - Data Models

struct LeaveBalance: Identifiable {
    let id = UUID()
    let type: String
    let used: Int
    let total: Int
    let color: Color

    var progress: CGFloat {
        total > 0 ? CGFloat(used) / CGFloat(total) : 0
    }
}

struct Announcement: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

// MARK: - ViewModel

class DashboardViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    // User
    @Published var userName: String = "User"
    @Published var userInitials: String = "U"
    @Published var greeting: String = "Good Morning"

    // Attendance
    @Published var isPunchedIn: Bool = false
    @Published var attendanceStatus: String = "Not Checked In"
    @Published var punchInTime: String = "--:--"
    @Published var punchOutTime: String = "--:--"
    @Published var workedHours: String = "0h 0m"

    // Stats
    @Published var presentDays: Int = 0
    @Published var leaveDays: Int = 0
    @Published var absentDays: Int = 0

    // Leave balances
    @Published var leaveBalances: [LeaveBalance] = []

    // Announcements
    @Published var announcements: [Announcement] = []

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        computeGreeting()
        if let args = args {
            update(from: args)
        }
    }

    private func computeGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greeting = "Good Morning"
        } else if hour < 17 {
            greeting = "Good Afternoon"
        } else {
            greeting = "Good Evening"
        }
    }

    func update(from data: [String: Any]) {
        if let name = data["userName"] as? String {
            userName = name
            let parts = name.split(separator: " ")
            userInitials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
        }

        if let punched = data["isPunchedIn"] as? Bool {
            isPunchedIn = punched
            attendanceStatus = punched ? "Checked In" : "Not Checked In"
        }

        if let t = data["punchInTime"] as? String { punchInTime = t }
        if let t = data["punchOutTime"] as? String { punchOutTime = t }
        if let t = data["workedHours"] as? String { workedHours = t }

        if let p = data["presentDays"] as? Int { presentDays = p }
        if let l = data["leaveDays"] as? Int { leaveDays = l }
        if let a = data["absentDays"] as? Int { absentDays = a }

        // Leave balances
        if let balances = data["leaveBalances"] as? [[String: Any]] {
            let colors: [Color] = [
                Color(hex: "3B5FE5"), Color(hex: "10B981"),
                Color(hex: "F59E0B"), Color(hex: "EF4444"),
                Color(hex: "8B5CF6"),
            ]
            leaveBalances = balances.enumerated().map { idx, b in
                LeaveBalance(
                    type: b["type"] as? String ?? "Leave",
                    used: b["used"] as? Int ?? 0,
                    total: b["total"] as? Int ?? 0,
                    color: colors[idx % colors.count]
                )
            }
        }

        // Announcements
        if let items = data["announcements"] as? [[String: Any]] {
            announcements = items.map {
                Announcement(
                    title: $0["title"] as? String ?? "",
                    body: $0["body"] as? String ?? ""
                )
            }
        }
    }
}
