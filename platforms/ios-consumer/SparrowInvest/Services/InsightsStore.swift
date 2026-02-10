//
//  InsightsStore.swift
//  SparrowInvest
//
//  AI Insights state management matching Android InsightsViewModel
//

import Foundation
import SwiftUI

// MARK: - UI State

enum InsightsUiState: Equatable {
    case idle
    case analyzing
    case success
    case error(String)
}

// MARK: - Alert Models

enum InsightsAlertType {
    case warning, info, success, actionRequired

    var color: Color {
        switch self {
        case .warning: return .orange
        case .info: return .blue
        case .success: return .green
        case .actionRequired: return .red
        }
    }

    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .actionRequired: return "bell.badge.fill"
        }
    }
}

enum InsightsAlertPriority: String {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}

struct PortfolioAlert: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: InsightsAlertType
    let priority: InsightsAlertPriority
    var actionLabel: String?
}

// MARK: - Insight Card Models

enum InsightsCardType {
    case diversification
    case riskAdjustedReturns
    case expenseRatio
    case taxEfficiency
    case goalProgress

    var color: Color {
        switch self {
        case .diversification: return .blue
        case .riskAdjustedReturns: return .green
        case .expenseRatio: return .orange
        case .taxEfficiency: return Color(hex: "8B5CF6")
        case .goalProgress: return .blue
        }
    }

    var icon: String {
        switch self {
        case .diversification: return "shield.fill"
        case .riskAdjustedReturns: return "chart.line.uptrend.xyaxis"
        case .expenseRatio: return "info.circle.fill"
        case .taxEfficiency: return "checkmark.circle.fill"
        case .goalProgress: return "lightbulb.fill"
        }
    }
}

struct InsightsCard: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: InsightsCardType
    var value: String?
    var trend: Double?
}

// MARK: - Action Item Models

struct ActionTypeData {
    let displayName: String
    let color: Color

    static let buy = ActionTypeData(displayName: "Buy", color: Color(hex: "10B981"))
    static let sell = ActionTypeData(displayName: "Sell", color: Color(hex: "EF4444"))
    static let hold = ActionTypeData(displayName: "Hold", color: Color(hex: "64748B"))
    static let increaseSIP = ActionTypeData(displayName: "Increase SIP", color: Color(hex: "10B981"))
    static let startSIP = ActionTypeData(displayName: "Start SIP", color: Color(hex: "10B981"))
    static let rebalance = ActionTypeData(displayName: "Rebalance", color: Color(hex: "F59E0B"))
}

enum InsightsActionPriority: String {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct ActionItemData: Identifiable {
    let id = UUID()
    let action: ActionTypeData
    let fundName: String
    let reason: String
    let priority: InsightsActionPriority
    var amount: Double?
}

// MARK: - Analysis Result

struct AnalysisResult {
    let overallScore: Int
    let diversificationScore: Int
    let riskAlignmentScore: Int
    let costEfficiencyScore: Int
    let summary: String
    let strengths: [String]
    let weaknesses: [String]
    let riskAssessment: RiskAssessmentData?
}

struct RiskAssessmentData {
    let currentRiskLevel: String
    let recommendedRiskLevel: String
    let aligned: Bool
    let explanation: String
}

// MARK: - Insights View Mode (separate from DashboardStore's PortfolioViewMode)

enum InsightsViewMode: String, CaseIterable {
    case individual = "Individual"
    case family = "Family"
}

// MARK: - Insights Store

@MainActor
class InsightsStore: ObservableObject {
    @Published var uiState: InsightsUiState = .idle
    @Published var analysisResult: AnalysisResult?
    @Published var alerts: [PortfolioAlert] = []
    @Published var actionItems: [ActionItemData] = []
    @Published var insightCards: [InsightsCard] = []
    @Published var lastAnalyzedDate: String?
    @Published var portfolioViewMode: InsightsViewMode = .individual

    // MARK: - Actions

    func analyzePortfolio() {
        guard uiState != .analyzing else { return }
        uiState = .analyzing

        // Simulate API call with delay
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            analysisResult = createMockAnalysis()
            uiState = .success
            loadAlerts()
            loadActionItems()
            loadInsightCards()
            lastAnalyzedDate = "Jan 19, 2026"
        }
    }

    func dismissAlert(id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            alerts.removeAll { $0.id == id }
        }
    }

    func setPortfolioViewMode(_ mode: InsightsViewMode) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            portfolioViewMode = mode
            // Reset analysis when switching modes
            uiState = .idle
            analysisResult = nil
            alerts = []
            actionItems = []
            insightCards = []
            lastAnalyzedDate = nil
        }
    }

    // MARK: - Mock Data (matching Android InsightsViewModel exactly)

    private func loadAlerts() {
        alerts = [
            PortfolioAlert(
                id: "1",
                title: "High Mid-Cap Exposure",
                message: "Your mid-cap allocation (38%) is above recommended levels for a moderate risk profile. Consider rebalancing.",
                type: .warning,
                priority: .high,
                actionLabel: "Rebalance Now"
            ),
            PortfolioAlert(
                id: "2",
                title: "Tax Saving Opportunity",
                message: "You can invest \u{20B9}50,000 more in ELSS funds to maximize your 80C deductions before March 31.",
                type: .info,
                priority: .medium,
                actionLabel: "Explore ELSS"
            ),
            PortfolioAlert(
                id: "3",
                title: "SIP Due Tomorrow",
                message: "Your Parag Parikh Flexi Cap SIP of \u{20B9}10,000 is due tomorrow. Ensure sufficient balance.",
                type: .actionRequired,
                priority: .high,
                actionLabel: "View SIP"
            ),
            PortfolioAlert(
                id: "4",
                title: "Goal On Track",
                message: "Your Retirement Fund goal is on track! You've achieved 25% of your target.",
                type: .success,
                priority: .low
            )
        ]
    }

    private func loadActionItems() {
        actionItems = [
            ActionItemData(
                action: .rebalance,
                fundName: "Mid-Cap to Large-Cap",
                reason: "Reduce mid-cap exposure by 8% and increase large-cap allocation for better risk management",
                priority: .high
            ),
            ActionItemData(
                action: .startSIP,
                fundName: "Motilal Oswal Nasdaq 100 FOF",
                reason: "Add international equity exposure for geographic diversification",
                priority: .medium,
                amount: 3000
            ),
            ActionItemData(
                action: .increaseSIP,
                fundName: "ICICI Prudential Corporate Bond",
                reason: "Increase debt allocation for portfolio stability",
                priority: .medium,
                amount: 2000
            ),
            ActionItemData(
                action: .buy,
                fundName: "Nippon India Gold Savings Fund",
                reason: "Add gold exposure as inflation hedge and portfolio diversifier",
                priority: .low,
                amount: 5000
            )
        ]
    }

    private func loadInsightCards() {
        insightCards = [
            InsightsCard(
                id: "1",
                title: "Diversification Score",
                description: "Your portfolio is well-diversified across 5 asset classes",
                type: .diversification,
                value: "Good",
                trend: 5.0
            ),
            InsightsCard(
                id: "2",
                title: "Risk-Adjusted Returns",
                description: "Sharpe Ratio of 1.2 indicates efficient risk management",
                type: .riskAdjustedReturns,
                value: "1.2",
                trend: 0.1
            ),
            InsightsCard(
                id: "3",
                title: "Expense Ratio",
                description: "Portfolio weighted average expense ratio",
                type: .expenseRatio,
                value: "0.45%",
                trend: -0.05
            ),
            InsightsCard(
                id: "4",
                title: "Tax Efficiency",
                description: "Estimated tax liability on current gains",
                type: .taxEfficiency,
                value: "\u{20B9}8,250"
            )
        ]
    }

    private func createMockAnalysis() -> AnalysisResult {
        AnalysisResult(
            overallScore: 78,
            diversificationScore: 72,
            riskAlignmentScore: 85,
            costEfficiencyScore: 82,
            summary: "Your portfolio shows good diversification across asset classes with a slight overweight in mid-cap equity. The overall risk-return profile aligns well with your moderate investment strategy.",
            strengths: [
                "Well-diversified across large, mid, and flexi cap funds",
                "Low expense ratio funds selected (avg 0.45%)",
                "Good mix of growth and value-oriented funds",
                "Risk profile aligned with moderate investment strategy",
                "Consistent SIP discipline maintained"
            ],
            weaknesses: [
                "Limited exposure to international equities (0%)",
                "Mid-cap allocation slightly higher than recommended",
                "Could benefit from more debt allocation for stability",
                "No ELSS funds - missing tax saving opportunity"
            ],
            riskAssessment: RiskAssessmentData(
                currentRiskLevel: "Moderate-High",
                recommendedRiskLevel: "Moderate",
                aligned: false,
                explanation: "Your current portfolio risk is slightly higher than your stated moderate risk preference due to high mid-cap exposure."
            )
        )
    }
}
