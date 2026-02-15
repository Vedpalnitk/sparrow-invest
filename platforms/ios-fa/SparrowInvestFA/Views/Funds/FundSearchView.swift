import SwiftUI

struct FundSearchView: View {
    @StateObject private var store = FundsStore()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    TextField("Search by fund name...", text: $store.searchQuery)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            Task { await store.searchFunds(query: store.searchQuery) }
                        }
                        .onChange(of: store.searchQuery) { _, newValue in
                            Task {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                guard store.searchQuery == newValue else { return }
                                await store.searchFunds(query: newValue)
                            }
                        }

                    if !store.searchQuery.isEmpty {
                        Button {
                            store.searchQuery = ""
                            store.funds = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)

                // Category Filter Chips (pill-shaped)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        Button {
                            store.selectedCategory = "All"
                        } label: {
                            Text("All")
                                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                .foregroundColor(store.selectedCategory == "All" ? .white : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    store.selectedCategory == "All"
                                        ? AnyShapeStyle(AppTheme.primaryGradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        ForEach(FundsStore.categories, id: \.self) { category in
                            Button {
                                store.selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                    .foregroundColor(store.selectedCategory == category ? .white : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        store.selectedCategory == category
                                            ? AnyShapeStyle(AppTheme.primaryGradient)
                                            : AnyShapeStyle(Color.clear)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                    )
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
                .padding(.bottom, AppTheme.Spacing.small)

                // Content
                if store.isLoading && store.funds.isEmpty {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if store.searchQuery.isEmpty {
                    Spacer()
                    idleState
                    Spacer()
                } else if store.filteredFunds.isEmpty && !store.isLoading {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            ForEach(store.filteredFunds) { fund in
                                NavigationLink {
                                    FundDetailView(schemeCode: fund.schemeCode)
                                } label: {
                                    fundRow(fund)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.xxxLarge)
                    }
                    .refreshable {
                        await store.searchFunds(query: store.searchQuery)
                    }
                }
            }
            .navigationTitle("Search Funds")
        }
    }

    // MARK: - Fund Row

    private func fundRow(_ fund: FAFund) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Fund Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(categoryColor(fund.schemeCategory).opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: categoryIcon(fund.schemeCategory))
                    .font(.system(size: 18))
                    .foregroundColor(categoryColor(fund.schemeCategory))
            }

            // Fund Info
            VStack(alignment: .leading, spacing: 2) {
                Text(fund.schemeName)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppTheme.Spacing.small) {
                    if let category = fund.schemeCategory {
                        categoryBadge(category)
                    }

                    if let nav = fund.nav {
                        Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Returns & Risk
            VStack(alignment: .trailing, spacing: 4) {
                if let returns1y = fund.returns1y {
                    returnBadge("1Y", value: returns1y)
                }

                if let returns3y = fund.returns3y {
                    Text("3Y: \(returns3y.formattedPercent)")
                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                        .foregroundColor(AppTheme.returnColor(returns3y))
                }

                if let risk = fund.riskLevel {
                    riskBadge(risk)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Badges

    private func categoryBadge(_ category: String) -> some View {
        let short = shortenCategory(category)
        return Text(short)
            .font(AppTheme.Typography.label(iPad ? 11 : 9))
            .foregroundColor(categoryColor(category))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(categoryColor(category).opacity(0.1))
            .clipShape(Capsule())
    }

    private func returnBadge(_ period: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 8))
            Text("\(period) \(value.formattedPercent)")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
        }
        .foregroundColor(AppTheme.returnColor(value))
    }

    private func riskBadge(_ risk: String) -> some View {
        let color = riskColor(risk)
        return Text(risk)
            .font(AppTheme.Typography.label(iPad ? 11 : 9))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func categoryColor(_ category: String?) -> Color {
        guard let category = category?.lowercased() else { return AppTheme.primary }
        if category.contains("equity") { return AppTheme.equityColor }
        if category.contains("debt") { return AppTheme.debtColor }
        if category.contains("hybrid") { return AppTheme.hybridColor }
        if category.contains("elss") || category.contains("tax") { return AppTheme.elssColor }
        if category.contains("index") { return AppTheme.indexColor }
        if category.contains("gold") { return AppTheme.goldColor }
        return AppTheme.primary
    }

    private func categoryIcon(_ category: String?) -> String {
        guard let category = category?.lowercased() else { return "chart.bar" }
        if category.contains("equity") { return "chart.line.uptrend.xyaxis" }
        if category.contains("debt") { return "building.columns" }
        if category.contains("hybrid") { return "chart.pie" }
        if category.contains("elss") || category.contains("tax") { return "indianrupeesign.circle" }
        if category.contains("index") { return "chart.bar.xaxis" }
        if category.contains("gold") { return "circle.fill" }
        return "chart.bar"
    }

    private func shortenCategory(_ category: String) -> String {
        let lower = category.lowercased()
        if lower.contains("equity") { return "Equity" }
        if lower.contains("debt") { return "Debt" }
        if lower.contains("hybrid") { return "Hybrid" }
        if lower.contains("elss") || lower.contains("tax") { return "ELSS" }
        if lower.contains("index") { return "Index" }
        if lower.contains("gold") { return "Gold" }
        return category.count > 12 ? String(category.prefix(12)) + "..." : category
    }

    private func riskColor(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "low", "low to moderate": return AppTheme.success
        case "moderate", "moderately high": return AppTheme.warning
        case "high", "very high": return AppTheme.error
        default: return .secondary
        }
    }

    // MARK: - States

    private var idleState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Search for funds")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Enter a fund name or select a category to get started")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppTheme.Spacing.xLarge)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No funds found")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Try a different search term or category")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
