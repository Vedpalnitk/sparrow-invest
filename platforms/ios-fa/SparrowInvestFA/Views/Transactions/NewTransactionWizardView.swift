import SwiftUI

struct NewTransactionWizardView: View {
    @StateObject private var store = NewTransactionWizardStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step Indicator
                stepIndicator

                // Error Banner
                if let error = store.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                        Text(error)
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    }
                    .foregroundColor(AppTheme.error)
                    .padding(AppTheme.Spacing.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.top, AppTheme.Spacing.small)
                }

                // Step Content
                TabView(selection: $store.currentStep) {
                    selectClientStep.tag(0)
                    selectFundStep.tag(1)
                    enterDetailsStep.tag(2)
                    selectPlatformStep.tag(3)
                    reviewStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: store.currentStep)

                // Bottom Navigation
                bottomBar
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Success", isPresented: $store.showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Transaction created successfully")
            }
        }
    }

    // MARK: - Step Indicator

    private let stepCount = 5

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<stepCount, id: \.self) { step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(step <= store.currentStep ? AppTheme.primary : colorScheme == .dark ? Color.white.opacity(0.1) : Color(UIColor.tertiarySystemFill))
                            .frame(width: 26, height: 26)

                        if step < store.currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step + 1)")
                                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                .foregroundColor(step == store.currentStep ? .white : .secondary)
                        }
                    }

                    Text(stepTitle(step))
                        .font(AppTheme.Typography.label(iPad ? 10 : 8))
                        .foregroundColor(step <= store.currentStep ? AppTheme.primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if step < stepCount - 1 {
                    Rectangle()
                        .fill(step < store.currentStep ? AppTheme.primary : colorScheme == .dark ? Color.white.opacity(0.1) : Color(UIColor.tertiarySystemFill))
                        .frame(height: 2)
                        .frame(maxWidth: 20)
                        .padding(.bottom, 14)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
    }

    private func stepTitle(_ step: Int) -> String {
        switch step {
        case 0: return "Client"
        case 1: return "Fund"
        case 2: return "Details"
        case 3: return "Platform"
        case 4: return "Review"
        default: return ""
        }
    }

    // MARK: - Step 1: Select Client

    private var selectClientStep: some View {
        VStack(spacing: 0) {
            stepHeader(icon: "person.2.fill", iconColor: AppTheme.primary, title: "Select Client", subtitle: "Choose a client for this transaction")
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.compact)

            // Search
            searchField(placeholder: "Search by name or email...", text: $store.clientSearchQuery)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.small)

            if store.isLoadingClients {
                Spacer()
                ProgressView("Loading clients...")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(store.filteredClients) { client in
                            clientSelectCard(client)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.xxxLarge)
                }
            }
        }
    }

    private func clientSelectCard(_ client: FAClient) -> some View {
        let isSelected = store.selectedClient?.id == client.id

        return Button {
            store.selectedClient = client
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.primary : AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text(client.initials)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(isSelected ? .white : AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.primary)

                    Text(client.email)
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(client.formattedAum)
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(.primary)

                    if let risk = client.riskProfile {
                        Text(risk)
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(.secondary)
                    }
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.primary)
                }
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(AppTheme.primary, lineWidth: 2)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Select Fund

    private var selectFundStep: some View {
        VStack(spacing: 0) {
            stepHeader(icon: "chart.line.uptrend.xyaxis", iconColor: AppTheme.secondary, title: "Select Fund", subtitle: "Search and select a mutual fund")
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.compact)

            if let fund = store.selectedFund {
                // Selected fund card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fund.schemeName)
                            .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                            .foregroundColor(.primary)

                        HStack(spacing: AppTheme.Spacing.small) {
                            if let nav = fund.nav {
                                Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                    .foregroundColor(.secondary)
                            }
                            if let cat = fund.schemeCategory {
                                Text(cat)
                                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.primary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    Button {
                        store.selectedFund = nil
                        store.fundSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)

                Spacer()
            } else {
                // Search field
                searchField(placeholder: "Search funds (min. 3 characters)...", text: $store.fundSearchQuery)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .onChange(of: store.fundSearchQuery) { _, newValue in
                        Task { await store.searchFunds(query: newValue) }
                    }

                if store.isFundSearchLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppTheme.Spacing.large)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            ForEach(store.fundSearchResults) { fund in
                                fundSelectCard(fund)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.xxxLarge)
                    }
                }
            }
        }
    }

    private func fundSelectCard(_ fund: FAFund) -> some View {
        Button {
            store.selectedFund = fund
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.secondary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fund.schemeName)
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: AppTheme.Spacing.small) {
                        if let nav = fund.nav {
                            Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                .foregroundColor(.secondary)
                        }
                        if let ret = fund.returns1y {
                            let retColor = ret >= 0 ? AppTheme.success : AppTheme.error
                            Text(String(format: "%+.1f%% 1Y", ret))
                                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                .foregroundColor(retColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(retColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        if let cat = fund.schemeCategory {
                            Text(cat)
                                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                .foregroundColor(AppTheme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary.opacity(0.08))
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Enter Details

    private var enterDetailsStep: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                stepHeader(icon: "doc.text.fill", iconColor: AppTheme.warning, title: "Transaction Details", subtitle: "Configure the trade parameters")
                    .padding(.horizontal, AppTheme.Spacing.medium)

                // Transaction Type
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("TYPE")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(NewTransactionWizardStore.transactionTypes, id: \.self) { type in
                            let isSelected = store.transactionType == type
                            Button {
                                store.transactionType = type
                            } label: {
                                Text(type)
                                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        isSelected
                                            ? AnyShapeStyle(AppTheme.primaryGradient)
                                            : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Amount
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("AMOUNT")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    HStack(spacing: AppTheme.Spacing.small) {
                        Text("\u{20B9}")
                            .font(AppTheme.Typography.numeric(iPad ? 22 : 18))
                            .foregroundColor(.secondary)

                        TextField("Enter amount", text: $store.amount)
                            .font(AppTheme.Typography.numeric(iPad ? 22 : 18))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .frame(height: 48)
                    .background(inputBackground)
                    .overlay(inputBorder)
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Folio Number
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("FOLIO")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    HStack(spacing: 0) {
                        ForEach(["New Folio", "Existing"], id: \.self) { option in
                            let isSelected = (option == "New Folio") == store.isNewFolio
                            Button {
                                store.isNewFolio = (option == "New Folio")
                            } label: {
                                Text(option)
                                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                    .foregroundColor(isSelected ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        isSelected
                                            ? AnyShapeStyle(AppTheme.primaryGradient)
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

                    if !store.isNewFolio {
                        TextField("Enter folio number", text: $store.folioNumber)
                            .font(AppTheme.Typography.body(iPad ? 17 : 15))
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .frame(height: 44)
                            .background(inputBackground)
                            .overlay(inputBorder)
                    }
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Payment Mode
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("PAYMENT MODE")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(NewTransactionWizardStore.paymentModes, id: \.self) { mode in
                            let isSelected = store.paymentMode == mode
                            Button {
                                store.paymentMode = mode
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: paymentModeIcon(mode))
                                        .font(.system(size: 13))
                                    Text(mode)
                                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                }
                                .foregroundColor(isSelected ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isSelected
                                        ? AnyShapeStyle(AppTheme.primaryGradient)
                                        : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
                                )
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Notes
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("NOTES (OPTIONAL)")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    TextField("Any additional notes...", text: $store.notes, axis: .vertical)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .lineLimit(3...6)
                        .padding(AppTheme.Spacing.compact)
                        .background(inputBackground)
                        .overlay(inputBorder)
                }
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.top, AppTheme.Spacing.compact)
        }
    }

    private func paymentModeIcon(_ mode: String) -> String {
        switch mode {
        case "Net Banking": return "building.columns"
        case "UPI": return "indianrupeesign.circle"
        case "NACH": return "arrow.triangle.2.circlepath"
        case "Cheque": return "doc.text"
        default: return "creditcard"
        }
    }

    // MARK: - Step 4: Select Platform

    private var selectPlatformStep: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                stepHeader(icon: "building.2.fill", iconColor: Color(hex: "6366F1"), title: "Select Platform", subtitle: "Choose a transaction platform")
                    .padding(.horizontal, AppTheme.Spacing.medium)

                // Platform Cards
                VStack(spacing: AppTheme.Spacing.compact) {
                    platformCard(
                        name: "BSE Star MF",
                        description: "BSE's mutual fund transaction platform for distributors",
                        icon: "star.circle.fill",
                        gradient: [Color(hex: "3B82F6"), Color(hex: "1D4ED8")],
                        isSelected: store.selectedPlatform == "BSE"
                    ) {
                        store.selectedPlatform = "BSE"
                    }

                    platformCard(
                        name: "MF Utility (MFU)",
                        description: "Industry-wide transaction portal with TransactEezz",
                        icon: "globe.americas.fill",
                        gradient: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                        isSelected: store.selectedPlatform == "MFU"
                    ) {
                        store.selectedPlatform = "MFU"
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)

                // Open Platform + Order ID
                if let platform = store.selectedPlatform {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                        // Open Platform Button
                        Button {
                            store.platformVisited = true
                            let urlString = platform == "BSE"
                                ? "https://www.bsestarmf.in"
                                : "https://www.mfuonline.com"
                            if let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 16))
                                Text("Open \(platform == "BSE" ? "BSE Star MF" : "MF Utility")")
                                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Capsule())
                        }

                        // Order ID
                        if store.platformVisited || store.skipOrderId {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                Text("ORDER ID")
                                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                    .foregroundColor(AppTheme.primary)

                                if !store.skipOrderId {
                                    TextField("Enter order ID from platform", text: $store.orderId)
                                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                        .padding(.horizontal, AppTheme.Spacing.medium)
                                        .frame(height: 44)
                                        .background(inputBackground)
                                        .overlay(inputBorder)
                                }

                                // Skip toggle
                                Button {
                                    store.skipOrderId.toggle()
                                    if store.skipOrderId { store.orderId = "" }
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.small) {
                                        Image(systemName: store.skipOrderId ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 18))
                                            .foregroundColor(store.skipOrderId ? AppTheme.primary : .secondary)

                                        Text("Skip \u{2014} Record without Order ID")
                                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .glassCard()
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.top, AppTheme.Spacing.compact)
        }
    }

    private func platformCard(name: String, description: String, icon: String, gradient: [Color], isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    Text(description)
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(gradient.first ?? AppTheme.primary)
                }
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(gradient.first ?? AppTheme.primary, lineWidth: 2)
                    : nil
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 5: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                stepHeader(icon: "doc.text.magnifyingglass", iconColor: AppTheme.success, title: "Review Transaction", subtitle: "Please verify all details before submitting")
                    .padding(.horizontal, AppTheme.Spacing.medium)

                // Client
                reviewSection(icon: "person.fill", iconColor: AppTheme.primary, label: "CLIENT") {
                    if let client = store.selectedClient {
                        HStack(spacing: AppTheme.Spacing.compact) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Text(client.initials)
                                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                    .foregroundColor(AppTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.name)
                                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                    .foregroundColor(.primary)
                                Text(client.email)
                                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Fund
                reviewSection(icon: "chart.line.uptrend.xyaxis", iconColor: AppTheme.secondary, label: "FUND") {
                    if let fund = store.selectedFund {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fund.schemeName)
                                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                                .foregroundColor(.primary)

                            HStack(spacing: AppTheme.Spacing.small) {
                                if let nav = fund.nav {
                                    Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                        .foregroundColor(.secondary)
                                }
                                if let cat = fund.schemeCategory {
                                    Text(cat)
                                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                        .foregroundColor(AppTheme.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                // Trade Details
                reviewSection(icon: "doc.text.fill", iconColor: AppTheme.warning, label: "TRADE DETAILS") {
                    VStack(spacing: 0) {
                        reviewRow("Type", value: store.transactionType)
                        reviewRow("Amount", value: "\u{20B9}\(store.amount)")
                        reviewRow("Folio", value: store.isNewFolio ? "New Folio" : store.folioNumber)
                        reviewRow("Payment", value: store.paymentMode)
                        if !store.notes.isEmpty {
                            reviewRow("Notes", value: store.notes)
                        }
                    }
                }

                // Platform
                reviewSection(icon: "building.2.fill", iconColor: Color(hex: "6366F1"), label: "PLATFORM") {
                    VStack(spacing: 0) {
                        reviewRow("Platform", value: store.selectedPlatform == "BSE" ? "BSE Star MF" : "MF Utility")
                        if !store.orderId.isEmpty {
                            reviewRow("Order ID", value: store.orderId)
                        } else {
                            reviewRow("Order ID", value: "Not provided")
                        }
                    }
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.top, AppTheme.Spacing.compact)
        }
    }

    // MARK: - Shared Components

    private func searchField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField(placeholder, text: text)
                .font(AppTheme.Typography.body(iPad ? 17 : 15))
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .frame(height: 44)
        .background(inputBackground)
        .overlay(inputBorder)
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
    }

    private func reviewSection(icon: String, iconColor: Color, label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                }

                Text(label)
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(iconColor)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func reviewRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }

    private func stepHeader(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline(iPad ? 19 : 16))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: AppTheme.Spacing.compact) {
                // Back / Cancel
                Button {
                    if store.currentStep > 0 {
                        withAnimation { store.currentStep -= 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(store.currentStep == 0 ? "Cancel" : "Back")
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill)
                        )
                        .clipShape(Capsule())
                }

                // Next / Submit
                if store.currentStep == stepCount - 1 {
                    Button {
                        Task { await store.submitTransaction() }
                    } label: {
                        Group {
                            if store.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Submit Transaction")
                                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(store.canGoNext && !store.isSubmitting ? AppTheme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                    }
                    .disabled(!store.canGoNext || store.isSubmitting)
                } else {
                    Button {
                        withAnimation { store.currentStep += 1 }
                    } label: {
                        Text("Next")
                            .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(store.canGoNext ? AppTheme.primaryGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .disabled(!store.canGoNext)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.compact)
            .background(AppTheme.background)
        }
    }
}

// MARK: - New Transaction Wizard Store

@MainActor
class NewTransactionWizardStore: ObservableObject {
    static let transactionTypes = ["Buy", "Sell", "SIP", "SWP", "Switch", "STP"]
    static let paymentModes = ["Net Banking", "UPI", "NACH", "Cheque"]

    @Published var currentStep = 0

    // Step 1: Client
    @Published var clients: [FAClient] = []
    @Published var clientSearchQuery = ""
    @Published var selectedClient: FAClient?
    @Published var isLoadingClients = false

    // Step 2: Fund
    @Published var fundSearchQuery = ""
    @Published var fundSearchResults: [FAFund] = []
    @Published var selectedFund: FAFund?
    @Published var isFundSearchLoading = false

    // Step 3: Details
    @Published var transactionType = "Buy"
    @Published var amount = ""
    @Published var isNewFolio = true
    @Published var folioNumber = ""
    @Published var paymentMode = "Net Banking"
    @Published var notes = ""

    // Step 4: Platform
    @Published var selectedPlatform: String?
    @Published var orderId = ""
    @Published var skipOrderId = false
    @Published var platformVisited = false

    // General
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var showSuccess = false

    private var searchTask: Task<Void, Never>?

    init() {
        Task { await loadClients() }
    }

    var filteredClients: [FAClient] {
        guard !clientSearchQuery.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(clientSearchQuery) ||
            $0.email.localizedCaseInsensitiveContains(clientSearchQuery)
        }
    }

    var canGoNext: Bool {
        switch currentStep {
        case 0: return selectedClient != nil
        case 1: return selectedFund != nil
        case 2:
            let amountVal = Double(amount) ?? 0
            return amountVal > 0
        case 3:
            return selectedPlatform != nil && (!orderId.isEmpty || skipOrderId)
        case 4:
            return selectedClient != nil && selectedFund != nil && !amount.isEmpty && !isSubmitting
        default: return false
        }
    }

    func loadClients() async {
        isLoadingClients = true
        do {
            let response: PaginatedResponse<FAClient> = try await APIService.shared.get("/clients?limit=100")
            clients = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingClients = false
    }

    func searchFunds(query: String) async {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            fundSearchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }

            isFundSearchLoading = true
            do {
                let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
                fundSearchResults = try await APIService.shared.get("/funds/live/search?q=\(encoded)")
            } catch {
                if !Task.isCancelled {
                    fundSearchResults = []
                }
            }
            if !Task.isCancelled {
                isFundSearchLoading = false
            }
        }
    }

    func submitTransaction() async {
        guard let client = selectedClient, let fund = selectedFund else { return }
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Enter a valid amount"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            // Build remarks with platform + order ID + notes
            var remarkParts: [String] = []
            if let platform = selectedPlatform {
                remarkParts.append("Platform: \(platform == "BSE" ? "BSE Star MF" : "MF Utility")")
            }
            if !orderId.isEmpty {
                remarkParts.append("Order ID: \(orderId)")
            }
            if !notes.isEmpty {
                remarkParts.append(notes)
            }
            let remarks = remarkParts.isEmpty ? nil : remarkParts.joined(separator: " | ")

            let request = CreateTransactionRequest(
                clientId: client.id,
                fundName: fund.schemeName,
                fundSchemeCode: "\(fund.schemeCode)",
                fundCategory: fund.schemeCategory ?? "",
                type: transactionType,
                amount: amountValue,
                nav: fund.nav ?? 0,
                folioNumber: isNewFolio ? "NEW" : folioNumber,
                date: nil,
                paymentMode: paymentMode,
                remarks: remarks
            )

            let isSellType = transactionType == "Sell" || transactionType == "SWP"
            let endpoint = isSellType ? "/transactions/redemption" : "/transactions/lumpsum"
            let _: FATransaction = try await APIService.shared.post(endpoint, body: request)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
