//
//  RecentTransactionsCard.swift
//  SparrowInvest
//
//  iOS 26 Liquid Glass Recent Transactions Card
//

import SwiftUI

struct RecentTransactionsCard: View {
    let transactions: [Transaction]
    @Environment(\.colorScheme) private var colorScheme

    private var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                NavigationLink(destination: Text("All Transactions")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .light))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
            }

            // Transactions List
            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                    Text("No transactions yet")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
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
                            .init(color: .black.opacity(0.15), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.05), location: 0.7),
                            .init(color: .black.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @Environment(\.colorScheme) private var colorScheme

    private var typeColor: Color {
        switch transaction.type {
        case .purchase, .sipInstallment:
            return .green
        case .redemption, .switchOut:
            return .red
        case .switchIn:
            return .blue
        case .dividend:
            return .purple
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
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: typeIcon)
                    .font(.system(size: 16))
                    .foregroundColor(typeColor)
            }

            // Transaction Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.fundName)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.type.displayName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(typeColor)

                    Text("•")
                        .foregroundColor(Color(uiColor: .tertiaryLabel))

                    Text(formatDate(transaction.date))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.type == .redemption ? "-" : "+")\(transaction.amount.currencyFormatted)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(transaction.type == .redemption ? .red : .green)

                Text("\(String(format: "%.3f", transaction.units)) units")
                    .font(.system(size: 11, weight: .regular))
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

    @ViewBuilder
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
