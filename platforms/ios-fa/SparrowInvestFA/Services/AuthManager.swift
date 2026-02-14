import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var user: FAUser?
    @Published var authError: String?

    private let userKey = "fa_user"
    private let tokenKey = "authToken"

    init() {
        // Restore session
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let savedUser = try? JSONDecoder().decode(FAUser.self, from: userData) {
                self.user = savedUser
                self.isAuthenticated = true
            }
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        authError = nil

        do {
            let request = LoginRequest(email: email, password: password)
            let data = try await APIService.shared.post("/auth/login", body: request) as Data

            // Debug: print raw response
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("Login response: \(jsonStr)")
            }

            let response = try JSONDecoder().decode(LoginResponse.self, from: data)
            APIService.shared.setAuthToken(response.accessToken)
            UserDefaults.standard.set(response.accessToken, forKey: tokenKey)

            // Use user from login response if available, otherwise fetch /auth/me
            if let loginUser = response.user {
                self.user = loginUser
            } else {
                let profile: FAUser = try await APIService.shared.get("/auth/me")
                self.user = profile
            }

            // Save user data
            if let user = self.user, let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: userKey)
            }

            isAuthenticated = true
        } catch let error as APIError {
            print("API error: \(error)")
            authError = error.errorDescription
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            authError = "Data format error: \(error.localizedDescription)"
        } catch {
            print("Login error: \(error)")
            authError = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        APIService.shared.clearAuthToken()
        UserDefaults.standard.removeObject(forKey: userKey)
        user = nil
        isAuthenticated = false
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
}

// Note: Notification.Name.userDidLogout is declared in AvyaChatStore.swift
