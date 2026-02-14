import SwiftUI

@MainActor
class FundsStore: ObservableObject {
    @Published var funds: [FAFund] = []
    @Published var searchQuery = ""
    @Published var selectedCategory = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFund: FAFundDetail?
    @Published var isLoadingDetail = false
    @Published var navHistory: [NavHistoryPoint] = []

    static let categories = ["Equity", "Debt", "Hybrid", "ELSS", "Index", "Gold"]

    var filteredFunds: [FAFund] {
        var result = funds

        if selectedCategory != "All" {
            result = result.filter {
                $0.schemeCategory?.localizedCaseInsensitiveContains(selectedCategory) == true ||
                $0.schemeType?.localizedCaseInsensitiveContains(selectedCategory) == true
            }
        }

        return result
    }

    func searchFunds(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            funds = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            funds = try await APIService.shared.get("/funds/live/search?q=\(encoded)")
        } catch {
            errorMessage = error.localizedDescription
            funds = []
        }

        isLoading = false
    }

    func loadFundsByCategory(_ category: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? category
            funds = try await APIService.shared.get("/funds/live/category/\(encoded)")
        } catch {
            errorMessage = error.localizedDescription
            funds = []
        }

        isLoading = false
    }

    func loadFundDetail(schemeCode: Int) async {
        isLoadingDetail = true
        errorMessage = nil

        do {
            selectedFund = try await APIService.shared.get("/funds/live/\(schemeCode)")
        } catch {
            errorMessage = error.localizedDescription
            selectedFund = nil
        }

        isLoadingDetail = false
    }

    func loadNavHistory(schemeCode: Int) async {
        do {
            navHistory = try await APIService.shared.get("/funds/live/\(schemeCode)/nav-history")
        } catch {
            navHistory = []
        }
    }
}
