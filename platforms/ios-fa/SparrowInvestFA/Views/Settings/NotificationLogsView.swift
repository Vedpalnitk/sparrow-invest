import SwiftUI

struct NotificationLogsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var logs: [NotificationLogItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading notifications...")
                        .padding(.top, AppTheme.Spacing.xxxLarge)
                } else if logs.isEmpty {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No notifications yet")
                            .font(AppTheme.Typography.headline(17))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, AppTheme.Spacing.xxxLarge)
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(logs, id: \.id) { log in
                            notificationRow(log)
                                .onTapGesture {
                                    markAsRead(log.id)
                                }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.xxxLarge)
                }
            }
            .navigationTitle("Notification Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        markAllAsRead()
                    } label: {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            logs = NotificationLogItem.mockData
            isLoading = false
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ item: NotificationLogItem) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
            // Unread indicator
            Circle()
                .fill(item.isRead ? Color.clear : AppTheme.primary)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            // Type icon
            ZStack {
                Circle()
                    .fill(typeColor(item.type).opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: typeIcon(item.type))
                    .font(.system(size: 14))
                    .foregroundColor(typeColor(item.type))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                Text(item.title)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                Text(item.body)
                    .font(AppTheme.Typography.label(12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(item.timestamp)
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .listItemCard()
    }

    // MARK: - Type Helpers

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "trade": return "arrow.left.arrow.right"
        case "sip": return "arrow.triangle.2.circlepath"
        case "kyc": return "checkmark.shield"
        case "portfolio": return "chart.line.uptrend.xyaxis"
        case "client": return "person.badge.plus"
        case "system": return "gearshape"
        default: return "bell"
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "trade": return AppTheme.primary
        case "sip": return AppTheme.success
        case "kyc": return AppTheme.info
        case "portfolio": return AppTheme.warning
        case "client": return AppTheme.secondary
        case "system": return AppTheme.primaryLight
        default: return .secondary
        }
    }

    // MARK: - Actions

    private func markAsRead(_ id: String) {
        if let index = logs.firstIndex(where: { $0.id == id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                logs[index].isRead = true
            }
        }
    }

    private func markAllAsRead() {
        withAnimation(.easeInOut(duration: 0.3)) {
            for index in logs.indices {
                logs[index].isRead = true
            }
        }
    }
}

// MARK: - Notification Log Item

struct NotificationLogItem: Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String
    var isRead: Bool
    let timestamp: String

    static let mockData: [NotificationLogItem] = [
        NotificationLogItem(
            id: "n1",
            title: "Trade order executed",
            body: "Priya Patel's buy order for HDFC Top 100 Direct Growth has been successfully executed at NAV 842.35",
            type: "trade",
            isRead: true,
            timestamp: "2h ago"
        ),
        NotificationLogItem(
            id: "n2",
            title: "SIP reminder",
            body: "Monthly SIP due tomorrow for 3 clients. Review and confirm execution before market hours.",
            type: "sip",
            isRead: false,
            timestamp: "3h ago"
        ),
        NotificationLogItem(
            id: "n3",
            title: "KYC update",
            body: "Rajesh Sharma's KYC verified successfully. All documents approved by the registrar.",
            type: "kyc",
            isRead: true,
            timestamp: "5h ago"
        ),
        NotificationLogItem(
            id: "n4",
            title: "Portfolio alert",
            body: "Vikram Patel's portfolio dropped 3.2% today due to market correction in mid-cap segment.",
            type: "portfolio",
            isRead: false,
            timestamp: "6h ago"
        ),
        NotificationLogItem(
            id: "n5",
            title: "Client request",
            body: "New onboarding request from Ananya Patel. Complete profile setup and risk assessment.",
            type: "client",
            isRead: false,
            timestamp: "Yesterday"
        ),
        NotificationLogItem(
            id: "n6",
            title: "Switch order completed",
            body: "Harish Patel's switch from ICICI Prudential Value Discovery to Axis Bluechip completed.",
            type: "trade",
            isRead: true,
            timestamp: "Yesterday"
        ),
        NotificationLogItem(
            id: "n7",
            title: "SIP cancelled",
            body: "Sunita Sharma cancelled her monthly SIP of Rs 10,000 in Kotak Emerging Equity.",
            type: "sip",
            isRead: false,
            timestamp: "2 days ago"
        ),
        NotificationLogItem(
            id: "n8",
            title: "System maintenance",
            body: "Scheduled platform maintenance on Sunday 2 AM - 5 AM IST. Trading services will be unavailable.",
            type: "system",
            isRead: true,
            timestamp: "3 days ago"
        ),
    ]
}
