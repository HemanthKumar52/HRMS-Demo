import SwiftUI
import AVFoundation

// MARK: - SwiftUI Attendance Check-In View
// Production-grade native iOS attendance UI with camera preview,
// Face ID animation, haptics, and spring-based transitions.

struct AttendanceCheckInView: View {
    @ObservedObject var viewModel: AttendanceCheckInViewModel

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0F0F1A"), Color(hex: "1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)

                Spacer()

                // Camera ring
                cameraRingSection

                Spacer()

                // Status message
                statusSection
                    .padding(.bottom, 12)

                // Action buttons
                actionButtons
                    .padding(.bottom, 24)
                    .padding(.horizontal, 32)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Face Verification")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(viewModel.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }

    // MARK: - Camera Ring

    private var cameraRingSection: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .stroke(viewModel.ringColor.opacity(0.15), lineWidth: 3)
                .frame(width: 230, height: 230)
                .scaleEffect(viewModel.pulseScale)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: viewModel.pulseScale
                )

            // Main ring
            Circle()
                .stroke(viewModel.ringColor, lineWidth: 4)
                .frame(width: 210, height: 210)
                .shadow(color: viewModel.ringColor.opacity(0.4), radius: 12)

            // Inner content
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 200, height: 200)
                .overlay {
                    Group {
                        switch viewModel.stage {
                        case .idle:
                            idleContent
                        case .scanning:
                            scanningContent
                        case .processing:
                            processingContent
                        case .success:
                            successContent
                        case .failed:
                            failedContent
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                .clipShape(Circle())

            // Scanning ring animation
            if viewModel.stage == .scanning {
                ScanningRingView()
            }

            // Countdown overlay
            if viewModel.stage == .scanning, viewModel.countdown > 0 {
                Text("\(viewModel.countdown)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .transition(.scale.combined(with: .opacity))
                    .id("countdown-\(viewModel.countdown)")
            }
        }
        .offset(x: viewModel.shakeOffset)
    }

    private var idleContent: some View {
        Image(systemName: "faceid")
            .font(.system(size: 64, weight: .thin))
            .foregroundColor(Color.white.opacity(0.4))
    }

    private var scanningContent: some View {
        ZStack {
            Color.clear
            if !viewModel.cameraReady {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)
            }
        }
    }

    private var processingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.6)
            Text("Verifying...")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var successContent: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.green)
    }

    private var failedContent: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(.red)
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 6) {
            Text(viewModel.statusTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.statusColor)
                .animation(.spring(response: 0.3), value: viewModel.statusTitle)

            Text(viewModel.statusMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .animation(.spring(response: 0.3), value: viewModel.statusMessage)
        }
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Cancel
            Button {
                viewModel.cancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.isBusy)

            // Verify / Retry
            Button {
                viewModel.startVerification()
            } label: {
                Text(viewModel.stage == .failed ? "Retry" : "Verify")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.isBusy)
            .opacity(viewModel.isBusy ? 0.5 : 1)
        }
        .opacity(viewModel.stage == .success ? 0 : 1)
        .animation(.spring(response: 0.3), value: viewModel.stage)
    }
}

// MARK: - Scanning Ring Animation

struct ScanningRingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.3)
            .stroke(
                AngularGradient(
                    colors: [.clear, Color(hex: "6366F1"), .clear],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: 218, height: 218)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
