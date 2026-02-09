//
//  FamilyPortfolioCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Family Portfolio Card
//

import SwiftUI

struct FamilyPortfolioCard: View {
    let familyPortfolio: FamilyPortfolio
    var onMemberTap: ((FamilyMember) -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Text("Family Portfolio")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                NavigationLink(destination: Text("Family Details")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .light))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
            }

            // Total Value
            VStack(alignment: .leading, spacing: 4) {
                Text("Combined Value")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(familyPortfolio.totalValue.currencyFormatted)
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(.primary)

                    Text("+\(familyPortfolio.returnsPercentage.percentFormatted)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.green)
                }
            }

            // Members List
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(familyPortfolio.linkedMembers.prefix(4)) { member in
                    FamilyMemberRow(member: member)
                        .onTapGesture {
                            onMemberTap?(member)
                        }
                }
            }

            // Add Member Button
            if familyPortfolio.members.count < 5 {
                Button {
                    // Add member action
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Family Member")
                            .font(.system(size: 13, weight: .light))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Color.blue.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    )
                }
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

struct FamilyMemberRow: View {
    let member: FamilyMember
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.relationship.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(member.initials)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(member.relationship.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.primary)

                    if member.relationship == .myself {
                        Text("You")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Color.blue.opacity(0.1),
                                in: Capsule()
                            )
                    }
                }

                Text(member.relationship.displayName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Value & Contribution
            VStack(alignment: .trailing, spacing: 2) {
                Text(member.portfolioValue.currencyFormatted)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)

                Text("\(Int(member.contribution))%")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(rowBackground)
        .overlay(rowBorder)
        .shadow(color: rowShadow, radius: 8, x: 0, y: 2)
    }

    private var rowShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var rowBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.25), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.12), location: 0),
                            .init(color: .black.opacity(0.06), location: 0.5),
                            .init(color: .black.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

#Preview {
    FamilyPortfolioCard(familyPortfolio: .empty)
        .padding()
}
