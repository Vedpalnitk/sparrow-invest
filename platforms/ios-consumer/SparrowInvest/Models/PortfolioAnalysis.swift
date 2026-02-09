import Foundation
import SwiftUI

// MARK: - Fund Health Status

enum FundHealthStatus: String, Codable, CaseIterable {
    case inForm = "in_form"
    case onTrack = "on_track"
    case offTrack = "off_track"
    case outOfForm = "out_of_form"

    var label: String {
        switch self {
        case .inForm: return "In-form"
        case .onTrack: return "On-track"
        case .offTrack: return "Off-track"
        case .outOfForm: return "Out-of-form"
        }
    }

    var description: String {
        switch self {
        case .inForm: return "Performing great"
        case .onTrack: return "Performing good"
        case .offTrack: return "Don't invest further"
        case .outOfForm: return "Exit now"
        }
    }

    var actionHint: String {
        switch self {
        case .inForm: return "Continue investing"
        case .onTrack: return "Hold / invest more"
        case .offTrack: return "Review and monitor"
        case .outOfForm: return "Consider exiting"
        }
    }

    var color: Color {
        switch self {
        case .inForm: return Color(hex: "#16C47F")      // Strong green
        case .onTrack: return Color(hex: "#84CC16")     // Light green/lime
        case .offTrack: return Color(hex: "#FB923C")    // Orange/light red
        case .outOfForm: return Color(hex: "#EF4444")   // Red
        }
    }

    var icon: String {
        switch self {
        case .inForm: return "chevron.up.2"
        case .onTrack: return "chevron.up"
        case .offTrack: return "chevron.down"
        case .outOfForm: return "chevron.down.2"
        }
    }

    var sortOrder: Int {
        switch self {
        case .inForm: return 0
        case .onTrack: return 1
        case .offTrack: return 2
        case .outOfForm: return 3
        }
    }
}

// MARK: - Score Details

struct HoldingScores: Codable {
    let returnsScore: Double
    let riskScore: Double
    let consistencyScore: Double
    let momentumScore: Double
    let overallScore: Double

    enum CodingKeys: String, CodingKey {
        case returnsScore = "returns_score"
        case riskScore = "risk_score"
        case consistencyScore = "consistency_score"
        case momentumScore = "momentum_score"
        case overallScore = "overall_score"
    }
}

// MARK: - Holding Analysis

struct HoldingAnalysis: Codable, Identifiable {
    let holdingId: String
    let fundSchemeCode: String
    let fundName: String
    let fundCategory: String
    let assetClass: String
    let status: FundHealthStatus
    let statusLabel: String
    let statusDescription: String
    let actionHint: String
    let scores: HoldingScores
    let insights: [String]
    let investedValue: Double
    let currentValue: Double
    let absoluteGain: Double
    let absoluteGainPercent: Double
    let rankInPortfolio: Int?

    var id: String { holdingId }

    enum CodingKeys: String, CodingKey {
        case holdingId = "holding_id"
        case fundSchemeCode = "fund_scheme_code"
        case fundName = "fund_name"
        case fundCategory = "fund_category"
        case assetClass = "asset_class"
        case status
        case statusLabel = "status_label"
        case statusDescription = "status_description"
        case actionHint = "action_hint"
        case scores
        case insights
        case investedValue = "invested_value"
        case currentValue = "current_value"
        case absoluteGain = "absolute_gain"
        case absoluteGainPercent = "absolute_gain_percent"
        case rankInPortfolio = "rank_in_portfolio"
    }

    /// Computed status color using the enum
    var statusColor: Color { status.color }

    /// Computed status icon using the enum
    var statusIcon: String { status.icon }
}

// MARK: - Portfolio Analysis Summary

struct PortfolioAnalysisSummary: Codable {
    let totalHoldings: Int
    let inFormCount: Int
    let onTrackCount: Int
    let offTrackCount: Int
    let outOfFormCount: Int
    let portfolioHealthScore: Double
    let healthTrend: String?
    let topPerformer: String?
    let worstPerformer: String?
    let actionRequiredCount: Int

    enum CodingKeys: String, CodingKey {
        case totalHoldings = "total_holdings"
        case inFormCount = "in_form_count"
        case onTrackCount = "on_track_count"
        case offTrackCount = "off_track_count"
        case outOfFormCount = "out_of_form_count"
        case portfolioHealthScore = "portfolio_health_score"
        case healthTrend = "health_trend"
        case topPerformer = "top_performer"
        case worstPerformer = "worst_performer"
        case actionRequiredCount = "action_required_count"
    }

    var healthColor: Color {
        if portfolioHealthScore >= 75 {
            return FundHealthStatus.inForm.color
        } else if portfolioHealthScore >= 50 {
            return FundHealthStatus.onTrack.color
        } else if portfolioHealthScore >= 25 {
            return FundHealthStatus.offTrack.color
        } else {
            return FundHealthStatus.outOfForm.color
        }
    }

    var healthLabel: String {
        if portfolioHealthScore >= 75 {
            return "Excellent"
        } else if portfolioHealthScore >= 50 {
            return "Good"
        } else if portfolioHealthScore >= 25 {
            return "Needs Attention"
        } else {
            return "Poor"
        }
    }
}

// MARK: - Portfolio Analysis Response

struct PortfolioAnalysisResponse: Codable {
    let clientId: String
    let analysisDate: String
    let summary: PortfolioAnalysisSummary
    let holdings: [HoldingAnalysis]
    let recommendations: [String]
    let dataQuality: String?
    let poweredBy: String?

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case analysisDate = "analysis_date"
        case summary
        case holdings
        case recommendations
        case dataQuality = "data_quality"
        case poweredBy = "powered_by"
    }

    /// Holdings grouped by status for display
    var holdingsByStatus: [FundHealthStatus: [HoldingAnalysis]] {
        Dictionary(grouping: holdings) { $0.status }
    }

    /// Holdings sorted by score (best first)
    var holdingsSortedByScore: [HoldingAnalysis] {
        holdings.sorted { $0.scores.overallScore > $1.scores.overallScore }
    }
}

// MARK: - Analysis Request

struct AnalyzePortfolioRequest: Encodable {
    let clientId: String
    let holdings: [AnalyzeHoldingInput]

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case holdings
    }
}

struct AnalyzeHoldingInput: Encodable {
    let holdingId: String
    let fundSchemeCode: String
    let fundName: String
    let fundCategory: String
    let assetClass: String
    let units: Double
    let avgNav: Double
    let currentNav: Double
    let investedValue: Double
    let currentValue: Double
    let fundReturn1y: Double?
    let fundReturn3y: Double?
    let fundReturn6m: Double?
    let fundReturn3m: Double?
    let categoryAvgReturn1y: Double?
    let fundVolatility: Double?
    let fundSharpeRatio: Double?
    let expenseRatio: Double?

    enum CodingKeys: String, CodingKey {
        case holdingId = "holding_id"
        case fundSchemeCode = "fund_scheme_code"
        case fundName = "fund_name"
        case fundCategory = "fund_category"
        case assetClass = "asset_class"
        case units
        case avgNav = "avg_nav"
        case currentNav = "current_nav"
        case investedValue = "invested_value"
        case currentValue = "current_value"
        case fundReturn1y = "fund_return_1y"
        case fundReturn3y = "fund_return_3y"
        case fundReturn6m = "fund_return_6m"
        case fundReturn3m = "fund_return_3m"
        case categoryAvgReturn1y = "category_avg_return_1y"
        case fundVolatility = "fund_volatility"
        case fundSharpeRatio = "fund_sharpe_ratio"
        case expenseRatio = "expense_ratio"
    }
}

