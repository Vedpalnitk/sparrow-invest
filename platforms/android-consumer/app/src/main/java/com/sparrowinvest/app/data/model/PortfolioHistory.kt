package com.sparrowinvest.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PortfolioHistoryPoint(
    val id: String,
    val date: String,
    val value: Double,
    val invested: Double
) {
    val returns: Double get() = value - invested
    val returnsPercentage: Double
        get() = if (invested > 0) ((value - invested) / invested) * 100 else 0.0
}

@Serializable
data class PortfolioHistory(
    @SerialName("data_points")
    val dataPoints: List<PortfolioHistoryPoint> = emptyList(),
    val period: HistoryPeriod = HistoryPeriod.ONE_YEAR
) {
    val minValue: Double get() = dataPoints.minOfOrNull { it.value } ?: 0.0
    val maxValue: Double get() = dataPoints.maxOfOrNull { it.value } ?: 0.0
    val latestValue: Double get() = dataPoints.lastOrNull()?.value ?: 0.0
    val earliestValue: Double get() = dataPoints.firstOrNull()?.value ?: 0.0

    val periodReturn: Double
        get() = if (earliestValue > 0) ((latestValue - earliestValue) / earliestValue) * 100 else 0.0

    companion object {
        val empty = PortfolioHistory()
    }
}

@Serializable
enum class HistoryPeriod(val label: String, val days: Int) {
    @SerialName("1M")
    ONE_MONTH("1M", 30),

    @SerialName("3M")
    THREE_MONTHS("3M", 90),

    @SerialName("6M")
    SIX_MONTHS("6M", 180),

    @SerialName("1Y")
    ONE_YEAR("1Y", 365),

    @SerialName("3Y")
    THREE_YEARS("3Y", 365 * 3),

    @SerialName("5Y")
    FIVE_YEARS("5Y", 365 * 5),

    @SerialName("All")
    ALL("All", 365 * 10);
}
