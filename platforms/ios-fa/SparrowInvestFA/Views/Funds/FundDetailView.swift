import SwiftUI

struct FundDetailView: View {
    let schemeCode: Int
    @StateObject private var store = FundsStore()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var selectedChartPeriod = "1Y"

    private var filteredNavHistory: [NavHistoryPoint] {
        let history = store.navHistory
        guard selectedChartPeriod != "ALL", !history.isEmpty else { return history }

        let days: Int = switch selectedChartPeriod {
        case "1M": 30
        case "6M": 180
        case "1Y": 365
        case "3Y": 1095
        default: 0
        }
        guard days > 0 else { return history }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return history.filter { point in
            guard let date = formatter.date(from: String(point.date.prefix(10))) else { return true }
            return date >= cutoff
        }
    }

    var body: some View {
        ScrollView {
            if let fund = store.selectedFund {
                VStack(spacing: AppTheme.Spacing.medium) {
                    fundHeader(fund)
                    navHistoryCard
                    keyMetricsCard(fund)
                    fundInfoCard(fund)
                    investmentCard(fund)
                    holdingsCard(fund)
                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            } else if store.isLoadingDetail {
                ProgressView("Loading fund details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let error = store.errorMessage {
                errorState(error)
                    .padding(.top, 100)
            }
        }
        .refreshable { await store.loadFundDetail(schemeCode: schemeCode) }
        .navigationTitle("Fund Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.loadFundDetail(schemeCode: schemeCode)
            await store.loadNavHistory(schemeCode: schemeCode)
        }
    }

    // MARK: - NAV History Card

    private var navHistoryCard: some View {
        let chartData = filteredNavHistory.map { point in
            PortfolioHistoryPoint(
                date: String(point.date.prefix(10)),
                value: point.nav,
                invested: point.nav,
                dayChange: nil,
                dayChangePct: nil
            )
        }

        return sectionCard(title: "NAV History", icon: "chart.xyaxis.line", color: AppTheme.primary) {
            PortfolioLineChart(
                data: chartData,
                selectedPeriod: $selectedChartPeriod,
                periods: ["1M", "6M", "1Y", "3Y", "ALL"],
                onPeriodChange: { period in
                    selectedChartPeriod = period
                }
            )
        }
    }

    // MARK: - Fund Header

    private func fundHeader(_ fund: FAFundDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            Text(fund.schemeName)
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            HStack(spacing: AppTheme.Spacing.small) {
                if let category = fund.schemeCategory {
                    categoryBadge(category)
                }
                if let risk = fund.riskLevel {
                    riskBadge(risk)
                }
            }

            HStack(spacing: AppTheme.Spacing.xLarge) {
                // NAV
                VStack(spacing: 4) {
                    Text("NAV")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)

                    Text(fund.nav != nil ? "\u{20B9}\(String(format: "%.4f", fund.nav!))" : "-")
                        .font(AppTheme.Typography.numeric(iPad ? 24 : 20))
                        .foregroundColor(AppTheme.primary)

                    if let navDate = fund.formattedNavDate {
                        Text(navDate)
                            .font(AppTheme.Typography.label(iPad ? 12 : 10))
                            .foregroundColor(.secondary)
                    }
                }

                // 1Y Return
                if let returns1y = fund.returns1y {
                    VStack(spacing: 4) {
                        Text("1Y Return")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)

                        HStack(spacing: 2) {
                            Image(systemName: returns1y >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12))
                            Text(returns1y.formattedPercent)
                                .font(AppTheme.Typography.numeric(iPad ? 24 : 20))
                        }
                        .foregroundColor(AppTheme.returnColor(returns1y))
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.small)
        }
        .glassCard()
    }

    // MARK: - Key Metrics Card

    private func keyMetricsCard(_ fund: FAFundDetail) -> some View {
        sectionCard(title: "Performance", icon: "chart.line.uptrend.xyaxis", color: AppTheme.primary) {
            // Returns Row
            HStack(spacing: 0) {
                returnColumn("1 Year", fund.returns1y)
                Spacer()
                returnColumn("3 Year", fund.returns3y)
                Spacer()
                returnColumn("5 Year", fund.returns5y)
            }

            Divider()
                .padding(.vertical, AppTheme.Spacing.small)

            // AUM & Expense Ratio
            HStack {
                if let aum = fund.aum {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AUM")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                        Text(AppTheme.formatCurrencyWithSymbol(aum))
                            .font(AppTheme.Typography.numeric(iPad ? 17 : 14))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                if let expense = fund.expenseRatio {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Expense Ratio")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f%%", expense))
                            .font(AppTheme.Typography.numeric(iPad ? 17 : 14))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func returnColumn(_ period: String, _ value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(period)
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)

            if let value {
                Text(value.formattedPercent)
                    .font(AppTheme.Typography.headline(iPad ? 19 : 16))
                    .foregroundColor(AppTheme.returnColor(value))
            } else {
                Text("-")
                    .font(AppTheme.Typography.accent(iPad ? 19 : 16))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Fund Info Card

    private func fundInfoCard(_ fund: FAFundDetail) -> some View {
        sectionCard(title: "Fund Information", icon: "info.circle", color: AppTheme.secondary) {
            VStack(spacing: AppTheme.Spacing.small) {
                if let fundHouse = fund.fundHouse {
                    infoRow("Fund House", fundHouse)
                }
                if let manager = fund.fundManager {
                    infoRow("Fund Manager", manager)
                }
                if let benchmark = fund.benchmark {
                    infoRow("Benchmark", benchmark)
                }
                if let launchDate = fund.launchDate {
                    infoRow("Launch Date", launchDate)
                }
                if let exitLoad = fund.exitLoad {
                    infoRow("Exit Load", exitLoad)
                }
                if let schemeType = fund.schemeType {
                    infoRow("Scheme Type", schemeType)
                }
            }
        }
    }

    // MARK: - Investment Card

    private func investmentCard(_ fund: FAFundDetail) -> some View {
        let hasSip = fund.minSipAmount != nil
        let hasLumpsum = fund.minLumpsumAmount != nil

        return Group {
            if hasSip || hasLumpsum {
                sectionCard(title: "Investment Details", icon: "building.columns", color: AppTheme.accent) {
                    VStack(spacing: AppTheme.Spacing.small) {
                        if let sipAmount = fund.minSipAmount {
                            infoRow("Min SIP Amount", "\u{20B9}\(String(format: "%.0f", sipAmount))")
                        }
                        if let lumpsumAmount = fund.minLumpsumAmount {
                            infoRow("Min Lumpsum", "\u{20B9}\(String(format: "%.0f", lumpsumAmount))")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Holdings Card

    private func holdingsCard(_ fund: FAFundDetail) -> some View {
        Group {
            if let holdings = fund.holdings, !holdings.isEmpty {
                sectionCard(title: "Top Holdings", icon: "chart.pie", color: AppTheme.info) {
                    VStack(spacing: AppTheme.Spacing.compact) {
                        ForEach(Array(holdings.prefix(10).enumerated()), id: \.offset) { _, holding in
                            holdingRow(holding)
                        }
                    }
                }
            }
        }
    }

    private func holdingRow(_ holding: FundHolding) -> some View {
        VStack(spacing: AppTheme.Spacing.micro) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.name)
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let sector = holding.sector {
                        Text(sector)
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(String(format: "%.2f%%", holding.percentage))
                    .font(AppTheme.Typography.numeric(iPad ? 15 : 13))
                    .foregroundColor(AppTheme.primary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(min(holding.percentage / 100.0, 1.0)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .listItemCard()
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
                    .font(AppTheme.Typography.headline(iPad ? 19 : 16))
                    .foregroundColor(.primary)
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Info Row

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Badges

    private func categoryBadge(_ category: String) -> some View {
        Text(category)
            .font(AppTheme.Typography.label(iPad ? 12 : 10))
            .foregroundColor(AppTheme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(Capsule())
    }

    private func riskBadge(_ risk: String) -> some View {
        let color = riskColor(risk)
        return Text(risk)
            .font(AppTheme.Typography.label(iPad ? 12 : 10))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func riskColor(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "low", "low to moderate": return AppTheme.success
        case "moderate", "moderately high": return AppTheme.warning
        case "high", "very high": return AppTheme.error
        default: return .secondary
        }
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.warning)

            Text("Something went wrong")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text(message)
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await store.loadFundDetail(schemeCode: schemeCode) }
            } label: {
                Text("Retry")
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xLarge)
    }
}
