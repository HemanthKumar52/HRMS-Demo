import SwiftUI

// MARK: - HR Dashboard View

struct HRDashboardView: View {
    @ObservedObject var viewModel: HRViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            hrTabBar
                .fadeInOnAppear(delay: 0)

            Group {
                switch viewModel.selectedTab {
                case 0: attendanceTab
                case 1: claimsTab
                case 2: directoryTab
                default: attendanceTab
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Tab Bar

    private var hrTabBar: some View {
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

    // MARK: - Attendance Tab

    private var attendanceTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Overview cards
                HStack(spacing: 12) {
                    _HRStatCard(label: "Total", value: "\(viewModel.totalEmployees)", icon: "person.2.fill", color: Color(hex: "3B5FE5"))
                    _HRStatCard(label: "Present", value: "\(viewModel.totalPresent)", icon: "checkmark.circle.fill", color: Color(hex: "10B981"))
                }
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.05)

                HStack(spacing: 12) {
                    _HRStatCard(label: "Absent", value: "\(viewModel.totalAbsent)", icon: "xmark.circle.fill", color: Color(hex: "EF4444"))
                    _HRStatCard(label: "On Leave", value: "\(viewModel.totalLeave)", icon: "bed.double.fill", color: Color(hex: "F59E0B"))
                }
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.1)

                // Department breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Department Attendance")
                        .font(.system(size: 16, weight: .bold))

                    ForEach(viewModel.teamAttendance) { dept in
                        _DepartmentRow(dept: dept)
                    }
                }
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .fadeInOnAppear(delay: 0.15)

                Spacer(minLength: 100)
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Claims Tab

    private var claimsTab: some View {
        VStack(spacing: 0) {
            // Claims sub-tabs
            HStack(spacing: 8) {
                ForEach(0..<viewModel.claimsTabs.count, id: \.self) { index in
                    Button {
                        HapticManager.shared.select()
                        viewModel.claimsTab = index
                    } label: {
                        Text(viewModel.claimsTabs[index])
                            .font(.system(size: 13, weight: viewModel.claimsTab == index ? .semibold : .medium))
                            .foregroundColor(viewModel.claimsTab == index ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.claimsTab == index
                                    ? Color(hex: "3B5FE5")
                                    : Color(UIColor.secondarySystemGroupedBackground)
                            )
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if viewModel.filteredClaims.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 40)
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No claims")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(viewModel.filteredClaims.enumerated()), id: \.element.id) { index, claim in
                            _ClaimCard(
                                claim: claim,
                                showActions: viewModel.claimsTab == 0,
                                onApprove: { viewModel.approveClaim(claim) },
                                onReject: { viewModel.rejectClaim(claim) }
                            )
                            .fadeInOnAppear(delay: 0.03 * Double(index))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Directory Tab

    private var directoryTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search employees...", text: $viewModel.dirSearchText)
                    .font(.system(size: 15))
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.filteredDirectory.enumerated()), id: \.element.id) { index, emp in
                        _HRDirectoryCard(employee: emp) {
                            viewModel.viewEmployee(emp)
                        }
                        .fadeInOnAppear(delay: 0.03 * Double(index))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Sub-components

private struct _HRStatCard: View {
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

private struct _DepartmentRow: View {
    let dept: HRTeamAttendance

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(dept.department)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(dept.present)/\(dept.total)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                let total = max(dept.total, 1)
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: geo.size.width * CGFloat(dept.present) / CGFloat(total))
                    Rectangle()
                        .fill(Color(hex: "F59E0B"))
                        .frame(width: geo.size.width * CGFloat(dept.leave) / CGFloat(total))
                    Rectangle()
                        .fill(Color(hex: "EF4444"))
                        .frame(width: geo.size.width * CGFloat(dept.absent) / CGFloat(total))
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}

private struct _ClaimCard: View {
    let claim: ClaimItem
    let showActions: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(claim.employeeName)
                        .font(.system(size: 15, weight: .semibold))
                    Text(claim.type)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatAmount(claim.amount))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "10B981"))
                    Text(claim.date)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if showActions {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Text("Reject")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "EF4444"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "EF4444").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button(action: onApprove) {
                        Text("Approve")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "10B981"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func formatAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "\u{20B9}"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\u{20B9}0"
    }
}

private struct _HRDirectoryCard: View {
    let employee: DirectoryEmployee
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(employee.avatarColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(employee.avatarInitials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(employee.avatarColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(employee.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("\(employee.designation) - \(employee.department)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
