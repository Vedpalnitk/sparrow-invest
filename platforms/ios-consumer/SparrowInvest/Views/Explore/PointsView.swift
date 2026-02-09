//
//  PointsView.swift
//  SparrowInvest
//
//  Created by Claude on 2025.
//

import SwiftUI

struct PointsView: View {
    @EnvironmentObject var pointsStore: PointsStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Tier Card - Primary Glass Tile
                TierCard(
                    tier: pointsStore.points.tier,
                    totalPoints: pointsStore.points.totalPoints,
                    pointsToNext: pointsStore.pointsToNextTier,
                    progress: pointsStore.progressToNextTier
                )

                // Points Summary - Quick Access Tiles
                PointsSummarySection(
                    lifetimePoints: pointsStore.formattedLifetimePoints,
                    expiringPoints: pointsStore.formattedExpiringPoints,
                    expiryDate: pointsStore.expiryDateFormatted
                )

                // Tier Benefits - List Item Tiles
                TierBenefitsSection(tier: pointsStore.points.tier)

                // All Tiers Overview
                AllTiersSection(currentTier: pointsStore.points.tier)
            }
            .padding(AppTheme.Spacing.medium)
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Points")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Tier Card (Primary Glass Tile)

private struct TierCard: View {
    let tier: RewardTier
    let totalPoints: Int
    let pointsToNext: Int
    let progress: Double
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Tier icon and name
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tier.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: tier.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(tier.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("Member")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Total points
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(totalPoints.formatted())")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)

                Text("points")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Progress to next tier
            if let nextTier = tier.nextTier {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(pointsToNext.formatted()) points to \(nextTier.displayName)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tier.color.opacity(0.2))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [tier.color, nextTier.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            // Dark mode: Dark transparent glass
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            // Light mode: White with shadow
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xxLarge, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
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

// MARK: - Points Summary Section (Quick Access Tiles)

private struct PointsSummarySection: View {
    let lifetimePoints: String
    let expiringPoints: String
    let expiryDate: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("SUMMARY")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            HStack(spacing: AppTheme.Spacing.compact) {
                SummaryTile(
                    title: "Lifetime",
                    value: lifetimePoints,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )

                if let date = expiryDate {
                    SummaryTile(
                        title: "Expiring",
                        value: expiringPoints,
                        subtitle: "by \(date)",
                        icon: "clock.fill",
                        color: .orange
                    )
                }
            }
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundStyle(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.compact)
        .background(tileBackground)
        .overlay(tileBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var tileBackground: some View {
        if colorScheme == .dark {
            // Dark mode: Dark transparent glass
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            // Light mode: White with shadow
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 3)
        }
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.5), location: 0),
                            .init(color: .white.opacity(0.2), location: 0.25),
                            .init(color: .white.opacity(0.05), location: 0.6),
                            .init(color: .white.opacity(0.15), location: 1)
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

// MARK: - Tier Benefits Section (List Item Tiles)

private struct TierBenefitsSection: View {
    let tier: RewardTier
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("\(tier.displayName.uppercased()) BENEFITS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(tier.benefits.enumerated()), id: \.offset) { index, benefit in
                    HStack(alignment: .center, spacing: AppTheme.Spacing.compact) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(tier.color.opacity(0.15))
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(tier.color)
                        }

                        Text(benefit)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.compact)
                    .padding(.vertical, 10)

                    if index < tier.benefits.count - 1 {
                        Divider().padding(.leading, 46)
                    }
                }
            }
            .background(sectionBackground)
            .overlay(sectionBorder)
        }
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            // Dark mode: Dark transparent glass
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            // Light mode: White with shadow
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 3)
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.12), location: 1)
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

// MARK: - All Tiers Section

private struct AllTiersSection: View {
    let currentTier: RewardTier
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("ALL TIERS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(RewardTier.allCases.enumerated()), id: \.element) { index, tier in
                    TierRow(tier: tier, isCurrentTier: tier == currentTier)

                    if index < RewardTier.allCases.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(sectionBackground)
            .overlay(sectionBorder)
        }
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 3)
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.12), location: 1)
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

private struct TierRow: View {
    let tier: RewardTier
    let isCurrentTier: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tier.color.opacity(0.15))
                    .frame(width: 26, height: 26)
                Image(systemName: tier.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tier.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(tier.displayName)
                        .font(.system(size: 14, weight: isCurrentTier ? .medium : .regular))
                        .foregroundStyle(.primary)

                    if isCurrentTier {
                        Text("Current")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(tier.color, in: Capsule())
                    }
                }

                Text(tier.minPoints == 0 ? "Starting tier" : "\(tier.minPoints.formatted())+ points")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(tier.benefits.count) benefits")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.compact)
        .padding(.vertical, 10)
        .background(isCurrentTier ? tier.color.opacity(0.05) : Color.clear)
    }
}

#Preview {
    NavigationStack {
        PointsView()
            .environmentObject(PointsStore())
    }
}
