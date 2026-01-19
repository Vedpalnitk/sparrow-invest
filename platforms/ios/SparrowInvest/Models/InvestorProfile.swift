//
//  InvestorProfile.swift
//  SparrowInvest
//
//  Investor profile model for AI-powered portfolio analysis
//

import Foundation

// MARK: - Investor Profile for Analysis

struct InvestorProfile: Codable, Identifiable {
    let id: String
    var name: String
    var age: Int
    var investmentExperience: InvestmentExperience
    var riskTolerance: RiskTolerance
    var investmentGoal: InvestmentGoal
    var investmentHorizon: InvestmentHorizon
    var monthlyIncome: IncomeRange
    var existingInvestments: Double
    var monthlyInvestmentCapacity: Double
    var createdAt: Date
    var updatedAt: Date

    // Computed risk score based on answers
    var computedRiskScore: Int {
        var score = 0

        // Age factor (younger = higher risk capacity)
        switch age {
        case ..<30: score += 25
        case 30..<40: score += 20
        case 40..<50: score += 15
        case 50..<60: score += 10
        default: score += 5
        }

        // Experience factor
        score += investmentExperience.scoreContribution

        // Risk tolerance factor
        score += riskTolerance.scoreContribution

        // Investment horizon factor
        score += investmentHorizon.scoreContribution

        // Goal factor
        score += investmentGoal.scoreContribution

        return min(100, max(0, score))
    }

    var recommendedRiskCategory: RiskCategory {
        switch computedRiskScore {
        case 0..<20: return .conservative
        case 20..<40: return .moderatelyConservative
        case 40..<60: return .moderate
        case 60..<80: return .moderatelyAggressive
        default: return .aggressive
        }
    }

    static var empty: InvestorProfile {
        InvestorProfile(
            id: UUID().uuidString,
            name: "",
            age: 30,
            investmentExperience: .beginner,
            riskTolerance: .moderate,
            investmentGoal: .wealthCreation,
            investmentHorizon: .mediumTerm,
            monthlyIncome: .range3to5L,
            existingInvestments: 0,
            monthlyInvestmentCapacity: 10000,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Investment Experience

enum InvestmentExperience: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case experienced = "Experienced"
    case expert = "Expert"

    var description: String {
        switch self {
        case .beginner: return "New to investing (< 1 year)"
        case .intermediate: return "Some experience (1-3 years)"
        case .experienced: return "Regular investor (3-7 years)"
        case .expert: return "Seasoned investor (7+ years)"
        }
    }

    var scoreContribution: Int {
        switch self {
        case .beginner: return 5
        case .intermediate: return 10
        case .experienced: return 15
        case .expert: return 20
        }
    }
}

// MARK: - Risk Tolerance

enum RiskTolerance: String, Codable, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"

    var description: String {
        switch self {
        case .veryLow: return "I cannot tolerate any loss"
        case .low: return "I can handle small losses (up to 5%)"
        case .moderate: return "I can handle moderate losses (up to 15%)"
        case .high: return "I can handle significant losses (up to 25%)"
        case .veryHigh: return "I can handle large losses for higher returns"
        }
    }

    var scoreContribution: Int {
        switch self {
        case .veryLow: return 5
        case .low: return 10
        case .moderate: return 15
        case .high: return 20
        case .veryHigh: return 25
        }
    }
}

// MARK: - Investment Goal

enum InvestmentGoal: String, Codable, CaseIterable {
    case capitalPreservation = "Capital Preservation"
    case regularIncome = "Regular Income"
    case wealthCreation = "Wealth Creation"
    case retirement = "Retirement Planning"
    case childEducation = "Child's Education"
    case homePurchase = "Home Purchase"
    case taxSaving = "Tax Saving"

    var icon: String {
        switch self {
        case .capitalPreservation: return "shield.fill"
        case .regularIncome: return "indianrupeesign.circle.fill"
        case .wealthCreation: return "chart.line.uptrend.xyaxis"
        case .retirement: return "beach.umbrella.fill"
        case .childEducation: return "graduationcap.fill"
        case .homePurchase: return "house.fill"
        case .taxSaving: return "percent"
        }
    }

    var scoreContribution: Int {
        switch self {
        case .capitalPreservation: return 5
        case .regularIncome: return 10
        case .taxSaving: return 12
        case .retirement: return 15
        case .homePurchase: return 15
        case .childEducation: return 18
        case .wealthCreation: return 20
        }
    }
}

// MARK: - Investment Horizon

enum InvestmentHorizon: String, Codable, CaseIterable {
    case shortTerm = "Short Term"
    case mediumTerm = "Medium Term"
    case longTerm = "Long Term"
    case veryLongTerm = "Very Long Term"

    var description: String {
        switch self {
        case .shortTerm: return "Less than 1 year"
        case .mediumTerm: return "1-3 years"
        case .longTerm: return "3-7 years"
        case .veryLongTerm: return "More than 7 years"
        }
    }

    var scoreContribution: Int {
        switch self {
        case .shortTerm: return 5
        case .mediumTerm: return 10
        case .longTerm: return 15
        case .veryLongTerm: return 20
        }
    }
}

// MARK: - Income Range

enum IncomeRange: String, Codable, CaseIterable {
    case below3L = "Below ₹3 Lakhs"
    case range3to5L = "₹3-5 Lakhs"
    case range5to10L = "₹5-10 Lakhs"
    case range10to25L = "₹10-25 Lakhs"
    case above25L = "Above ₹25 Lakhs"

    var midValue: Double {
        switch self {
        case .below3L: return 200000
        case .range3to5L: return 400000
        case .range5to10L: return 750000
        case .range10to25L: return 1750000
        case .above25L: return 3500000
        }
    }
}

// MARK: - Portfolio Input for Analysis

struct AnalysisPortfolio: Codable, Identifiable {
    let id: String
    var name: String
    var holdings: [AnalysisHolding]
    var createdAt: Date
    var updatedAt: Date

    var totalInvestedAmount: Double {
        holdings.reduce(0) { $0 + $1.investedAmount }
    }

    var totalCurrentValue: Double {
        holdings.reduce(0) { $0 + $1.currentValue }
    }

    var totalReturns: Double {
        totalCurrentValue - totalInvestedAmount
    }

    var returnsPercentage: Double {
        guard totalInvestedAmount > 0 else { return 0 }
        return (totalReturns / totalInvestedAmount) * 100
    }

    static var empty: AnalysisPortfolio {
        AnalysisPortfolio(
            id: UUID().uuidString,
            name: "My Portfolio",
            holdings: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct AnalysisHolding: Codable, Identifiable {
    let id: String
    var fundName: String
    var fundCode: String?
    var category: String
    var assetClass: Holding.AssetClass
    var investedAmount: Double
    var currentValue: Double
    var units: Double

    var returns: Double {
        currentValue - investedAmount
    }

    var returnsPercentage: Double {
        guard investedAmount > 0 else { return 0 }
        return (returns / investedAmount) * 100
    }

    init(id: String = UUID().uuidString, fundName: String, fundCode: String? = nil, category: String, assetClass: Holding.AssetClass, investedAmount: Double, currentValue: Double, units: Double) {
        self.id = id
        self.fundName = fundName
        self.fundCode = fundCode
        self.category = category
        self.assetClass = assetClass
        self.investedAmount = investedAmount
        self.currentValue = currentValue
        self.units = units
    }
}
