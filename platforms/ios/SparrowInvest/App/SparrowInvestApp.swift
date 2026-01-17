import SwiftUI

@main
struct SparrowInvestApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var portfolioStore = PortfolioStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var fundsStore = FundsStore()
    @StateObject private var dashboardStore = DashboardStore()
    @StateObject private var familyStore = FamilyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(portfolioStore)
                .environmentObject(goalsStore)
                .environmentObject(fundsStore)
                .environmentObject(dashboardStore)
                .environmentObject(familyStore)
        }
    }
}
