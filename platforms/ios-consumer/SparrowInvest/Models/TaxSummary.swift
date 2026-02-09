//
//  TaxSummary.swift
//  SparrowInvest
//
//  Tax calculation models for capital gains
//

import Foundation

// MARK: - Tax Summary

struct TaxSummary: Codable {
    var financialYear: String
    var totalLTCG: Double      // Long Term Capital Gains (>12 months for equity)
    var totalSTCG: Double      // Short Term Capital Gains (<12 months)
    var netLTCG: Double        // After 1L exemption
    var netSTCG: Double
    var ltcgTaxLiability: Double  // 10% for equity LTCG over 1L
    var stcgTaxLiability: Double  // 15% for equity STCG
    var totalTaxLiability: Double
    var totalTaxSaved: Double     // From ELSS investments
    var elssInvestment: Double    // 80C ELSS investments
    var elss80CLimit: Double      // 1.5L limit
    var elss80CProgress: Double   // Progress towards limit
    var elss80CRemaining: Double  // Remaining to invest

    static var empty: TaxSummary {
        TaxSummary(
            financialYear: "FY 2025-26",
            totalLTCG: 0,
            totalSTCG: 0,
            netLTCG: 0,
            netSTCG: 0,
            ltcgTaxLiability: 0,
            stcgTaxLiability: 0,
            totalTaxLiability: 0,
            totalTaxSaved: 0,
            elssInvestment: 0,
            elss80CLimit: 150000,
            elss80CProgress: 0,
            elss80CRemaining: 150000
        )
    }

    // Calculate tax based on gains
    static func calculate(ltcg: Double, stcg: Double, elss: Double) -> TaxSummary {
        let exemption: Double = 100000 // 1L exemption for LTCG
        let netLTCG = max(0, ltcg - exemption)
        let ltcgTax = netLTCG * 0.10 // 10% tax on LTCG
        let stcgTax = max(0, stcg) * 0.15 // 15% tax on STCG

        let elssLimit: Double = 150000
        let elssProgress = min(elss / elssLimit, 1.0)
        let taxSaved = min(elss, elssLimit) * 0.30 // Assuming 30% tax bracket

        return TaxSummary(
            financialYear: "FY 2025-26",
            totalLTCG: ltcg,
            totalSTCG: stcg,
            netLTCG: netLTCG,
            netSTCG: stcg,
            ltcgTaxLiability: ltcgTax,
            stcgTaxLiability: stcgTax,
            totalTaxLiability: ltcgTax + stcgTax,
            totalTaxSaved: taxSaved,
            elssInvestment: elss,
            elss80CLimit: elssLimit,
            elss80CProgress: elssProgress,
            elss80CRemaining: max(0, elssLimit - elss)
        )
    }
}
