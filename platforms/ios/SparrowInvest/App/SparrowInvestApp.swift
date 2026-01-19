import SwiftUI

@main
struct SparrowInvestApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var portfolioStore = PortfolioStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var fundsStore = FundsStore()
    @StateObject private var dashboardStore = DashboardStore()
    @StateObject private var familyStore = FamilyStore()
    @StateObject private var pointsStore = PointsStore()
    @StateObject private var advisorStore = AdvisorStore()
    @StateObject private var appearanceManager = AppearanceManager()

    // Observable stores (Swift 5.9+ @Observable)
    @State private var analysisProfileStore = AnalysisProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(portfolioStore)
                .environmentObject(goalsStore)
                .environmentObject(fundsStore)
                .environmentObject(dashboardStore)
                .environmentObject(familyStore)
                .environmentObject(pointsStore)
                .environmentObject(advisorStore)
                .environmentObject(appearanceManager)
                .environment(analysisProfileStore)
                .preferredColorScheme(appearanceManager.preferredColorScheme)
        }
    }
}
