//
//  PortfolioHealthTile.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Portfolio Health - SF Pro Light
//

import SwiftUI

struct PortfolioHealthTile: View {
    let healthScore: Int
    var onTapAnalysis: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    private var healthColor: Color {
        if healthScore >= 80 {
            return .green
        } else if healthScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }

    private var healthLabel: String {
        if healthScore >= 80 {
            return "Excellent"
        } else if healthScore >= 60 {
            return "Good"
        } else if healthScore >= 40 {
            return "Fair"
        } else {
            return "Needs Attention"
        }
    }

    private var diagnostics: [(icon: String, text: String, isPositive: Bool)] {
        [
            ("checkmark.circle.fill", "Well diversified", true),
            ("checkmark.circle.fill", "On track for goals", true),
            ("exclamationmark.triangle.fill", "Rebalancing recommended", false)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Health")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    Text(healthLabel)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(healthColor)
                }

                Spacer()

                // Health Score Circle
                ZStack {
                    Circle()
                        .stroke(healthColor.opacity(0.2), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: CGFloat(healthScore) / 100)
                        .stroke(healthColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text("\(healthScore)")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundColor(healthColor)
                }
            }

            // Quick Diagnostics
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(diagnostics.indices, id: \.self) { index in
                    let diagnostic = diagnostics[index]
                    HStack(spacing: 8) {
                        Image(systemName: diagnostic.icon)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(diagnostic.isPositive ? .green : .orange)

                        Text(diagnostic.text)
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // View Full Analysis Button
            Button {
                onTapAnalysis?()
            } label: {
                HStack {
                    Text("View Full Analysis")
                        .font(.system(size: 13, weight: .regular))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .light))
                }
                .foregroundColor(.blue)
            }
        }
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

#Preview {
    PortfolioHealthTile(healthScore: 78)
        .padding()
}
