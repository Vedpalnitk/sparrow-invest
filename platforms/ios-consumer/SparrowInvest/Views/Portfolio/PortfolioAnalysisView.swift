import SwiftUI

struct PortfolioAnalysisView: View {
    @StateObject private var analysisStore = PortfolioAnalysisStore()
    @EnvironmentObject var portfolioStore: PortfolioStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStatus: FundHealthStatus?
    @State private var selectedHolding: HoldingAnalysis?
    @State private var showHoldingDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Summary Header
                if let analysis = analysisStore.analysis {
                    HealthSummaryCard(summary: analysis.summary)

                    // Status Filter Pills
                    StatusFilterBar(
                        summary: analysis.summary,
                        selectedStatus: $selectedStatus
                    )

                    // Holdings List by Status
                    AnalysisHoldingsListSection(
                        analysis: analysis,
                        selectedStatus: selectedStatus,
                        onHoldingTap: { holding in
                            selectedHolding = holding
                            showHoldingDetail = true
                        }
                    )

                    // Recommendations Section
                    if !analysis.recommendations.isEmpty {
                        RecommendationsCard(recommendations: analysis.recommendations)
                    }

                    // Powered By Footer
                    if let poweredBy = analysis.poweredBy {
                        HStack {
                            Spacer()
                            Text("Powered by \(poweredBy)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.top, AppTheme.Spacing.small)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.large)
        }
        .background(backgroundGradient)
        .navigationTitle("Portfolio Health")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await analysisStore.fetchAnalysis(
                            clientId: "current_user",
                            holdings: portfolioStore.holdings,
                            forceRefresh: true
                        )
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .regular))
                }
            }
        }
        .task {
            await analysisStore.fetchAnalysis(
                clientId: "current_user",
                holdings: portfolioStore.holdings
            )
        }
        .overlay {
            if analysisStore.isLoading && analysisStore.analysis == nil {
                LoadingOverlay()
            }
        }
        .sheet(isPresented: $showHoldingDetail) {
            if let holding = selectedHolding {
                HoldingAnalysisDetailSheet(holding: holding)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(hex: "#0A0A0F")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Health Summary Card

private struct HealthSummaryCard: View {
    let summary: PortfolioAnalysisSummary
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Health Score Circle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Health")
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.secondary)

                    Text(summary.healthLabel)
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(summary.healthColor)

                    if let trend = summary.healthTrend {
                        HStack(spacing: 4) {
                            Image(systemName: trend == "improving" ? "arrow.up.right" : "minus")
                                .font(.system(size: 11, weight: .regular))
                            Text(trend.capitalized)
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundColor(trend == "improving" ? .green : .secondary)
                    }
                }

                Spacer()

                // Score Circle
                ZStack {
                    Circle()
                        .stroke(summary.healthColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(summary.portfolioHealthScore) / 100)
                        .stroke(
                            summary.healthColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(summary.portfolioHealthScore))")
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .foregroundColor(summary.healthColor)
                        Text("/ 100")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Status Counts Grid
            HStack(spacing: AppTheme.Spacing.small) {
                StatusCountBadge(
                    count: summary.inFormCount,
                    status: .inForm
                )
                StatusCountBadge(
                    count: summary.onTrackCount,
                    status: .onTrack
                )
                StatusCountBadge(
                    count: summary.offTrackCount,
                    status: .offTrack
                )
                StatusCountBadge(
                    count: summary.outOfFormCount,
                    status: .outOfForm
                )
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

// MARK: - Status Count Badge

private struct StatusCountBadge: View {
    let count: Int
    let status: FundHealthStatus
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: status.icon)
                    .font(.system(size: 11, weight: .medium))
                Text("\(count)")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
            }
            .foregroundColor(status.color)

            Text(status.label)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            status.color.opacity(colorScheme == .dark ? 0.15 : 0.1),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .stroke(
                    colorScheme == .dark ? status.color.opacity(0.2) : Color.clear,
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Status Filter Bar

private struct StatusFilterBar: View {
    let summary: PortfolioAnalysisSummary
    @Binding var selectedStatus: FundHealthStatus?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                AnalysisFilterPill(
                    label: "All",
                    count: summary.totalHoldings,
                    isSelected: selectedStatus == nil,
                    color: .blue
                ) {
                    selectedStatus = nil
                }

                ForEach(FundHealthStatus.allCases, id: \.self) { status in
                    let count = countFor(status: status)
                    if count > 0 {
                        AnalysisFilterPill(
                            label: status.label,
                            count: count,
                            isSelected: selectedStatus == status,
                            color: status.color
                        ) {
                            selectedStatus = status
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func countFor(status: FundHealthStatus) -> Int {
        switch status {
        case .inForm: return summary.inFormCount
        case .onTrack: return summary.onTrackCount
        case .offTrack: return summary.offTrackCount
        case .outOfForm: return summary.outOfFormCount
        }
    }
}

// MARK: - Filter Pill

private struct AnalysisFilterPill: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .regular))

                Text("\(count)")
                    .font(.system(size: 12, weight: .regular))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        isSelected
                            ? Color.white.opacity(0.2)
                            : color.opacity(colorScheme == .dark ? 0.2 : 0.12),
                        in: Capsule()
                    )
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(pillBackground)
            .overlay(pillBorder)
            .shadow(color: pillShadow, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var pillShadow: Color {
        if isSelected { return .clear }
        return colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var pillBackground: some View {
        if isSelected {
            Capsule().fill(color)
        } else if colorScheme == .dark {
            Capsule()
                .fill(Color.black.opacity(0.4))
                .background(Capsule().fill(.ultraThinMaterial))
        } else {
            Capsule().fill(Color.white)
        }
    }

    @ViewBuilder
    private var pillBorder: some View {
        if isSelected {
            Capsule().stroke(Color.clear, lineWidth: 0)
        } else {
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
}

// MARK: - Holdings List Section

private struct AnalysisHoldingsListSection: View {
    let analysis: PortfolioAnalysisResponse
    let selectedStatus: FundHealthStatus?
    let onHoldingTap: (HoldingAnalysis) -> Void

    var filteredHoldings: [HoldingAnalysis] {
        if let status = selectedStatus {
            return analysis.holdings.filter { $0.status == status }
        }
        return analysis.holdingsSortedByScore
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(filteredHoldings) { holding in
                HoldingAnalysisCard(holding: holding)
                    .onTapGesture {
                        onHoldingTap(holding)
                    }
            }
        }
    }
}

// MARK: - Holding Analysis Card

private struct HoldingAnalysisCard: View {
    let holding: HoldingAnalysis
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Header Row
            HStack(alignment: .top) {
                // Status Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(holding.statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: holding.statusIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(holding.statusColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.fundName)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(holding.fundCategory)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                StatusBadge(status: holding.status)
            }

            // Values Row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Invested")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.secondary)
                    Text(formatCurrency(holding.investedValue))
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 3) {
                    Text("Current")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.secondary)
                    Text(formatCurrency(holding.currentValue))
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("Returns")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.secondary)
                    Text(formatPercent(holding.absoluteGainPercent))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(holding.absoluteGainPercent >= 0 ? .green : .red)
                }
            }
            .padding(.top, 8)

            // Score Bar
            HStack(spacing: 8) {
                Text("Score")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(holding.statusColor.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(holding.statusColor)
                            .frame(width: geometry.size.width * CGFloat(holding.scores.overallScore / 100), height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(holding.scores.overallScore))")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(holding.statusColor)
                    .frame(width: 28, alignment: .trailing)
            }
            .padding(.top, 8)

            // Action Hint
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundColor(holding.statusColor)

                Text(holding.actionHint)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.top, 8)
        }
        .padding(AppTheme.Spacing.medium)
        .background(holdingCardBackground)
        .overlay(holdingCardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var holdingCardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
        }
    }

    private var holdingCardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.3), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.5),
                            .init(color: .white.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.06), location: 0),
                            .init(color: .black.opacity(0.03), location: 0.5),
                            .init(color: .black.opacity(0.05), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0

        if value >= 100000 {
            return "₹\(String(format: "%.1f", value / 100000))L"
        } else if value >= 1000 {
            return "₹\(String(format: "%.1f", value / 1000))K"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: FundHealthStatus
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10, weight: .medium))
            Text(status.label)
                .font(.system(size: 11, weight: .regular))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            status.color.opacity(colorScheme == .dark ? 0.2 : 0.12),
            in: Capsule()
        )
    }
}

// MARK: - Recommendations Card

private struct RecommendationsCard: View {
    let recommendations: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)

                Text("Recommendations")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
            }

            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)

                    Text(recommendation)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Holding Analysis Detail Sheet

private struct HoldingAnalysisDetailSheet: View {
    let holding: HoldingAnalysis
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.small) {
                        ZStack {
                            Circle()
                                .fill(holding.statusColor.opacity(0.15))
                                .frame(width: 64, height: 64)

                            Image(systemName: holding.statusIcon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(holding.statusColor)
                        }

                        Text(holding.fundName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text(holding.fundCategory)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)

                        StatusBadge(status: holding.status)
                    }
                    .padding(.top, AppTheme.Spacing.medium)

                    // Score Breakdown
                    ScoreBreakdownCard(scores: holding.scores, statusColor: holding.statusColor)

                    // Insights
                    InsightsCard(insights: holding.insights, statusColor: holding.statusColor)

                    // Investment Summary
                    AnalysisInvestmentSummaryCard(holding: holding)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.large)
            }
            .background(
                colorScheme == .dark
                    ? Color.black.ignoresSafeArea()
                    : Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            )
            .navigationTitle("Fund Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Score Breakdown Card

private struct ScoreBreakdownCard: View {
    let scores: HoldingScores
    let statusColor: Color
    @Environment(\.colorScheme) private var colorScheme

    private var scoreItems: [(label: String, score: Double, weight: String)] {
        [
            ("Returns", scores.returnsScore, "40%"),
            ("Risk-Adjusted", scores.riskScore, "25%"),
            ("Consistency", scores.consistencyScore, "20%"),
            ("Momentum", scores.momentumScore, "15%")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("Score Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            ForEach(scoreItems, id: \.label) { item in
                HStack {
                    Text(item.label)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)

                    Text(item.weight)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())

                    Spacer()

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(statusColor)
                                .frame(width: geometry.size.width * CGFloat(item.score / 100), height: 6)
                        }
                    }
                    .frame(width: 80, height: 6)

                    Text("\(Int(item.score))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(statusColor)
                        .frame(width: 28, alignment: .trailing)
                }
            }

            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("Overall Score")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(Int(scores.overallScore))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(statusColor)
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
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Insights Card

private struct InsightsCard: View {
    let insights: [String]
    let statusColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("Key Insights")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(statusColor)
                        .padding(.top, 1)

                    Text(insight)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }
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
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                    lineWidth: 0.5
                )
        )
    }
}

// MARK: - Investment Summary Card

private struct AnalysisInvestmentSummaryCard: View {
    let holding: HoldingAnalysis
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("Investment Summary")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            HStack {
                SummaryItem(label: "Invested", value: formatCurrency(holding.investedValue))
                Spacer()
                SummaryItem(label: "Current", value: formatCurrency(holding.currentValue))
                Spacer()
                SummaryItem(
                    label: "Returns",
                    value: formatPercent(holding.absoluteGainPercent),
                    valueColor: holding.absoluteGainPercent >= 0 ? .green : .red
                )
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
                    colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                    lineWidth: 0.5
                )
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100000 {
            return "₹\(String(format: "%.1f", value / 100000))L"
        } else if value >= 1000 {
            return "₹\(String(format: "%.1f", value / 1000))K"
        }
        return "₹\(Int(value))"
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }
}

// MARK: - Summary Item

private struct SummaryItem: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Loading Overlay

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Analyzing portfolio...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PortfolioAnalysisView()
            .environmentObject(PortfolioStore())
    }
}
