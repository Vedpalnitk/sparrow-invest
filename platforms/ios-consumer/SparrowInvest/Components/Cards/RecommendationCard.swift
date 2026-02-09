//
//  RecommendationCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Recommendation Card
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: FundRecommendation
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Fund Avatar
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text(recommendation.fund.initials)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.fund.shortName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(recommendation.fund.assetClass.capitalized) • \(recommendation.fund.category)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Returns
                VStack(alignment: .trailing, spacing: 2) {
                    Text(recommendation.fund.returns?.threeYear?.percentFormatted ?? "N/A")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.green)
                    Text("3Y")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            // Reason
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text(recommendation.topReason)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Color.blue.opacity(0.08),
                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
            )

            // Action Button
            NavigationLink(destination: FundDetailView(fund: recommendation.fund)) {
                HStack {
                    Spacer()
                    Text("Invest")
                        .font(.system(size: 14, weight: .regular))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .regular))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                )
                .foregroundColor(.white)
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

#Preview {
    RecommendationCard(recommendation: FundRecommendation(
        id: "1",
        fund: Fund(
            id: "119598",
            schemeCode: 119598,
            schemeName: "Parag Parikh Flexi Cap Fund Direct Growth",
            category: "Flexi Cap",
            assetClass: "equity",
            nav: 78.45,
            navDate: Date(),
            returns: FundReturns(oneMonth: 2.5, threeMonth: 5.8, sixMonth: 12.3, oneYear: 22.4, threeYear: 18.7, fiveYear: 19.2),
            aum: 48520,
            expenseRatio: 0.63,
            riskRating: 4,
            minSIP: 1000,
            minLumpSum: 1000,
            fundManager: "Rajeev Thakkar",
            fundHouse: "PPFAS"
        ),
        score: 0.95,
        reasons: ["Excellent risk-adjusted returns", "Low expense ratio"],
        suggestedAllocation: 0.25
    ))
    .padding()
}
