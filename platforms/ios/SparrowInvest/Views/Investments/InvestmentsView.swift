//
//  InvestmentsView.swift
//  SparrowInvest
//
//  Portfolio holdings and investments overview
//

import SwiftUI

struct InvestmentsView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @State private var selectedFilter: Holding.AssetClass? = nil

    var filteredHoldings: [Holding] {
        if let filter = selectedFilter {
            return portfolioStore.holdings.filter { $0.assetClass == filter }
        }
        return portfolioStore.holdings
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Summary Card
                    InvestmentSummaryCard(portfolio: portfolioStore.portfolio)

                    // Asset Filter Pills
                    AssetFilterPills(selectedFilter: $selectedFilter)

                    // Holdings List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("HOLDINGS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primary)
                                .tracking(1)

                            Spacer()

                            Text("\(filteredHoldings.count) funds")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        if filteredHoldings.isEmpty {
                            EmptyHoldingsView()
                        } else {
                            ForEach(filteredHoldings) { holding in
                                HoldingCard(holding: holding)
                            }
                        }
                    }

                    // Quick Actions
                    QuickActionsSection()
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Investments")
            .refreshable {
                await portfolioStore.fetchPortfolio()
            }
        }
    }
}

// MARK: - Portfolio Summary Card

struct InvestmentSummaryCard: View {
    let portfolio: Portfolio

    var body: some View {
        VStack(spacing: 16) {
            // Current Value
            VStack(spacing: 4) {
                Text("Current Value")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)

                Text(portfolio.totalValue.currencyFormatted)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: portfolio.totalReturns >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text("\(portfolio.totalReturns.currencyFormatted) (\(portfolio.returnsPercentage.percentFormatted))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(portfolio.totalReturns >= 0 ? AppTheme.success : AppTheme.error)
            }

            Divider()

            // Stats Row
            HStack(spacing: 0) {
                StatItem(title: "Invested", value: portfolio.totalInvested.currencyFormatted)
                Divider().frame(height: 40)
                StatItem(title: "Today", value: portfolio.todayChange >= 0 ? "+\(portfolio.todayChange.currencyFormatted)" : portfolio.todayChange.currencyFormatted, color: portfolio.todayChange >= 0 ? AppTheme.success : AppTheme.error)
                Divider().frame(height: 40)
                StatItem(title: "XIRR", value: "\((portfolio.xirr ?? 0).percentFormatted)", color: AppTheme.primary)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    var color: Color = AppTheme.textPrimary

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Asset Filter Pills

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

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primary : AppTheme.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Holding Card

struct HoldingCard: View {
    let holding: Holding

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Fund Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(holding.assetClass.color.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(holding.fundName.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(holding.assetClass.color)
                }

                // Fund Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(holding.fundName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(holding.category)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)

                        Text("•")
                            .foregroundColor(AppTheme.textTertiary)

                        Text(holding.assetClass.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(holding.assetClass.color)
                    }
                }

                Spacer()

                // Returns
                VStack(alignment: .trailing, spacing: 4) {
                    Text(holding.currentValue.currencyFormatted)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    HStack(spacing: 2) {
                        Image(systemName: holding.returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(holding.returnsPercentage.percentFormatted)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(holding.returns >= 0 ? AppTheme.success : AppTheme.error)
                }
            }

            // Progress bar showing allocation
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.progressBackground)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(holding.assetClass.color)
                        .frame(width: geo.size.width * 0.3, height: 4) // Mock allocation %
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty Holdings View

struct EmptyHoldingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)

            Text("No holdings found")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)

            Text("Start investing to build your portfolio")
                .font(.subheadline)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primary)
                .tracking(1)

            HStack(spacing: 12) {
                QuickActionButton(icon: "plus.circle.fill", title: "Add Funds", color: AppTheme.primary)
                QuickActionButton(icon: "arrow.up.circle.fill", title: "Withdraw", color: AppTheme.warning)
                QuickActionButton(icon: "arrow.triangle.2.circlepath", title: "Switch", color: AppTheme.secondary)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    InvestmentsView()
        .environmentObject(PortfolioStore())
}
