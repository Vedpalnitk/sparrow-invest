import SwiftUI

struct HomeView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @EnvironmentObject var goalsStore: GoalsStore
    @EnvironmentObject var fundsStore: FundsStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dashboardStore: DashboardStore
    @EnvironmentObject var familyStore: FamilyStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    GreetingHeader(name: authManager.user?.firstName ?? "Investor")

                    // Portfolio Hero Card with Individual/Family Toggle
                    PortfolioHeroCard(
                        portfolio: portfolioStore.portfolio,
                        viewMode: $dashboardStore.viewMode,
                        familyPortfolio: familyStore.familyPortfolio
                    )

                    // Quick Actions
                    QuickActionsRow()

                    // Portfolio Health Score
                    PortfolioHealthTile(
                        healthScore: portfolioStore.portfolioHealth,
                        onTapAnalysis: {
                            // Navigate to AI Analysis
                        }
                    )

                    // Asset Allocation Pie Chart
                    AssetAllocationPieChart(
                        allocation: currentPortfolio.assetAllocation
                    )

                    // Portfolio Growth Line Chart
                    PortfolioGrowthLineChart(
                        history: dashboardStore.portfolioHistory,
                        selectedPeriod: $dashboardStore.selectedHistoryPeriod,
                        onPeriodChange: { period in
                            dashboardStore.loadPortfolioHistory(for: period)
                        }
                    )

                    // Family Portfolio (only show in family mode or if has family members)
                    if dashboardStore.viewMode == .family || !familyStore.familyPortfolio.members.isEmpty {
                        FamilyPortfolioCard(
                            familyPortfolio: familyStore.familyPortfolio,
                            onMemberTap: { member in
                                familyStore.selectMember(member)
                            }
                        )
                    }

                    // Top Movers
                    let movers = dashboardStore.topMovers(from: portfolioStore.holdings)
                    TopMoversCard(
                        gainers: movers.gainers,
                        losers: movers.losers
                    )

                    // SIP Dashboard
                    SIPDashboardCard(activeSIPs: portfolioStore.activeSIPs)

                    // Goal Progress
                    GoalProgressTile(
                        goals: goalsStore.goals,
                        onTapGoal: { goal in
                            // Navigate to goal detail
                        }
                    )

                    // Market Overview
                    MarketOverviewCard(marketOverview: dashboardStore.marketOverview)

                    // Upcoming Actions
                    UpcomingActionsCard(
                        actions: dashboardStore.upcomingActions,
                        onComplete: { action in
                            dashboardStore.completeAction(action)
                        },
                        onDismiss: { action in
                            dashboardStore.dismissAction(action)
                        }
                    )

                    // Recent Transactions
                    RecentTransactionsCard(transactions: portfolioStore.transactions)

                    // Tax Summary
                    TaxSummaryCard(taxSummary: dashboardStore.taxSummary)

                    // Dividend Income
                    DividendIncomeCard(dividendSummary: dashboardStore.dividendSummary)
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "bird.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("Sparrow Invest")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Notification Bell with Badge
                        ZStack(alignment: .topTrailing) {
                            Button(action: {}) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            if dashboardStore.highPriorityActionCount > 0 {
                                Text("\(dashboardStore.highPriorityActionCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(AppTheme.error))
                                    .offset(x: 6, y: -6)
                            }
                        }
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .refreshable {
                await refreshAllData()
            }
        }
    }

    // Current portfolio based on view mode
    private var currentPortfolio: Portfolio {
        // For now, return individual portfolio
        // In family mode, this would aggregate family data
        portfolioStore.portfolio
    }

    private func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await portfolioStore.fetchPortfolio()
            }
            group.addTask {
                await goalsStore.fetchGoals()
            }
            group.addTask {
                await fundsStore.fetchRecommendations()
            }
            group.addTask {
                await dashboardStore.refreshAllData()
            }
            group.addTask {
                await familyStore.refreshData()
            }
        }
    }
}

// MARK: - Greeting Header
struct GreetingHeader: View {
    let name: String

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Text(name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
            }
            Spacer()
        }
    }
}

// MARK: - Quick Actions
struct QuickActionsRow: View {
    var body: some View {
        HStack(spacing: 12) {
            HomeQuickActionButton(
                title: "Invest",
                icon: "plus.circle.fill",
                color: AppTheme.primary
            )

            HomeQuickActionButton(
                title: "Withdraw",
                icon: "arrow.down.circle.fill",
                color: AppTheme.secondary
            )

            HomeQuickActionButton(
                title: "SIP",
                icon: "repeat.circle.fill",
                color: AppTheme.success
            )
        }
    }
}

struct HomeQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(PortfolioStore())
        .environmentObject(GoalsStore())
        .environmentObject(FundsStore())
        .environmentObject(DashboardStore())
        .environmentObject(FamilyStore())
}
