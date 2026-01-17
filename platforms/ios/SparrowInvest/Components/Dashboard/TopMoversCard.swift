//
//  TopMoversCard.swift
//  SparrowInvest
//
//  Top gainers and losers display
//

import SwiftUI

struct TopMoversCard: View {
    let gainers: [Holding]
    let losers: [Holding]

    @State private var selectedTab: MoverTab = .gainers

    enum MoverTab: String, CaseIterable {
        case gainers = "Top Gainers"
        case losers = "Top Losers"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Tab Toggle
            HStack {
                Text("Today's Movers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()
            }

            // Tab Toggle
            HStack(spacing: 0) {
                ForEach(MoverTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .white : AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab ?
                                AnyView(
                                    Capsule()
                                        .fill(tab == .gainers ? AppTheme.success : AppTheme.error)
                                ) : AnyView(Color.clear)
                            )
                    }
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(AppTheme.chipBackground)
            )

            // Holdings List
            let holdings = selectedTab == .gainers ? gainers : losers

            if holdings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: selectedTab == .gainers ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textTertiary)
                    Text(selectedTab == .gainers ? "No gainers today" : "No losers today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(holdings.prefix(3)) { holding in
                        MoverRow(holding: holding, isGainer: selectedTab == .gainers)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

struct MoverRow: View {
    let holding: Holding
    let isGainer: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Fund Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(holding.assetClass.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text(String(holding.fundName.prefix(2)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(holding.assetClass.color)
            }

            // Fund Info
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.fundName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(holding.assetClass.rawValue.capitalized)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Change
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.dayChange.currencyFormatted)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isGainer ? AppTheme.success : AppTheme.error)

                HStack(spacing: 2) {
                    Image(systemName: isGainer ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text(holding.dayChangePercentage.percentFormatted)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(isGainer ? AppTheme.success : AppTheme.error)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.chipBackground)
        )
    }
}

#Preview {
    TopMoversCard(gainers: [], losers: [])
        .padding()
}
