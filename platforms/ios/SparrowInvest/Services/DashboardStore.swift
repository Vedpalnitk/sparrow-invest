//
//  DashboardStore.swift
//  SparrowInvest
//
//  Central dashboard state management
//

import Foundation
import SwiftUI

// MARK: - Portfolio View Mode

enum PortfolioViewMode: String, CaseIterable {
    case individual = "Individual"
    case family = "Family"
}

// MARK: - Dashboard Store

@MainActor
class DashboardStore: ObservableObject {
    @Published var viewMode: PortfolioViewMode = .individual
    @Published var portfolioHistory: PortfolioHistory = .empty
    @Published var marketOverview: MarketOverview = .empty
    @Published var taxSummary: TaxSummary = .empty
    @Published var dividendSummary: DividendSummary = .empty
    @Published var upcomingActions: [UpcomingAction] = []
    @Published var selectedHistoryPeriod: HistoryPeriod = .oneYear
    @Published var isLoading: Bool = false

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        loadMarketData()
        loadPortfolioHistory()
        loadTaxSummary()
        loadDividendSummary()
        loadUpcomingActions()
    }

    func refreshAllData() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadMockData()
        isLoading = false
    }

    // MARK: - Market Data

    private func loadMarketData() {
        let indices = [
            MarketIndex(
                id: "nifty50",
                name: "NIFTY 50",
                symbol: "NSEI",
                value: 24856.75,
                previousClose: 24712.30,
                change: 144.45,
                changePercentage: 0.58,
                lastUpdated: Date()
            ),
            MarketIndex(
                id: "sensex",
                name: "SENSEX",
                symbol: "BSESN",
                value: 81652.45,
                previousClose: 81234.80,
                change: 417.65,
                changePercentage: 0.51,
                lastUpdated: Date()
            ),
            MarketIndex(
                id: "niftybank",
                name: "NIFTY Bank",
                symbol: "NSEBANK",
                value: 51234.20,
                previousClose: 51456.80,
                change: -222.60,
                changePercentage: -0.43,
                lastUpdated: Date()
            ),
            MarketIndex(
                id: "niftymidcap",
                name: "NIFTY Midcap 100",
                symbol: "NSEMID",
                value: 58432.15,
                previousClose: 57892.40,
                change: 539.75,
                changePercentage: 0.93,
                lastUpdated: Date()
            )
        ]

        // Determine market status based on current time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let weekday = calendar.component(.weekday, from: Date())

        var status: MarketStatus = .closed
        if weekday >= 2 && weekday <= 6 { // Monday to Friday
            if hour == 9 && minute < 15 {
                status = .preOpen
            } else if (hour == 9 && minute >= 15) || (hour > 9 && hour < 15) || (hour == 15 && minute <= 30) {
                status = .open
            } else if hour == 15 && minute > 30 && minute <= 45 {
                status = .postClose
            }
        }

        marketOverview = MarketOverview(
            indices: indices,
            status: status,
            lastUpdated: Date()
        )
    }

    // MARK: - Portfolio History

    func loadPortfolioHistory() {
        loadPortfolioHistory(for: selectedHistoryPeriod)
    }

    func loadPortfolioHistory(for period: HistoryPeriod) {
        selectedHistoryPeriod = period
        var dataPoints: [PortfolioHistoryPoint] = []

        let calendar = Calendar.current
        let today = Date()
        let numberOfPoints = min(period.days, 365)
        let interval = max(1, period.days / numberOfPoints)

        // Starting values
        var currentValue: Double = 1_200_000
        var currentInvested: Double = 1_000_000

        for i in stride(from: period.days, through: 0, by: -interval) {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }

            // Random walk with slight upward bias
            let dailyChange = Double.random(in: -0.02...0.025)
            currentValue *= (1 + dailyChange)

            // Occasional SIP investment
            if i % 30 == 0 {
                currentInvested += 25000
                currentValue += 25000
            }

            let point = PortfolioHistoryPoint(
                date: date,
                value: currentValue,
                invested: currentInvested
            )
            dataPoints.append(point)
        }

        portfolioHistory = PortfolioHistory(dataPoints: dataPoints, period: period)
    }

    // MARK: - Tax Summary

    private func loadTaxSummary() {
        taxSummary = TaxSummary.calculate(
            ltcg: 185000,  // 1.85L LTCG
            stcg: 45000,   // 45K STCG
            elss: 75000    // 75K ELSS invested
        )
    }

    // MARK: - Dividend Summary

    private func loadDividendSummary() {
        let records = [
            DividendRecord(
                fundCode: "HDFC_EQUITY",
                fundName: "HDFC Top 100 Fund",
                amount: 2500,
                unitsHeld: 450.5,
                dividendPerUnit: 5.55,
                recordDate: Date().addingTimeInterval(-30 * 24 * 3600),
                paymentDate: Date().addingTimeInterval(-25 * 24 * 3600),
                status: .paid
            ),
            DividendRecord(
                fundCode: "ICICI_BLUECHIP",
                fundName: "ICICI Pru Bluechip",
                amount: 1800,
                unitsHeld: 320.25,
                dividendPerUnit: 5.62,
                recordDate: Date().addingTimeInterval(-60 * 24 * 3600),
                paymentDate: Date().addingTimeInterval(-55 * 24 * 3600),
                status: .paid
            ),
            DividendRecord(
                fundCode: "SBI_CONTRA",
                fundName: "SBI Contra Fund",
                amount: 3200,
                unitsHeld: 580.0,
                dividendPerUnit: 5.52,
                recordDate: Date().addingTimeInterval(-90 * 24 * 3600),
                paymentDate: Date().addingTimeInterval(-85 * 24 * 3600),
                status: .paid
            ),
            DividendRecord(
                fundCode: "AXIS_MIDCAP",
                fundName: "Axis Midcap Fund",
                amount: 1500,
                unitsHeld: 125.0,
                dividendPerUnit: 12.0,
                recordDate: Date().addingTimeInterval(15 * 24 * 3600),
                paymentDate: Date().addingTimeInterval(20 * 24 * 3600),
                status: .announced
            )
        ]

        let totalReceived = records.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }

        dividendSummary = DividendSummary(
            financialYear: "FY 2025-26",
            totalReceived: totalReceived,
            projectedAnnual: totalReceived * 1.5,
            dividendYield: 1.8,
            records: records,
            nextExpectedDate: Date().addingTimeInterval(15 * 24 * 3600)
        )
    }

    // MARK: - Upcoming Actions

    private func loadUpcomingActions() {
        upcomingActions = [
            UpcomingAction(
                type: .sipDue,
                title: "SIP Due: HDFC Flexi Cap",
                description: "Monthly SIP of Rs 10,000",
                dueDate: Date().addingTimeInterval(3 * 24 * 3600),
                priority: .high,
                amount: 10000,
                fundCode: "HDFC_FLEXICAP"
            ),
            UpcomingAction(
                type: .sipDue,
                title: "SIP Due: Axis Small Cap",
                description: "Monthly SIP of Rs 5,000",
                dueDate: Date().addingTimeInterval(5 * 24 * 3600),
                priority: .high,
                amount: 5000,
                fundCode: "AXIS_SMALLCAP"
            ),
            UpcomingAction(
                type: .rebalance,
                title: "Portfolio Rebalancing Recommended",
                description: "Equity allocation has drifted 8% above target",
                dueDate: Date().addingTimeInterval(7 * 24 * 3600),
                priority: .medium
            ),
            UpcomingAction(
                type: .goalDeadline,
                title: "Goal Review: Emergency Fund",
                description: "You're 85% towards your goal",
                dueDate: Date().addingTimeInterval(14 * 24 * 3600),
                priority: .low,
                goalId: "emergency_fund"
            ),
            UpcomingAction(
                type: .taxHarvest,
                title: "Tax Harvesting Opportunity",
                description: "Book Rs 15,000 LTCG before March 31",
                dueDate: Date().addingTimeInterval(30 * 24 * 3600),
                priority: .medium
            ),
            UpcomingAction(
                type: .kycExpiry,
                title: "KYC Update Required",
                description: "Your KYC will expire in 45 days",
                dueDate: Date().addingTimeInterval(45 * 24 * 3600),
                priority: .low
            )
        ]
    }

    // MARK: - Top Movers

    func topMovers(from holdings: [Holding]) -> (gainers: [Holding], losers: [Holding]) {
        let sorted = holdings.sorted { $0.dayChangePercentage > $1.dayChangePercentage }
        let gainers = Array(sorted.prefix(3).filter { $0.dayChangePercentage > 0 })
        let losers = Array(sorted.suffix(3).filter { $0.dayChangePercentage < 0 }.reversed())
        return (gainers, losers)
    }

    // MARK: - Active Actions

    var activeActions: [UpcomingAction] {
        upcomingActions.filter { !$0.isCompleted && !$0.isDismissed }
            .sortedByPriority
    }

    var highPriorityActionCount: Int {
        upcomingActions.highPriorityCount
    }

    // MARK: - Action Management

    func completeAction(_ action: UpcomingAction) {
        if let index = upcomingActions.firstIndex(where: { $0.id == action.id }) {
            upcomingActions[index].isCompleted = true
        }
    }

    func dismissAction(_ action: UpcomingAction) {
        if let index = upcomingActions.firstIndex(where: { $0.id == action.id }) {
            upcomingActions[index].isDismissed = true
        }
    }
}
