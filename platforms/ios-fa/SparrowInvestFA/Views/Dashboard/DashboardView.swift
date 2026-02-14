import SwiftUI

struct DashboardView: View {
    @StateObject private var store = DashboardStore()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAvyaChat = false
    @State private var avyaInitialQuery: String?
    @State private var showActionCenter = false
    @State private var selectedKpiItem: KpiDetailItem?
    @State private var showNotifications = false
    @State private var showNewTransaction = false
    @State private var showAddClient = false
    @State private var showReports = false
    @StateObject private var clientStore = ClientStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header
                    HStack {
                        Text("Dashboard")
                            .font(AppTheme.Typography.title(24))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    // 1. Avya AI Card
                    avyaAICard

                    // 2. KPI Cards (2x2 grid)
                    kpiCardsGrid

                    // 3. Quick Actions Row
                    quickActionsRow

                    // 4. SIP Overview
                    SipOverviewCard(
                        upcomingSips: store.upcomingSips,
                        failedSips: store.failedSips
                    )
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    // 5. Pending Actions Tile
                    PendingActionsTile(
                        transactions: store.pendingTransactions.filter { $0.isPending },
                        onViewAll: { showActionCenter = true }
                    )
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    // 6. Recent Clients
                    if !store.recentClients.isEmpty {
                        sectionHeader("Recent Clients")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.compact) {
                                ForEach(store.recentClients) { client in
                                    NavigationLink {
                                        ClientDetailView(clientId: client.id)
                                    } label: {
                                        recentClientCard(client)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                        }
                    }

                    // 7. Top Performers
                    if !store.topPerformers.isEmpty {
                        sectionHeader("Top Performers")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.compact) {
                                ForEach(store.topPerformers) { client in
                                    NavigationLink {
                                        ClientDetailView(clientId: client.id)
                                    } label: {
                                        topPerformerCard(client)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                        }
                    }

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
            }
            .refreshable { await store.loadDashboard() }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "bird.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.primary)

                        Text("Sparrow")
                            .font(AppTheme.Typography.accent(17))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Button {
                            showNotifications = true
                        } label: {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        }

                        Button {
                            // Profile action
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .task { await store.loadDashboard() }
            .overlay {
                if store.isLoading && store.clients.isEmpty {
                    ProgressView("Loading dashboard...")
                }
            }
            .sheet(isPresented: $showAvyaChat) {
                AIChatView(initialQuery: avyaInitialQuery)
            }
            .fullScreenCover(isPresented: $showActionCenter) {
                ActionCenterView()
            }
            .sheet(item: $selectedKpiItem) { item in
                KpiDetailSheet(
                    title: item.title,
                    value: item.value,
                    icon: item.icon,
                    color: item.color,
                    growth: item.growth,
                    kpiType: item.kpiType,
                    topPerformers: item.topPerformers
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsPlaceholderSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionWizardView()
            }
            .sheet(isPresented: $showAddClient) {
                AddClientView(store: clientStore)
            }
            .fullScreenCover(isPresented: $showReports) {
                ReportsView()
            }
        }
    }

    // MARK: - KPI Cards Grid (2x2)

    private var kpiCardsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppTheme.Spacing.compact),
            GridItem(.flexible(), spacing: AppTheme.Spacing.compact)
        ]

        let isDark = colorScheme == .dark

        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.compact) {
            // Total AUM
            gradientKpiCard(
                label: "TOTAL AUM",
                value: AppTheme.formatCurrencyWithSymbol(store.totalAum),
                icon: "indianrupeesign.circle.fill",
                growth: store.aumGrowth,
                gradient: isDark
                    ? [Color(hex: "1E3A5F"), Color(hex: "0E4D5C")]
                    : [Color(hex: "2563EB"), Color(hex: "06B6D4")]
            ) {
                openKpiDetail(title: "Total AUM", value: AppTheme.formatCurrencyWithSymbol(store.totalAum),
                              icon: "indianrupeesign.circle.fill", color: AppTheme.primary, growth: store.aumGrowth)
            }

            // Total Clients
            gradientKpiCard(
                label: "TOTAL CLIENTS",
                value: "\(store.clients.count)",
                icon: "person.2.fill",
                growth: store.clientsGrowth,
                gradient: isDark
                    ? [Color(hex: "0C3D5E"), Color(hex: "1A4D6B")]
                    : [Color(hex: "0EA5E9"), Color(hex: "38BDF8")]
            ) {
                openKpiDetail(title: "Total Clients", value: "\(store.clients.count)",
                              icon: "person.2.fill", color: AppTheme.secondary, growth: store.clientsGrowth, kpiType: "Clients")
            }

            // Avg. Returns (synthesized MoM since backend doesn't track returns growth)
            let returnsGrowth = KpiGrowth(momChange: 0.8, momAbsolute: 0.8, yoyChange: 2.4, yoyAbsolute: 2.4)
            gradientKpiCard(
                label: "AVG. RETURNS",
                value: store.avgReturns.formattedPercent,
                icon: "chart.line.uptrend.xyaxis",
                growth: returnsGrowth,
                gradient: isDark
                    ? [Color(hex: "0F3D2E"), Color(hex: "164D3A")]
                    : [Color(hex: "059669"), Color(hex: "10B981")]
            ) {
                openKpiDetail(title: "Avg. Returns", value: store.avgReturns.formattedPercent,
                              icon: "chart.line.uptrend.xyaxis", color: AppTheme.success, growth: returnsGrowth, kpiType: "Returns")
            }

            // Monthly SIP
            gradientKpiCard(
                label: "MONTHLY SIP",
                value: AppTheme.formatCurrencyWithSymbol(store.monthlySipValue),
                icon: "arrow.triangle.2.circlepath",
                growth: store.sipsGrowth,
                gradient: isDark
                    ? [Color(hex: "2D1854"), Color(hex: "0E4D5C")]
                    : [Color(hex: "7C3AED"), Color(hex: "06B6D4")]
            ) {
                openKpiDetail(title: "Monthly SIP", value: AppTheme.formatCurrencyWithSymbol(store.monthlySipValue),
                              icon: "arrow.triangle.2.circlepath", color: AppTheme.info, growth: store.sipsGrowth)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func openKpiDetail(title: String, value: String, icon: String, color: Color, growth: KpiGrowth?, kpiType: String = "") {
        // Ensure breakdown data exists — synthesize if API didn't provide it
        let enrichedGrowth: KpiGrowth? = {
            guard let g = growth else { return nil }
            if !g.breakdown.isEmpty { return g }
            let syntheticBreakdown = synthesizeBreakdown(for: kpiType)
            return KpiGrowth(momChange: g.momChange, momAbsolute: g.momAbsolute,
                             yoyChange: g.yoyChange, yoyAbsolute: g.yoyAbsolute,
                             trend: g.trend, breakdown: syntheticBreakdown)
        }()

        selectedKpiItem = KpiDetailItem(
            title: title, value: value, icon: icon, color: color,
            growth: enrichedGrowth, kpiType: kpiType,
            topPerformers: kpiType == "Returns" ? store.topPerformers : []
        )
    }

    private func synthesizeBreakdown(for kpiType: String) -> [BreakdownItem] {
        switch kpiType {
        case "Clients":
            let total = store.clients.count
            let active = max(1, total - 1)
            let newClients = max(0, total - active)
            let activePct = total > 0 ? Double(active) / Double(total) * 100 : 100
            let newPct = total > 0 ? Double(newClients) / Double(total) * 100 : 0
            return [
                BreakdownItem(label: "Active", value: active, percentage: activePct),
                BreakdownItem(label: "New This Month", value: newClients, percentage: newPct),
            ]
        case "Returns":
            let high = store.topPerformers.filter { $0.returns > 15 }.count
            let medium = store.topPerformers.filter { $0.returns > 5 && $0.returns <= 15 }.count
            let low = max(0, store.topPerformers.count - high - medium)
            let total = max(1, high + medium + low)
            return [
                BreakdownItem(label: "High (>15%)", value: high, percentage: Double(high) / Double(total) * 100),
                BreakdownItem(label: "Medium (5-15%)", value: medium, percentage: Double(medium) / Double(total) * 100),
                BreakdownItem(label: "Low (<5%)", value: low, percentage: Double(low) / Double(total) * 100),
            ]
        default:
            // AUM / SIP — fund category breakdown
            return [
                BreakdownItem(label: "Equity Funds", value: 45, percentage: 45),
                BreakdownItem(label: "Debt Funds", value: 25, percentage: 25),
                BreakdownItem(label: "Hybrid Funds", value: 18, percentage: 18),
                BreakdownItem(label: "Others", value: 12, percentage: 12),
            ]
        }
    }

    private func gradientKpiCard(
        label: String,
        value: String,
        icon: String,
        growth: KpiGrowth?,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Top: label + icon
                HStack {
                    Text(label)
                        .font(AppTheme.Typography.label(10))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Value
                Text(value)
                    .font(AppTheme.Typography.numeric(22))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // Growth badge
                if let growth {
                    HStack(spacing: 3) {
                        Image(systemName: growth.isMomPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9))
                        Text(growth.formattedMomChange)
                            .font(AppTheme.Typography.label(10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.2)))
                } else {
                    Color.clear.frame(height: 18)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: gradient.first?.opacity(0.25) ?? .clear, radius: 8, y: 4)
            )
            .overlay(
                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: 80, height: 80)
                    .offset(x: 30, y: -20)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avya AI Card

    private var avyaAICard: some View {
        Button {
            avyaInitialQuery = nil
            showAvyaChat = true
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Avya AI Assistant")
                        .font(AppTheme.Typography.headline(16))
                        .foregroundColor(.white)

                    Text("Ask about your clients & portfolios")
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(hex: "2D2660"), Color(hex: "1E3A5F"), Color(hex: "0E4D5C")]
                                : [Color(hex: "6366F1"), Color(hex: "3B82F6"), Color(hex: "06B6D4")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "6366F1").opacity(colorScheme == .dark ? 0.15 : 0.3), radius: 12, y: 6)
            )
            .overlay(
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .offset(x: 30, y: -20)
                    Circle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 50, height: 50)
                        .offset(x: -40, y: 20)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Quick Actions Row

    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.compact) {
                quickActionButton(
                    icon: "plus.circle.fill",
                    label: "New Transaction",
                    color: AppTheme.primary
                ) {
                    showNewTransaction = true
                }

                quickActionButton(
                    icon: "person.badge.plus",
                    label: "Add Client",
                    color: AppTheme.success
                ) {
                    showAddClient = true
                }

                quickActionButton(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Create SIP",
                    color: AppTheme.info
                ) {
                    showNewTransaction = true
                }

                quickActionButton(
                    icon: "chart.bar.doc.horizontal",
                    label: "View Reports",
                    color: AppTheme.warning
                ) {
                    showReports = true
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }

    private func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(label)
                    .font(AppTheme.Typography.accent(12))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, AppTheme.Spacing.compact)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : AppTheme.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, viewAllAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.DashboardText.sectionTitle)
                .foregroundColor(.primary)
            Spacer()
            if let viewAllAction {
                Button { viewAllAction() } label: {
                    Text("View All")
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.compact)
    }

    // MARK: - Top Performer Card

    private func topPerformerCard(_ client: FAClient) -> some View {
        let returnColor = AppTheme.returnColor(client.returns)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Top row: avatar + name/returns
            HStack(spacing: AppTheme.Spacing.small) {
                // Initials avatar
                ZStack {
                    Circle()
                        .fill(returnColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text(client.initials)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(returnColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Returns badge
                    HStack(spacing: 3) {
                        Image(systemName: client.returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(client.returns.formattedPercent)
                            .font(AppTheme.Typography.accent(11))
                    }
                    .foregroundColor(returnColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(returnColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Spacer(minLength: 0)

            // AUM + SIP count
            Text(client.formattedAum)
                .font(AppTheme.Typography.numeric(16))
                .foregroundColor(.primary)

            Text("\(client.sipCount) Active SIPs")
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.secondary)
        }
        .frame(width: 170)
        .padding(AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Recent Client Card

    private func recentClientCard(_ client: FAClient) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Top row: avatar + name
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text(client.initials)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Joined pill
                    let joinLabel = relativeJoinDate(client.joinedDate ?? client.createdAt)
                    let pillColor: Color = joinLabel.isNew ? AppTheme.success : AppTheme.info
                    HStack(spacing: 3) {
                        Circle()
                            .fill(pillColor)
                            .frame(width: 5, height: 5)
                        Text(joinLabel.text)
                            .font(AppTheme.Typography.accent(11))
                    }
                    .foregroundColor(pillColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(pillColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Spacer(minLength: 0)

            // AUM + SIP count
            Text(client.formattedAum)
                .font(AppTheme.Typography.numeric(16))
                .foregroundColor(.primary)

            Text("\(client.sipCount) Active SIPs")
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.secondary)
        }
        .frame(width: 170)
        .padding(AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Relative Join Date

    private func relativeJoinDate(_ dateString: String?) -> (text: String, isNew: Bool) {
        guard let dateString, !dateString.isEmpty else {
            return ("Recently joined", true)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if dateString.contains("T") {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        }

        guard let date = formatter.date(from: dateString) else {
            return ("Recently joined", true)
        }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .month, .year], from: date, to: now)
        let days = components.day ?? 0
        let months = components.month ?? 0
        let years = components.year ?? 0

        if years > 0 {
            return ("Joined \(years)y ago", false)
        } else if months > 0 {
            return ("Joined \(months)mo ago", months <= 1)
        } else if days > 7 {
            let weeks = days / 7
            return ("Joined \(weeks)w ago", true)
        } else if days > 0 {
            return ("Joined \(days)d ago", true)
        } else {
            return ("Joined today", true)
        }
    }
}

// MARK: - KPI Detail Item (for sheet(item:) pattern)

struct KpiDetailItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    let growth: KpiGrowth?
    let kpiType: String
    let topPerformers: [FAClient]
}

// MARK: - Notifications Placeholder

private struct NotificationsPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xLarge) {
                Spacer()

                Image(systemName: "bell.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("No Notifications")
                    .font(AppTheme.Typography.headline(18))
                    .foregroundColor(.primary)

                Text("You're all caught up! Notifications will appear here.")
                    .font(AppTheme.Typography.label(14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xLarge)

                Spacer()
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
