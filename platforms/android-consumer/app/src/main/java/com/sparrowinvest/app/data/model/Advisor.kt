package com.sparrowinvest.app.data.model

import kotlinx.serialization.Serializable

enum class AdvisorSpecialization(val displayName: String, val iconName: String) {
    RETIREMENT("Retirement", "account_balance"),
    TAX_PLANNING("Tax Planning", "receipt_long"),
    HNI("HNI Wealth", "diamond"),
    MUTUAL_FUNDS("Mutual Funds", "trending_up"),
    INSURANCE("Insurance", "shield"),
    ESTATE_PLANNING("Estate Planning", "home_work"),
    NRI("NRI Services", "flight"),
    EQUITY("Direct Equity", "candlestick_chart")
}

@Serializable
data class Advisor(
    val id: String,
    val name: String,
    val region: String,
    val phone: String,
    val email: String,
    val specializations: List<String> = emptyList(),
    val experienceYears: Int,
    val rating: Double,
    val reviewCount: Int,
    val languages: List<String> = emptyList(),
    val isAvailable: Boolean = true
) {
    val initials: String get() {
        val parts = name.split(" ")
        return if (parts.size >= 2) "${parts[0].first()}${parts[1].first()}".uppercase()
        else name.take(2).uppercase()
    }

    val formattedExperience: String get() = "${experienceYears}+ years"

    val specializationEnums: List<AdvisorSpecialization> get() =
        specializations.mapNotNull { name ->
            AdvisorSpecialization.entries.find { it.name == name }
        }
}
