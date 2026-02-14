import SwiftUI

struct TransactionsView: View {
    @StateObject private var store = TransactionStore()
    @State private var selectedFilter = "All"
    @State private var showNewTransaction = false
    @State private var showPlatformWebView = false
    @State private var selectedPlatform = TransactionPlatform.bseStarMF
    @Environment(\.colorScheme) private var colorScheme

    let filters = ["All", "Pending", "Completed", "Processing", "Failed"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Chips
                GlassSegmentedControl(items: filters, selection: $selectedFilter)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)

                if store.isLoading && store.transactions.isEmpty {
                    Spacer()
                    ProgressView("Loading transactions...")
                    Spacer()
                } else if filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No transactions found")
                            .font(AppTheme.Typography.headline(17))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            // Summary Card
                            transactionSummaryCard

                            ForEach(filteredTransactions) { tx in
                                NavigationLink {
                                    TransactionDetailView(transactionId: tx.id)
                                } label: {
                                    transactionRow(tx)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.xxxLarge)
                    }
                    .refreshable { await store.loadTransactions() }
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(TransactionPlatform.allCases, id: \.rawValue) { platform in
                                Button {
                                    selectedPlatform = platform
                                    showPlatformWebView = true
                                } label: {
                                    Label(platform.title, systemImage: "globe")
                                }
                            }
                        } label: {
                            Image(systemName: "globe")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.primary)
                                .padding(7)
                                .background(AppTheme.primary.opacity(0.1))
                                .clipShape(Circle())
                        }

                        Button {
                            showNewTransaction = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("New")
                                    .font(AppTheme.Typography.accent(14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionWizardView()
            }
            .fullScreenCover(isPresented: $showPlatformWebView) {
                PlatformWebView(platform: selectedPlatform)
            }
            .task { await store.loadTransactions() }
        }
    }

    // MARK: - Transaction Summary Card

    private var transactionSummaryCard: some View {
        let allTx = store.transactions
        let pending = allTx.filter { $0.status == "Pending" }
        let completed = allTx.filter { $0.status == "Completed" || $0.status == "Executed" }
        let rejected = allTx.filter { $0.status == "Rejected" || $0.status == "Failed" }
        let pendingValue = pending.reduce(0) { $0 + $1.amount }

        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
            summaryTile(
                icon: "clock.fill",
                label: "Pending",
                value: "\(pending.count)",
                color: AppTheme.warning
            )
            summaryTile(
                icon: "checkmark.circle.fill",
                label: "Executed",
                value: "\(completed.count)",
                color: AppTheme.success
            )
            summaryTile(
                icon: "xmark.circle.fill",
                label: "Rejected",
                value: "\(rejected.count)",
                color: AppTheme.error
            )
            summaryTile(
                icon: "indianrupeesign.circle.fill",
                label: "Pending Value",
                value: AppTheme.formatCurrencyWithSymbol(pendingValue),
                color: AppTheme.primary
            )
        }
        .padding(.bottom, AppTheme.Spacing.small)
    }

    private func summaryTile(icon: String, label: String, value: String, color: Color) -> some View {
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

    private var filteredTransactions: [FATransaction] {
        if selectedFilter == "All" { return store.transactions }
        return store.transactions.filter { $0.status == selectedFilter }
    }

    private func transactionRow(_ tx: FATransaction) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Type Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(typeColor(tx.type).opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: typeIcon(tx.type))
                        .font(.system(size: 16))
                        .foregroundColor(typeColor(tx.type))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.clientName)
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(.primary)

                    Text(tx.fundName)
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: AppTheme.Spacing.small) {
                        Text(tx.type)
                            .font(AppTheme.Typography.label(10))
                            .foregroundColor(typeColor(tx.type))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor(tx.type).opacity(0.1))
                            .clipShape(Capsule())

                        Text(tx.date)
                            .font(AppTheme.Typography.label(10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(tx.formattedAmount)
                        .font(AppTheme.Typography.numeric(14))
                        .foregroundColor(.primary)

                    Text(tx.status)
                        .font(AppTheme.Typography.label(10))
                        .foregroundColor(AppTheme.statusColor(tx.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.statusColor(tx.status).opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Inline Approve/Reject for pending transactions
            if tx.isPending {
                Divider()
                    .padding(.vertical, AppTheme.Spacing.small)

                HStack(spacing: AppTheme.Spacing.compact) {
                    Button {
                        Task {
                            await store.updateTransactionStatus(tx.id, status: "Rejected")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                            Text("Reject")
                                .font(AppTheme.Typography.accent(12))
                        }
                        .foregroundColor(AppTheme.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(AppTheme.error.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await store.updateTransactionStatus(tx.id, status: "Approved")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                            Text("Approve")
                                .font(AppTheme.Typography.accent(12))
                        }
                        .foregroundColor(AppTheme.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(AppTheme.success.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    private func typeIcon(_ type: String) -> String {
        switch type {
        case "Buy": return "arrow.down.circle"
        case "Sell": return "arrow.up.circle"
        case "SIP": return "arrow.triangle.2.circlepath"
        case "Switch": return "arrow.left.arrow.right"
        default: return "doc.text"
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "Buy": return AppTheme.success
        case "Sell": return AppTheme.error
        case "SIP": return AppTheme.primary
        case "Switch": return AppTheme.info
        default: return AppTheme.secondary
        }
    }
}

// MARK: - Transaction Store

@MainActor
class TransactionStore: ObservableObject {
    @Published var transactions: [FATransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadTransactions() async {
        isLoading = true
        do {
            let response: PaginatedResponse<FATransaction> = try await APIService.shared.get("/transactions?limit=100")
            transactions = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateTransactionStatus(_ id: String, status: String) async {
        do {
            let request = UpdateStatusRequest(status: status, notes: nil)
            let _: FATransaction = try await APIService.shared.put("/transactions/\(id)/status", body: request)
            await loadTransactions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
