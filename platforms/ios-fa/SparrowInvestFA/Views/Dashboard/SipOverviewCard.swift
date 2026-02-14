import SwiftUI

// MARK: - SIP Overview Card

struct SipOverviewCard: View {
    let upcomingSips: [FASip]
    let failedSips: [FASip]

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSegment = "Upcoming"
    @State private var showSipList = false

    private var showFailed: Bool { selectedSegment == "Failed" }
    private var activeSips: [FASip] { showFailed ? failedSips : upcomingSips }
    private var displayedSips: [FASip] { Array(activeSips.prefix(5)) }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Header with segmented control
            HStack {
                Text("SIP Overview")
                    .font(AppTheme.Typography.headline(17))
                    .foregroundColor(.primary)

                Spacer()

                // Compact inline toggle
                HStack(spacing: 0) {
                    segmentButton("Upcoming", isSelected: !showFailed)
                    segmentButton("Failed", isSelected: showFailed)
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                )
            }

            // Summary stats row
            HStack(spacing: 0) {
                sipStat(
                    value: "\(upcomingSips.count)",
                    label: "Upcoming",
                    color: AppTheme.primary
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 1, height: 32)

                sipStat(
                    value: "\(failedSips.count)",
                    label: "Failed",
                    color: failedSips.isEmpty ? AppTheme.success : AppTheme.error
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 1, height: 32)

                sipStat(
                    value: AppTheme.formatCurrencyWithSymbol(
                        upcomingSips.reduce(0) { $0 + $1.amount }
                    ),
                    label: "Total Due",
                    color: AppTheme.secondary
                )
            }
            .padding(.vertical, AppTheme.Spacing.small)

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)

            // Content
            if showFailed {
                failedSipsList
            } else {
                upcomingSipsList
            }

            // View All
            if activeSips.count > 5 {
                Button { showSipList = true } label: {
                    Text("View All \(activeSips.count) SIPs")
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(AppTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.xLarge, padding: AppTheme.Spacing.medium)
        .fullScreenCover(isPresented: $showSipList) {
            SipListView()
        }
    }

    // MARK: - Segment Button

    private func segmentButton(_ title: String, isSelected: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = title }
        } label: {
            Text(title)
                .font(AppTheme.Typography.accent(12))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.primaryGradient)
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stat

    private func sipStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(AppTheme.Typography.numeric(18))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Upcoming SIPs List

    private var upcomingSipsList: some View {
        Group {
            if upcomingSips.isEmpty {
                emptyState(
                    icon: "calendar.badge.checkmark",
                    message: "No upcoming SIPs",
                    color: AppTheme.primary
                )
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(displayedSips) { sip in
                        upcomingSipRow(sip)
                    }
                }
            }
        }
    }

    private func upcomingSipRow(_ sip: FASip) -> some View {
        NavigationLink {
            ClientDetailView(clientId: sip.clientId)
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Date badge
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Text("\(sip.sipDate)")
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(AppTheme.primary)
                }

                // SIP details
                VStack(alignment: .leading, spacing: 2) {
                    Text(sip.clientName ?? "Client")
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(sip.fundName)
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Amount
                Text(sip.formattedAmount)
                    .font(AppTheme.Typography.numeric(14))
                    .foregroundColor(.primary)
            }
            .padding(AppTheme.Spacing.compact)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : AppTheme.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : AppTheme.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Failed SIPs List

    private var failedSipsList: some View {
        Group {
            if failedSips.isEmpty {
                emptyState(
                    icon: "checkmark.circle",
                    message: "No failed SIPs",
                    color: AppTheme.success
                )
            } else {
                let displayed = Array(failedSips.prefix(5))
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(displayed) { sip in
                        failedSipRow(sip)
                    }
                }
            }
        }
    }

    private func failedSipRow(_ sip: FASip) -> some View {
        NavigationLink {
            ClientDetailView(clientId: sip.clientId)
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Warning icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.error.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.error)
                }

                // SIP details
                VStack(alignment: .leading, spacing: 2) {
                    Text(sip.clientName ?? "Client")
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(sip.fundName)
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Amount + status
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sip.formattedAmount)
                        .font(AppTheme.Typography.numeric(13))
                        .foregroundColor(AppTheme.error)

                    Text("Failed")
                        .font(AppTheme.Typography.label(9))
                        .foregroundColor(AppTheme.error)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(AppTheme.error.opacity(0.1)))
                }
            }
            .padding(AppTheme.Spacing.compact)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : AppTheme.error.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : AppTheme.error.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private func emptyState(icon: String, message: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color.opacity(0.5))

            Text(message)
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.large)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SipOverviewCard(
            upcomingSips: [
                FASip(id: "1", clientId: "c1", clientName: "Priya Patel", fundName: "HDFC Flexi Cap Fund - Direct Growth", amount: 10000, frequency: "MONTHLY", sipDate: 5),
                FASip(id: "2", clientId: "c2", clientName: "Rajesh Sharma", fundName: "ICICI Pru Bluechip Fund - Direct Growth", amount: 25000, frequency: "MONTHLY", sipDate: 10),
                FASip(id: "3", clientId: "c3", clientName: "Ananya Patel", fundName: "SBI Small Cap Fund - Direct Growth", amount: 5000, frequency: "MONTHLY", sipDate: 15)
            ],
            failedSips: [
                FASip(id: "4", clientId: "c1", clientName: "Vikram Patel", fundName: "Axis Long Term Equity Fund", amount: 15000, status: "FAILED"),
                FASip(id: "5", clientId: "c2", clientName: "Sunita Sharma", fundName: "Kotak Emerging Equity Fund", amount: 8000, status: "CANCELLED")
            ]
        )
        .padding(.horizontal, AppTheme.Spacing.medium)
    }
}
