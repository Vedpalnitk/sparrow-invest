import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var biometricManager: BiometricManager
    @State private var showPasswordFallback = false

    var body: some View {
        Group {
            if !authManager.hasSeenWelcome {
                // First-time user: show intro pages
                WelcomeFlow()
            } else if !authManager.isAuthenticated && biometricManager.hasBiometricCredentials && !showPasswordFallback {
                // Biometric login: user was previously authenticated and has biometric enabled
                BiometricLoginView(onUsePassword: {
                    showPasswordFallback = true
                })
            } else if authManager.isAuthenticated {
                if authManager.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingFlow()
                }
            } else {
                AuthFlow()
            }
        }
        .animation(.easeInOut, value: authManager.hasSeenWelcome)
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .animation(.easeInOut, value: authManager.hasCompletedOnboarding)
        .animation(.easeInOut, value: showPasswordFallback)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Reset fallback flag on successful login
                showPasswordFallback = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(BiometricManager())
        .environmentObject(PortfolioStore())
        .environmentObject(GoalsStore())
        .environmentObject(FundsStore())
}
