import SwiftUI

// MARK: - Portfolio Line Chart

struct PortfolioLineChart: View {
    let data: [PortfolioHistoryPoint]
    @Binding var selectedPeriod: String
    let periods: [String]
    let onPeriodChange: (String) -> Void
    var title: String? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var drawProgress: CGFloat = 0
    @State private var touchIndex: Int? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Header: title (left) + period selector (right)
            HStack(alignment: .center) {
                if let title {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.primary)
                        Text(title)
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                            .foregroundColor(.primary)
                    }
                }

                Spacer()

                periodSelector
            }

            if data.isEmpty {
                emptyPlaceholder
            } else {
                chartContent
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(periods, id: \.self) { period in
                Button {
                    withAnimation(.bouncy) { selectedPeriod = period }
                } label: {
                    Text(period)
                        .font(.system(size: 10, weight: .semibold))
                        .fixedSize()
                        .foregroundColor(selectedPeriod == period ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            selectedPeriod == period
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.7))
                .overlay(Capsule().stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 0.5))
        )
        .onChange(of: selectedPeriod) { _, newPeriod in
            onPeriodChange(newPeriod)
            touchIndex = nil
            drawProgress = 0
            withAnimation(.easeOut(duration: 1.0)) {
                drawProgress = 1
            }
        }
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        let values = data.map(\.value)
        let minVal = (values.min() ?? 0) * 0.95
        let maxVal = (values.max() ?? 1) * 1.05

        return VStack(spacing: 0) {
            // Touch indicator tooltip
            if let idx = touchIndex, idx < data.count {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(formatDateLabel(data[idx].date))
                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                        .foregroundColor(.secondary)
                    Text(AppTheme.formatCurrencyWithSymbol(data[idx].value))
                        .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                        .foregroundColor(AppTheme.primary)
                    if let dayChange = data[idx].dayChange, dayChange != 0 {
                        Text(String(format: "%@%.1f%%", dayChange >= 0 ? "+" : "", (data[idx].dayChangePct ?? 0)))
                            .font(AppTheme.Typography.label(iPad ? 12 : 10))
                            .foregroundColor(dayChange >= 0 ? AppTheme.success : AppTheme.error)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
                .transition(.opacity)
            }

            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                // Y-axis labels
                VStack {
                    Text(AppTheme.formatCurrencyWithSymbol(maxVal))
                    Spacer()
                    Text(AppTheme.formatCurrencyWithSymbol(minVal))
                }
                .font(AppTheme.Typography.label(iPad ? 11 : 9))
                .foregroundColor(.secondary)
                .frame(width: 48, alignment: .trailing)

                // Chart canvas + x-axis
                VStack(spacing: 4) {
                    // Chart area
                    GeometryReader { geometry in
                        let size = geometry.size
                        ZStack {
                            // Horizontal grid lines
                            ForEach(0..<3, id: \.self) { i in
                                let y = size.height * CGFloat(i) / 2.0
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: size.width, y: y))
                                }
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06),
                                        style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            }

                            // Gradient fill
                            LineChartFillShape(data: values, minValue: minVal, maxValue: maxVal, size: size)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.primary.opacity(0.25),
                                            AppTheme.primary.opacity(0.08),
                                            AppTheme.primary.opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .mask(
                                    Rectangle()
                                        .frame(width: size.width * drawProgress)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )

                            // Line path
                            LineChartLineShape(data: values, minValue: minVal, maxValue: maxVal, size: size)
                                .trim(from: 0, to: drawProgress)
                                .stroke(
                                    AppTheme.primaryGradient,
                                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                                )

                            // Touch indicator
                            if let idx = touchIndex, idx < values.count, drawProgress >= 1 {
                                let range = maxVal - minVal
                                let x = range > 0 ? CGFloat(idx) / CGFloat(values.count - 1) * size.width : 0
                                let y = range > 0 ? size.height - ((CGFloat(values[idx]) - CGFloat(minVal)) / CGFloat(range)) * size.height : size.height / 2

                                // Vertical line
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: 0))
                                    path.addLine(to: CGPoint(x: x, y: size.height))
                                }
                                .stroke(AppTheme.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                                // Point
                                Circle()
                                    .fill(AppTheme.primary)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: AppTheme.primary.opacity(0.5), radius: 4, y: 2)
                                    .position(x: x, y: y)
                            }

                            // Last point indicator (when not touching)
                            if touchIndex == nil, drawProgress >= 1, let lastPoint = pointPosition(at: values.count - 1, size: size, minVal: minVal, maxVal: maxVal) {
                                Circle()
                                    .fill(AppTheme.primary)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 4, y: 2)
                                    .position(lastPoint)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let x = gesture.location.x
                                    let idx = Int(round(x / size.width * CGFloat(values.count - 1)))
                                    let clamped = max(0, min(values.count - 1, idx))
                                    withAnimation(.interactiveSpring()) { touchIndex = clamped }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) { touchIndex = nil }
                                }
                        )
                    }
                    .frame(height: 150)

                    // X-axis labels
                    xAxisLabels
                }
            }
        }
        .onAppear {
            drawProgress = 0
            withAnimation(.easeOut(duration: 1.0)) {
                drawProgress = 1
            }
        }
    }

    // MARK: - X-Axis Labels

    private var xAxisLabels: some View {
        let labels = computeXLabels()
        return HStack {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(AppTheme.Typography.label(iPad ? 11 : 9))
                    .foregroundColor(.secondary)
                if label != labels.last {
                    Spacer()
                }
            }
        }
    }

    private func computeXLabels() -> [String] {
        guard data.count > 2 else { return [] }
        let count = min(5, data.count)
        let step = max(1, (data.count - 1) / (count - 1))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let outFormatter = DateFormatter()

        switch selectedPeriod {
        case "1M":
            outFormatter.dateFormat = "dd MMM"
        case "6M", "1Y":
            outFormatter.dateFormat = "MMM yy"
        default:
            outFormatter.dateFormat = "MMM yy"
        }

        var labels: [String] = []
        for i in stride(from: 0, to: data.count, by: step) {
            if let date = formatter.date(from: data[i].date) {
                labels.append(outFormatter.string(from: date))
            }
        }
        // Always include last
        if let last = data.last, let date = formatter.date(from: last.date) {
            let lastLabel = outFormatter.string(from: date)
            if labels.last != lastLabel {
                labels.append(lastLabel)
            }
        }
        return Array(labels.prefix(5))
    }

    // MARK: - Empty Placeholder

    private var emptyPlaceholder: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No data available")
                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func pointPosition(at index: Int, size: CGSize, minVal: Double, maxVal: Double) -> CGPoint? {
        let values = data.map(\.value)
        guard values.count > 1 else { return nil }
        let range = maxVal - minVal
        guard range > 0 else { return nil }

        let x = CGFloat(index) / CGFloat(values.count - 1) * size.width
        let y = size.height - ((CGFloat(values[index]) - CGFloat(minVal)) / CGFloat(range)) * size.height
        return CGPoint(x: x, y: y)
    }

    private func formatDateLabel(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = "dd MMM yyyy"
        return outFormatter.string(from: date)
    }
}

// MARK: - Line Shape (for trim animation)

private struct LineChartLineShape: Shape {
    let data: [Double]
    let minValue: Double
    let maxValue: Double
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        let range = maxValue - minValue
        guard range > 0 else { return Path() }

        var path = Path()
        let points = data.enumerated().map { index, value -> CGPoint in
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let y = size.height - ((CGFloat(value) - CGFloat(minValue)) / CGFloat(range)) * size.height
            return CGPoint(x: x, y: y)
        }

        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let controlX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: controlX, y: prev.y),
                control2: CGPoint(x: controlX, y: curr.y)
            )
        }

        return path
    }
}

// MARK: - Fill Shape (gradient area below line)

private struct LineChartFillShape: Shape {
    let data: [Double]
    let minValue: Double
    let maxValue: Double
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        guard data.count > 1 else { return Path() }
        let range = maxValue - minValue
        guard range > 0 else { return Path() }

        var path = Path()
        let points = data.enumerated().map { index, value -> CGPoint in
            let x = CGFloat(index) / CGFloat(data.count - 1) * size.width
            let y = size.height - ((CGFloat(value) - CGFloat(minValue)) / CGFloat(range)) * size.height
            return CGPoint(x: x, y: y)
        }

        path.move(to: CGPoint(x: points[0].x, y: size.height))
        path.addLine(to: points[0])

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let controlX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: controlX, y: prev.y),
                control2: CGPoint(x: controlX, y: curr.y)
            )
        }

        path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
        path.closeSubpath()

        return path
    }
}
