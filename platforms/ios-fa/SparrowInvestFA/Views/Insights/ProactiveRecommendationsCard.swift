import SwiftUI

// MARK: - Proactive Recommendations Card

struct ProactiveRecommendationsCard: View {
    let insights: FAInsights
    let onAskAvya: (String) -> Void
    let onViewClient: (String) -> Void

    @State private var isExpanded = true
    @Environment(\.colorScheme) private var colorScheme

    private var recommendations: [Recommendation] {
        var items: [Recommendation] = []

        // Priority clients: health score < 60
        for item in insights.portfolioHealth where item.score < 60 {
            items.append(Recommendation(
                type: .priority,
                clientId: item.clientId,
                text: "Review \(item.clientName)'s portfolio (Health: \(item.score)/100)",
                avyaQuery: "Analyze \(item.clientName)'s portfolio health issues and suggest improvements"
            ))
        }

        // SIP opportunities: goal alerts with RISK status
        for alert in insights.goalAlerts where alert.status.uppercased().contains("RISK") {
            items.append(Recommendation(
                type: .sip,
                clientId: alert.clientId,
                text: "Consider SIP for \(alert.clientName)'s \(alert.goalName)",
                avyaQuery: "Suggest SIP options for \(alert.clientName)'s \(alert.goalName) goal"
            ))
        }

        // Tax opportunities
        for opp in insights.taxHarvesting {
            items.append(Recommendation(
                type: .tax,
                clientId: opp.clientId,
                text: "Tax saving: \(opp.potentialSavings.formattedCurrency) available for \(opp.clientName)",
                avyaQuery: "Explain tax harvesting opportunity for \(opp.clientName) in \(opp.fundName)"
            ))
        }

        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            DisclosureGroup(isExpanded: $isExpanded) {
                if recommendations.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: AppTheme.Spacing.small) {
                        ForEach(recommendations) { rec in
                            recommendationRow(rec)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.small)
                }
            } label: {
                headerLabel
            }
            .tint(.secondary)
        }
        .glassCard()
    }

    // MARK: - Header

    private var headerLabel: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ZStack {
                Circle()
                    .fill(
                        AppTheme.avyaBubbleGradient
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: "sparkles")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }

            Text("AVYA RECOMMENDS")
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.primary)

            if !recommendations.isEmpty {
                Text("\(recommendations.count)")
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(AppTheme.error))
            }

            Spacer()
        }
    }

    // MARK: - Recommendation Row

    private func recommendationRow(_ rec: Recommendation) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
            Image(systemName: rec.type.icon)
                .font(.system(size: 14))
                .foregroundColor(rec.type.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(rec.text)
                    .font(AppTheme.Typography.accent(13))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: AppTheme.Spacing.small) {
                    Button {
                        onViewClient(rec.clientId)
                    } label: {
                        Text("View Client")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, AppTheme.Spacing.compact)
                            .padding(.vertical, AppTheme.Spacing.micro)
                            .background(
                                Capsule()
                                    .stroke(AppTheme.primary.opacity(0.4), lineWidth: 1)
                            )
                    }

                    Button {
                        onAskAvya(rec.avyaQuery)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                            Text("Ask Avya")
                                .font(AppTheme.Typography.label(11))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.compact)
                        .padding(.vertical, AppTheme.Spacing.micro)
                        .background(
                            Capsule().fill(AppTheme.avyaBubbleGradient)
                        )
                    }
                }
            }
        }
        .listItemCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.success)

            Text("All clear! No urgent recommendations.")
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.medium)
    }
}

// MARK: - Recommendation Model

private struct Recommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let clientId: String
    let text: String
    let avyaQuery: String
}

private enum RecommendationType {
    case priority
    case sip
    case tax

    var icon: String {
        switch self {
        case .priority: return "exclamationmark.triangle"
        case .sip: return "arrow.triangle.2.circlepath"
        case .tax: return "indianrupeesign.circle"
        }
    }

    var color: Color {
        switch self {
        case .priority: return AppTheme.error
        case .sip: return AppTheme.primary
        case .tax: return AppTheme.success
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleInsights = FAInsights(
        portfolioHealth: [
            PortfolioHealthItem(clientId: "1", clientName: "Priya Patel", score: 45, issues: ["High concentration"], recommendations: ["Diversify"])
        ],
        rebalancingAlerts: [],
        taxHarvesting: [
            TaxHarvestingOpportunity(clientId: "2", clientName: "Rajesh Sharma", fundName: "HDFC Mid Cap", unrealizedLoss: 15000, potentialSavings: 4500)
        ],
        goalAlerts: [
            GoalAlert(clientId: "1", clientName: "Priya Patel", goalName: "Retirement", status: "AT_RISK", message: "Behind target")
        ],
        marketInsights: []
    )

    ScrollView {
        ProactiveRecommendationsCard(
            insights: sampleInsights,
            onAskAvya: { _ in },
            onViewClient: { _ in }
        )
        .padding()
    }
}
