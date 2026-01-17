//
//  DividendIncomeCard.swift
//  SparrowInvest
//
//  Dividend income summary card
//

import SwiftUI

struct DividendIncomeCard: View {
    let dividendSummary: DividendSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dividend Income")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(dividendSummary.financialYear)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                NavigationLink(destination: Text("Dividend Details")) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Stats Row
            HStack(spacing: 16) {
                // Received
                VStack(alignment: .leading, spacing: 4) {
                    Text("Received")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(dividendSummary.totalReceived.currencyFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.success)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 40)

                // Projected
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(dividendSummary.projectedAnnual.currencyFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 40)

                // Yield
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yield")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(String(format: "%.1f", dividendSummary.dividendYield))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Recent Dividends
            if !dividendSummary.recentRecords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Dividends")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    ForEach(dividendSummary.recentRecords.prefix(3)) { record in
                        DividendRecordRow(record: record)
                    }
                }
            }

            // Next Expected
            if let nextDate = dividendSummary.nextExpectedDate {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primary)

                    Text("Next expected: \(formatDate(nextDate))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.primary.opacity(0.08))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadow, radius: 8, x: 0, y: 2)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

struct DividendRecordRow: View {
    let record: DividendRecord

    var body: some View {
        HStack(spacing: 12) {
            // Fund Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#8B5CF6").opacity(0.15))
                    .frame(width: 36, height: 36)

                Text(String(record.fundName.prefix(2)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#8B5CF6"))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(record.fundName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(formatPaymentDate(record.paymentDate))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            // Amount & Status
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.amount.currencyFormatted)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.success)

                Text(record.status.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(statusColor(record.status))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor(record.status).opacity(0.1))
                    )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.chipBackground)
        )
    }

    private func formatPaymentDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    private func statusColor(_ status: DividendStatus) -> Color {
        switch status {
        case .announced: return Color(hex: "#F59E0B")
        case .pending: return AppTheme.primary
        case .paid: return AppTheme.success
        }
    }
}

#Preview {
    DividendIncomeCard(dividendSummary: .empty)
        .padding()
}
