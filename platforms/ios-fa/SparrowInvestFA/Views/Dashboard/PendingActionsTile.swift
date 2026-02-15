import SwiftUI

struct PendingActionsTile: View {
    let transactions: [FATransaction]
    let onViewAll: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    private var pending: [FATransaction] { Array(transactions.prefix(5)) }

    private var totalPendingAmount: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    private var transactionTypeCounts: [(type: String, count: Int, color: Color)] {
        var counts: [String: Int] = [:]
        for tx in transactions {
            counts[tx.type, default: 0] += 1
        }
        return counts.map { (type: $0.key, count: $0.value, color: colorForType($0.key)) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Header
            HStack {
                Text("Pending Actions")
                    .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                    .foregroundColor(.primary)

                Spacer()

                if transactions.count > 5 {
                    Button { onViewAll() } label: {
                        Text("View All")
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }

            // Summary stats
            if !transactions.isEmpty {
                HStack(spacing: 0) {
                    pendingStat(
                        value: "\(transactions.count)",
                        label: "Pending",
                        color: AppTheme.warning
                    )

                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 32)

                    pendingStat(
                        value: AppTheme.formatCurrencyWithSymbol(totalPendingAmount),
                        label: "Total Value",
                        color: AppTheme.primary
                    )

                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 1, height: 32)

                    pendingStat(
                        value: "\(transactionTypeCounts.count)",
                        label: "Types",
                        color: AppTheme.info
                    )
                }
                .padding(.vertical, AppTheme.Spacing.small)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
            }

            // Content
            if transactions.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(pending) { tx in
                        NavigationLink {
                            TransactionDetailView(transactionId: tx.id)
                        } label: {
                            actionRow(tx)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // View All button at bottom
                if transactions.count > 5 {
                    Button { onViewAll() } label: {
                        Text("View All \(transactions.count) Actions")
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                            .foregroundColor(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.small)
                    }
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.xLarge, padding: AppTheme.Spacing.medium)
    }

    // MARK: - Stat

    private func pendingStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(AppTheme.Typography.numeric(iPad ? 22 : 18))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(AppTheme.Typography.label(iPad ? 14 : 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Row

    private func actionRow(_ tx: FATransaction) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(colorForType(tx.type).opacity(0.1))
                    .frame(width: iPad ? 44 : 40, height: iPad ? 44 : 40)

                Image(systemName: iconForType(tx.type))
                    .font(.system(size: iPad ? 18 : 16))
                    .foregroundColor(colorForType(tx.type))
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.clientName)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(tx.type) \u{2022} \(tx.fundName)")
                    .font(AppTheme.Typography.label(iPad ? 15 : 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text(tx.formattedAmount)
                .font(AppTheme.Typography.numeric(iPad ? 17 : 14))
                .foregroundColor(.primary)
        }
        .padding(AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : colorForType(tx.type).opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : colorForType(tx.type).opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.success.opacity(0.5))

            Text("All caught up!")
                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xLarge)
    }

    // MARK: - Helpers

    private func iconForType(_ type: String) -> String {
        switch type.uppercased() {
        case "BUY", "INVEST": return "arrow.down.circle"
        case "SELL", "REDEEM": return "arrow.up.circle"
        case "SIP": return "arrow.triangle.2.circlepath"
        case "SWITCH": return "arrow.left.arrow.right"
        default: return "clock.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type.uppercased() {
        case "BUY", "INVEST": return AppTheme.success
        case "SELL", "REDEEM": return AppTheme.error
        case "SIP": return AppTheme.primary
        case "SWITCH": return AppTheme.info
        default: return AppTheme.warning
        }
    }
}
