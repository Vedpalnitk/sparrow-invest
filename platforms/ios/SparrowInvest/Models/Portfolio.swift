import Foundation
import SwiftUI

struct Portfolio: Codable {
    var totalValue: Double
    var totalInvested: Double
    var totalReturns: Double
    var returnsPercentage: Double
    var todayChange: Double
    var todayChangePercentage: Double
    var xirr: Double?
    var assetAllocation: AssetAllocation
    var holdings: [Holding]

    // Aliases for compatibility
    var currentValue: Double { totalValue }
    var absoluteReturnsPercentage: Double { returnsPercentage }

    static var empty: Portfolio {
        Portfolio(
            totalValue: 0,
            totalInvested: 0,
            totalReturns: 0,
            returnsPercentage: 0,
            todayChange: 0,
            todayChangePercentage: 0,
            xirr: nil,
            assetAllocation: AssetAllocation(equity: 0, debt: 0, hybrid: 0, gold: 0, other: 0),
            holdings: []
        )
    }
}

struct AssetAllocation: Codable {
    var equity: Double
    var debt: Double
    var hybrid: Double
    var gold: Double
    var other: Double

    init(equity: Double, debt: Double, hybrid: Double, gold: Double, other: Double = 0) {
        self.equity = equity
        self.debt = debt
        self.hybrid = hybrid
        self.gold = gold
        self.other = other
    }

    var total: Double {
        equity + debt + hybrid + gold + other
    }

    var equityPercentage: Double {
        guard total > 0 else { return 0 }
        return (equity / total) * 100
    }

    var debtPercentage: Double {
        guard total > 0 else { return 0 }
        return (debt / total) * 100
    }

    var hybridPercentage: Double {
        guard total > 0 else { return 0 }
        return (hybrid / total) * 100
    }

    var goldPercentage: Double {
        guard total > 0 else { return 0 }
        return (gold / total) * 100
    }

    var otherPercentage: Double {
        guard total > 0 else { return 0 }
        return (other / total) * 100
    }
}

struct Holding: Codable, Identifiable {
    let id: String
    let fundCode: String
    let fundName: String
    let category: String
    let assetClass: AssetClass
    var units: Double
    var averageNav: Double
    var currentNav: Double
    var investedAmount: Double
    var currentValue: Double
    var returns: Double
    var returnsPercentage: Double
    var dayChange: Double
    var dayChangePercentage: Double

    init(
        id: String,
        fundCode: String,
        fundName: String,
        category: String,
        assetClass: AssetClass,
        units: Double,
        averageNav: Double,
        currentNav: Double,
        investedAmount: Double,
        currentValue: Double,
        returns: Double,
        returnsPercentage: Double,
        dayChange: Double = 0,
        dayChangePercentage: Double = 0
    ) {
        self.id = id
        self.fundCode = fundCode
        self.fundName = fundName
        self.category = category
        self.assetClass = assetClass
        self.units = units
        self.averageNav = averageNav
        self.currentNav = currentNav
        self.investedAmount = investedAmount
        self.currentValue = currentValue
        self.returns = returns
        self.returnsPercentage = returnsPercentage
        self.dayChange = dayChange
        self.dayChangePercentage = dayChangePercentage
    }

    enum AssetClass: String, Codable {
        case equity = "equity"
        case debt = "debt"
        case hybrid = "hybrid"
        case gold = "gold"
        case other = "other"

        var color: Color {
            switch self {
            case .equity: return Color(hex: "#3B82F6")
            case .debt: return Color(hex: "#10B981")
            case .hybrid: return Color(hex: "#8B5CF6")
            case .gold: return Color(hex: "#F59E0B")
            case .other: return Color(hex: "#64748B")
            }
        }
    }

    /// Convert holding to Fund for detail view
    func toFund() -> Fund {
        Fund(
            id: fundCode,
            schemeCode: Int(fundCode) ?? 0,
            schemeName: fundName,
            category: category,
            assetClass: assetClass.rawValue,
            nav: currentNav,
            navDate: Date(),
            returns: FundReturns(
                oneMonth: nil,
                threeMonth: nil,
                sixMonth: nil,
                oneYear: returnsPercentage,
                threeYear: nil,
                fiveYear: nil
            ),
            aum: nil,
            expenseRatio: nil,
            riskRating: nil,
            minSIP: 500,
            minLumpSum: 1000,
            fundManager: nil,
            fundHouse: nil
        )
    }
}

struct SIP: Codable, Identifiable {
    let id: String
    let fundCode: String
    let fundName: String
    var amount: Double
    let frequency: SIPFrequency
    var nextDate: Date
    var status: SIPStatus
    var totalInvested: Double
    var sipCount: Int

    var isActive: Bool {
        status == .active
    }

    var nextInstallmentDate: Date? {
        isActive ? nextDate : nil
    }

    enum SIPFrequency: String, Codable {
        case monthly = "monthly"
        case quarterly = "quarterly"
        case weekly = "weekly"
    }

    enum SIPStatus: String, Codable {
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

struct Transaction: Codable, Identifiable {
    let id: String
    let fundCode: String
    let fundName: String
    let type: TransactionType
    let amount: Double
    let units: Double
    let nav: Double
    let date: Date
    let status: TransactionStatus

    enum TransactionType: String, Codable {
        case purchase = "purchase"
        case redemption = "redemption"
        case sipInstallment = "sip"
        case switchIn = "switch_in"
        case switchOut = "switch_out"
        case dividend = "dividend"

        var displayName: String {
            switch self {
            case .purchase: return "Purchase"
            case .redemption: return "Redemption"
            case .sipInstallment: return "SIP"
            case .switchIn: return "Switch In"
            case .switchOut: return "Switch Out"
            case .dividend: return "Dividend"
            }
        }
    }

    enum TransactionStatus: String, Codable {
        case pending = "pending"
        case processing = "processing"
        case completed = "completed"
        case failed = "failed"
    }
}
