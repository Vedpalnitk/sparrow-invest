//
//  PortfolioHeroCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Portfolio Hero - SF Pro Light
//

import SwiftUI

struct PortfolioHeroCard: View {
    let portfolio: Portfolio
    @Binding var viewMode: PortfolioViewMode
    var familyPortfolio: FamilyPortfolio?
    var onTap: (() -> Void)?
    var onMemberTap: ((FamilyMember?) -> Void)?
    var onAddMember: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFamilySheet = false

    private var currentValue: Double {
        viewMode == .family ? (familyPortfolio?.totalValue ?? portfolio.currentValue) : portfolio.currentValue
    }

    private var investedValue: Double {
        viewMode == .family ? (familyPortfolio?.totalInvested ?? portfolio.totalInvested) : portfolio.totalInvested
    }

    private var returns: Double {
        viewMode == .family ? (familyPortfolio?.totalReturns ?? portfolio.totalReturns) : portfolio.totalReturns
    }

    private var returnsPercentage: Double {
        viewMode == .family ? (familyPortfolio?.returnsPercentage ?? portfolio.absoluteReturnsPercentage) : portfolio.absoluteReturnsPercentage
    }

    private var xirrValue: Double {
        viewMode == .family ? (familyPortfolio?.familyXIRR ?? portfolio.xirr ?? 0) : (portfolio.xirr ?? 0)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            // View Mode Toggle
            viewModeToggle

            // Tappable Content Area
            Button {
                if viewMode == .family {
                    showFamilySheet = true
                } else {
                    onTap?()
                }
            } label: {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Main Value Display
                    VStack(spacing: 8) {
                        Text("Total Portfolio Value")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.secondary)

                        Text(currentValue.currencyFormatted)
                            .font(.system(size: 38, weight: .light, design: .rounded))
                            .foregroundColor(.primary)

                        // Returns Badge
                        HStack(spacing: 6) {
                            Image(systemName: returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12, weight: .regular))
                            Text("\(returns >= 0 ? "+" : "")\(returns.compactCurrencyFormatted)")
                                .font(.system(size: 14, weight: .regular))
                            Text("(\(returnsPercentage.percentFormatted))")
                                .font(.system(size: 14, weight: .light))
                        }
                        .foregroundColor(returns >= 0 ? .green : .red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            (returns >= 0 ? Color.green : Color.red).opacity(colorScheme == .dark ? 0.15 : 0.12),
                            in: Capsule()
                        )
                    }

                    // Stats Row
                    HStack(spacing: 0) {
                        HeroStatItem(
                            label: "Invested",
                            value: investedValue.compactCurrencyFormatted,
                            icon: "arrow.down.circle.fill",
                            color: .blue
                        )

                        Divider()
                            .frame(height: 40)

                        HeroStatItem(
                            label: "Day Change",
                            value: "+₹2,450",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )

                        Divider()
                            .frame(height: 40)

                        HeroStatItem(
                            label: "XIRR",
                            value: xirrValue.percentFormatted,
                            icon: "percent",
                            color: xirrValue >= 0 ? .green : .red
                        )
                    }
                    .padding(.top, 8)

                    // Tap indicator
                    HStack {
                        Spacer()
                        Text("View Details")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.large)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showFamilySheet) {
            FamilyPortfolioSheet(
                familyPortfolio: familyPortfolio,
                onMemberTap: { member in
                    showFamilySheet = false
                    onMemberTap?(member)
                },
                onAddMember: {
                    showFamilySheet = false
                    onAddMember?()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
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
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            ForEach(PortfolioViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(viewMode == mode ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if viewMode == mode {
                                Capsule()
                                    .fill(Color.blue)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(toggleBackground)
        .overlay(toggleBorder)
        .shadow(color: toggleShadow, radius: 8, x: 0, y: 2)
    }

    private var toggleShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var toggleBackground: some View {
        if colorScheme == .dark {
            Capsule()
                .fill(Color.black.opacity(0.4))
                .background(Capsule().fill(.ultraThinMaterial))
        } else {
            Capsule().fill(Color.white)
        }
    }

    private var toggleBorder: some View {
        Capsule()
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Hero Stat Item

private struct HeroStatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Family Portfolio Sheet

struct FamilyPortfolioSheet: View {
    let familyPortfolio: FamilyPortfolio?
    var onMemberTap: ((FamilyMember?) -> Void)?
    var onAddMember: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Family Total Card
                    familyTotalCard

                    // Members List
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                        Text("FAMILY MEMBERS")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, 4)

                        VStack(spacing: AppTheme.Spacing.small) {
                            if let members = familyPortfolio?.members {
                                ForEach(members) { member in
                                    FamilyMemberSheetRow(member: member) {
                                        onMemberTap?(member)
                                    }
                                }
                            }

                            // Add Family Member Button
                            addMemberButton
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Family Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                }
            }
        }
    }

    private var familyTotalCard: some View {
        Button {
            onMemberTap?(nil) // nil means view all family
        } label: {
            VStack(spacing: AppTheme.Spacing.compact) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Combined Family Portfolio")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)
                        Text("\(familyPortfolio?.members.count ?? 0) members")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Value")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.secondary)
                        Text((familyPortfolio?.totalValue ?? 0).currencyFormatted)
                            .font(.system(size: 18, weight: .light, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Returns")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text((familyPortfolio?.totalReturns ?? 0).compactCurrencyFormatted)
                                .font(.system(size: 14, weight: .regular))
                            Text("(\((familyPortfolio?.returnsPercentage ?? 0).percentFormatted))")
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundColor((familyPortfolio?.totalReturns ?? 0) >= 0 ? .green : .red)
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var addMemberButton: some View {
        Button {
            onAddMember?()
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.blue)
                }

                Text("Add Family Member")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(AppTheme.Spacing.medium)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: cardShadow, radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Family Member Sheet Row

struct FamilyMemberSheetRow: View {
    let member: FamilyMember
    var onTap: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(member.relationship.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(String(member.name.prefix(1)))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(member.relationship.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.primary)

                        Text(member.relationship.displayName)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(member.relationship.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                member.relationship.color.opacity(0.12),
                                in: Capsule()
                            )
                    }

                    HStack(spacing: 8) {
                        Text(member.portfolioValue.compactCurrencyFormatted)
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(member.returnsPercentage.percentFormatted)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(member.returnsPercentage >= 0 ? .green : .red)
                    }
                }

                Spacer()

                // Contribution
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(member.contribution))%")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                    Text("share")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(AppTheme.Spacing.compact)
            .background(rowBackground)
            .overlay(rowBorder)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.black.opacity(0.06),
                lineWidth: 0.5
            )
    }
}

#Preview {
    PortfolioHeroCard(
        portfolio: .empty,
        viewMode: .constant(.individual)
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
