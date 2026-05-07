import SwiftUI

// MARK: - Directory View

struct DirectoryView: View {
    @ObservedObject var viewModel: DirectoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search + filter
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search employees...", text: $viewModel.searchText)
                        .font(.system(size: 15))
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Department filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.departments, id: \.self) { dept in
                            Button {
                                HapticManager.shared.select()
                                viewModel.selectedDepartment = dept
                            } label: {
                                Text(dept)
                                    .font(.system(size: 12, weight: viewModel.selectedDepartment == dept ? .semibold : .medium))
                                    .foregroundColor(viewModel.selectedDepartment == dept ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedDepartment == dept
                                            ? Color(hex: "3B5FE5")
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .fadeInOnAppear(delay: 0)

            // Employee list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.filteredEmployees.enumerated()), id: \.element.id) { index, employee in
                        _DirectoryCard(employee: employee) {
                            viewModel.viewEmployee(employee)
                        }
                        .fadeInOnAppear(delay: 0.03 * Double(index))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Employee Detail View

struct EmployeeDetailView: View {
    @ObservedObject var viewModel: DirectoryViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if let detail = viewModel.selectedEmployee {
                VStack(spacing: 20) {
                    // Profile card
                    profileCard(detail.employee)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .fadeInOnAppear(delay: 0)

                    // Contact info
                    contactSection(detail.employee)
                        .padding(.horizontal, 20)
                        .fadeInOnAppear(delay: 0.05)

                    // Work info
                    workInfoSection(detail.workInfo)
                        .padding(.horizontal, 20)
                        .fadeInOnAppear(delay: 0.1)

                    Spacer(minLength: 100)
                }
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Employee Selected")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func profileCard(_ employee: DirectoryEmployee) -> some View {
        VStack(spacing: 16) {
            Circle()
                .fill(employee.avatarColor.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(employee.avatarInitials)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(employee.avatarColor)
                )

            VStack(spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(employee.designation)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(employee.department)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "3B5FE5"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "3B5FE5").opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack(spacing: 24) {
                Button {
                    viewModel.callEmployee(employee)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "10B981"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "10B981").opacity(0.12))
                            .clipShape(Circle())
                        Text("Call")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    viewModel.emailEmployee(employee)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "3B5FE5"))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: "3B5FE5").opacity(0.12))
                            .clipShape(Circle())
                        Text("Email")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func contactSection(_ employee: DirectoryEmployee) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.system(size: 16, weight: .bold))

            _InfoRow(icon: "envelope.fill", label: "Email", value: employee.email, color: Color(hex: "3B5FE5"))
            _InfoRow(icon: "phone.fill", label: "Phone", value: employee.phone, color: Color(hex: "10B981"))
            _InfoRow(icon: "building.2.fill", label: "Department", value: employee.department, color: Color(hex: "8B5CF6"))
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func workInfoSection(_ work: EmployeeWorkInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Work Information")
                .font(.system(size: 16, weight: .bold))

            _InfoRow(icon: "calendar", label: "Join Date", value: work.joinDate, color: Color(hex: "F59E0B"))
            _InfoRow(icon: "briefcase.fill", label: "Type", value: work.employeeType, color: Color(hex: "6366F1"))
            _InfoRow(icon: "clock.fill", label: "Shift", value: work.shift, color: Color(hex: "EC4899"))
            _InfoRow(icon: "person.fill", label: "Reports To", value: work.reportingTo, color: Color(hex: "14B8A6"))
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sub-components

private struct _DirectoryCard: View {
    let employee: DirectoryEmployee
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(employee.avatarColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(employee.avatarInitials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(employee.avatarColor)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(employee.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(employee.designation)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(employee.department)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "3B5FE5"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "3B5FE5").opacity(0.1))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct _InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value.isEmpty ? "--" : value)
                    .font(.system(size: 14, weight: .medium))
            }

            Spacer()
        }
    }
}
