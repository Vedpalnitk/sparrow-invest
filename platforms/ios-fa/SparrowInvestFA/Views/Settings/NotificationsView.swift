import SwiftUI

// MARK: - Notification Models

enum NotificationCategory: String, CaseIterable, Identifiable {
    case tradeAlerts = "trade_alerts"
    case sipReminders = "sip_reminders"
    case clientRequests = "client_requests"
    case marketUpdates = "market_updates"
    case dailyDigest = "daily_digest"
    case portfolioAlerts = "portfolio_alerts"
    case kycAlerts = "kyc_alerts"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tradeAlerts: return "Trade Alerts"
        case .sipReminders: return "SIP Reminders"
        case .clientRequests: return "Client Requests"
        case .marketUpdates: return "Market Updates"
        case .dailyDigest: return "Daily Digest"
        case .portfolioAlerts: return "Portfolio Alerts"
        case .kycAlerts: return "KYC Alerts"
        }
    }

    var description: String {
        switch self {
        case .tradeAlerts: return "Buy, sell, and switch order updates"
        case .sipReminders: return "Upcoming SIP dates and failures"
        case .clientRequests: return "New client requests and approvals"
        case .marketUpdates: return "Market movements and news"
        case .dailyDigest: return "Daily portfolio summary"
        case .portfolioAlerts: return "Significant portfolio changes"
        case .kycAlerts: return "KYC status and verification updates"
        }
    }

    var icon: String {
        switch self {
        case .tradeAlerts: return "arrow.left.arrow.right"
        case .sipReminders: return "arrow.triangle.2.circlepath"
        case .clientRequests: return "person.badge.plus"
        case .marketUpdates: return "chart.line.uptrend.xyaxis"
        case .dailyDigest: return "newspaper"
        case .portfolioAlerts: return "exclamationmark.triangle"
        case .kycAlerts: return "checkmark.shield"
        }
    }

    /// Categories that belong to the "Alerts" section
    static var alerts: [NotificationCategory] {
        [.tradeAlerts, .sipReminders, .clientRequests, .portfolioAlerts, .kycAlerts]
    }

    /// Categories that belong to the "Updates" section
    static var updates: [NotificationCategory] {
        [.marketUpdates, .dailyDigest]
    }
}

enum NotificationChannel: String, CaseIterable {
    case push = "push"
    case email = "email"
    case whatsapp = "whatsapp"

    var displayName: String {
        switch self {
        case .push: return "Push"
        case .email: return "Email"
        case .whatsapp: return "WhatsApp"
        }
    }
}

struct NotificationPreference: Codable {
    var push: Bool
    var email: Bool
    var whatsapp: Bool

    init(push: Bool = true, email: Bool = true, whatsapp: Bool = false) {
        self.push = push
        self.email = email
        self.whatsapp = whatsapp
    }
}

struct NotificationPreferencesPayload: Codable {
    var tradeAlerts: NotificationPreference
    var sipReminders: NotificationPreference
    var clientRequests: NotificationPreference
    var marketUpdates: NotificationPreference
    var dailyDigest: NotificationPreference
    var portfolioAlerts: NotificationPreference
    var kycAlerts: NotificationPreference

    enum CodingKeys: String, CodingKey {
        case tradeAlerts = "trade_alerts"
        case sipReminders = "sip_reminders"
        case clientRequests = "client_requests"
        case marketUpdates = "market_updates"
        case dailyDigest = "daily_digest"
        case portfolioAlerts = "portfolio_alerts"
        case kycAlerts = "kyc_alerts"
    }

    init() {
        tradeAlerts = NotificationPreference(push: true, email: true, whatsapp: false)
        sipReminders = NotificationPreference(push: true, email: true, whatsapp: false)
        clientRequests = NotificationPreference(push: true, email: true, whatsapp: false)
        marketUpdates = NotificationPreference(push: false, email: true, whatsapp: false)
        dailyDigest = NotificationPreference(push: false, email: true, whatsapp: false)
        portfolioAlerts = NotificationPreference(push: true, email: false, whatsapp: false)
        kycAlerts = NotificationPreference(push: true, email: true, whatsapp: false)
    }

    mutating func preference(for category: NotificationCategory) -> NotificationPreference {
        switch category {
        case .tradeAlerts: return tradeAlerts
        case .sipReminders: return sipReminders
        case .clientRequests: return clientRequests
        case .marketUpdates: return marketUpdates
        case .dailyDigest: return dailyDigest
        case .portfolioAlerts: return portfolioAlerts
        case .kycAlerts: return kycAlerts
        }
    }

    mutating func setPreference(for category: NotificationCategory, channel: NotificationChannel, enabled: Bool) {
        switch (category, channel) {
        case (.tradeAlerts, .push): tradeAlerts.push = enabled
        case (.tradeAlerts, .email): tradeAlerts.email = enabled
        case (.tradeAlerts, .whatsapp): tradeAlerts.whatsapp = enabled
        case (.sipReminders, .push): sipReminders.push = enabled
        case (.sipReminders, .email): sipReminders.email = enabled
        case (.sipReminders, .whatsapp): sipReminders.whatsapp = enabled
        case (.clientRequests, .push): clientRequests.push = enabled
        case (.clientRequests, .email): clientRequests.email = enabled
        case (.clientRequests, .whatsapp): clientRequests.whatsapp = enabled
        case (.marketUpdates, .push): marketUpdates.push = enabled
        case (.marketUpdates, .email): marketUpdates.email = enabled
        case (.marketUpdates, .whatsapp): marketUpdates.whatsapp = enabled
        case (.dailyDigest, .push): dailyDigest.push = enabled
        case (.dailyDigest, .email): dailyDigest.email = enabled
        case (.dailyDigest, .whatsapp): dailyDigest.whatsapp = enabled
        case (.portfolioAlerts, .push): portfolioAlerts.push = enabled
        case (.portfolioAlerts, .email): portfolioAlerts.email = enabled
        case (.portfolioAlerts, .whatsapp): portfolioAlerts.whatsapp = enabled
        case (.kycAlerts, .push): kycAlerts.push = enabled
        case (.kycAlerts, .email): kycAlerts.email = enabled
        case (.kycAlerts, .whatsapp): kycAlerts.whatsapp = enabled
        }
    }

    func isEnabled(category: NotificationCategory, channel: NotificationChannel) -> Bool {
        let pref: NotificationPreference
        switch category {
        case .tradeAlerts: pref = tradeAlerts
        case .sipReminders: pref = sipReminders
        case .clientRequests: pref = clientRequests
        case .marketUpdates: pref = marketUpdates
        case .dailyDigest: pref = dailyDigest
        case .portfolioAlerts: pref = portfolioAlerts
        case .kycAlerts: pref = kycAlerts
        }
        switch channel {
        case .push: return pref.push
        case .email: return pref.email
        case .whatsapp: return pref.whatsapp
        }
    }
}

struct NotificationLogEntry: Identifiable {
    let id: String
    let category: String
    let channel: String
    let subject: String?
    let status: String
    let sentAt: String?
    let createdAt: String
}

// MARK: - View

struct NotificationsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var preferences = NotificationPreferencesPayload()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var logs: [NotificationLogEntry] = []
    @State private var logsLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading preferences...")
                            .font(AppTheme.Typography.caption())
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    notificationsContent
                }
            }
            .navigationTitle("Notifications")
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
            }
        }
        .task {
            await loadPreferences()
            await loadLogs()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Content

    private var notificationsContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Alerts Section
                notificationSection(title: "ALERTS", categories: NotificationCategory.alerts)

                // Updates Section
                notificationSection(title: "UPDATES", categories: NotificationCategory.updates)

                // Recent Notification Logs
                HStack {
                    sectionHeader("RECENT NOTIFICATIONS")
                    Spacer()
                    NavigationLink {
                        NotificationLogsView()
                    } label: {
                        Text("View All")
                            .font(AppTheme.Typography.label(iPad ? 14 : 12))
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .padding(.trailing, AppTheme.Spacing.compact)

                if logsLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .frame(height: 60)
                        Spacer()
                    }
                } else if logs.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                            Text("No recent notifications")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, AppTheme.Spacing.large)
                        Spacer()
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large)
                } else {
                    VStack(spacing: 0) {
                        ForEach(logs.prefix(10)) { log in
                            notificationLogRow(log)
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }

    // MARK: - Notification Section

    private func notificationSection(title: String, categories: [NotificationCategory]) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            sectionHeader(title)

            VStack(spacing: 0) {
                ForEach(categories) { category in
                    categoryRow(category)

                    if category.id != categories.last?.id {
                        Divider()
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .opacity(0.3)
                    }
                }
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
        }
    }

    // MARK: - Category Row

    private func categoryRow(_ category: NotificationCategory) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Category header
            HStack(spacing: AppTheme.Spacing.compact) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.displayName)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    Text(category.description)
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Channel toggles
            HStack(spacing: AppTheme.Spacing.large) {
                ForEach(NotificationChannel.allCases, id: \.rawValue) { channel in
                    channelToggle(category: category, channel: channel)
                }
            }
            .padding(.leading, 36)
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Channel Toggle

    private func channelToggle(category: NotificationCategory, channel: NotificationChannel) -> some View {
        let isEnabled = preferences.isEnabled(category: category, channel: channel)

        return HStack(spacing: 4) {
            Text(channel.displayName)
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)

            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    preferences.setPreference(for: category, channel: channel, enabled: newValue)
                    savePreferences()
                }
            ))
            .labelsHidden()
            .scaleEffect(0.8)
        }
    }

    // MARK: - Notification Log Row

    private func notificationLogRow(_ log: NotificationLogEntry) -> some View {
        let statusColor = logStatusColor(log.status)
        let channelIcon = logChannelIcon(log.channel)

        return HStack(spacing: AppTheme.Spacing.compact) {
            // Channel icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: channelIcon)
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(log.subject ?? log.category.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: AppTheme.Spacing.small) {
                    Text(log.channel.capitalized)
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)

                    Text(formatLogDate(log.sentAt ?? log.createdAt))
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status icon
            Image(systemName: logStatusIcon(log.status))
                .font(.system(size: 14))
                .foregroundColor(statusColor)
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.label(iPad ? 13 : 11))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppTheme.Spacing.compact)
            .padding(.top, AppTheme.Spacing.small)
    }

    // MARK: - Helpers

    private func logStatusColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "SENT", "DELIVERED": return AppTheme.success
        case "FAILED": return AppTheme.error
        case "PENDING", "QUEUED": return AppTheme.warning
        default: return .secondary
        }
    }

    private func logChannelIcon(_ channel: String) -> String {
        switch channel.uppercased() {
        case "EMAIL": return "envelope.fill"
        case "PUSH": return "bell.fill"
        case "WHATSAPP": return "message.fill"
        default: return "bell.badge.fill"
        }
    }

    private func logStatusIcon(_ status: String) -> String {
        switch status.uppercased() {
        case "SENT", "DELIVERED": return "checkmark"
        case "FAILED": return "xmark"
        default: return "clock"
        }
    }

    private func formatLogDate(_ dateStr: String) -> String {
        if dateStr.count >= 16 {
            return String(dateStr.prefix(16)).replacingOccurrences(of: "T", with: " ")
        }
        return String(dateStr.prefix(10))
    }

    // MARK: - API

    private func loadPreferences() async {
        isLoading = true
        do {
            let data = try await APIService.shared.get("/notifications/preferences") as Data
            let decoder = JSONDecoder()
            let loaded = try decoder.decode(NotificationPreferencesPayload.self, from: data)
            await MainActor.run {
                preferences = loaded
                isLoading = false
            }
        } catch {
            // Use defaults if API fails
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func loadLogs() async {
        logsLoading = true
        // Simulated logs for demo - replace with real API call
        await MainActor.run {
            logs = [
                NotificationLogEntry(id: "1", category: "trade_alerts", channel: "push",
                                     subject: "Buy order executed for Priya Patel",
                                     status: "DELIVERED", sentAt: "2026-02-10T09:30:00Z",
                                     createdAt: "2026-02-10T09:30:00Z"),
                NotificationLogEntry(id: "2", category: "sip_reminders", channel: "email",
                                     subject: "SIP due tomorrow: HDFC Top 100",
                                     status: "SENT", sentAt: "2026-02-09T18:00:00Z",
                                     createdAt: "2026-02-09T18:00:00Z"),
                NotificationLogEntry(id: "3", category: "client_requests", channel: "push",
                                     subject: "New client onboarding: Rajesh Sharma",
                                     status: "DELIVERED", sentAt: "2026-02-09T14:22:00Z",
                                     createdAt: "2026-02-09T14:22:00Z"),
                NotificationLogEntry(id: "4", category: "kyc_alerts", channel: "email",
                                     subject: "KYC verification pending for Ananya Patel",
                                     status: "FAILED", sentAt: nil,
                                     createdAt: "2026-02-08T11:00:00Z"),
                NotificationLogEntry(id: "5", category: "portfolio_alerts", channel: "push",
                                     subject: "Portfolio dropped 3% - Vikram Patel",
                                     status: "PENDING", sentAt: nil,
                                     createdAt: "2026-02-08T08:45:00Z"),
            ]
            logsLoading = false
        }
    }

    private func savePreferences() {
        Task {
            do {
                let _ = try await APIService.shared.put("/notifications/preferences", body: preferences)
            } catch {
                // Silently handle save errors for toggle changes
                print("Failed to save notification preferences: \(error)")
            }
        }
    }
}
