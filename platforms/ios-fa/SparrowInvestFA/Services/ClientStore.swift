import SwiftUI

@MainActor
class ClientStore: ObservableObject {
    @Published var clients: [FAClient] = []
    @Published var selectedClient: FAClientDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var selectedFilter = "All"

    // Portfolio chart data
    @Published var allocation: [AssetAllocationItem] = []
    @Published var portfolioHistory: [PortfolioHistoryPoint] = []
    @Published var selectedPeriod = "1Y"
    @Published var pendingActions: [PendingAction] = []
    @Published var goals: [FAGoal] = []

    let filters = ["All", "Active", "Pending KYC", "High AUM"]
    let periods = ["1M", "6M", "1Y", "3Y", "ALL"]

    var filteredClients: [FAClient] {
        var result = clients

        // Search
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.email.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Filter (backend returns title case: "Active", "Pending", etc.)
        switch selectedFilter {
        case "Active":
            result = result.filter { $0.status?.lowercased() == "active" || $0.status == nil }
        case "Pending KYC":
            result = result.filter { $0.kycStatus?.lowercased() == "pending" }
        case "High AUM":
            result = result.sorted { $0.aum > $1.aum }
        default:
            break
        }

        return result
    }

    func loadClients() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: PaginatedResponse<FAClient> = try await APIService.shared.get("/clients?limit=100")
            clients = response.data
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadClient(_ clientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedClient = try await APIService.shared.get("/clients/\(clientId)")
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createClient(_ request: CreateClientRequest) async -> Bool {
        do {
            let _: FAClient = try await APIService.shared.post("/clients", body: request)
            await loadClients()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func loadAllocation(_ clientId: String) async {
        do {
            let result: [AssetAllocationItem] = try await APIService.shared.get("/portfolio/clients/\(clientId)/allocation")
            allocation = result.isEmpty ? synthesizeAllocation() : result
        } catch {
            allocation = synthesizeAllocation()
        }
    }

    func loadPortfolioHistory(_ clientId: String) async {
        do {
            let result: [PortfolioHistoryPoint] = try await APIService.shared.get("/portfolio/clients/\(clientId)/history?period=\(selectedPeriod)")
            portfolioHistory = result.isEmpty ? synthesizePortfolioHistory() : result
        } catch {
            portfolioHistory = synthesizePortfolioHistory()
        }
    }

    // MARK: - Data Synthesis (fallback when API has no data)

    private func synthesizeAllocation() -> [AssetAllocationItem] {
        guard let client = selectedClient, !client.holdings.isEmpty else { return [] }

        let total = client.holdings.reduce(0) { $0 + $1.currentValue }
        guard total > 0 else { return [] }

        // Use fund-name-based sub-categories for more granular breakdown
        var categoryTotals: [String: Double] = [:]
        for holding in client.holdings {
            let name = holding.fundName.lowercased()
            let cat = holding.fundCategory?.lowercased() ?? holding.category?.lowercased() ?? ""

            let label: String
            if name.contains("large") && name.contains("cap") || cat.contains("large") {
                label = "Large Cap"
            } else if name.contains("mid") && name.contains("cap") || cat.contains("mid") {
                label = "Mid Cap"
            } else if name.contains("small") && name.contains("cap") || cat.contains("small") {
                label = "Small Cap"
            } else if name.contains("flexi") || name.contains("multi") || cat.contains("flexi") {
                label = "Flexi Cap"
            } else if name.contains("value") || name.contains("contra") {
                label = "Value"
            } else if name.contains("debt") || name.contains("bond") || name.contains("liquid") || name.contains("money")
                        || cat.contains("debt") || cat.contains("bond") {
                label = "Debt"
            } else if name.contains("hybrid") || name.contains("balanced") || cat.contains("hybrid") {
                label = "Hybrid"
            } else if name.contains("gold") || name.contains("commodity") || cat.contains("gold") {
                label = "Gold"
            } else if name.contains("international") || name.contains("global") || name.contains("us ") || name.contains("nasdaq") {
                label = "International"
            } else if name.contains("index") || name.contains("nifty") || name.contains("sensex") {
                label = "Index"
            } else if name.contains("elss") || name.contains("tax") {
                label = "ELSS"
            } else {
                label = "Equity"
            }
            categoryTotals[label, default: 0] += holding.currentValue
        }

        let subCatColors: [String: String] = [
            "Large Cap": "2563EB", "Mid Cap": "7C3AED", "Small Cap": "EC4899",
            "Flexi Cap": "06B6D4", "Value": "0EA5E9", "Debt": "64748B",
            "Hybrid": "F59E0B", "Gold": "D97706", "International": "10B981",
            "Index": "3B82F6", "ELSS": "8B5CF6", "Equity": "2563EB"
        ]

        return categoryTotals
            .sorted { $0.value > $1.value }
            .map { cat, value in
                AssetAllocationItem(
                    assetClass: cat,
                    value: value,
                    percentage: (value / total) * 100,
                    color: subCatColors[cat] ?? "64748B"
                )
            }
    }

    private func synthesizePortfolioHistory() -> [PortfolioHistoryPoint] {
        guard let client = selectedClient else { return [] }

        let currentValue = client.holdings.isEmpty ? client.aum : client.holdings.reduce(0) { $0 + $1.currentValue }
        let annualReturn = client.returns / 100
        guard currentValue > 0 else { return [] }

        // Determine number of data points and days based on period
        let (days, points): (Int, Int) = {
            switch selectedPeriod {
            case "1M": return (30, 30)
            case "6M": return (180, 26)
            case "1Y": return (365, 52)
            case "3Y": return (1095, 36)
            case "ALL": return (1825, 60)
            default: return (365, 52)
            }
        }()

        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Work backward from current value using the annual return rate
        let dailyReturn = annualReturn / 365.0
        var history: [PortfolioHistoryPoint] = []

        for i in 0..<points {
            let daysBack = Int(Double(days) * Double(points - 1 - i) / Double(points - 1))
            let date = calendar.date(byAdding: .day, value: -daysBack, to: today)!
            let dateStr = formatter.string(from: date)

            // Value at this point: current * e^(-dailyReturn * daysBack) with some noise
            let growthFactor = exp(-dailyReturn * Double(daysBack))
            let noise = 1.0 + Double.random(in: -0.015...0.015) // ±1.5% noise
            let value = currentValue * growthFactor * noise
            let invested = value * 0.85 // Approximate invested as ~85% of current

            let dayChange = i > 0 ? value - (history.last?.value ?? value) : 0
            history.append(PortfolioHistoryPoint(
                date: dateStr,
                value: value,
                invested: invested,
                dayChange: dayChange,
                dayChangePct: i > 0 ? (dayChange / (history.last?.value ?? value)) * 100 : 0
            ))
        }

        return history
    }

    func loadPendingActions(_ clientId: String) async {
        do {
            let result: [PendingAction] = try await APIService.shared.get("/clients/\(clientId)/pending-actions")
            pendingActions = result
        } catch {
            // Synthesize only for demo — in production, API would return real data
            #if DEBUG
            pendingActions = synthesizePendingActions(clientId)
            #else
            pendingActions = []
            #endif
        }
    }

    private func synthesizePendingActions(_ clientId: String) -> [PendingAction] {
        guard let client = selectedClient else { return [] }

        var actions: [PendingAction] = []

        // KYC pending if client has pending KYC
        if client.kycStatus?.lowercased() == "pending" || client.kycStatus == nil {
            actions.append(PendingAction(
                id: "\(clientId)-kyc",
                clientId: clientId,
                clientName: client.name,
                type: "KYC_PENDING",
                title: "Complete KYC",
                message: "KYC verification is pending for this client",
                priority: .high,
                createdAt: nil
            ))
        }

        // eMandate setup
        actions.append(PendingAction(
            id: "\(clientId)-emandate",
            clientId: clientId,
            clientName: client.name,
            type: "TRADE_PENDING",
            title: "Setup eMandate",
            message: "eMandate required for SIP auto-debit",
            priority: .medium,
            createdAt: nil
        ))

        // Nominee
        actions.append(PendingAction(
            id: "\(clientId)-nominee",
            clientId: clientId,
            clientName: client.name,
            type: "REBALANCE",
            title: "Add Nominee",
            message: "Nominee details are not updated",
            priority: .low,
            createdAt: nil
        ))

        return actions
    }

    func loadGoals(_ clientId: String) async {
        do {
            goals = try await APIService.shared.get("/clients/\(clientId)/goals")
        } catch {
            goals = []
        }
    }
}
