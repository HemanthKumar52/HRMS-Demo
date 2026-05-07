import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @FocusState private var focusedField: LoginField?

    enum LoginField { case username, password }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0F0F1A"), Color(hex: "1A1A2E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(Color(hex: "6366F1"))

                        Text("PPULSE")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("Employee Self Service")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 48)

                    // Form
                    VStack(spacing: 16) {
                        // Username
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(width: 20)
                                TextField("Enter username", text: $viewModel.username)
                                    .textContentType(.username)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.white)
                                    .focused($focusedField, equals: .username)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        focusedField == .username ? Color(hex: "6366F1") : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(width: 20)
                                if viewModel.showPassword {
                                    TextField("Enter password", text: $viewModel.password)
                                        .foregroundColor(.white)
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("Enter password", text: $viewModel.password)
                                        .foregroundColor(.white)
                                        .focused($focusedField, equals: .password)
                                }
                                Button {
                                    viewModel.showPassword.toggle()
                                } label: {
                                    Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        focusedField == .password ? Color(hex: "6366F1") : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        }

                        // Error message
                        if !viewModel.errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(viewModel.errorMessage)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.red)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Login button
                        Button {
                            focusedField = nil
                            viewModel.login()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(hex: "6366F1").opacity(0.4), radius: 12, y: 4)
                        }
                        .disabled(viewModel.isLoading || viewModel.username.isEmpty || viewModel.password.isEmpty)
                        .opacity(viewModel.username.isEmpty || viewModel.password.isEmpty ? 0.6 : 1)

                        // Biometric login
                        if viewModel.biometricAvailable {
                            Button {
                                viewModel.biometricLogin()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: viewModel.biometricType == .faceID ? "faceid" : "touchid")
                                        .font(.system(size: 20))
                                    Text("Sign in with \(viewModel.biometricType == .faceID ? "Face ID" : "Touch ID")")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "6366F1"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 60)
                }
            }
        }
        .onSubmit {
            switch focusedField {
            case .username: focusedField = .password
            case .password: viewModel.login()
            case nil: break
            }
        }
    }
}
