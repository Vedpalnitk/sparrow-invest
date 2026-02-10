//
//  InsightsView.swift
//  SparrowInvest
//
//  AI-powered portfolio insights matching Android InsightsScreen.kt
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var insightsStore: InsightsStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // A. Header
                    InsightsHeaderSection(
                        lastAnalyzedDate: insightsStore.lastAnalyzedDate,
                        viewMode: insightsStore.portfolioViewMode,
                        onViewModeChange: { insightsStore.setPortfolioViewMode($0) }
                    )

                    // B. AI Analysis Card
                    AIAnalysisCard(
                        isAnalyzing: insightsStore.uiState == .analyzing,
                        canAnalyze: insightsStore.uiState != .analyzing,
                        onAnalyze: { insightsStore.analyzePortfolio() }
                    )

                    // State-dependent content
                    switch insightsStore.uiState {
                    case .idle:
                        InsightsPlaceholderCard()

                    case .analyzing:
                        InsightsAnalyzingCard()

                    case .success:
                        successContent

                    case .error(let message):
                        InsightsErrorCard(message: message)
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(AppTheme.groupedBackground)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Success State Content

    @ViewBuilder
    private var successContent: some View {
        // C. Health Score Card
        if let result = insightsStore.analysisResult {
            HealthScoreSection(
                overallScore: result.overallScore,
                diversificationScore: result.diversificationScore,
                riskAlignmentScore: result.riskAlignmentScore,
                costEfficiencyScore: result.costEfficiencyScore
            )
        }

        // D. Alerts Section
        if !insightsStore.alerts.isEmpty {
            InsightsAlertsSectionView(
                alerts: insightsStore.alerts,
                onDismiss: { insightsStore.dismissAlert(id: $0) }
            )
        }

        // E. Action Items Section
        if !insightsStore.actionItems.isEmpty {
            InsightsActionItemsSection(actionItems: insightsStore.actionItems)
        }

        // F. Insight Cards (horizontal scroll)
        if !insightsStore.insightCards.isEmpty {
            InsightCardsRow(cards: insightsStore.insightCards)
        }

        // G. Strengths & Weaknesses
        if let result = insightsStore.analysisResult {
            if !result.strengths.isEmpty {
                StrengthsSection(items: result.strengths)
            }
            if !result.weaknesses.isEmpty {
                WeaknessesSection(items: result.weaknesses)
            }

            // H. Risk Assessment
            if let risk = result.riskAssessment {
                RiskAssessmentSection(
                    currentRisk: risk.currentRiskLevel,
                    recommendedRisk: risk.recommendedRiskLevel,
                    aligned: risk.aligned,
                    explanation: risk.explanation
                )
            }
        }
    }
}

// MARK: - A. Header Section

private struct InsightsHeaderSection: View {
    let lastAnalyzedDate: String?
    let viewMode: InsightsViewMode
    let onViewModeChange: (InsightsViewMode) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Insights")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.primary)

                    if let date = lastAnalyzedDate {
                        Text("Last analyzed: \(date)")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.blue)
                }
            }

            // Portfolio View Mode Segmented Control
            HStack(spacing: 4) {
                ForEach(InsightsViewMode.allCases, id: \.self) { mode in
                    Button {
                        onViewModeChange(mode)
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(viewMode == mode ? .white : .secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background {
                                if viewMode == mode {
                                    Capsule().fill(Color.blue)
                                }
                            }
                    }
                }
            }
            .padding(4)
            .background(toggleBackground)
            .overlay(toggleBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private var toggleBackground: some View {
        if colorScheme == .dark {
            Capsule()
                .fill(Color.black.opacity(0.4))
                .background(Capsule().fill(.ultraThinMaterial))
        } else {
            Capsule().fill(Color.white)
        }
    }

    private var toggleBorder: some View {
        Capsule()
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - B. AI Analysis Card

private struct AIAnalysisCard: View {
    let isAnalyzing: Bool
    let canAnalyze: Bool
    let onAnalyze: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Sparkles icon box with gradient
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(
                        canAnalyze && !isAnalyzing
                            ? LinearGradient(
                                colors: [.blue, Color(red: 0.545, green: 0.361, blue: 0.965)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Portfolio Analysis")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Text(canAnalyze
                     ? "Get personalized insights powered by AI"
                     : "Complete requirements to run analysis")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Analyze pill button
            Button(action: onAnalyze) {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                } else {
                    Text("Analyze")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
            }
            .background(
                canAnalyze && !isAnalyzing
                    ? LinearGradient(
                        colors: [.blue, Color(red: 0.545, green: 0.361, blue: 0.965)],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    : LinearGradient(
                        colors: [.gray.opacity(0.4), .gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                      ),
                in: Capsule()
            )
            .disabled(!canAnalyze || isAnalyzing)
        }
        .padding(AppTheme.Spacing.medium)
        .background(aiCardBackground)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // Blue-to-purple gradient tint over glass card
    @ViewBuilder
    private var aiCardBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.05),
                        Color(red: 0.545, green: 0.361, blue: 0.965).opacity(colorScheme == .dark ? 0.1 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - C. Health Score Section

private struct HealthScoreSection: View {
    let overallScore: Int
    let diversificationScore: Int
    let riskAlignmentScore: Int
    let costEfficiencyScore: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("PORTFOLIO HEALTH")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            HStack(spacing: AppTheme.Spacing.large) {
                // Animated Score Ring
                AnimatedScoreRing(score: overallScore)

                // Mini scores column
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    MiniScoreRow(
                        label: "Diversification",
                        score: diversificationScore,
                        icon: "shield.fill"
                    )
                    MiniScoreRow(
                        label: "Risk Alignment",
                        score: riskAlignmentScore,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    MiniScoreRow(
                        label: "Cost Efficiency",
                        score: costEfficiencyScore,
                        icon: "checkmark.circle.fill"
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Animated Score Ring

private struct AnimatedScoreRing: View {
    let score: Int
    @State private var animatedProgress: CGFloat = 0

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(scoreColor.opacity(0.2), lineWidth: 10)
                .frame(width: 100, height: 100)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            // Score text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(scoreColor)

                Text("/ 100")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = CGFloat(score) / 100.0
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = CGFloat(newValue) / 100.0
            }
        }
    }
}

// MARK: - Mini Score Row

private struct MiniScoreRow: View {
    let label: String
    let score: Int
    let icon: String

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(scoreColor.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(scoreColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))

                Text("\(score)/100")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(scoreColor)
            }
        }
    }
}

// MARK: - D. Alerts Section

private struct InsightsAlertsSectionView: View {
    let alerts: [PortfolioAlert]
    let onDismiss: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Section header with count badge
            HStack {
                Text("ALERTS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
                    .tracking(1)

                Spacer()

                Text("\(alerts.count)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1), in: Capsule())
            }

            ForEach(alerts) { alert in
                InsightsAlertRow(
                    alert: alert,
                    onDismiss: { onDismiss(alert.id) }
                )
            }
        }
    }
}

private struct InsightsAlertRow: View {
    let alert: PortfolioAlert
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
            // Colored icon box
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(alert.type.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: alert.type.icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(alert.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Title row with priority badge
                HStack {
                    Text(alert.title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)

                    Spacer()

                    if alert.priority == .high {
                        Text("HIGH")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }

                Text(alert.message)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Action label link
                if let actionLabel = alert.actionLabel {
                    Button(action: {}) {
                        Text(actionLabel)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(alert.type.color)
                    }
                    .padding(.top, 2)
                }
            }

            // Dismiss X button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(AppTheme.Spacing.compact)
        .background(alertBackground)
        .overlay(alertBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var alertBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var alertBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? alert.type.color.opacity(0.4)
                    : alert.type.color.opacity(0.3),
                lineWidth: 1
            )
    }
}

// MARK: - E. Action Items Section

private struct InsightsActionItemsSection: View {
    let actionItems: [ActionItemData]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Section header with count
            HStack {
                Text("RECOMMENDED ACTIONS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
                    .tracking(1)

                Spacer()

                Text("\(actionItems.count)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1), in: Capsule())
            }

            ForEach(actionItems) { item in
                InsightsActionItemRow(item: item)
            }
        }
    }
}

private struct InsightsActionItemRow: View {
    let item: ActionItemData
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Colored icon circle with first letter
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(item.action.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(String(item.action.displayName.prefix(1)))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(item.action.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Action type badge + fund name
                HStack(spacing: 4) {
                    Text(item.action.displayName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(item.action.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(item.action.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text(item.fundName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Text(item.reason)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Amount and priority
            if let amount = item.amount {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(amount.compactCurrencyFormatted)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(item.action.color)

                    Text(item.priority.rawValue)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
        }
        .padding(AppTheme.Spacing.compact)
        .listItemCardStyle(cornerRadius: AppTheme.CornerRadius.large)
    }
}

// MARK: - F. Insight Cards Row

private struct InsightCardsRow: View {
    let cards: [InsightCardData]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("PORTFOLIO INSIGHTS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.compact) {
                    ForEach(cards) { card in
                        InsightMetricCard(card: card)
                    }
                }
            }
        }
    }
}

private struct InsightMetricCard: View {
    let card: InsightCardData
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Icon + trend arrow
            HStack(spacing: 4) {
                Image(systemName: card.type.icon)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(card.type.color)

                if let trend = card.trend {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(trend >= 0 ? .green : .red)
                }
            }

            Text(card.title)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            if let value = card.value {
                Text(value)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(card.type.color)
            }
        }
        .padding(AppTheme.Spacing.compact)
        .frame(width: 140)
        .listItemCardStyle(cornerRadius: AppTheme.CornerRadius.large)
    }
}

// MARK: - G. Strengths Section

private struct StrengthsSection: View {
    let items: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("STRENGTHS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)

                        Text(item)
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - G. Weaknesses Section

private struct WeaknessesSection: View {
    let items: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("AREAS FOR IMPROVEMENT")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)

                        Text(item)
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - H. Risk Assessment Section

private struct RiskAssessmentSection: View {
    let currentRisk: String
    let recommendedRisk: String
    let aligned: Bool
    let explanation: String
    @Environment(\.colorScheme) private var colorScheme

    private var statusColor: Color {
        aligned ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("RISK ASSESSMENT")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(spacing: AppTheme.Spacing.medium) {
                HStack {
                    // Current risk
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Risk")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))

                        Text(currentRisk)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Aligned/Misaligned badge
                    Text(aligned ? "Aligned" : "Misaligned")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.1), in: Capsule())

                    Spacer()

                    // Recommended risk
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Recommended")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))

                        Text(recommendedRisk)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                    }
                }

                Text(explanation)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - I. Placeholder State

private struct InsightsPlaceholderCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.blue.opacity(0.5))

            Text("Analyze Your Portfolio")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.primary)

            Text("Get AI-powered insights, recommendations, and alerts tailored to your investment goals.")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xxLarge)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - I. Analyzing State

private struct InsightsAnalyzingCard: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .scaleEffect(2.0)
                .tint(.blue)
                .frame(width: 64, height: 64)

            Text("Analyzing Your Portfolio")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.primary)

            Text("Our AI is evaluating your investments across multiple dimensions...")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xxLarge)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - I. Error State

private struct InsightsErrorCard: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.red)

            Text("Analysis Failed")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xxLarge)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environmentObject(InsightsStore())
}
