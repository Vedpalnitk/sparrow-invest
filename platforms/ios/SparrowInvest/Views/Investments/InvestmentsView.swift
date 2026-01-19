//
//  InvestmentsView.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass - Tabbed Investments View
//

import SwiftUI

// MARK: - Investment Tab Enum

enum InvestmentTab: String, CaseIterable {
    case portfolio = "Portfolio"
    case sips = "SIPs"
    case transactions = "Transactions"
}

// MARK: - Portfolio Option for Selector

struct PortfolioOption: Identifiable, Hashable {
    let id: String
    let name: String
    let value: Double

    static let mockPortfolios: [PortfolioOption] = [
        PortfolioOption(id: "1", name: "My Portfolio", value: 245680),
        PortfolioOption(id: "2", name: "Wife's Portfolio", value: 189450),
        PortfolioOption(id: "3", name: "Kids Education", value: 85000),
        PortfolioOption(id: "4", name: "Retirement Fund", value: 520000)
    ]
}

// MARK: - Main View

struct InvestmentsView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @EnvironmentObject var fundsStore: FundsStore
    @State private var selectedTab: InvestmentTab = .portfolio
    @State private var selectedPortfolio: PortfolioOption = PortfolioOption.mockPortfolios[0]
    @State private var showPortfolioPicker = false
    @State private var selectedFilter: Holding.AssetClass? = nil

    var filteredHoldings: [Holding] {
        if let filter = selectedFilter {
            return portfolioStore.holdings.filter { $0.assetClass == filter }
        }
        return portfolioStore.holdings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Portfolio Selector
                PortfolioSelectorButton(
                    selectedPortfolio: selectedPortfolio,
                    onTap: { showPortfolioPicker = true }
                )
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)

                // Tab Selector
                InvestmentTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.top, AppTheme.Spacing.medium)

                // Tab Content
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.large) {
                        switch selectedTab {
                        case .portfolio:
                            PortfolioTabContent(
                                portfolio: portfolioStore.portfolio,
                                holdings: filteredHoldings,
                                selectedFilter: $selectedFilter
                            )
                        case .sips:
                            SIPsTabContent(sips: portfolioStore.activeSIPs)
                        case .transactions:
                            TransactionsTabContent(transactions: portfolioStore.transactions)
                        }
                    }
                    .padding(AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.xxLarge)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Investments")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await portfolioStore.fetchPortfolio()
            }
            .sheet(isPresented: $showPortfolioPicker) {
                PortfolioPickerSheet(
                    portfolios: PortfolioOption.mockPortfolios,
                    selectedPortfolio: $selectedPortfolio,
                    isPresented: $showPortfolioPicker
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Portfolio Selector Button

struct PortfolioSelectorButton: View {
    let selectedPortfolio: PortfolioOption
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VIEWING")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .tracking(1)

                    Text(selectedPortfolio.name)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text(selectedPortfolio.value.currencyFormatted)
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundColor(.blue)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.compact)
            .background(selectorBackground)
            .overlay(selectorBorder)
            .shadow(color: selectorShadow, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var selectorShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.06)
    }

    @ViewBuilder
    private var selectorBackground: some View {
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

    private var selectorBorder: some View {
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

// MARK: - Investment Tab Selector

struct InvestmentTabSelector: View {
    @Binding var selectedTab: InvestmentTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InvestmentTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .regular : .light))
                            .foregroundColor(selectedTab == tab ? .blue : .secondary)

                        // Indicator
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .background(tabBackground)
        .overlay(tabBorder)
        .shadow(color: tabShadow, radius: 8, x: 0, y: 2)
    }

    private var tabShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var tabBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var tabBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Portfolio Tab Content

struct PortfolioTabContent: View {
    let portfolio: Portfolio
    let holdings: [Holding]
    @Binding var selectedFilter: Holding.AssetClass?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // Portfolio Summary Card
            InvestmentSummaryCard(portfolio: portfolio)

            // Asset Filter Pills
            AssetFilterPills(selectedFilter: $selectedFilter)

            // Holdings List
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                HStack {
                    Text("HOLDINGS")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.blue)
                        .tracking(1)

                    Spacer()

                    Text("\(holdings.count) funds")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                if holdings.isEmpty {
                    EmptyHoldingsView()
                } else {
                    ForEach(holdings) { holding in
                        NavigationLink(destination: FundDetailView(fund: holding.toFund())) {
                            HoldingCard(holding: holding)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - SIPs Tab Content

struct SIPsTabContent: View {
    let sips: [SIP]

    private var totalMonthlyAmount: Double {
        sips.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }

    private var activeSIPsCount: Int {
        sips.filter { $0.isActive }.count
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // SIP Summary
            VStack(spacing: AppTheme.Spacing.medium) {
                HStack(spacing: AppTheme.Spacing.medium) {
                    SIPStatCard(
                        title: "Active SIPs",
                        value: "\(activeSIPsCount)",
                        icon: "repeat.circle.fill",
                        color: .green
                    )

                    SIPStatCard(
                        title: "Monthly",
                        value: totalMonthlyAmount.currencyFormatted,
                        icon: "calendar",
                        color: .blue
                    )
                }
            }

            // SIP List
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                Text("YOUR SIPS")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .tracking(1)

                if sips.isEmpty {
                    InvestmentsEmptySIPsView()
                } else {
                    ForEach(sips) { sip in
                        InvestmentSIPCard(sip: sip)
                    }
                }
            }

            // Start New SIP Button
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .light))
                    Text("Start New SIP")
                        .font(.system(size: 14, weight: .regular))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                )
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - SIP Stat Card

struct SIPStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .light, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var cardBorder: some View {
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

// MARK: - Investment SIP Card

struct InvestmentSIPCard: View {
    let sip: SIP
    @Environment(\.colorScheme) private var colorScheme

    private var nextDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: sip.nextDate)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
                // Fund Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sip.fundName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(sip.frequency.rawValue.capitalized) • \(sip.sipCount) installments")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(sip.amount.currencyFormatted)
                        .font(.system(size: 14, weight: .light, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Next: \(nextDateFormatted)")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.blue)
                }
            }

            // Status Badge
            HStack {
                Spacer()

                Text(sip.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(sip.isActive ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(sip.isActive ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                    )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(sipCardBackground)
        .overlay(sipCardBorder)
        .shadow(color: sipCardShadow, radius: 12, x: 0, y: 4)
    }

    private var sipCardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var sipCardBackground: some View {
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

    private var sipCardBorder: some View {
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

// MARK: - Transactions Tab Content

struct TransactionsTabContent: View {
    let transactions: [Transaction]

    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: transactions) { transaction in
            formatter.string(from: transaction.date)
        }

        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            if transactions.isEmpty {
                EmptyTransactionsView()
            } else {
                ForEach(groupedTransactions, id: \.0) { month, monthTransactions in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                        Text(month.uppercased())
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.blue)
                            .tracking(1)

                        ForEach(monthTransactions) { transaction in
                            TransactionCard(transaction: transaction)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Card

struct TransactionCard: View {
    let transaction: Transaction
    @Environment(\.colorScheme) private var colorScheme

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: transaction.date)
    }

    private var typeIcon: String {
        switch transaction.type {
        case .purchase, .sipInstallment:
            return "arrow.down.circle.fill"
        case .redemption:
            return "arrow.up.circle.fill"
        case .switchIn:
            return "arrow.right.circle.fill"
        case .switchOut:
            return "arrow.left.circle.fill"
        case .dividend:
            return "indianrupeesign.circle.fill"
        }
    }

    private var typeColor: Color {
        switch transaction.type {
        case .purchase, .sipInstallment, .dividend, .switchIn:
            return .green
        case .redemption, .switchOut:
            return .orange
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(typeColor.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: typeIcon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(typeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.fundName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(transaction.type.displayName)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(typeColor)

                    Text("•")
                        .foregroundColor(Color(uiColor: .tertiaryLabel))

                    Text(dateFormatted)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.type == .redemption ? "-\(transaction.amount.currencyFormatted)" : "+\(transaction.amount.currencyFormatted)")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundColor(transaction.type == .redemption ? .orange : .green)

                if transaction.units > 0 {
                    Text("\(String(format: "%.2f", transaction.units)) units")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(txCardBackground)
        .overlay(txCardBorder)
        .shadow(color: txCardShadow, radius: 12, x: 0, y: 4)
    }

    private var txCardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var txCardBackground: some View {
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

    private var txCardBorder: some View {
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

// MARK: - Portfolio Picker Sheet

struct PortfolioPickerSheet: View {
    let portfolios: [PortfolioOption]
    @Binding var selectedPortfolio: PortfolioOption
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(portfolios) { portfolio in
                    Button(action: {
                        selectedPortfolio = portfolio
                        isPresented = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(portfolio.name)
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(.primary)

                                Text(portfolio.value.currencyFormatted)
                                    .font(.system(size: 14, weight: .light, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedPortfolio.id == portfolio.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .regular))
                }
            }
        }
    }
}

// MARK: - Empty States

struct InvestmentsEmptySIPsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            Text("No active SIPs")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)

            Text("Start a SIP to build wealth systematically")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(emptySIPBackground)
        .overlay(emptySIPBorder)
        .shadow(color: emptySIPShadow, radius: 12, x: 0, y: 4)
    }

    private var emptySIPShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var emptySIPBackground: some View {
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

    private var emptySIPBorder: some View {
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

struct EmptyTransactionsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            Text("No transactions yet")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)

            Text("Your transaction history will appear here")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(emptyTxBackground)
        .overlay(emptyTxBorder)
        .shadow(color: emptyTxShadow, radius: 12, x: 0, y: 4)
    }

    private var emptyTxShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var emptyTxBackground: some View {
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

    private var emptyTxBorder: some View {
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

// MARK: - Existing Components (Updated)

struct InvestmentSummaryCard: View {
    let portfolio: Portfolio
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Current Value
            VStack(spacing: 4) {
                Text("Current Value")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)

                Text(portfolio.totalValue.currencyFormatted)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: portfolio.totalReturns >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .regular))
                    Text("\(portfolio.totalReturns.currencyFormatted) (\(portfolio.returnsPercentage.percentFormatted))")
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundColor(portfolio.totalReturns >= 0 ? .green : .red)
            }

            Divider()

            // Stats Row
            HStack(spacing: 0) {
                StatItem(title: "Invested", value: portfolio.totalInvested.currencyFormatted)
                Divider().frame(height: 40)
                StatItem(title: "Today", value: portfolio.todayChange >= 0 ? "+\(portfolio.todayChange.currencyFormatted)" : portfolio.todayChange.currencyFormatted, color: portfolio.todayChange >= 0 ? .green : .red)
                Divider().frame(height: 40)
                StatItem(title: "XIRR", value: "\((portfolio.xirr ?? 0).percentFormatted)", color: .blue)
            }
        }
        .padding(AppTheme.Spacing.large)
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

struct StatItem: View {
    let title: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AssetFilterPills: View {
    @Binding var selectedFilter: Holding.AssetClass?

    let filters: [(Holding.AssetClass?, String)] = [
        (nil, "All"),
        (.equity, "Equity"),
        (.debt, "Debt"),
        (.hybrid, "Hybrid"),
        (.gold, "Gold")
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters, id: \.1) { filter in
                    FilterPill(
                        title: filter.1,
                        isSelected: selectedFilter == filter.0,
                        action: { selectedFilter = filter.0 }
                    )
                }
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .light))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(pillBackground)
                .overlay(pillBorder)
                .shadow(color: pillShadow, radius: 6, x: 0, y: 2)
        }
    }

    private var pillShadow: Color {
        if isSelected { return .clear }
        return colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            Capsule().fill(Color.blue)
        } else if colorScheme == .dark {
            Capsule()
                .fill(Color.black.opacity(0.4))
                .background(Capsule().fill(.ultraThinMaterial))
        } else {
            Capsule().fill(Color.white)
        }
    }

    @ViewBuilder
    private var pillBorder: some View {
        if isSelected {
            Capsule().stroke(Color.clear, lineWidth: 0)
        } else {
            Capsule()
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
                                .init(color: .black.opacity(0.1), location: 0),
                                .init(color: .black.opacity(0.05), location: 0.3),
                                .init(color: .black.opacity(0.03), location: 0.7),
                                .init(color: .black.opacity(0.07), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ),
                    lineWidth: 1
                )
        }
    }
}

struct HoldingCard: View {
    let holding: Holding
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
                // Fund Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(holding.assetClass.color.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(holding.fundName.prefix(2).uppercased())
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(holding.assetClass.color)
                }

                // Fund Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.fundName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(holding.category)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(Color(uiColor: .tertiaryLabel))

                        Text(holding.assetClass.rawValue.capitalized)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(holding.assetClass.color)
                    }
                }

                Spacer()

                // Returns
                VStack(alignment: .trailing, spacing: 4) {
                    Text(holding.currentValue.currencyFormatted)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.primary)

                    HStack(spacing: 2) {
                        Image(systemName: holding.returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .regular))
                        Text(holding.returnsPercentage.percentFormatted)
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(holding.returns >= 0 ? .green : .red)
                }

                // Navigation indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }

            // Progress bar showing allocation
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(holding.assetClass.color.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(holding.assetClass.color)
                        .frame(width: geo.size.width * 0.3, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(AppTheme.Spacing.medium)
        .background(holdingCardBackground)
        .overlay(holdingCardBorder)
        .shadow(color: holdingCardShadow, radius: 12, x: 0, y: 4)
    }

    private var holdingCardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var holdingCardBackground: some View {
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

    private var holdingCardBorder: some View {
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

struct EmptyHoldingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            Text("No holdings found")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)

            Text("Start investing to build your portfolio")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(emptyHoldingsBackground)
        .overlay(emptyHoldingsBorder)
        .shadow(color: emptyHoldingsShadow, radius: 12, x: 0, y: 4)
    }

    private var emptyHoldingsShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var emptyHoldingsBackground: some View {
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

    private var emptyHoldingsBorder: some View {
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

// MARK: - Preview

#Preview {
    InvestmentsView()
        .environmentObject(PortfolioStore())
        .environmentObject(FundsStore())
}
