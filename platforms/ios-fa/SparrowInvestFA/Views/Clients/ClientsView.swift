import SwiftUI

struct ClientsView: View {
    @StateObject private var store = ClientStore()
    @State private var showAddClient = false
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        if sizeClass == .regular {
            // iPad: just the list content (parent NavigationSplitView provides the 3-column split)
            clientListContent
                .navigationTitle("Clients")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        addClientButton
                    }
                }
                .sheet(isPresented: $showAddClient) {
                    AddClientView(store: store)
                }
                .task { await store.loadClients() }
        } else {
            iPhoneClientsLayout
        }
    }

    // MARK: - iPhone Stack

    private var iPhoneClientsLayout: some View {
        NavigationStack {
            clientListContent
                .navigationTitle("Clients")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        addClientButton
                    }
                }
                .sheet(isPresented: $showAddClient) {
                    AddClientView(store: store)
                }
                .task { await store.loadClients() }
        }
    }

    // MARK: - Shared List Content

    private var clientListContent: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                TextField("Search clients...", text: $store.searchQuery)
                    .font(AppTheme.Typography.body(iPad ? 16 : 15))
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06), lineWidth: 0.5)
            )
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)

            // Filter Chips
            GlassSegmentedControl(items: store.filters, selection: $store.selectedFilter)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.small)

            // Client List
            if store.isLoading && store.clients.isEmpty {
                Spacer()
                ProgressView("Loading clients...")
                Spacer()
            } else if store.filteredClients.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(store.filteredClients) { client in
                            if sizeClass == .regular {
                                Button {
                                    coordinator.selectedClientId = client.id
                                } label: {
                                    clientRow(client)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                                .stroke(coordinator.selectedClientId == client.id ? AppTheme.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    ClientDetailView(clientId: client.id)
                                } label: {
                                    clientRow(client)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.xxxLarge)
                }
                .refreshable { await store.loadClients() }
            }
        }
        .background(AppTheme.pageBackground(colorScheme: colorScheme))
    }

    private var addClientButton: some View {
        Button {
            showAddClient = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                Text("Client")
                    .font(AppTheme.Typography.accent(14))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(AppTheme.primaryGradient)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Client Row

    private func clientRow(_ client: FAClient) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: iPad ? 52 : 48, height: iPad ? 52 : 48)

                Text(client.initials)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 15))
                    .foregroundColor(AppTheme.primary)
            }

            // Left: Identity
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(client.name)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let kyc = client.kycStatus {
                        statusBadge(kyc)
                    }
                }

                Text(client.email)
                    .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let risk = client.riskProfile {
                    Text(risk)
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Right: Metrics
            VStack(alignment: .trailing, spacing: 3) {
                Text(client.formattedAum)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 15))
                    .foregroundColor(.primary)

                returnBadge(client.returns)

                Text("\(client.sipCount) SIPs")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
            }

            if sizeClass != .regular {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .listItemCard(cornerRadius: AppTheme.CornerRadius.medium)
    }

    private func returnBadge(_ returns: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: iPad ? 12 : 10))
            Text(returns.formattedPercent)
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
        }
        .foregroundColor(AppTheme.returnColor(returns))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(AppTheme.returnColor(returns).opacity(0.1))
        .clipShape(Capsule())
    }

    private func statusBadge(_ status: String) -> some View {
        let color = kycColor(status)
        return Text(status)
            .font(AppTheme.Typography.label(iPad ? 12 : 10))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private func kycColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "VERIFIED", "COMPLETED": return AppTheme.success
        case "PENDING", "IN_PROGRESS": return AppTheme.warning
        case "REJECTED", "FAILED": return AppTheme.error
        default: return .secondary
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No clients found")
                .font(AppTheme.Typography.headline(17))
                .foregroundColor(.primary)

            Text("Try a different search or add a new client")
                .font(AppTheme.Typography.body(14))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Client Detail View

struct ClientDetailView: View {
    let clientId: String
    @StateObject private var store = ClientStore()
    @State private var selectedTab = 0
    @State private var showEditClient = false
    @State private var showExecuteTrade = false
    @State private var showCreateSip = false
    @State private var showShareSheet = false
    @State private var showCallConfirmation = false
    @State private var showGeneratePdf = false
    @State private var holdingsCategory = "All"
    @State private var holdingsSortBy = "Value"
    @State private var holdingsSortAscending = false
    @State private var headerCollapsed = false
    @State private var txTypeFilter = "All"
    @State private var txStatusFilter = "All"
    @State private var txSortBy = "Date"
    @State private var txSortAscending = false
    @State private var pendingActionsExpanded = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if let client = store.selectedClient {
                // Pinned header – collapses when content is scrolled
                pinnedHeader(client)
                    .clipped()

                // Pinned pending actions (between header and tabs, like Android)
                if !store.pendingActions.isEmpty {
                    pendingActionsSection
                }

                // Pinned tab selector
                tabSelector
                    .padding(.vertical, AppTheme.Spacing.small)

                // Scrollable content area
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.small) {
                        // Tab Content
                        switch selectedTab {
                        case 0: overviewTab(client)
                        case 1: holdingsTab(client)
                        case 2: sipsTab(client)
                        case 3: transactionsTab(client)
                        case 4: familyTab(client)
                        case 5: GoalsTabView(goals: store.goals)
                        case 6: ReportsTabView(client: client)
                        case 7: NotesTabView(clientId: clientId)
                        case 8: InsuranceTabView(clientId: clientId)
                        default: EmptyView()
                        }

                        Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("contentScroll")).minY
                                )
                        }
                    )
                }
                .coordinateSpace(name: "contentScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    let shouldCollapse = offset < -10
                    let shouldExpand = offset > -2
                    if shouldCollapse && !headerCollapsed {
                        withAnimation(.easeInOut(duration: 0.2)) { headerCollapsed = true }
                    } else if shouldExpand && headerCollapsed {
                        withAnimation(.easeInOut(duration: 0.2)) { headerCollapsed = false }
                    }
                }
                .onChange(of: selectedTab) { _, _ in
                    // Reset header when switching tabs
                    withAnimation(.easeInOut(duration: 0.2)) { headerCollapsed = false }
                }
                .refreshable { await store.loadClient(clientId) }
            } else if store.isLoading {
                Spacer()
                ProgressView("Loading client...")
                Spacer()
            }
        }
        .background(AppTheme.pageBackground(colorScheme: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Client Details")
                    .font(AppTheme.Typography.accent(17))
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showEditClient = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .sheet(isPresented: $showEditClient) {
            EditClientView(clientId: clientId) {
                Task { await store.loadClient(clientId) }
            }
        }
        .sheet(isPresented: $showExecuteTrade) {
            ExecuteTradeView(clientId: clientId)
        }
        .sheet(isPresented: $showCreateSip) {
            SipListView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let client = store.selectedClient {
                ShareWithClientSheet(client: client, onDismiss: { showShareSheet = false })
            }
        }
        .confirmationDialog(
            store.selectedClient?.phone ?? "No phone number",
            isPresented: $showCallConfirmation,
            titleVisibility: .visible
        ) {
            if let phone = store.selectedClient?.phone, !phone.isEmpty,
               let url = URL(string: "tel:\(phone)") {
                Button("Call") { UIApplication.shared.open(url) }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showGeneratePdf) {
            if let client = store.selectedClient {
                NavigationStack {
                    ReportsTabView(client: client)
                        .navigationTitle("Generate Report")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Done") { showGeneratePdf = false }
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                }
            }
        }
        .task {
            // Load client first so synthesis fallbacks have data
            await store.loadClient(clientId)
            async let pendingLoad: () = store.loadPendingActions(clientId)
            async let goalsLoad: () = store.loadGoals(clientId)
            async let allocationLoad: () = store.loadAllocation(clientId)
            async let historyLoad: () = store.loadPortfolioHistory(clientId)
            _ = await (pendingLoad, goalsLoad, allocationLoad, historyLoad)
        }
    }

    // MARK: - Pinned Header

    private func pinnedHeader(_ client: FAClientDetail) -> some View {
        VStack(spacing: 0) {
            if headerCollapsed {
                compactHeader(client)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                fullHeader(client)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: headerCollapsed)
    }

    private func compactHeader(_ client: FAClientDetail) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                Text(client.initials)
                    .font(AppTheme.Typography.accent(13))
                    .foregroundColor(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: AppTheme.Spacing.small) {
                    Text(AppTheme.formatCurrencyWithSymbol(client.aum))
                        .font(AppTheme.Typography.numeric(13))
                        .foregroundColor(AppTheme.primary)

                    Text(client.returns.formattedPercent)
                        .font(AppTheme.Typography.numeric(12))
                        .foregroundColor(AppTheme.returnColor(client.returns))
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button { showExecuteTrade = true } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Circle())
                }

                Button { showCreateSip = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Circle())
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.small)
    }

    private func fullHeader(_ client: FAClientDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Row 1: Avatar + Name/Stats + Contact actions
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Text(client.initials)
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(client.name)
                        .font(AppTheme.Typography.headline(16))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: AppTheme.Spacing.small) {
                        Text(AppTheme.formatCurrencyWithSymbol(client.aum))
                            .font(AppTheme.Typography.numeric(13))
                            .foregroundColor(AppTheme.primary)

                        returnBadge(client.returns)

                        Text("\(client.holdings.count) funds")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Contact & share buttons
                HStack(spacing: 6) {
                    contactIconButton(icon: "phone.fill", color: AppTheme.success) {
                        showCallConfirmation = true
                    }

                    Menu {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Share with Client")
                                    Text("Send via email or WhatsApp")
                                        .font(.caption)
                                }
                            } icon: {
                                Image(systemName: "paperplane.fill")
                            }
                        }

                        Button {
                            showGeneratePdf = true
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text("Generate PDF")
                                    Text("Create downloadable report")
                                        .font(.caption)
                                }
                            } icon: {
                                Image(systemName: "doc.text.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }

            // Row 2: Action Buttons
            HStack(spacing: AppTheme.Spacing.small) {
                Button { showExecuteTrade = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12))
                        Text("Buy")
                            .font(AppTheme.Typography.accent(13))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                }

                Button { showCreateSip = true } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text("Start SIP")
                            .font(AppTheme.Typography.accent(13))
                    }
                    .foregroundColor(AppTheme.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.success.opacity(0.1))
                    .overlay(Capsule().stroke(AppTheme.success.opacity(0.3), lineWidth: 1))
                    .clipShape(Capsule())
                }
            }
        }
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.small)
    }

    // MARK: - Pending Actions Section

    private var pendingActionsSection: some View {
        let urgentCount = store.pendingActions.filter { $0.priority == .high }.count

        return VStack(spacing: 0) {
            // Header bar
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { pendingActionsExpanded.toggle() }
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.error)

                    Text("\(store.pendingActions.count) pending actions")
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(AppTheme.error)

                    if urgentCount > 0 {
                        Text("\(urgentCount) urgent")
                            .font(AppTheme.Typography.label(10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppTheme.error))
                    }

                    Spacer()

                    Image(systemName: pendingActionsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.error.opacity(0.7))
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.compact)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(AppTheme.error.opacity(colorScheme == .dark ? 0.15 : 0.08))
                )
            }
            .buttonStyle(.plain)

            // Expanded action items
            if pendingActionsExpanded {
                VStack(spacing: 0) {
                    ForEach(store.pendingActions) { action in
                        HStack(spacing: AppTheme.Spacing.compact) {
                            Image(systemName: action.typeIcon)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: action.priority.color))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: action.priority.color).opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                            Text(action.title)
                                .font(AppTheme.Typography.accent(13))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            if action.priority == .high {
                                Text("URGENT")
                                    .font(AppTheme.Typography.label(9))
                                    .foregroundColor(AppTheme.error)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.error.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.compact)

                        if action.id != store.pendingActions.last?.id {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.7))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.small)
    }

    private func contactIconButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func returnBadge(_ returns: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: returns >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9))
            Text(returns.formattedPercent)
                .font(AppTheme.Typography.label(11))
        }
        .fixedSize()
        .foregroundColor(AppTheme.returnColor(returns))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(AppTheme.returnColor(returns).opacity(0.1))
        .clipShape(Capsule())
    }

    private func statTile(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.numeric(15))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(AppTheme.Typography.label(11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.compact)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : color.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : color.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var tabSelector: some View {
        GlassTabSelector(
            tabs: ["Overview", "Holdings", "SIPs", "Transactions", "Family", "Goals", "Reports", "Notes", "Insurance"],
            selectedIndex: $selectedTab
        )
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Overview Tab

    @Environment(\.horizontalSizeClass) private var detailSizeClass

    private func overviewTab(_ client: FAClientDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // A. Portfolio Quick Stats
            let columnCount = AppTheme.adaptiveColumns(detailSizeClass)
            let columns = Array(repeating: GridItem(.flexible()), count: columnCount)
            let totalInvested = client.holdings.reduce(0) { $0 + $1.investedValue }
            let currentValue = client.holdings.reduce(0) { $0 + $1.currentValue }
            let monthlySip = client.sips.filter { $0.isActive }.reduce(0) { $0 + $1.amount }

            // A. Portfolio Summary (in tile)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                sectionTitle("Portfolio Summary", icon: "chart.bar.fill")

                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                    statTile(
                        icon: "banknote",
                        label: "Total Invested",
                        value: AppTheme.formatCurrencyWithSymbol(totalInvested),
                        color: AppTheme.info
                    )
                    statTile(
                        icon: "indianrupeesign.circle",
                        label: "Current Value",
                        value: AppTheme.formatCurrencyWithSymbol(currentValue),
                        color: AppTheme.primary
                    )
                    statTile(
                        icon: "arrow.triangle.2.circlepath",
                        label: "Monthly SIP",
                        value: AppTheme.formatCurrencyWithSymbol(monthlySip),
                        color: AppTheme.success
                    )
                    statTile(
                        icon: "gauge.with.dots.needle.33percent",
                        label: "Risk Profile",
                        value: client.riskProfile ?? "Moderate",
                        color: AppTheme.warning
                    )
                }
            }
            .glassCard()

            // B. Portfolio Value Chart (title + filters inside tile)
            PortfolioLineChart(
                data: store.portfolioHistory,
                selectedPeriod: $store.selectedPeriod,
                periods: store.periods,
                onPeriodChange: { period in
                    store.selectedPeriod = period
                    Task { await store.loadPortfolioHistory(clientId) }
                },
                title: "Portfolio Value"
            )
            .frame(height: 260)
            .glassCard()

            // C. Asset Allocation Chart
            AllocationDonutChart(
                data: store.allocation,
                totalValue: currentValue,
                title: "Asset Allocation"
            )
            .glassCard()

            // D. Recent Activity
            if !client.recentTransactions.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    HStack {
                        Text("Recent Activity")
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)

                        Spacer()

                        Button {
                            selectedTab = 3 // Transactions tab
                        } label: {
                            Text("View All")
                                .font(AppTheme.Typography.accent(12))
                                .foregroundColor(AppTheme.primary)
                        }
                    }

                    ForEach(Array(client.recentTransactions.prefix(3))) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.fundName)
                                    .font(AppTheme.Typography.accent(14))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text("\(tx.type) | \(tx.date)")
                                    .font(AppTheme.Typography.label(11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(tx.formattedAmount)
                                    .font(AppTheme.Typography.numeric(14))
                                    .foregroundColor(.primary)

                                statusBadge(tx.status)
                            }
                        }
                        .padding(AppTheme.Spacing.compact)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 0.5)
                        )
                    }
                }
                .glassCard()
            }

            // E. Client Information Card
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                Text("Client Information")
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)

                clientInfoRow(label: "Email", value: client.email, icon: "envelope")
                if let phone = client.phone, !phone.isEmpty {
                    clientInfoRow(label: "Phone", value: phone, icon: "phone")
                }
                if let pan = client.panNumber, !pan.isEmpty {
                    clientInfoRow(label: "PAN", value: pan, icon: "creditcard")
                }
                if let risk = client.riskProfile {
                    clientInfoRow(label: "Risk Profile", value: risk, icon: "gauge.with.dots.needle.33percent")
                }
                if let kyc = client.kycStatus {
                    clientInfoRow(label: "KYC Status", value: kyc, icon: "checkmark.shield")
                }
                if let nominee = client.nomineeName, !nominee.isEmpty {
                    let relation = client.nomineeRelation ?? ""
                    let display = relation.isEmpty ? nominee : "\(nominee) (\(relation))"
                    clientInfoRow(label: "Nominee", value: display, icon: "person.badge.shield.checkmark")
                } else {
                    clientInfoRow(label: "Nominee", value: "Not Added", icon: "person.badge.shield.checkmark")
                }
                if let address = client.address, !address.isEmpty {
                    clientInfoRow(label: "Address", value: address, icon: "mappin.and.ellipse")
                }
                if let memberSince = client.createdAt {
                    clientInfoRow(label: "Member Since", value: formatMemberSince(memberSince), icon: "calendar")
                }
            }
            .glassCard()
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.primary)

            Text(title)
                .font(AppTheme.Typography.accent(14))
                .foregroundColor(.primary)

            Spacer()
        }
    }

    private func clientInfoRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.primary)
                .frame(width: 24)

            Text(label)
                .font(AppTheme.Typography.label(12))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(AppTheme.Typography.body(13))
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func clientShareSummary(_ client: FAClientDetail) -> String {
        let activeSips = client.sips.filter { $0.isActive }
        let monthlySip = activeSips.reduce(0) { $0 + $1.amount }
        return """
        Portfolio Summary - \(client.name)

        AUM: \(AppTheme.formatCurrencyWithSymbol(client.aum))
        Returns: \(client.returns.formattedPercent)
        Holdings: \(client.holdings.count)
        Active SIPs: \(activeSips.count) (\(AppTheme.formatCurrencyWithSymbol(monthlySip))/month)

        Generated by Sparrow Invest FA
        """
    }

    private func formatMemberSince(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime, .withTimeZone]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM yyyy"
            return displayFormatter.string(from: date)
        }
        // Try simpler format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = simpleFormatter.date(from: String(dateString.prefix(19))) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM yyyy"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    // MARK: - Holdings Tab

    private func holdingsTab(_ client: FAClientDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Summary Card
            let totalCurrentValue = client.holdings.reduce(0) { $0 + $1.currentValue }
            let totalInvestedValue = client.holdings.reduce(0) { $0 + $1.investedValue }
            let totalGain = totalCurrentValue - totalInvestedValue
            let returnsPercent = totalInvestedValue > 0 ? ((totalCurrentValue - totalInvestedValue) / totalInvestedValue) * 100 : 0

            let holdingsColumnCount = AppTheme.adaptiveColumns(detailSizeClass)
            let columns = Array(repeating: GridItem(.flexible()), count: holdingsColumnCount)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                sectionTitle("Holdings Summary", icon: "chart.bar.fill")
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                    statTile(
                        icon: "indianrupeesign.circle",
                        label: "Current Value",
                        value: AppTheme.formatCurrencyWithSymbol(totalCurrentValue),
                        color: AppTheme.primary
                    )
                    statTile(
                        icon: "banknote",
                        label: "Total Invested",
                        value: AppTheme.formatCurrencyWithSymbol(totalInvestedValue),
                        color: AppTheme.info
                    )
                    statTile(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Total Gain",
                        value: AppTheme.formatCurrencyWithSymbol(totalGain),
                        color: AppTheme.returnColor(totalGain)
                    )
                    statTile(
                        icon: "percent",
                        label: "Returns",
                        value: returnsPercent.formattedPercent,
                        color: AppTheme.returnColor(returnsPercent)
                    )
                }
            }
            .glassCard()

            HoldingsFilterBar(
                selectedCategory: $holdingsCategory,
                sortBy: $holdingsSortBy,
                sortAscending: $holdingsSortAscending
            )

            ForEach(filteredHoldings(client.holdings)) { holding in
                NavigationLink {
                    if let code = holding.schemeCode {
                        FundDetailView(schemeCode: code)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.fundName)
                                .font(AppTheme.Typography.accent(14))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if let cat = holding.fundCategory {
                                Text(cat)
                                    .font(AppTheme.Typography.label(11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(holding.currentValue.formattedCurrency)
                                .font(AppTheme.Typography.numeric(14))
                                .foregroundColor(.primary)

                            Text(holding.returnsPercentage.formattedPercent)
                                .font(AppTheme.Typography.accent(12))
                                .foregroundColor(AppTheme.returnColor(holding.returnsPercentage))
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func filteredHoldings(_ holdings: [Holding]) -> [Holding] {
        var result = holdings

        if holdingsCategory != "All" {
            result = result.filter { ($0.fundCategory ?? $0.category ?? "").localizedCaseInsensitiveContains(holdingsCategory) }
        }

        switch holdingsSortBy {
        case "Returns":
            result = result.sorted { holdingsSortAscending ? $0.returnsPercentage < $1.returnsPercentage : $0.returnsPercentage > $1.returnsPercentage }
        case "Invested":
            result = result.sorted { holdingsSortAscending ? $0.investedValue < $1.investedValue : $0.investedValue > $1.investedValue }
        default: // Value
            result = result.sorted { holdingsSortAscending ? $0.currentValue < $1.currentValue : $0.currentValue > $1.currentValue }
        }

        return result
    }

    private func sipsTab(_ client: FAClientDetail) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Summary Card
            let activeSips = client.sips.filter { $0.isActive }
            let pausedSips = client.sips.filter { $0.isPaused }
            let monthlyAmount = activeSips.reduce(0) { $0 + $1.amount }
            let totalSipInvested = client.sips.reduce(0) { $0 + $1.totalInvested }

            let sipColumnCount = AppTheme.adaptiveColumns(detailSizeClass)
            let columns = Array(repeating: GridItem(.flexible()), count: sipColumnCount)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                sectionTitle("SIP Summary", icon: "arrow.triangle.2.circlepath")
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                    statTile(
                        icon: "checkmark.circle",
                        label: "Active SIPs",
                        value: "\(activeSips.count)",
                        color: AppTheme.success
                    )
                    statTile(
                        icon: "indianrupeesign.circle",
                        label: "Monthly Amount",
                        value: AppTheme.formatCurrencyWithSymbol(monthlyAmount),
                        color: AppTheme.primary
                    )
                    statTile(
                        icon: "banknote",
                        label: "Total Invested",
                        value: AppTheme.formatCurrencyWithSymbol(totalSipInvested),
                        color: AppTheme.info
                    )
                    statTile(
                        icon: "pause.circle",
                        label: "Paused",
                        value: "\(pausedSips.count)",
                        color: AppTheme.warning
                    )
                }
            }
            .glassCard()

            ForEach(client.sips) { sip in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sip.fundName)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(sip.frequency) | Day \(sip.sipDate)")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(sip.formattedAmount)
                            .font(AppTheme.Typography.numeric(14))
                            .foregroundColor(.primary)

                        statusBadge(sip.status)
                    }
                }
                .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func transactionsTab(_ client: FAClientDetail) -> some View {
        let filtered = filteredTransactions(client.recentTransactions)
        let totalFilteredValue = filtered.reduce(0) { $0 + $1.amount }

        return VStack(spacing: AppTheme.Spacing.small) {
            // Row 1: Type filter chips
            GlassSegmentedControl(items: ["All", "Buy", "Sell", "SIP"], selection: $txTypeFilter)

            // Row 2: Status dropdown + Sort dropdown + direction toggle
            HStack(spacing: AppTheme.Spacing.small) {
                // Status dropdown
                Menu {
                    ForEach(["All", "Pending", "Executed"], id: \.self) { option in
                        Button {
                            txStatusFilter = option
                        } label: {
                            HStack {
                                Text(option)
                                if txStatusFilter == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    filterDropdownLabel(icon: "line.3.horizontal.decrease", text: "Status: \(txStatusFilter)")
                }

                // Sort dropdown
                Menu {
                    ForEach(["Date", "Amount"], id: \.self) { option in
                        Button {
                            txSortBy = option
                        } label: {
                            HStack {
                                Text(option)
                                if txSortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    filterDropdownLabel(icon: "arrow.up.arrow.down", text: "Sort: \(txSortBy)")
                }

                // Sort direction toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        txSortAscending.toggle()
                    }
                } label: {
                    Image(systemName: txSortAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                }

                Spacer()
            }

            // Summary stats row
            HStack(spacing: AppTheme.Spacing.compact) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                    Text("\(filtered.count) transactions")
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "indianrupeesign.circle")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                    Text(AppTheme.formatCurrencyWithSymbol(totalFilteredValue))
                        .font(AppTheme.Typography.numeric(13))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, AppTheme.Spacing.compact)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : AppTheme.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : AppTheme.primary.opacity(0.08), lineWidth: 0.5)
            )

            // Transaction list
            ForEach(filtered) { tx in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tx.fundName)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(tx.type) | \(tx.date)")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(tx.formattedAmount)
                            .font(AppTheme.Typography.numeric(14))
                            .foregroundColor(.primary)

                        statusBadge(tx.status)
                    }
                }
                .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
            }

            if filtered.isEmpty {
                VStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No transactions match filters")
                        .font(AppTheme.Typography.body(14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xxxLarge)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func filteredTransactions(_ transactions: [FATransaction]) -> [FATransaction] {
        var result = transactions

        if txTypeFilter != "All" {
            result = result.filter { $0.type.localizedCaseInsensitiveCompare(txTypeFilter) == .orderedSame }
        }

        if txStatusFilter != "All" {
            switch txStatusFilter {
            case "Pending":
                result = result.filter { $0.status.localizedCaseInsensitiveContains("Pending") || $0.status.localizedCaseInsensitiveContains("Processing") }
            case "Executed":
                result = result.filter { $0.status.localizedCaseInsensitiveContains("Completed") || $0.status.localizedCaseInsensitiveContains("Executed") }
            default:
                break
            }
        }

        switch txSortBy {
        case "Amount":
            result = result.sorted { txSortAscending ? $0.amount < $1.amount : $0.amount > $1.amount }
        default: // Date
            result = result.sorted { txSortAscending ? $0.date < $1.date : $0.date > $1.date }
        }

        return result
    }

    private func familyTab(_ client: FAClientDetail) -> some View {
        let activeMembers = client.familyMembers.filter { $0.aum > 0 }
        let totalFamilyAum = activeMembers.reduce(0) { $0 + $1.aum }
        let avgReturns = activeMembers.isEmpty ? 0 : activeMembers.reduce(0) { $0 + $1.returns } / Double(activeMembers.count)
        let totalHoldings = activeMembers.reduce(0) { $0 + $1.holdingsCount }
        let totalFamilySips = activeMembers.reduce(0) { $0 + $1.sipCount }

        return VStack(spacing: AppTheme.Spacing.small) {
            // Summary Card
            let familyColumnCount = AppTheme.adaptiveColumns(detailSizeClass)
            let columns = Array(repeating: GridItem(.flexible()), count: familyColumnCount)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                sectionTitle("Family Summary", icon: "person.2.fill")
                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                    statTile(
                        icon: "indianrupeesign.circle",
                        label: "Total AUM",
                        value: AppTheme.formatCurrencyWithSymbol(totalFamilyAum),
                        color: AppTheme.primary
                    )
                    statTile(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Avg Returns",
                        value: avgReturns.formattedPercent,
                        color: AppTheme.returnColor(avgReturns)
                    )
                    statTile(
                        icon: "chart.pie",
                        label: "Total Holdings",
                        value: "\(totalHoldings)",
                        color: AppTheme.info
                    )
                    statTile(
                        icon: "arrow.triangle.2.circlepath",
                        label: "Total SIPs",
                        value: "\(totalFamilySips)",
                        color: AppTheme.success
                    )
                }
            }
            .glassCard()

            ForEach(activeMembers) { member in
                HStack(spacing: AppTheme.Spacing.compact) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Text(member.initials)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(AppTheme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)

                        Text(member.relationshipLabel)
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(AppTheme.formatCurrencyWithSymbol(member.aum))
                            .font(AppTheme.Typography.numeric(14))
                            .foregroundColor(.primary)

                        Text("\(member.holdingsCount) holdings")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(.secondary)
                    }
                }
                .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(AppTheme.Typography.label(10))
            .foregroundColor(AppTheme.statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }

    private func filterDropdownLabel(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.micro) {
            Image(systemName: icon)
                .font(.system(size: 11))

            Text(text)
                .font(AppTheme.Typography.label(12))

            Image(systemName: "chevron.down")
                .font(.system(size: 9))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, AppTheme.Spacing.compact)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Add Client View

struct AddClientView: View {
    @ObservedObject var store: ClientStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var pan = ""
    @State private var riskProfile = "Moderate"
    @State private var address = ""
    @State private var isSaving = false

    // Validation errors
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var phoneError: String?
    @State private var panError: String?

    private let riskProfiles = ["Conservative", "Moderate", "Aggressive"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Section 1: Basic Information
                    sectionCard(title: "Basic Information", icon: "person.text.rectangle") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            validatedField(
                                label: "FULL NAME",
                                text: $name,
                                icon: "person",
                                placeholder: "Enter full name",
                                error: nameError,
                                isRequired: true
                            ) {
                                nameError = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Name is required" : nil
                            }

                            validatedField(
                                label: "EMAIL ADDRESS",
                                text: $email,
                                icon: "envelope",
                                placeholder: "Enter email address",
                                keyboard: .emailAddress,
                                autocapitalization: .never,
                                error: emailError,
                                isRequired: true
                            ) {
                                validateEmail()
                            }

                            validatedField(
                                label: "PHONE NUMBER",
                                text: $phone,
                                icon: "phone",
                                placeholder: "10-digit mobile number",
                                keyboard: .phonePad,
                                error: phoneError
                            ) {
                                validatePhone()
                            }
                        }
                    }

                    // Section 2: KYC Information
                    sectionCard(title: "KYC Information", icon: "doc.text") {
                        validatedField(
                            label: "PAN NUMBER",
                            text: $pan,
                            icon: "creditcard",
                            placeholder: "e.g. ABCDE1234F",
                            autocapitalization: .characters,
                            error: panError
                        ) {
                            validatePan()
                        }
                    }

                    // Section 3: Risk Profile
                    sectionCard(title: "Risk Profile", icon: "gauge.with.dots.needle.33percent") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            Text("RISK TOLERANCE")
                                .font(AppTheme.Typography.label(11))
                                .foregroundColor(AppTheme.primary)

                            HStack(spacing: 0) {
                                ForEach(riskProfiles, id: \.self) { profile in
                                    let isSelected = riskProfile == profile
                                    Button {
                                        riskProfile = profile
                                    } label: {
                                        Text(profile)
                                            .font(AppTheme.Typography.accent(12))
                                            .foregroundColor(isSelected ? .white : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                isSelected
                                                    ? AnyShapeStyle(riskGradient(profile))
                                                    : AnyShapeStyle(Color.clear)
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(3)
                            .background(
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                            )
                        }
                    }

                    // Section 4: Address
                    sectionCard(title: "Address", icon: "mappin.and.ellipse") {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            Text("ADDRESS (OPTIONAL)")
                                .font(AppTheme.Typography.label(11))
                                .foregroundColor(AppTheme.primary)

                            TextField("Enter full address...", text: $address, axis: .vertical)
                                .font(AppTheme.Typography.body(15))
                                .lineLimit(3...6)
                                .padding(AppTheme.Spacing.compact)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }

                    // Submit Button
                    Button {
                        submitForm()
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: AppTheme.Spacing.small) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16))
                                    Text("Add Client")
                                        .font(AppTheme.Typography.accent(15))
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid && !isSaving ? AppTheme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.horizontal, AppTheme.Spacing.medium)

                    Spacer().frame(height: AppTheme.Spacing.large)
                }
                .padding(.top, AppTheme.Spacing.compact)
            }
            .background(AppTheme.groupedBackground.ignoresSafeArea())
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else { return false }
        guard nameError == nil, emailError == nil, phoneError == nil, panError == nil else { return false }
        return true
    }

    private func validateEmail() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            emailError = "Email is required"
        } else {
            let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
            emailError = trimmed.range(of: pattern, options: .regularExpression) != nil ? nil : "Enter a valid email address"
        }
    }

    private func validatePhone() {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            phoneError = nil // Optional field
            return
        }
        let pattern = #"^[6-9]\d{9}$"#
        phoneError = trimmed.range(of: pattern, options: .regularExpression) != nil ? nil : "Enter a valid 10-digit Indian mobile number"
    }

    private func validatePan() {
        let trimmed = pan.trimmingCharacters(in: .whitespaces).uppercased()
        pan = trimmed
        guard !trimmed.isEmpty else {
            panError = nil // Optional field
            return
        }
        let pattern = #"^[A-Z]{5}[0-9]{4}[A-Z]$"#
        panError = trimmed.range(of: pattern, options: .regularExpression) != nil ? nil : "PAN must be in format ABCDE1234F"
    }

    private func submitForm() {
        // Run all validations
        nameError = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Name is required" : nil
        validateEmail()
        validatePhone()
        validatePan()

        guard isFormValid else { return }

        Task {
            isSaving = true
            let request = CreateClientRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                panNumber: pan.isEmpty ? nil : pan.trimmingCharacters(in: .whitespaces).uppercased(),
                riskProfile: riskProfile,
                address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespaces)
            )
            if await store.createClient(request) {
                dismiss()
            }
            isSaving = false
        }
    }

    // MARK: - Components

    private func sectionCard(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }

                Text(title)
                    .font(AppTheme.Typography.accent(14))
                    .foregroundColor(.primary)
            }

            content()
        }
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func validatedField(
        label: String,
        text: Binding<String>,
        icon: String,
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .words,
        error: String? = nil,
        isRequired: Bool = false,
        onValidate: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            HStack(spacing: 4) {
                Text(label)
                    .font(AppTheme.Typography.label(11))
                    .foregroundColor(AppTheme.primary)
                if isRequired {
                    Text("*")
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(AppTheme.error)
                }
            }

            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(error != nil ? AppTheme.error : .secondary)

                TextField(placeholder, text: text)
                    .font(AppTheme.Typography.body(15))
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalization)
                    .onChange(of: text.wrappedValue) { _, _ in
                        onValidate()
                    }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(error != nil ? AppTheme.error.opacity(0.5) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5)), lineWidth: 1)
            )

            if let error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(AppTheme.Typography.label(11))
                }
                .foregroundColor(AppTheme.error)
            }
        }
    }

    private func riskGradient(_ profile: String) -> LinearGradient {
        switch profile {
        case "Conservative":
            return LinearGradient(colors: [AppTheme.success, AppTheme.success.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        case "Aggressive":
            return LinearGradient(colors: [AppTheme.error, AppTheme.error.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        default:
            return AppTheme.primaryGradient
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

