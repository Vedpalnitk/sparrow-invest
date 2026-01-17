//
//  TaxSummaryCard.swift
//  SparrowInvest
//
//  Tax summary display card
//

import SwiftUI

struct TaxSummaryCard: View {
    let taxSummary: TaxSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(taxSummary.financialYear)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                NavigationLink(destination: Text("Tax Details")) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Capital Gains
            HStack(spacing: 12) {
                // LTCG
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("LTCG")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    Text(taxSummary.totalLTCG.currencyFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(taxSummary.totalLTCG >= 0 ? AppTheme.success : AppTheme.error)

                    Text("Tax: \(taxSummary.ltcgTaxLiability.currencyFormatted)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.success.opacity(0.08))
                )

                // STCG
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("STCG")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    Text(taxSummary.totalSTCG.currencyFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(taxSummary.totalSTCG >= 0 ? AppTheme.success : AppTheme.error)

                    Text("Tax: \(taxSummary.stcgTaxLiability.currencyFormatted)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.primary.opacity(0.08))
                )
            }

            // 80C ELSS Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("80C ELSS Investment")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Text("\(taxSummary.elssInvestment.compactCurrencyFormatted) / \(taxSummary.elss80CLimit.compactCurrencyFormatted)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.primary.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * taxSummary.elss80CProgress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Tax Saved: \(taxSummary.totalTaxSaved.currencyFormatted)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.success)

                    Spacer()

                    if taxSummary.elss80CRemaining > 0 {
                        Text("Remaining: \(taxSummary.elss80CRemaining.compactCurrencyFormatted)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.chipBackground)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    TaxSummaryCard(taxSummary: .empty)
        .padding()
}
