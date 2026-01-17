//
//  AssetAllocationPieChart.swift
//  SparrowInvest
//
//  Donut chart for asset allocation display
//

import SwiftUI
import Charts

struct AllocationSlice: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let percentage: Double
    let color: Color
}

struct AssetAllocationPieChart: View {
    let allocation: AssetAllocation

    private var slices: [AllocationSlice] {
        [
            AllocationSlice(
                name: "Equity",
                value: allocation.equity,
                percentage: allocation.equityPercentage,
                color: Color(hex: "#3B82F6")
            ),
            AllocationSlice(
                name: "Debt",
                value: allocation.debt,
                percentage: allocation.debtPercentage,
                color: Color(hex: "#10B981")
            ),
            AllocationSlice(
                name: "Hybrid",
                value: allocation.hybrid,
                percentage: allocation.hybridPercentage,
                color: Color(hex: "#8B5CF6")
            ),
            AllocationSlice(
                name: "Gold",
                value: allocation.gold,
                percentage: allocation.goldPercentage,
                color: Color(hex: "#F59E0B")
            ),
            AllocationSlice(
                name: "Other",
                value: allocation.other,
                percentage: allocation.otherPercentage,
                color: Color(hex: "#64748B")
            )
        ].filter { $0.value > 0 }
    }

    @State private var selectedSlice: AllocationSlice?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Asset Allocation")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 20) {
                // Pie Chart
                ZStack {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Value", slice.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(slice.color)
                        .opacity(selectedSlice?.id == slice.id ? 1.0 : 0.9)
                    }
                    .chartBackground { _ in
                        VStack(spacing: 2) {
                            if let selected = selectedSlice {
                                Text(selected.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text("\(Int(selected.percentage))%")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(selected.color)
                            } else {
                                Text("Total")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                Text(allocation.total.compactCurrencyFormatted)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }
                    .frame(width: 140, height: 140)
                }

                // Legend
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(slices) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(slice.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)

                                Text(slice.value.compactCurrencyFormatted)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            Text("\(Int(slice.percentage))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(slice.color)
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedSlice?.id == slice.id {
                                    selectedSlice = nil
                                } else {
                                    selectedSlice = slice
                                }
                            }
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

#Preview {
    AssetAllocationPieChart(allocation: AssetAllocation(
        equity: 800000,
        debt: 300000,
        hybrid: 150000,
        gold: 50000,
        other: 0
    ))
    .padding()
}
