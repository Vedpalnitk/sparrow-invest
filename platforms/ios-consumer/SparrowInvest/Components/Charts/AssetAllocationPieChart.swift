//
//  AssetAllocationPieChart.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Asset Allocation Chart
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

// Portfolio filter option for asset allocation
struct PortfolioFilterOption: Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let color: Color

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PortfolioFilterOption, rhs: PortfolioFilterOption) -> Bool {
        lhs.id == rhs.id
    }

    static let individual = PortfolioFilterOption(id: "individual", name: "My Portfolio", shortName: "Mine", color: .blue)
    static let family = PortfolioFilterOption(id: "family", name: "Family Portfolio", shortName: "Family", color: .purple)
}

struct AssetAllocationPieChart: View {
    let allocation: AssetAllocation
    var familyAllocation: AssetAllocation?
    var familyMembers: [FamilyMember]
    var memberAllocations: [String: AssetAllocation]
    var onTap: ((PortfolioFilterOption) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFilter: PortfolioFilterOption = .individual

    // Computed filter options based on available data
    private var filterOptions: [PortfolioFilterOption] {
        var options: [PortfolioFilterOption] = [.individual]

        // Add family option if family data exists
        if familyAllocation != nil || !familyMembers.isEmpty {
            options.append(.family)
        }

        // Add individual family members
        for member in familyMembers where member.relationship != .myself {
            options.append(PortfolioFilterOption(
                id: member.id,
                name: member.name,
                shortName: String(member.name.prefix(8)),
                color: member.relationship.color
            ))
        }

        return options
    }

    // Current allocation based on selected filter
    private var currentAllocation: AssetAllocation {
        switch selectedFilter.id {
        case "individual":
            return allocation
        case "family":
            return familyAllocation ?? allocation
        default:
            // Check if it's a family member
            if let memberAlloc = memberAllocations[selectedFilter.id] {
                return memberAlloc
            }
            return allocation
        }
    }

    private var slices: [AllocationSlice] {
        [
            AllocationSlice(
                name: "Equity",
                value: currentAllocation.equity,
                percentage: currentAllocation.equityPercentage,
                color: .blue
            ),
            AllocationSlice(
                name: "Debt",
                value: currentAllocation.debt,
                percentage: currentAllocation.debtPercentage,
                color: .green
            ),
            AllocationSlice(
                name: "Hybrid",
                value: currentAllocation.hybrid,
                percentage: currentAllocation.hybridPercentage,
                color: .purple
            ),
            AllocationSlice(
                name: "Gold",
                value: currentAllocation.gold,
                percentage: currentAllocation.goldPercentage,
                color: .orange
            ),
            AllocationSlice(
                name: "Other",
                value: currentAllocation.other,
                percentage: currentAllocation.otherPercentage,
                color: .gray
            )
        ].filter { $0.value > 0 }
    }

    @State private var selectedSlice: AllocationSlice?

    // Initialize with default values for backward compatibility
    init(
        allocation: AssetAllocation,
        familyAllocation: AssetAllocation? = nil,
        familyMembers: [FamilyMember] = [],
        memberAllocations: [String: AssetAllocation] = [:],
        onTap: ((PortfolioFilterOption) -> Void)? = nil
    ) {
        self.allocation = allocation
        self.familyAllocation = familyAllocation
        self.familyMembers = familyMembers
        self.memberAllocations = memberAllocations
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap?(selectedFilter)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Header with Filter
                HStack {
                    Text("Asset Allocation")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    Spacer()

                    // Portfolio Filter (only show if there are multiple options)
                    if filterOptions.count > 1 {
                        PortfolioFilterPicker(
                            options: filterOptions,
                            selected: $selectedFilter
                        )
                    }
                }

                HStack(spacing: AppTheme.Spacing.large) {
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
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(.secondary)
                                    Text("\(Int(selected.percentage))%")
                                        .font(.system(size: 20, weight: .light, design: .rounded))
                                        .foregroundColor(selected.color)
                                } else {
                                    Text("Total")
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundColor(.secondary)
                                    Text(currentAllocation.total.compactCurrencyFormatted)
                                        .font(.system(size: 16, weight: .light, design: .rounded))
                                        .foregroundColor(.primary)
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
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.primary)

                                    Text(slice.value.compactCurrencyFormatted)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("\(Int(slice.percentage))%")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
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

                // Tap indicator
                HStack {
                    Spacer()
                    Text("View Holdings")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(AppTheme.Spacing.medium)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.15), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.05), location: 0.7),
                            .init(color: .black.opacity(0.12), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Portfolio Filter Picker

struct PortfolioFilterPicker: View {
    let options: [PortfolioFilterOption]
    @Binding var selected: PortfolioFilterOption
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = option
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 8, height: 8)
                        Text(option.name)
                        if selected.id == option.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(selected.color)
                    .frame(width: 8, height: 8)
                Text(selected.shortName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(filterBackground)
            .overlay(filterBorder)
        }
    }

    @ViewBuilder
    private var filterBackground: some View {
        if colorScheme == .dark {
            Capsule()
                .fill(Color.white.opacity(0.08))
        } else {
            Capsule()
                .fill(Color(uiColor: .tertiarySystemFill))
        }
    }

    private var filterBorder: some View {
        Capsule()
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.15)
                    : Color.black.opacity(0.08),
                lineWidth: 0.5
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Single portfolio (no filter shown)
        AssetAllocationPieChart(allocation: AssetAllocation(
            equity: 800000,
            debt: 300000,
            hybrid: 150000,
            gold: 50000,
            other: 0
        ))

        // With family data (filter shown)
        AssetAllocationPieChart(
            allocation: AssetAllocation(
                equity: 800000,
                debt: 300000,
                hybrid: 150000,
                gold: 50000,
                other: 0
            ),
            familyAllocation: AssetAllocation(
                equity: 1500000,
                debt: 500000,
                hybrid: 300000,
                gold: 100000,
                other: 50000
            ),
            familyMembers: [
                FamilyMember(name: "Rahul Sharma", relationship: .spouse, portfolioValue: 500000),
                FamilyMember(name: "Ananya Sharma", relationship: .child, portfolioValue: 200000)
            ]
        )
    }
    .padding()
}
