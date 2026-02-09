//
//  AIChatView.swift
//  SparrowInvest
//
//  Avya - AI Chat interface with voice and text input
//

import SwiftUI

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
                        LazyVStack(spacing: AppTheme.Spacing.medium) {
                            // Welcome Message
                            if chatStore.messages.isEmpty {
                                WelcomeCard(onQuestionTap: { question in
                                    messageText = question
                                    sendMessage()
                                })
                                    .padding(.top, AppTheme.Spacing.large)
                            }

                            // Messages
                            ForEach(chatStore.messages) { message in
                                ChatBubble(
                                    message: message,
                                    onSpeak: {
                                        #if os(iOS)
                                        Task {
                                            try? await chatStore.speakMessage(message)
                                        }
                                        #endif
                                    },
                                    isSpeaking: chatStore.isSpeaking
                                )
                                    .id(message.id)
                            }

                            // Typing Indicator
                            if chatStore.isProcessing {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, AppTheme.Spacing.medium)
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
                    isRecording: chatStore.isRecording,
                    isProcessing: chatStore.isProcessing,
                    speakResponses: $chatStore.speakResponses,
                    isInputFocused: $isInputFocused,
                    onSend: sendMessage,
                    onVoiceToggle: toggleVoiceRecording
                )
            }
            .background(Color(uiColor: .systemGroupedBackground))
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

                        Toggle(isOn: $chatStore.speakResponses) {
                            Label("Speak Responses", systemImage: "speaker.wave.2")
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

    private func toggleVoiceRecording() {
        #if os(iOS)
        if chatStore.isRecording {
            Task {
                do {
                    let transcription = try await chatStore.stopRecording()
                    messageText = transcription
                } catch {
                    chatStore.errorMessage = error.localizedDescription
                }
            }
        } else {
            do {
                try chatStore.startRecording()
            } catch {
                chatStore.errorMessage = error.localizedDescription
            }
        }
        #endif
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
        "How is my portfolio performing?",
        "Should I rebalance my investments?",
        "What tax-saving options do I have?",
        "Recommend funds for my goals"
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
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

            VStack(spacing: AppTheme.Spacing.small) {
                Text("Avya")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Your intelligent portfolio assistant")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)
            }

            // Suggested Questions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
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
        .padding(AppTheme.Spacing.large)
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
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
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
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.blue)

                Text(question)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.horizontal, AppTheme.Spacing.compact)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.06)
                    : Color(uiColor: .tertiarySystemFill),
                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: AvyaChatMessage
    var onSpeak: (() -> Void)?
    var isSpeaking: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.small) {
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
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.compact)
                    .background(bubbleBackground)

                HStack(spacing: 8) {
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))

                    // Speaker button for AI messages
                    if !message.isUser, onSpeak != nil {
                        Button {
                            onSpeak?()
                        } label: {
                            Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                }
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
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.small) {
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
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.compact)
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
    var isRecording: Bool
    var isProcessing: Bool
    @Binding var speakResponses: Bool
    @FocusState.Binding var isInputFocused: Bool

    let onSend: () -> Void
    let onVoiceToggle: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: AppTheme.Spacing.compact) {
                // Voice Button
                Button(action: onVoiceToggle) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isRecording ? .white : .blue)
                            .symbolEffect(.variableColor, isActive: isRecording)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
                .disabled(isProcessing)

                // Text Input
                HStack(spacing: AppTheme.Spacing.small) {
                    TextField("Ask Avya...", text: $messageText, axis: .vertical)
                        .font(.system(size: 15, weight: .regular))
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .disabled(isProcessing || isRecording)

                    if !messageText.isEmpty {
                        Button(action: { messageText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
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
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.compact)
            .background(
                colorScheme == .dark
                    ? Color(uiColor: .systemBackground)
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
                .fill(Color(uiColor: .tertiarySystemFill))
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
