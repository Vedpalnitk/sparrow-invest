package com.sparrowinvest.fa.data.model

import kotlinx.serialization.Serializable

@Serializable
data class InsurancePolicy(
    val id: String,
    val clientId: String,
    val policyNumber: String,
    val provider: String,
    val type: String,
    val status: String = "ACTIVE",
    val sumAssured: Double,
    val premiumAmount: Double,
    val premiumFrequency: String = "ANNUAL",
    val startDate: String,
    val maturityDate: String? = null,
    val nominees: String? = null,
    val notes: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null
) {
    val formattedSumAssured: String get() = when {
        sumAssured >= 10000000 -> "₹${"%.1f".format(sumAssured / 10000000)} Cr"
        sumAssured >= 100000 -> "₹${"%.1f".format(sumAssured / 100000)} L"
        else -> "₹${"%,.0f".format(sumAssured)}"
    }

    val formattedPremium: String get() = when {
        premiumAmount >= 100000 -> "₹${"%.1f".format(premiumAmount / 100000)} L"
        else -> "₹${"%,.0f".format(premiumAmount)}"
    }

    val typeLabel: String get() = when (type) {
        "TERM_LIFE" -> "Term Life"
        "WHOLE_LIFE" -> "Whole Life"
        "ENDOWMENT" -> "Endowment"
        "ULIP" -> "ULIP"
        "HEALTH" -> "Health"
        "CRITICAL_ILLNESS" -> "Critical Illness"
        "PERSONAL_ACCIDENT" -> "Personal Accident"
        else -> "Other"
    }

    val isLifeCover: Boolean get() = type in listOf("TERM_LIFE", "WHOLE_LIFE", "ENDOWMENT", "ULIP")
    val isHealthCover: Boolean get() = type in listOf("HEALTH", "CRITICAL_ILLNESS")
    val isActive: Boolean get() = status == "ACTIVE"
}

@Serializable
data class CoverageGap(
    val recommended: Double,
    val current: Double,
    val gap: Double,
    val adequate: Boolean
)

@Serializable
data class GapAnalysisResponse(
    val life: CoverageGap,
    val health: CoverageGap,
    val policies: List<InsurancePolicy> = emptyList()
)

@Serializable
data class CreateInsurancePolicyRequest(
    val policyNumber: String,
    val provider: String,
    val type: String,
    val status: String? = null,
    val sumAssured: Double,
    val premiumAmount: Double,
    val premiumFrequency: String? = null,
    val startDate: String,
    val maturityDate: String? = null,
    val nominees: String? = null,
    val notes: String? = null
)
