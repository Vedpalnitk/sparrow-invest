import SwiftUI

struct ExecuteTradeView: View {
    let clientId: String
    @StateObject private var store = ExecuteTradeStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.isLoadingClient {
                    ProgressView("Loading client...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        // Client Info
                        if let client = store.client {
                            clientInfoSection(client)
                        }

                        // Trade Type
                        tradeTypeSection

                        // Fund Selection
                        fundSelectionSection

                        // Amount & Notes
                        amountSection

                        // Execute Button
                        executeButton

                        Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                    }
                    .padding(.top, AppTheme.Spacing.compact)
                }
            }
            .navigationTitle("Execute Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await store.loadClient(clientId) }
            .alert("Error", isPresented: $store.showError) {
                Button("OK") {}
            } message: {
                Text(store.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $store.showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Trade executed successfully")
            }
        }
    }

    // MARK: - Client Info

    private func clientInfoSection(_ client: FAClient) -> some View {
        tradeFormSection(title: "Client", subtitle: client.name, icon: "person.fill") {
            HStack {
                Text(client.email)
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text("AUM: \(client.formattedAum)")
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    .foregroundColor(AppTheme.primary)
            }
        }
    }

    // MARK: - Trade Type

    private var tradeTypeSection: some View {
        tradeFormSection(title: "Trade Type", subtitle: "Select buy or sell", icon: "indianrupeesign.circle.fill") {
            HStack(spacing: 0) {
                ForEach(["Buy", "Sell"], id: \.self) { type in
                    let isSelected = store.tradeType == type
                    Button {
                        store.tradeType = type
                    } label: {
                        Text(type)
                            .font(AppTheme.Typography.accent(iPad ? 17 : 14))
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
        }
    }

    // MARK: - Fund Selection

    private var fundSelectionSection: some View {
        tradeFormSection(title: "Fund", subtitle: "Search and select a fund", icon: "building.columns.fill") {
            if let fund = store.selectedFund {
                // Selected fund
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fund.schemeName)
                            .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if let nav = fund.nav {
                            Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                .font(AppTheme.Typography.label(iPad ? 14 : 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        store.selectedFund = nil
                        store.fundSearchQuery = ""
                        store.fundSearchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .listItemCard()
            } else {
                // Search
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    TextField("Search fund name...", text: $store.fundSearchQuery)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .onChange(of: store.fundSearchQuery) { _, newValue in
                            Task { await store.searchFunds(query: newValue) }
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

                if store.isFundSearchLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.small)
                }

                // Search Results
                if !store.fundSearchResults.isEmpty {
                    VStack(spacing: AppTheme.Spacing.micro) {
                        ForEach(store.fundSearchResults.prefix(5)) { fund in
                            Button {
                                store.selectedFund = fund
                                store.fundSearchResults = []
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fund.schemeName)
                                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    HStack {
                                        if let nav = fund.nav {
                                            Text("NAV: \u{20B9}\(String(format: "%.2f", nav))")
                                                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
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

    // MARK: - Amount & Notes

    private var amountSection: some View {
        tradeFormSection(title: "Amount", subtitle: "Enter trade amount", icon: "indianrupeesign.circle.fill") {
            VStack(spacing: AppTheme.Spacing.compact) {
                // Amount Field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                    Text("AMOUNT (\u{20B9})")
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
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .stroke(
                                store.amountError != nil
                                    ? AppTheme.error
                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5)),
                                lineWidth: 1
                            )
                    )

                    if let amountError = store.amountError {
                        Text(amountError)
                            .font(AppTheme.Typography.label(iPad ? 13 : 11))
                            .foregroundColor(AppTheme.error)
                    }
                }

                // Notes Field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                    Text("NOTES (OPTIONAL)")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(AppTheme.primary)

                    TextField("Add any notes...", text: $store.notes, axis: .vertical)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
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
        }
    }

    // MARK: - Execute Button

    private var executeButton: some View {
        Button {
            Task { await store.executeTrade() }
        } label: {
            Group {
                if store.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                        Text("Execute \(store.tradeType)")
                            .font(AppTheme.Typography.headline(iPad ? 19 : 16))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                store.canExecute && !store.isSubmitting
                    ? AppTheme.primaryGradient
                    : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
        }
        .disabled(!store.canExecute || store.isSubmitting)
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Trade Form Section

    private func tradeFormSection(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.primary)
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

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }
}

// MARK: - Execute Trade Store

@MainActor
class ExecuteTradeStore: ObservableObject {
    @Published var client: FAClient?
    @Published var isLoadingClient = false
    @Published var tradeType = "Buy"
    @Published var selectedFund: FAFund?
    @Published var fundSearchQuery = ""
    @Published var fundSearchResults: [FAFund] = []
    @Published var isFundSearchLoading = false
    @Published var amount = ""
    @Published var amountError: String?
    @Published var notes = ""
    @Published var isSubmitting = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false

    private var clientId = ""
    private var searchTask: Task<Void, Never>?

    var canExecute: Bool {
        selectedFund != nil && !amount.isEmpty && (Double(amount) ?? 0) > 0
    }

    func loadClient(_ clientId: String) async {
        self.clientId = clientId
        isLoadingClient = true
        do {
            let detail: FAClientDetail = try await APIService.shared.get("/clients/\(clientId)")
            client = FAClient(
                id: detail.id, name: detail.name, email: detail.email,
                phone: detail.phone, aum: detail.aum, returns: detail.returns,
                riskProfile: detail.riskProfile, kycStatus: detail.kycStatus
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingClient = false
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

    func executeTrade() async {
        guard let fund = selectedFund else {
            errorMessage = "Please select a fund"
            showError = true
            return
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            amountError = "Enter a valid amount"
            return
        }

        amountError = nil
        isSubmitting = true
        errorMessage = nil

        do {
            let request = ExecuteTradeRequest(
                clientId: clientId,
                schemeCode: "\(fund.schemeCode)",
                amount: amountValue,
                familyMemberId: nil,
                notes: notes.isEmpty ? nil : notes
            )

            let endpoint = (tradeType == "Sell") ? "/transactions/redemption" : "/transactions/lumpsum"
            let _: FATransaction = try await APIService.shared.post(endpoint, body: request)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}
