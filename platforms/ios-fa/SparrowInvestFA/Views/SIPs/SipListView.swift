import SwiftUI

struct SipListView: View {
    @StateObject private var store = SipStore()
    @State private var showCreateSip = false
    @State private var showCancelAlert = false
    @State private var sipToCancel: FASip?
    @State private var showActionBanner = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("SIPs")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showCreateSip) {
                    CreateSipView(store: store)
                }
                .alert("Cancel SIP", isPresented: $showCancelAlert, presenting: sipToCancel) { sip in
                    Button("Keep", role: .cancel) { }
                    Button("Cancel SIP", role: .destructive) {
                        Task { await store.cancelSip(id: sip.id) }
                    }
                } message: { sip in
                    Text("Are you sure you want to cancel the SIP for \(sip.fundName)? This action cannot be undone.")
                }
                .overlay(alignment: .bottom) { bannerOverlay }
                .onChange(of: store.actionMessage) { _, newValue in
                    if newValue != nil {
                        withAnimation(.easeInOut) { showActionBanner = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            withAnimation(.easeInOut) { showActionBanner = false }
                            store.clearActionMessage()
                        }
                    }
                }
                .task { await store.loadSips() }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showCreateSip = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                    Text("New SIP")
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.primaryGradient)
                .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var bannerOverlay: some View {
        if showActionBanner, let message = store.actionMessage {
            actionBanner(message: message, isSuccess: store.isActionSuccess)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            summaryBar

            // Pill-shaped filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(store.filters, id: \.self) { filter in
                        Button {
                            store.selectedFilter = filter
                        } label: {
                            Text(filter)
                                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                .foregroundColor(store.selectedFilter == filter ? .white : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    store.selectedFilter == filter
                                        ? AnyShapeStyle(AppTheme.primaryGradient)
                                        : AnyShapeStyle(Color.clear)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                )
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)
            }

            if store.isLoading && store.sips.isEmpty {
                Spacer()
                ProgressView("Loading SIPs...")
                Spacer()
            } else if store.filteredSips.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                sipList
            }
        }
    }

    private var sipList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(store.filteredSips) { sip in
                    sipRow(sip)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.xxxLarge)
        }
        .refreshable { await store.loadSips() }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack {
            Text("\(store.filteredSips.count) SIPs")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            Spacer()

            Text("\(AppTheme.formatCurrencyWithSymbol(store.totalMonthlyValue))/month")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(AppTheme.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
    }

    // MARK: - SIP Row

    private func sipRow(_ sip: FASip) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Top row: fund name + amount/status
            HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
                // SIP Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sip.fundName)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let clientName = sip.clientName {
                        Text(clientName)
                            .font(AppTheme.Typography.label(iPad ? 15 : 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(sip.formattedAmount)
                        .font(AppTheme.Typography.numeric(iPad ? 17 : 14))
                        .foregroundColor(.primary)

                    statusBadge(sip.status)
                }
            }

            // Bottom row: details + action buttons
            HStack {
                // Frequency & Date
                HStack(spacing: AppTheme.Spacing.small) {
                    Text("\(sip.frequency.capitalized) - Day \(sip.sipDate)")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)

                    if sip.installmentsPaid > 0 {
                        Text("\(sip.installmentsPaid) paid")
                            .font(AppTheme.Typography.label(iPad ? 12 : 10))
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                // Action Buttons
                HStack(spacing: AppTheme.Spacing.small) {
                    if sip.isActive {
                        sipActionButton(
                            icon: "pause.fill",
                            label: "Pause",
                            color: AppTheme.warning,
                            isProcessing: store.processingId == sip.id
                        ) {
                            Task { await store.pauseSip(id: sip.id) }
                        }

                        sipActionButton(
                            icon: "xmark",
                            label: "Cancel",
                            color: AppTheme.error,
                            isProcessing: store.processingId == sip.id
                        ) {
                            sipToCancel = sip
                            showCancelAlert = true
                        }
                    } else if sip.isPaused {
                        sipActionButton(
                            icon: "play.fill",
                            label: "Resume",
                            color: AppTheme.success,
                            isProcessing: store.processingId == sip.id
                        ) {
                            Task { await store.resumeSip(id: sip.id) }
                        }

                        sipActionButton(
                            icon: "xmark",
                            label: "Cancel",
                            color: AppTheme.error,
                            isProcessing: store.processingId == sip.id
                        ) {
                            sipToCancel = sip
                            showCancelAlert = true
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    // MARK: - SIP Action Button

    private func sipActionButton(icon: String, label: String, color: Color, isProcessing: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }

                Text(label)
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
            }
            .foregroundColor(color)
            .padding(.horizontal, AppTheme.Spacing.compact)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
        }
        .disabled(isProcessing)
    }

    // MARK: - Status Badge

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(AppTheme.Typography.label(iPad ? 12 : 10))
            .foregroundColor(AppTheme.statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Action Banner

    private func actionBanner(message: String, isSuccess: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16))

            Text(message)
                .font(AppTheme.Typography.accent(iPad ? 17 : 14))

            Spacer()
        }
        .foregroundColor(.white)
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(isSuccess ? AppTheme.success : AppTheme.error)
        )
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.small)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No SIPs found")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text(store.selectedFilter == "All"
                 ? "Create a new SIP to get started"
                 : "No SIPs match the selected filter")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)

            if store.selectedFilter == "All" {
                Button {
                    showCreateSip = true
                } label: {
                    Text("Create SIP")
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
    }
}
