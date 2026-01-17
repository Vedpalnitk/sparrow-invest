//
//  PortfolioGrowthLineChart.swift
//  SparrowInvest
//
//  Line/area chart for portfolio growth over time
//

import SwiftUI
import Charts

struct PortfolioGrowthLineChart: View {
    let history: PortfolioHistory
    @Binding var selectedPeriod: HistoryPeriod
    var onPeriodChange: ((HistoryPeriod) -> Void)?

    @State private var selectedPoint: PortfolioHistoryPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Growth")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    if let point = selectedPoint {
                        HStack(spacing: 8) {
                            Text(point.value.currencyFormatted)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)

                            Text(point.returnsPercentage.percentFormatted)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(point.returns >= 0 ? AppTheme.success : AppTheme.error)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Text(history.periodReturn >= 0 ? "+" : "")
                            Text("\(String(format: "%.1f", history.periodReturn))%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(history.periodReturn >= 0 ? AppTheme.success : AppTheme.error)
                            Text("in \(selectedPeriod.rawValue)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            // Period Selector
            periodSelector

            // Chart
            if history.dataPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No data available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart {
                    ForEach(history.dataPoints) { point in
                        // Area fill
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.primary.opacity(0.3), AppTheme.primary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(AppTheme.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    // Selection indicator
                    if let selected = selectedPoint {
                        RuleMark(x: .value("Date", selected.date))
                            .foregroundStyle(AppTheme.primary.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

                        PointMark(
                            x: .value("Date", selected.date),
                            y: .value("Value", selected.value)
                        )
                        .foregroundStyle(AppTheme.primary)
                        .symbolSize(80)
                    }
                }
                .chartYScale(domain: history.minValue * 0.95...history.maxValue * 1.05)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatAxisDate(date))
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount.compactCurrencyFormatted)
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let date: Date = proxy.value(atX: x) {
                                            if let closest = history.dataPoints.min(by: {
                                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                            }) {
                                                selectedPoint = closest
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(HistoryPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                        onPeriodChange?(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .white : AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ?
                            AnyView(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primary, AppTheme.primaryDark],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            ) : AnyView(Color.clear)
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(AppTheme.chipBackground)
        )
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .oneMonth:
            formatter.dateFormat = "d"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "MMM"
        case .oneYear, .threeYears, .fiveYears, .all:
            formatter.dateFormat = "MMM yy"
        }
        return formatter.string(from: date)
    }
}

#Preview {
    PortfolioGrowthLineChart(
        history: .empty,
        selectedPeriod: .constant(.oneYear)
    )
    .padding()
}
