import SwiftUI

struct AuthFlow: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentStep: AuthStep = .login

    enum AuthStep {
        case login
        case otp
        case signup
    }

    var body: some View {
        NavigationStack {
            switch currentStep {
            case .login:
                LoginView(
                    onOTPSent: { currentStep = .otp },
                    onSkip: { authManager.continueAsGuest() }
                )
            case .otp:
                OTPVerifyView(
                    onVerified: { currentStep = .signup },
                    onSkip: { authManager.continueAsGuest() }
                )
            case .signup:
                SignupView(
                    onSkip: { authManager.continueAsGuest() }
                )
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    let onOTPSent: () -> Void
    let onSkip: () -> Void
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button(action: onSkip) {
                    Text("Skip")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.trailing, 24)
            }
            .padding(.top, 16)

            Spacer()

            // Logo
            HStack(spacing: 8) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.primaryGradient)
                Text("Sparrow Invest")
                    .font(AppTheme.Typography.title(24))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.bottom, 40)

            VStack(spacing: 8) {
                Text("Enter your phone number")
                    .font(AppTheme.Typography.headline(20))
                    .foregroundColor(AppTheme.textPrimary)

                Text("We'll send you a verification code")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PHONE NUMBER")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
                    .tracking(1)

                HStack {
                    Text("+91")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.leading, 16)

                    TextField("98765 43210", text: $phoneNumber)
                        .font(AppTheme.Typography.body())
                        .keyboardType(.phonePad)
                        .padding(.vertical, 16)
                }
                .background(inputBackground)
                .overlay(inputBorder)
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.error)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: sendOTP) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send OTP")
                            .font(AppTheme.Typography.accent(17))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(phoneNumber.count >= 10 ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.textTertiary], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(phoneNumber.count < 10 || isLoading)

                Button(action: onSkip) {
                    Text("Continue without login")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var inputBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        }
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.3), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.5),
                            .init(color: .white.opacity(0.2), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.5),
                            .init(color: .black.opacity(0.08), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    private func sendOTP() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.login(phone: phoneNumber)
                onOTPSent()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - OTP Verify View
struct OTPVerifyView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    let onVerified: () -> Void
    let onSkip: () -> Void
    @State private var otp = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isOTPFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button(action: onSkip) {
                    Text("Skip")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.trailing, 24)
            }
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 8) {
                Text("Enter verification code")
                    .font(AppTheme.Typography.headline(20))
                    .foregroundColor(AppTheme.textPrimary)

                Text("We sent a 6-digit code to your phone")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.textSecondary)
            }

            // OTP Input
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(
                        digit: index < otp.count ? String(otp[otp.index(otp.startIndex, offsetBy: index)]) : ""
                    )
                }
            }
            .padding(.top, 32)
            .onTapGesture {
                isOTPFocused = true
            }

            // Hidden text field for OTP input
            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .focused($isOTPFocused)
                .opacity(0)
                .frame(height: 0)
                .onChange(of: otp) { _, newValue in
                    if newValue.count > 6 {
                        otp = String(newValue.prefix(6))
                    }
                    if newValue.count == 6 {
                        verifyOTP()
                    }
                }

            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(AppTheme.error)
                    .padding(.top, 12)
            }

            // Resend
            Button(action: {}) {
                Text("Didn't receive code? ")
                    .foregroundColor(AppTheme.textSecondary)
                +
                Text("Resend")
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            .font(AppTheme.Typography.caption())
            .padding(.top, 20)

            Spacer()

            VStack(spacing: 16) {
                Button(action: verifyOTP) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify")
                            .font(AppTheme.Typography.accent(17))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(otp.count == 6 ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.textTertiary], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(otp.count != 6 || isLoading)

                Button(action: onSkip) {
                    Text("Continue without login")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
        .onAppear { isOTPFocused = true }
    }

    private func verifyOTP() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authManager.verifyOTP(otp: otp)
                onVerified()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct OTPDigitBox: View {
    let digit: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(digit)
            .font(AppTheme.Typography.title(24))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: 48, height: 56)
            .background(boxBackground)
            .overlay(boxBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var boxBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        }
    }

    private var boxBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                digit.isEmpty
                    ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                    : Color.blue,
                lineWidth: digit.isEmpty ? 1 : 2
            )
    }
}

// MARK: - Signup View
struct SignupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    let onSkip: () -> Void
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button(action: onSkip) {
                    Text("Skip")
                        .font(AppTheme.Typography.body())
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.trailing, 24)
            }
            .padding(.top, 16)

            VStack(spacing: 8) {
                Text("Complete your profile")
                    .font(AppTheme.Typography.headline(20))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Just a few more details to get started")
                    .font(AppTheme.Typography.body())
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(.top, 24)

            VStack(spacing: 16) {
                FormFieldStyled(label: "FIRST NAME", text: $firstName)
                FormFieldStyled(label: "LAST NAME", text: $lastName)
                FormFieldStyled(label: "EMAIL", text: $email, keyboardType: .emailAddress)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 16) {
                Button(action: completeSignup) {
                    Text("Continue")
                        .font(AppTheme.Typography.accent(17))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(AppTheme.Typography.caption())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
    }

    private func completeSignup() {
        // In real app, would update user profile
        authManager.completeOnboarding()
    }
}

struct FormFieldStyled: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            TextField("", text: $text)
                .font(AppTheme.Typography.body())
                .keyboardType(keyboardType)
                .padding()
                .background(fieldBackground)
                .overlay(fieldBorder)
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    @ViewBuilder
    private var fieldBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        }
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.3), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.5),
                            .init(color: .white.opacity(0.2), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.5),
                            .init(color: .black.opacity(0.08), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// Keep legacy FormField for compatibility
struct FormField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        FormFieldStyled(label: label, text: $text, keyboardType: keyboardType)
    }
}

#Preview {
    AuthFlow()
        .environmentObject(AuthManager())
}
