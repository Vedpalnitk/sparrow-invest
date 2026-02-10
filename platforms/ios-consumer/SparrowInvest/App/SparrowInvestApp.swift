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
    @StateObject private var biometricManager = BiometricManager()
    @StateObject private var appearanceManager = AppearanceManager()
    @StateObject private var navigationStore = NavigationStore()
    @StateObject private var insightsStore = InsightsStore()

    // Observable stores (Swift 5.9+ @Observable)
    @State private var analysisProfileStore = AnalysisProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(biometricManager)
                .environmentObject(portfolioStore)
                .environmentObject(goalsStore)
                .environmentObject(fundsStore)
                .environmentObject(dashboardStore)
                .environmentObject(familyStore)
                .environmentObject(pointsStore)
                .environmentObject(advisorStore)
                .environmentObject(appearanceManager)
                .environmentObject(navigationStore)
                .environmentObject(insightsStore)
                .environment(analysisProfileStore)
                .preferredColorScheme(appearanceManager.preferredColorScheme)
        }
    }
}
