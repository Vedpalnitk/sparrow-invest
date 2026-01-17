//
//  PortfolioHealthTile.swift
//  SparrowInvest
//
//  Portfolio health score display
//

import SwiftUI

struct PortfolioHealthTile: View {
    let healthScore: Int
    var onTapAnalysis: (() -> Void)?

    private var healthColor: Color {
        if healthScore >= 80 {
            return AppTheme.success
        } else if healthScore >= 60 {
            return Color(hex: "#F59E0B")
        } else {
            return AppTheme.error
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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Health")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(healthLabel)
                        .font(.system(size: 13, weight: .medium))
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
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(healthColor)
                }
            }

            // Quick Diagnostics
            VStack(alignment: .leading, spacing: 8) {
                ForEach(diagnostics.indices, id: \.self) { index in
                    let diagnostic = diagnostics[index]
                    HStack(spacing: 8) {
                        Image(systemName: diagnostic.icon)
                            .font(.system(size: 14))
                            .foregroundColor(diagnostic.isPositive ? AppTheme.success : Color(hex: "#F59E0B"))

                        Text(diagnostic.text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            // View Full Analysis Button
            Button {
                onTapAnalysis?()
            } label: {
                HStack {
                    Text("View Full Analysis")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(AppTheme.primary)
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
    PortfolioHealthTile(healthScore: 78)
        .padding()
}
