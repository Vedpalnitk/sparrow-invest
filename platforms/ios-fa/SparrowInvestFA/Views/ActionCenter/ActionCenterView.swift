import SwiftUI
import MessageUI

struct ActionCenterView: View {
    @StateObject private var store = ActionCenterStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var shareText: String?
    @State private var showShareSheet = false
    @State private var mailData: MailData?
    @State private var showMailCompose = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.isLoading && store.isEmpty {
                    ProgressView("Loading actions...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                } else if store.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        // Summary Bar
                        summaryBar

                        // Failed SIPs Section
                        if !store.failedSips.isEmpty {
                            sectionCard(
                                title: "FAILED SIPS",
                                count: store.failedSips.count,
                                icon: "exclamationmark.triangle",
                                color: AppTheme.error
                            ) {
                                ForEach(store.failedSips) { sip in
                                    failedSipRow(sip)
                                }
                            }
                        }

                        // Pending Transactions Section
                        if !store.pendingTransactions.isEmpty {
                            sectionCard(
                                title: "PENDING TRANSACTIONS",
                                count: store.pendingTransactions.count,
                                icon: "arrow.left.arrow.right",
                                color: AppTheme.warning
                            ) {
                                ForEach(store.pendingTransactions) { tx in
                                    pendingTransactionRow(tx)
                                }
                            }
                        }

                        // KYC Alerts Section
                        if !store.pendingKycClients.isEmpty {
                            sectionCard(
                                title: "KYC PENDING",
                                count: store.pendingKycClients.count,
                                icon: "person.badge.shield.checkmark",
                                color: AppTheme.primary
                            ) {
                                ForEach(store.pendingKycClients) { client in
                                    kycAlertRow(client)
                                }
                            }
                        }

                        Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
            }
            .refreshable { await store.loadActions() }
            .navigationTitle("Action Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task { await store.loadActions() }
            .sheet(isPresented: $showShareSheet) {
                if let text = shareText {
                    ActivityViewController(activityItems: [text])
                }
            }
            .sheet(isPresented: $showMailCompose) {
                if let data = mailData {
                    MailComposeView(data: data)
                }
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            summaryChip(
                count: store.failedSips.count,
                label: "Failed SIPs",
                color: AppTheme.error
            )
            summaryChip(
                count: store.pendingTransactions.count,
                label: "Pending Tx",
                color: AppTheme.warning
            )
            summaryChip(
                count: store.pendingKycClients.count,
                label: "KYC Pending",
                color: AppTheme.primary
            )
        }
    }

    private func summaryChip(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(AppTheme.Typography.numeric(iPad ? 26 : 22))
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.Typography.label(iPad ? 14 : 11))
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.Spacing.compact)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String, count: Int, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Section label with count badge
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(color)

                Text("\(count)")
                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                    .foregroundColor(color)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(color.opacity(0.15))
                    )

                Spacer()
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Failed SIP Row

    private func failedSipRow(_ sip: FASip) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.error.opacity(0.1))
                    .frame(width: iPad ? 44 : 40, height: iPad ? 44 : 40)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: iPad ? 18 : 16))
                    .foregroundColor(AppTheme.error)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(sip.clientName ?? "Client")
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(sip.fundName)
                    .font(AppTheme.Typography.label(iPad ? 15 : 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("SIP of \(sip.formattedAmount) failed")
                    .font(AppTheme.Typography.label(iPad ? 14 : 11))
                    .foregroundColor(AppTheme.error)
            }

            Spacer()

            // Share buttons
            shareButtons(
                onWhatsApp: { shareSipFailureViaWhatsApp(sip) },
                onEmail: { emailSipFailure(sip) }
            )
        }
        .listItemCard()
    }

    // MARK: - Pending Transaction Row

    private func pendingTransactionRow(_ tx: FATransaction) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.warning.opacity(0.1))
                    .frame(width: iPad ? 44 : 40, height: iPad ? 44 : 40)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: iPad ? 18 : 16))
                    .foregroundColor(AppTheme.warning)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.clientName)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(tx.type) - \(tx.fundName)")
                    .font(AppTheme.Typography.label(iPad ? 15 : 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(tx.formattedAmount)
                    .font(AppTheme.Typography.label(iPad ? 14 : 11))
                    .foregroundColor(AppTheme.warning)
            }

            Spacer()

            // Share buttons
            shareButtons(
                onWhatsApp: { sharePendingTransactionViaWhatsApp(tx) },
                onEmail: { emailPendingTransaction(tx) }
            )
        }
        .listItemCard()
    }

    // MARK: - KYC Alert Row

    private func kycAlertRow(_ client: FAClient) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: iPad ? 44 : 40, height: iPad ? 44 : 40)

                Image(systemName: "person.badge.shield.checkmark")
                    .font(.system(size: iPad ? 18 : 16))
                    .foregroundColor(AppTheme.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("KYC: \(client.kycStatus ?? "PENDING")")
                    .font(AppTheme.Typography.label(iPad ? 14 : 11))
                    .foregroundColor(AppTheme.primary)
            }

            Spacer()

            // Share buttons
            shareButtons(
                onWhatsApp: { shareKycReminderViaWhatsApp(client) },
                onEmail: { emailKycReminder(client) }
            )
        }
        .listItemCard()
    }

    // MARK: - Share Buttons

    private func shareButtons(onWhatsApp: @escaping () -> Void, onEmail: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Button(action: onWhatsApp) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.success)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.success.opacity(0.08))
                    .clipShape(Circle())
            }

            Button(action: onEmail) {
                Image(systemName: "envelope")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primary.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.success)

            Text("All caught up!")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("No pending actions at the moment")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Share Helpers (SIP Failure)

    private func shareSipFailureViaWhatsApp(_ sip: FASip) {
        let message = """
        Hi \(sip.clientName ?? ""),

        Your SIP of \(sip.formattedAmount) in \(sip.fundName) could not be processed.

        This usually happens due to insufficient balance in your bank account on the SIP date.

        Please ensure sufficient funds are available and I'll help re-initiate the installment.

        - Sparrow Invest
        """
        shareText = message
        showShareSheet = true
    }

    private func emailSipFailure(_ sip: FASip) {
        let subject = "SIP Payment Failed - \(sip.fundName)"
        let body = """
        Hi \(sip.clientName ?? ""),

        Your SIP of \(sip.formattedAmount) in \(sip.fundName) could not be processed.

        This usually happens due to insufficient balance in your bank account on the SIP date.

        Please ensure sufficient funds are available and I'll help re-initiate the installment.

        Best regards,
        Sparrow Invest
        """
        mailData = MailData(subject: subject, body: body)
        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else {
            shareText = "\(subject)\n\n\(body)"
            showShareSheet = true
        }
    }

    // MARK: - Share Helpers (Pending Transaction)

    private func sharePendingTransactionViaWhatsApp(_ tx: FATransaction) {
        let message = """
        Hi \(tx.clientName),

        Your \(tx.type) transaction of \(tx.formattedAmount) in \(tx.fundName) is pending.

        Please complete the required steps to process this transaction at the earliest.

        - Sparrow Invest
        """
        shareText = message
        showShareSheet = true
    }

    private func emailPendingTransaction(_ tx: FATransaction) {
        let subject = "Pending Transaction - \(tx.fundName)"
        let body = """
        Hi \(tx.clientName),

        Your \(tx.type) transaction of \(tx.formattedAmount) in \(tx.fundName) is pending.

        Please complete the required steps to process this transaction at the earliest.

        Best regards,
        Sparrow Invest
        """
        mailData = MailData(subject: subject, body: body)
        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else {
            shareText = "\(subject)\n\n\(body)"
            showShareSheet = true
        }
    }

    // MARK: - Share Helpers (KYC Reminder)

    private func shareKycReminderViaWhatsApp(_ client: FAClient) {
        let message = """
        Hi \(client.name),

        A gentle reminder to complete your KYC verification for your mutual fund investments.

        KYC is mandatory as per SEBI regulations and takes just a few minutes. Please share your PAN card and address proof at your earliest convenience.

        I'm happy to guide you through the process.

        - Sparrow Invest
        """
        shareText = message
        showShareSheet = true
    }

    private func emailKycReminder(_ client: FAClient) {
        let subject = "KYC Verification Reminder"
        let body = """
        Hi \(client.name),

        A gentle reminder to complete your KYC verification for your mutual fund investments.

        KYC is mandatory as per SEBI regulations and takes just a few minutes. Please share your PAN card and address proof at your earliest convenience.

        I'm happy to guide you through the process.

        Best regards,
        Sparrow Invest
        """
        mailData = MailData(subject: subject, body: body, recipient: client.email)
        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else {
            shareText = "\(subject)\n\n\(body)"
            showShareSheet = true
        }
    }
}

// MARK: - Action Center Store

@MainActor
class ActionCenterStore: ObservableObject {
    @Published var failedSips: [FASip] = []
    @Published var pendingTransactions: [FATransaction] = []
    @Published var pendingKycClients: [FAClient] = []
    @Published var isLoading = false

    var isEmpty: Bool {
        failedSips.isEmpty && pendingTransactions.isEmpty && pendingKycClients.isEmpty
    }

    var totalCount: Int {
        failedSips.count + pendingTransactions.count + pendingKycClients.count
    }

    func loadActions() async {
        isLoading = true

        // Load failed SIPs
        do {
            let allSips: [FASip] = try await APIService.shared.get("/sips")
            failedSips = allSips.filter { $0.status == "FAILED" }
        } catch {
            failedSips = []
        }

        // Load pending transactions
        do {
            let allTx: [FATransaction] = try await APIService.shared.get("/transactions")
            pendingTransactions = allTx.filter { $0.status == "Pending" }
        } catch {
            pendingTransactions = []
        }

        // Load clients with pending KYC
        do {
            let allClients: [FAClient] = try await APIService.shared.get("/clients")
            pendingKycClients = allClients.filter {
                guard let kyc = $0.kycStatus?.uppercased() else { return true }
                return kyc != "VERIFIED"
            }
        } catch {
            pendingKycClients = []
        }

        isLoading = false
    }
}

// MARK: - Mail Data

struct MailData {
    let subject: String
    let body: String
    var recipient: String?
}

// MARK: - Activity View Controller (Share Sheet)

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let data: MailData
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(data.subject)
        vc.setMessageBody(data.body, isHTML: false)
        if let recipient = data.recipient {
            vc.setToRecipients([recipient])
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
