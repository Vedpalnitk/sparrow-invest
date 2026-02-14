import SwiftUI

@MainActor
class CommunicationStore: ObservableObject {
    @Published var stats: CommunicationStats?
    @Published var logs: [CommunicationLog] = []
    @Published var templates: [CommunicationTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Pagination
    @Published var total = 0
    @Published var page = 1
    @Published var totalPages = 1

    // Filters
    @Published var channelFilter: String?
    @Published var typeFilter: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Load stats, history, and templates
        async let statsTask: () = loadStats()
        async let historyTask: () = loadHistory()
        async let templatesTask: () = loadTemplates()

        _ = await (statsTask, historyTask, templatesTask)
        isLoading = false
    }

    private func loadStats() async {
        do {
            stats = try await APIService.shared.get("/communications/history/stats")
        } catch {
            // Stats may not be available yet
        }
    }

    func loadHistory(page: Int = 1) async {
        do {
            var endpoint = "/communications/history?page=\(page)&limit=20"
            if let channel = channelFilter {
                endpoint += "&channel=\(channel)"
            }
            if let type = typeFilter {
                endpoint += "&type=\(type)"
            }
            let response: PaginatedCommunicationResponse = try await APIService.shared.get(endpoint)
            logs = response.data
            total = response.total
            self.page = response.page
            totalPages = response.totalPages
        } catch {
            if page == 1 {
                logs = []
            }
        }
    }

    func loadTemplates() async {
        do {
            templates = try await APIService.shared.get("/communications/templates")
        } catch {
            // Templates may not be available
        }
    }

    func preview(clientId: String, type: String) async -> CommunicationPreview? {
        do {
            let request = PreviewCommunicationRequest(clientId: clientId, type: type)
            let preview: CommunicationPreview = try await APIService.shared.post("/communications/preview", body: request)
            return preview
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func send(clientId: String, channel: String, type: String, subject: String, body: String) async -> CommunicationSendResult? {
        do {
            let request = SendCommunicationRequest(
                clientId: clientId, channel: channel,
                type: type, subject: subject, body: body
            )
            let result: CommunicationSendResult = try await APIService.shared.post("/communications/send", body: request)
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func sendBulk(clientIds: [String], channel: String, type: String) async -> BulkSendResult? {
        do {
            let request = BulkSendRequest(
                clientIds: clientIds, channel: channel,
                type: type, subject: nil, customBody: nil
            )
            let result: BulkSendResult = try await APIService.shared.post("/communications/send-bulk", body: request)
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
