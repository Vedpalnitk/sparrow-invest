import SwiftUI

struct TransactionDetailView: View {
    let transactionId: String
    @StateObject private var store = TransactionDetailStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNotesSheet = false
    @State private var pendingAction: TransactionAction?
    @State private var actionNotes = ""

    var body: some View {
        ScrollView {
            if let tx = store.transaction {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Amount & Status Header
                    amountHeader(tx)

                    // Client Info Section
                    detailSection("Client", icon: "person.fill") {
                        detailRow("Name", value: tx.clientName)
                        detailRow("Client ID", value: tx.clientId)
                    }

                    // Fund Info Section
                    detailSection("Fund", icon: "building.columns.fill") {
                        detailRow("Fund Name", value: tx.fundName)
                        if !tx.fundSchemeCode.isEmpty {
                            detailRow("Scheme Code", value: tx.fundSchemeCode)
                        }
                        if !tx.fundCategory.isEmpty {
                            detailRow("Category", value: tx.fundCategory)
                        }
                    }

                    // Transaction Details Section
                    detailSection("Details", icon: "doc.text.fill") {
                        detailRow("Amount", value: tx.formattedAmount)
                        if tx.units > 0 {
                            detailRow("Units", value: String(format: "%.4f", tx.units))
                        }
                        if tx.nav > 0 {
                            detailRow("NAV", value: String(format: "\u{20B9}%.4f", tx.nav))
                        }
                        detailRow("Date", value: tx.date)
                        if !tx.folioNumber.isEmpty {
                            detailRow("Folio Number", value: tx.folioNumber)
                        }
                        if let orderId = tx.orderId, !orderId.isEmpty {
                            detailRow("Order ID", value: orderId)
                        }
                        if let paymentMode = tx.paymentMode, !paymentMode.isEmpty {
                            detailRow("Payment Mode", value: paymentMode)
                        }
                    }

                    // Remarks Section
                    if let remarks = tx.remarks, !remarks.isEmpty {
                        detailSection("Remarks", icon: "text.quote") {
                            Text(remarks)
                                .font(AppTheme.Typography.caption())
                                .foregroundColor(.secondary)
                        }
                    }

                    // Approval Timeline
                    approvalTimeline(tx)

                    // Action Buttons for Pending Transactions
                    if tx.isPending {
                        actionsSection(tx)
                    }

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
            } else if store.isLoading {
                ProgressView("Loading transaction...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            } else if let error = store.errorMessage {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.warning)
                    Text(error)
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await store.loadTransaction(transactionId) }
                    }
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(AppTheme.primary)
                }
                .padding(.top, 100)
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadTransaction(transactionId) }
        .alert("Error", isPresented: $store.showActionError) {
            Button("OK") {}
        } message: {
            Text(store.actionErrorMessage ?? "An error occurred")
        }
        .alert("Success", isPresented: $store.showActionSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text(store.actionSuccessMessage ?? "Action completed")
        }
        .sheet(isPresented: $showNotesSheet) {
            transactionNotesSheet
        }
    }

    // MARK: - Amount & Status Header

    private func amountHeader(_ tx: FATransaction) -> some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            Text(tx.formattedAmount)
                .font(AppTheme.Typography.display(32))
                .foregroundColor(.primary)

            HStack(spacing: AppTheme.Spacing.compact) {
                statusBadge(tx.status)
                typeBadge(tx.type)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Detail Section

    private func detailSection(_ title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }

                Text(title)
                    .font(AppTheme.Typography.headline(16))
                    .foregroundColor(.primary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Detail Row

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Status Badge

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(AppTheme.Typography.label(12))
            .foregroundColor(AppTheme.statusColor(status))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.statusColor(status).opacity(0.1))
            .clipShape(Capsule())
    }

    private func typeBadge(_ type: String) -> some View {
        let color = typeColor(type)
        return Text(type)
            .font(AppTheme.Typography.label(12))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Approval Timeline

    private func approvalTimeline(_ tx: FATransaction) -> some View {
        let steps = timelineSteps(for: tx)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }

                Text("Timeline")
                    .font(AppTheme.Typography.headline(16))
                    .foregroundColor(.primary)
            }

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.compact) {
                        // Timeline dot and line
                        VStack(spacing: 0) {
                            Circle()
                                .fill(step.isCompleted ? step.color : Color.secondary.opacity(0.3))
                                .frame(width: 12, height: 12)
                                .overlay(
                                    step.isCompleted
                                        ? Circle().fill(step.color.opacity(0.3)).frame(width: 20, height: 20)
                                        : nil
                                )

                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(step.isCompleted ? step.color.opacity(0.3) : Color.secondary.opacity(0.15))
                                    .frame(width: 2, height: 36)
                            }
                        }
                        .frame(width: 24)

                        // Step content
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(AppTheme.Typography.accent(14))
                                .foregroundColor(step.isCompleted ? .primary : .secondary)

                            if let subtitle = step.subtitle {
                                Text(subtitle)
                                    .font(AppTheme.Typography.label(11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, index < steps.count - 1 ? AppTheme.Spacing.small : 0)

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    private func timelineSteps(for tx: FATransaction) -> [TimelineStep] {
        var steps: [TimelineStep] = []

        // Created step — always present
        steps.append(TimelineStep(
            title: "Created",
            subtitle: tx.date,
            color: AppTheme.primary,
            isCompleted: true
        ))

        // Status-based steps
        let status = tx.status
        let isApproved = status == "Approved" || status == "Executed" || status == "Completed"
        let isExecuted = status == "Executed" || status == "Completed"
        let isRejected = status == "Rejected"
        let isCancelled = status == "Cancelled"
        let isFailed = status == "Failed"

        if isRejected {
            steps.append(TimelineStep(title: "Rejected", subtitle: "Transaction was rejected", color: AppTheme.error, isCompleted: true))
        } else if isCancelled {
            steps.append(TimelineStep(title: "Cancelled", subtitle: "Transaction was cancelled", color: .secondary, isCompleted: true))
        } else if isFailed {
            steps.append(TimelineStep(title: "Failed", subtitle: "Transaction failed", color: AppTheme.error, isCompleted: true))
        } else {
            // Approved step
            steps.append(TimelineStep(
                title: "Approved",
                subtitle: isApproved ? "Approved by advisor" : nil,
                color: AppTheme.success,
                isCompleted: isApproved
            ))

            // Executed step
            steps.append(TimelineStep(
                title: "Executed",
                subtitle: isExecuted ? "Trade executed on exchange" : nil,
                color: AppTheme.primary,
                isCompleted: isExecuted
            ))
        }

        return steps
    }

    // MARK: - Actions Section

    private func actionsSection(_ tx: FATransaction) -> some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text("ACTIONS")
                .font(AppTheme.Typography.label(11))
                .foregroundColor(AppTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.isActionLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.medium)
            } else {
                // Execute Button
                Button {
                    pendingAction = .execute
                    actionNotes = ""
                    showNotesSheet = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Execute Trade")
                            .font(AppTheme.Typography.accent(15))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                }

                // Approve & Reject
                HStack(spacing: AppTheme.Spacing.compact) {
                    Button {
                        pendingAction = .reject
                        actionNotes = ""
                        showNotesSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                            Text("Reject")
                                .font(AppTheme.Typography.accent(14))
                        }
                        .foregroundColor(AppTheme.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.error.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        pendingAction = .approve
                        actionNotes = ""
                        showNotesSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                            Text("Approve")
                                .font(AppTheme.Typography.accent(14))
                        }
                        .foregroundColor(AppTheme.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.success.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                // Cancel Button
                Button {
                    pendingAction = .cancel
                    actionNotes = ""
                    showNotesSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "nosign")
                            .font(.system(size: 12))
                        Text("Cancel Transaction")
                            .font(AppTheme.Typography.accent(14))
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.medium)
    }

    // MARK: - Transaction Notes Sheet

    private var transactionNotesSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Action header
                if let action = pendingAction {
                    HStack(spacing: AppTheme.Spacing.compact) {
                        ZStack {
                            Circle()
                                .fill(action.color.opacity(0.1))
                                .frame(width: 44, height: 44)

                            Image(systemName: action.icon)
                                .font(.system(size: 18))
                                .foregroundColor(action.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(AppTheme.Typography.headline(16))
                                .foregroundColor(.primary)

                            Text(action.subtitle)
                                .font(AppTheme.Typography.accent(13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .glassCard()
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }

                // Notes field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("NOTES (OPTIONAL)")
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(AppTheme.primary)

                    TextField("Add notes for this action...", text: $actionNotes, axis: .vertical)
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
                .glassCard()
                .padding(.horizontal, AppTheme.Spacing.medium)

                Spacer()

                // Confirm button
                if let action = pendingAction, let tx = store.transaction {
                    Button {
                        showNotesSheet = false
                        let notes = actionNotes.isEmpty ? nil : actionNotes
                        Task {
                            await store.updateStatus(tx.id, status: action.statusValue, notes: notes, successMessage: action.successMessage)
                        }
                    } label: {
                        Text("Confirm \(action.title)")
                            .font(AppTheme.Typography.accent(15))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(action.color == .secondary ? AppTheme.primaryGradient : LinearGradient(colors: [action.color, action.color.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.bottom, AppTheme.Spacing.medium)
                }
            }
            .padding(.top, AppTheme.Spacing.compact)
            .navigationTitle("Confirm Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showNotesSheet = false
                        pendingAction = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "Buy", "SIP": return AppTheme.success
        case "Sell", "SWP": return AppTheme.error
        case "Switch", "STP": return AppTheme.info
        default: return AppTheme.secondary
        }
    }
}

// MARK: - Transaction Detail Store

@MainActor
class TransactionDetailStore: ObservableObject {
    @Published var transaction: FATransaction?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isActionLoading = false
    @Published var showActionError = false
    @Published var actionErrorMessage: String?
    @Published var showActionSuccess = false
    @Published var actionSuccessMessage: String?

    func loadTransaction(_ transactionId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            transaction = try await APIService.shared.get("/transactions/\(transactionId)")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateStatus(_ id: String, status: String, notes: String?, successMessage: String) async {
        isActionLoading = true
        do {
            let request = UpdateStatusRequest(status: status, notes: notes)
            let _: FATransaction = try await APIService.shared.put("/transactions/\(id)/status", body: request)
            actionSuccessMessage = successMessage
            showActionSuccess = true
        } catch {
            actionErrorMessage = error.localizedDescription
            showActionError = true
        }
        isActionLoading = false
    }
}

// MARK: - Timeline Step

struct TimelineStep {
    let title: String
    let subtitle: String?
    let color: Color
    let isCompleted: Bool
}

// MARK: - Transaction Action Enum

enum TransactionAction {
    case approve
    case reject
    case execute
    case cancel

    var title: String {
        switch self {
        case .approve: return "Approve"
        case .reject: return "Reject"
        case .execute: return "Execute"
        case .cancel: return "Cancel"
        }
    }

    var subtitle: String {
        switch self {
        case .approve: return "Approve this transaction for processing"
        case .reject: return "Reject and return this transaction"
        case .execute: return "Execute this trade on the exchange"
        case .cancel: return "Cancel this pending transaction"
        }
    }

    var icon: String {
        switch self {
        case .approve: return "checkmark.circle"
        case .reject: return "xmark.circle"
        case .execute: return "play.circle"
        case .cancel: return "nosign"
        }
    }

    var color: Color {
        switch self {
        case .approve: return AppTheme.success
        case .reject: return AppTheme.error
        case .execute: return AppTheme.primary
        case .cancel: return .secondary
        }
    }

    var statusValue: String {
        switch self {
        case .approve: return "Approved"
        case .reject: return "Rejected"
        case .execute: return "Executed"
        case .cancel: return "Cancelled"
        }
    }

    var successMessage: String {
        switch self {
        case .approve: return "Transaction approved"
        case .reject: return "Transaction rejected"
        case .execute: return "Trade executed successfully"
        case .cancel: return "Transaction cancelled"
        }
    }
}
