import SwiftUI
import UIKit

// MARK: - iOS Native Glass/Blur Effects + Haptics
// Replaces Flutter's custom LiquidGlass with native SwiftUI Material

// ── Glass Card ──────────────────────────────────────────────────────────

/// Native iOS glass card with blur, border, and shadow
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

/// Liquid glass pill (for tab bars, badges)
struct GlassPill<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }
}

// ── Glass Navigation Bar ────────────────────────────────────────────────

/// Native iOS glass nav bar (replaces Flutter LiquidGlass app bar)
struct GlassNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingAction: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let action = leadingAction {
                Button(action: action) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                }
            } else {
                // Balance spacing
                Color.clear.frame(width: 30)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// ── Glass Tab Bar ───────────────────────────────────────────────────────

/// Native iOS glass tab bar for bottom navigation
struct GlassTabBar: View {
    let items: [(icon: String, label: String)]
    @Binding var selectedIndex: Int
    let onTap: (Int) -> Void

    var body: some View {
        HStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    let haptic = UISelectionFeedbackGenerator()
                    haptic.selectionChanged()
                    selectedIndex = index
                    onTap(index)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 22))
                            .symbolVariant(selectedIndex == index ? .fill : .none)
                        Text(item.label)
                            .font(.system(size: 10, weight: selectedIndex == index ? .semibold : .regular))
                    }
                    .foregroundColor(selectedIndex == index ? Color(hex: "3B5FE5") : .secondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 2)
        .background(.ultraThinMaterial)
    }
}

// ── Haptic Feedback Manager ─────────────────────────────────────────────

class HapticManager {
    static let shared = HapticManager()
    private init() {}

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        selection.prepare()
    }

    func light() { lightImpact.impactOccurred() }
    func medium() { mediumImpact.impactOccurred() }
    func heavy() { heavyImpact.impactOccurred() }
    func select() { selection.selectionChanged() }
    func success() { notification.notificationOccurred(.success) }
    func warning() { notification.notificationOccurred(.warning) }
    func error() { notification.notificationOccurred(.error) }

    /// Soft impact with custom intensity (0.0 - 1.0)
    func soft(intensity: CGFloat = 0.5) {
        lightImpact.impactOccurred(intensity: intensity)
    }
}

// ── iOS Spring Animation Presets ────────────────────────────────────────

extension Animation {
    /// Standard iOS spring — used for most transitions
    static var iosSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.75)
    }

    /// Bouncy spring — for attention-grabbing animations
    static var iosBouncy: Animation {
        .spring(response: 0.5, dampingFraction: 0.6)
    }

    /// Snappy spring — for quick interactions
    static var iosSnappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.85)
    }

    /// Slow spring — for large layout changes
    static var iosSlow: Animation {
        .spring(response: 0.6, dampingFraction: 0.8)
    }
}

// ── View Modifiers ──────────────────────────────────────────────────────

extension View {
    /// Apply glass card styling
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    /// Shimmer loading effect
    func shimmer(active: Bool = true) -> some View {
        self.redacted(reason: active ? .placeholder : [])
    }

    /// Fade in on appear
    func fadeInOnAppear(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}

struct FadeInModifier: ViewModifier {
    let delay: Double
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.iosSpring.delay(delay)) {
                    opacity = 1
                    offset = 0
                }
            }
    }
}
