import SwiftUI

@MainActor
class DashboardStore: ObservableObject {
    @Published var dashboard: FADashboard?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var totalAum: Double { dashboard?.totalAum ?? 0 }
    var avgReturns: Double { dashboard?.avgReturns ?? 0 }
    var activeSipCount: Int { dashboard?.activeSips ?? 0 }
    var monthlySipValue: Double { dashboard?.monthlySipValue ?? 0 }
    var pendingCount: Int { dashboard?.pendingActions ?? 0 }
    var clients: [FAClient] { dashboard?.recentClients ?? [] }
    var pendingTransactions: [FATransaction] { dashboard?.pendingTransactions ?? [] }
    var topPerformers: [FAClient] { dashboard?.topPerformers ?? [] }
    var recentClients: [FAClient] { dashboard?.recentClients ?? [] }
    var upcomingSips: [FASip] { dashboard?.upcomingSips ?? [] }
    var failedSips: [FASip] { dashboard?.failedSips ?? [] }

    // Growth data for KPI detail sheets
    var aumGrowth: KpiGrowth? { dashboard?.aumGrowth }
    var clientsGrowth: KpiGrowth? { dashboard?.clientsGrowth }
    var sipsGrowth: KpiGrowth? { dashboard?.sipsGrowth }

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            dashboard = try await APIService.shared.get("/advisor/dashboard")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Dashboard load error: \(error)")
        }

        isLoading = false
    }
}
