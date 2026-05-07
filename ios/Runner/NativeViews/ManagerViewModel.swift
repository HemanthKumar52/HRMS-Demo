import SwiftUI
import Flutter

// MARK: - Data Models

struct TeamMember: Identifiable {
    let id = UUID()
    let employeeId: String
    let name: String
    let designation: String
    let status: String // "present", "absent", "leave", "remote"
    let avatarInitials: String
}

struct ApprovalItem: Identifiable {
    let id = UUID()
    let approvalId: String
    let employeeName: String
    let type: String
    let title: String
    let dateRange: String
    let reason: String
}

struct AnalyticsData: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let color: Color
}

// MARK: - ViewModel

class ManagerViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var selectedTab: Int = 0
    let tabs = ["My Team", "Approvals", "Analytics"]

    // Team
    @Published var teamMembers: [TeamMember] = []
    @Published var teamSearchText: String = ""

    // Approvals
    @Published var approvals: [ApprovalItem] = []

    // Analytics
    @Published var analyticsData: [AnalyticsData] = []
    @Published var totalEmployees: Int = 0
    @Published var presentToday: Int = 0
    @Published var onLeaveToday: Int = 0
    @Published var absentToday: Int = 0

    var filteredTeam: [TeamMember] {
        if teamSearchText.isEmpty { return teamMembers }
        return teamMembers.filter {
            $0.name.localizedCaseInsensitiveContains(teamSearchText)
            || $0.designation.localizedCaseInsensitiveContains(teamSearchText)
        }
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let tab = data["selectedTab"] as? Int { selectedTab = tab }

        if let team = data["teamData"] as? [[String: Any]] {
            teamMembers = team.map { t in
                let name = t["name"] as? String ?? ""
                let parts = name.split(separator: " ")
                let initials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
                return TeamMember(
                    employeeId: t["id"] as? String ?? "",
                    name: name,
                    designation: t["designation"] as? String ?? "",
                    status: t["status"] as? String ?? "",
                    avatarInitials: initials
                )
            }
        }

        if let items = data["approvals"] as? [[String: Any]] {
            approvals = items.map { a in
                ApprovalItem(
                    approvalId: a["id"] as? String ?? "",
                    employeeName: a["employeeName"] as? String ?? "",
                    type: a["type"] as? String ?? "",
                    title: a["title"] as? String ?? "",
                    dateRange: a["dateRange"] as? String ?? "",
                    reason: a["reason"] as? String ?? ""
                )
            }
        }

        if let analytics = data["analyticsData"] as? [String: Any] {
            totalEmployees = analytics["total"] as? Int ?? 0
            presentToday = analytics["present"] as? Int ?? 0
            onLeaveToday = analytics["leave"] as? Int ?? 0
            absentToday = analytics["absent"] as? Int ?? 0

            analyticsData = [
                AnalyticsData(label: "Present", value: presentToday, color: Color(hex: "10B981")),
                AnalyticsData(label: "On Leave", value: onLeaveToday, color: Color(hex: "F59E0B")),
                AnalyticsData(label: "Absent", value: absentToday, color: Color(hex: "EF4444")),
            ]
        }
    }

    func selectTab(_ index: Int) {
        HapticManager.shared.select()
        selectedTab = index
    }

    func viewEmployee(_ member: TeamMember) {
        HapticManager.shared.light()
        channel?.invokeMethod("navigate", arguments: [
            "screen": "employeeDetail",
            "employeeId": member.employeeId
        ])
    }

    func approve(_ item: ApprovalItem) {
        HapticManager.shared.success()
        channel?.invokeMethod("approve", arguments: ["id": item.approvalId])
    }

    func reject(_ item: ApprovalItem) {
        HapticManager.shared.warning()
        channel?.invokeMethod("reject", arguments: ["id": item.approvalId])
    }
}
