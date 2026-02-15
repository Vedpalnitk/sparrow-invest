import SwiftUI

struct GapAnalysisCard: View {
    let gapAnalysis: GapAnalysis?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }

                Text("Coverage Gap Analysis")
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Spacer()
            }

            if let gap = gapAnalysis {
                coverageBar(
                    label: "Life Insurance",
                    icon: "shield.checkered",
                    current: gap.life.current,
                    recommended: gap.life.recommended,
                    adequate: gap.life.adequate
                )

                coverageBar(
                    label: "Health Insurance",
                    icon: "heart.text.square",
                    current: gap.health.current,
                    recommended: gap.health.recommended,
                    adequate: gap.health.adequate
                )
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, AppTheme.Spacing.medium)
                    Spacer()
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
    }

    private func coverageBar(label: String, icon: String, current: Double, recommended: Double, adequate: Bool) -> some View {
        let progress = recommended > 0 ? min(current / recommended, 1.0) : 0
        let barColor = adequate ? Color(hex: "10B981") : Color(hex: "EF4444")

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(barColor)

                Text(label)
                    .font(AppTheme.Typography.accent(12))
                    .foregroundColor(.primary)

                Spacer()

                if adequate {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Adequate")
                            .font(AppTheme.Typography.label(10))
                    }
                    .foregroundColor(Color(hex: "10B981"))
                } else {
                    Text("Gap: \(formatAmount(recommended - current))")
                        .font(AppTheme.Typography.label(10))
                        .foregroundColor(Color(hex: "EF4444"))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [barColor, barColor.opacity(0.7)]),
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Current: \(formatAmount(current))")
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.secondary)

                Spacer()

                Text("Recommended: \(formatAmount(recommended))")
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        )
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000000 {
            return String(format: "₹%.1f Cr", amount / 10000000)
        } else if amount >= 100000 {
            return String(format: "₹%.1f L", amount / 100000)
        }
        return String(format: "₹%.0f", amount)
    }
}
