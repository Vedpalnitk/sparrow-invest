import SwiftUI

struct HomeView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @EnvironmentObject var goalsStore: GoalsStore
    @EnvironmentObject var fundsStore: FundsStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dashboardStore: DashboardStore
    @EnvironmentObject var familyStore: FamilyStore
    @Environment(AnalysisProfileStore.self) private var analysisStore

    // Sheet states for AI Analysis
    @State private var showProfileSetup = false
    @State private var showPortfolioInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
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

                    // AI Analysis Quick Access
                    AIAnalysisQuickAccessCard(
                        onCreateProfile: { showProfileSetup = true },
                        onCreatePortfolio: { showPortfolioInput = true }
                    )

                    // Asset Allocation Pie Chart with Portfolio Filter
                    AssetAllocationPieChart(
                        allocation: currentPortfolio.assetAllocation,
                        familyAllocation: familyStore.familyAssetAllocation,
                        familyMembers: familyStore.familyPortfolio.members,
                        memberAllocations: familyStore.memberAssetAllocations
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

                    // SIP Dashboard
                    SIPDashboardCard(activeSIPs: portfolioStore.activeSIPs)

                    // Goal Progress
                    GoalProgressTile(
                        goals: goalsStore.goals,
                        onTapGoal: { goal in
                            // Navigate to goal detail
                        }
                    )

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
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xxLarge)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "bird.fill")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        Text("Sparrow")
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Notification Bell with Badge
                        Button(action: {}) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                if dashboardStore.highPriorityActionCount > 0 {
                                    Text("\(dashboardStore.highPriorityActionCount)")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .refreshable {
                await refreshAllData()
            }
            .sheet(isPresented: $showProfileSetup) {
                InvestorProfileSetupView()
            }
            .sheet(isPresented: $showPortfolioInput) {
                PortfolioInputView()
            }
        }
    }

    // Current portfolio based on view mode
    private var currentPortfolio: Portfolio {
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
                    .foregroundColor(.secondary)
                Text(name)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Quick Actions

struct QuickActionsRow: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            HomeQuickActionButton(
                title: "Invest",
                icon: "plus.circle.fill",
                color: .blue
            )

            HomeQuickActionButton(
                title: "Withdraw",
                icon: "arrow.down.circle.fill",
                color: .cyan
            )

            HomeQuickActionButton(
                title: "SIP",
                icon: "repeat.circle.fill",
                color: .green
            )
        }
    }
}

struct HomeQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .overlay(buttonBorder)
            .shadow(color: buttonShadow, radius: 8, x: 0, y: 2)
        }
    }

    private var buttonShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.06)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
        }
    }

    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.15), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.05), location: 0.7),
                            .init(color: .black.opacity(0.12), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - AI Analysis Quick Access Card

struct AIAnalysisQuickAccessCard: View {
    let onCreateProfile: () -> Void
    let onCreatePortfolio: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple)
                }

                Text("AI Portfolio Analysis")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text("Set up your investor profile and portfolio to get personalized AI-powered insights and recommendations.")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Action Buttons
            HStack(spacing: AppTheme.Spacing.compact) {
                AIAnalysisActionButton(
                    title: "Create Profile",
                    icon: "person.crop.circle.badge.plus",
                    color: .blue,
                    action: onCreateProfile
                )

                AIAnalysisActionButton(
                    title: "Create Portfolio",
                    icon: "chart.pie.fill",
                    color: .green,
                    action: onCreatePortfolio
                )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

struct AIAnalysisActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(buttonBackground)
            .overlay(buttonBorder)
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(color.opacity(0.15))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(color.opacity(0.08))
        }
    }

    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? color.opacity(0.3)
                    : color.opacity(0.2),
                lineWidth: 1
            )
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
        .environment(AnalysisProfileStore())
}
