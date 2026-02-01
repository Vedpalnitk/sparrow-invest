//
//  DashboardStore.swift
//  SparrowInvest
//
//  Central dashboard state management with API integration
//

import Foundation
import SwiftUI

// MARK: - API Response Models

/// Market index response from /api/v1/market/indices
struct MarketIndexResponse: Decodable {
    let id: String
    let symbol: String
    let name: String
    let currentValue: Double
    let change: Double
    let changePercent: Double
    let previousClose: Double
    let dayHigh: Double?
    let dayLow: Double?
    let lastUpdated: String

    func toMarketIndex() -> MarketIndex {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: lastUpdated) ?? Date()

        return MarketIndex(
            id: id,
            name: name,
            symbol: symbol,
            value: currentValue,
            previousClose: previousClose,
            change: change,
            changePercentage: changePercent,
            lastUpdated: date
        )
    }
}

/// Market status response from /api/v1/market/status
struct MarketStatusResponse: Decodable {
    let isOpen: Bool
    let status: String
    let currentTime: String
    let nextOpenTime: String?
    let nextCloseTime: String?

    func toMarketStatus() -> MarketStatus {
        switch status.lowercased() {
        case "open": return .open
        case "pre_open", "preopen": return .preOpen
        case "post_close", "postclose": return .postClose
        default: return .closed
        }
    }
}

/// Portfolio history response from /api/v1/auth/me/portfolio/history
struct PortfolioHistoryResponse: Decodable {
    let period: Int
    let data: [PortfolioHistoryDataPoint]
}

struct PortfolioHistoryDataPoint: Decodable {
    let date: String
    let totalValue: Double
    let totalInvested: Double
    let dayChange: Double?
    let dayChangePct: Double?

    func toHistoryPoint() -> PortfolioHistoryPoint {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = dateFormatter.date(from: date) ?? Date()

        return PortfolioHistoryPoint(
            date: parsedDate,
            value: totalValue,
            invested: totalInvested
        )
    }
}

/// Dividend response from /api/v1/auth/me/dividends
struct DividendAPIResponse: Decodable {
    let id: String
    let fundName: String
    let fundSchemeCode: String
    let amount: Double
    let dividendType: String
    let recordDate: String
    let paymentDate: String
    let nav: Double?
    let units: Double?

    func toDividendRecord() -> DividendRecord {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return DividendRecord(
            fundCode: fundSchemeCode,
            fundName: fundName,
            amount: amount,
            unitsHeld: units ?? 0,
            dividendPerUnit: units != nil && units! > 0 ? amount / units! : 0,
            recordDate: dateFormatter.date(from: recordDate) ?? Date(),
            paymentDate: dateFormatter.date(from: paymentDate) ?? Date(),
            status: .paid
        )
    }
}

/// Tax summary response from /api/v1/me/taxes/summary
struct TaxSummaryAPIResponse: Decodable {
    let id: String
    let financialYear: String
    let ltcgRealized: Double
    let stcgRealized: Double
    let ltcgUnrealized: Double
    let stcgUnrealized: Double
    let elssInvested: Double
    let dividendReceived: Double
    let taxHarvestingDone: Double
    let taxEstimate: TaxEstimateResponse
    let capitalGains: [CapitalGainResponse]?

    func toTaxSummary() -> TaxSummary {
        return TaxSummary.calculate(
            ltcg: ltcgRealized,
            stcg: stcgRealized,
            elss: elssInvested
        )
    }
}

struct TaxEstimateResponse: Decodable {
    let ltcgTax: Double
    let stcgTax: Double
    let totalTax: Double
    let ltcgExemption: Double
    let remainingExemption: Double
}

struct CapitalGainResponse: Decodable {
    let id: String
    let fundName: String
    let fundSchemeCode: String
    let gainType: String
    let purchaseDate: String
    let saleDate: String
    let purchaseValue: Double
    let saleValue: Double
    let gain: Double
    let taxableGain: Double
}

/// Actions response from /api/v1/me/actions
struct ActionsAPIResponse: Decodable {
    let actions: [ActionAPIResponse]
    let total: Int
    let unreadCount: Int
    let highPriorityCount: Int
}

struct ActionAPIResponse: Decodable {
    let id: String
    let type: String
    let priority: String
    let title: String
    let description: String?
    let actionUrl: String?
    let referenceId: String?
    let dueDate: String?
    let isRead: Bool
    let isDismissed: Bool
    let isCompleted: Bool
    let createdAt: String
    let expiresAt: String?

    func toUpcomingAction() -> UpcomingAction {
        let actionType: ActionType = {
            switch type.uppercased() {
            case "SIP_DUE": return .sipDue
            case "SIP_FAILED": return .sipDue
            case "REBALANCE_RECOMMENDED": return .rebalance
            case "GOAL_REVIEW": return .goalDeadline
            case "TAX_HARVESTING": return .taxHarvest
            case "KYC_EXPIRY": return .kycExpiry
            case "DIVIDEND_RECEIVED": return .sipDue
            default: return .sipDue
            }
        }()

        let actionPriority: ActionPriority = {
            switch priority.uppercased() {
            case "URGENT", "HIGH": return .high
            case "MEDIUM": return .medium
            case "LOW": return .low
            default: return .medium
            }
        }()

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsedDueDate = dueDate.flatMap { isoFormatter.date(from: $0) } ?? Date()

        var action = UpcomingAction(
            type: actionType,
            title: title,
            description: description ?? "",
            dueDate: parsedDueDate,
            priority: actionPriority,
            amount: nil,
            fundCode: nil,
            goalId: referenceId
        )
        action.isCompleted = isCompleted
        action.isDismissed = isDismissed
        return action
    }
}

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
    @Published var error: Error?

    private let apiService = APIService.shared

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        loadMarketDataMock()
        loadPortfolioHistoryMock()
        loadTaxSummary()
        loadDividendSummaryMock()
        loadUpcomingActions()
    }

    func refreshAllData() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch from API in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMarketIndices() }
            group.addTask { await self.fetchPortfolioHistory() }
            group.addTask { await self.fetchDividends() }
            group.addTask { await self.fetchTaxSummary() }
            group.addTask { await self.fetchActions() }
        }
    }

    // MARK: - API Data Fetching

    func fetchMarketIndices() async {
        do {
            let indices: [MarketIndexResponse] = try await apiService.get("/market/indices", authenticated: false)
            let marketIndices = indices.map { $0.toMarketIndex() }

            // Try to get market status
            var status: MarketStatus = .closed
            do {
                let statusResponse: MarketStatusResponse = try await apiService.get("/market/status", authenticated: false)
                status = statusResponse.toMarketStatus()
            } catch {
                // Calculate status locally based on time
                status = calculateMarketStatus()
            }

            marketOverview = MarketOverview(
                indices: marketIndices,
                status: status,
                lastUpdated: Date()
            )
            self.error = nil
        } catch {
            print("Failed to fetch market indices: \(error). Using mock data.")
            loadMarketDataMock()
        }
    }

    func fetchPortfolioHistory() async {
        do {
            let response: PortfolioHistoryResponse = try await apiService.get("/auth/me/portfolio/history?days=\(selectedHistoryPeriod.days)")
            let dataPoints = response.data.map { $0.toHistoryPoint() }
            portfolioHistory = PortfolioHistory(dataPoints: dataPoints, period: selectedHistoryPeriod)
            self.error = nil
        } catch {
            print("Failed to fetch portfolio history: \(error). Using mock data.")
            loadPortfolioHistoryMock()
        }
    }

    func fetchDividends() async {
        do {
            let response: [DividendAPIResponse] = try await apiService.get("/auth/me/dividends")
            let records = response.map { $0.toDividendRecord() }
            let totalReceived = records.reduce(0) { $0 + $1.amount }

            dividendSummary = DividendSummary(
                financialYear: "FY 2025-26",
                totalReceived: totalReceived,
                projectedAnnual: totalReceived * 1.5,
                dividendYield: 1.8,
                records: records,
                nextExpectedDate: records.first?.paymentDate
            )
            self.error = nil
        } catch {
            print("Failed to fetch dividends: \(error). Using mock data.")
            loadDividendSummaryMock()
        }
    }

    func fetchTaxSummary() async {
        do {
            let response: TaxSummaryAPIResponse = try await apiService.get("/me/taxes/summary")
            taxSummary = response.toTaxSummary()
            self.error = nil
        } catch {
            print("Failed to fetch tax summary: \(error). Using mock data.")
            loadTaxSummary()
        }
    }

    func fetchActions() async {
        do {
            let response: ActionsAPIResponse = try await apiService.get("/me/actions")
            upcomingActions = response.actions.map { $0.toUpcomingAction() }
            self.error = nil
        } catch {
            print("Failed to fetch actions: \(error). Using mock data.")
            loadUpcomingActions()
        }
    }

    private func calculateMarketStatus() -> MarketStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let weekday = calendar.component(.weekday, from: Date())

        if weekday >= 2 && weekday <= 6 { // Monday to Friday
            if hour == 9 && minute < 15 {
                return .preOpen
            } else if (hour == 9 && minute >= 15) || (hour > 9 && hour < 15) || (hour == 15 && minute <= 30) {
                return .open
            } else if hour == 15 && minute > 30 && minute <= 45 {
                return .postClose
            }
        }
        return .closed
    }

    // MARK: - Market Data (Mock)

    private func loadMarketDataMock() {
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

        marketOverview = MarketOverview(
            indices: indices,
            status: calculateMarketStatus(),
            lastUpdated: Date()
        )
    }

    // MARK: - Portfolio History

    func loadPortfolioHistory() {
        loadPortfolioHistory(for: selectedHistoryPeriod)
    }

    func loadPortfolioHistory(for period: HistoryPeriod) {
        selectedHistoryPeriod = period
        // Try to fetch from API
        Task {
            await fetchPortfolioHistory()
        }
    }

    private func loadPortfolioHistoryMock() {
        loadPortfolioHistoryMock(for: selectedHistoryPeriod)
    }

    private func loadPortfolioHistoryMock(for period: HistoryPeriod) {
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

    // MARK: - Dividend Summary (Mock)

    private func loadDividendSummaryMock() {
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
