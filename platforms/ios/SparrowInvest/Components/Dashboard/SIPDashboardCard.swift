//
//  SIPDashboardCard.swift
//  SparrowInvest
//
//  SIP summary dashboard tile
//

import SwiftUI

struct SIPDashboardCard: View {
    let activeSIPs: [SIP]

    private var totalMonthlyAmount: Double {
        activeSIPs.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }

    private var nextSIPDate: Date? {
        activeSIPs
            .filter { $0.isActive }
            .compactMap { $0.nextInstallmentDate }
            .min()
    }

    private var nextSIPFormatted: String {
        guard let date = nextSIPDate else { return "No upcoming" }
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("SIP Dashboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                NavigationLink(destination: Text("SIP Details")) {
                    HStack(spacing: 4) {
                        Text("Manage")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // Stats Grid
            HStack(spacing: 16) {
                // Active SIPs
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary)
                        Text("Active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Text("\(activeSIPs.filter { $0.isActive }.count)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 44)

                // Monthly Amount
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.success)
                        Text("Monthly")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Text(totalMonthlyAmount.currencyFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(AppTheme.cardBorder)
                    .frame(width: 1, height: 44)

                // Next SIP
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        Text("Next")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Text(nextSIPFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Upcoming SIPs List
            let upcomingSIPs = Array(getUpcomingSIPs().prefix(2))
            if !upcomingSIPs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(upcomingSIPs) { sip in
                        UpcomingSIPRow(sip: sip)
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

    private func getUpcomingSIPs() -> [SIP] {
        activeSIPs
            .filter { $0.isActive && $0.nextInstallmentDate != nil }
            .sorted { ($0.nextInstallmentDate ?? Date()) < ($1.nextInstallmentDate ?? Date()) }
    }
}

struct UpcomingSIPRow: View {
    let sip: SIP

    var body: some View {
        HStack(spacing: 12) {
            // Fund Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 36, height: 36)

                Text(String(sip.fundName.prefix(2)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(sip.fundName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                if let date = sip.nextInstallmentDate {
                    Text(formatDate(date))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            // Amount
            Text(sip.amount.currencyFormatted)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
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
    SIPDashboardCard(activeSIPs: [])
        .padding()
}
