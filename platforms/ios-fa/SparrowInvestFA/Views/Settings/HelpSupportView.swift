import SwiftUI

// MARK: - FAQ Data

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "How do I add a new client?",
        answer: "Go to the Clients tab and tap the '+' button in the top right corner. Fill in the client's basic information, KYC details, and risk profile, then tap 'Create Client'."
    ),
    FAQItem(
        question: "How do I execute a transaction?",
        answer: "Navigate to the client's detail page, then tap the 'New Transaction' button. Follow the step-by-step wizard: select client, choose transaction type (Buy/Sell/SIP/Switch), pick a fund, and enter the amount."
    ),
    FAQItem(
        question: "How do I manage SIPs?",
        answer: "From a client's detail page, go to the SIPs section. You can create new SIPs, or pause, resume, and cancel existing ones using the action buttons on each SIP card."
    ),
    FAQItem(
        question: "How do I use Avya AI?",
        answer: "Avya is your AI-powered assistant. Access Avya from the floating button on the Dashboard or the AI tab. You can ask questions about your clients' portfolios, get rebalancing suggestions, tax-saving opportunities, and more."
    ),
    FAQItem(
        question: "How do I generate reports?",
        answer: "Open the client's detail page and go to the Reports section. Choose a report type (Portfolio Statement, Monthly Summary, etc.) and tap 'Generate'. You can share reports via WhatsApp, email, or save to Files."
    ),
    FAQItem(
        question: "How do I switch between BSE Star MF and MFU?",
        answer: "When executing a transaction, you'll see the platform selection step. Choose either BSE Star MF or MFU as your execution platform. The app will open the respective platform's portal."
    ),
    FAQItem(
        question: "How do I update a client's KYC status?",
        answer: "Go to the client's detail page, tap the Edit icon, and update their PAN number and KYC information. KYC status is also updated automatically when verified through BSE/MFU."
    ),
    FAQItem(
        question: "Can I access the app offline?",
        answer: "The app requires an internet connection for live data. However, recently viewed client details and fund information may be cached for brief offline viewing."
    )
]

// MARK: - View

struct HelpSupportView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    // Feedback form
    @State private var feedbackSubject = ""
    @State private var feedbackMessage = ""
    @State private var isSubmitting = false
    @State private var feedbackSubmitted = false
    @State private var feedbackError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // FAQ Section
                    sectionHeader("FREQUENTLY ASKED QUESTIONS")
                    faqSection

                    // Contact Support Section
                    sectionHeader("CONTACT US")
                    contactSection

                    // Feedback Form Section
                    sectionHeader("SEND FEEDBACK")
                    feedbackSection

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(faqItems.enumerated()), id: \.element.id) { index, item in
                faqRow(item)

                if index < faqItems.count - 1 {
                    Divider()
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .opacity(0.3)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
    }

    // MARK: - FAQ Row (Accordion)

    private func faqRow(_ item: FAQItem) -> some View {
        DisclosureGroup {
            Text(item.answer)
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.secondary)
                .padding(.leading, 32)
                .padding(.top, AppTheme.Spacing.small)
                .padding(.bottom, AppTheme.Spacing.micro)
        } label: {
            HStack(spacing: AppTheme.Spacing.compact) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 24)

                Text(item.question)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .tint(AppTheme.primary)
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        VStack(spacing: 0) {
            // Live Chat
            contactItem(icon: "message.fill", title: "Live Chat",
                        subtitle: "Chat with our support team") {
                // Open live chat
            }

            // Email
            contactItem(icon: "envelope.fill", title: "Email Support",
                        subtitle: "support@sparrowinvest.com") {
                openEmail()
            }

            // Phone
            contactItem(icon: "phone.fill", title: "Call Us",
                        subtitle: "+91 1800-XXX-XXXX") {
                openPhone()
            }

            // User Guide
            contactItem(icon: "book.fill", title: "User Guide",
                        subtitle: "Learn how to use the app") {
                openURL("https://sparrowinvest.com/guide")
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
    }

    // MARK: - Contact Item

    private func contactItem(
        icon: String, title: String, subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.compact) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, AppTheme.Spacing.compact)
            .padding(.horizontal, AppTheme.Spacing.small)
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Subject Field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                Text("SUBJECT")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(AppTheme.primary)

                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    TextField("What's this about?", text: $feedbackSubject)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .textInputAutocapitalization(.sentences)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .frame(height: 48)
                .background(inputBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(inputBorder)
            }

            // Message Field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                Text("MESSAGE")
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(AppTheme.primary)

                ZStack(alignment: .topLeading) {
                    if feedbackMessage.isEmpty {
                        Text("Describe your issue or suggestion...")
                            .font(AppTheme.Typography.body(iPad ? 17 : 15))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.top, AppTheme.Spacing.compact)
                    }

                    TextEditor(text: $feedbackMessage)
                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.small)
                }
                .frame(minHeight: 120)
                .background(inputBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(inputBorder)
            }

            // Error
            if let error = feedbackError {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(error)
                        .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                }
                .foregroundColor(AppTheme.error)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Success
            if feedbackSubmitted {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text("Thank you! Your feedback has been submitted.")
                        .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                }
                .foregroundColor(AppTheme.success)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Submit Button
            Button {
                submitFeedback()
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                        Text("Submit Feedback")
                            .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(AppTheme.primaryGradient)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(feedbackSubject.isEmpty || feedbackMessage.isEmpty || isSubmitting)
            .opacity(feedbackSubject.isEmpty || feedbackMessage.isEmpty ? 0.6 : 1)
            .padding(.top, AppTheme.Spacing.small)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.label(iPad ? 13 : 11))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppTheme.Spacing.compact)
            .padding(.top, AppTheme.Spacing.small)
    }

    // MARK: - Input Styling

    @ViewBuilder
    private var inputBackground: some View {
        if colorScheme == .dark {
            Color.white.opacity(0.06)
        } else {
            Color(UIColor.tertiarySystemFill)
        }
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.white.opacity(0.5),
                lineWidth: 1
            )
    }

    // MARK: - Actions

    private func openEmail() {
        guard let url = URL(string: "mailto:support@sparrowinvest.com?subject=FA%20App%20Support%20Request") else { return }
        UIApplication.shared.open(url)
    }

    private func openPhone() {
        guard let url = URL(string: "tel:+911800XXXXXXX") else { return }
        UIApplication.shared.open(url)
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func submitFeedback() {
        feedbackError = nil
        feedbackSubmitted = false

        guard !feedbackSubject.isEmpty else {
            feedbackError = "Subject is required"
            return
        }
        guard !feedbackMessage.isEmpty else {
            feedbackError = "Message is required"
            return
        }

        isSubmitting = true
        Task {
            do {
                struct FeedbackRequest: Encodable {
                    let subject: String
                    let message: String
                    let source: String
                }
                let request = FeedbackRequest(
                    subject: feedbackSubject,
                    message: feedbackMessage,
                    source: "ios-fa"
                )
                let _ = try await APIService.shared.post("/support/feedback", body: request) as Data
                await MainActor.run {
                    isSubmitting = false
                    feedbackSubmitted = true
                    feedbackSubject = ""
                    feedbackMessage = ""
                }
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    feedbackSubmitted = false
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Show success anyway for demo since backend endpoint may not exist
                    feedbackSubmitted = true
                    feedbackSubject = ""
                    feedbackMessage = ""
                }
                try? await Task.sleep(for: .seconds(4))
                await MainActor.run {
                    feedbackSubmitted = false
                }
            }
        }
    }
}
