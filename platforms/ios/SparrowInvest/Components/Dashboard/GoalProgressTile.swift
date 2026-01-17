//
//  GoalProgressTile.swift
//  SparrowInvest
//
//  Goal progress summary tile
//

import SwiftUI

struct GoalProgressTile: View {
    let goals: [Goal]
    var onTapGoal: ((Goal) -> Void)?

    private var displayGoals: [Goal] {
        Array(goals.sorted { $0.progress > $1.progress }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Goal Progress")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                NavigationLink(destination: GoalsView()) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Goals List
            if goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No goals set yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Button {
                        // Create goal action
                    } label: {
                        Text("Create Your First Goal")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.primaryDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(displayGoals) { goal in
                        GoalProgressRow(goal: goal)
                            .onTapGesture {
                                onTapGoal?(goal)
                            }
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

struct GoalProgressRow: View {
    let goal: Goal

    private var progressPercentage: Double {
        goal.progress * 100
    }

    private var progressColor: Color {
        if progressPercentage >= 80 {
            return AppTheme.success
        } else if progressPercentage >= 50 {
            return AppTheme.primary
        } else {
            return Color(hex: "#F59E0B")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Goal Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: goal.category.systemIcon)
                        .font(.system(size: 16))
                        .foregroundColor(progressColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(goal.timeRemaining)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progressPercentage))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(progressColor)

                    Text(goal.currentAmount.compactCurrencyFormatted)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * goal.progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.chipBackground)
        )
    }
}

// Extension for GoalCategory to provide SF Symbol icon
extension GoalCategory {
    var systemIcon: String {
        switch self {
        case .retirement: return "beach.umbrella"
        case .education: return "graduationcap.fill"
        case .home: return "house.fill"
        case .car: return "car.fill"
        case .vacation: return "airplane"
        case .wedding: return "heart.circle.fill"
        case .emergency: return "cross.case.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .custom: return "star.fill"
        }
    }
}

#Preview {
    GoalProgressTile(goals: [])
        .padding()
}
