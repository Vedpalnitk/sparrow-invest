import Foundation

// MARK: - Login Request

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// MARK: - Register Request

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case name, email, password, phone
    }
}

// MARK: - Auth Response (from /auth/login or /auth/register)

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let user: AuthUser?

    struct AuthUser: Decodable {
        let id: String
        let email: String
        let role: String
    }

    /// Returns the user ID
    var effectiveUserId: String? {
        user?.id
    }

    /// Returns the user name (email as fallback)
    var effectiveUserName: String? {
        user?.email
    }
}

// MARK: - Refresh Token Request

struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - User Profile Response (from /auth/me)

struct UserProfileResponse: Decodable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let role: String?
    let isVerified: Bool?
    let clientType: String?
    let clientId: String?
    let kycStatus: String?
    let riskProfile: String?
    let city: String?
    let state: String?
    let advisor: AdvisorInfo?
    let family: FamilyInfo?

    struct AdvisorInfo: Decodable {
        let id: String
        let name: String
        let email: String
    }

    struct FamilyInfo: Decodable {
        let groupId: String
        let role: String?
        let isHead: Bool?
        let members: [FamilyMember]?

        struct FamilyMember: Decodable {
            let id: String
            let name: String
            let role: String?
            let riskProfile: String?
        }
    }

    /// Convert to User model
    func toUser() -> User {
        let nameParts = name.split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? name
        let lastName = nameParts.dropFirst().joined(separator: " ")

        let kycStatusEnum: User.KYCStatus = {
            switch kycStatus?.lowercased() {
            case "verified": return .verified
            case "in_progress", "submitted": return .inProgress
            case "rejected": return .rejected
            default: return .pending
            }
        }()

        let riskProfileValue: RiskProfile? = {
            guard let profile = riskProfile?.lowercased() else { return nil }
            let category: RiskCategory
            switch profile {
            case "conservative": category = .conservative
            case "moderately_conservative": category = .moderatelyConservative
            case "moderate": category = .moderate
            case "moderately_aggressive": category = .moderatelyAggressive
            case "aggressive": category = .aggressive
            default: category = .moderate
            }
            return RiskProfile(score: 5, category: category, assessedAt: Date())
        }()

        return User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone ?? "",
            panNumber: nil,
            kycStatus: kycStatusEnum,
            riskProfile: riskProfileValue,
            createdAt: Date(),
            clientType: clientType,
            advisorName: advisor?.name,
            advisorEmail: advisor?.email,
            familyRole: family?.role,
            familyMembers: family?.members?.map { member in
                User.FamilyMember(
                    id: member.id,
                    name: member.name,
                    role: member.role ?? "",
                    riskProfile: member.riskProfile ?? ""
                )
            }
        )
    }
}

// MARK: - Portfolio Response (from /auth/me/portfolio)

struct PortfolioResponse: Decodable {
    let clientType: String
    let clientId: String?
    let advisor: AdvisorResponse?
    let portfolio: PortfolioData
    let family: FamilyData?

    struct AdvisorResponse: Decodable {
        let id: String
        let name: String
        let email: String
    }

    struct PortfolioData: Decodable {
        let totalValue: Double
        let totalInvested: Double
        let totalReturns: Double
        let returnsPercentage: Double
        let holdingsCount: Int
        let activeSIPs: Int
        let holdings: [HoldingData]?
        let sips: [SIPData]?
    }

    struct HoldingData: Decodable {
        let id: String
        let fundName: String
        let fundCategory: String
        let assetClass: String
        let units: String
        let avgNav: String
        let currentNav: String
        let investedValue: String
        let currentValue: String
        let gain: String
        let gainPercent: String
        let xirr: String?
    }

    struct SIPData: Decodable {
        let id: String
        let fundName: String
        let fundSchemeCode: String?
        let amount: Double
        let frequency: String
        let sipDate: Int?
        let nextSipDate: String?
        let status: String
        let totalInvested: Double?
        let currentValue: Double?
        let returns: Double?
        let completedInstallments: Int?
    }

    struct FamilyData: Decodable {
        let groupId: String
        let currentMemberRole: String?
        let isHead: Bool
        let totalValue: Double
        let totalInvested: Double
        let totalReturns: Double
        let returnsPercentage: Double
        let members: [FamilyMemberData]
    }

    struct FamilyMemberData: Decodable {
        let id: String
        let name: String
        let role: String?
        let riskProfile: String?
        let isCurrentUser: Bool
        let portfolio: MemberPortfolioData
    }

    /// Portfolio data for family members (includes holdings)
    struct MemberPortfolioData: Decodable {
        let totalValue: Double
        let totalInvested: Double
        let totalReturns: Double
        let returnsPercentage: Double
        let holdingsCount: Int
        let activeSIPs: Int
        let holdings: [HoldingData]?
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case networkError
    case serverError(String)
    case tokenExpired
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Network error. Please check your connection"
        case .serverError(let message):
            return message
        case .tokenExpired:
            return "Session expired. Please login again"
        case .notAuthenticated:
            return "Please login to continue"
        }
    }
}
