//
//  AIChatView.swift
//  SparrowInvestFA
//
//  Avya - AI Chat interface for Financial Advisors (text-only)
//

import SwiftUI

// MARK: - Spacing & Corner Radius Constants

private enum ChatSpacing {
    static let small: CGFloat = 8
    static let compact: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
}

private enum ChatCornerRadius {
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
}

// MARK: - AI Chat View

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var chatStore = AvyaChatStore()

    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: ChatSpacing.medium) {
                            // Welcome Message
                            if chatStore.messages.isEmpty {
                                WelcomeCard(onQuestionTap: { question in
                                    messageText = question
                                    sendMessage()
                                })
                                    .padding(.top, ChatSpacing.large)
                            }

                            // Messages
                            ForEach(chatStore.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing Indicator
                            if chatStore.isProcessing {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, ChatSpacing.medium)
                        .padding(.bottom, ChatSpacing.medium)
                    }
                    .onChange(of: chatStore.messages.count) { _, _ in
                        withAnimation {
                            if let lastMessage = chatStore.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatStore.isProcessing) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input Area
                ChatInputBar(
                    messageText: $messageText,
                    isProcessing: chatStore.isProcessing,
                    isInputFocused: $isInputFocused,
                    onSend: sendMessage
                )
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Avya")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: clearChat) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Error", isPresented: .constant(chatStore.errorMessage != nil)) {
                Button("OK") {
                    chatStore.errorMessage = nil
                }
            } message: {
                Text(chatStore.errorMessage ?? "")
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let content = messageText
        messageText = ""
        isInputFocused = false

        Task {
            try? await chatStore.sendMessage(content)
        }
    }

    private func clearChat() {
        withAnimation {
            chatStore.clearMessages()
        }
    }
}

// MARK: - Welcome Card

struct WelcomeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let onQuestionTap: (String) -> Void

    let suggestedQuestions = [
        "Give me an overview of my client book",
        "Which clients need portfolio rebalancing?",
        "How is Priya Patel's portfolio doing?",
        "Any goals at risk this quarter?"
    ]

    var body: some View {
        VStack(spacing: ChatSpacing.large) {
            // Avya Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.3, blue: 0.9),
                                Color(red: 0.2, green: 0.5, blue: 1.0),
                                Color(red: 0.0, green: 0.7, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: ChatSpacing.small) {
                Text("Avya")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Your intelligent advisor assistant")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)
            }

            // Suggested Questions
            VStack(alignment: .leading, spacing: ChatSpacing.compact) {
                Text("TRY ASKING")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .tracking(1)

                ForEach(suggestedQuestions, id: \.self) { question in
                    SuggestedQuestionChip(question: question, onTap: {
                        onQuestionTap(question)
                    })
                }
            }
        }
        .padding(ChatSpacing.large)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 12, x: 0, y: 4)
    }

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: ChatCornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: ChatCornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: ChatCornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: ChatCornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.08), location: 0),
                            .init(color: .black.opacity(0.04), location: 0.3),
                            .init(color: .black.opacity(0.02), location: 0.7),
                            .init(color: .black.opacity(0.06), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Suggested Question Chip

struct SuggestedQuestionChip: View {
    let question: String
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: ChatSpacing.small) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.blue)

                Text(question)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, ChatSpacing.compact)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color(UIColor.tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: ChatCornerRadius.medium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: AvyaChatMessage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: ChatSpacing.small) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .padding(.horizontal, ChatSpacing.medium)
                    .padding(.vertical, ChatSpacing.compact)
                    .background(bubbleBackground)

                Text(formatTime(message.timestamp))
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isUser {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationPhase = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: ChatSpacing.small) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1 : 0.5)
                }
            }
            .padding(.horizontal, ChatSpacing.medium)
            .padding(.vertical, ChatSpacing.compact)
            .background(typingBackground)

            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }

    @ViewBuilder
    private var typingBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.1))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @Binding var messageText: String
    var isProcessing: Bool
    @FocusState.Binding var isInputFocused: Bool

    let onSend: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: ChatSpacing.compact) {
                // Text Input
                HStack(spacing: ChatSpacing.small) {
                    TextField("Ask Avya...", text: $messageText, axis: .vertical)
                        .font(.system(size: 15, weight: .regular))
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .disabled(isProcessing)

                    if !messageText.isEmpty {
                        Button(action: { messageText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                }
                .padding(.horizontal, ChatSpacing.medium)
                .padding(.vertical, 10)
                .background(inputBackground)
                .overlay(inputBorder)

                // Send Button
                Button(action: onSend) {
                    ZStack {
                        if messageText.isEmpty || isProcessing {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 1.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                        }

                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(messageText.isEmpty ? .gray : .white)
                        }
                    }
                }
                .disabled(messageText.isEmpty || isProcessing)
            }
            .padding(.horizontal, ChatSpacing.medium)
            .padding(.vertical, ChatSpacing.compact)
            .background(
                colorScheme == .dark
                    ? Color(UIColor.systemBackground)
                    : Color.white
            )
        }
    }

    @ViewBuilder
    private var inputBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.tertiarySystemFill))
        }
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.black.opacity(0.05),
                lineWidth: 1
            )
    }
}

// MARK: - Preview

#Preview {
    AIChatView()
}
