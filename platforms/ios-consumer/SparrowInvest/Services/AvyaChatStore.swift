//
//  AvyaChatStore.swift
//  SparrowInvest
//
//  State management for Avya AI chatbot with voice support
//

import Foundation
#if os(iOS)
import AVFoundation
#endif

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

struct TranscriptionResponse: Codable {
    let text: String
    let language: String?
    let duration: Double?
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
    var audioUrl: String?

    static func == (lhs: AvyaChatMessage, rhs: AvyaChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Logout Notification

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}

// MARK: - AvyaChatStore

@MainActor
class AvyaChatStore: ObservableObject {
    @Published var messages: [AvyaChatMessage] = []
    @Published var isProcessing = false
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var currentSessionId: String?
    @Published var errorMessage: String?
    @Published var speakResponses = false

    #if os(iOS)
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioPlayerDelegate: AudioPlayerDelegate?
    #endif
    private var pollingTimer: Timer?
    private var pendingMessageId: String?
    private var logoutObserver: NSObjectProtocol?

    private let pollingInterval: TimeInterval = 0.5
    private let maxPollingAttempts = 120 // 60 seconds max

    init() {
        setupAudioSession()
        // Clear chat data when user logs out to prevent cross-user data leakage
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clearMessages()
            }
        }
    }

    deinit {
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }

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

        // Create session if needed
        if currentSessionId == nil {
            _ = try await createSession()
        }

        guard let sessionId = currentSessionId else {
            throw ChatError.noSession
        }

        // Add user message to UI
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
            // Send to backend
            let request = SendMessageRequest(
                sessionId: sessionId,
                content: content,
                speakResponse: speakResponses
            )

            let data = try await APIService.shared.post("/chat/messages", body: request)
            let decoder = JSONDecoder()
            let response = try decoder.decode(ChatMessageResponse.self, from: data)

            // Start polling for response
            pendingMessageId = response.messageId
            startPolling()
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription

            // Add error message
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
                        timestamp: Date(),
                        audioUrl: status.audioUrl
                    )
                    messages.append(aiMessage)

                    // Auto-play audio if speaking is enabled
                    if speakResponses, let audioUrl = status.audioUrl {
                        try? await playAudio(from: audioUrl)
                    }
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
            // Silently continue polling on network errors
            print("Polling error: \(error)")
        }
    }

    // MARK: - Voice Recording

    #if os(iOS)
    func startRecording() throws {
        let audioFilename = getRecordingURL()

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            throw ChatError.recordingFailed(error.localizedDescription)
        }
    }

    func stopRecording() async throws -> String {
        guard let recorder = audioRecorder, recorder.isRecording else {
            throw ChatError.notRecording
        }

        recorder.stop()
        isRecording = false

        let audioURL = recorder.url

        // Transcribe audio
        let transcription = try await transcribeAudio(at: audioURL)

        // Clean up recording file
        try? FileManager.default.removeItem(at: audioURL)

        return transcription
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        // Clean up recording file
        if let url = audioRecorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func getRecordingURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("avya_recording.wav")
    }
    #endif

    private func transcribeAudio(at url: URL) async throws -> String {
        let audioData = try Data(contentsOf: url)

        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        // Make request
        let baseURL = getBaseURL()
        let url = URL(string: "\(baseURL)/chat/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ChatError.transcriptionFailed
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(TranscriptionResponse.self, from: data)
        return result.text
    }

    // MARK: - TTS Playback

    #if os(iOS)
    func speakMessage(_ message: AvyaChatMessage) async throws {
        if let audioUrl = message.audioUrl {
            try await playAudio(from: audioUrl)
        } else {
            // Generate audio on demand
            let encodedText = message.content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let baseURL = getBaseURL()
            let url = "\(baseURL)/chat/synthesize?text=\(encodedText)&voice=avya_voice"
            try await playAudio(from: url)
        }
    }

    func playAudio(from urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw ChatError.invalidAudioURL
        }

        isSpeaking = true

        do {
            var request = URLRequest(url: url)
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let (data, _) = try await URLSession.shared.data(for: request)

            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayerDelegate = AudioPlayerDelegate { [weak self] in
                Task { @MainActor in
                    self?.isSpeaking = false
                }
            }
            audioPlayer?.delegate = audioPlayerDelegate
            audioPlayer?.play()
        } catch {
            isSpeaking = false
            throw ChatError.audioPlaybackFailed(error.localizedDescription)
        }
    }

    func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioPlayerDelegate = nil
        isSpeaking = false
    }
    #endif

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

    private func getBaseURL() -> String {
        #if DEBUG
        return "http://localhost:3501/api/v1"
        #else
        return "https://api.sparrow-invest.com/api/v1"
        #endif
    }
}

// MARK: - Audio Player Delegate

#if os(iOS)
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion()
    }
}
#endif

// MARK: - Chat Errors

enum ChatError: LocalizedError {
    case noSession
    case recordingFailed(String)
    case notRecording
    case transcriptionFailed
    case invalidAudioURL
    case audioPlaybackFailed(String)

    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No chat session available"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .notRecording:
            return "Not currently recording"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .invalidAudioURL:
            return "Invalid audio URL"
        case .audioPlaybackFailed(let message):
            return "Audio playback failed: \(message)"
        }
    }
}
