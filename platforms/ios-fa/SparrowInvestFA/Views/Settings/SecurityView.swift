import SwiftUI
import LocalAuthentication

struct SecurityView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var biometricEnabled = false
    @State private var twoFactorEnabled = false
    @State private var showChangePassword = false
    @State private var selectedTimeout = "15 min"
    @State private var showSavedToast = false
    @State private var showChangePinSheet = false
    @State private var isToggling2FA = false

    // Change Password fields
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var passwordError: String?
    @State private var isChangingPassword = false
    @State private var passwordChanged = false

    private let timeoutOptions = ["5 min", "10 min", "15 min", "30 min", "1 hour"]

    private var biometricType: String {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "Biometric"
        }
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometric"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Change Password Section
                    sectionHeader("PASSWORD")
                    changePasswordSection

                    // Biometric Section
                    sectionHeader("AUTHENTICATION")
                    VStack(spacing: 0) {
                        biometricToggle
                        twoFactorToggle
                        sessionTimeoutPicker
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Transaction PIN Section
                    sectionHeader("TRANSACTION PIN")
                    VStack(spacing: 0) {
                        Button {
                            showChangePinSheet = true
                        } label: {
                            HStack(spacing: AppTheme.Spacing.compact) {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Change Transaction PIN")
                                        .font(AppTheme.Typography.accent(15))
                                        .foregroundColor(.primary)

                                    Text("PIN required to approve and execute trades")
                                        .font(AppTheme.Typography.label(12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppTheme.Spacing.compact)
                            .padding(.horizontal, AppTheme.Spacing.small)
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Devices Section
                    sectionHeader("DEVICES")
                    VStack(spacing: 0) {
                        NavigationLink {
                            ActiveSessionsView()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.compact) {
                                Image(systemName: "iphone")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Active Sessions")
                                        .font(AppTheme.Typography.accent(15))
                                        .foregroundColor(.primary)

                                    Text("Manage logged-in devices")
                                        .font(AppTheme.Typography.label(12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppTheme.Spacing.compact)
                            .padding(.horizontal, AppTheme.Spacing.small)
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .overlay(
            showSavedToast ? savedToast : nil,
            alignment: .bottom
        )
        .sheet(isPresented: $showChangePinSheet) {
            ChangePinSheet()
        }
    }

    // MARK: - Change Password Section

    private var changePasswordSection: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Current Password
            passwordField(
                label: "CURRENT PASSWORD",
                placeholder: "Enter current password",
                text: $currentPassword,
                isSecure: !showCurrentPassword,
                toggleVisibility: { showCurrentPassword.toggle() },
                showToggle: true,
                isVisible: showCurrentPassword
            )

            // New Password
            passwordField(
                label: "NEW PASSWORD",
                placeholder: "Min 8 characters",
                text: $newPassword,
                isSecure: !showNewPassword,
                toggleVisibility: { showNewPassword.toggle() },
                showToggle: true,
                isVisible: showNewPassword
            )

            // Confirm Password
            passwordField(
                label: "CONFIRM NEW PASSWORD",
                placeholder: "Re-enter new password",
                text: $confirmPassword,
                isSecure: true,
                toggleVisibility: {},
                showToggle: false,
                isVisible: false
            )

            // Error message
            if let error = passwordError {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(error)
                        .font(AppTheme.Typography.caption(13))
                }
                .foregroundColor(AppTheme.error)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Success message
            if passwordChanged {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Password updated successfully")
                        .font(AppTheme.Typography.caption(13))
                }
                .foregroundColor(AppTheme.success)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Save Button
            Button {
                changePassword()
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    if isChangingPassword {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Update Password")
                            .font(AppTheme.Typography.accent(15))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(currentPassword.isEmpty || newPassword.isEmpty ||
                      confirmPassword.isEmpty || isChangingPassword)
            .opacity(currentPassword.isEmpty || newPassword.isEmpty ||
                     confirmPassword.isEmpty ? 0.6 : 1)
            .padding(.top, AppTheme.Spacing.small)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: - Password Field

    private func passwordField(
        label: String, placeholder: String,
        text: Binding<String>, isSecure: Bool,
        toggleVisibility: @escaping () -> Void,
        showToggle: Bool, isVisible: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            Text(label)
                .font(AppTheme.Typography.label(11))
                .foregroundColor(AppTheme.primary)

            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "lock")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                if isSecure {
                    SecureField(placeholder, text: text)
                        .font(AppTheme.Typography.body(15))
                } else {
                    TextField(placeholder, text: text)
                        .font(AppTheme.Typography.body(15))
                }

                if showToggle {
                    Button(action: toggleVisibility) {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 48)
            .background(inputBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(inputBorder)
        }
    }

    // MARK: - Biometric Toggle

    private var biometricToggle: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: biometricType == "Face ID" ? "faceid" : "touchid")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(biometricType) Login")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Text("Use \(biometricType.lowercased()) to unlock the app")
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $biometricEnabled)
                .labelsHidden()
                .onChange(of: biometricEnabled) { _, newValue in
                    if newValue {
                        authenticateBiometric()
                    }
                }
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Two-Factor Authentication Toggle

    private var twoFactorToggle: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("Two-Factor Authentication")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Text("Extra security via OTP on login")
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isToggling2FA {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: $twoFactorEnabled)
                    .labelsHidden()
                    .onChange(of: twoFactorEnabled) { _, newValue in
                        toggle2FA(enabled: newValue)
                    }
            }
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Session Timeout Picker

    private var sessionTimeoutPicker: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: "clock")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("Session Timeout")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Text("Auto-lock after inactivity")
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Menu {
                ForEach(timeoutOptions, id: \.self) { option in
                    Button {
                        selectedTimeout = option
                    } label: {
                        HStack {
                            Text(option)
                            if option == selectedTimeout {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedTimeout)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(AppTheme.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, AppTheme.Spacing.micro)
                .background(AppTheme.primary.opacity(0.1))
                .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Menu Item

    private func menuItem(
        icon: String, title: String, subtitle: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.compact) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.label(12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, AppTheme.Spacing.compact)
            .padding(.horizontal, AppTheme.Spacing.small)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.label(11))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppTheme.Spacing.compact)
            .padding(.top, AppTheme.Spacing.small)
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.success)
            Text("Settings saved")
                .font(AppTheme.Typography.accent(14))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        .padding(.bottom, AppTheme.Spacing.xxLarge)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Input Styling

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
    }

    // MARK: - Actions

    private func changePassword() {
        passwordError = nil
        passwordChanged = false

        guard !currentPassword.isEmpty else {
            passwordError = "Current password is required"
            return
        }
        guard newPassword.count >= 8 else {
            passwordError = "Password must be at least 8 characters"
            return
        }
        guard newPassword == confirmPassword else {
            passwordError = "Passwords do not match"
            return
        }

        isChangingPassword = true
        Task {
            do {
                struct ChangePasswordRequest: Encodable {
                    let currentPassword: String
                    let newPassword: String
                }
                let request = ChangePasswordRequest(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                let _ = try await APIService.shared.put("/auth/change-password", body: request)
                await MainActor.run {
                    isChangingPassword = false
                    passwordChanged = true
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    passwordChanged = false
                }
            } catch {
                await MainActor.run {
                    isChangingPassword = false
                    passwordError = error.localizedDescription
                }
            }
        }
    }

    private func toggle2FA(enabled: Bool) {
        isToggling2FA = true
        Task {
            do {
                struct TwoFactorRequest: Encodable {
                    let enabled: Bool
                }
                let request = TwoFactorRequest(enabled: enabled)
                let _ = try await APIService.shared.put("/auth/2fa", body: request)
                await MainActor.run {
                    isToggling2FA = false
                    withAnimation {
                        showSavedToast = true
                    }
                }
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    withAnimation {
                        showSavedToast = false
                    }
                }
            } catch {
                await MainActor.run {
                    isToggling2FA = false
                    twoFactorEnabled = !enabled // Revert on failure
                }
            }
        }
    }

    private func authenticateBiometric() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricEnabled = false
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Enable \(biometricType) for app login"
        ) { success, authError in
            DispatchQueue.main.async {
                if !success {
                    biometricEnabled = false
                }
            }
        }
    }
}

// MARK: - Change PIN Sheet

struct ChangePinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPin = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var pinError: String?
    @State private var isChanging = false
    @State private var pinChanged = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Info banner
                    HStack(spacing: AppTheme.Spacing.compact) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.primary)

                        Text("Transaction PIN is required when approving or executing trades.")
                            .font(AppTheme.Typography.accent(13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.compact)
                    .background(AppTheme.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))

                    // Current PIN
                    pinField(label: "CURRENT PIN", placeholder: "Enter current 4-digit PIN", text: $currentPin)

                    // New PIN
                    pinField(label: "NEW PIN", placeholder: "Enter new 4-digit PIN", text: $newPin)

                    // Confirm PIN
                    pinField(label: "CONFIRM NEW PIN", placeholder: "Re-enter new PIN", text: $confirmPin)

                    // Error
                    if let error = pinError {
                        HStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(AppTheme.Typography.caption(13))
                        }
                        .foregroundColor(AppTheme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Success
                    if pinChanged {
                        HStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                            Text("Transaction PIN updated successfully")
                                .font(AppTheme.Typography.caption(13))
                        }
                        .foregroundColor(AppTheme.success)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Submit
                    Button {
                        changePin()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.small) {
                            if isChanging {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Update PIN")
                                    .font(AppTheme.Typography.accent(15))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(AppTheme.primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty || isChanging)
                    .opacity(currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty ? 0.6 : 1)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.compact)
            }
            .navigationTitle("Change Transaction PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func pinField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            Text(label)
                .font(AppTheme.Typography.label(11))
                .foregroundColor(AppTheme.primary)

            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                SecureField(placeholder, text: text)
                    .font(AppTheme.Typography.body(15))
                    .keyboardType(.numberPad)
                    .onChange(of: text.wrappedValue) { _, newValue in
                        // Limit to 4 digits
                        if newValue.count > 4 {
                            text.wrappedValue = String(newValue.prefix(4))
                        }
                        // Only allow digits
                        text.wrappedValue = text.wrappedValue.filter { $0.isNumber }
                    }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 48)
            .background(
                colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill)
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
    }

    private func changePin() {
        pinError = nil
        pinChanged = false

        guard currentPin.count == 4 else {
            pinError = "Current PIN must be 4 digits"
            return
        }
        guard newPin.count == 4 else {
            pinError = "New PIN must be 4 digits"
            return
        }
        guard newPin == confirmPin else {
            pinError = "PINs do not match"
            return
        }
        guard newPin != currentPin else {
            pinError = "New PIN must be different from current PIN"
            return
        }

        isChanging = true
        Task {
            do {
                struct ChangePinRequest: Encodable {
                    let currentPin: String
                    let newPin: String
                }
                let request = ChangePinRequest(currentPin: currentPin, newPin: newPin)
                let _ = try await APIService.shared.put("/auth/change-pin", body: request)
                await MainActor.run {
                    isChanging = false
                    pinChanged = true
                    currentPin = ""
                    newPin = ""
                    confirmPin = ""
                }
                try? await Task.sleep(for: .seconds(2))
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isChanging = false
                    pinError = error.localizedDescription
                }
            }
        }
    }
}
