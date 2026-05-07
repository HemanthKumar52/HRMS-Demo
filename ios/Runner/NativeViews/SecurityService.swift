import Foundation
import UIKit
import LocalAuthentication
import Security
import Flutter

// MARK: - iOS Security Service
// Handles: jailbreak detection, screenshot protection, Keychain storage,
// developer mode check, SSL pinning, biometric auth

class PPulseSecurityService {
    static let shared = PPulseSecurityService()
    private init() {}

    // MARK: - Jailbreak Detection

    /// Multi-layered jailbreak detection
    func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 1. Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/private/var/tmp/cydia.log",
            "/usr/libexec/cydia",
            "/var/cache/apt",
            "/var/lib/dpkg",
            "/var/log/syslog",
            "/bin/sh",
            "/usr/libexec/sftp-server",
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // 2. Check if can open Cydia URL scheme
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        // 3. Try writing to a restricted path
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // Should NOT be able to write here
        } catch {
            // Expected — device is not jailbroken
        }

        // 4. Check for suspicious environment variables
        if let _ = getenv("DYLD_INSERT_LIBRARIES") {
            return true
        }

        // 5. Check for sandbox integrity
        let sandboxPath = String(format: "%@/Documents/.sandbox_test", NSHomeDirectory())
        do {
            try "test".write(toFile: sandboxPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: sandboxPath)
        } catch {
            // If we can't write to our own sandbox, something is very wrong
            return true
        }

        return false
        #endif
    }

    // MARK: - Developer Mode Check

    func isDeveloperModeEnabled() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        // On iOS, "developer mode" is controlled by Xcode connection.
        // Check if a debugger is attached.
        return isDebuggerAttached()
        #endif
    }

    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - Screenshot Protection

    private var screenshotObserver: NSObjectProtocol?
    private var screenCaptureObserver: NSObjectProtocol?
    private var secureFields: [UITextField] = []

    /// Enable screenshot/screen recording protection on a window
    func enableScreenshotProtection(for window: UIWindow?) {
        guard let window = window else { return }

        // Method 1: Overlay with secure text field trick
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        secureField.isUserInteractionEnabled = false
        window.addSubview(secureField)
        secureField.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
        secureField.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
        secureField.translatesAutoresizingMaskIntoConstraints = false
        window.layer.superlayer?.addSublayer(secureField.layer)
        secureField.layer.sublayers?.first?.addSublayer(window.layer)
        secureFields.append(secureField)

        // Method 2: Observe screenshot notifications
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onScreenshotDetected()
        }

        // Method 3: Observe screen capture (recording)
        if #available(iOS 11.0, *) {
            screenCaptureObserver = NotificationCenter.default.addObserver(
                forName: UIScreen.capturedDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                if UIScreen.main.isCaptured {
                    self?.onScreenRecordingDetected()
                }
            }
        }
    }

    func disableScreenshotProtection() {
        if let obs = screenshotObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let obs = screenCaptureObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        secureFields.forEach { $0.removeFromSuperview() }
        secureFields.removeAll()
    }

    private func onScreenshotDetected() {
        // Log audit event
        print("SECURITY: Screenshot detected")
        // Could send to backend via method channel
    }

    private func onScreenRecordingDetected() {
        print("SECURITY: Screen recording detected")
    }

    // MARK: - Keychain Storage

    /// Store a value securely in the iOS Keychain
    func keychainSet(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ppulse.hrms",
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ppulse.hrms",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a value from the iOS Keychain
    func keychainGet(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ppulse.hrms",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the iOS Keychain
    func keychainDelete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.ppulse.hrms",
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use PIN"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometrics not available")
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    completion(false, error?.localizedDescription ?? "Authentication failed")
                }
            }
        }
    }

    var biometricType: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "none"
        }
        switch context.biometryType {
        case .faceID: return "faceID"
        case .touchID: return "touchID"
        case .opticID: return "opticID"
        @unknown default: return "unknown"
        }
    }

    // MARK: - SSL Pinning Helper

    /// Returns a URLSession configured with certificate pinning
    func pinnedSession(pinnedHosts: [String: [Data]]) -> URLSession {
        let delegate = SSLPinningDelegate(pinnedHosts: pinnedHosts)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }
}

// MARK: - SSL Pinning Delegate

private class SSLPinningDelegate: NSObject, URLSessionDelegate {
    let pinnedHosts: [String: [Data]]

    init(pinnedHosts: [String: [Data]]) {
        self.pinnedHosts = pinnedHosts
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String?,
              let pins = pinnedHosts[host] else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Extract server certificate
        let serverCertCount = SecTrustGetCertificateCount(serverTrust)
        guard serverCertCount > 0 else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if let serverCert = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
           let firstCert = serverCert.first {
            let serverCertData = SecCertificateCopyData(firstCert) as Data
            if pins.contains(serverCertData) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// MARK: - Flutter Method Channel Handler

class SecurityMethodChannelHandler {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.ppulse.hrms_demo/ios_security",
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { call, result in
            let security = PPulseSecurityService.shared

            switch call.method {
            case "isJailbroken":
                result(security.isDeviceJailbroken())

            case "isDeveloperMode":
                result(security.isDeveloperModeEnabled())

            case "getBiometricType":
                result(security.biometricType)

            case "authenticate":
                let args = call.arguments as? [String: Any]
                let reason = args?["reason"] as? String ?? "Authenticate to continue"
                security.authenticateWithBiometrics(reason: reason) { success, error in
                    result(["success": success, "error": error as Any])
                }

            case "keychainSet":
                let args = call.arguments as? [String: Any]
                guard let key = args?["key"] as? String, let value = args?["value"] as? String else {
                    result(false)
                    return
                }
                result(security.keychainSet(key: key, value: value))

            case "keychainGet":
                let args = call.arguments as? [String: Any]
                guard let key = args?["key"] as? String else {
                    result(nil)
                    return
                }
                result(security.keychainGet(key: key))

            case "keychainDelete":
                let args = call.arguments as? [String: Any]
                guard let key = args?["key"] as? String else {
                    result(false)
                    return
                }
                result(security.keychainDelete(key: key))

            case "enableScreenshotProtection":
                let window = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })
                security.enableScreenshotProtection(for: window)
                result(nil)

            case "disableScreenshotProtection":
                security.disableScreenshotProtection()
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
