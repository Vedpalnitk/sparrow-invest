import SwiftUI

// MARK: - Trend Bar Chart

struct TrendBarChart: View {
    let data: [(String, Double)]
    let color: Color

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var animationProgress: CGFloat = 0

    private let chartHeight: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            let barCount = CGFloat(data.count)
            let totalSpacing = AppTheme.Spacing.small * (barCount - 1)
            let barWidth = max(0, (geometry.size.width - totalSpacing) / barCount)

            HStack(alignment: .bottom, spacing: AppTheme.Spacing.small) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: AppTheme.Spacing.micro) {
                        // Bar
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: max(4, chartHeight * item.1 * animationProgress)
                            )

                        // Label
                        Text(item.0)
                            .font(AppTheme.Typography.label(iPad ? 12 : 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: chartHeight + 20)
        .onAppear {
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        TrendBarChart(
            data: [("Sep", 0.6), ("Oct", 0.7), ("Nov", 0.65), ("Dec", 0.8), ("Jan", 0.85), ("Feb", 0.9)],
            color: AppTheme.primary
        )
        .padding()
    }
    .glassCard()
    .padding()
}
