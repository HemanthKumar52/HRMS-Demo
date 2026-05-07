import SwiftUI
import Flutter

// MARK: - Data Models

struct RequestItem: Identifiable {
    let id = UUID()
    let requestId: String
    let type: String // "leave", "attendance", "claim", "ticket"
    let title: String
    let subtitle: String
    let status: String // "pending", "approved", "rejected", "cancelled"
    let date: String
    let amount: String?
}

// MARK: - ViewModel

class RequestsViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var selectedTab: Int = 0
    @Published var requests: [RequestItem] = []
    @Published var isLoading: Bool = false

    let tabs = ["All", "Leave", "Attendance", "Claims", "Tickets"]

    var filteredRequests: [RequestItem] {
        if selectedTab == 0 { return requests }
        let typeMap = ["", "leave", "attendance", "claim", "ticket"]
        let filterType = typeMap[selectedTab]
        return requests.filter { $0.type == filterType }
    }

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let tab = data["selectedTab"] as? Int { selectedTab = tab }

        if let items = data["requests"] as? [[String: Any]] {
            requests = items.map { r in
                RequestItem(
                    requestId: r["id"] as? String ?? "",
                    type: r["type"] as? String ?? "",
                    title: r["title"] as? String ?? "",
                    subtitle: r["subtitle"] as? String ?? "",
                    status: r["status"] as? String ?? "pending",
                    date: r["date"] as? String ?? "",
                    amount: r["amount"] as? String
                )
            }
        }
    }

    func selectTab(_ index: Int) {
        HapticManager.shared.select()
        selectedTab = index
        channel?.invokeMethod("tabChanged", arguments: ["tab": index])
    }

    func openDetail(_ request: RequestItem) {
        HapticManager.shared.light()
        channel?.invokeMethod("navigate", arguments: [
            "screen": "requestDetail",
            "requestId": request.requestId,
            "type": request.type
        ])
    }

    func createNew() {
        HapticManager.shared.medium()
        channel?.invokeMethod("navigate", arguments: ["screen": "newRequest"])
    }
}
