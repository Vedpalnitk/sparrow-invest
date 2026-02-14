import SwiftUI

@MainActor
class SipStore: ObservableObject {
    @Published var sips: [FASip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter = "All"
    @Published var actionMessage: String?
    @Published var isActionSuccess = false
    @Published var processingId: String?

    let filters = ["All", "Active", "Paused", "Cancelled"]

    // MARK: - Computed Properties

    var filteredSips: [FASip] {
        switch selectedFilter {
        case "Active":
            return sips.filter { $0.status == "ACTIVE" }
        case "Paused":
            return sips.filter { $0.status == "PAUSED" }
        case "Cancelled":
            return sips.filter { $0.status == "CANCELLED" }
        default:
            return sips
        }
    }

    var totalCount: Int { sips.count }
    var activeCount: Int { sips.filter { $0.status == "ACTIVE" }.count }
    var pausedCount: Int { sips.filter { $0.status == "PAUSED" }.count }
    var cancelledCount: Int { sips.filter { $0.status == "CANCELLED" }.count }

    var totalMonthlyValue: Double {
        sips.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }

    func filterCount(for filter: String) -> Int {
        switch filter {
        case "Active": return activeCount
        case "Paused": return pausedCount
        case "Cancelled": return cancelledCount
        default: return totalCount
        }
    }

    // MARK: - API Methods

    func loadSips() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: PaginatedResponse<FASip> = try await APIService.shared.get("/sips?limit=100")
            sips = response.data
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func pauseSip(id: String) async {
        guard processingId == nil else { return }
        processingId = id

        do {
            let _: FASip = try await APIService.shared.post("/sips/\(id)/pause", body: EmptyBody())
            actionMessage = "SIP paused successfully"
            isActionSuccess = true
            await loadSips()
        } catch {
            actionMessage = "Failed to pause SIP: \(error.localizedDescription)"
            isActionSuccess = false
        }

        processingId = nil
    }

    func resumeSip(id: String) async {
        guard processingId == nil else { return }
        processingId = id

        do {
            let _: FASip = try await APIService.shared.post("/sips/\(id)/resume", body: EmptyBody())
            actionMessage = "SIP resumed successfully"
            isActionSuccess = true
            await loadSips()
        } catch {
            actionMessage = "Failed to resume SIP: \(error.localizedDescription)"
            isActionSuccess = false
        }

        processingId = nil
    }

    func cancelSip(id: String) async {
        guard processingId == nil else { return }
        processingId = id

        do {
            let _: FASip = try await APIService.shared.post("/sips/\(id)/cancel", body: EmptyBody())
            actionMessage = "SIP cancelled"
            isActionSuccess = true
            await loadSips()
        } catch {
            actionMessage = "Failed to cancel SIP: \(error.localizedDescription)"
            isActionSuccess = false
        }

        processingId = nil
    }

    func createSip(request: CreateSipRequest) async -> Bool {
        do {
            let _: FASip = try await APIService.shared.post("/sips", body: request)
            await loadSips()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearActionMessage() {
        actionMessage = nil
    }

    // MARK: - Fund Search (for Create SIP)

    @Published var searchQuery = ""
    @Published var searchResults: [FAFund] = []
    @Published var isSearching = false

    func searchFunds(query: String) async {
        guard query.count >= 3 else {
            searchResults = []
            return
        }

        isSearching = true
        do {
            searchResults = try await APIService.shared.get("/funds/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)")
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    // MARK: - Client Loading (for Create SIP)

    @Published var clients: [FAClient] = []

    func loadClients() async {
        do {
            let response: PaginatedResponse<FAClient> = try await APIService.shared.get("/clients?limit=100")
            clients = response.data
        } catch {
            // Silently fail - clients list is supplementary
        }
    }
}

// MARK: - Empty Body for POST without payload

private struct EmptyBody: Encodable {}
