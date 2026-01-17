//
//  DividendSummary.swift
//  SparrowInvest
//
//  Dividend tracking models
//

import Foundation

// MARK: - Dividend Record

struct DividendRecord: Codable, Identifiable {
    let id: String
    let fundCode: String
    let fundName: String
    let amount: Double
    let unitsHeld: Double
    let dividendPerUnit: Double
    let recordDate: Date
    let paymentDate: Date
    let status: DividendStatus

    init(
        id: String = UUID().uuidString,
        fundCode: String,
        fundName: String,
        amount: Double,
        unitsHeld: Double,
        dividendPerUnit: Double,
        recordDate: Date,
        paymentDate: Date,
        status: DividendStatus = .paid
    ) {
        self.id = id
        self.fundCode = fundCode
        self.fundName = fundName
        self.amount = amount
        self.unitsHeld = unitsHeld
        self.dividendPerUnit = dividendPerUnit
        self.recordDate = recordDate
        self.paymentDate = paymentDate
        self.status = status
    }
}

// MARK: - Dividend Status

enum DividendStatus: String, Codable {
    case announced = "Announced"
    case pending = "Pending"
    case paid = "Paid"
}

// MARK: - Dividend Summary

struct DividendSummary: Codable {
    var financialYear: String
    var totalReceived: Double
    var projectedAnnual: Double
    var dividendYield: Double
    var records: [DividendRecord]
    var nextExpectedDate: Date?

    static var empty: DividendSummary {
        DividendSummary(
            financialYear: "FY 2025-26",
            totalReceived: 0,
            projectedAnnual: 0,
            dividendYield: 0,
            records: [],
            nextExpectedDate: nil
        )
    }

    var recentRecords: [DividendRecord] {
        records.sorted { $0.paymentDate > $1.paymentDate }.prefix(5).map { $0 }
    }

    var monthlyAverage: Double {
        guard !records.isEmpty else { return 0 }
        return totalReceived / 12
    }
}
