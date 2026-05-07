import SwiftUI

struct ProfileSheetView: View {
    @ObservedObject var viewModel: ProfileSheetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with avatar
                profileHeader
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                // Info cards
                VStack(spacing: 12) {
                    _InfoCard(title: "Personal Information", items: [
                        ("person.fill", "Name", viewModel.fullName),
                        ("envelope.fill", "Email", viewModel.email),
                        ("phone.fill", "Phone", viewModel.phone),
                        ("calendar", "Date of Birth", viewModel.dob),
                    ])

                    _InfoCard(title: "Work Information", items: [
                        ("building.2.fill", "Department", viewModel.department),
                        ("briefcase.fill", "Designation", viewModel.designation),
                        ("person.badge.key.fill", "Employee ID", viewModel.badgeId),
                        ("calendar.badge.clock", "Joining Date", viewModel.joiningDate),
                    ])

                    _InfoCard(title: "Manager", items: [
                        ("person.crop.circle.fill", "Reporting To", viewModel.managerName),
                    ])
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "3B5FE5"), Color(hex: "8B5CF6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 90, height: 90)
                .overlay(
                    Text(viewModel.initials)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                )
                .shadow(color: Color(hex: "3B5FE5").opacity(0.3), radius: 12, y: 4)

            Text(viewModel.fullName)
                .font(.system(size: 22, weight: .bold))

            Text(viewModel.designation)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Role badge
            if !viewModel.role.isEmpty {
                Text(viewModel.role.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "3B5FE5"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(hex: "3B5FE5").opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Info Card

private struct _InfoCard: View {
    let title: String
    let items: [(icon: String, label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                if !item.value.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .foregroundColor(Color(hex: "3B5FE5"))
                            .frame(width: 20)
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.label)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(item.value)
                                .font(.system(size: 15, weight: .medium))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if idx < items.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
