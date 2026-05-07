import SwiftUI

// MARK: - Manager View

struct ManagerView: View {
    @ObservedObject var viewModel: ManagerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            managerTabBar
                .fadeInOnAppear(delay: 0)

            // Content
            Group {
                switch viewModel.selectedTab {
                case 0: teamTab
                case 1: approvalsTab
                case 2: analyticsTab
                default: teamTab
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Tab Bar

    private var managerTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<viewModel.tabs.count, id: \.self) { index in
                Button {
                    viewModel.selectTab(index)
                } label: {
                    VStack(spacing: 6) {
                        Text(viewModel.tabs[index])
                            .font(.system(size: 14, weight: viewModel.selectedTab == index ? .semibold : .medium))
                            .foregroundColor(viewModel.selectedTab == index ? Color(hex: "3B5FE5") : .secondary)

                        Rectangle()
                            .fill(viewModel.selectedTab == index ? Color(hex: "3B5FE5") : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - My Team Tab

    private var teamTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search team...", text: $viewModel.teamSearchText)
                        .font(.system(size: 15))
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.05)

                ForEach(Array(viewModel.filteredTeam.enumerated()), id: \.element.id) { index, member in
                    _TeamMemberCard(member: member) {
                        viewModel.viewEmployee(member)
                    }
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.05 + 0.03 * Double(index))
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Approvals Tab

    private var approvalsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                if viewModel.approvals.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 60)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "10B981").opacity(0.5))
                        Text("All caught up!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("No pending approvals")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(viewModel.approvals.enumerated()), id: \.element.id) { index, approval in
                        _ApprovalCard(
                            approval: approval,
                            onApprove: { viewModel.approve(approval) },
                            onReject: { viewModel.reject(approval) }
                        )
                        .padding(.horizontal, 20)
                        .fadeInOnAppear(delay: 0.05 + 0.03 * Double(index))
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Analytics Tab

    private var analyticsTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Summary cards
                HStack(spacing: 12) {
                    _AnalyticsSummaryCard(label: "Total", value: "\(viewModel.totalEmployees)", icon: "person.2.fill", color: Color(hex: "3B5FE5"))
                    _AnalyticsSummaryCard(label: "Present", value: "\(viewModel.presentToday)", icon: "checkmark.circle.fill", color: Color(hex: "10B981"))
                }
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.05)

                HStack(spacing: 12) {
                    _AnalyticsSummaryCard(label: "On Leave", value: "\(viewModel.onLeaveToday)", icon: "bed.double.fill", color: Color(hex: "F59E0B"))
                    _AnalyticsSummaryCard(label: "Absent", value: "\(viewModel.absentToday)", icon: "xmark.circle.fill", color: Color(hex: "EF4444"))
                }
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.1)

                // Bar chart
                analyticsBarChart
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.15)

                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    private var analyticsBarChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Overview")
                .font(.system(size: 16, weight: .bold))

            ForEach(viewModel.analyticsData) { item in
                HStack(spacing: 12) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 70, alignment: .leading)

                    GeometryReader { geo in
                        let total = max(viewModel.totalEmployees, 1)
                        let width = geo.size.width * CGFloat(item.value) / CGFloat(total)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.color)
                            .frame(width: max(4, width), height: 24)
                    }
                    .frame(height: 24)

                    Text("\(item.value)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sub-components

private struct _TeamMemberCard: View {
    let member: TeamMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(member.avatarInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(statusColor)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(member.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(member.designation)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(member.status.capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch member.status.lowercased() {
        case "present": return Color(hex: "10B981")
        case "absent": return Color(hex: "EF4444")
        case "leave": return Color(hex: "F59E0B")
        case "remote": return Color(hex: "3B5FE5")
        default: return Color(hex: "64748B")
        }
    }
}

private struct _ApprovalCard: View {
    let approval: ApprovalItem
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(approval.employeeName)
                        .font(.system(size: 15, weight: .semibold))
                    Text(approval.title)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(approval.type.capitalized)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "3B5FE5"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "3B5FE5").opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(approval.dateRange)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            if !approval.reason.isEmpty {
                Text(approval.reason)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "EF4444"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "EF4444").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onApprove) {
                    Text("Approve")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct _AnalyticsSummaryCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
