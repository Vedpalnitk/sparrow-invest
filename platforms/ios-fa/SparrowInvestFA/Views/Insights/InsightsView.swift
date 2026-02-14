import SwiftUI

struct InsightsView: View {
    @StateObject private var store = InsightsStore()
    @Environment(\.colorScheme) private var colorScheme
    @State private var avyaQuery = ""
    @State private var showAvyaChat = false
    @State private var avyaInitialQuery: String?
    @State private var selectedInsightTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Avya Hub Header
                    avyaHubHeader

                    // Quick Action Chips
                    avyaQuickChips

                    // Proactive Recommendations
                    ProactiveRecommendationsCard(
                        insights: store.insights,
                        onAskAvya: { query in
                            avyaInitialQuery = query
                            showAvyaChat = true
                        },
                        onViewClient: { _ in }
                    )

                    // Insight Tabs
                    InsightTabBar(
                        selectedTab: $selectedInsightTab,
                        healthCount: store.insights.portfolioHealth.count,
                        rebalancingCount: store.insights.rebalancingAlerts.count,
                        goalCount: store.insights.goalAlerts.count,
                        taxCount: store.insights.taxHarvesting.count
                    )

                    // Tab Content
                    if selectedInsightTab == 0 {
                        healthTabContent
                    } else if selectedInsightTab == 1 {
                        rebalancingTabContent
                    } else if selectedInsightTab == 2 {
                        goalsTabContent
                    } else {
                        taxTabContent
                    }

                    // Market Insights
                    if !store.insights.marketInsights.isEmpty {
                        sectionCard(
                            title: "Market Insights",
                            icon: "chart.line.uptrend.xyaxis",
                            color: AppTheme.secondary
                        ) {
                            ForEach(store.insights.marketInsights) { insight in
                                marketRow(insight)
                            }
                        }
                    }

                    if !store.isLoading && store.isEmpty {
                        emptyState
                    }

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .refreshable { await store.loadInsights() }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Insights")
            .task { await store.loadInsights() }
            .overlay {
                if store.isLoading && store.isEmpty {
                    ProgressView("Loading insights...")
                }
            }
            .sheet(isPresented: $showAvyaChat) {
                AIChatView(initialQuery: avyaInitialQuery)
            }
        }
    }

    // MARK: - Avya Hub Header

    private var avyaHubHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Top row with avatar and chat button
            HStack {
                HStack(spacing: AppTheme.Spacing.compact) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle().stroke(.white.opacity(0.3), lineWidth: 2)
                            )

                        Image(systemName: "sparkles")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avya AI")
                            .font(AppTheme.Typography.headline(16))
                            .foregroundColor(.white)

                        Text("Your portfolio assistant")
                            .font(AppTheme.Typography.label(12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                Button {
                    avyaInitialQuery = nil
                    showAvyaChat = true
                } label: {
                    Text("Chat")
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            // Search bar
            HStack(spacing: AppTheme.Spacing.compact) {
                TextField("", text: $avyaQuery, prompt: Text("Ask anything about your clients...").foregroundColor(.white.opacity(0.6)))
                    .font(AppTheme.Typography.caption())
                    .foregroundColor(.white)
                    .submitLabel(.send)
                    .onSubmit {
                        if !avyaQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                            avyaInitialQuery = avyaQuery
                            avyaQuery = ""
                            showAvyaChat = true
                        }
                    }

                Button {
                    if !avyaQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                        avyaInitialQuery = avyaQuery
                        avyaQuery = ""
                        showAvyaChat = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(avyaQuery.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .white)
                            .frame(width: 32, height: 32)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(
                                avyaQuery.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? .white.opacity(0.5)
                                    : AppTheme.avyaIndigo
                            )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                Capsule().fill(.white.opacity(0.15))
            )
            .overlay(
                Capsule().stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(AppTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(
                    AppTheme.avyaGradient
                )
                .shadow(color: AppTheme.avyaIndigo.opacity(0.3), radius: 12, y: 6)
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .offset(x: 50, y: -30)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 60, height: 60)
                    .offset(x: -40, y: 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous))
        )
    }

    // MARK: - Quick Action Chips

    private var avyaQuickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                avyaChip(icon: "exclamationmark.triangle", label: "Portfolio risks") {
                    avyaInitialQuery = "Tell me about portfolio risks for my clients"
                    showAvyaChat = true
                }
                avyaChip(icon: "chart.line.uptrend.xyaxis", label: "Top performers") {
                    avyaInitialQuery = "Who are my top performing clients?"
                    showAvyaChat = true
                }
                avyaChip(icon: "arrow.triangle.2.circlepath", label: "SIP opportunities") {
                    avyaInitialQuery = "Which clients should start SIPs?"
                    showAvyaChat = true
                }
                avyaChip(icon: "indianrupeesign.circle", label: "Tax saving") {
                    avyaInitialQuery = "Tell me about tax saving opportunities for my clients"
                    showAvyaChat = true
                }
            }
        }
    }

    private func avyaChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.primary)

                Text(label)
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, AppTheme.Spacing.compact)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color(UIColor.tertiarySystemFill)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5),
                    lineWidth: 1
                )
            )
        }
    }

    // MARK: - Tab Content Views

    private var healthTabContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if store.insights.portfolioHealth.isEmpty {
                tabEmptyState("No health issues", icon: "heart.text.square")
            } else {
                ForEach(store.insights.portfolioHealth) { item in
                    HStack(spacing: AppTheme.Spacing.compact) {
                        HealthScoreRing(score: item.score, size: 52)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.clientName)
                                .font(AppTheme.Typography.accent(14))
                                .foregroundColor(.primary)

                            if let issue = item.issues.first {
                                Text(issue)
                                    .font(AppTheme.Typography.label(12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .listItemCard()
                }
            }
        }
    }

    private var rebalancingTabContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if store.insights.rebalancingAlerts.isEmpty {
                tabEmptyState("No rebalancing needed", icon: "arrow.triangle.2.circlepath")
            } else {
                ForEach(store.insights.rebalancingAlerts) { alert in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text(alert.clientName)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)

                        DriftBar(
                            assetClass: alert.assetClass,
                            current: alert.currentAllocation,
                            target: alert.targetAllocation,
                            deviation: alert.currentAllocation - alert.targetAllocation
                        )
                    }
                    .listItemCard()
                }
            }
        }
    }

    private var goalsTabContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if store.insights.goalAlerts.isEmpty {
                tabEmptyState("All goals on track", icon: "flag.checkered")
            } else {
                ForEach(store.insights.goalAlerts) { alert in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(AppTheme.statusColor(alert.status))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(alert.clientName) - \(alert.goalName)")
                                .font(AppTheme.Typography.accent(14))
                                .foregroundColor(.primary)

                            Text(alert.message)
                                .font(AppTheme.Typography.label(12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.leading, AppTheme.Spacing.compact)

                        Spacer()

                        Text(alert.status.replacingOccurrences(of: "_", with: " "))
                            .font(AppTheme.Typography.label(10))
                            .foregroundColor(AppTheme.statusColor(alert.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.statusColor(alert.status).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
                }
            }
        }
    }

    private var taxTabContent: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            if store.insights.taxHarvesting.isEmpty {
                tabEmptyState("No tax opportunities", icon: "indianrupeesign.circle")
            } else {
                ForEach(store.insights.taxHarvesting) { opp in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opp.clientName)
                                    .font(AppTheme.Typography.accent(14))
                                    .foregroundColor(.primary)

                                Text(opp.fundName)
                                    .font(AppTheme.Typography.label(12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(opp.potentialSavings.formattedCurrency)
                                .font(AppTheme.Typography.numeric(14))
                                .foregroundColor(AppTheme.success)
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.error.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.success)
                                    .frame(width: geo.size.width * min(opp.potentialSavings / max(opp.unrealizedLoss, 1), 1.0), height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Label("Loss: \(opp.unrealizedLoss.formattedCurrency)", systemImage: "arrow.down")
                                .font(AppTheme.Typography.label(10))
                                .foregroundColor(AppTheme.error)
                            Spacer()
                            Label("Savings: \(opp.potentialSavings.formattedCurrency)", systemImage: "arrow.up")
                                .font(AppTheme.Typography.label(10))
                                .foregroundColor(AppTheme.success)
                        }
                    }
                    .listItemCard()
                }
            }
        }
    }

    private func tabEmptyState(_ message: String, icon: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(message)
                .font(AppTheme.Typography.accent(15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xLarge)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(AppTheme.Typography.headline(16))
                    .foregroundColor(.primary)
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Row Views

    private func healthRow(_ item: PortfolioHealthItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.clientName)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                if let issue = item.issues.first {
                    Text(issue)
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            healthScoreBadge(item.score)
        }
        .listItemCard()
    }

    private func healthScoreBadge(_ score: Int) -> some View {
        let color: Color = score >= 80 ? AppTheme.success :
                           score >= 60 ? AppTheme.warning : AppTheme.error

        return Text("\(score)")
            .font(AppTheme.Typography.numeric(14))
            .foregroundColor(color)
            .frame(width: 40, height: 40)
            .background(
                Circle().fill(color.opacity(0.1))
            )
    }

    private func rebalancingRow(_ alert: RebalancingAlert) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.clientName)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Text("\(alert.assetClass): \(String(format: "%.0f%%", alert.currentAllocation)) → \(String(format: "%.0f%%", alert.targetAllocation))")
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(alert.action)
                .font(AppTheme.Typography.label(10))
                .foregroundColor(alert.action == "INCREASE" ? AppTheme.success : AppTheme.error)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((alert.action == "INCREASE" ? AppTheme.success : AppTheme.error).opacity(0.1))
                .clipShape(Capsule())
        }
        .listItemCard()
    }

    private func taxRow(_ opp: TaxHarvestingOpportunity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(opp.clientName)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Text(opp.fundName)
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(opp.potentialSavings.formattedCurrency)
                    .font(AppTheme.Typography.accent(13))
                    .foregroundColor(AppTheme.success)

                Text("savings")
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.secondary)
            }
        }
        .listItemCard()
    }

    private func goalRow(_ alert: GoalAlert) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(alert.clientName) - \(alert.goalName)")
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Text(alert.message)
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(alert.status.replacingOccurrences(of: "_", with: " "))
                .font(AppTheme.Typography.label(10))
                .foregroundColor(AppTheme.statusColor(alert.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.statusColor(alert.status).opacity(0.1))
                .clipShape(Capsule())
        }
        .listItemCard()
    }

    private func marketRow(_ insight: MarketInsight) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            HStack {
                Text(insight.title)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Spacer()

                impactBadge(insight.impact)
            }

            Text(insight.summary)
                .font(AppTheme.Typography.label(12))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .listItemCard()
    }

    private func impactBadge(_ impact: String) -> some View {
        let color: Color = impact == "POSITIVE" ? AppTheme.success :
                           impact == "NEGATIVE" ? AppTheme.error : .secondary

        return HStack(spacing: 3) {
            Image(systemName: impact == "POSITIVE" ? "arrow.up" : impact == "NEGATIVE" ? "arrow.down" : "minus")
                .font(.system(size: 8))
            Text(impact)
                .font(AppTheme.Typography.label(9))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No insights available")
                .font(AppTheme.Typography.headline(17))
            Text("Insights will appear as your clients' portfolios grow")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Insights Store

@MainActor
class InsightsStore: ObservableObject {
    @Published var insights = FAInsights(
        portfolioHealth: [], rebalancingAlerts: [],
        taxHarvesting: [], goalAlerts: [], marketInsights: []
    )
    @Published var isLoading = false

    var isEmpty: Bool {
        insights.portfolioHealth.isEmpty && insights.rebalancingAlerts.isEmpty &&
        insights.taxHarvesting.isEmpty && insights.goalAlerts.isEmpty &&
        insights.marketInsights.isEmpty
    }

    func loadInsights() async {
        isLoading = true
        do {
            insights = try await APIService.shared.get("/advisor/insights")
        } catch {
            // Keep empty state on error
        }
        isLoading = false
    }
}
