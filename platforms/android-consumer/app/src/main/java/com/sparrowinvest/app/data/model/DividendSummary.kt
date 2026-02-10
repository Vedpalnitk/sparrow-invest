package com.sparrowinvest.app.data.model

import kotlinx.serialization.Serializable

enum class DividendStatus(val displayName: String) {
    ANNOUNCED("Announced"),
    PENDING("Pending"),
    PAID("Paid")
}

@Serializable
data class DividendRecord(
    val id: String,
    val fundCode: String,
    val fundName: String,
    val amount: Double,
    val unitsHeld: Double,
    val dividendPerUnit: Double,
    val recordDate: String,
    val paymentDate: String,
    val status: String = "Paid" // Announced, Pending, Paid
)

@Serializable
data class DividendSummary(
    val financialYear: String = "FY 2025-26",
    val totalReceived: Double = 0.0,
    val projectedAnnual: Double = 0.0,
    val dividendYield: Double = 0.0,
    val records: List<DividendRecord> = emptyList(),
    val nextExpectedDate: String? = null
) {
    companion object {
        val empty = DividendSummary()
    }

    val recentRecords: List<DividendRecord>
        get() = records.sortedByDescending { it.paymentDate }.take(3)
}
