import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
class BiometricManager: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var biometricType: LABiometryType = .none
    @AppStorage("biometricEnabled") var isBiometricEnabled = false
    @AppStorage("biometricUserId") private var storedUserId: String = ""

    init() {
        checkBiometricAvailability()
    }

    // MARK: - Check Device Biometric Support

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType
        } else {
            isBiometricAvailable = false
            biometricType = .none
        }
    }

    // MARK: - Authenticate with Face ID / Touch ID

    func authenticate() async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to Sparrow Invest"
            )
            return success
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel:
                throw BiometricError.userCancelled
            case .userFallback:
                throw BiometricError.userFallback
            case .biometryLockout:
                throw BiometricError.lockout
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            default:
                throw BiometricError.authenticationFailed
            }
        }
    }

    // MARK: - Enable / Disable Biometric

    func enableBiometric(userId: String) {
        storedUserId = userId
        isBiometricEnabled = true
    }

    func disableBiometric() {
        storedUserId = ""
        isBiometricEnabled = false
    }

    // MARK: - Credentials Check

    var hasBiometricCredentials: Bool {
        isBiometricEnabled && !storedUserId.isEmpty
    }

    // MARK: - Display Name

    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Biometric"
        }
    }

    /// SF Symbol name for the current biometric type
    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        @unknown default:
            return "lock.fill"
        }
    }
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError {
    case notAvailable
    case userCancelled
    case userFallback
    case lockout
    case notEnrolled
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "Password authentication requested"
        case .lockout:
            return "Biometric authentication is locked. Please use your device passcode to unlock"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .authenticationFailed:
            return "Authentication failed. Please try again"
        }
    }
}
