import SwiftUI
import AVFoundation
import UIKit

// MARK: - Stage enum

enum CheckInStage: String {
    case idle, scanning, processing, success, failed
}

// MARK: - ViewModel — bridges SwiftUI ↔ Flutter MethodChannel

class AttendanceCheckInViewModel: ObservableObject {
    // State
    @Published var stage: CheckInStage = .idle
    @Published var statusTitle = "Face Verification"
    @Published var statusMessage = "Position your face within the circle"
    @Published var subtitle = "Secure attendance check-in"
    @Published var countdown: Int = 0
    @Published var pulseScale: CGFloat = 1.0
    @Published var shakeOffset: CGFloat = 0
    @Published var cameraReady = false

    var isBusy: Bool {
        stage == .scanning || stage == .processing
    }

    var ringColor: Color {
        switch stage {
        case .idle: return Color.white.opacity(0.3)
        case .scanning: return Color(hex: "6366F1")
        case .processing: return Color(hex: "6366F1")
        case .success: return .green
        case .failed: return .red
        }
    }

    var statusColor: Color {
        switch stage {
        case .success: return .green
        case .failed: return .red
        default: return .white
        }
    }

    // Flutter bridge
    private var channel: FlutterMethodChannel?
    private var countdownTimer: Timer?
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    init(channel: FlutterMethodChannel?) {
        self.channel = channel
        haptic.prepare()
    }

    // MARK: - Lifecycle

    func onAppear() {
        pulseScale = 1.08
    }

    func onDisappear() {
        countdownTimer?.invalidate()
    }

    // MARK: - Actions

    func startVerification() {
        guard !isBusy else { return }
        haptic.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            stage = .scanning
            statusTitle = "Hold Still"
            statusMessage = "Capturing in..."
            countdown = 2
        }

        // Tell Flutter to start the camera and begin capture flow.
        channel?.invokeMethod("startCamera", arguments: nil)
        cameraReady = true

        // Countdown 2 → 1 → capture
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            DispatchQueue.main.async {
                if self.countdown > 1 {
                    withAnimation(.spring(response: 0.3)) {
                        self.countdown -= 1
                    }
                    self.haptic.impactOccurred(intensity: 0.5)
                } else {
                    timer.invalidate()
                    self.captureAndVerify()
                }
            }
        }
    }

    func cancel() {
        countdownTimer?.invalidate()
        channel?.invokeMethod("cancel", arguments: nil)
    }

    // MARK: - Capture

    private func captureAndVerify() {
        withAnimation(.spring(response: 0.4)) {
            stage = .processing
            statusTitle = "Verifying..."
            statusMessage = "Checking your identity"
            countdown = 0
        }

        // Ask Flutter to capture + send to backend.
        channel?.invokeMethod("captureAndVerify", arguments: nil)
    }

    // MARK: - Callbacks from Flutter

    func onVerificationSuccess() {
        DispatchQueue.main.async {
            let successHaptic = UINotificationFeedbackGenerator()
            successHaptic.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                self.stage = .success
                self.statusTitle = "Verified!"
                self.statusMessage = "Punch recorded successfully"
            }

            // Auto-dismiss after 1.2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.channel?.invokeMethod("dismiss", arguments: nil)
            }
        }
    }

    func onVerificationFailed(errorCode: String, message: String) {
        DispatchQueue.main.async {
            let failHaptic = UINotificationFeedbackGenerator()
            failHaptic.notificationOccurred(.error)

            withAnimation(.spring(response: 0.4)) {
                self.stage = .failed
                self.statusTitle = "Verification Failed"
                self.statusMessage = message
            }

            // Shake animation
            self.triggerShake()
        }
    }

    private func triggerShake() {
        let sequence: [(CGFloat, TimeInterval)] = [
            (14, 0.05), (-12, 0.05), (10, 0.05), (-8, 0.05),
            (5, 0.05), (-3, 0.05), (1, 0.05), (0, 0.05),
        ]
        var delay: TimeInterval = 0
        for (offset, duration) in sequence {
            delay += duration
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.interactiveSpring(response: 0.1)) {
                    self.shakeOffset = offset
                }
            }
        }
    }
}
