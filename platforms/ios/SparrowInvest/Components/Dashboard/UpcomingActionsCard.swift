//
//  UpcomingActionsCard.swift
//  SparrowInvest
//
//  Upcoming actions and alerts card
//

import SwiftUI

struct UpcomingActionsCard: View {
    let actions: [UpcomingAction]
    var onComplete: ((UpcomingAction) -> Void)?
    var onDismiss: ((UpcomingAction) -> Void)?

    private var activeActions: [UpcomingAction] {
        actions.filter { !$0.isCompleted && !$0.isDismissed }.sortedByPriority
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("Upcoming Actions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    if actions.highPriorityCount > 0 {
                        Text("\(actions.highPriorityCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(AppTheme.error))
                    }
                }

                Spacer()

                NavigationLink(destination: Text("All Actions")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Actions List
            if activeActions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.success)
                    Text("All caught up!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(activeActions.prefix(4))) { action in
                        ActionRow(
                            action: action,
                            onComplete: { onComplete?(action) },
                            onDismiss: { onDismiss?(action) }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

struct ActionRow: View {
    let action: UpcomingAction
    var onComplete: (() -> Void)?
    var onDismiss: (() -> Void)?

    private var priorityColor: Color {
        switch action.priority {
        case .high: return AppTheme.error
        case .medium: return Color(hex: "#F59E0B")
        case .low: return AppTheme.success
        }
    }

    private var typeColor: Color {
        Color(hex: action.type.color == "primary" ? "#3B82F6" :
                    action.type.color == "secondary" ? "#8B5CF6" :
                    action.type.color == "success" ? "#10B981" :
                    action.type.color == "warning" ? "#F59E0B" :
                    action.type.color == "error" ? "#EF4444" : "#64748B")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Priority Indicator
            Rectangle()
                .fill(priorityColor)
                .frame(width: 3)
                .cornerRadius(2)

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: action.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(typeColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(action.dueDateFormatted)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(action.isOverdue ? AppTheme.error : AppTheme.textSecondary)

                    if action.isOverdue {
                        Text("Overdue")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.error)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.error.opacity(0.1))
                            )
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onComplete?()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.success)
                }

                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.chipBackground)
        )
    }
}

#Preview {
    UpcomingActionsCard(actions: [])
        .padding()
}
