import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Greeting
                greetingSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Attendance card
                attendanceCard
                    .padding(.horizontal, 20)

                // Quick stats row
                quickStatsRow
                    .padding(.horizontal, 20)

                // Leave balance
                leaveBalanceSection
                    .padding(.horizontal, 20)

                // Quick actions
                quickActionsGrid
                    .padding(.horizontal, 20)

                // Announcements
                if !viewModel.announcements.isEmpty {
                    announcementsSection
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(viewModel.userName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            Spacer()
            // Profile avatar
            Circle()
                .fill(Color(hex: "3B5FE5").opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(viewModel.userInitials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "3B5FE5"))
                )
                .onTapGesture {
                    viewModel.channel?.invokeMethod("openProfile", arguments: nil)
                }
        }
    }

    // MARK: - Attendance Card

    private var attendanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Attendance")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(viewModel.attendanceStatus)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: viewModel.isPunchedIn ? "checkmark.circle.fill" : "clock")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 24) {
                _AttendanceStat(label: "Check In", value: viewModel.punchInTime)
                _AttendanceStat(label: "Check Out", value: viewModel.punchOutTime)
                _AttendanceStat(label: "Hours", value: viewModel.workedHours)
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

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            _StatCard(
                icon: "calendar.badge.clock",
                label: "Present",
                value: "\(viewModel.presentDays)",
                color: Color(hex: "10B981")
            )
            _StatCard(
                icon: "bed.double",
                label: "Leave",
                value: "\(viewModel.leaveDays)",
                color: Color(hex: "F59E0B")
            )
            _StatCard(
                icon: "xmark.circle",
                label: "Absent",
                value: "\(viewModel.absentDays)",
                color: Color(hex: "EF4444")
            )
        }
    }

    // MARK: - Leave Balance

    private var leaveBalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leave Balance")
                .font(.system(size: 16, weight: .bold))

            ForEach(viewModel.leaveBalances, id: \.type) { balance in
                HStack {
                    Circle()
                        .fill(balance.color)
                        .frame(width: 8, height: 8)
                    Text(balance.type)
                        .font(.system(size: 14))
                    Spacer()
                    Text("\(balance.used)/\(balance.total)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(UIColor.systemGray5))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(balance.color)
                                .frame(width: geo.size.width * balance.progress, height: 6)
                        }
                    }
                    .frame(width: 60, height: 6)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                _ActionButton(icon: "doc.text.fill", label: "Requests", color: Color(hex: "6366F1")) {
                    viewModel.channel?.invokeMethod("navigate", arguments: ["screen": "requests"])
                }
                _ActionButton(icon: "indianrupeesign.circle.fill", label: "Payslip", color: Color(hex: "10B981")) {
                    viewModel.channel?.invokeMethod("navigate", arguments: ["screen": "payslip"])
                }
                _ActionButton(icon: "person.2.fill", label: "Team", color: Color(hex: "F59E0B")) {
                    viewModel.channel?.invokeMethod("navigate", arguments: ["screen": "team"])
                }
                _ActionButton(icon: "gearshape.fill", label: "Settings", color: Color(hex: "64748B")) {
                    viewModel.channel?.invokeMethod("navigate", arguments: ["screen": "settings"])
                }
            }
        }
    }

    // MARK: - Announcements

    private var announcementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Announcements")
                .font(.system(size: 16, weight: .bold))

            ForEach(viewModel.announcements, id: \.title) { item in
                HStack(spacing: 12) {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(Color(hex: "F59E0B"))
                        .font(.system(size: 16))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                        Text(item.body)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Sub-components

private struct _AttendanceStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct _StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct _ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
