import SwiftUI

// MARK: - Splash View

struct SplashView: View {
    @ObservedObject var viewModel: SplashOnboardingViewModel

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var showSecurityCheck: Bool = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0F0F1A"), Color(hex: "1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo animation
                ZStack {
                    // Rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "3B5FE5"), Color(hex: "5B7FF9"), Color(hex: "3B5FE5").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(ringRotation))

                    // Logo icon
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(Color(hex: "3B5FE5"))
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // App title
                VStack(spacing: 6) {
                    Text("PPulse")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)

                    Text("HR Management System")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .opacity(logoOpacity)
                }

                Spacer()

                // Security check indicator
                if showSecurityCheck {
                    VStack(spacing: 8) {
                        if viewModel.isDeveloperMode {
                            // Developer mode blocked
                            Image(systemName: "shield.slash.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "EF4444"))

                            Text("Developer Mode Detected")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))

                            Text("Please disable developer mode in Settings")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)

                            Button {
                                viewModel.openSettings()
                            } label: {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Open Settings")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(hex: "EF4444"))
                                .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                                    .scaleEffect(0.8)
                                Text("Verifying security...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    .transition(.opacity)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.iosSpring) {
                    showSecurityCheck = true
                }
            }
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @ObservedObject var viewModel: SplashOnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Get Started")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Grant permissions for the best experience")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            .fadeInOnAppear(delay: 0)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(Array(viewModel.permissions.enumerated()), id: \.element.id) { index, permission in
                        _PermissionCard(permission: permission) {
                            viewModel.requestPermission(permission)
                        }
                        .fadeInOnAppear(delay: 0.1 + 0.08 * Double(index))
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            // Continue button
            Button {
                viewModel.continueToApp()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "3B5FE5"), Color(hex: "5B7FF9")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .fadeInOnAppear(delay: 0.4)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Sub-components

private struct _PermissionCard: View {
    let permission: PermissionRequest
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: permission.icon)
                .font(.system(size: 24))
                .foregroundColor(permission.isGranted ? Color(hex: "10B981") : Color(hex: "3B5FE5"))
                .frame(width: 44, height: 44)
                .background(
                    (permission.isGranted ? Color(hex: "10B981") : Color(hex: "3B5FE5")).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(permission.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(permission.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if permission.isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "10B981"))
            } else {
                Button(action: onRequest) {
                    Text("Allow")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(hex: "3B5FE5"))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
