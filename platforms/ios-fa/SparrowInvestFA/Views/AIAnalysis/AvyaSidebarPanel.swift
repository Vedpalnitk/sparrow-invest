import SwiftUI

/// Compact Avya AI chat panel pinned to the right edge of iPad, toggleable with Cmd+K.
struct AvyaSidebarPanel: View {
    @StateObject private var chatStore = AvyaChatStore()
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            panelHeader

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatStore.messages.isEmpty {
                            compactWelcome
                        }

                        ForEach(chatStore.messages) { message in
                            compactBubble(message)
                                .id(message.id)
                        }

                        if chatStore.isProcessing {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Thinking...")
                                    .font(AppTheme.Typography.label(iPad ? 15 : 13))
                                    .foregroundColor(.secondary)
                            }
                            .id("typing")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: chatStore.messages.count) { _, _ in
                    withAnimation {
                        if let last = chatStore.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            inputBar
        }
        .frame(width: 360)
        .background(
            colorScheme == .dark
                ? Color(uiColor: .secondarySystemBackground)
                : Color(uiColor: .systemBackground)
        )
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ZStack {
                Circle()
                    .fill(AppTheme.avyaGradient)
                    .frame(width: 28, height: 28)
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }

            Text("Avya AI")
                .font(AppTheme.Typography.headline(iPad ? 18 : 15))
                .foregroundColor(.primary)

            Spacer()

            Button {
                chatStore.clearMessages()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Button {
                coordinator.showAvyaChat = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Compact Welcome

    private var compactWelcome: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.avyaGradient)

            Text("Ask Avya anything")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            Text("Portfolio analysis, client insights, market research")
                .font(AppTheme.Typography.label(iPad ? 15 : 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Quick suggestions
            VStack(spacing: 6) {
                quickSuggestion("Top performing clients?")
                quickSuggestion("SIP opportunities today?")
                quickSuggestion("Portfolio risk summary")
            }
            .padding(.top, 4)
        }
        .padding(.vertical, AppTheme.Spacing.large)
    }

    private func quickSuggestion(_ text: String) -> some View {
        Button {
            messageText = text
            sendMessage()
        } label: {
            Text(text)
                .font(AppTheme.Typography.label(iPad ? 16 : 14))
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compact Bubble

    private func compactBubble(_ message: AvyaChatMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
                Text(message.content)
                    .font(AppTheme.Typography.body(iPad ? 16 : 14))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(AppTheme.avyaBubbleGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(AppTheme.Typography.body(iPad ? 16 : 14))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
                .padding(10)
                .background(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color(uiColor: .tertiarySystemFill)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask Avya...", text: $messageText)
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.secondary.opacity(0.4)
                            : AppTheme.avyaIndigo
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Send

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        messageText = ""
        Task {
            try? await chatStore.sendMessage(trimmed)
        }
    }
}
