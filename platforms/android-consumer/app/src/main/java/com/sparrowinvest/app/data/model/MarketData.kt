package com.sparrowinvest.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.Locale

@Serializable
data class MarketIndex(
    val id: String = "",
    val name: String,
    val symbol: String = "",
    val value: Double,
    @SerialName("previous_close")
    val previousClose: Double = 0.0,
    val change: Double,
    @SerialName("change_percentage")
    val changePercentage: Double,
    @SerialName("last_updated")
    val lastUpdated: String? = null
) {
    val isPositive: Boolean get() = change >= 0
    val formattedValue: String get() = String.format(Locale.US, "%.2f", value)
    val formattedChange: String get() {
        val sign = if (change >= 0) "+" else ""
        return "$sign${String.format(Locale.US, "%.2f", change)} (${String.format(Locale.US, "%.2f", changePercentage)}%)"
    }
}

@Serializable
data class MarketSummary(
    val nifty50: MarketIndex? = null,
    val sensex: MarketIndex? = null,
    val niftyBank: MarketIndex? = null,
    @SerialName("market_status")
    val marketStatus: MarketStatus = MarketStatus.CLOSED,
    @SerialName("next_open")
    val nextOpen: String? = null
)

@Serializable
data class MarketOverview(
    val indices: List<MarketIndex> = emptyList(),
    val status: String = "Closed",
    val lastUpdated: String = ""
) {
    companion object {
        val empty = MarketOverview()
    }

    val primaryIndices: List<MarketIndex>
        get() = indices.filter { it.symbol == "NSEI" || it.symbol == "BSESN" }

    val otherIndices: List<MarketIndex>
        get() = indices.filter { it.symbol != "NSEI" && it.symbol != "BSESN" }

    val statusEnum: MarketStatus
        get() = when (status) {
            "Open" -> MarketStatus.OPEN
            "Pre-Open" -> MarketStatus.PRE_OPEN
            "Post-Close" -> MarketStatus.POST_CLOSE
            else -> MarketStatus.CLOSED
        }
}

@Serializable
enum class MarketStatus {
    @SerialName("open")
    OPEN,
    @SerialName("closed")
    CLOSED,
    @SerialName("pre_open")
    PRE_OPEN,
    @SerialName("post_close")
    POST_CLOSE;

    val displayName: String
        get() = when (this) {
            OPEN -> "Market Open"
            CLOSED -> "Market Closed"
            PRE_OPEN -> "Pre-Open"
            POST_CLOSE -> "Post-Close"
        }

    val color: Long
        get() = when (this) {
            OPEN -> 0xFF10B981
            CLOSED -> 0xFFEF4444
            PRE_OPEN -> 0xFFF59E0B
            POST_CLOSE -> 0xFFF59E0B
        }
}

@Serializable
data class Watchlist(
    val id: String,
    val name: String,
    val funds: List<String> = emptyList(),
    @SerialName("created_at")
    val createdAt: String? = null
)
