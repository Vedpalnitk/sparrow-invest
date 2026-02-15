import SwiftUI

// MARK: - Share With Client Sheet

struct ShareWithClientSheet: View {
    let client: FAClientDetail
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var selectedChannel: ShareChannel = .whatsApp
    @State private var selectedTemplate: ShareTemplate = .portfolioSummary
    @State private var messageBody = ""
    @State private var showCopiedToast = false

    enum ShareChannel: String, CaseIterable {
        case email = "Email"
        case whatsApp = "WhatsApp"

        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .whatsApp: return "message.fill"
            }
        }

        var color: Color {
            switch self {
            case .email: return AppTheme.primary
            case .whatsApp: return AppTheme.whatsAppGreen
            }
        }
    }

    enum ShareTemplate: String, CaseIterable {
        case portfolioSummary = "Portfolio Summary"
        case sipFailureAlert = "SIP Failure Alert"
        case sipPaymentReminder = "SIP Payment Reminder"
        case goalProgressUpdate = "Goal Progress"
        case transactionConfirmation = "Transaction Update"
        case reportSharing = "Report Sharing"
        case kycReminder = "KYC Reminder"
        case custom = "Custom Message"

        var icon: String {
            switch self {
            case .portfolioSummary: return "chart.pie.fill"
            case .sipFailureAlert: return "exclamationmark.triangle.fill"
            case .sipPaymentReminder: return "calendar.badge.clock"
            case .goalProgressUpdate: return "target"
            case .transactionConfirmation: return "checkmark.circle.fill"
            case .reportSharing: return "doc.text.fill"
            case .kycReminder: return "checkmark.shield.fill"
            case .custom: return "pencil.and.outline"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    channelToggle
                    templateSelector
                    messagePreview
                    sendButton
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Share with \(client.name.components(separatedBy: " ").first ?? client.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .onAppear { generateMessage() }
        .onChange(of: selectedChannel) { _, _ in generateMessage() }
        .onChange(of: selectedTemplate) { _, _ in generateMessage() }
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

    // MARK: - Channel Toggle

    private var channelToggle: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Channel")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(ShareChannel.allCases, id: \.self) { channel in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedChannel = channel }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: channel.icon)
                                .font(.system(size: 13))
                            Text(channel.rawValue)
                                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        }
                        .foregroundColor(selectedChannel == channel ? .white : channel.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedChannel == channel
                                ? AnyShapeStyle(channel.color)
                                : AnyShapeStyle(channel.color.opacity(0.1))
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Template Selector

    private var templateSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Template")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(ShareTemplate.allCases, id: \.self) { template in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedTemplate = template }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: template.icon)
                                    .font(.system(size: 11))
                                Text(template.rawValue)
                                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                            }
                            .fixedSize()
                            .foregroundColor(selectedTemplate == template ? .white : AppTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                selectedTemplate == template
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

    // MARK: - Message Preview

    private var messagePreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Message Preview")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    UIPasteboard.general.string = messageBody
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

            Text(messageBody)
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

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedChannel == .whatsApp ? "paperplane.fill" : "envelope.fill")
                    .font(.system(size: 14))
                Text(selectedChannel == .whatsApp ? "Send via WhatsApp" : "Send via Email")
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(selectedChannel.color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var firstName: String {
        client.name.components(separatedBy: " ").first ?? client.name
    }

    private var activeSips: [FASip] {
        client.sips.filter { $0.isActive }
    }

    private var monthlySip: Double {
        activeSips.reduce(0) { $0 + $1.amount }
    }

    private var totalInvested: Double {
        client.holdings.reduce(0) { $0 + $1.investedValue }
    }

    private var currentValue: Double {
        client.holdings.reduce(0) { $0 + $1.currentValue }
    }

    private var gain: Double {
        currentValue - totalInvested
    }

    // MARK: - Message Generation

    private func generateMessage() {
        let isWA = selectedChannel == .whatsApp

        switch selectedTemplate {
        case .portfolioSummary:
            messageBody = isWA ? """
            📊 *Portfolio Update*

            Dear \(firstName),

            Here's your portfolio summary:

            💰 Total Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            📈 Invested: \(AppTheme.formatCurrencyWithSymbol(totalInvested))
            \(gain >= 0 ? "✅" : "🔻") Returns: \(AppTheme.formatCurrencyWithSymbol(abs(gain))) (\(client.returns.formattedPercent))
            📋 Holdings: \(client.holdings.count) funds
            🔄 Active SIPs: \(activeSips.count) (\(AppTheme.formatCurrencyWithSymbol(monthlySip))/mo)

            For details, please check the Sparrow Invest app.

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            Please find your portfolio summary below:

            Portfolio Overview:
            - Current Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            - Total Invested: \(AppTheme.formatCurrencyWithSymbol(totalInvested))
            - \(gain >= 0 ? "Gain" : "Loss"): \(AppTheme.formatCurrencyWithSymbol(abs(gain))) (\(client.returns.formattedPercent))
            - Holdings: \(client.holdings.count) funds
            - Active SIPs: \(activeSips.count) (\(AppTheme.formatCurrencyWithSymbol(monthlySip))/month)

            Please feel free to reach out if you have any questions.

            Best regards,
            Sparrow Invest
            """

        case .sipFailureAlert:
            let failedSip = client.sips.first { !$0.isActive } ?? client.sips.first
            let fundName = failedSip?.fundName ?? "N/A"
            let sipAmount = failedSip?.amount ?? monthlySip

            messageBody = isWA ? """
            ⚠️ *SIP Payment Failed*

            Dear \(firstName),

            Your SIP payment could not be processed:

            📋 Fund: \(fundName)
            💰 Amount: \(AppTheme.formatCurrencyWithSymbol(sipAmount))

            Please ensure sufficient balance in your account and check your mandate status.

            Contact us if you need help.

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            We noticed that your SIP payment did not go through. Here are the details:

            Fund: \(fundName)
            Amount: \(AppTheme.formatCurrencyWithSymbol(sipAmount))

            What you can do:
            - Ensure sufficient balance in your bank account
            - Check if your mandate/auto-debit is active
            - Contact us for assistance

            Best regards,
            Sparrow Invest
            """

        case .sipPaymentReminder:
            let nextSip = activeSips.first
            let fundName = nextSip?.fundName ?? "Your Fund"
            let sipAmount = nextSip?.amount ?? monthlySip

            messageBody = isWA ? """
            📅 *SIP Payment Reminder*

            Dear \(firstName),

            Your SIP payment is coming up:

            📋 Fund: \(fundName)
            💰 Amount: \(AppTheme.formatCurrencyWithSymbol(sipAmount))
            🔄 Total Active SIPs: \(activeSips.count) (\(AppTheme.formatCurrencyWithSymbol(monthlySip))/mo)

            Please ensure sufficient balance in your account.

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            This is a reminder that your upcoming SIP payment is scheduled:

            Fund: \(fundName)
            Amount: \(AppTheme.formatCurrencyWithSymbol(sipAmount))
            Total Active SIPs: \(activeSips.count) (\(AppTheme.formatCurrencyWithSymbol(monthlySip))/month)

            Please ensure sufficient balance in your bank account.

            Best regards,
            Sparrow Invest
            """

        case .goalProgressUpdate:
            messageBody = isWA ? """
            🎯 *Goal Progress Update*

            Dear \(firstName),

            Here's an update on your financial goals:

            💰 Portfolio Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            📈 Returns: \(client.returns.formattedPercent)
            📋 Holdings: \(client.holdings.count) funds

            Keep investing consistently to reach your goals!

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            Here's the latest update on your financial goals:

            Portfolio Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            Returns: \(client.returns.formattedPercent)
            Holdings: \(client.holdings.count) funds

            Keep up the great work! We're here to help you reach your goals.

            Best regards,
            Sparrow Invest
            """

        case .transactionConfirmation:
            let recentTx = client.recentTransactions.first
            let txType = recentTx?.type ?? "Purchase"
            let txFund = recentTx?.fundName ?? "N/A"
            let txAmount = recentTx?.amount ?? 0
            let txStatus = recentTx?.status ?? "Completed"

            messageBody = isWA ? """
            ✅ *Transaction \(txStatus)*

            Dear \(firstName),

            📋 Type: \(txType)
            📋 Fund: \(txFund)
            💰 Amount: \(AppTheme.formatCurrencyWithSymbol(txAmount))
            📊 Status: \(txStatus)

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            Here are your transaction details:

            Type: \(txType)
            Fund: \(txFund)
            Amount: \(AppTheme.formatCurrencyWithSymbol(txAmount))
            Status: \(txStatus)

            Best regards,
            Sparrow Invest
            """

        case .reportSharing:
            messageBody = isWA ? """
            📄 *Report Shared*

            Dear \(firstName),

            I've prepared your portfolio report.

            📋 Portfolio Summary
            💰 Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            📈 Returns: \(client.returns.formattedPercent)

            Please check your email or the Sparrow Invest app for the full report.

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            Please find your portfolio report attached.

            Portfolio Summary:
            - Current Value: \(AppTheme.formatCurrencyWithSymbol(currentValue))
            - Returns: \(client.returns.formattedPercent)
            - Holdings: \(client.holdings.count) funds

            Feel free to reach out if you have any questions about the report.

            Best regards,
            Sparrow Invest
            """

        case .kycReminder:
            messageBody = isWA ? """
            📋 *KYC Reminder*

            Dear \(firstName),

            Your KYC documentation needs attention. Please update it to continue enjoying uninterrupted investment services.

            📌 Required: PAN, Aadhaar, Address Proof, Bank Statement

            Please contact us to complete your KYC.

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            We noticed that your KYC documentation needs attention. Please ensure your KYC is up to date to continue enjoying uninterrupted investment services.

            Required Documents:
            - PAN Card
            - Aadhaar Card
            - Address Proof
            - Bank Statement (last 3 months)

            Please contact us to complete your KYC at the earliest.

            Best regards,
            Sparrow Invest
            """

        case .custom:
            messageBody = isWA ? """
            Dear \(firstName),

            [Your message here]

            Regards,
            Sparrow Invest
            """ : """
            Dear \(client.name),

            [Your message here]

            Best regards,
            Sparrow Invest
            """
        }

        // Trim leading whitespace from each line (due to Swift multiline string indentation)
        messageBody = messageBody
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .init(charactersIn: " ")) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Send

    private func sendMessage() {
        switch selectedChannel {
        case .whatsApp:
            let phone = client.phone?.replacingOccurrences(of: "+", with: "").replacingOccurrences(of: " ", with: "") ?? ""
            let encoded = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = phone.isEmpty ? "https://wa.me/?text=\(encoded)" : "https://wa.me/\(phone)?text=\(encoded)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }

        case .email:
            let subject = "\(selectedTemplate.rawValue) - \(client.name)"
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let encodedBody = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "mailto:\(client.email)?subject=\(encodedSubject)&body=\(encodedBody)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}
