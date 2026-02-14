import SwiftUI

// MARK: - Allocation Donut Chart

struct AllocationDonutChart: View {
    let data: [AssetAllocationItem]
    let totalValue: Double
    var title: String? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var animationProgress: CGFloat = 0
    @State private var selectedSlice: String? = nil

    private let outerRadiusFraction: CGFloat = 0.42
    private let innerRadiusFraction: CGFloat = 0.25

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            if let title {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                    Text(title)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                    Spacer()
                }
            }

            if data.isEmpty {
                emptyPlaceholder
            } else {
                donutChart
                legend
            }
        }
        .onAppear {
            animationProgress = 0
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1
            }
        }
    }

    // MARK: - Donut Chart

    private var donutChart: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: size / 2)
            let outerRadius = size * outerRadiusFraction
            let innerRadius = size * innerRadiusFraction

            ZStack {
                Canvas { context, canvasSize in
                    let totalPercentage = data.reduce(0) { $0 + $1.percentage }
                    guard totalPercentage > 0 else { return }

                    var startAngle: Double = -90
                    for item in data {
                        let sweepAngle = (item.percentage / totalPercentage) * 360 * Double(animationProgress)
                        let endAngle = startAngle + sweepAngle

                        var segmentPath = Path()
                        segmentPath.addArc(
                            center: center,
                            radius: outerRadius,
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            clockwise: false
                        )
                        segmentPath.addArc(
                            center: center,
                            radius: innerRadius,
                            startAngle: .degrees(endAngle),
                            endAngle: .degrees(startAngle),
                            clockwise: true
                        )
                        segmentPath.closeSubpath()

                        context.fill(segmentPath, with: .color(Color(hex: item.color)))

                        startAngle = endAngle
                    }
                }

                // Center text
                VStack(spacing: 2) {
                    Text("Total")
                        .font(AppTheme.Typography.label(10))
                        .foregroundColor(.secondary)

                    Text(AppTheme.formatCurrencyWithSymbol(totalValue))
                        .font(AppTheme.Typography.headline(16))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: innerRadius * 1.6)
                .position(center)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Legend

    private var legend: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppTheme.Spacing.small),
            GridItem(.flexible(), spacing: AppTheme.Spacing.small)
        ]

        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
            ForEach(data, id: \.assetClass) { item in
                HStack(spacing: AppTheme.Spacing.small) {
                    Circle()
                        .fill(Color(hex: item.color))
                        .frame(width: 10, height: 10)

                    Text(item.assetClass)
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.1f%%", item.percentage))
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Empty Placeholder

    private var emptyPlaceholder: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "chart.pie")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No allocation data")
                .font(AppTheme.Typography.accent(14))
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}
