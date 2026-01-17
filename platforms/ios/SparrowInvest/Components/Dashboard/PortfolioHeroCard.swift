//
//  PortfolioHeroCard.swift
//  SparrowInvest
//
//  Main portfolio summary hero card
//

import SwiftUI

struct PortfolioHeroCard: View {
    let portfolio: Portfolio
    @Binding var viewMode: PortfolioViewMode
    var familyPortfolio: FamilyPortfolio?

    private var currentValue: Double {
        viewMode == .family ? (familyPortfolio?.totalValue ?? portfolio.currentValue) : portfolio.currentValue
    }

    private var investedValue: Double {
        viewMode == .family ? (familyPortfolio?.totalInvested ?? portfolio.totalInvested) : portfolio.totalInvested
    }

    private var returns: Double {
        viewMode == .family ? (familyPortfolio?.totalReturns ?? portfolio.totalReturns) : portfolio.totalReturns
    }

    private var returnsPercentage: Double {
        viewMode == .family ? (familyPortfolio?.returnsPercentage ?? portfolio.absoluteReturnsPercentage) : portfolio.absoluteReturnsPercentage
    }

    private var xirrValue: Double {
        viewMode == .family ? (familyPortfolio?.familyXIRR ?? portfolio.xirr ?? 0) : (portfolio.xirr ?? 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            // View Mode Toggle
            viewModeToggle

            // Main Value Display
            VStack(spacing: 8) {
                Text("Total Portfolio Value")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                Text(currentValue.currencyFormatted)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                // Day Change (mock for now)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                    Text("+₹2,450 (0.2%) today")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppTheme.success)
            }

            // Returns Summary
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Invested")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(investedValue.currencyFormatted)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 32)

                VStack(spacing: 4) {
                    Text("Returns")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    HStack(spacing: 4) {
                        Text(returns.currencyFormatted)
                            .font(.system(size: 15, weight: .semibold))
                        Text("(\(returnsPercentage.percentFormatted))")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(returns >= 0 ? AppTheme.success : AppTheme.error)
                }

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 32)

                VStack(spacing: 4) {
                    Text("XIRR")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(xirrValue.percentFormatted)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(xirrValue >= 0 ? AppTheme.success : AppTheme.error)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 12, x: 0, y: 4)
        )
    }

    private var viewModeToggle: some View {
        HStack(spacing: 0) {
            ForEach(PortfolioViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(viewMode == mode ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewMode == mode ?
                            AnyView(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.primaryDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            ) : AnyView(Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(AppTheme.chipBackground)
        )
    }
}

#Preview {
    PortfolioHeroCard(
        portfolio: .empty,
        viewMode: .constant(.individual)
    )
    .padding()
}
