//
//  FamilyStore.swift
//  SparrowInvest
//
//  Family portfolio management
//

import Foundation
import SwiftUI

@MainActor
class FamilyStore: ObservableObject {
    @Published var familyPortfolio: FamilyPortfolio = .empty
    @Published var selectedMemberId: String?
    @Published var isLoading: Bool = false

    init() {
        loadMockData()
    }

    // MARK: - Data Loading

    func loadMockData() {
        let members = [
            FamilyMember(
                name: "Rahul Sharma",
                relationship: .myself,
                email: "rahul.sharma@email.com",
                phone: "+91 98765 43210",
                panNumber: "ABCDE1234F",
                portfolioValue: 1_250_000,
                investedAmount: 1_000_000,
                returns: 250_000,
                returnsPercentage: 25.0,
                xirr: 18.5,
                contribution: 48.5,
                holdings: 12,
                activeSIPs: 5,
                isLinked: true
            ),
            FamilyMember(
                name: "Priya Sharma",
                relationship: .spouse,
                email: "priya.sharma@email.com",
                portfolioValue: 850_000,
                investedAmount: 700_000,
                returns: 150_000,
                returnsPercentage: 21.4,
                xirr: 15.2,
                contribution: 33.0,
                holdings: 8,
                activeSIPs: 3,
                isLinked: true
            ),
            FamilyMember(
                name: "Aarav Sharma",
                relationship: .child,
                portfolioValue: 350_000,
                investedAmount: 300_000,
                returns: 50_000,
                returnsPercentage: 16.7,
                xirr: 12.8,
                contribution: 13.5,
                holdings: 4,
                activeSIPs: 2,
                isLinked: true
            ),
            FamilyMember(
                name: "Sunita Sharma",
                relationship: .parent,
                portfolioValue: 125_000,
                investedAmount: 100_000,
                returns: 25_000,
                returnsPercentage: 25.0,
                xirr: 14.5,
                contribution: 5.0,
                holdings: 2,
                activeSIPs: 1,
                isLinked: false
            )
        ]

        let totalValue = members.reduce(0) { $0 + $1.portfolioValue }
        let totalInvested = members.reduce(0) { $0 + $1.investedAmount }
        let totalReturns = totalValue - totalInvested
        let returnsPercentage = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0

        familyPortfolio = FamilyPortfolio(
            members: members,
            totalValue: totalValue,
            totalInvested: totalInvested,
            totalReturns: totalReturns,
            returnsPercentage: returnsPercentage,
            familyXIRR: 16.2
        )

        // Select first member by default
        selectedMemberId = members.first?.id
    }

    func refreshData() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadMockData()
        isLoading = false
    }

    // MARK: - Member Management

    var selectedMember: FamilyMember? {
        familyPortfolio.members.first { $0.id == selectedMemberId }
    }

    func selectMember(_ member: FamilyMember) {
        selectedMemberId = member.id
    }

    func addMember(_ member: FamilyMember) {
        var updatedMembers = familyPortfolio.members
        updatedMembers.append(member)
        recalculateFamilyPortfolio(with: updatedMembers)
    }

    func removeMember(_ member: FamilyMember) {
        var updatedMembers = familyPortfolio.members
        updatedMembers.removeAll { $0.id == member.id }
        recalculateFamilyPortfolio(with: updatedMembers)
    }

    func toggleMemberLink(_ member: FamilyMember) {
        if let index = familyPortfolio.members.firstIndex(where: { $0.id == member.id }) {
            var updatedMember = familyPortfolio.members[index]
            updatedMember.isLinked.toggle()
            var updatedMembers = familyPortfolio.members
            updatedMembers[index] = updatedMember
            recalculateFamilyPortfolio(with: updatedMembers)
        }
    }

    private func recalculateFamilyPortfolio(with members: [FamilyMember]) {
        let linkedMembers = members.filter { $0.isLinked }
        let totalValue = linkedMembers.reduce(0) { $0 + $1.portfolioValue }
        let totalInvested = linkedMembers.reduce(0) { $0 + $1.investedAmount }
        let totalReturns = totalValue - totalInvested
        let returnsPercentage = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0

        // Recalculate contributions
        var updatedMembers = members.map { member -> FamilyMember in
            var updated = member
            if member.isLinked && totalValue > 0 {
                updated.contribution = (member.portfolioValue / totalValue) * 100
            } else {
                updated.contribution = 0
            }
            return updated
        }

        familyPortfolio = FamilyPortfolio(
            members: updatedMembers,
            totalValue: totalValue,
            totalInvested: totalInvested,
            totalReturns: totalReturns,
            returnsPercentage: returnsPercentage,
            familyXIRR: calculateFamilyXIRR(members: linkedMembers)
        )
    }

    private func calculateFamilyXIRR(members: [FamilyMember]) -> Double {
        guard !members.isEmpty else { return 0 }
        // Weighted average of individual XIRRs
        let totalValue = members.reduce(0) { $0 + $1.portfolioValue }
        let weightedXIRR = members.reduce(0) { result, member in
            let weight = totalValue > 0 ? member.portfolioValue / totalValue : 0
            return result + (member.xirr * weight)
        }
        return weightedXIRR
    }

    // MARK: - Computed Properties

    var linkedMembers: [FamilyMember] {
        familyPortfolio.members.filter { $0.isLinked }
    }

    var unlinkedMembers: [FamilyMember] {
        familyPortfolio.members.filter { !$0.isLinked }
    }

    var topContributor: FamilyMember? {
        familyPortfolio.members.max { $0.portfolioValue < $1.portfolioValue }
    }

    var bestPerformer: FamilyMember? {
        familyPortfolio.members.max { $0.xirr < $1.xirr }
    }

    var totalActiveSIPs: Int {
        familyPortfolio.members.reduce(0) { $0 + $1.activeSIPs }
    }

    var totalHoldings: Int {
        familyPortfolio.members.reduce(0) { $0 + $1.holdings }
    }

    // MARK: - Asset Allocation

    /// Combined family asset allocation (sum of all linked members)
    var familyAssetAllocation: AssetAllocation {
        let linked = linkedMembers
        guard !linked.isEmpty else {
            return AssetAllocation(equity: 0, debt: 0, hybrid: 0, gold: 0, other: 0)
        }

        // Sum up allocations from all linked members
        var totalEquity: Double = 0
        var totalDebt: Double = 0
        var totalHybrid: Double = 0
        var totalGold: Double = 0
        var totalOther: Double = 0

        for member in linked {
            if let allocation = memberAssetAllocations[member.id] {
                totalEquity += allocation.equity
                totalDebt += allocation.debt
                totalHybrid += allocation.hybrid
                totalGold += allocation.gold
                totalOther += allocation.other
            }
        }

        return AssetAllocation(
            equity: totalEquity,
            debt: totalDebt,
            hybrid: totalHybrid,
            gold: totalGold,
            other: totalOther
        )
    }

    /// Asset allocation for each family member (mock data)
    var memberAssetAllocations: [String: AssetAllocation] {
        var allocations: [String: AssetAllocation] = [:]

        for member in familyPortfolio.members {
            // Generate allocation based on member's portfolio value and relationship
            let allocation = generateMockAllocation(for: member)
            allocations[member.id] = allocation
        }

        return allocations
    }

    private func generateMockAllocation(for member: FamilyMember) -> AssetAllocation {
        let total = member.portfolioValue

        // Different allocation profiles based on relationship
        switch member.relationship {
        case .myself:
            // Balanced growth portfolio
            return AssetAllocation(
                equity: total * 0.60,
                debt: total * 0.25,
                hybrid: total * 0.10,
                gold: total * 0.05,
                other: 0
            )
        case .spouse:
            // Moderate portfolio
            return AssetAllocation(
                equity: total * 0.50,
                debt: total * 0.30,
                hybrid: total * 0.12,
                gold: total * 0.08,
                other: 0
            )
        case .child:
            // Aggressive growth for long horizon
            return AssetAllocation(
                equity: total * 0.75,
                debt: total * 0.10,
                hybrid: total * 0.10,
                gold: total * 0.05,
                other: 0
            )
        case .parent:
            // Conservative portfolio
            return AssetAllocation(
                equity: total * 0.30,
                debt: total * 0.50,
                hybrid: total * 0.10,
                gold: total * 0.10,
                other: 0
            )
        case .sibling, .other:
            // Balanced portfolio
            return AssetAllocation(
                equity: total * 0.55,
                debt: total * 0.30,
                hybrid: total * 0.10,
                gold: total * 0.05,
                other: 0
            )
        }
    }
}
