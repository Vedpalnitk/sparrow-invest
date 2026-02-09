import Foundation
import SwiftUI

// MARK: - API Response Models

/// Portfolio summary response from /api/v1/users/portfolio
struct PortfolioSummaryResponse: Decodable {
    let totalValue: Double
    let totalInvested: Double
    let totalReturns: Double
    let returnsPercentage: Double
    let todayChange: Double
    let todayChangePercentage: Double
    let xirr: Double?
    let assetAllocation: [String: Double]
    let holdingsCount: Int

    enum CodingKeys: String, CodingKey {
        case totalValue = "total_value"
        case totalInvested = "total_invested"
        case totalReturns = "total_returns"
        case returnsPercentage = "returns_percentage"
        case todayChange = "today_change"
        case todayChangePercentage = "today_change_percentage"
        case xirr
        case assetAllocation = "asset_allocation"
        case holdingsCount = "holdings_count"
    }

    func toPortfolio(holdings: [Holding]) -> Portfolio {
        let allocation = AssetAllocation(
            equity: assetAllocation["equity"] ?? 0,
            debt: assetAllocation["debt"] ?? 0,
            hybrid: assetAllocation["hybrid"] ?? 0,
            gold: assetAllocation["gold"] ?? 0
        )
        return Portfolio(
            totalValue: totalValue,
            totalInvested: totalInvested,
            totalReturns: totalReturns,
            returnsPercentage: returnsPercentage,
            todayChange: todayChange,
            todayChangePercentage: todayChangePercentage,
            xirr: xirr,
            assetAllocation: allocation,
            holdings: holdings
        )
    }
}

/// Holding response from /api/v1/users/holdings
struct HoldingResponse: Decodable {
    let id: String
    let fundCode: String
    let fundName: String
    let category: String?
    let assetClass: String?
    let units: Double
    let averageNav: Double
    let currentNav: Double?
    let investedAmount: Double
    let currentValue: Double?
    let returns: Double?
    let returnsPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case fundCode = "fund_code"
        case fundName = "fund_name"
        case category
        case assetClass = "asset_class"
        case units
        case averageNav = "average_nav"
        case currentNav = "current_nav"
        case investedAmount = "invested_amount"
        case currentValue = "current_value"
        case returns
        case returnsPercentage = "returns_percentage"
    }

    func toHolding() -> Holding {
        let assetClassEnum: Holding.AssetClass = {
            switch assetClass?.lowercased() {
            case "equity": return .equity
            case "debt": return .debt
            case "hybrid": return .hybrid
            case "gold": return .gold
            default: return .other
            }
        }()

        return Holding(
            id: id,
            fundCode: fundCode,
            fundName: fundName,
            category: category ?? "Other",
            assetClass: assetClassEnum,
            units: units,
            averageNav: averageNav,
            currentNav: currentNav ?? averageNav,
            investedAmount: investedAmount,
            currentValue: currentValue ?? investedAmount,
            returns: returns ?? 0,
            returnsPercentage: returnsPercentage ?? 0
        )
    }
}

/// SIP response from /api/v1/users/sips
struct SIPResponse: Decodable {
    let id: String
    let fundCode: String
    let fundName: String
    let amount: Double
    let frequency: String
    let nextDate: String?
    let status: String
    let totalInvested: Double
    let sipCount: Int
    let goalId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fundCode = "fund_code"
        case fundName = "fund_name"
        case amount
        case frequency
        case nextDate = "next_date"
        case status
        case totalInvested = "total_invested"
        case sipCount = "sip_count"
        case goalId = "goal_id"
    }

    func toSIP() -> SIP {
        let frequencyEnum: SIP.SIPFrequency = {
            switch frequency.lowercased() {
            case "weekly": return .weekly
            case "quarterly": return .quarterly
            default: return .monthly
            }
        }()

        let statusEnum: SIP.SIPStatus = {
            switch status.lowercased() {
            case "paused": return .paused
            case "completed": return .completed
            case "cancelled": return .cancelled
            default: return .active
            }
        }()

        let nextDateValue: Date = {
            guard let dateStr = nextDate else { return Date() }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return formatter.date(from: dateStr) ?? Date()
        }()

        return SIP(
            id: id,
            fundCode: fundCode,
            fundName: fundName,
            amount: amount,
            frequency: frequencyEnum,
            nextDate: nextDateValue,
            status: statusEnum,
            totalInvested: totalInvested,
            sipCount: sipCount
        )
    }
}

/// Request to create a new holding
struct CreateHoldingRequest: Encodable {
    let fundCode: String
    let fundName: String
    let category: String?
    let assetClass: String?
    let units: Double
    let averageNav: Double
    let currentNav: Double?
    let investedAmount: Double
    let folioNumber: String?

    enum CodingKeys: String, CodingKey {
        case fundCode = "fund_code"
        case fundName = "fund_name"
        case category
        case assetClass = "asset_class"
        case units
        case averageNav = "average_nav"
        case currentNav = "current_nav"
        case investedAmount = "invested_amount"
        case folioNumber = "folio_number"
    }
}

/// Request to create a new SIP
struct CreateSIPRequest: Encodable {
    let fundCode: String
    let fundName: String
    let amount: Double
    let frequency: String
    let sipDate: Int?
    let startDate: String
    let goalId: String?

    enum CodingKeys: String, CodingKey {
        case fundCode = "fund_code"
        case fundName = "fund_name"
        case amount
        case frequency
        case sipDate = "sip_date"
        case startDate = "start_date"
        case goalId = "goal_id"
    }
}

// MARK: - Portfolio Store

@MainActor
class PortfolioStore: ObservableObject {
    @Published var portfolio: Portfolio = .empty
    @Published var holdings: [Holding] = []
    @Published var activeSIPs: [SIP] = []
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: Error?

    // Portfolio health score (0-100)
    var portfolioHealth: Int {
        calculatePortfolioHealth()
    }

    private func calculatePortfolioHealth() -> Int {
        var score = 70 // Base score

        // Diversification bonus (if holdings > 3)
        if holdings.count >= 3 {
            score += 10
        }

        // Positive returns bonus
        if portfolio.totalReturns > 0 {
            score += 10
        }

        // Active SIPs bonus
        if activeSIPs.count >= 2 {
            score += 5
        }

        // Asset allocation check (equity between 40-80%)
        let equityPercentage = portfolio.assetAllocation.equityPercentage
        if equityPercentage >= 40 && equityPercentage <= 80 {
            score += 5
        }

        return min(100, max(0, score))
    }

    private let apiService = APIService.shared

    init() {
        // Load mock data for development
        loadMockData()
    }

    func fetchPortfolio() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch holdings and portfolio summary in parallel
            async let holdingsTask: [HoldingResponse] = apiService.get("/users/holdings")
            async let summaryTask: PortfolioSummaryResponse = apiService.get("/users/portfolio")
            async let sipsTask: [SIPResponse] = apiService.get("/users/sips")

            let (holdingsResponse, summaryResponse, sipsResponse) = try await (holdingsTask, summaryTask, sipsTask)

            // Convert API responses to domain models
            self.holdings = holdingsResponse.map { $0.toHolding() }
            self.portfolio = summaryResponse.toPortfolio(holdings: self.holdings)
            self.activeSIPs = sipsResponse.map { $0.toSIP() }

        } catch {
            self.error = error
            // Fallback to mock data for development
            print("Failed to fetch portfolio from API: \(error). Using mock data.")
            loadMockData()
        }
    }

    func fetchTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            // Mock transactions loaded in loadMockData
        } catch {
            self.error = error
        }
    }

    /// Add a new holding via API
    func addHolding(_ holding: Holding) async throws {
        let request = CreateHoldingRequest(
            fundCode: holding.fundCode,
            fundName: holding.fundName,
            category: holding.category,
            assetClass: holding.assetClass.rawValue,
            units: holding.units,
            averageNav: holding.averageNav,
            currentNav: holding.currentNav,
            investedAmount: holding.investedAmount,
            folioNumber: nil
        )

        let _: HoldingResponse = try await apiService.post("/users/holdings", body: request)

        // Refresh portfolio data after adding
        await fetchPortfolio()
    }

    /// Add holding locally (for offline/mock mode)
    func addHoldingLocally(_ holding: Holding) {
        holdings.append(holding)

        // Update portfolio totals
        portfolio = Portfolio(
            totalValue: portfolio.totalValue + holding.currentValue,
            totalInvested: portfolio.totalInvested + holding.investedAmount,
            totalReturns: portfolio.totalReturns + holding.returns,
            returnsPercentage: ((portfolio.totalInvested + holding.investedAmount) > 0)
                ? ((portfolio.totalReturns + holding.returns) / (portfolio.totalInvested + holding.investedAmount)) * 100
                : 0,
            todayChange: portfolio.todayChange,
            todayChangePercentage: portfolio.todayChangePercentage,
            xirr: portfolio.xirr,
            assetAllocation: recalculateAssetAllocation(),
            holdings: holdings
        )
    }

    /// Create a new SIP via API
    func createSIP(fundCode: String, fundName: String, amount: Double, frequency: SIP.SIPFrequency = .monthly, goalId: String? = nil) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = dateFormatter.string(from: Date())

        let request = CreateSIPRequest(
            fundCode: fundCode,
            fundName: fundName,
            amount: amount,
            frequency: frequency.rawValue,
            sipDate: Calendar.current.component(.day, from: Date()),
            startDate: startDate,
            goalId: goalId
        )

        let _: SIPResponse = try await apiService.post("/users/sips", body: request)

        // Refresh portfolio data after creating SIP
        await fetchPortfolio()
    }

    /// Pause a SIP
    func pauseSIP(_ sipId: String) async throws {
        let _: [String: String] = try await apiService.put("/users/sips/\(sipId)/pause", body: EmptyBody())
        await fetchPortfolio()
    }

    /// Resume a paused SIP
    func resumeSIP(_ sipId: String) async throws {
        let _: [String: String] = try await apiService.put("/users/sips/\(sipId)/resume", body: EmptyBody())
        await fetchPortfolio()
    }

    /// Cancel/Delete a SIP
    func cancelSIP(_ sipId: String) async throws {
        try await apiService.delete("/users/sips/\(sipId)")
        await fetchPortfolio()
    }

    /// Delete a holding
    func deleteHolding(_ holdingId: String) async throws {
        try await apiService.delete("/users/holdings/\(holdingId)")
        await fetchPortfolio()
    }

    private func recalculateAssetAllocation() -> AssetAllocation {
        let totalValue = holdings.reduce(0) { $0 + $1.currentValue }
        guard totalValue > 0 else {
            return AssetAllocation(equity: 0, debt: 0, hybrid: 0, gold: 0)
        }

        var equity: Double = 0
        var debt: Double = 0
        var hybrid: Double = 0
        var gold: Double = 0

        for holding in holdings {
            let percentage = (holding.currentValue / totalValue) * 100
            switch holding.assetClass {
            case .equity: equity += percentage
            case .debt: debt += percentage
            case .hybrid: hybrid += percentage
            case .gold: gold += percentage
            case .other: break // Ignore other asset classes
            }
        }

        return AssetAllocation(
            equity: equity.rounded(),
            debt: debt.rounded(),
            hybrid: hybrid.rounded(),
            gold: gold.rounded()
        )
    }

    private func loadMockData() {
        // Mock Portfolio
        portfolio = Portfolio(
            totalValue: 245680,
            totalInvested: 233230,
            totalReturns: 12450,
            returnsPercentage: 5.34,
            todayChange: 890,
            todayChangePercentage: 0.36,
            xirr: 14.2,
            assetAllocation: AssetAllocation(equity: 72, debt: 18, hybrid: 7, gold: 3),
            holdings: []
        )

        // Mock Holdings
        holdings = [
            Holding(
                id: "1",
                fundCode: "119598",
                fundName: "Parag Parikh Flexi Cap Fund",
                category: "Flexi Cap",
                assetClass: .equity,
                units: 1250.45,
                averageNav: 65.50,
                currentNav: 78.45,
                investedAmount: 81904,
                currentValue: 98110,
                returns: 16206,
                returnsPercentage: 19.78
            ),
            Holding(
                id: "2",
                fundCode: "120503",
                fundName: "HDFC Mid-Cap Opportunities",
                category: "Mid Cap",
                assetClass: .equity,
                units: 850.25,
                averageNav: 95.20,
                currentNav: 112.35,
                investedAmount: 80944,
                currentValue: 95526,
                returns: 14582,
                returnsPercentage: 18.01
            ),
            Holding(
                id: "3",
                fundCode: "119775",
                fundName: "ICICI Pru Corporate Bond",
                category: "Corporate Bond",
                assetClass: .debt,
                units: 2500.00,
                averageNav: 22.50,
                currentNav: 24.10,
                investedAmount: 56250,
                currentValue: 60250,
                returns: 4000,
                returnsPercentage: 7.11
            )
        ]

        portfolio.holdings = holdings

        // Mock SIPs
        activeSIPs = [
            SIP(
                id: "1",
                fundCode: "119598",
                fundName: "Parag Parikh Flexi Cap Fund",
                amount: 10000,
                frequency: .monthly,
                nextDate: Date().addingTimeInterval(86400 * 5),
                status: .active,
                totalInvested: 120000,
                sipCount: 12
            ),
            SIP(
                id: "2",
                fundCode: "120503",
                fundName: "HDFC Mid-Cap Opportunities",
                amount: 5000,
                frequency: .monthly,
                nextDate: Date().addingTimeInterval(86400 * 10),
                status: .active,
                totalInvested: 60000,
                sipCount: 12
            ),
            SIP(
                id: "3",
                fundCode: "119775",
                fundName: "ICICI Pru Corporate Bond",
                amount: 5000,
                frequency: .monthly,
                nextDate: Date().addingTimeInterval(86400 * 15),
                status: .active,
                totalInvested: 56250,
                sipCount: 11
            )
        ]

        // Mock Transactions
        transactions = [
            Transaction(
                id: "1",
                fundCode: "119598",
                fundName: "Parag Parikh Flexi Cap Fund",
                type: .sipInstallment,
                amount: 10000,
                units: 127.55,
                nav: 78.40,
                date: Date().addingTimeInterval(-86400 * 2),
                status: .completed
            ),
            Transaction(
                id: "2",
                fundCode: "120503",
                fundName: "HDFC Mid-Cap Opportunities",
                type: .sipInstallment,
                amount: 5000,
                units: 44.52,
                nav: 112.30,
                date: Date().addingTimeInterval(-86400 * 5),
                status: .completed
            ),
            Transaction(
                id: "3",
                fundCode: "119775",
                fundName: "ICICI Pru Corporate Bond",
                type: .purchase,
                amount: 25000,
                units: 1037.34,
                nav: 24.10,
                date: Date().addingTimeInterval(-86400 * 15),
                status: .completed
            ),
            Transaction(
                id: "4",
                fundCode: "119598",
                fundName: "Parag Parikh Flexi Cap Fund",
                type: .dividend,
                amount: 850,
                units: 0,
                nav: 0,
                date: Date().addingTimeInterval(-86400 * 30),
                status: .completed
            )
        ]
    }
}
