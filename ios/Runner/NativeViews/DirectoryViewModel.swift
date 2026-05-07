import SwiftUI
import Flutter

// MARK: - Data Models

struct DirectoryEmployee: Identifiable {
    let id = UUID()
    let employeeId: String
    let name: String
    let designation: String
    let department: String
    let email: String
    let phone: String
    let avatarInitials: String
    let avatarColor: Color
}

struct EmployeeWorkInfo {
    let joinDate: String
    let employeeType: String
    let shift: String
    let reportingTo: String
}

struct EmployeeDetailData {
    let employee: DirectoryEmployee
    let workInfo: EmployeeWorkInfo
}

// MARK: - ViewModel

class DirectoryViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var employees: [DirectoryEmployee] = []
    @Published var searchText: String = ""
    @Published var selectedDepartment: String = "All"
    @Published var departments: [String] = ["All"]

    // Employee detail
    @Published var selectedEmployee: EmployeeDetailData?

    var filteredEmployees: [DirectoryEmployee] {
        var list = employees
        if selectedDepartment != "All" {
            list = list.filter { $0.department == selectedDepartment }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.designation.localizedCaseInsensitiveContains(searchText)
                || $0.department.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        let colors: [Color] = [
            Color(hex: "3B5FE5"), Color(hex: "10B981"), Color(hex: "F59E0B"),
            Color(hex: "EF4444"), Color(hex: "8B5CF6"), Color(hex: "EC4899"),
        ]

        if let items = data["employees"] as? [[String: Any]] {
            employees = items.enumerated().map { idx, e in
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

            let depts = Set(employees.map { $0.department }).sorted()
            departments = ["All"] + depts
        }

        if let empData = data["employeeData"] as? [String: Any] {
            let name = empData["name"] as? String ?? ""
            let parts = name.split(separator: " ")
            let initials = parts.prefix(2).map { String($0.prefix(1)) }.joined().uppercased()

            let emp = DirectoryEmployee(
                employeeId: empData["id"] as? String ?? "",
                name: name,
                designation: empData["designation"] as? String ?? "",
                department: empData["department"] as? String ?? "",
                email: empData["email"] as? String ?? "",
                phone: empData["phone"] as? String ?? "",
                avatarInitials: initials,
                avatarColor: colors[0]
            )

            let work = EmployeeWorkInfo(
                joinDate: empData["joinDate"] as? String ?? "",
                employeeType: empData["employeeType"] as? String ?? "",
                shift: empData["shift"] as? String ?? "",
                reportingTo: empData["reportingTo"] as? String ?? ""
            )

            selectedEmployee = EmployeeDetailData(employee: emp, workInfo: work)
        }
    }

    func viewEmployee(_ employee: DirectoryEmployee) {
        HapticManager.shared.light()
        channel?.invokeMethod("navigate", arguments: [
            "screen": "employeeDetail",
            "employeeId": employee.employeeId
        ])
    }

    func callEmployee(_ employee: DirectoryEmployee) {
        HapticManager.shared.light()
        channel?.invokeMethod("call", arguments: ["phone": employee.phone])
    }

    func emailEmployee(_ employee: DirectoryEmployee) {
        HapticManager.shared.light()
        channel?.invokeMethod("email", arguments: ["email": employee.email])
    }
}
