import SwiftUI

struct CommunicationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @StateObject private var store = CommunicationStore()
    @StateObject private var clientStore = ClientStore()

    @State private var showCompose = false
    @State private var showBulkSend = false
    @State private var channelFilter: String?
    @State private var typeFilter: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    // Stats KPI Row
                    statsRow

                    // Channel Filter
                    channelFilterToggle

                    // Type Filter
                    if !store.templates.isEmpty {
                        typeFilterSelector
                    }

                    // History
                    historySection
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Communications")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.compact) {
                        Button { showBulkSend = true } label: {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 13))
                        }
                        Button { showCompose = true } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14))
                        }
                    }
                }
            }
        }
        .task {
            await store.loadData()
            await clientStore.loadClients()
        }
        .sheet(isPresented: $showCompose) {
            ComposeSheet(store: store, clients: clientStore.clients)
        }
        .sheet(isPresented: $showBulkSend) {
            BulkSendSheet(store: store, clients: clientStore.clients)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            statCard(icon: "paperplane.fill", label: "Total Sent",
                     value: "\(store.stats?.totalSent ?? 0)", color: AppTheme.primary)
            statCard(icon: "envelope.fill", label: "Emails",
                     value: "\(store.stats?.emailCount ?? 0)", color: AppTheme.info)
            statCard(icon: "message.fill", label: "WhatsApp",
                     value: "\(store.stats?.whatsappCount ?? 0)", color: AppTheme.whatsAppGreen)
            statCard(icon: "calendar", label: "This Month",
                     value: "\(store.stats?.thisMonthCount ?? 0)", color: AppTheme.warning)
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: iPad ? 38 : 32, height: iPad ? 38 : 32)
                Image(systemName: icon)
                    .font(.system(size: iPad ? 16 : 13))
                    .foregroundColor(color)
            }
            Text(value)
                .font(AppTheme.Typography.headline(iPad ? 24 : 20))
                .foregroundColor(.primary)
            Text(label)
                .font(AppTheme.Typography.caption(iPad ? 13 : 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Channel Filter Toggle

    private var channelFilterToggle: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Channel")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppTheme.Spacing.small) {
                channelFilterButton(label: "All", icon: "tray.fill", value: nil, color: AppTheme.primary)
                channelFilterButton(label: "Email", icon: "envelope.fill", value: "EMAIL", color: AppTheme.primary)
                channelFilterButton(label: "WhatsApp", icon: "message.fill", value: "WHATSAPP", color: AppTheme.whatsAppGreen)
            }
        }
    }

    private func channelFilterButton(label: String, icon: String, value: String?, color: Color) -> some View {
        let isSelected = channelFilter == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                channelFilter = value
                store.channelFilter = value
                reloadHistory()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(color.opacity(0.1))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Type Filter Selector

    private var typeFilterSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Type")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    typeFilterPill(label: "All", type: nil)
                    ForEach(store.templates) { template in
                        typeFilterPill(label: template.label, type: template.type)
                    }
                }
            }
        }
    }

    private func typeFilterPill(label: String, type: String?) -> some View {
        let isSelected = typeFilter == type
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                typeFilter = type
                store.typeFilter = type
                reloadHistory()
            }
        } label: {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                .fixedSize()
                .foregroundColor(isSelected ? .white : AppTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? AnyShapeStyle(AppTheme.primaryGradient)
                        : AnyShapeStyle(AppTheme.primary.opacity(0.08))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func reloadHistory() {
        Task { await store.loadHistory(page: 1) }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("History")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(store.total) total")
                    .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
            }

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if store.logs.isEmpty {
                VStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No communications yet")
                        .font(AppTheme.Typography.body(iPad ? 16 : 14))
                        .foregroundColor(.secondary)
                    Text("Tap compose to send your first message")
                        .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xxLarge)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
                )
            } else {
                ForEach(store.logs) { log in
                    historyRow(log)
                }

                if store.totalPages > 1 {
                    paginationRow
                }
            }

            Spacer().frame(height: 40)
        }
    }

    private func historyRow(_ log: CommunicationLog) -> some View {
        let channelColor: Color = log.channel == "EMAIL" ? AppTheme.primary : AppTheme.whatsAppGreen

        return HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(channelColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: log.channel == "EMAIL" ? "envelope.fill" : "message.fill")
                    .font(.system(size: 14))
                    .foregroundColor(channelColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.client?.name ?? "Unknown")
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(log.subject ?? log.type)
                    .font(AppTheme.Typography.caption(iPad ? 15 : 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(formatDate(log.createdAt))
                    .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            Text(log.status)
                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                .foregroundColor(statusColor(log.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor(log.status).opacity(0.1))
                .clipShape(Capsule())
        }
        .listItemCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    private var paginationRow: some View {
        HStack {
            Button {
                Task { await store.loadHistory(page: store.page - 1) }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10))
                    Text("Previous")
                }
                .font(AppTheme.Typography.label(iPad ? 15 : 13))
                .foregroundColor(store.page <= 1 ? .secondary.opacity(0.4) : AppTheme.primary)
            }
            .disabled(store.page <= 1)

            Spacer()
            Text("Page \(store.page) of \(store.totalPages)")
                .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                .foregroundColor(.secondary)
            Spacer()

            Button {
                Task { await store.loadHistory(page: store.page + 1) }
            } label: {
                HStack(spacing: 4) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                }
                .font(AppTheme.Typography.label(iPad ? 15 : 13))
                .foregroundColor(store.page >= store.totalPages ? .secondary.opacity(0.4) : AppTheme.primary)
            }
            .disabled(store.page >= store.totalPages)
        }
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "sent": return AppTheme.success
        case "failed": return AppTheme.error
        case "pending": return AppTheme.warning
        default: return .secondary
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let prefix = String(dateStr.prefix(10))
        let parts = prefix.split(separator: "-")
        guard parts.count == 3, let m = Int(parts[1]) else { return dateStr }
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let month = m < months.count ? months[m] : String(parts[1])
        return "\(parts[2]) \(month) \(parts[0])"
    }
}

// MARK: - Quick Compose Sheet

private struct ComposeSheet: View {
    @ObservedObject var store: CommunicationStore
    let clients: [FAClient]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var selectedClient: FAClient?
    @State private var searchQuery = ""
    @State private var channel: String = "EMAIL"
    @State private var selectedType = ""
    @State private var subject = ""
    @State private var emailBody = ""
    @State private var whatsappBody = ""
    @State private var isLoadingPreview = false
    @State private var isSending = false
    @State private var isSent = false
    @State private var error: String?
    @State private var showCopiedToast = false

    private var channelColor: Color {
        channel == "WHATSAPP" ? AppTheme.whatsAppGreen : AppTheme.primary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if isSent {
                        successView
                    } else if selectedClient == nil {
                        clientSelection
                    } else {
                        composeForm
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Quick Compose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .overlay {
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.success)
                        Text("Copied to clipboard")
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.8))
                    )
                    .foregroundColor(colorScheme == .dark ? .primary : .white)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.success)
            }

            Text("Sent successfully!")
                .font(AppTheme.Typography.headline(iPad ? 24 : 20))
                .foregroundColor(.primary)

            Text("Your message has been delivered")
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .foregroundColor(.secondary)

            Button {
                Task { await store.loadData() }
                dismiss()
            } label: {
                Text("Done")
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }

    // MARK: - Client Selection

    private var clientSelection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Select Client")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                TextField("Search clients...", text: $searchQuery)
                    .font(AppTheme.Typography.body(iPad ? 16 : 14))
            }
            .padding(.horizontal, AppTheme.Spacing.compact)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
            )

            let filtered = clients.filter {
                searchQuery.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.email.localizedCaseInsensitiveContains(searchQuery)
            }.prefix(15)

            ForEach(Array(filtered)) { client in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedClient = client
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.compact) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Text(String(client.name.prefix(1)).uppercased())
                                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                .foregroundColor(AppTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name)
                                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                .foregroundColor(.primary)
                            Text(client.email)
                                .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .listItemCard(cornerRadius: AppTheme.CornerRadius.medium)
                }
            }
        }
    }

    // MARK: - Compose Form

    private var composeForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Selected client chip
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Text(String(selectedClient?.name.prefix(1) ?? "?").uppercased())
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(selectedClient?.name ?? "")
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.primary)
                    Text(selectedClient?.email ?? "")
                        .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedClient = nil
                        selectedType = ""
                        subject = ""
                        emailBody = ""
                        whatsappBody = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(AppTheme.Spacing.compact)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
            )

            // Channel toggle
            channelToggle

            // Template selector
            templateSelector

            if isLoadingPreview {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(minHeight: 60)
            }

            if !selectedType.isEmpty && !isLoadingPreview {
                if channel == "EMAIL" {
                    // Subject field
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        Text("Subject")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        TextField("Email subject", text: $subject)
                            .font(AppTheme.Typography.body(iPad ? 16 : 14))
                            .padding(.horizontal, AppTheme.Spacing.compact)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                }

                // Message preview
                messagePreview
            }

            if let error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                }
                .foregroundColor(AppTheme.error)
            }

            // Send button
            sendButton
        }
    }

    // MARK: - Channel Toggle (matching ShareWithClientSheet)

    private var channelToggle: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Channel")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppTheme.Spacing.small) {
                composeChannelButton(label: "Email", icon: "envelope.fill", value: "EMAIL", color: AppTheme.primary)
                composeChannelButton(label: "WhatsApp", icon: "message.fill", value: "WHATSAPP", color: AppTheme.whatsAppGreen)
            }
        }
    }

    private func composeChannelButton(label: String, icon: String, value: String, color: Color) -> some View {
        let isSelected = channel == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { channel = value }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(color.opacity(0.1))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Selector (matching ShareWithClientSheet)

    private var templateSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Template")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(store.templates) { template in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedType = template.type
                                loadPreview()
                            }
                        } label: {
                            Text(template.label)
                                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                .fixedSize()
                                .foregroundColor(selectedType == template.type ? .white : AppTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedType == template.type
                                        ? AnyShapeStyle(AppTheme.primaryGradient)
                                        : AnyShapeStyle(AppTheme.primary.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Message Preview (matching ShareWithClientSheet)

    private var messagePreview: some View {
        let previewText = channel == "EMAIL"
            ? emailBody.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            : whatsappBody

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Message Preview")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    UIPasteboard.general.string = previewText
                    withAnimation { showCopiedToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { showCopiedToast = false }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                        Text("Copy")
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    }
                    .foregroundColor(AppTheme.primary)
                }
                .buttonStyle(.plain)
            }

            Text(previewText)
                .font(AppTheme.Typography.body(iPad ? 15 : 13))
                .foregroundColor(.primary)
                .padding(AppTheme.Spacing.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Send Button (matching ShareWithClientSheet)

    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            HStack(spacing: 6) {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: channel == "WHATSAPP" ? "paperplane.fill" : "envelope.fill")
                        .font(.system(size: 14))
                    Text(channel == "WHATSAPP" ? "Send via WhatsApp" : "Send via Email")
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(channelColor.opacity(selectedType.isEmpty || isSending || isLoadingPreview ? 0.4 : 1.0))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(selectedType.isEmpty || isSending || isLoadingPreview)
    }

    // MARK: - Actions

    private func loadPreview() {
        guard let client = selectedClient else { return }
        isLoadingPreview = true
        Task {
            if let preview = await store.preview(clientId: client.id, type: selectedType) {
                subject = preview.emailSubject
                emailBody = preview.emailBody
                whatsappBody = preview.whatsappBody
            }
            isLoadingPreview = false
        }
    }

    private func sendMessage() {
        guard let client = selectedClient else { return }
        isSending = true
        error = nil

        if channel == "WHATSAPP" {
            let phone = client.phone?.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression) ?? ""
            let encoded = whatsappBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlStr = phone.isEmpty ? "https://wa.me/?text=\(encoded)" : "https://wa.me/\(phone)?text=\(encoded)"
            if let url = URL(string: urlStr) {
                UIApplication.shared.open(url)
            }
            Task {
                _ = await store.send(clientId: client.id, channel: "WHATSAPP", type: selectedType, subject: "", body: whatsappBody)
                isSent = true
                isSending = false
            }
        } else {
            Task {
                let result = await store.send(clientId: client.id, channel: "EMAIL", type: selectedType, subject: subject, body: emailBody)
                if let result, result.success {
                    isSent = true
                } else {
                    error = result?.error ?? "Failed to send email"
                }
                isSending = false
            }
        }
    }
}

// MARK: - Bulk Send Sheet

private struct BulkSendSheet: View {
    @ObservedObject var store: CommunicationStore
    let clients: [FAClient]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var selectedIds: Set<String> = []
    @State private var channel = "EMAIL"
    @State private var selectedType = ""
    @State private var searchQuery = ""
    @State private var isSending = false
    @State private var result: BulkSendResult?
    @State private var error: String?

    private var channelColor: Color {
        channel == "WHATSAPP" ? AppTheme.whatsAppGreen : AppTheme.primary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    if let result {
                        resultView(result)
                    } else {
                        bulkForm
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Bulk Send")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }

    // MARK: - Result View

    private func resultView(_ result: BulkSendResult) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.success)
            }

            Text("Bulk send complete")
                .font(AppTheme.Typography.headline(iPad ? 24 : 20))
                .foregroundColor(.primary)

            HStack(spacing: AppTheme.Spacing.medium) {
                VStack(spacing: 4) {
                    Text("\(result.sent)")
                        .font(AppTheme.Typography.headline(iPad ? 26 : 22))
                        .foregroundColor(AppTheme.success)
                    Text("Sent")
                        .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 4) {
                    Text("\(result.failed)")
                        .font(AppTheme.Typography.headline(iPad ? 26 : 22))
                        .foregroundColor(result.failed > 0 ? AppTheme.error : .secondary)
                    Text("Failed")
                        .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 4) {
                    Text("\(result.total)")
                        .font(AppTheme.Typography.headline(iPad ? 26 : 22))
                        .foregroundColor(.primary)
                    Text("Total")
                        .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
            }

            Button {
                Task { await store.loadData() }
                dismiss()
            } label: {
                Text("Done")
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, AppTheme.Spacing.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }

    // MARK: - Bulk Form

    private var bulkForm: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Channel toggle
            bulkChannelToggle

            // Template selector
            bulkTemplateSelector

            // Client selection
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Select Clients")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(selectedIds.count) selected")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)
                }

                // Search
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    TextField("Search clients...", text: $searchQuery)
                        .font(AppTheme.Typography.body(iPad ? 16 : 14))
                }
                .padding(.horizontal, AppTheme.Spacing.compact)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08), lineWidth: 0.5)
                )

                // Select all / deselect
                let filteredClients = clients.filter {
                    searchQuery.isEmpty ||
                    $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.email.localizedCaseInsensitiveContains(searchQuery)
                }

                HStack {
                    Button {
                        let allIds = Set(filteredClients.map { $0.id })
                        if allIds.isSubset(of: selectedIds) {
                            selectedIds.subtract(allIds)
                        } else {
                            selectedIds.formUnion(allIds)
                        }
                    } label: {
                        let allSelected = !filteredClients.isEmpty && Set(filteredClients.map { $0.id }).isSubset(of: selectedIds)
                        HStack(spacing: 4) {
                            Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                            Text(allSelected ? "Deselect All" : "Select All")
                                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        }
                        .foregroundColor(AppTheme.primary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                ForEach(filteredClients) { client in
                    let isSelected = selectedIds.contains(client.id)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if isSelected { selectedIds.remove(client.id) }
                            else { selectedIds.insert(client.id) }
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.compact) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(isSelected ? AppTheme.primary : .secondary.opacity(0.4))

                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Text(String(client.name.prefix(1)).uppercased())
                                    .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                                    .foregroundColor(AppTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.name)
                                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                    .foregroundColor(.primary)
                                Text(client.email)
                                    .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .listItemCard(cornerRadius: AppTheme.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                }
                .foregroundColor(AppTheme.error)
            }

            // Send button
            Button {
                sendBulk()
            } label: {
                HStack(spacing: 6) {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: channel == "WHATSAPP" ? "paperplane.fill" : "envelope.fill")
                            .font(.system(size: 14))
                        Text("Send to \(selectedIds.count) client\(selectedIds.count == 1 ? "" : "s")")
                            .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(channelColor.opacity(selectedIds.isEmpty || selectedType.isEmpty || isSending ? 0.4 : 1.0))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(selectedIds.isEmpty || selectedType.isEmpty || isSending)
        }
    }

    // MARK: - Bulk Channel Toggle

    private var bulkChannelToggle: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Channel")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppTheme.Spacing.small) {
                bulkChannelButton(label: "Email", icon: "envelope.fill", value: "EMAIL", color: AppTheme.primary)
                bulkChannelButton(label: "WhatsApp", icon: "message.fill", value: "WHATSAPP", color: AppTheme.whatsAppGreen)
            }
        }
    }

    private func bulkChannelButton(label: String, icon: String, value: String, color: Color) -> some View {
        let isSelected = channel == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { channel = value }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
            }
            .foregroundColor(isSelected ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(color.opacity(0.1))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bulk Template Selector

    private var bulkTemplateSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Template")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(store.templates) { template in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedType = template.type
                            }
                        } label: {
                            Text(template.label)
                                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                .fixedSize()
                                .foregroundColor(selectedType == template.type ? .white : AppTheme.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedType == template.type
                                        ? AnyShapeStyle(AppTheme.primaryGradient)
                                        : AnyShapeStyle(AppTheme.primary.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func sendBulk() {
        isSending = true
        error = nil
        Task {
            if let res = await store.sendBulk(clientIds: Array(selectedIds), channel: channel, type: selectedType) {
                result = res
            } else {
                error = store.errorMessage ?? "Failed to send"
            }
            isSending = false
        }
    }
}
