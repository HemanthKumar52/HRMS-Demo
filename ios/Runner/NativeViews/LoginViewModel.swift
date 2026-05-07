import SwiftUI
import Flutter
import LocalAuthentication

class LoginViewModel: ObservableObject {
    let channel: FlutterMethodChannel?

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var showPassword: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var biometricAvailable: Bool = false
    @Published var biometricType: LABiometryType = .none

    init(channel: FlutterMethodChannel?) {
        self.channel = channel
        checkBiometrics()
    }

    private func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }

    func login() {
        guard !username.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = ""

        // Send credentials to Flutter for API call
        channel?.invokeMethod("login", arguments: [
            "username": username,
            "password": password,
        ])
    }

    func biometricLogin() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in to PPULSE") { success, error in
            DispatchQueue.main.async {
                if success {
                    // Tell Flutter to use stored credentials
                    self.channel?.invokeMethod("biometricLogin", arguments: nil)
                } else {
                    self.errorMessage = "Biometric authentication failed"
                }
            }
        }
    }

    func onLoginSuccess() {
        isLoading = false
        errorMessage = ""
        // Flutter handles navigation after login
    }

    func onLoginFailed(error: String) {
        isLoading = false
        withAnimation(.spring(response: 0.3)) {
            errorMessage = error
        }
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.error)
    }
}
