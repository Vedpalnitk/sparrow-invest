import SwiftUI

struct FundCategory: Identifiable {
    let id = UUID()
    let name: String
    let apiKey: String
    let icon: String
    let tint: Color
}

private let fundCategories = [
    FundCategory(name: "Large Cap", apiKey: "large_cap", icon: "building.columns", tint: Color(hex: "3B82F6")),
    FundCategory(name: "Mid Cap", apiKey: "mid_cap", icon: "chart.line.uptrend.xyaxis", tint: Color(hex: "8B5CF6")),
    FundCategory(name: "Small Cap", apiKey: "small_cap", icon: "diamond", tint: Color(hex: "EC4899")),
    FundCategory(name: "Flexi Cap", apiKey: "flexi_cap", icon: "arrow.left.arrow.right", tint: Color(hex: "06B6D4")),
    FundCategory(name: "ELSS", apiKey: "ELSS", icon: "graduationcap", tint: Color(hex: "10B981")),
    FundCategory(name: "Debt", apiKey: "Debt", icon: "banknote", tint: Color(hex: "F59E0B")),
    FundCategory(name: "Hybrid", apiKey: "Hybrid", icon: "chart.pie", tint: Color(hex: "EF4444")),
    FundCategory(name: "Index", apiKey: "Index", icon: "chart.bar.xaxis", tint: Color(hex: "6366F1"))
]

private enum FundSortOption: String, CaseIterable {
    case returns1y = "1Y Returns ↓"
    case returns3y = "3Y Returns ↓"
    case aum = "AUM ↓"
    case rating = "Rating ↓"
    case nameAZ = "Name A→Z"
}

struct FundUniverseView: View {
    @StateObject private var store = FundsStore()
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedCategory: FundCategory?
    @State private var showSearch = false
    @State private var localSearch = ""
    @State private var sortOption: FundSortOption = .returns1y
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        if sizeClass == .regular {
            iPadFundLayout
        } else {
            iPhoneFundLayout
        }
    }

    // MARK: - iPad List Content (for 3-column split)

    private var iPadFundLayout: some View {
        VStack(spacing: 0) {
            if let category = selectedCategory {
                fundListContent(category: category)
            } else {
                categoryGridContent
            }
        }
        .background(AppTheme.pageBackground(colorScheme: colorScheme))
        .navigationTitle(selectedCategory.map { "Fund Universe — \($0.name)" } ?? "Fund Universe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedCategory != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedCategory = nil
                        store.funds = []
                        localSearch = ""
                        coordinator.selectedFundCode = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Categories")
                                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSearch) {
            FundSearchView()
        }
    }

    // MARK: - iPhone Stack

    private var iPhoneFundLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let category = selectedCategory {
                    fundListContent(category: category)
                } else {
                    categoryGridContent
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle(selectedCategory.map { "Fund Universe — \($0.name)" } ?? "Fund Universe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if selectedCategory != nil {
                            selectedCategory = nil
                            store.funds = []
                            localSearch = ""
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedCategory != nil ? "chevron.left" : "xmark")
                                .font(.system(size: selectedCategory != nil ? 14 : 16))
                            if selectedCategory != nil {
                                Text("Categories")
                                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showSearch) {
                FundSearchView()
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGridContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.compact) {
                // Search bar on landing page
                Button {
                    showSearch = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        Text("Search funds...")
                            .font(AppTheme.Typography.body(iPad ? 17 : 15))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                .glassCard(cornerRadius: AppTheme.CornerRadius.medium)
                .padding(.horizontal, AppTheme.Spacing.medium)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: AppTheme.Spacing.compact
                ) {
                    ForEach(fundCategories) { category in
                        categoryCard(category)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .padding(.vertical, AppTheme.Spacing.compact)
        }
    }

    private func categoryCard(_ category: FundCategory) -> some View {
        Button {
            selectedCategory = category
            Task { await store.loadFundsByCategory(category.apiKey) }
        } label: {
            VStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(category.tint.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.system(size: 22))
                        .foregroundColor(category.tint)
                }

                Text(category.name)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: - Fund List

    private var filteredAndSortedFunds: [FAFund] {
        let filtered = localSearch.isEmpty ? store.funds
            : store.funds.filter { $0.schemeName.localizedCaseInsensitiveContains(localSearch) }

        switch sortOption {
        case .returns1y:
            return filtered.sorted { ($0.returns1y ?? -.infinity) > ($1.returns1y ?? -.infinity) }
        case .returns3y:
            return filtered.sorted { ($0.returns3y ?? -.infinity) > ($1.returns3y ?? -.infinity) }
        case .aum:
            return filtered.sorted { ($0.aum ?? 0) > ($1.aum ?? 0) }
        case .rating:
            return filtered.sorted { ($0.fundRating ?? 0) > ($1.fundRating ?? 0) }
        case .nameAZ:
            return filtered.sorted { $0.schemeName < $1.schemeName }
        }
    }

    private func fundListContent(category: FundCategory) -> some View {
        Group {
            if store.isLoading && store.funds.isEmpty {
                Spacer()
                ProgressView("Loading \(category.name) funds...")
                Spacer()
            } else if let error = store.errorMessage {
                Spacer()
                errorState(message: error, category: category)
                Spacer()
            } else if store.funds.isEmpty && !store.isLoading {
                Spacer()
                emptyState(category: category)
                Spacer()
            } else {
                VStack(spacing: 0) {
                    // Local search + sort controls
                    HStack(spacing: AppTheme.Spacing.small) {
                        HStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            TextField("Filter funds...", text: $localSearch)
                                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, AppTheme.Spacing.compact)
                        .frame(height: 40)
                        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: 0)

                        Menu {
                            ForEach(FundSortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 40, height: 40)
                                .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: 0)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)

                    let funds = filteredAndSortedFunds
                    if funds.isEmpty {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.compact) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No matches for \"\(localSearch)\"")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.small) {
                                ForEach(funds) { fund in
                                    if sizeClass == .regular {
                                        Button {
                                            coordinator.selectedFundCode = fund.schemeCode
                                        } label: {
                                            fundRow(fund)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                                                        .stroke(coordinator.selectedFundCode == fund.schemeCode ? AppTheme.primary : Color.clear, lineWidth: 2)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        NavigationLink {
                                            FundDetailView(schemeCode: fund.schemeCode)
                                        } label: {
                                            fundRow(fund)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.bottom, AppTheme.Spacing.xxxLarge)
                        }
                        .refreshable {
                            await store.loadFundsByCategory(category.apiKey)
                        }
                    }
                }
            }
        }
    }

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
                HStack(alignment: .top, spacing: 4) {
                    Text(fund.schemeName)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 14))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    if let rating = fund.fundRating {
                        starRating(rating)
                    }
                }

                HStack(spacing: AppTheme.Spacing.small) {
                    if let category = fund.schemeCategory {
                        let short = shortenCategory(category)
                        Text(short)
                            .font(AppTheme.Typography.label(iPad ? 12 : 9))
                            .foregroundColor(categoryColor(category))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor(category).opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let nav = fund.nav {
                        Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                            .font(AppTheme.Typography.label(iPad ? 14 : 11))
                            .foregroundColor(.secondary)
                    }

                    if let aum = fund.aum {
                        Text("AUM: \(formatAum(aum))")
                            .font(AppTheme.Typography.label(iPad ? 14 : 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Returns
            VStack(alignment: .trailing, spacing: 4) {
                if let returns1y = fund.returns1y {
                    returnBadge("1Y", value: returns1y)
                }

                if let returns3y = fund.returns3y {
                    returnBadge("3Y", value: returns3y)
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

    // MARK: - Stars & Badges

    private func starRating(_ rating: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: iPad ? 12 : 9))
                    .foregroundColor(i <= rating ? AppTheme.warning : Color.secondary.opacity(0.3))
            }
        }
    }

    private func returnBadge(_ period: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: iPad ? 10 : 8))
            Text("\(period) \(value.formattedPercent)")
                .font(AppTheme.Typography.label(iPad ? 14 : 11))
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

    private func formatAum(_ aum: Double) -> String {
        if aum >= 1_00_00_00_000 {
            return "\u{20B9}\(String(format: "%.0f", aum / 1_00_00_00_000)) K Cr"
        } else if aum >= 1_00_00_000 {
            return "\u{20B9}\(String(format: "%.0f", aum / 1_00_00_000)) Cr"
        } else if aum >= 1_00_000 {
            return "\u{20B9}\(String(format: "%.0f", aum / 1_00_000)) L"
        } else {
            return "\u{20B9}\(String(format: "%.0f", aum))"
        }
    }

    private func categoryColor(_ category: String?) -> Color {
        guard let category = category?.lowercased() else { return AppTheme.primary }
        if category.contains("equity") || category.contains("large") || category.contains("mid") || category.contains("small") || category.contains("flexi") { return AppTheme.equityColor }
        if category.contains("debt") { return AppTheme.debtColor }
        if category.contains("hybrid") { return AppTheme.hybridColor }
        if category.contains("elss") || category.contains("tax") { return AppTheme.elssColor }
        if category.contains("index") { return AppTheme.indexColor }
        if category.contains("gold") { return AppTheme.goldColor }
        return AppTheme.primary
    }

    private func categoryIcon(_ category: String?) -> String {
        guard let category = category?.lowercased() else { return "chart.bar" }
        if category.contains("equity") || category.contains("large") || category.contains("mid") || category.contains("small") || category.contains("flexi") { return "chart.line.uptrend.xyaxis" }
        if category.contains("debt") { return "building.columns" }
        if category.contains("hybrid") { return "chart.pie" }
        if category.contains("elss") || category.contains("tax") { return "indianrupeesign.circle" }
        if category.contains("index") { return "chart.bar.xaxis" }
        if category.contains("gold") { return "circle.fill" }
        return "chart.bar"
    }

    private func shortenCategory(_ category: String) -> String {
        let lower = category.lowercased()
        if lower.contains("large") { return "Large Cap" }
        if lower.contains("mid") { return "Mid Cap" }
        if lower.contains("small") { return "Small Cap" }
        if lower.contains("flexi") { return "Flexi Cap" }
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

    private func errorState(message: String, category: FundCategory) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.error.opacity(0.7))

            Text("Something went wrong")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text(message)
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await store.loadFundsByCategory(category.apiKey) }
            } label: {
                Text("Try Again")
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .overlay(
                        Capsule().stroke(AppTheme.primary, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xLarge)
    }

    private func emptyState(category: FundCategory) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No funds found")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("No \(category.name) funds available")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
