//
//  FamilyPortfolioCard.swift
//  SparrowInvest
//
//  Family portfolio overview card
//

import SwiftUI

struct FamilyPortfolioCard: View {
    let familyPortfolio: FamilyPortfolio
    var onMemberTap: ((FamilyMember) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Family Portfolio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                NavigationLink(destination: Text("Family Details")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Total Value
            VStack(alignment: .leading, spacing: 4) {
                Text("Combined Value")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(familyPortfolio.totalValue.currencyFormatted)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("+\(familyPortfolio.returnsPercentage.percentFormatted)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.success)
                }
            }

            // Members List
            VStack(spacing: 8) {
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
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.primary.opacity(0.1))
                    )
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

struct FamilyMemberRow: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(member.relationship.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(member.initials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(member.relationship.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)

                    if member.relationship == .myself {
                        Text("You")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.primary.opacity(0.1))
                            )
                    }
                }

                Text(member.relationship.displayName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Value & Contribution
            VStack(alignment: .trailing, spacing: 2) {
                Text(member.portfolioValue.currencyFormatted)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("\(Int(member.contribution))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.chipBackground)
        )
    }
}

#Preview {
    FamilyPortfolioCard(familyPortfolio: .empty)
        .padding()
}
