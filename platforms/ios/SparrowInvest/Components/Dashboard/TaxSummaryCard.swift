//
//  TaxSummaryCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Tax Summary Card
//

import SwiftUI

struct TaxSummaryCard: View {
    let taxSummary: TaxSummary
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Summary")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    Text(taxSummary.financialYear)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink(destination: Text("Tax Details")) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 13, weight: .light))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
            }

            // Capital Gains
            HStack(spacing: AppTheme.Spacing.compact) {
                // LTCG
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("LTCG")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    Text(taxSummary.totalLTCG.currencyFormatted)
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(taxSummary.totalLTCG >= 0 ? .green : .red)

                    Text("Tax: \(taxSummary.ltcgTaxLiability.currencyFormatted)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.compact)
                .background(
                    Color.green.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                )

                // STCG
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("STCG")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                    Text(taxSummary.totalSTCG.currencyFormatted)
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(taxSummary.totalSTCG >= 0 ? .green : .red)

                    Text("Tax: \(taxSummary.stcgTaxLiability.currencyFormatted)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.compact)
                .background(
                    Color.blue.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                )
            }

            // 80C ELSS Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("80C ELSS Investment")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(taxSummary.elssInvestment.compactCurrencyFormatted) / \(taxSummary.elss80CLimit.compactCurrencyFormatted)")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
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
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.green)

                    Spacer()

                    if taxSummary.elss80CRemaining > 0 {
                        Text("Remaining: \(taxSummary.elss80CRemaining.compactCurrencyFormatted)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.compact)
            .background(elssBackground)
            .overlay(elssBorder)
            .shadow(color: elssShadow, radius: 8, x: 0, y: 2)
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
                            .init(color: .black.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    // MARK: - ELSS Section Styling

    private var elssShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var elssBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var elssBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.25), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.12), location: 0),
                            .init(color: .black.opacity(0.06), location: 0.5),
                            .init(color: .black.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

#Preview {
    TaxSummaryCard(taxSummary: .empty)
        .padding()
}
