import SwiftUI
import Flutter

// MARK: - ViewModel

class ShellViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var selectedTab: Int = 0
    @Published var userRole: String = "employee" // "employee", "manager", "admin", "hr"
    @Published var userName: String = "User"
    @Published var showDynamicIsland: Bool = false
    @Published var dynamicIslandText: String = ""

    var tabItems: [(icon: String, label: String)] {
        var items: [(String, String)] = [
            ("house.fill", "Home"),
            ("doc.text.fill", "Requests"),
            ("clock.fill", "Attendance"),
            ("indianrupeesign.circle.fill", "Payslip"),
        ]
        if userRole == "manager" || userRole == "admin" || userRole == "hr" {
            items.append(("person.2.fill", "Team"))
        }
        return items
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let tab = data["selectedTab"] as? Int { selectedTab = tab }
        if let role = data["userRole"] as? String { userRole = role }
        if let name = data["userName"] as? String { userName = name }

        if let island = data["dynamicIsland"] as? [String: Any] {
            showDynamicIsland = island["show"] as? Bool ?? false
            dynamicIslandText = island["text"] as? String ?? ""
        }
    }

    func selectTab(_ index: Int) {
        HapticManager.shared.select()
        selectedTab = index
        channel?.invokeMethod("tabChanged", arguments: ["tab": index])
    }
}
