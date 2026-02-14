import SwiftUI

// MARK: - KPI Detail Sheet

struct KpiDetailSheet: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let growth: KpiGrowth?
    let kpiType: String
    let topPerformers: [FAClient]

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDataIndex: Int? = nil
    @State private var chartDrawProgress: CGFloat = 0
    @State private var selectedPeriod = "6M"

    init(title: String, value: String, icon: String, color: Color, growth: KpiGrowth?,
         kpiType: String = "", topPerformers: [FAClient] = []) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.growth = growth
        self.kpiType = kpiType
        self.topPerformers = topPerformers
    }

    private let periods = ["1W", "1M", "3M", "6M", "1Y"]

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var trendData: [(String, Double)] {
        generateTrendData(for: selectedPeriod)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                headerSection

                if let growth {
                    growthPills(growth)
                }

                if !trendData.isEmpty {
                    trendChartSection
                }

                // Top Performers (Returns KPI only)
                if kpiType == "Returns" && !topPerformers.isEmpty {
                    topPerformersSection
                }

                if let growth, !growth.breakdown.isEmpty {
                    breakdownSection(growth.breakdown)
                }

                Spacer().frame(height: AppTheme.Spacing.large)
            }
        }
        .background(AppTheme.groupedBackground)
    }

    // MARK: - Compact Header

    private var headerSection: some View {
        ZStack {
            Rectangle().fill(headerGradient)

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(x: 80, y: -30)
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 140, height: 140)
                .offset(x: -100, y: 40)

            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(AppTheme.Typography.accent(11))
                        .tracking(1.0)
                        .foregroundColor(.white.opacity(0.7))

                    Text(value)
                        .font(AppTheme.Typography.display(28))
                        .foregroundColor(.white)
                }

                Spacer()

                // Close button
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .clipped()
    }

    // MARK: - Growth Pills (4 pills in 2x2 grid)

    private func growthPills(_ growth: KpiGrowth) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
            growthPill(
                label: "MoM Change",
                change: growth.momChange,
                absolute: growth.momAbsolute,
                isPositive: growth.isMomPositive
            )

            growthPill(
                label: "YoY Change",
                change: growth.yoyChange,
                absolute: growth.yoyAbsolute,
                isPositive: growth.yoyChange >= 0
            )

            statPill(
                label: "Prev Month",
                value: formatAbsoluteValue(growth.momAbsolute),
                icon: "calendar.badge.clock"
            )

            statPill(
                label: "Current",
                value: value,
                icon: "chart.bar.fill"
            )
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    /// Format absolute values based on KPI type
    private func formatAbsoluteValue(_ val: Double) -> String {
        switch kpiType {
        case "Returns":
            return String(format: "%+.1f%%", val)
        case "Clients":
            return "\(Int(abs(val)))"
        default:
            return AppTheme.formatCurrencyWithSymbol(abs(val))
        }
    }

    private func growthPill(label: String, change: Double, absolute: Double, isPositive: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.micro) {
            HStack(spacing: AppTheme.Spacing.micro) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 14))
                    .foregroundColor(isPositive ? AppTheme.success : AppTheme.error)

                Text(String(format: "%+.1f%%", change))
                    .font(AppTheme.Typography.accent(18))
                    .foregroundColor(isPositive ? AppTheme.success : AppTheme.error)
            }

            Text(label)
                .font(AppTheme.Typography.label(13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
        )
    }

    private func statPill(label: String, value: String, icon: String) -> some View {
        VStack(spacing: AppTheme.Spacing.micro) {
            HStack(spacing: AppTheme.Spacing.micro) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(value)
                    .font(AppTheme.Typography.accent(16))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(label)
                .font(AppTheme.Typography.label(13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
        )
    }

    // MARK: - Trend Chart

    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack {
                Text("Trend")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Spacer()

                // Inline period selector
                HStack(spacing: 2) {
                    ForEach(periods, id: \.self) { period in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedPeriod = period
                                chartDrawProgress = 0
                                selectedDataIndex = nil
                            }
                            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                                chartDrawProgress = 1
                            }
                        } label: {
                            Text(period)
                                .font(AppTheme.Typography.accent(11))
                                .foregroundColor(selectedPeriod == period ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(selectedPeriod == period ? color : Color.clear)
                                )
                        }
                    }
                }
                .padding(2)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                )
            }

            interactiveAreaChart
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Interactive Area Chart

    private var interactiveAreaChart: some View {
        let data = trendData

        return GeometryReader { geo in
            let chartWidth = geo.size.width
            let chartHeight = geo.size.height - 24
            let values = data.map(\.1)
            let maxVal = values.max() ?? 1
            let minVal = (values.min() ?? 0) * 0.85
            let range = max(maxVal - minVal, 0.01)

            let points: [CGPoint] = data.enumerated().map { i, item in
                let x = data.count > 1
                    ? chartWidth * CGFloat(i) / CGFloat(data.count - 1)
                    : chartWidth / 2
                let normalized = CGFloat((item.1 - minVal) / range)
                let y = (chartHeight - 16) * (1 - normalized) + 8
                return CGPoint(x: x, y: y)
            }

            ZStack(alignment: .topLeading) {
                // Dashed grid lines
                ForEach(0..<4, id: \.self) { i in
                    let y = chartHeight * CGFloat(i + 1) / 5.0
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: chartWidth, y: y))
                    }
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color.gray.opacity(0.15),
                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                    )
                }

                // Gradient area fill (revealed left-to-right)
                makeAreaPath(points: points, bottomY: chartHeight)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(alignment: .leading) {
                        Color.black
                            .frame(width: max(1, chartWidth * chartDrawProgress))
                    }

                // Smooth curve line
                makeSmoothPath(through: points)
                    .trim(from: 0, to: chartDrawProgress)
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )

                // Data point dots (appear sequentially as line draws)
                ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                    let fraction = data.count > 1 ? CGFloat(i) / CGFloat(data.count - 1) : 0
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(color, lineWidth: 2))
                        .position(point)
                        .opacity(chartDrawProgress > fraction + 0.05 && selectedDataIndex != i ? 1 : 0)
                }

                // Selected point indicator + tooltip
                if let idx = selectedDataIndex, idx < points.count {
                    let point = points[idx]
                    let item = data[idx]

                    // Vertical dashed indicator
                    Path { p in
                        p.move(to: CGPoint(x: point.x, y: 0))
                        p.addLine(to: CGPoint(x: point.x, y: chartHeight))
                    }
                    .stroke(color.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    // Glow dot
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .shadow(color: color.opacity(0.4), radius: 6)
                        .position(point)

                    // Floating tooltip
                    tooltipView(label: item.0, value: item.1)
                        .position(
                            x: clampTooltipX(point.x, in: chartWidth),
                            y: max(20, point.y - 34)
                        )
                }

                // X-axis labels
                HStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { i, item in
                        if i > 0 { Spacer() }
                        Text(item.0)
                            .font(AppTheme.Typography.label(10))
                            .foregroundColor(selectedDataIndex == i ? color : .secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let x = gesture.location.x
                        let nearest = points.enumerated().min(by: {
                            abs($0.element.x - x) < abs($1.element.x - x)
                        })?.offset
                        if nearest != selectedDataIndex {
                            selectedDataIndex = nearest
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedDataIndex = nil
                        }
                    }
            )
        }
        .frame(height: 160)
        .onAppear {
            chartDrawProgress = 0
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                chartDrawProgress = 1
            }
        }
    }

    // MARK: - Chart Path Helpers

    private func makeSmoothPath(through points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count {
            let p0 = i > 1 ? points[i - 2] : points[i - 1]
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = i < points.count - 1 ? points[i + 1] : points[i]

            let tension: CGFloat = 0.3
            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }

        return path
    }

    private func makeAreaPath(points: [CGPoint], bottomY: CGFloat) -> Path {
        var path = makeSmoothPath(through: points)

        if let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: bottomY))
        }
        if let first = points.first {
            path.addLine(to: CGPoint(x: first.x, y: bottomY))
        }
        path.closeSubpath()

        return path
    }

    private func tooltipView(label: String, value: Double) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(AppTheme.Typography.label(10))
                .foregroundColor(.secondary)
            Text(formatTooltipValue(value))
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.micro)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(colorScheme == .dark ? Color(.systemGray5) : .white)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }

    private func formatTooltipValue(_ value: Double) -> String {
        switch kpiType {
        case "Returns":
            return String(format: "%.1f%%", value)
        case "Clients":
            return "\(Int(round(value)))"
        default:
            return AppTheme.formatCurrencyWithSymbol(value)
        }
    }

    private func clampTooltipX(_ x: CGFloat, in width: CGFloat) -> CGFloat {
        min(max(x, 40), width - 40)
    }

    // MARK: - Top Performers Section

    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.warning)

                Text("Top Performers")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)
            }

            ForEach(Array(topPerformers.prefix(3).enumerated()), id: \.element.id) { index, client in
                HStack(spacing: AppTheme.Spacing.compact) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(rankColor(index).opacity(0.15))
                            .frame(width: 28, height: 28)

                        Text("#\(index + 1)")
                            .font(AppTheme.Typography.accent(12))
                            .foregroundColor(rankColor(index))
                    }

                    // Client name
                    Text(client.name)
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Return percentage
                    HStack(spacing: 3) {
                        Image(systemName: client.returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        Text(client.returns.formattedPercent)
                            .font(AppTheme.Typography.accent(13))
                    }
                    .foregroundColor(AppTheme.returnColor(client.returns))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.returnColor(client.returns).opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.vertical, AppTheme.Spacing.small)
                .padding(.horizontal, AppTheme.Spacing.compact)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(AppTheme.success.opacity(colorScheme == .dark ? 0.06 : 0.03))
                )
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return Color(hex: "F59E0B") // Gold
        case 1: return Color(hex: "94A3B8") // Silver
        case 2: return Color(hex: "B45309") // Bronze
        default: return .secondary
        }
    }

    // MARK: - Breakdown Section

    private var usesPieChart: Bool {
        kpiType == "" || kpiType == "AUM" || kpiType == "SIP"
    }

    private func breakdownSection(_ items: [BreakdownItem]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("Breakdown")
                .font(AppTheme.Typography.accent(15))
                .foregroundColor(.primary)

            if usesPieChart {
                pieChartBreakdown(items)
            } else {
                barListBreakdown(items)
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: Pie Chart Breakdown (AUM / SIP)

    private func pieChartBreakdown(_ items: [BreakdownItem]) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            // Donut chart
            ZStack {
                ForEach(Array(pieSlices(items).enumerated()), id: \.offset) { index, slice in
                    PieSlice(startAngle: slice.start, endAngle: slice.end)
                        .fill(breakdownColor(for: index))
                }

                // Inner cutout for donut effect
                Circle()
                    .fill(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white)
                    .frame(width: 60, height: 60)

                // Center label
                VStack(spacing: 0) {
                    Text("\(items.count)")
                        .font(AppTheme.Typography.accent(16))
                        .foregroundColor(.primary)
                    Text("Types")
                        .font(AppTheme.Typography.label(10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 110, height: 110)

            // Legend
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: AppTheme.Spacing.small) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(breakdownColor(for: index))
                            .frame(width: 12, height: 12)

                        Text(item.label)
                            .font(AppTheme.Typography.accent(13))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(String(format: "%.0f%%", item.percentage))
                            .font(AppTheme.Typography.accent(13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, AppTheme.Spacing.small)
    }

    private func pieSlices(_ items: [BreakdownItem]) -> [(start: Angle, end: Angle)] {
        let total = items.reduce(0.0) { $0 + $1.percentage }
        guard total > 0 else { return [] }

        var slices: [(start: Angle, end: Angle)] = []
        var currentAngle: Double = -90 // Start from top

        for item in items {
            let sweep = item.percentage / total * 360
            let start = Angle(degrees: currentAngle)
            let end = Angle(degrees: currentAngle + sweep)
            slices.append((start: start, end: end))
            currentAngle += sweep
        }
        return slices
    }

    // MARK: Bar List Breakdown (Clients / Returns)

    private func barListBreakdown(_ items: [BreakdownItem]) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                breakdownRow(item, colorIndex: index)
            }
        }
    }

    private func breakdownRow(_ item: BreakdownItem, colorIndex: Int) -> some View {
        let rowColor = breakdownColor(for: colorIndex)

        return HStack(spacing: AppTheme.Spacing.compact) {
            Circle()
                .fill(rowColor)
                .frame(width: 8, height: 8)

            Text(item.label)
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.primary)

            Spacer()

            Text("\(item.value)")
                .font(AppTheme.Typography.numeric(13))
                .foregroundColor(.primary)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(rowColor.opacity(0.15))
                    .frame(width: geo.size.width)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(rowColor)
                            .frame(width: geo.size.width * min(item.percentage / 100.0, 1.0))
                    }
            }
            .frame(width: 60, height: 6)

            Text(String(format: "%.0f%%", item.percentage))
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func breakdownColor(for index: Int) -> Color {
        let colors: [Color] = [
            Color(hex: "3B82F6"),
            Color(hex: "22C55E"),
            Color(hex: "F97316"),
            Color(hex: "A855F7"),
            Color(hex: "EF4444"),
            Color(hex: "06B6D4"),
        ]
        return colors[index % colors.count]
    }

    // MARK: - Generate Trend Data Per Period

    private func generateTrendData(for period: String) -> [(String, Double)] {
        // Use real trend data when available for default period
        if let growth, !growth.trend.isEmpty, period == "6M" {
            return growth.trend.map { ($0.month, $0.value) }
        }

        // Clamp monthly growth to a reasonable range for synthesis (-20%..+20%)
        let rawMomRate = growth?.momChange ?? 2.0
        let momRate = max(-20, min(20, rawMomRate))

        // Use last real data point or a sensible default
        let baseValue: Double
        if let lastReal = growth?.trend.last?.value, lastReal > 0 {
            baseValue = lastReal
        } else {
            baseValue = 100.0 // Use a normalized base of 100
        }

        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()

        func synthesize(count: Int, stepBack: (Int) -> Date, labelFormat: String, divisor: Double) -> [(String, Double)] {
            dateFormatter.dateFormat = labelFormat
            let stepRate = momRate / divisor
            return (0..<count).reversed().map { stepsAgo in
                let date = stepBack(stepsAgo)
                let label = dateFormatter.string(from: date)
                let jitter = Double.random(in: -0.5...0.5) * (baseValue * 0.02)
                let value = baseValue * (1.0 - Double(stepsAgo) * stepRate / 100.0) + jitter
                return (label, max(baseValue * 0.3, value))
            }
        }

        switch period {
        case "1W":
            return synthesize(count: 7, stepBack: { calendar.date(byAdding: .day, value: -$0, to: now) ?? now },
                              labelFormat: "EEE", divisor: 30.0)
        case "1M":
            return synthesize(count: 5, stepBack: { calendar.date(byAdding: .day, value: -$0 * 7, to: now) ?? now },
                              labelFormat: "d MMM", divisor: 4.0)
        case "3M":
            return synthesize(count: 4, stepBack: { calendar.date(byAdding: .month, value: -$0, to: now) ?? now },
                              labelFormat: "MMM", divisor: 1.0)
        case "6M":
            if let growth, !growth.trend.isEmpty {
                return growth.trend.map { ($0.month, $0.value) }
            }
            return synthesize(count: 7, stepBack: { calendar.date(byAdding: .month, value: -$0, to: now) ?? now },
                              labelFormat: "MMM", divisor: 1.0)
        case "1Y":
            return synthesize(count: 6, stepBack: { calendar.date(byAdding: .month, value: -$0 * 2, to: now) ?? now },
                              labelFormat: "MMM", divisor: 1.0)
        default:
            return growth?.trend.map { ($0.month, $0.value) } ?? []
        }
    }
}

// MARK: - Pie Slice Shape

private struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            KpiDetailSheet(
                title: "Total AUM",
                value: "\u{20B9}24.5 Cr",
                icon: "indianrupeesign.circle.fill",
                color: AppTheme.primary,
                growth: KpiGrowth(
                    momChange: 3.2,
                    momAbsolute: 750000,
                    yoyChange: 18.5,
                    yoyAbsolute: 3800000,
                    trend: [
                        GrowthDataPoint(month: "Sep", value: 0.6),
                        GrowthDataPoint(month: "Oct", value: 0.7),
                        GrowthDataPoint(month: "Nov", value: 0.65),
                        GrowthDataPoint(month: "Dec", value: 0.8),
                        GrowthDataPoint(month: "Jan", value: 0.85),
                        GrowthDataPoint(month: "Feb", value: 0.9),
                    ],
                    breakdown: [
                        BreakdownItem(label: "Equity Funds", value: 45, percentage: 45),
                        BreakdownItem(label: "Debt Funds", value: 25, percentage: 25),
                        BreakdownItem(label: "Hybrid Funds", value: 18, percentage: 18),
                        BreakdownItem(label: "Others", value: 12, percentage: 12),
                    ]
                ),
                kpiType: "Returns",
                topPerformers: [
                    FAClient(id: "1", name: "Priya Patel", email: "priya@demo.com", returns: 18.5),
                    FAClient(id: "2", name: "Rajesh Sharma", email: "rajesh@demo.com", returns: 15.2),
                    FAClient(id: "3", name: "Ananya Gupta", email: "ananya@demo.com", returns: 12.8),
                ]
            )
        }
}
