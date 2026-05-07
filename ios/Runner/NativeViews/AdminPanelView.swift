import SwiftUI

// MARK: - Admin Panel View

struct AdminPanelView: View {
    @ObservedObject var viewModel: AdminPanelViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .fadeInOnAppear(delay: 0)

                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.05)

                // Grid
                adminGrid
                    .padding(.horizontal, 20)
                    .fadeInOnAppear(delay: 0.1)

                Spacer(minLength: 100)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin Panel")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("Manage your organization")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "3B5FE5"))
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search sections...", text: $viewModel.searchText)
                .font(.system(size: 15))
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Grid

    private var adminGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            ForEach(viewModel.filteredSections) { section in
                _AdminTile(section: section) {
                    viewModel.openSection(section)
                }
            }
        }
    }
}

// MARK: - Sub-components

private struct _AdminTile: View {
    let section: AdminSection
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 26))
                    .foregroundColor(section.color)

                Text(section.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if section.count > 0 {
                    Text("\(section.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(section.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(section.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
