import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var navigationStore: NavigationStore

    var body: some View {
        TabView(selection: $navigationStore.selectedTab) {
            HomeView()
                .tabItem {
                    Label(NavigationStore.Tab.home.rawValue, systemImage: NavigationStore.Tab.home.icon)
                }
                .tag(NavigationStore.Tab.home)

            InvestmentsView()
                .tabItem {
                    Label(NavigationStore.Tab.investments.rawValue, systemImage: NavigationStore.Tab.investments.icon)
                }
                .tag(NavigationStore.Tab.investments)

            AIAnalysisView()
                .tabItem {
                    Label(NavigationStore.Tab.insights.rawValue, systemImage: NavigationStore.Tab.insights.icon)
                }
                .tag(NavigationStore.Tab.insights)

            ExploreView()
                .tabItem {
                    Label(NavigationStore.Tab.explore.rawValue, systemImage: NavigationStore.Tab.explore.icon)
                }
                .tag(NavigationStore.Tab.explore)

            ProfileView()
                .tabItem {
                    Label(NavigationStore.Tab.profile.rawValue, systemImage: NavigationStore.Tab.profile.icon)
                }
                .tag(NavigationStore.Tab.profile)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(NavigationStore())
        .environmentObject(AuthManager())
        .environmentObject(PortfolioStore())
        .environmentObject(FundsStore())
}
