//
//  MarketOverviewCard.swift
//  SparrowInvest
//
//  Market indices overview card
//

import SwiftUI

struct MarketOverviewCard: View {
    let marketOverview: MarketOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Market Overview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                // Market Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(marketOverview.status.color)
                        .frame(width: 8, height: 8)
                    Text(marketOverview.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(marketOverview.status.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(marketOverview.status.color.opacity(0.1))
                )
            }

            // Primary Indices
            HStack(spacing: 16) {
                ForEach(marketOverview.primaryIndices) { index in
                    MarketIndexTile(index: index)
                }
            }

            // Other Indices (if any)
            if !marketOverview.otherIndices.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(marketOverview.otherIndices) { index in
                            CompactIndexTile(index: index)
                        }
                    }
                }
            }

            // Last Updated
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("Updated \(formatLastUpdated(marketOverview.lastUpdated))")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }

    private func formatLastUpdated(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MarketIndexTile: View {
    let index: MarketIndex

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(index.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            Text(index.formattedValue)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 4) {
                Image(systemName: index.isPositive ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text(index.formattedChange)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(index.isPositive ? AppTheme.success : AppTheme.error)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(index.isPositive ? AppTheme.success.opacity(0.08) : AppTheme.error.opacity(0.08))
        )
    }
}

struct CompactIndexTile: View {
    let index: MarketIndex

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(index.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: 4) {
                Text(String(format: "%.0f", index.value))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(index.isPositive ? "+" : "")\(String(format: "%.1f", index.changePercentage))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(index.isPositive ? AppTheme.success : AppTheme.error)
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
    MarketOverviewCard(marketOverview: .empty)
        .padding()
}
