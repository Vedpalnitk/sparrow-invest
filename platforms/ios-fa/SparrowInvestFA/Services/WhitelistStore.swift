import SwiftUI

@MainActor
class WhitelistStore: ObservableObject {
    @Published var funds: [WhitelistedFund] = []
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var isLoading = false
    @Published var errorMessage: String?

    var filteredFunds: [WhitelistedFund] {
        funds.filter { $0.year == selectedYear }
    }

    var availableYears: [Int] {
        Array(Set(funds.map { $0.year })).sorted(by: >)
    }

    var avgReturns1y: Double? {
        let vals = filteredFunds.compactMap { $0.returns1y }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var avgReturns3y: Double? {
        let vals = filteredFunds.compactMap { $0.returns3y }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var categoryBreakdown: [(String, Int)] {
        var counts: [String: Int] = [:]
        for fund in filteredFunds {
            let cat = fund.schemeCategory ?? "Other"
            counts[cat, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    func isWhitelisted(schemeCode: Int) -> Bool {
        filteredFunds.contains { $0.schemeCode == schemeCode }
    }

    // MARK: - API

    func loadWhitelist() async {
        isLoading = true
        errorMessage = nil

        do {
            funds = try await APIService.shared.get("/advisor/whitelist")
        } catch {
            #if DEBUG
            if funds.isEmpty {
                funds = synthesizeWhitelist()
            }
            #else
            errorMessage = error.localizedDescription
            #endif
        }

        isLoading = false
    }

    func addFund(schemeCode: Int, year: Int, notes: String?) async -> Bool {
        let request = AddToWhitelistRequest(schemeCode: schemeCode, year: year, notes: notes)
        do {
            let fund: WhitelistedFund = try await APIService.shared.post("/advisor/whitelist", body: request)
            funds.insert(fund, at: 0)
            return true
        } catch {
            #if DEBUG
            // Synthesize for demo
            let fund = WhitelistedFund(
                id: UUID().uuidString, schemeCode: schemeCode,
                schemeName: "Fund \(schemeCode)", schemeCategory: nil,
                nav: nil, returns1y: nil, returns3y: nil, returns5y: nil,
                riskRating: nil, fundRating: nil, aum: nil,
                year: year, notes: notes,
                addedAt: ISO8601DateFormatter().string(from: Date())
            )
            funds.insert(fund, at: 0)
            return true
            #else
            errorMessage = error.localizedDescription
            return false
            #endif
        }
    }

    func removeFund(id: String) async -> Bool {
        do {
            try await APIService.shared.delete("/advisor/whitelist/\(id)")
            funds.removeAll { $0.id == id }
            return true
        } catch {
            #if DEBUG
            funds.removeAll { $0.id == id }
            return true
            #else
            errorMessage = error.localizedDescription
            return false
            #endif
        }
    }

    // MARK: - Demo Synthesis

    private func synthesizeWhitelist() -> [WhitelistedFund] {
        let year = Calendar.current.component(.year, from: Date())
        return [
            WhitelistedFund(
                id: "wl-1", schemeCode: 120503,
                schemeName: "ICICI Prudential Bluechip Fund - Direct Growth",
                schemeCategory: "Large Cap", nav: 98.45, returns1y: 18.2,
                returns3y: 14.8, returns5y: 16.1, riskRating: 3, fundRating: 5,
                aum: 45_000, year: year, notes: "Core large cap holding",
                addedAt: "\(year)-01-15T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-2", schemeCode: 122639,
                schemeName: "Axis Midcap Fund - Direct Growth",
                schemeCategory: "Mid Cap", nav: 112.30, returns1y: 24.5,
                returns3y: 18.2, returns5y: 20.3, riskRating: 4, fundRating: 5,
                aum: 28_000, year: year, notes: "Best-in-class mid cap",
                addedAt: "\(year)-01-15T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-3", schemeCode: 119551,
                schemeName: "SBI Small Cap Fund - Direct Growth",
                schemeCategory: "Small Cap", nav: 156.80, returns1y: 28.7,
                returns3y: 22.1, returns5y: 24.6, riskRating: 5, fundRating: 4,
                aum: 18_500, year: year, notes: nil,
                addedAt: "\(year)-01-20T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-4", schemeCode: 125354,
                schemeName: "Mirae Asset ELSS Tax Saver Fund - Direct Growth",
                schemeCategory: "ELSS", nav: 42.15, returns1y: 21.3,
                returns3y: 16.9, returns5y: 18.4, riskRating: 4, fundRating: 5,
                aum: 22_000, year: year, notes: "Tax saving pick",
                addedAt: "\(year)-02-01T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-5", schemeCode: 135781,
                schemeName: "HDFC Balanced Advantage Fund - Direct Growth",
                schemeCategory: "Hybrid", nav: 78.90, returns1y: 15.8,
                returns3y: 13.4, returns5y: 14.7, riskRating: 3, fundRating: 4,
                aum: 62_000, year: year, notes: "Conservative option",
                addedAt: "\(year)-02-05T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-6", schemeCode: 118834,
                schemeName: "Parag Parikh Flexi Cap Fund - Direct Growth",
                schemeCategory: "Flexi Cap", nav: 68.20, returns1y: 22.1,
                returns3y: 17.5, returns5y: 19.8, riskRating: 3, fundRating: 5,
                aum: 48_000, year: year, notes: "International diversification",
                addedAt: "\(year)-01-10T10:00:00Z"
            ),
            // Previous year fund for year filter demo
            WhitelistedFund(
                id: "wl-7", schemeCode: 120503,
                schemeName: "ICICI Prudential Bluechip Fund - Direct Growth",
                schemeCategory: "Large Cap", nav: 85.20, returns1y: 12.5,
                returns3y: 11.2, returns5y: 13.8, riskRating: 3, fundRating: 5,
                aum: 42_000, year: year - 1, notes: nil,
                addedAt: "\(year - 1)-01-10T10:00:00Z"
            ),
            WhitelistedFund(
                id: "wl-8", schemeCode: 122639,
                schemeName: "Axis Midcap Fund - Direct Growth",
                schemeCategory: "Mid Cap", nav: 95.10, returns1y: 19.8,
                returns3y: 15.6, returns5y: 17.9, riskRating: 4, fundRating: 5,
                aum: 24_000, year: year - 1, notes: nil,
                addedAt: "\(year - 1)-01-10T10:00:00Z"
            )
        ]
    }
}
