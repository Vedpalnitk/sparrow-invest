import SwiftUI

/// Side-by-side fund comparison view (iPad-exclusive, 2–4 funds in columns with aligned metric rows).
struct FundCompareView: View {
    @StateObject private var store = FundsStore()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var searchQuery = ""
    @State private var selectedFunds: [FAFund] = []
    @State private var showSearch = false

    private let maxFunds = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedFunds.isEmpty {
                    emptyState
                } else {
                    comparisonContent
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Compare Funds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedFunds.count < maxFunds {
                        Button {
                            showSearch = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("Add Fund")
                                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                fundPickerSheet
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xLarge) {
            Spacer()

            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))

            Text("Compare Funds Side by Side")
                .font(AppTheme.Typography.headline(iPad ? 21 : 18))
                .foregroundColor(.primary)

            Text("Add 2–4 funds to compare their performance, risk, and key metrics in aligned columns.")
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button {
                showSearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add First Fund")
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Comparison Content

    private var comparisonContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Fund header cards
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    // Metric label column
                    VStack(spacing: 0) {
                        Text("")
                            .frame(height: 100)
                    }
                    .frame(width: 120)

                    ForEach(selectedFunds, id: \.schemeCode) { fund in
                        fundHeaderCard(fund)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Comparison rows
                comparisonSection("Performance") {
                    comparisonRow("1Y Returns") { fund in
                        returnText(fund.returns1y)
                    }
                    comparisonRow("3Y Returns") { fund in
                        returnText(fund.returns3y)
                    }
                }

                comparisonSection("Fund Details") {
                    comparisonRow("NAV") { fund in
                        Text(fund.nav.map { "\u{20B9}\(String(format: "%.2f", $0))" } ?? "—")
                            .font(AppTheme.Typography.numeric(iPad ? 19 : 16))
                            .foregroundColor(.primary)
                    }
                    comparisonRow("AUM") { fund in
                        Text(fund.aum.map { AppTheme.formatCurrencyWithSymbol($0) } ?? "—")
                            .font(AppTheme.Typography.numeric(iPad ? 19 : 16))
                            .foregroundColor(.primary)
                    }
                    comparisonRow("Rating") { fund in
                        if let rating = fund.fundRating {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(i <= rating ? AppTheme.warning : .secondary.opacity(0.3))
                                }
                            }
                        } else {
                            Text("—")
                                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    comparisonRow("Risk Level") { fund in
                        if let risk = fund.riskLevel {
                            Text(risk)
                                .font(AppTheme.Typography.label(iPad ? 15 : 13))
                                .foregroundColor(riskColor(risk))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(riskColor(risk).opacity(0.1))
                                .clipShape(Capsule())
                        } else {
                            Text("—")
                                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    comparisonRow("Category") { fund in
                        Text(fund.schemeCategory ?? "—")
                            .font(AppTheme.Typography.label(iPad ? 15 : 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
        }
    }

    // MARK: - Comparison Helpers

    private func fundHeaderCard(_ fund: FAFund) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text(fund.schemeName)
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.center)

            Button {
                selectedFunds.removeAll { $0.schemeCode == fund.schemeCode }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    private func comparisonSection(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(AppTheme.Typography.label(iPad ? 15 : 13))
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.small)

            rows()
        }
    }

    private func comparisonRow(_ label: String, @ViewBuilder content: @escaping (FAFund) -> some View) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 16 : 14))
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading)

            ForEach(selectedFunds, id: \.schemeCode) { fund in
                content(fund)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.3))
        )
    }

    private func returnText(_ value: Double?) -> some View {
        Group {
            if let val = value {
                Text(val.formattedPercent)
                    .font(AppTheme.Typography.numeric(iPad ? 19 : 16))
                    .foregroundColor(AppTheme.returnColor(val))
            } else {
                Text("—")
                    .font(AppTheme.Typography.body(iPad ? 16 : 14))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func riskColor(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "low", "low to moderate": return AppTheme.success
        case "moderate", "moderately high": return AppTheme.warning
        case "high", "very high": return AppTheme.error
        default: return .secondary
        }
    }

    // MARK: - Fund Picker Sheet

    private var fundPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    TextField("Search funds to compare...", text: $searchQuery)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            Task { await store.searchFunds(query: searchQuery) }
                        }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(height: 44)
                .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: 0)
                .padding(AppTheme.Spacing.medium)

                if store.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if store.funds.isEmpty {
                    Spacer()
                    Text("Search for funds to add to comparison")
                        .font(AppTheme.Typography.body(iPad ? 16 : 14))
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(store.funds) { fund in
                        let alreadyAdded = selectedFunds.contains { $0.schemeCode == fund.schemeCode }
                        Button {
                            if !alreadyAdded && selectedFunds.count < maxFunds {
                                selectedFunds.append(fund)
                                showSearch = false
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fund.schemeName)
                                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    if let cat = fund.schemeCategory {
                                        Text(cat)
                                            .font(AppTheme.Typography.label(iPad ? 15 : 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if alreadyAdded {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.success)
                                }
                            }
                        }
                        .disabled(alreadyAdded)
                    }
                }
            }
            .navigationTitle("Add Fund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSearch = false }
                }
            }
        }
    }
}
