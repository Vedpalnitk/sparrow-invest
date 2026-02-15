import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        ScrollView {
                VStack(spacing: AppTheme.Spacing.xxLarge) {
                    Spacer().frame(height: 60)

                    // Logo & Title
                    VStack(spacing: AppTheme.Spacing.medium) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primaryGradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        Text("Sparrow Invest")
                            .font(AppTheme.Typography.display(iPad ? 34 : 28))
                            .foregroundColor(.primary)

                        Text("Financial Advisor Portal")
                            .font(AppTheme.Typography.body(iPad ? 17 : 15))
                            .foregroundColor(.secondary)
                    }

                    // Login Form
                    VStack(spacing: AppTheme.Spacing.medium) {
                        // Email Field
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                            Text("EMAIL")
                                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                .foregroundColor(AppTheme.primary)

                            HStack(spacing: AppTheme.Spacing.small) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)

                                TextField("", text: $email, prompt: Text("email@sparrowinvest.com").foregroundColor(.gray))
                                    .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .frame(height: 48)
                            .background(inputBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(inputBorder)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                            Text("PASSWORD")
                                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                .foregroundColor(AppTheme.primary)

                            HStack(spacing: AppTheme.Spacing.small) {
                                Image(systemName: "lock")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)

                                if showPassword {
                                    TextField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                } else {
                                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .frame(height: 48)
                            .background(inputBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(inputBorder)
                        }

                        // Error Message
                        if let error = authManager.authError {
                            HStack(spacing: AppTheme.Spacing.small) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                Text(error)
                                    .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                            }
                            .foregroundColor(AppTheme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Login Button
                        Button {
                            Task { await authManager.login(email: email, password: password) }
                        } label: {
                            HStack(spacing: AppTheme.Spacing.small) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .font(AppTheme.Typography.headline(iPad ? 19 : 16))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.primaryGradient)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                    }
                    .glassCard()
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    // Demo credentials hint
                    VStack(spacing: AppTheme.Spacing.small) {
                        Text("Demo Credentials")
                            .font(AppTheme.Typography.label(iPad ? 14 : 12))
                            .foregroundColor(.secondary)

                        Button {
                            email = "advisor@sparrowinvest.com"
                            password = "Advisor@123"
                        } label: {
                            Text("advisor@sparrowinvest.com / Advisor@123")
                                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.xxLarge)
                }
            }
        .background(backgroundGradient.ignoresSafeArea())
    }

    @ViewBuilder
    private var backgroundGradient: some View {
        if colorScheme == .dark {
            Color(UIColor.systemBackground)
        } else {
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    AppTheme.primary.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var inputBackground: some View {
        if colorScheme == .dark {
            Color.white.opacity(0.06)
        } else {
            Color(UIColor.tertiarySystemFill)
        }
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.white.opacity(0.5),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }
}
