import SwiftUI
import Flutter

// MARK: - Data Models

struct AdminSection: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let icon: String
    let color: Color
    let count: Int
}

// MARK: - ViewModel

class AdminPanelViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var sections: [AdminSection] = []
    @Published var searchText: String = ""

    var filteredSections: [AdminSection] {
        if searchText.isEmpty { return sections }
        return sections.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        setupDefaultSections()
        if let args = args { update(from: args) }
    }

    private func setupDefaultSections() {
        sections = [
            AdminSection(key: "users", title: "Users", icon: "person.2.fill", color: Color(hex: "3B5FE5"), count: 0),
            AdminSection(key: "geofences", title: "Geofences", icon: "location.circle.fill", color: Color(hex: "10B981"), count: 0),
            AdminSection(key: "holidays", title: "Holidays", icon: "calendar.badge.exclamationmark", color: Color(hex: "F59E0B"), count: 0),
            AdminSection(key: "departments", title: "Departments", icon: "building.2.fill", color: Color(hex: "8B5CF6"), count: 0),
            AdminSection(key: "shifts", title: "Shifts", icon: "clock.arrow.2.circlepath", color: Color(hex: "EC4899"), count: 0),
            AdminSection(key: "policies", title: "Policies", icon: "doc.text.fill", color: Color(hex: "6366F1"), count: 0),
            AdminSection(key: "announcements", title: "Announcements", icon: "megaphone.fill", color: Color(hex: "F97316"), count: 0),
            AdminSection(key: "reports", title: "Reports", icon: "chart.bar.fill", color: Color(hex: "14B8A6"), count: 0),
            AdminSection(key: "roles", title: "Roles", icon: "shield.checkered", color: Color(hex: "64748B"), count: 0),
        ]
    }

    func update(from data: [String: Any]) {
        if let counts = data["sectionCounts"] as? [String: Int] {
            sections = sections.map { section in
                if let count = counts[section.key] {
                    return AdminSection(key: section.key, title: section.title, icon: section.icon, color: section.color, count: count)
                }
                return section
            }
        }
    }

    func openSection(_ section: AdminSection) {
        HapticManager.shared.light()
        channel?.invokeMethod("navigate", arguments: ["screen": "admin_\(section.key)"])
    }
}
