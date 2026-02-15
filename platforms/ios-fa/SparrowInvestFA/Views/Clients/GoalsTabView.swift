import SwiftUI

struct GoalsTabView: View {
    let goals: [FAGoal]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        if goals.isEmpty {
            emptyState
        } else {
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(goals) { goal in
                    goalCard(goal)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "flag")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No goals set")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Create investment goals to track progress")
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }

    // MARK: - Goal Card

    private func goalCard(_ goal: FAGoal) -> some View {
        let statusColor = Color(hex: goal.statusColor)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Top row: icon + name + date
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: goal.categoryIcon)
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Target: \(goal.targetDate)")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                Text(goal.statusLabel)
                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Progress bar
            VStack(spacing: AppTheme.Spacing.micro) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)

                        // Fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primary, statusColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * goal.progress, height: 6)
                    }
                }
                .frame(height: 6)

                // Amount row
                HStack {
                    Text(AppTheme.formatCurrencyWithSymbol(goal.currentAmount))
                        .font(AppTheme.Typography.numeric(iPad ? 15 : 13))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(String(format: "%.0f%%", goal.progress * 100))
                        .font(AppTheme.Typography.accent(iPad ? 13 : 11))
                        .foregroundColor(statusColor)

                    Spacer()

                    Text(AppTheme.formatCurrencyWithSymbol(goal.targetAmount))
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }
            }

            // Monthly required
            if let monthly = goal.monthlyRequired, monthly > 0 {
                HStack(spacing: AppTheme.Spacing.micro) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("\(AppTheme.formatCurrencyWithSymbol(monthly))/mo needed")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 8),
            alignment: .leading
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        GoalsTabView(goals: [
            FAGoal(
                id: "1", clientId: "c1", name: "Retirement Fund",
                targetAmount: 5_000_000, currentAmount: 1_250_000,
                targetDate: "2045-01-01", status: "ON_TRACK",
                category: "Retirement", monthlyRequired: 15000,
                createdAt: nil
            ),
            FAGoal(
                id: "2", clientId: "c1", name: "Child Education",
                targetAmount: 2_000_000, currentAmount: 800_000,
                targetDate: "2030-06-01", status: "AT_RISK",
                category: "Education", monthlyRequired: 25000,
                createdAt: nil
            ),
            FAGoal(
                id: "3", clientId: "c1", name: "Dream Home",
                targetAmount: 10_000_000, currentAmount: 1_500_000,
                targetDate: "2035-12-01", status: "OFF_TRACK",
                category: "Home", monthlyRequired: 45000,
                createdAt: nil
            )
        ])
    }
}
