//
//  PointsStore.swift
//  SparrowInvest
//
//  Created by Claude on 2025.
//

import Foundation
import SwiftUI

// MARK: - API Response Models

/// Points summary response from /api/v1/me/points (camelCase from backend)
struct PointsSummaryResponse: Decodable {
    let currentPoints: Int
    let lifetimePoints: Int
    let redeemedPoints: Int
    let tier: String
    let tierName: String
    let pointsToNextTier: Int
    let nextTier: String?
    let sipStreak: Int
    let tierUpdatedAt: String?

    func toPoints() -> Points {
        let tierEnum: RewardTier = {
            switch tier.uppercased() {
            case "SILVER": return .silver
            case "GOLD": return .gold
            case "PLATINUM": return .platinum
            default: return .bronze
            }
        }()

        // Calculate expiring points (not tracked by backend yet, use placeholder)
        let expiringPoints = 0
        let expiryDate: Date? = nil

        return Points(
            totalPoints: currentPoints,
            tier: tierEnum,
            lifetimePoints: lifetimePoints,
            expiringPoints: expiringPoints,
            expiryDate: expiryDate
        )
    }
}

/// Points transactions response wrapper from /api/v1/me/points/transactions
struct PointsTransactionsResponse: Decodable {
    let transactions: [PointsTransactionAPIResponse]
    let total: Int
}

/// Points transaction response from /api/v1/me/points/transactions (camelCase from backend)
struct PointsTransactionAPIResponse: Decodable {
    let id: String
    let type: String
    let typeName: String
    let points: Int
    let description: String?
    let referenceId: String?
    let expiresAt: String?
    let createdAt: String

    func toTransaction() -> PointsTransaction {
        let typeEnum: PointsTransactionType = {
            switch type.uppercased() {
            case "REDEEMED": return .redeemed
            case "EXPIRED": return .expired
            case "EARNED_STREAK", "EARNED_REFERRAL", "EARNED_GOAL", "EARNED_KYC": return .bonus
            default: return .earned // EARNED_SIP, EARNED_LUMPSUM
            }
        }()

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: createdAt) ?? Date()

        return PointsTransaction(
            id: id,
            type: typeEnum,
            points: points,
            description: description ?? typeName,
            date: date
        )
    }
}

// MARK: - Points Store

@MainActor
class PointsStore: ObservableObject {
    @Published var points: Points = .empty
    @Published var transactions: [PointsTransaction] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Computed Properties

    var pointsToNextTier: Int {
        guard let nextTier = points.tier.nextTier else { return 0 }
        return max(0, nextTier.minPoints - points.totalPoints)
    }

    var progressToNextTier: Double {
        guard let nextTier = points.tier.nextTier else { return 1.0 }
        let currentTierMin = points.tier.minPoints
        let nextTierMin = nextTier.minPoints
        let range = nextTierMin - currentTierMin
        let progress = points.totalPoints - currentTierMin
        return min(1.0, max(0.0, Double(progress) / Double(range)))
    }

    var formattedTotalPoints: String {
        points.totalPoints.formatted()
    }

    var formattedLifetimePoints: String {
        points.lifetimePoints.formatted()
    }

    var formattedExpiringPoints: String {
        points.expiringPoints.formatted()
    }

    var expiryDateFormatted: String? {
        guard let date = points.expiryDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private let apiService = APIService.shared

    // MARK: - Initialization

    init() {
        loadMockData()
    }

    // MARK: - Data Fetching

    func fetchPoints() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: PointsSummaryResponse = try await apiService.get("/me/points")
            self.points = response.toPoints()
            self.error = nil

            // Also fetch transactions
            await fetchTransactions()
        } catch {
            self.error = error
            // Fallback to mock data
            print("Failed to fetch points from API: \(error). Using mock data.")
            loadMockData()
        }
    }

    func fetchTransactions() async {
        do {
            let response: PointsTransactionsResponse = try await apiService.get("/me/points/transactions")
            self.transactions = response.transactions.map { $0.toTransaction() }
        } catch {
            print("Failed to fetch transactions: \(error)")
            // Keep existing transactions or mock data
        }
    }

    // MARK: - Mock Data

    private func loadMockData() {
        // Points data per plan spec
        points = Points(
            totalPoints: 2450,
            tier: .gold,
            lifetimePoints: 5200,
            expiringPoints: 350,
            expiryDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())
        )

        // Sample transactions
        let calendar = Calendar.current
        transactions = [
            PointsTransaction(
                id: "txn_001",
                type: .earned,
                points: 150,
                description: "SIP investment - HDFC Flexi Cap Fund",
                date: calendar.date(byAdding: .day, value: -2, to: Date())!
            ),
            PointsTransaction(
                id: "txn_002",
                type: .earned,
                points: 200,
                description: "Lump sum investment - Axis Bluechip Fund",
                date: calendar.date(byAdding: .day, value: -5, to: Date())!
            ),
            PointsTransaction(
                id: "txn_003",
                type: .bonus,
                points: 500,
                description: "Gold tier bonus reward",
                date: calendar.date(byAdding: .day, value: -10, to: Date())!
            ),
            PointsTransaction(
                id: "txn_004",
                type: .redeemed,
                points: 100,
                description: "Redeemed for ₹100 fee waiver",
                date: calendar.date(byAdding: .day, value: -15, to: Date())!
            ),
            PointsTransaction(
                id: "txn_005",
                type: .earned,
                points: 75,
                description: "SIP investment - Parag Parikh Flexi Cap",
                date: calendar.date(byAdding: .day, value: -18, to: Date())!
            ),
            PointsTransaction(
                id: "txn_006",
                type: .earned,
                points: 125,
                description: "New goal created - Retirement fund",
                date: calendar.date(byAdding: .day, value: -25, to: Date())!
            ),
            PointsTransaction(
                id: "txn_007",
                type: .expired,
                points: 50,
                description: "Points expired",
                date: calendar.date(byAdding: .day, value: -30, to: Date())!
            ),
            PointsTransaction(
                id: "txn_008",
                type: .earned,
                points: 300,
                description: "Referral bonus - Friend joined",
                date: calendar.date(byAdding: .day, value: -35, to: Date())!
            )
        ]
    }
}
