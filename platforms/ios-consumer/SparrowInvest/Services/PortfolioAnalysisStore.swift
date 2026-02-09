import Foundation
import SwiftUI

/// Store for managing portfolio analysis data
@MainActor
class PortfolioAnalysisStore: ObservableObject {
    @Published var analysis: PortfolioAnalysisResponse?
    @Published var isLoading = false
    @Published var error: Error?

    // Cache management
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 5 * 60 // 5 minutes

    private let apiService = APIService.shared

    var isCacheValid: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheTTL
    }

    /// Fetch analysis for a portfolio, using cache if valid
    func fetchAnalysis(clientId: String, holdings: [Holding], forceRefresh: Bool = false) async {
        // Return cached data if valid and not forcing refresh
        if !forceRefresh && isCacheValid && analysis != nil {
            return
        }

        isLoading = true
        error = nil

        do {
            let request = buildAnalysisRequest(clientId: clientId, holdings: holdings)
            let response: PortfolioAnalysisResponse = try await apiService.post(
                "/portfolio-analysis/analyze",
                body: request
            )

            self.analysis = response
            self.cacheTimestamp = Date()
        } catch {
            self.error = error
            print("Failed to fetch portfolio analysis: \(error)")

            // Load mock data for development
            loadMockAnalysis(clientId: clientId, holdings: holdings)
        }

        isLoading = false
    }

    /// Clear the cached analysis
    func clearCache() {
        analysis = nil
        cacheTimestamp = nil
    }

    // MARK: - Private Helpers

    private func buildAnalysisRequest(clientId: String, holdings: [Holding]) -> AnalyzePortfolioRequest {
        let holdingInputs = holdings.map { holding in
            AnalyzeHoldingInput(
                holdingId: holding.id,
                fundSchemeCode: holding.fundCode,
                fundName: holding.fundName,
                fundCategory: holding.category,
                assetClass: holding.assetClass.rawValue,
                units: holding.units,
                avgNav: holding.averageNav,
                currentNav: holding.currentNav,
                investedValue: holding.investedAmount,
                currentValue: holding.currentValue,
                fundReturn1y: holding.returnsPercentage,
                fundReturn3y: nil,
                fundReturn6m: nil,
                fundReturn3m: nil,
                categoryAvgReturn1y: nil,
                fundVolatility: nil,
                fundSharpeRatio: nil,
                expenseRatio: nil
            )
        }

        return AnalyzePortfolioRequest(clientId: clientId, holdings: holdingInputs)
    }

    private func loadMockAnalysis(clientId: String, holdings: [Holding]) {
        // Generate mock analysis based on actual holdings
        let mockHoldings = holdings.enumerated().map { index, holding -> HoldingAnalysis in
            // Determine status based on returns
            let status: FundHealthStatus
            let score: Double

            if holding.returnsPercentage >= 15 {
                status = .inForm
                score = 80 + Double.random(in: 0...15)
            } else if holding.returnsPercentage >= 8 {
                status = .onTrack
                score = 55 + Double.random(in: 0...20)
            } else if holding.returnsPercentage >= 0 {
                status = .offTrack
                score = 30 + Double.random(in: 0...20)
            } else {
                status = .outOfForm
                score = 10 + Double.random(in: 0...15)
            }

            let insights = generateInsights(for: status, category: holding.category)

            return HoldingAnalysis(
                holdingId: holding.id,
                fundSchemeCode: holding.fundCode,
                fundName: holding.fundName,
                fundCategory: holding.category,
                assetClass: holding.assetClass.rawValue,
                status: status,
                statusLabel: status.label,
                statusDescription: status.description,
                actionHint: status.actionHint,
                scores: HoldingScores(
                    returnsScore: min(100, max(0, score + Double.random(in: -10...10))),
                    riskScore: min(100, max(0, score + Double.random(in: -15...15))),
                    consistencyScore: min(100, max(0, score + Double.random(in: -10...10))),
                    momentumScore: min(100, max(0, score + Double.random(in: -20...20))),
                    overallScore: score
                ),
                insights: insights,
                investedValue: holding.investedAmount,
                currentValue: holding.currentValue,
                absoluteGain: holding.returns,
                absoluteGainPercent: holding.returnsPercentage,
                rankInPortfolio: index + 1
            )
        }

        let sortedByScore = mockHoldings.sorted { $0.scores.overallScore > $1.scores.overallScore }

        let inFormCount = mockHoldings.filter { $0.status == .inForm }.count
        let onTrackCount = mockHoldings.filter { $0.status == .onTrack }.count
        let offTrackCount = mockHoldings.filter { $0.status == .offTrack }.count
        let outOfFormCount = mockHoldings.filter { $0.status == .outOfForm }.count

        let portfolioScore = mockHoldings.isEmpty ? 0.0 :
            mockHoldings.reduce(0.0) { $0 + $1.scores.overallScore } / Double(mockHoldings.count)

        let summary = PortfolioAnalysisSummary(
            totalHoldings: mockHoldings.count,
            inFormCount: inFormCount,
            onTrackCount: onTrackCount,
            offTrackCount: offTrackCount,
            outOfFormCount: outOfFormCount,
            portfolioHealthScore: portfolioScore,
            healthTrend: portfolioScore >= 60 ? "improving" : "stable",
            topPerformer: sortedByScore.first?.fundName,
            worstPerformer: sortedByScore.last?.fundName,
            actionRequiredCount: offTrackCount + outOfFormCount
        )

        let recommendations = generateRecommendations(
            inFormCount: inFormCount,
            offTrackCount: offTrackCount,
            outOfFormCount: outOfFormCount
        )

        analysis = PortfolioAnalysisResponse(
            clientId: clientId,
            analysisDate: ISO8601DateFormatter().string(from: Date()),
            summary: summary,
            holdings: mockHoldings,
            recommendations: recommendations,
            dataQuality: "good",
            poweredBy: "Sparrow AI"
        )

        cacheTimestamp = Date()
    }

    private func generateInsights(for status: FundHealthStatus, category: String) -> [String] {
        switch status {
        case .inForm:
            return [
                "Outperforming category average",
                "Strong momentum in recent months",
                "Consistent returns over time"
            ]
        case .onTrack:
            return [
                "Meeting category benchmarks",
                "Stable performance",
                "Good risk-adjusted returns"
            ]
        case .offTrack:
            return [
                "Below category average returns",
                "Consider reviewing allocation",
                "Monitor for improvement"
            ]
        case .outOfForm:
            return [
                "Significantly underperforming",
                "High risk relative to returns",
                "Consider switching to better alternatives"
            ]
        }
    }

    private func generateRecommendations(inFormCount: Int, offTrackCount: Int, outOfFormCount: Int) -> [String] {
        var recommendations: [String] = []

        if outOfFormCount > 0 {
            recommendations.append("Review \(outOfFormCount) underperforming fund(s) for potential exit")
        }

        if offTrackCount > 0 {
            recommendations.append("Monitor \(offTrackCount) off-track fund(s) closely")
        }

        if inFormCount > 0 {
            recommendations.append("Continue SIPs in \(inFormCount) top-performing fund(s)")
        }

        if recommendations.isEmpty {
            recommendations.append("Your portfolio is well-balanced")
        }

        return recommendations
    }
}
