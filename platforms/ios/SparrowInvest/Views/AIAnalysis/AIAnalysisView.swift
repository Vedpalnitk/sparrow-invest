//
//  InsightsView.swift (formerly AIAnalysisView)
//  SparrowInvest
//
//  AI-powered portfolio analysis, recommendations and insights
//

import SwiftUI

struct AIAnalysisView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @EnvironmentObject var fundsStore: FundsStore
    @State private var isAnalyzing = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // AI Header
                    AIHeaderCard(isAnalyzing: $isAnalyzing)

                    // AI Recommendations Section (moved from Explore)
                    AIRecommendationsSection()

                    // Analysis Tabs
                    Picker("Analysis", selection: $selectedTab) {
                        Text("Analysis").tag(0)
                        Text("Optimize").tag(1)
                        Text("Alerts").tag(2)
                    }
                    .pickerStyle(.segmented)

                    // Content based on tab
                    switch selectedTab {
                    case 0:
                        InsightsSection()
                    case 1:
                        OptimizationSection()
                    case 2:
                        AlertsSection()
                    default:
                        EmptyView()
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Insights")
        }
    }
}

// MARK: - AI Recommendations (moved from ExploreView)

struct AIRecommendationsSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.blue)
                Text("AI RECOMMENDATIONS")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .tracking(1)
            }

            Text("Personalized picks based on your profile")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.compact) {
                    ForEach(0..<5, id: \.self) { _ in
                        RecommendedFundCard()
                    }
                }
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

struct RecommendedFundCard: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("PP")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.blue)
                    )
                Spacer()
                Image(systemName: "heart")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }

            Text("Parag Parikh Flexi Cap Fund")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(2)

            Text("Equity - Flexi Cap")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("3Y Returns")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    Text("+18.7%")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.green)
                }
                Spacer()
                Button(action: {}) {
                    Text("Invest")
                        .font(.system(size: 12, weight: .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                        .foregroundColor(.white)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(width: 180)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
        )
    }
}

// MARK: - AI Header Card

struct AIHeaderCard: View {
    @Binding var isAnalyzing: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.compact) {
                // AI Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sparrow AI")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    Text("Your intelligent portfolio assistant")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1), in: Capsule())
            }

            // Last Analysis
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                Text("Last analyzed: 2 hours ago")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))

                Spacer()

                Button(action: { isAnalyzing = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .light))
                        Text("Refresh")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
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

// MARK: - Insights Section

struct InsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("KEY INSIGHTS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            // Portfolio Health Score
            HealthScoreCard(score: 78)

            // Insight Cards
            InsightCard(
                icon: "chart.pie.fill",
                title: "Diversification",
                message: "Your portfolio is well-diversified across 3 asset classes. Consider adding international exposure.",
                type: .positive
            )

            InsightCard(
                icon: "arrow.up.right.circle.fill",
                title: "Performance",
                message: "Your portfolio has outperformed the benchmark by 2.3% in the last year.",
                type: .positive
            )

            InsightCard(
                icon: "exclamationmark.triangle.fill",
                title: "Risk Alert",
                message: "Mid-cap allocation is 5% above your risk profile recommendation.",
                type: .warning
            )

            InsightCard(
                icon: "lightbulb.fill",
                title: "Tax Optimization",
                message: "You can save up to ₹15,000 in taxes by investing in ELSS before March.",
                type: .info
            )
        }
    }
}

// MARK: - Health Score Card

struct HealthScoreCard: View {
    let score: Int
    @Environment(\.colorScheme) private var colorScheme

    var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var scoreLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Attention"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            // Score Ring
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 22, weight: .light, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("/ 100")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Portfolio Health")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Text(scoreLabel)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(scoreColor)

                Text("Based on diversification, risk, and returns")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.large)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
        )
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    let type: InsightType
    @Environment(\.colorScheme) private var colorScheme

    enum InsightType {
        case positive, warning, info

        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
        )
    }
}

// MARK: - Optimization Section

struct OptimizationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("OPTIMIZATION SUGGESTIONS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            OptimizationCard(
                title: "Rebalance Portfolio",
                description: "Your equity allocation has drifted 5% from target. Rebalance to maintain your risk profile.",
                action: "Rebalance Now",
                impact: "Reduce risk by 12%"
            )

            OptimizationCard(
                title: "Tax Loss Harvesting",
                description: "Sell underperforming funds to offset capital gains and save on taxes.",
                action: "View Opportunities",
                impact: "Save up to ₹8,500"
            )

            OptimizationCard(
                title: "SIP Top-up",
                description: "Increase your SIP by 10% annually to reach your goals faster.",
                action: "Increase SIP",
                impact: "Reach goals 2 years earlier"
            )
        }
    }
}

struct OptimizationCard: View {
    let title: String
    let description: String
    let action: String
    let impact: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)

            Text(description)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.secondary)

            HStack {
                // Impact badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .light))
                    Text(impact)
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1), in: Capsule())

                Spacer()

                Button(action: {}) {
                    Text(action)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
        )
    }
}

// MARK: - Alerts Section

struct AlertsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("ACTIVE ALERTS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            AlertCard(
                icon: "bell.badge.fill",
                title: "SIP Due Tomorrow",
                message: "₹10,000 SIP for Parag Parikh Flexi Cap is due tomorrow",
                time: "1 day",
                type: .info
            )

            AlertCard(
                icon: "chart.line.downtrend.xyaxis",
                title: "Fund Underperforming",
                message: "HDFC Mid-Cap has underperformed its benchmark for 3 consecutive quarters",
                time: "Review needed",
                type: .warning
            )

            AlertCard(
                icon: "calendar.badge.exclamationmark",
                title: "Goal Deadline Approaching",
                message: "Your 'Home Down Payment' goal is 3 months away with 62% progress",
                time: "3 months",
                type: .warning
            )
        }
    }
}

struct AlertCard: View {
    let icon: String
    let title: String
    let message: String
    let time: String
    let type: AlertType
    @Environment(\.colorScheme) private var colorScheme

    enum AlertType {
        case info, warning, critical

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(time)
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }

                Text(message)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? type.color.opacity(0.4)
                        : type.color.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    AIAnalysisView()
        .environmentObject(PortfolioStore())
        .environmentObject(FundsStore())
}
