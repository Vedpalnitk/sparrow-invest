package com.sparrowinvest.app.data.model

import androidx.compose.ui.graphics.Color

/**
 * Fund health status categories matching the iOS FundHealthStatus enum.
 * Each status maps to a specific color, icon, and label for the portfolio analysis screen.
 */
enum class FundHealthStatus(
    val label: String,
    val description: String,
    val actionHint: String,
    val statusColor: Color,
    val icon: String, // Material icon name
    val sortOrder: Int
) {
    IN_FORM(
        label = "In-form",
        description = "Performing great",
        actionHint = "Continue investing",
        statusColor = Color(0xFF16C47F),
        icon = "keyboard_double_arrow_up",
        sortOrder = 0
    ),
    ON_TRACK(
        label = "On-track",
        description = "Performing good",
        actionHint = "Hold / invest more",
        statusColor = Color(0xFF84CC16),
        icon = "keyboard_arrow_up",
        sortOrder = 1
    ),
    OFF_TRACK(
        label = "Off-track",
        description = "Don't invest further",
        actionHint = "Review and monitor",
        statusColor = Color(0xFFFB923C),
        icon = "keyboard_arrow_down",
        sortOrder = 2
    ),
    OUT_OF_FORM(
        label = "Out-of-form",
        description = "Exit now",
        actionHint = "Consider exiting",
        statusColor = Color(0xFFEF4444),
        icon = "keyboard_double_arrow_down",
        sortOrder = 3
    )
}

/**
 * Score breakdown for an individual holding, mapping directly to the iOS HoldingScores model.
 */
data class HoldingScores(
    val overallScore: Double,
    val returnsScore: Double,
    val riskScore: Double,
    val consistencyScore: Double,
    val momentumScore: Double
)

/**
 * Analysis result for a single mutual fund holding.
 */
data class HoldingAnalysis(
    val id: String,
    val fundName: String,
    val fundCategory: String,
    val status: FundHealthStatus,
    val investedValue: Double,
    val currentValue: Double,
    val absoluteGainPercent: Double,
    val scores: HoldingScores,
    val insights: List<String>,
    val actionHint: String
) {
    val statusColor: Color get() = status.statusColor
    val statusIcon: String get() = status.icon
}

/**
 * Summary of the overall portfolio health analysis.
 */
data class PortfolioAnalysisSummary(
    val portfolioHealthScore: Double,
    val healthLabel: String,
    val healthTrend: String?,
    val inFormCount: Int,
    val onTrackCount: Int,
    val offTrackCount: Int,
    val outOfFormCount: Int,
    val totalHoldings: Int
) {
    val healthColor: Color
        get() = when {
            portfolioHealthScore >= 75 -> FundHealthStatus.IN_FORM.statusColor
            portfolioHealthScore >= 50 -> FundHealthStatus.ON_TRACK.statusColor
            portfolioHealthScore >= 25 -> FundHealthStatus.OFF_TRACK.statusColor
            else -> FundHealthStatus.OUT_OF_FORM.statusColor
        }

    fun countFor(status: FundHealthStatus): Int = when (status) {
        FundHealthStatus.IN_FORM -> inFormCount
        FundHealthStatus.ON_TRACK -> onTrackCount
        FundHealthStatus.OFF_TRACK -> offTrackCount
        FundHealthStatus.OUT_OF_FORM -> outOfFormCount
    }
}

/**
 * Complete portfolio analysis response containing summary, holdings, and recommendations.
 */
data class PortfolioAnalysisResponse(
    val summary: PortfolioAnalysisSummary,
    val holdings: List<HoldingAnalysis>,
    val recommendations: List<String>,
    val poweredBy: String? = null
) {
    /** Holdings sorted by overall score descending (best first). */
    val holdingsSortedByScore: List<HoldingAnalysis>
        get() = holdings.sortedByDescending { it.scores.overallScore }
}
