import Foundation
import SwiftUI

/// Empty body for POST requests that don't need a body
struct EmptyBody: Encodable {}

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var hasSeenWelcome = false
    @Published var isGuestUser = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var authError: String?

    private let userDefaults = UserDefaults.standard
    private let authKey = "isAuthenticated"
    private let onboardingKey = "hasCompletedOnboarding"
    private let welcomeKey = "hasSeenWelcome"
    private let guestKey = "isGuestUser"
    private let userKey = "currentUser"
    private let tokenKey = "authToken"
    private let refreshTokenKey = "refreshToken"

    private let apiService = APIService.shared

    /// Profile completion percentage (0-100)
    var profileCompletion: Int {
        guard let user = user else { return 0 }
        var completed = 0
        let total = 7

        if !user.firstName.isEmpty { completed += 1 }
        if !user.lastName.isEmpty { completed += 1 }
        if !user.email.isEmpty { completed += 1 }
        if !user.phone.isEmpty { completed += 1 }
        if user.panNumber != nil { completed += 1 }
        if user.kycStatus == .verified { completed += 1 }
        if user.riskProfile != nil { completed += 1 }

        return Int((Double(completed) / Double(total)) * 100)
    }

    var isProfileComplete: Bool {
        profileCompletion >= 100
    }

    init() {
        loadStoredAuth()
    }

    private func loadStoredAuth() {
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        hasSeenWelcome = userDefaults.bool(forKey: welcomeKey)
        isGuestUser = userDefaults.bool(forKey: guestKey)

        // Load cached user data
        if let userData = userDefaults.data(forKey: userKey) {
            user = try? JSONDecoder().decode(User.self, from: userData)
        }

        // Check if we have a stored token
        if let token = userDefaults.string(forKey: tokenKey), !token.isEmpty {
            // Restore token to API service
            apiService.setAuthToken(token)

            // Verify session is still valid (async)
            Task {
                await checkSession()
            }

            // Temporarily show as authenticated until session check completes
            isAuthenticated = userDefaults.bool(forKey: authKey)
        }

        // For guest users, mark as authenticated
        if isGuestUser {
            isAuthenticated = true
        }

        // For development - auto-login with mock user
        // Uncomment the lines below to auto-login (skips welcome flow)
        // #if DEBUG
        // if !isAuthenticated {
        //     mockLogin()
        // }
        // #endif
    }

    /// Continue as guest without phone verification
    func continueAsGuest() {
        let guestUser = User(
            id: UUID().uuidString,
            firstName: "",
            lastName: "",
            email: "",
            phone: "",
            panNumber: nil,
            kycStatus: .pending,
            riskProfile: nil,
            createdAt: Date()
        )

        self.user = guestUser
        self.isAuthenticated = true
        self.isGuestUser = true
        self.hasCompletedOnboarding = true

        userDefaults.set(true, forKey: authKey)
        userDefaults.set(true, forKey: guestKey)
        userDefaults.set(true, forKey: onboardingKey)
        saveAuth()
    }

    func completeWelcome() {
        hasSeenWelcome = true
        userDefaults.set(true, forKey: welcomeKey)
    }

    enum ResetMethod {
        case email
        case phone
    }

    func login(phone: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Phone-based OTP login not yet implemented on backend
        // For now, just store the phone and wait for OTP
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func loginWithEmail(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            // Call the auth API
            let loginRequest = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await apiService.post("/auth/login", body: loginRequest)

            // Store tokens
            apiService.setAuthToken(response.accessToken)
            if let refreshToken = response.refreshToken {
                userDefaults.set(refreshToken, forKey: refreshTokenKey)
            }

            // Fetch full user profile
            await fetchUserProfile()

            // If profile fetch failed but we have basic info, create user from response
            if user == nil {
                let nameParts = (response.effectiveUserName ?? "User").split(separator: " ")
                let firstName = nameParts.first.map(String.init) ?? "User"
                let lastName = nameParts.dropFirst().joined(separator: " ")

                user = User(
                    id: response.effectiveUserId ?? UUID().uuidString,
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone: "",
                    panNumber: nil,
                    kycStatus: .pending,
                    riskProfile: nil,
                    createdAt: Date()
                )
            }

            self.isAuthenticated = true
            self.isGuestUser = false

            // Check if user has already completed onboarding (managed client with profile)
            // Skip onboarding for managed clients or users with existing risk profile
            if let currentUser = user {
                if currentUser.isManaged || currentUser.riskProfile != nil {
                    self.hasCompletedOnboarding = true
                } else {
                    // Check if this user previously completed onboarding
                    let userOnboardingKey = "onboarding_completed_\(currentUser.id)"
                    if userDefaults.bool(forKey: userOnboardingKey) {
                        self.hasCompletedOnboarding = true
                    }
                }
            }

            saveAuth()

        } catch let error as APIError {
            switch error {
            case .unauthorized:
                authError = "Invalid email or password"
                throw AuthError.invalidCredentials
            case .serverError:
                authError = "Server error. Please try again"
                throw AuthError.serverError("Server error")
            default:
                authError = error.localizedDescription
                throw AuthError.networkError
            }
        } catch {
            authError = error.localizedDescription
            throw AuthError.networkError
        }
    }

    /// Register a new account
    func register(name: String, email: String, password: String, phone: String? = nil) async throws {
        isLoading = true
        authError = nil
        defer { isLoading = false }

        do {
            let registerRequest = RegisterRequest(name: name, email: email, password: password, phone: phone)
            let response: AuthResponse = try await apiService.post("/auth/register", body: registerRequest)

            // Store tokens
            apiService.setAuthToken(response.accessToken)
            if let refreshToken = response.refreshToken {
                userDefaults.set(refreshToken, forKey: refreshTokenKey)
            }

            // Create user from response
            let nameParts = name.split(separator: " ")
            let firstName = nameParts.first.map(String.init) ?? name
            let lastName = nameParts.dropFirst().joined(separator: " ")

            user = User(
                id: response.effectiveUserId ?? UUID().uuidString,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone ?? "",
                panNumber: nil,
                kycStatus: .pending,
                riskProfile: nil,
                createdAt: Date()
            )

            self.isAuthenticated = true
            self.isGuestUser = false
            saveAuth()

        } catch let error as APIError {
            switch error {
            case .unauthorized:
                authError = "Email already registered"
                throw AuthError.emailAlreadyExists
            default:
                authError = error.localizedDescription
                throw AuthError.networkError
            }
        } catch {
            authError = error.localizedDescription
            throw AuthError.networkError
        }
    }

    /// Fetch user profile from API
    func fetchUserProfile() async {
        do {
            let profile: UserProfileResponse = try await apiService.get("/auth/me")
            self.user = profile.toUser()
        } catch {
            // Profile fetch failed - user might still be valid if we have basic info
            print("Failed to fetch user profile: \(error)")
        }
    }

    func sendPasswordResetOTP(to identifier: String, method: ResetMethod) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate API call to send reset OTP
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // In real app, this would send OTP via email or SMS
    }

    func verifyPasswordResetOTP(otp: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate OTP verification
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // In real app, this would verify the OTP with backend
    }

    func resetPassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate password reset
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // In real app, this would update the password on backend
    }

    func verifyOTP(otp: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Simulate OTP verification
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Mock user for development
        let mockUser = User(
            id: UUID().uuidString,
            firstName: "Priya",
            lastName: "Sharma",
            email: "priya@example.com",
            phone: "+91 98765 43210",
            panNumber: "ABCDE1234F",
            kycStatus: .verified,
            riskProfile: RiskProfile(
                score: 6,
                category: .moderate,
                assessedAt: Date()
            ),
            createdAt: Date()
        )

        self.user = mockUser
        self.isAuthenticated = true

        // Save to UserDefaults
        saveAuth()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)

        // Also save per-user onboarding completion
        if let userId = user?.id {
            let userOnboardingKey = "onboarding_completed_\(userId)"
            userDefaults.set(true, forKey: userOnboardingKey)
        }
    }

    func logout() {
        // Clear server session (fire and forget)
        Task {
            try? await apiService.post("/auth/logout", body: EmptyBody())
        }

        // Clear local state
        isAuthenticated = false
        hasCompletedOnboarding = false
        hasSeenWelcome = false
        isGuestUser = false
        user = nil
        authError = nil

        // Clear stored data
        apiService.clearAuthToken()
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: onboardingKey)
        userDefaults.removeObject(forKey: welcomeKey)
        userDefaults.removeObject(forKey: guestKey)
        userDefaults.removeObject(forKey: userKey)
        userDefaults.removeObject(forKey: refreshTokenKey)
    }

    /// Refresh access token using refresh token
    func refreshAccessToken() async throws {
        guard let refreshToken = userDefaults.string(forKey: refreshTokenKey) else {
            throw AuthError.notAuthenticated
        }

        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response: AuthResponse = try await apiService.post("/auth/refresh", body: request)

            apiService.setAuthToken(response.accessToken)
            if let newRefreshToken = response.refreshToken {
                userDefaults.set(newRefreshToken, forKey: refreshTokenKey)
            }
        } catch {
            // Refresh failed - force logout
            logout()
            throw AuthError.tokenExpired
        }
    }

    /// Check if user has a valid session
    func checkSession() async {
        guard userDefaults.string(forKey: tokenKey) != nil else {
            return
        }

        do {
            await fetchUserProfile()
            if user != nil {
                isAuthenticated = true
            }
        } catch {
            // Session invalid - try refresh
            do {
                try await refreshAccessToken()
                await fetchUserProfile()
                if user != nil {
                    isAuthenticated = true
                }
            } catch {
                // Refresh also failed - clear auth
                logout()
            }
        }
    }

    private func saveAuth() {
        userDefaults.set(isAuthenticated, forKey: authKey)
        userDefaults.set(hasCompletedOnboarding, forKey: onboardingKey)
        userDefaults.set(isGuestUser, forKey: guestKey)

        if let user = user, let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }

    /// Get the current auth token (for other services that need it)
    var authToken: String? {
        userDefaults.string(forKey: tokenKey)
    }

    #if DEBUG
    func mockLogin() {
        let mockUser = User(
            id: UUID().uuidString,
            firstName: "Priya",
            lastName: "Sharma",
            email: "priya@example.com",
            phone: "+91 98765 43210",
            panNumber: "ABCDE1234F",
            kycStatus: .verified,
            riskProfile: RiskProfile(
                score: 6,
                category: .moderate,
                assessedAt: Date()
            ),
            createdAt: Date()
        )

        self.user = mockUser
        self.isAuthenticated = true
        self.hasCompletedOnboarding = true
        self.hasSeenWelcome = true
        saveAuth()
    }

    func resetToWelcome() {
        // Debug helper to reset and show welcome flow
        isAuthenticated = false
        hasCompletedOnboarding = false
        hasSeenWelcome = false
        user = nil
        userDefaults.removeObject(forKey: authKey)
        userDefaults.removeObject(forKey: onboardingKey)
        userDefaults.removeObject(forKey: welcomeKey)
        userDefaults.removeObject(forKey: userKey)
    }
    #endif
}
