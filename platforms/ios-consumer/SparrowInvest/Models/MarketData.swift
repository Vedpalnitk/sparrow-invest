//
//  MarketData.swift
//  SparrowInvest
//
//  Market indices and overview models
//

import Foundation
import SwiftUI

// MARK: - Market Index

struct MarketIndex: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String
    var value: Double
    var previousClose: Double
    var change: Double
    var changePercentage: Double
    var lastUpdated: Date

    var isPositive: Bool {
        change >= 0
    }

    var formattedValue: String {
        String(format: "%.2f", value)
    }

    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change)) (\(String(format: "%.2f", changePercentage))%)"
    }
}

// MARK: - Market Overview

struct MarketOverview: Codable {
    var indices: [MarketIndex]
    var status: MarketStatus
    var lastUpdated: Date

    static var empty: MarketOverview {
        MarketOverview(
            indices: [],
            status: .closed,
            lastUpdated: Date()
        )
    }

    var primaryIndices: [MarketIndex] {
        indices.filter { $0.symbol == "NSEI" || $0.symbol == "BSESN" }
    }

    var otherIndices: [MarketIndex] {
        indices.filter { $0.symbol != "NSEI" && $0.symbol != "BSESN" }
    }
}

// MARK: - Market Status

enum MarketStatus: String, Codable {
    case open = "Open"
    case closed = "Closed"
    case preOpen = "Pre-Open"
    case postClose = "Post-Close"

    var color: Color {
        switch self {
        case .open: return Color(hex: "#10B981")
        case .closed: return Color(hex: "#EF4444")
        case .preOpen, .postClose: return Color(hex: "#F59E0B")
        }
    }

    var icon: String {
        switch self {
        case .open: return "circle.fill"
        case .closed: return "moon.fill"
        case .preOpen: return "sunrise.fill"
        case .postClose: return "sunset.fill"
        }
    }
}
