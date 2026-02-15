import SwiftUI

struct WhitelistedFundsView: View {
    @StateObject private var store = WhitelistStore()
    @StateObject private var fundsStore = FundsStore()
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showAddSheet = false
    @State private var showDeleteConfirm = false
    @State private var fundToDelete: WhitelistedFund?
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        if sizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Split View

    private var iPadLayout: some View {
        mainContent
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("My Picks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { addButton }
            .task { await store.loadWhitelist() }
    }

    // MARK: - iPhone Stack

    private var iPhoneLayout: some View {
        NavigationStack {
            mainContent
                .background(AppTheme.pageBackground(colorScheme: colorScheme))
                .navigationTitle("My Picks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    addButton
                }
        }
        .task { await store.loadWhitelist() }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Summary Card
                summaryCard

                // Year Picker
                if !store.availableYears.isEmpty {
                    yearPicker
                }

                // Fund List
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xxxLarge)
                } else if store.filteredFunds.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(store.filteredFunds) { fund in
                            if sizeClass == .regular {
                                fundRow(fund)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                            .stroke(coordinator.selectedWhitelistFundCode == fund.schemeCode ? AppTheme.primary : Color.clear, lineWidth: 2)
                                    )
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
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
        .sheet(isPresented: $showAddSheet) {
            AddToWhitelistSheet(whitelistStore: store, fundsStore: fundsStore)
        }
        .alert("Remove Fund?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let fund = fundToDelete {
                    Task { _ = await store.removeFund(id: fund.id) }
                }
            }
        } message: {
            Text("This fund will be removed from your \(store.selectedYear) picks.")
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Portfolio Summary")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            HStack(spacing: AppTheme.Spacing.small) {
                metricTile(
                    label: "Total Funds",
                    value: "\(store.filteredFunds.count)",
                    color: AppTheme.primary
                )

                metricTile(
                    label: "Avg 1Y Return",
                    value: store.avgReturns1y.map { String(format: "%.1f%%", $0) } ?? "--",
                    color: returnsColor(store.avgReturns1y)
                )

                metricTile(
                    label: "Avg 3Y Return",
                    value: store.avgReturns3y.map { String(format: "%.1f%%", $0) } ?? "--",
                    color: returnsColor(store.avgReturns3y)
                )
            }

            // Category breakdown
            if !store.categoryBreakdown.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.categoryBreakdown, id: \.0) { cat, count in
                            Text("\(cat) (\(count))")
                                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.primary.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    private func metricTile(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.Typography.numeric(iPad ? 22 : 20))
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.availableYears, id: \.self) { year in
                    Button {
                        store.selectedYear = year
                    } label: {
                        Text("\(year)")
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                            .foregroundColor(store.selectedYear == year ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                store.selectedYear == year
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
        }
    }

    // MARK: - Fund Row

    private func fundRow(_ fund: WhitelistedFund) -> some View {
        Button {
            if sizeClass == .regular {
                coordinator.selectedWhitelistFundCode = fund.schemeCode
            }
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                Text(fund.schemeName)
                    .font(AppTheme.Typography.accent(iPad ? 18 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    if let cat = fund.schemeCategory {
                        Text(cat)
                            .font(AppTheme.Typography.label(iPad ? 13 : 10))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let risk = fund.riskLevel {
                        Text(risk)
                            .font(AppTheme.Typography.label(iPad ? 13 : 10))
                            .foregroundColor(AppTheme.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.warning.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let rating = fund.fundRating {
                        HStack(spacing: 1) {
                            Image(systemName: "star.fill")
                                .font(.system(size: iPad ? 11 : 8))
                            Text("\(rating)")
                                .font(AppTheme.Typography.label(iPad ? 13 : 10))
                        }
                        .foregroundColor(AppTheme.warning)
                    }
                }

                HStack {
                    if let r1y = fund.returns1y {
                        returnsBadge(label: "1Y", value: r1y)
                    }
                    if let r3y = fund.returns3y {
                        returnsBadge(label: "3Y", value: r3y)
                    }

                    Spacer()

                    Text("Added \(formatAddedDate(fund.addedAt))")
                        .font(AppTheme.Typography.label(iPad ? 13 : 10))
                        .foregroundColor(.secondary)
                }
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                fundToDelete = fund
                showDeleteConfirm = true
            } label: {
                Label("Remove from Picks", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                fundToDelete = fund
                showDeleteConfirm = true
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .background(
            Group {
                if sizeClass != .regular {
                    NavigationLink(value: fund.schemeCode) { EmptyView() }.opacity(0)
                }
            }
        )
        .navigationDestination(for: Int.self) { code in
            FundDetailView(schemeCode: code)
        }
    }

    private func returnsBadge(label: String, value: Double) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 12 : 9))
                .foregroundColor(.secondary)
            Text(String(format: "%+.1f%%", value))
                .font(AppTheme.Typography.accent(iPad ? 15 : 12))
                .foregroundColor(value >= 0 ? AppTheme.success : AppTheme.error)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer().frame(height: AppTheme.Spacing.xxLarge)

            Image(systemName: "star.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No picks for \(store.selectedYear)")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Curate your recommended fund list for the year")
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                    Text("Browse Funds")
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Toolbar

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Helpers

    private func returnsColor(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        return value >= 0 ? AppTheme.success : AppTheme.error
    }

    private func formatAddedDate(_ isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: isoDate) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM"
            return out.string(from: date)
        }
        return String(isoDate.prefix(10))
    }
}

// MARK: - Add to Whitelist Sheet

struct AddToWhitelistSheet: View {
    @ObservedObject var whitelistStore: WhitelistStore
    @ObservedObject var fundsStore: FundsStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var notes = ""
    @State private var isAdding: Int?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    TextField("Search funds to add...", text: $searchQuery)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            Task { await fundsStore.searchFunds(query: searchQuery) }
                        }

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            fundsStore.funds = []
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
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)

                // Results
                if fundsStore.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if fundsStore.funds.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    Text("No funds found")
                        .font(AppTheme.Typography.body(iPad ? 16 : 14))
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            ForEach(fundsStore.funds) { fund in
                                fundSearchRow(fund)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.top, AppTheme.Spacing.small)
                    }
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Add to My Picks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: searchQuery) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 3 else { return }
                Task { await fundsStore.searchFunds(query: trimmed) }
            }
        }
    }

    private func fundSearchRow(_ fund: FAFund) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fund.schemeName)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let cat = fund.schemeCategory {
                        Text(cat)
                            .font(AppTheme.Typography.label(iPad ? 11 : 9))
                            .foregroundColor(.secondary)
                    }
                    if let r1y = fund.returns1y {
                        Text(String(format: "1Y: %+.1f%%", r1y))
                            .font(AppTheme.Typography.label(iPad ? 11 : 9))
                            .foregroundColor(r1y >= 0 ? AppTheme.success : AppTheme.error)
                    }
                }
            }

            Spacer()

            if whitelistStore.isWhitelisted(schemeCode: fund.schemeCode) {
                Text("Added")
                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                    .foregroundColor(AppTheme.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.success.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Button {
                    addFund(fund)
                } label: {
                    if isAdding == fund.schemeCode {
                        ProgressView()
                            .frame(width: 60)
                    } else {
                        Text("Add")
                            .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Capsule())
                    }
                }
                .disabled(isAdding != nil)
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
    }

    private func addFund(_ fund: FAFund) {
        isAdding = fund.schemeCode
        Task {
            _ = await whitelistStore.addFund(
                schemeCode: fund.schemeCode,
                year: whitelistStore.selectedYear,
                notes: nil
            )
            isAdding = nil
        }
    }
}
