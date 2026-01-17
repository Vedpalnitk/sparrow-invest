//
//  RecentTransactionsCard.swift
//  SparrowInvest
//
//  Recent transactions display card
//

import SwiftUI

struct RecentTransactionsCard: View {
    let transactions: [Transaction]

    private var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                NavigationLink(destination: Text("All Transactions")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Transactions List
            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No transactions yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
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

struct TransactionRow: View {
    let transaction: Transaction

    private var typeColor: Color {
        switch transaction.type {
        case .purchase, .sipInstallment:
            return AppTheme.success
        case .redemption, .switchOut:
            return AppTheme.error
        case .switchIn:
            return AppTheme.primary
        case .dividend:
            return Color(hex: "#8B5CF6")
        }
    }

    private var typeIcon: String {
        switch transaction.type {
        case .purchase: return "arrow.down.circle.fill"
        case .redemption: return "arrow.up.circle.fill"
        case .sipInstallment: return "repeat.circle.fill"
        case .switchIn: return "arrow.left.arrow.right.circle.fill"
        case .switchOut: return "arrow.left.arrow.right.circle.fill"
        case .dividend: return "indianrupeesign.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: typeIcon)
                    .font(.system(size: 16))
                    .foregroundColor(typeColor)
            }

            // Transaction Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.fundName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.type.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(typeColor)

                    Text("•")
                        .foregroundColor(AppTheme.textTertiary)

                    Text(formatDate(transaction.date))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .redemption ? "-" : "+")\(transaction.amount.currencyFormatted)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(transaction.type == .redemption ? AppTheme.error : AppTheme.success)

                Text("\(String(format: "%.3f", transaction.units)) units")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.chipBackground)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

#Preview {
    RecentTransactionsCard(transactions: [])
        .padding()
}
