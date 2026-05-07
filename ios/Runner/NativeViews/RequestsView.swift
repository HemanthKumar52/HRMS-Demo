import SwiftUI

// MARK: - Requests View

struct RequestsView: View {
    @ObservedObject var viewModel: RequestsViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Tab bar
                tabBar
                    .fadeInOnAppear(delay: 0)

                // Content
                if viewModel.filteredRequests.isEmpty {
                    emptyState
                        .fadeInOnAppear(delay: 0.1)
                } else {
                    requestsList
                }
            }
            .background(Color(UIColor.systemGroupedBackground))

            // FAB
            fabButton
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .fadeInOnAppear(delay: 0.2)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<viewModel.tabs.count, id: \.self) { index in
                    Button {
                        viewModel.selectTab(index)
                    } label: {
                        Text(viewModel.tabs[index])
                            .font(.system(size: 13, weight: viewModel.selectedTab == index ? .semibold : .medium))
                            .foregroundColor(viewModel.selectedTab == index ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedTab == index
                                    ? Color(hex: "3B5FE5")
                                    : Color(UIColor.secondarySystemGroupedBackground)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredRequests.enumerated()), id: \.element.id) { index, request in
                    _RequestCard(request: request) {
                        viewModel.openDetail(request)
                    }
                    .fadeInOnAppear(delay: 0.05 * Double(index))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Requests")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Your requests will appear here")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button {
            viewModel.createNew()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "3B5FE5"), Color(hex: "5B7FF9")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color(hex: "3B5FE5").opacity(0.4), radius: 12, y: 4)
        }
    }
}

// MARK: - Sub-components

private struct _RequestCard: View {
    let request: RequestItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconForType(request.type))
                    .font(.system(size: 20))
                    .foregroundColor(colorForType(request.type))
                    .frame(width: 40, height: 40)
                    .background(colorForType(request.type).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(request.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    _StatusBadge(status: request.status)
                    Text(request.date)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "leave": return "calendar.badge.clock"
        case "attendance": return "clock.badge.checkmark"
        case "claim": return "indianrupeesign.circle"
        case "ticket": return "ticket"
        default: return "doc.text"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "leave": return Color(hex: "3B5FE5")
        case "attendance": return Color(hex: "10B981")
        case "claim": return Color(hex: "F59E0B")
        case "ticket": return Color(hex: "8B5CF6")
        default: return Color(hex: "64748B")
        }
    }
}

private struct _StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "approved": return Color(hex: "10B981")
        case "rejected": return Color(hex: "EF4444")
        case "pending": return Color(hex: "F59E0B")
        case "cancelled": return Color(hex: "64748B")
        default: return Color(hex: "64748B")
        }
    }
}
