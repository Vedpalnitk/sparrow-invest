//
//  Family.swift
//  SparrowInvest
//
//  Family portfolio management models
//

import Foundation
import SwiftUI

// MARK: - Family Member

struct FamilyMember: Codable, Identifiable {
    let id: String
    var name: String
    var relationship: FamilyRelationship
    var email: String?
    var phone: String?
    var panNumber: String?
    var portfolioValue: Double
    var investedAmount: Double
    var returns: Double
    var returnsPercentage: Double
    var xirr: Double
    var contribution: Double // Percentage of family portfolio
    var holdings: Int
    var activeSIPs: Int
    var isLinked: Bool
    var isHead: Bool // Head of the family

    init(
        id: String = UUID().uuidString,
        name: String,
        relationship: FamilyRelationship,
        email: String? = nil,
        phone: String? = nil,
        panNumber: String? = nil,
        portfolioValue: Double,
        investedAmount: Double = 0,
        returns: Double = 0,
        returnsPercentage: Double = 0,
        xirr: Double = 0,
        contribution: Double = 0,
        holdings: Int = 0,
        activeSIPs: Int = 0,
        isLinked: Bool = false,
        isHead: Bool = false
    ) {
        self.id = id
        self.name = name
        self.relationship = relationship
        self.email = email
        self.phone = phone
        self.panNumber = panNumber
        self.portfolioValue = portfolioValue
        self.investedAmount = investedAmount
        self.returns = returns
        self.returnsPercentage = returnsPercentage
        self.xirr = xirr
        self.contribution = contribution
        self.holdings = holdings
        self.activeSIPs = activeSIPs
        self.isLinked = isLinked
        self.isHead = isHead
    }

    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    static var empty: FamilyMember {
        FamilyMember(
            name: "",
            relationship: .myself,
            portfolioValue: 0,
            isLinked: false
        )
    }
}

// MARK: - Family Relationship

enum FamilyRelationship: String, Codable, CaseIterable {
    case myself = "Self"
    case spouse = "Spouse"
    case child = "Child"
    case parent = "Parent"
    case sibling = "Sibling"
    case other = "Other"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .myself: return "person.fill"
        case .spouse: return "heart.fill"
        case .child: return "figure.child"
        case .parent: return "figure.stand"
        case .sibling: return "person.2.fill"
        case .other: return "person.fill.questionmark"
        }
    }

    var color: Color {
        switch self {
        case .myself: return Color(hex: "#3B82F6")
        case .spouse: return Color(hex: "#EC4899")
        case .child: return Color(hex: "#10B981")
        case .parent: return Color(hex: "#8B5CF6")
        case .sibling: return Color(hex: "#F59E0B")
        case .other: return Color(hex: "#64748B")
        }
    }
}

// MARK: - Family Portfolio

struct FamilyPortfolio: Codable {
    var members: [FamilyMember]
    var totalValue: Double
    var totalInvested: Double
    var totalReturns: Double
    var returnsPercentage: Double
    var familyXIRR: Double

    init(
        members: [FamilyMember] = [],
        totalValue: Double = 0,
        totalInvested: Double = 0,
        totalReturns: Double = 0,
        returnsPercentage: Double = 0,
        familyXIRR: Double = 0
    ) {
        self.members = members
        self.totalValue = totalValue
        self.totalInvested = totalInvested
        self.totalReturns = totalReturns
        self.returnsPercentage = returnsPercentage
        self.familyXIRR = familyXIRR
    }

    static var empty: FamilyPortfolio {
        FamilyPortfolio()
    }

    var linkedMembers: [FamilyMember] {
        members.filter { $0.isLinked }
    }

    func contributionPercentage(for member: FamilyMember) -> Double {
        guard totalValue > 0 else { return 0 }
        return (member.portfolioValue / totalValue) * 100
    }
}
