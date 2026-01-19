import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "Home"
        case investments = "Investments"
        case insights = "Insights"
        case explore = "Explore"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .investments: return "chart.pie.fill"
            case .insights: return "brain.head.profile"
            case .explore: return "magnifyingglass"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            InvestmentsView()
                .tabItem {
                    Label(Tab.investments.rawValue, systemImage: Tab.investments.icon)
                }
                .tag(Tab.investments)

            AIAnalysisView()
                .tabItem {
                    Label(Tab.insights.rawValue, systemImage: Tab.insights.icon)
                }
                .tag(Tab.insights)

            ExploreView()
                .tabItem {
                    Label(Tab.explore.rawValue, systemImage: Tab.explore.icon)
                }
                .tag(Tab.explore)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(PortfolioStore())
        .environmentObject(FundsStore())
}
