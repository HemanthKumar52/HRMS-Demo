import SwiftUI

// MARK: - Shell View (Main Tab Container)

struct ShellView: View {
    @ObservedObject var viewModel: ShellViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area - delegates to Flutter via channel
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dynamic Island overlay
                if viewModel.showDynamicIsland {
                    dynamicIslandOverlay
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Tab bar
                GlassTabBar(
                    items: viewModel.tabItems,
                    selectedIndex: $viewModel.selectedTab,
                    onTap: { index in
                        viewModel.selectTab(index)
                    }
                )
            }
        }
    }

    // MARK: - Dynamic Island

    private var dynamicIslandOverlay: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "10B981"))

            Text(viewModel.dynamicIslandText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}
