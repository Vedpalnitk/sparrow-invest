//
//  AnalysisProfileStore.swift
//  SparrowInvest
//
//  Store for managing investor profiles and portfolios for AI analysis
//

import Foundation
import SwiftUI

@Observable
class AnalysisProfileStore {
    var investorProfile: InvestorProfile?
    var analysisPortfolio: AnalysisPortfolio?
    var isLoading = false
    var lastAnalysisDate: Date?

    // Check if profile is complete for analysis
    var hasCompleteProfile: Bool {
        investorProfile != nil && investorProfile?.name.isEmpty == false
    }

    // Check if portfolio has holdings
    var hasPortfolioData: Bool {
        guard let portfolio = analysisPortfolio else { return false }
        return !portfolio.holdings.isEmpty
    }

    // Check if ready for AI analysis
    var isReadyForAnalysis: Bool {
        hasCompleteProfile || hasPortfolioData
    }

    init() {
        loadSavedData()
    }

    // MARK: - Profile Management

    func createProfile(_ profile: InvestorProfile) {
        self.investorProfile = profile
        saveProfile()
    }

    func updateProfile(_ profile: InvestorProfile) {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        self.investorProfile = updatedProfile
        saveProfile()
    }

    func deleteProfile() {
        investorProfile = nil
        UserDefaults.standard.removeObject(forKey: "investorProfile")
    }

    // MARK: - Portfolio Management

    func createPortfolio(name: String) {
        var portfolio = AnalysisPortfolio.empty
        portfolio.name = name
        self.analysisPortfolio = portfolio
        savePortfolio()
    }

    func addHolding(_ holding: AnalysisHolding) {
        guard var portfolio = analysisPortfolio else {
            createPortfolio(name: "My Portfolio")
            analysisPortfolio?.holdings.append(holding)
            savePortfolio()
            return
        }
        portfolio.holdings.append(holding)
        portfolio.updatedAt = Date()
        self.analysisPortfolio = portfolio
        savePortfolio()
    }

    func updateHolding(_ holding: AnalysisHolding) {
        guard var portfolio = analysisPortfolio,
              let index = portfolio.holdings.firstIndex(where: { $0.id == holding.id }) else { return }
        portfolio.holdings[index] = holding
        portfolio.updatedAt = Date()
        self.analysisPortfolio = portfolio
        savePortfolio()
    }

    func removeHolding(id: String) {
        guard var portfolio = analysisPortfolio else { return }
        portfolio.holdings.removeAll { $0.id == id }
        portfolio.updatedAt = Date()
        self.analysisPortfolio = portfolio
        savePortfolio()
    }

    func clearPortfolio() {
        analysisPortfolio = nil
        UserDefaults.standard.removeObject(forKey: "analysisPortfolio")
    }

    // MARK: - Import from Existing Portfolio

    func importFromPortfolio(_ holdings: [Holding]) {
        let analysisHoldings = holdings.map { holding in
            AnalysisHolding(
                fundName: holding.fundName,
                fundCode: holding.fundCode,
                category: holding.category,
                assetClass: holding.assetClass,
                investedAmount: holding.investedAmount,
                currentValue: holding.currentValue,
                units: holding.units
            )
        }

        if var portfolio = analysisPortfolio {
            portfolio.holdings = analysisHoldings
            portfolio.updatedAt = Date()
            self.analysisPortfolio = portfolio
        } else {
            var portfolio = AnalysisPortfolio.empty
            portfolio.holdings = analysisHoldings
            self.analysisPortfolio = portfolio
        }
        savePortfolio()
    }

    // MARK: - Analysis

    func runAnalysis() async {
        isLoading = true
        // Simulate API call to AI service
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        lastAnalysisDate = Date()
        isLoading = false
    }

    // MARK: - Persistence

    private func saveProfile() {
        guard let profile = investorProfile else { return }
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "investorProfile")
        }
    }

    private func savePortfolio() {
        guard let portfolio = analysisPortfolio else { return }
        if let encoded = try? JSONEncoder().encode(portfolio) {
            UserDefaults.standard.set(encoded, forKey: "analysisPortfolio")
        }
    }

    private func loadSavedData() {
        // Load investor profile
        if let profileData = UserDefaults.standard.data(forKey: "investorProfile"),
           let profile = try? JSONDecoder().decode(InvestorProfile.self, from: profileData) {
            self.investorProfile = profile
        }

        // Load analysis portfolio
        if let portfolioData = UserDefaults.standard.data(forKey: "analysisPortfolio"),
           let portfolio = try? JSONDecoder().decode(AnalysisPortfolio.self, from: portfolioData) {
            self.analysisPortfolio = portfolio
        }
    }

    // MARK: - Computed Analysis Results

    var portfolioHealthScore: Int {
        guard let portfolio = analysisPortfolio, !portfolio.holdings.isEmpty else { return 0 }

        var score = 50 // Base score

        // Diversification bonus (more holdings = better)
        let holdingsCount = portfolio.holdings.count
        if holdingsCount >= 5 { score += 15 }
        else if holdingsCount >= 3 { score += 10 }
        else if holdingsCount >= 2 { score += 5 }

        // Asset class diversification
        let assetClasses = Set(portfolio.holdings.map { $0.assetClass })
        if assetClasses.count >= 3 { score += 15 }
        else if assetClasses.count >= 2 { score += 10 }

        // Returns bonus
        if portfolio.returnsPercentage > 15 { score += 15 }
        else if portfolio.returnsPercentage > 10 { score += 10 }
        else if portfolio.returnsPercentage > 5 { score += 5 }
        else if portfolio.returnsPercentage < 0 { score -= 10 }

        return min(100, max(0, score))
    }

    var assetAllocationBreakdown: [String: Double] {
        guard let portfolio = analysisPortfolio, portfolio.totalCurrentValue > 0 else {
            return [:]
        }

        var breakdown: [String: Double] = [:]
        for holding in portfolio.holdings {
            let assetClass = holding.assetClass.rawValue.capitalized
            breakdown[assetClass, default: 0] += holding.currentValue
        }

        // Convert to percentages
        let total = portfolio.totalCurrentValue
        return breakdown.mapValues { ($0 / total) * 100 }
    }
}
