//
//  UpcomingAction.swift
//  SparrowInvest
//
//  Upcoming actions and alerts models
//

import Foundation
import SwiftUI

// MARK: - Upcoming Action

struct UpcomingAction: Codable, Identifiable {
    let id: String
    let type: ActionType
    let title: String
    let description: String
    let dueDate: Date
    let priority: ActionPriority
    var amount: Double?
    var fundCode: String?
    var goalId: String?
    var isCompleted: Bool
    var isDismissed: Bool

    init(
        id: String = UUID().uuidString,
        type: ActionType,
        title: String,
        description: String,
        dueDate: Date,
        priority: ActionPriority,
        amount: Double? = nil,
        fundCode: String? = nil,
        goalId: String? = nil,
        isCompleted: Bool = false,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.amount = amount
        self.fundCode = fundCode
        self.goalId = goalId
        self.isCompleted = isCompleted
        self.isDismissed = isDismissed
    }

    var isOverdue: Bool {
        dueDate < Date()
    }

    var dueDateFormatted: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(dueDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if let daysUntil = calendar.dateComponents([.day], from: Date(), to: dueDate).day, daysUntil < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dueDate)
        } else {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: dueDate)
        }
    }
}

// MARK: - Action Type

enum ActionType: String, Codable {
    case sipDue = "sip_due"
    case rebalance = "rebalance"
    case goalDeadline = "goal_deadline"
    case taxHarvest = "tax_harvest"
    case fundAlert = "fund_alert"
    case kycExpiry = "kyc_expiry"

    var icon: String {
        switch self {
        case .sipDue: return "calendar.badge.clock"
        case .rebalance: return "arrow.triangle.2.circlepath"
        case .goalDeadline: return "target"
        case .taxHarvest: return "indianrupeesign.circle"
        case .fundAlert: return "exclamationmark.triangle"
        case .kycExpiry: return "person.badge.clock"
        }
    }

    var color: String {
        switch self {
        case .sipDue: return "primary"
        case .rebalance: return "secondary"
        case .goalDeadline: return "warning"
        case .taxHarvest: return "success"
        case .fundAlert: return "error"
        case .kycExpiry: return "warning"
        }
    }
}

// MARK: - Action Priority

enum ActionPriority: String, Codable, Comparable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Array Extensions

extension Array where Element == UpcomingAction {
    var sortedByPriority: [UpcomingAction] {
        sorted { $0.priority < $1.priority }
    }

    var highPriorityCount: Int {
        filter { $0.priority == .high && !$0.isCompleted && !$0.isDismissed }.count
    }
}
