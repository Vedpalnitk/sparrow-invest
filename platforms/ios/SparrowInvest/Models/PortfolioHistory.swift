//
//  PortfolioHistory.swift
//  SparrowInvest
//
//  Portfolio historical data for charts
//

import Foundation

// MARK: - Portfolio History Point

struct PortfolioHistoryPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let value: Double
    let invested: Double

    var returns: Double {
        value - invested
    }

    var returnsPercentage: Double {
        guard invested > 0 else { return 0 }
        return ((value - invested) / invested) * 100
    }

    init(id: String = UUID().uuidString, date: Date, value: Double, invested: Double) {
        self.id = id
        self.date = date
        self.value = value
        self.invested = invested
    }
}

// MARK: - Portfolio History

struct PortfolioHistory: Codable {
    var dataPoints: [PortfolioHistoryPoint]
    var period: HistoryPeriod

    static var empty: PortfolioHistory {
        PortfolioHistory(dataPoints: [], period: .oneYear)
    }

    var minValue: Double {
        dataPoints.map { $0.value }.min() ?? 0
    }

    var maxValue: Double {
        dataPoints.map { $0.value }.max() ?? 0
    }

    var latestValue: Double {
        dataPoints.last?.value ?? 0
    }

    var earliestValue: Double {
        dataPoints.first?.value ?? 0
    }

    var periodReturn: Double {
        guard earliestValue > 0 else { return 0 }
        return ((latestValue - earliestValue) / earliestValue) * 100
    }
}

// MARK: - History Period

enum HistoryPeriod: String, Codable, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case all = "All"

    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .threeYears: return 365 * 3
        case .fiveYears: return 365 * 5
        case .all: return 365 * 10
        }
    }
}
