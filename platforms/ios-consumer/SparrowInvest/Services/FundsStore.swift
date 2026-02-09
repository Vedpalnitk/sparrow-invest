import Foundation
import SwiftUI

// MARK: - API Response Models

/// Response model for /api/v1/funds/live/ml/funds endpoint
private struct FundsAPIResponse: Codable {
    let funds: [APIFund]
}

/// Watchlist item response from /api/v1/users/watchlist
struct WatchlistItemResponse: Decodable {
    let schemeCode: Int
    let schemeName: String
    let category: String
    let assetClass: String
    let nav: Double
    let return1y: Double?
    let return3y: Double?
    let return5y: Double?
    let expenseRatio: Double?
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case schemeCode = "scheme_code"
        case schemeName = "scheme_name"
        case category
        case assetClass = "asset_class"
        case nav
        case return1y = "return_1y"
        case return3y = "return_3y"
        case return5y = "return_5y"
        case expenseRatio = "expense_ratio"
        case addedAt = "added_at"
    }

    func toFund() -> Fund {
        Fund(
            id: String(schemeCode),
            schemeCode: schemeCode,
            schemeName: schemeName,
            category: category,
            assetClass: assetClass,
            nav: nav,
            navDate: nil,
            returns: FundReturns(
                oneMonth: nil,
                threeMonth: nil,
                sixMonth: nil,
                oneYear: return1y,
                threeYear: return3y,
                fiveYear: return5y
            ),
            aum: nil,
            expenseRatio: expenseRatio,
            riskRating: nil,
            minSIP: 500,
            minLumpSum: 1000,
            fundManager: nil,
            fundHouse: nil,
            isin: nil,
            crisilRating: nil,
            volatility: nil
        )
    }
}

/// Fund model matching the backend API response (snake_case)
private struct APIFund: Codable {
    let schemeCode: Int
    let schemeName: String
    let fundHouse: String?
    let category: String
    let assetClass: String
    let return1y: Double?
    let return3y: Double?
    let return5y: Double?
    let volatility: Double?
    let sharpeRatio: Double?
    let expenseRatio: Double?
    let nav: Double
    let lastUpdated: String?

    enum CodingKeys: String, CodingKey {
        case schemeCode = "scheme_code"
        case schemeName = "scheme_name"
        case fundHouse = "fund_house"
        case category
        case assetClass = "asset_class"
        case return1y = "return_1y"
        case return3y = "return_3y"
        case return5y = "return_5y"
        case volatility
        case sharpeRatio = "sharpe_ratio"
        case expenseRatio = "expense_ratio"
        case nav
        case lastUpdated = "last_updated"
    }

    /// Convert API fund to app's Fund model
    func toFund() -> Fund {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let navDate = lastUpdated.flatMap { dateFormatter.date(from: $0) }

        // Derive risk rating from volatility (1-5 scale)
        let riskRating: Int? = volatility.map { vol in
            switch vol {
            case ..<5: return 1
            case 5..<10: return 2
            case 10..<15: return 3
            case 15..<20: return 4
            default: return 5
            }
        }

        return Fund(
            id: String(schemeCode),
            schemeCode: schemeCode,
            schemeName: schemeName,
            category: category,
            assetClass: assetClass,
            nav: nav,
            navDate: navDate,
            returns: FundReturns(
                oneMonth: nil,
                threeMonth: nil,
                sixMonth: nil,
                oneYear: return1y,
                threeYear: return3y,
                fiveYear: return5y
            ),
            aum: nil,
            expenseRatio: expenseRatio,
            riskRating: riskRating,
            minSIP: 500,
            minLumpSum: 1000,
            fundManager: nil,
            fundHouse: fundHouse,
            isin: nil,
            crisilRating: nil,
            volatility: volatility
        )
    }
}

@MainActor
class FundsStore: ObservableObject {
    @Published var funds: [Fund] = []
    @Published var recommendations: [FundRecommendation] = []
    @Published var watchlist: [Fund] = []
    @Published var searchResults: [Fund] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService = APIService.shared

    init() {
        // Start with empty, will fetch on appear
        Task {
            await fetchFunds()
            await fetchWatchlist()
        }
    }

    func fetchFunds() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch from backend API
            let response: FundsAPIResponse = try await apiService.get("/funds/live/ml/funds")
            self.funds = response.funds.map { $0.toFund() }
            print("✅ Loaded \(funds.count) funds from API")
        } catch {
            print("❌ Failed to fetch funds: \(error)")
            self.error = error
            // Fallback to mock data if API fails
            loadMockData()
        }
    }

    func fetchRecommendations() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // In real app, fetch from ML service via backend
            try await Task.sleep(nanoseconds: 500_000_000)
            loadMockRecommendations()
        } catch {
            self.error = error
        }
    }

    func searchFunds(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            searchResults = funds.filter {
                $0.schemeName.localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Watchlist Data Fetching

    func fetchWatchlist() async {
        do {
            let response: [WatchlistItemResponse] = try await apiService.get("/users/watchlist")
            self.watchlist = response.map { $0.toFund() }
            print("✅ Loaded \(watchlist.count) watchlist items from API")
        } catch {
            print("Failed to fetch watchlist from API: \(error). Keeping local watchlist.")
            // Keep existing local watchlist on error
        }
    }

    func addToWatchlist(_ fund: Fund) {
        // Add locally first for immediate UI feedback
        if !watchlist.contains(where: { $0.id == fund.id }) {
            watchlist.append(fund)
        }

        // Sync with API in background
        Task {
            do {
                _ = try await apiService.post("/users/watchlist/\(fund.schemeCode)", body: EmptyBody()) as Data
                print("✅ Added fund \(fund.schemeCode) to watchlist on server")
            } catch {
                print("Failed to sync watchlist add to API: \(error)")
                // Keep local state - will sync on next fetch
            }
        }
    }

    func removeFromWatchlist(_ fundId: String) {
        // Get scheme code before removing
        let schemeCode = watchlist.first { $0.id == fundId }?.schemeCode

        // Remove locally first for immediate UI feedback
        watchlist.removeAll { $0.id == fundId }

        // Sync with API in background
        if let code = schemeCode {
            Task {
                do {
                    try await apiService.delete("/users/watchlist/\(code)")
                    print("✅ Removed fund \(code) from watchlist on server")
                } catch {
                    print("Failed to sync watchlist remove to API: \(error)")
                    // Keep local state - will sync on next fetch
                }
            }
        }
    }

    func isInWatchlist(_ fundId: String) -> Bool {
        watchlist.contains { $0.id == fundId }
    }

    /// Sync all local watchlist items to server (useful after initial login)
    func syncWatchlistToServer() async {
        guard !watchlist.isEmpty else { return }

        let schemeCodes = watchlist.map { $0.schemeCode }

        do {
            struct SyncRequest: Encodable {
                let scheme_codes: [Int]
            }
            _ = try await apiService.post("/users/watchlist/sync", body: SyncRequest(scheme_codes: schemeCodes)) as Data
            print("✅ Synced \(schemeCodes.count) watchlist items to server")
        } catch {
            print("Failed to sync watchlist to server: \(error)")
        }
    }

    /// Empty body for POST requests that don't need a body
    private struct EmptyBody: Encodable {}

    private func loadMockData() {
        funds = [
            Fund(
                id: "119598",
                schemeCode: 119598,
                schemeName: "Parag Parikh Flexi Cap Fund Direct Growth",
                category: "Flexi Cap",
                assetClass: "equity",
                nav: 78.45,
                navDate: Date(),
                returns: FundReturns(
                    oneMonth: 2.5,
                    threeMonth: 5.8,
                    sixMonth: 12.3,
                    oneYear: 22.4,
                    threeYear: 18.7,
                    fiveYear: 19.2
                ),
                aum: 48520,
                expenseRatio: 0.63,
                riskRating: 4,
                minSIP: 1000,
                minLumpSum: 1000,
                fundManager: "Rajeev Thakkar",
                fundHouse: "PPFAS"
            ),
            Fund(
                id: "120503",
                schemeCode: 120503,
                schemeName: "HDFC Mid-Cap Opportunities Direct Growth",
                category: "Mid Cap",
                assetClass: "equity",
                nav: 112.35,
                navDate: Date(),
                returns: FundReturns(
                    oneMonth: 3.2,
                    threeMonth: 8.5,
                    sixMonth: 15.2,
                    oneYear: 28.5,
                    threeYear: 22.3,
                    fiveYear: 18.9
                ),
                aum: 45890,
                expenseRatio: 0.85,
                riskRating: 5,
                minSIP: 500,
                minLumpSum: 5000,
                fundManager: "Chirag Setalvad",
                fundHouse: "HDFC"
            ),
            Fund(
                id: "119775",
                schemeCode: 119775,
                schemeName: "ICICI Prudential Corporate Bond Fund Direct Growth",
                category: "Corporate Bond",
                assetClass: "debt",
                nav: 24.10,
                navDate: Date(),
                returns: FundReturns(
                    oneMonth: 0.6,
                    threeMonth: 1.8,
                    sixMonth: 3.5,
                    oneYear: 7.2,
                    threeYear: 6.8,
                    fiveYear: 7.5
                ),
                aum: 22450,
                expenseRatio: 0.36,
                riskRating: 2,
                minSIP: 500,
                minLumpSum: 5000,
                fundManager: "Manish Banthia",
                fundHouse: "ICICI Prudential"
            ),
            Fund(
                id: "135781",
                schemeCode: 135781,
                schemeName: "Mirae Asset Large Cap Fund Direct Growth",
                category: "Large Cap",
                assetClass: "equity",
                nav: 89.25,
                navDate: Date(),
                returns: FundReturns(
                    oneMonth: 1.8,
                    threeMonth: 4.5,
                    sixMonth: 10.2,
                    oneYear: 18.5,
                    threeYear: 15.2,
                    fiveYear: 16.8
                ),
                aum: 38920,
                expenseRatio: 0.53,
                riskRating: 4,
                minSIP: 500,
                minLumpSum: 5000,
                fundManager: "Neelesh Surana",
                fundHouse: "Mirae Asset"
            ),
            Fund(
                id: "140251",
                schemeCode: 140251,
                schemeName: "Axis Bluechip Fund Direct Growth",
                category: "Large Cap",
                assetClass: "equity",
                nav: 52.80,
                navDate: Date(),
                returns: FundReturns(
                    oneMonth: 1.5,
                    threeMonth: 3.8,
                    sixMonth: 8.5,
                    oneYear: 15.2,
                    threeYear: 12.8,
                    fiveYear: 14.5
                ),
                aum: 35670,
                expenseRatio: 0.45,
                riskRating: 3,
                minSIP: 500,
                minLumpSum: 5000,
                fundManager: "Shreyash Devalkar",
                fundHouse: "Axis"
            )
        ]
    }

    private func loadMockRecommendations() {
        recommendations = funds.prefix(3).enumerated().map { index, fund in
            FundRecommendation(
                id: "rec-\(fund.id)",
                fund: fund,
                score: 0.95 - Double(index) * 0.05,
                reasons: [
                    "Excellent risk-adjusted returns (Sharpe: 1.1)",
                    "Consistent outperformance over 5+ years",
                    "Low expense ratio - 37% below category average",
                    "Matches your moderate risk profile"
                ],
                suggestedAllocation: 0.25 - Double(index) * 0.05
            )
        }
    }
}
