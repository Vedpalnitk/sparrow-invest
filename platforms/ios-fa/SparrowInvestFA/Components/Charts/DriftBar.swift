import SwiftUI

// MARK: - Drift Bar

struct DriftBar: View {
    let assetClass: String
    let current: Double
    let target: Double
    let deviation: Double

    @Environment(\.colorScheme) private var colorScheme

    private var barColor: Color {
        let absDev = abs(deviation)
        if absDev > 10 { return AppTheme.error }
        if absDev > 5 { return AppTheme.warning }
        return AppTheme.primary
    }

    private var deviationText: String {
        String(format: "%+.1f%%", deviation)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.micro) {
            HStack {
                Text(assetClass)
                    .font(AppTheme.Typography.accent(13))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: AppTheme.Spacing.micro) {
                    Text(String(format: "%.0f%%", current))
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.primary)

                    Text("/")
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.secondary)

                    Text(String(format: "%.0f%%", target))
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.secondary)

                    deviationBadge
                }
            }

            // Bar
            GeometryReader { geometry in
                let barWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)

                    // Current allocation bar
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(barColor)
                        .frame(width: max(0, min(barWidth, barWidth * current / 100)), height: 12)

                    // Target marker
                    let targetX = barWidth * target / 100
                    Rectangle()
                        .stroke(
                            AppTheme.secondary,
                            style: StrokeStyle(lineWidth: 2, dash: [3, 2])
                        )
                        .frame(width: 2, height: 18)
                        .offset(x: max(0, min(barWidth - 2, targetX - 1)))
                }
            }
            .frame(height: 18)
        }
    }

    private var deviationBadge: some View {
        let absDev = abs(deviation)
        let badgeColor: Color = absDev > 5 ? AppTheme.error : .secondary

        return Text(deviationText)
            .font(AppTheme.Typography.label(10))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppTheme.Spacing.medium) {
        DriftBar(assetClass: "Large Cap Equity", current: 45, target: 40, deviation: 5)
        DriftBar(assetClass: "Debt", current: 20, target: 30, deviation: -10)
        DriftBar(assetClass: "Mid Cap", current: 18, target: 15, deviation: 3)
    }
    .padding()
}
