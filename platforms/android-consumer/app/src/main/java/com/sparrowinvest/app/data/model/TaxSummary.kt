package com.sparrowinvest.app.data.model

import kotlinx.serialization.Serializable

@Serializable
data class TaxSummary(
    val financialYear: String = "FY 2025-26",
    val totalLTCG: Double = 0.0,
    val totalSTCG: Double = 0.0,
    val netLTCG: Double = 0.0,
    val netSTCG: Double = 0.0,
    val ltcgTaxLiability: Double = 0.0,
    val stcgTaxLiability: Double = 0.0,
    val totalTaxLiability: Double = 0.0,
    val totalTaxSaved: Double = 0.0,
    val elssInvestment: Double = 0.0,
    val elss80CLimit: Double = 150000.0,
    val elss80CProgress: Double = 0.0,
    val elss80CRemaining: Double = 150000.0
) {
    companion object {
        val empty = TaxSummary()

        fun calculate(ltcg: Double, stcg: Double, elss: Double): TaxSummary {
            val exemption = 100000.0
            val netLTCG = maxOf(0.0, ltcg - exemption)
            val ltcgTax = netLTCG * 0.10
            val stcgTax = maxOf(0.0, stcg) * 0.15
            val elssLimit = 150000.0
            val elssProgress = minOf(elss / elssLimit, 1.0)
            val taxSaved = minOf(elss, elssLimit) * 0.30
            return TaxSummary(
                totalLTCG = ltcg, totalSTCG = stcg,
                netLTCG = netLTCG, netSTCG = stcg,
                ltcgTaxLiability = ltcgTax, stcgTaxLiability = stcgTax,
                totalTaxLiability = ltcgTax + stcgTax,
                totalTaxSaved = taxSaved, elssInvestment = elss,
                elss80CLimit = elssLimit, elss80CProgress = elssProgress,
                elss80CRemaining = maxOf(0.0, elssLimit - elss)
            )
        }
    }
}
