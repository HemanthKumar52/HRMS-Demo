import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List {
            // Account section
            Section {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color(hex: "3B5FE5").opacity(0.15))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(viewModel.userInitials)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "3B5FE5"))
                        )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.userName)
                            .font(.system(size: 17, weight: .semibold))
                        Text(viewModel.userEmail)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.navigate("profile")
                }
            }

            // Appearance
            Section("Appearance") {
                Toggle(isOn: $viewModel.darkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
                .onChange(of: viewModel.darkMode) { newValue in
                    viewModel.channel?.invokeMethod("setDarkMode", arguments: ["enabled": newValue])
                }
            }

            // Security
            Section("Security") {
                Toggle(isOn: $viewModel.appLockEnabled) {
                    Label("App Lock", systemImage: "lock.fill")
                }
                .onChange(of: viewModel.appLockEnabled) { newValue in
                    viewModel.channel?.invokeMethod("setAppLock", arguments: ["enabled": newValue])
                }

                _SettingsRow(icon: "faceid", label: "Face Enrollment", color: Color(hex: "6366F1")) {
                    viewModel.navigate("faceEnrollment")
                }
            }

            // Notifications
            Section("Notifications") {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    Label("Push Notifications", systemImage: "bell.fill")
                }
                .onChange(of: viewModel.notificationsEnabled) { newValue in
                    viewModel.channel?.invokeMethod("setNotifications", arguments: ["enabled": newValue])
                }
            }

            // About
            Section("About") {
                _SettingsRow(icon: "info.circle", label: "App Version", color: .secondary, trailing: viewModel.appVersion)
                _SettingsRow(icon: "star.fill", label: "Rate App", color: Color(hex: "F59E0B")) {
                    viewModel.navigate("rateApp")
                }
                _SettingsRow(icon: "questionmark.circle", label: "Help & Support", color: Color(hex: "10B981")) {
                    viewModel.navigate("support")
                }
            }

            // Danger zone
            Section {
                Button(role: .destructive) {
                    viewModel.channel?.invokeMethod("logout", arguments: nil)
                } label: {
                    HStack {
                        Spacer()
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Settings Row

private struct _SettingsRow: View {
    let icon: String
    let label: String
    let color: Color
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(label)
                    .foregroundColor(.primary)
                Spacer()
                if let t = trailing {
                    Text(t)
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                if action != nil && trailing == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
        }
        .disabled(action == nil)
    }
}
