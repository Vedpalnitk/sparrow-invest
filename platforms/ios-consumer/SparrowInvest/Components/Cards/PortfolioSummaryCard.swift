//
//  PortfolioSummaryCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Portfolio Summary Card
//

import SwiftUI

struct PortfolioSummaryCard: View {
    let portfolio: Portfolio
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Text("YOUR PORTFOLIO")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .tracking(1)
                Spacer()
            }

            // Main Value
            VStack(alignment: .leading, spacing: 4) {
                Text(portfolio.totalValue.currencyFormatted)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: portfolio.totalReturns >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(portfolio.totalReturns.currencyFormatted)
                    }
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(portfolio.totalReturns >= 0 ? .green : .red)

                    Text("(\(portfolio.returnsPercentage.percentFormatted)) all time")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Today's Change
            HStack {
                Text("Today")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: portfolio.todayChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .regular))
                    Text("\(portfolio.todayChange.currencyFormatted) (\(portfolio.todayChangePercentage.percentFormatted))")
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundColor(portfolio.todayChange >= 0 ? .green : .red)
            }
        }
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
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
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
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

#Preview {
    PortfolioSummaryCard(portfolio: Portfolio(
        totalValue: 245680,
        totalInvested: 233230,
        totalReturns: 12450,
        returnsPercentage: 5.34,
        todayChange: 890,
        todayChangePercentage: 0.36,
        xirr: 14.2,
        assetAllocation: AssetAllocation(equity: 72, debt: 18, hybrid: 7, gold: 3),
        holdings: []
    ))
    .padding()
}
