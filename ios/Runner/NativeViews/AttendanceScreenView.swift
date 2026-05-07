import SwiftUI

// MARK: - Attendance Screen View

struct AttendanceScreenView: View {
    @ObservedObject var viewModel: AttendanceScreenViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Month selector
                monthSelector
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .fadeInOnAppear(delay: 0)

                // Today's attendance detail
                todayCard
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.05)

                // Monthly summary stats
                summaryStats
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.1)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.15)

                // Weekly hours bar chart
                weeklyChart
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.2)

                Spacer(minLength: 100)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "3B5FE5"))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.selectedMonth)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("\(viewModel.selectedYear)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "3B5FE5"))
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Today Card

    private var todayCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(viewModel.todayStatus)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: statusIcon(viewModel.todayStatus))
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 0) {
                _AttendanceInfoItem(label: "Check In", value: viewModel.todayPunchIn)
                _AttendanceInfoItem(label: "Check Out", value: viewModel.todayPunchOut)
                _AttendanceInfoItem(label: "Hours", value: viewModel.todayWorkedHours)
                _AttendanceInfoItem(label: "Overtime", value: viewModel.todayOvertime)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "3B5FE5"), Color(hex: "5B7FF9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: "3B5FE5").opacity(0.3), radius: 16, y: 6)
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: 12) {
            _MiniStatCard(label: "Present", value: "\(viewModel.totalPresent)", color: Color(hex: "10B981"))
            _MiniStatCard(label: "Absent", value: "\(viewModel.totalAbsent)", color: Color(hex: "EF4444"))
            _MiniStatCard(label: "Leave", value: "\(viewModel.totalLeave)", color: Color(hex: "F59E0B"))
            _MiniStatCard(label: "Holiday", value: "\(viewModel.totalHoliday)", color: Color(hex: "8B5CF6"))
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Overview")
                .font(.system(size: 16, weight: .bold))

            // Day labels
            let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLabels[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }

                ForEach(viewModel.monthlyData) { day in
                    _CalendarDayCell(day: day)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 16, weight: .bold))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(viewModel.weeklyData) { item in
                    VStack(spacing: 6) {
                        Text(String(format: "%.1f", item.hours))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3B5FE5"), Color(hex: "5B7FF9")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(4, CGFloat(item.hours) * 10))

                        Text(item.day)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func statusIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "present": return "checkmark.circle.fill"
        case "absent": return "xmark.circle.fill"
        case "leave": return "bed.double.fill"
        default: return "clock.fill"
        }
    }
}

// MARK: - Sub-components

private struct _AttendanceInfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct _MiniStatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct _CalendarDayCell: View {
    let day: DayAttendance

    var body: some View {
        Text(day.day > 0 ? "\(day.day)" : "")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(day.status == "absent" ? .white : .primary)
            .frame(width: 32, height: 32)
            .background(backgroundColor)
            .clipShape(Circle())
    }

    private var backgroundColor: Color {
        switch day.status {
        case "present": return Color(hex: "10B981").opacity(0.2)
        case "absent": return Color(hex: "EF4444")
        case "leave": return Color(hex: "F59E0B").opacity(0.2)
        case "holiday": return Color(hex: "8B5CF6").opacity(0.2)
        case "weekend": return Color(UIColor.systemGray5)
        default: return .clear
        }
    }
}
