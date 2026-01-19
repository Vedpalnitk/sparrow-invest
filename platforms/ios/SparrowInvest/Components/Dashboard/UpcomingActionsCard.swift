//
//  UpcomingActionsCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Upcoming Actions Card
//

import SwiftUI

struct UpcomingActionsCard: View {
    let actions: [UpcomingAction]
    var onComplete: ((UpcomingAction) -> Void)?
    var onDismiss: ((UpcomingAction) -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    private var activeActions: [UpcomingAction] {
        actions.filter { !$0.isCompleted && !$0.isDismissed }.sortedByPriority
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("Upcoming Actions")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    if actions.highPriorityCount > 0 {
                        Text("\(actions.highPriorityCount)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.red))
                    }
                }

                Spacer()

                NavigationLink(destination: Text("All Actions")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .light))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
            }

            // Actions List
            if activeActions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
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
        .padding(AppTheme.Spacing.medium)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

struct ActionRow: View {
    let action: UpcomingAction
    var onComplete: (() -> Void)?
    var onDismiss: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    private var priorityColor: Color {
        switch action.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    private var typeColor: Color {
        switch action.type.color {
        case "primary": return .blue
        case "secondary": return .purple
        case "success": return .green
        case "warning": return .orange
        case "error": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Priority Indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor)
                .frame(width: 3)

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: action.type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(typeColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(action.dueDateFormatted)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(action.isOverdue ? .red : .secondary)

                    if action.isOverdue {
                        Text("Overdue")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Color.red.opacity(0.1),
                                in: Capsule()
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
                        .foregroundColor(.green)
                }

                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 22))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
        }
        .padding(10)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color(uiColor: .tertiarySystemFill),
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
        )
    }
}

#Preview {
    UpcomingActionsCard(actions: [])
        .padding()
}
