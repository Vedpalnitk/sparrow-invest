import SwiftUI

struct BiometricLoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var biometricManager: BiometricManager
    @Environment(\.colorScheme) private var colorScheme

    let onUsePassword: () -> Void

    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            HStack(spacing: 8) {
                Image(systemName: "bird.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.primaryGradient)
                Text("Sparrow Invest")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 48)

            // Biometric Icon
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Glass card circle
                Circle()
                    .fill(iconCircleBackground)
                    .frame(width: 120, height: 120)
                    .overlay(iconCircleBorder)
                    .shadow(color: iconCircleShadow, radius: 16, x: 0, y: 6)

                // Biometric icon
                Image(systemName: biometricManager.biometricIconName)
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(AppTheme.primaryGradient)
            }
            .scaleEffect(iconScale)
            .opacity(iconOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    iconScale = 1.0
                    iconOpacity = 1.0
                }
            }

            // Title
            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)

                if let userName = authManager.user?.firstName, !userName.isEmpty {
                    Text(userName)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 28)

            // Error message
            if showError, let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                // Authenticate Button
                Button(action: performBiometricAuth) {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: biometricManager.biometricIconName)
                                .font(.system(size: 18))
                            Text("Authenticate with \(biometricManager.biometricDisplayName)")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isAuthenticating)

                // Password Fallback
                Button(action: onUsePassword) {
                    Text("Use Password Instead")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background)
        .task {
            // Auto-trigger biometric on appear
            try? await Task.sleep(nanoseconds: 400_000_000)
            performBiometricAuth()
        }
    }

    // MARK: - Biometric Authentication

    private func performBiometricAuth() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        showError = false
        errorMessage = nil

        Task {
            do {
                let success = try await biometricManager.authenticate()
                if success {
                    authManager.loginWithBiometric()
                }
            } catch let error as BiometricError {
                switch error {
                case .userCancelled:
                    // User cancelled - don't show error, just let them tap again
                    break
                case .userFallback:
                    onUsePassword()
                    return
                default:
                    withAnimation(.easeInOut(duration: 0.3)) {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } catch {
                withAnimation(.easeInOut(duration: 0.3)) {
                    errorMessage = "Authentication failed. Please try again."
                    showError = true
                }
            }
            isAuthenticating = false
        }
    }

    // MARK: - Styling

    private var iconCircleBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white
    }

    private var iconCircleBorder: some View {
        Circle()
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    private var iconCircleShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }
}

#Preview {
    BiometricLoginView(onUsePassword: {})
        .environmentObject(AuthManager())
        .environmentObject(BiometricManager())
}
