import SwiftUI
import Flutter

// MARK: - Data Models

struct DayAttendance: Identifiable {
    let id = UUID()
    let day: Int
    let status: String // "present", "absent", "leave", "holiday", "weekend", ""
    let punchIn: String
    let punchOut: String
}

struct WeeklyHour: Identifiable {
    let id = UUID()
    let day: String
    let hours: Double
}

// MARK: - ViewModel

class AttendanceScreenViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var selectedMonth: String = "May"
    @Published var selectedYear: Int = 2026
    @Published var monthlyData: [DayAttendance] = []
    @Published var weeklyData: [WeeklyHour] = []

    // Today
    @Published var todayStatus: String = "Present"
    @Published var todayPunchIn: String = "09:00 AM"
    @Published var todayPunchOut: String = "--:--"
    @Published var todayWorkedHours: String = "4h 32m"
    @Published var todayOvertime: String = "0h 0m"

    // Summary
    @Published var totalPresent: Int = 0
    @Published var totalAbsent: Int = 0
    @Published var totalLeave: Int = 0
    @Published var totalHoliday: Int = 0

    init(channel: FlutterMethodChannel?, args: [String: Any]?) {
        self.channel = channel
        if let args = args { update(from: args) }
    }

    func update(from data: [String: Any]) {
        if let m = data["month"] as? String { selectedMonth = m }
        if let y = data["year"] as? Int { selectedYear = y }

        if let today = data["todayStatus"] as? [String: Any] {
            todayStatus = today["status"] as? String ?? "Present"
            todayPunchIn = today["punchIn"] as? String ?? "--:--"
            todayPunchOut = today["punchOut"] as? String ?? "--:--"
            todayWorkedHours = today["workedHours"] as? String ?? "0h 0m"
            todayOvertime = today["overtime"] as? String ?? "0h 0m"
        }

        if let monthly = data["monthlyData"] as? [[String: Any]] {
            monthlyData = monthly.map { d in
                DayAttendance(
                    day: d["day"] as? Int ?? 0,
                    status: d["status"] as? String ?? "",
                    punchIn: d["punchIn"] as? String ?? "",
                    punchOut: d["punchOut"] as? String ?? ""
                )
            }
            totalPresent = monthlyData.filter { $0.status == "present" }.count
            totalAbsent = monthlyData.filter { $0.status == "absent" }.count
            totalLeave = monthlyData.filter { $0.status == "leave" }.count
            totalHoliday = monthlyData.filter { $0.status == "holiday" }.count
        }

        if let weekly = data["weeklyData"] as? [[String: Any]] {
            weeklyData = weekly.map { w in
                WeeklyHour(
                    day: w["day"] as? String ?? "",
                    hours: w["hours"] as? Double ?? 0
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
}
