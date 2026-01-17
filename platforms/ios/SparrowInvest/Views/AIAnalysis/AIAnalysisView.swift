//
//  AIAnalysisView.swift
//  SparrowInvest
//
//  AI-powered portfolio analysis and recommendations
//

import SwiftUI

struct AIAnalysisView: View {
    @EnvironmentObject var portfolioStore: PortfolioStore
    @State private var isAnalyzing = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Analysis Header
                    AIHeaderCard(isAnalyzing: $isAnalyzing)

                    // Analysis Tabs
                    Picker("Analysis", selection: $selectedTab) {
                        Text("Insights").tag(0)
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
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("AI Analysis")
        }
    }
}

// MARK: - AI Header Card

struct AIHeaderCard: View {
    @Binding var isAnalyzing: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // AI Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sparrow AI")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Your intelligent portfolio assistant")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(AppTheme.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.success.opacity(0.1))
                .cornerRadius(12)
            }

            // Last Analysis
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                Text("Last analyzed: 2 hours ago")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)

                Spacer()

                Button(action: { isAnalyzing = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadowColor, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KEY INSIGHTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primary)
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

    var scoreColor: Color {
        switch score {
        case 80...100: return AppTheme.success
        case 60..<80: return AppTheme.warning
        default: return AppTheme.error
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
        HStack(spacing: 20) {
            // Score Ring
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    Text("/ 100")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Portfolio Health")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Text(scoreLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)

                Text("Based on diversification, risk, and returns")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    let type: InsightType

    enum InsightType {
        case positive, warning, info

        var color: Color {
            switch self {
            case .positive: return AppTheme.success
            case .warning: return AppTheme.warning
            case .info: return AppTheme.primary
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Optimization Section

struct OptimizationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OPTIMIZATION SUGGESTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text(description)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)

            HStack {
                // Impact badge
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text(impact)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.success.opacity(0.1))
                .cornerRadius(8)

                Spacer()

                Button(action: {}) {
                    Text(action)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Alerts Section

struct AlertsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ACTIVE ALERTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.primary)
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

            // Empty state for no alerts
            if false {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(AppTheme.textTertiary)

                    Text("No active alerts")
                        .font(.headline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text("We'll notify you when something needs your attention")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
            }
        }
    }
}

struct AlertCard: View {
    let icon: String
    let title: String
    let message: String
    let time: String
    let type: AlertType

    enum AlertType {
        case info, warning, critical

        var color: Color {
            switch self {
            case .info: return AppTheme.primary
            case .warning: return AppTheme.warning
            case .critical: return AppTheme.error
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundColor(type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Text(time)
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }

                Text(message)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    AIAnalysisView()
        .environmentObject(PortfolioStore())
}
