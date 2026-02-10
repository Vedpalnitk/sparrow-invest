//
//  AvyaChatStore.swift
//  SparrowInvestFA
//
//  State management for Avya AI chatbot (text-only)
//

import Foundation

// MARK: - Chat Models

struct ChatSession: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String?
    let isActive: Bool
    let createdAt: String
}

struct ChatMessageResponse: Codable {
    let messageId: String
    let status: String
    let content: String?
    let audioUrl: String?
    let error: String?
    let createdAt: String?
}

struct ChatMessageStatus: Codable {
    let messageId: String
    let status: String
    let content: String?
    let audioUrl: String?
    let error: String?
}

struct ChatHistoryMessage: Codable, Identifiable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
}

// MARK: - Request DTOs

struct CreateSessionRequest: Codable {
    let title: String?
}

struct SendMessageRequest: Codable {
    let sessionId: String
    let content: String
    let speakResponse: Bool?
}

// MARK: - Chat Message UI Model

struct AvyaChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date

    static func == (lhs: AvyaChatMessage, rhs: AvyaChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - AvyaChatStore

@MainActor
class AvyaChatStore: ObservableObject {
    @Published var messages: [AvyaChatMessage] = []
    @Published var isProcessing = false
    @Published var currentSessionId: String?
    @Published var errorMessage: String?

    private var pollingTimer: Timer?
    private var pendingMessageId: String?

    private let pollingInterval: TimeInterval = 0.5
    private let maxPollingAttempts = 120

    // MARK: - Session Management

    func createSession(title: String? = nil) async throws -> String {
        let request = CreateSessionRequest(title: title)
        let data = try await APIService.shared.post("/chat/sessions", body: request)
        let decoder = JSONDecoder()
        let session = try decoder.decode(ChatSession.self, from: data)
        currentSessionId = session.id
        messages = []
        return session.id
    }

    func loadSession(_ sessionId: String) async throws {
        currentSessionId = sessionId
        let data: Data = try await APIService.shared.get("/chat/sessions/\(sessionId)/messages")
        let decoder = JSONDecoder()
        let history = try decoder.decode([ChatHistoryMessage].self, from: data)

        messages = history.map { msg in
            AvyaChatMessage(
                id: msg.id,
                content: msg.content,
                isUser: msg.role == "user",
                timestamp: ISO8601DateFormatter().date(from: msg.createdAt) ?? Date()
            )
        }
    }

    // MARK: - Message Sending

    func sendMessage(_ content: String) async throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if currentSessionId == nil {
            _ = try await createSession()
        }

        guard let sessionId = currentSessionId else {
            throw ChatError.noSession
        }

        let userMessage = AvyaChatMessage(
            id: UUID().uuidString,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)

        isProcessing = true
        errorMessage = nil

        do {
            let request = SendMessageRequest(
                sessionId: sessionId,
                content: content,
                speakResponse: false
            )

            let data = try await APIService.shared.post("/chat/messages", body: request)
            let decoder = JSONDecoder()
            let response = try decoder.decode(ChatMessageResponse.self, from: data)

            pendingMessageId = response.messageId
            startPolling()
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription

            let errorMsg = AvyaChatMessage(
                id: UUID().uuidString,
                content: "Sorry, I couldn't process your request. Please try again.",
                isUser: false,
                timestamp: Date()
            )
            messages.append(errorMsg)
            throw error
        }
    }

    // MARK: - Polling

    private func startPolling() {
        var attempts = 0

        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            attempts += 1

            if attempts >= self.maxPollingAttempts {
                timer.invalidate()
                Task { @MainActor in
                    self.isProcessing = false
                    self.errorMessage = "Response timed out"
                    let timeoutMsg = AvyaChatMessage(
                        id: UUID().uuidString,
                        content: "Sorry, the response took too long. Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    self.messages.append(timeoutMsg)
                }
                return
            }

            Task {
                await self.pollMessageStatus()
            }
        }
    }

    private func pollMessageStatus() async {
        guard let messageId = pendingMessageId else { return }

        do {
            let data: Data = try await APIService.shared.get("/chat/messages/\(messageId)/status")
            let decoder = JSONDecoder()
            let status = try decoder.decode(ChatMessageStatus.self, from: data)

            if status.status == "complete" {
                pollingTimer?.invalidate()
                pollingTimer = nil
                pendingMessageId = nil
                isProcessing = false

                if let content = status.content {
                    let aiMessage = AvyaChatMessage(
                        id: messageId,
                        content: content,
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(aiMessage)
                }
            } else if status.status == "error" {
                pollingTimer?.invalidate()
                pollingTimer = nil
                pendingMessageId = nil
                isProcessing = false
                errorMessage = status.error

                let errorMsg = AvyaChatMessage(
                    id: messageId,
                    content: status.error ?? "An error occurred.",
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(errorMsg)
            }
        } catch {
            print("Polling error: \(error)")
        }
    }

    // MARK: - Helpers

    func clearMessages() {
        messages = []
        currentSessionId = nil
        errorMessage = nil
        stopPolling()
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        pendingMessageId = nil
    }
}

// MARK: - Chat Errors

enum ChatError: LocalizedError {
    case noSession

    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No chat session available"
        }
    }
}
