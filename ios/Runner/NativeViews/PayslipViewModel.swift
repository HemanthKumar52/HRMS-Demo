import SwiftUI
import Flutter

// MARK: - Data Models

struct EarningItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let color: Color
}

struct DeductionItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
    let color: Color
}

// MARK: - ViewModel

class PayslipViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var month: String = "May"
    @Published var year: Int = 2026

    @Published var grossSalary: Double = 0
    @Published var netPay: Double = 0
    @Published var totalDeductions: Double = 0
    @Published var totalEarnings: Double = 0

    @Published var earnings: [EarningItem] = []
    @Published var deductions: [DeductionItem] = []

    @Published var employeeName: String = ""
    @Published var employeeId: String = ""
    @Published var designation: String = ""
    @Published var department: String = ""
    @Published var payDate: String = ""

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let m = data["month"] as? String { month = m }
        if let y = data["year"] as? Int { year = y }
        if let n = data["employeeName"] as? String { employeeName = n }
        if let i = data["employeeId"] as? String { employeeId = i }
        if let d = data["designation"] as? String { designation = d }
        if let d = data["department"] as? String { department = d }
        if let d = data["payDate"] as? String { payDate = d }

        if let g = data["grossSalary"] as? Double { grossSalary = g }
        if let n = data["netPay"] as? Double { netPay = n }
        if let d = data["totalDeductions"] as? Double { totalDeductions = d }
        if let e = data["totalEarnings"] as? Double { totalEarnings = e }

        let earningColors: [Color] = [
            Color(hex: "3B5FE5"), Color(hex: "10B981"),
            Color(hex: "F59E0B"), Color(hex: "8B5CF6"),
            Color(hex: "EC4899")
        ]
        if let items = data["earnings"] as? [[String: Any]] {
            earnings = items.enumerated().map { idx, e in
                EarningItem(
                    label: e["label"] as? String ?? "",
                    amount: e["amount"] as? Double ?? 0,
                    color: earningColors[idx % earningColors.count]
                )
            }
        }

        let deductionColors: [Color] = [
            Color(hex: "EF4444"), Color(hex: "F97316"),
            Color(hex: "64748B"), Color(hex: "6366F1")
        ]
        if let items = data["deductions"] as? [[String: Any]] {
            deductions = items.enumerated().map { idx, d in
                DeductionItem(
                    label: d["label"] as? String ?? "",
                    amount: d["amount"] as? Double ?? 0,
                    color: deductionColors[idx % deductionColors.count]
                )
            }
        }
    }

    func previousMonth() {
        HapticManager.shared.light()
        channel?.invokeMethod("previousMonth", arguments: nil)
    }

    func nextMonth() {
        HapticManager.shared.light()
        channel?.invokeMethod("nextMonth", arguments: nil)
    }

    func viewPayslip() {
        HapticManager.shared.medium()
        channel?.invokeMethod("viewPayslip", arguments: ["month": month, "year": year])
    }

    func downloadPayslip() {
        HapticManager.shared.medium()
        channel?.invokeMethod("downloadPayslip", arguments: ["month": month, "year": year])
    }
}
