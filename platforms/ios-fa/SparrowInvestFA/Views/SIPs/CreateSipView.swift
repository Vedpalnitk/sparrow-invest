import SwiftUI

struct CreateSipView: View {
    @ObservedObject var store: SipStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedClientId = ""
    @State private var selectedFund: FAFund?
    @State private var fundSearchQuery = ""
    @State private var amount = ""
    @State private var frequency = "MONTHLY"
    @State private var sipDate = 1
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage: String?

    @State private var searchDebounceTask: Task<Void, Never>?

    let frequencies = [("WEEKLY", "Weekly"), ("MONTHLY", "Monthly"), ("QUARTERLY", "Quarterly")]
    let sipDates = [1, 5, 10, 15, 20, 25]

    var isFormValid: Bool {
        !selectedClientId.isEmpty && selectedFund != nil && (Double(amount) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Client Section
                    formSection(
                        title: "Client",
                        subtitle: "Select a client",
                        icon: "person.fill"
                    ) {
                        clientSelector
                    }

                    // Fund Section
                    formSection(
                        title: "Fund",
                        subtitle: "Search and select a fund",
                        icon: "building.columns.fill"
                    ) {
                        fundSelector
                    }

                    // Amount Section
                    formSection(
                        title: "SIP Amount",
                        subtitle: "Investment amount per installment",
                        icon: "indianrupeesign"
                    ) {
                        amountInput
                    }

                    // Frequency Section
                    formSection(
                        title: "Frequency",
                        subtitle: "How often to invest",
                        icon: "repeat"
                    ) {
                        frequencySelector
                    }

                    // SIP Date Section
                    formSection(
                        title: "SIP Date",
                        subtitle: "Day of month for deduction",
                        icon: "calendar"
                    ) {
                        dateSelector
                    }

                    // Create Button
                    Button {
                        createSip()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.small) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSaving ? "Creating..." : "Create SIP")
                                .font(AppTheme.Typography.headline(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            isFormValid && !isSaving
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.gray.opacity(0.3))
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(!isFormValid || isSaving)

                    Spacer().frame(height: AppTheme.Spacing.large)
                }
                .padding(AppTheme.Spacing.medium)
            }
            .navigationTitle("Create SIP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .task {
                await store.loadClients()
            }
        }
    }

    // MARK: - Form Section

    private func formSection(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                }
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Client Selector

    private var clientSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if store.clients.isEmpty {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading clients...")
                        .font(AppTheme.Typography.caption(13))
                        .foregroundColor(.secondary)
                }
            } else {
                Menu {
                    ForEach(store.clients) { client in
                        Button {
                            selectedClientId = client.id
                        } label: {
                            HStack {
                                Text(client.name)
                                if selectedClientId == client.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let selected = store.clients.first(where: { $0.id == selectedClientId }) {
                            HStack(spacing: AppTheme.Spacing.small) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.primary.opacity(0.1))
                                        .frame(width: 32, height: 32)

                                    Text(selected.initials)
                                        .font(AppTheme.Typography.label(12))
                                        .foregroundColor(AppTheme.primary)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(selected.name)
                                        .font(AppTheme.Typography.accent(14))
                                        .foregroundColor(.primary)

                                    Text(selected.email)
                                        .font(AppTheme.Typography.label(11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Select a client")
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.compact)
                    .frame(height: 48)
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
        }
    }

    // MARK: - Fund Selector

    private var fundSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if let fund = selectedFund {
                // Selected fund display
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fund.schemeName)
                            .font(AppTheme.Typography.accent(14))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if let nav = fund.nav {
                            Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                .font(AppTheme.Typography.label(12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        selectedFund = nil
                        fundSearchQuery = ""
                        store.searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .listItemCard()
            } else {
                // Search input
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    TextField("Search fund name...", text: $fundSearchQuery)
                        .font(AppTheme.Typography.body(15))
                        .onChange(of: fundSearchQuery) { _, newValue in
                            Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                guard fundSearchQuery == newValue else { return }
                                await store.searchFunds(query: newValue)
                            }
                        }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                )

                // Search results
                if store.isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(AppTheme.Typography.caption(13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, AppTheme.Spacing.micro)
                } else if !store.searchResults.isEmpty {
                    VStack(spacing: AppTheme.Spacing.micro) {
                        ForEach(store.searchResults.prefix(5)) { fund in
                            Button {
                                selectedFund = fund
                                fundSearchQuery = fund.schemeName
                                store.searchResults = []
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fund.schemeName)
                                        .font(AppTheme.Typography.accent(13))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    HStack {
                                        if let nav = fund.nav {
                                            Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                                .font(AppTheme.Typography.label(11))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if let returns1y = fund.returns1y {
                                            Text(returns1y.formattedPercent)
                                                .font(AppTheme.Typography.label(11))
                                                .foregroundColor(AppTheme.returnColor(returns1y))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.returnColor(returns1y).opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listItemCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Amount Input

    private var amountInput: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            Text("AMOUNT (\u{20B9})")
                .font(AppTheme.Typography.label(11))
                .foregroundColor(AppTheme.primary)

            HStack(spacing: AppTheme.Spacing.small) {
                Text("\u{20B9}")
                    .font(AppTheme.Typography.numeric(18))
                    .foregroundColor(.secondary)

                TextField("Enter SIP amount", text: $amount)
                    .font(AppTheme.Typography.numeric(18))
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
            )

            // Quick amount chips
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach([500, 1000, 2500, 5000, 10000], id: \.self) { value in
                    Button {
                        amount = "\(value)"
                    } label: {
                        Text("\u{20B9}\(AppTheme.formatCurrency(Double(value)))")
                            .font(AppTheme.Typography.label(11))
                            .foregroundColor(amount == "\(value)" ? .white : AppTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                amount == "\(value)"
                                    ? AnyShapeStyle(AppTheme.primaryGradient)
                                    : AnyShapeStyle(AppTheme.primary.opacity(0.1))
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.micro)
        }
    }

    // MARK: - Frequency Selector

    private var frequencySelector: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ForEach(frequencies, id: \.0) { value, label in
                let isSelected = frequency == value
                Button {
                    frequency = value
                } label: {
                    Text(label)
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                        )
                        .clipShape(Capsule())
                        .overlay(
                            isSelected ? nil :
                            Capsule().stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(sipDates, id: \.self) { day in
                let isSelected = sipDate == day
                Button {
                    sipDate = day
                } label: {
                    Text("\(day)")
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isSelected
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                        .overlay(
                            isSelected ? nil :
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Create Action

    private func createSip() {
        guard let fund = selectedFund, let sipAmount = Double(amount), sipAmount > 0 else {
            errorMessage = "Please fill in all fields correctly"
            showError = true
            return
        }

        isSaving = true

        Task {
            let request = CreateSipRequest(
                clientId: selectedClientId,
                schemeCode: fund.schemeCode,
                amount: sipAmount,
                frequency: frequency,
                sipDate: sipDate
            )

            let success = await store.createSip(request: request)

            isSaving = false

            if success {
                dismiss()
            } else {
                errorMessage = store.errorMessage ?? "Failed to create SIP"
                showError = true
            }
        }
    }
}
