import SwiftUI
import Flutter

// MARK: - Data Models

struct HRTeamAttendance: Identifiable {
    let id = UUID()
    let department: String
    let present: Int
    let absent: Int
    let leave: Int
    let total: Int
}

struct ClaimItem: Identifiable {
    let id = UUID()
    let claimId: String
    let employeeName: String
    let amount: Double
    let type: String
    let status: String
    let date: String
}

// MARK: - ViewModel

class HRViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var selectedTab: Int = 0
    let tabs = ["Attendance", "Claims", "Directory"]

    // Attendance dashboard
    @Published var teamAttendance: [HRTeamAttendance] = []
    @Published var totalPresent: Int = 0
    @Published var totalAbsent: Int = 0
    @Published var totalLeave: Int = 0
    @Published var totalEmployees: Int = 0

    // Claims
    @Published var claimsTab: Int = 0 // 0=pending, 1=approved, 2=rejected
    @Published var claims: [ClaimItem] = []
    let claimsTabs = ["Pending", "Approved", "Rejected"]

    var filteredClaims: [ClaimItem] {
        let statusMap = ["pending", "approved", "rejected"]
        return claims.filter { $0.status == statusMap[claimsTab] }
    }

    // Directory filters
    @Published var directoryFilter: String = "All"
    @Published var directoryEmployees: [DirectoryEmployee] = []
    @Published var dirSearchText: String = ""

    var filteredDirectory: [DirectoryEmployee] {
        var list = directoryEmployees
        if directoryFilter != "All" {
            list = list.filter { $0.department == directoryFilter }
        }
        if !dirSearchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(dirSearchText)
                || $0.designation.localizedCaseInsensitiveContains(dirSearchText)
            }
        }
        return list
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let tab = data["selectedTab"] as? Int { selectedTab = tab }

        if let dashboard = data["dashboardData"] as? [String: Any] {
            totalPresent = dashboard["present"] as? Int ?? 0
            totalAbsent = dashboard["absent"] as? Int ?? 0
            totalLeave = dashboard["leave"] as? Int ?? 0
            totalEmployees = dashboard["total"] as? Int ?? 0

            if let teams = dashboard["departments"] as? [[String: Any]] {
                teamAttendance = teams.map { t in
                    HRTeamAttendance(
                        department: t["name"] as? String ?? "",
                        present: t["present"] as? Int ?? 0,
                        absent: t["absent"] as? Int ?? 0,
                        leave: t["leave"] as? Int ?? 0,
                        total: t["total"] as? Int ?? 0
                    )
                }
            }
        }

        if let claimData = data["claims"] as? [[String: Any]] {
            claims = claimData.map { c in
                ClaimItem(
                    claimId: c["id"] as? String ?? "",
                    employeeName: c["employeeName"] as? String ?? "",
                    amount: c["amount"] as? Double ?? 0,
                    type: c["type"] as? String ?? "",
                    status: c["status"] as? String ?? "pending",
                    date: c["date"] as? String ?? ""
                )
            }
        }

        let colors: [Color] = [
            Color(hex: "3B5FE5"), Color(hex: "10B981"), Color(hex: "F59E0B"),
            Color(hex: "EF4444"), Color(hex: "8B5CF6"), Color(hex: "EC4899"),
        ]
        if let emps = data["employees"] as? [[String: Any]] {
            directoryEmployees = emps.enumerated().map { idx, e in
                let name = e["name"] as? String ?? ""
                let parts = name.split(separator: " ")
                let initials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()
                return DirectoryEmployee(
                    employeeId: e["id"] as? String ?? "",
                    name: name,
                    designation: e["designation"] as? String ?? "",
                    department: e["department"] as? String ?? "",
                    email: e["email"] as? String ?? "",
                    phone: e["phone"] as? String ?? "",
                    avatarInitials: initials,
                    avatarColor: colors[idx % colors.count]
                )
            }
        }
    }

    func selectTab(_ index: Int) {
        HapticManager.shared.select()
        selectedTab = index
    }

    func approveClaim(_ claim: ClaimItem) {
        HapticManager.shared.success()
        channel?.invokeMethod("approveClaim", arguments: ["id": claim.claimId])
    }

    func rejectClaim(_ claim: ClaimItem) {
        HapticManager.shared.warning()
        channel?.invokeMethod("rejectClaim", arguments: ["id": claim.claimId])
    }

    func viewEmployee(_ emp: DirectoryEmployee) {
        HapticManager.shared.light()
        channel?.invokeMethod("navigate", arguments: [
            "screen": "employeeDetail",
            "employeeId": emp.employeeId
        ])
    }
}
