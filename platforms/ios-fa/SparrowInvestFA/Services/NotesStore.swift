import SwiftUI

@MainActor
class NotesStore: ObservableObject {
    @Published var notes: [MeetingNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Client Notes (API-backed)

    func loadNotes(clientId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            notes = try await APIService.shared.get("/clients/\(clientId)/notes")
        } catch {
            #if DEBUG
            if notes.isEmpty {
                notes = synthesizeNotes(clientId: clientId)
            }
            #else
            errorMessage = error.localizedDescription
            #endif
        }

        isLoading = false
    }

    func createNote(clientId: String, request: CreateNoteRequest) async -> Bool {
        do {
            let note: MeetingNote = try await APIService.shared.post("/clients/\(clientId)/notes", body: request)
            notes.insert(note, at: 0)
            return true
        } catch {
            #if DEBUG
            let note = MeetingNote(
                id: UUID().uuidString,
                clientId: clientId,
                prospectId: nil,
                title: request.title,
                content: request.content,
                meetingType: MeetingType(rawValue: request.meetingType) ?? .other,
                meetingDate: request.meetingDate,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            notes.insert(note, at: 0)
            return true
            #else
            errorMessage = error.localizedDescription
            return false
            #endif
        }
    }

    func deleteNote(clientId: String, noteId: String) async -> Bool {
        do {
            try await APIService.shared.delete("/clients/\(clientId)/notes/\(noteId)")
            notes.removeAll { $0.id == noteId }
            return true
        } catch {
            #if DEBUG
            notes.removeAll { $0.id == noteId }
            return true
            #else
            errorMessage = error.localizedDescription
            return false
            #endif
        }
    }

    // MARK: - Prospect Notes (local-only)

    func loadProspectNotes(prospectId: String, existing: [MeetingNote] = []) {
        notes = existing
    }

    func addProspectNote(prospectId: String, request: CreateNoteRequest) -> MeetingNote {
        let note = MeetingNote(
            id: UUID().uuidString,
            clientId: nil,
            prospectId: prospectId,
            title: request.title,
            content: request.content,
            meetingType: MeetingType(rawValue: request.meetingType) ?? .other,
            meetingDate: request.meetingDate,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        notes.insert(note, at: 0)
        return note
    }

    // MARK: - Demo Synthesis

    private func synthesizeNotes(clientId: String) -> [MeetingNote] {
        [
            MeetingNote(
                id: "note-1", clientId: clientId, prospectId: nil,
                title: "Annual Portfolio Review",
                content: "Reviewed overall portfolio performance. Client happy with returns. Discussed increasing SIP in mid-cap funds by 20%. Need to rebalance debt allocation.",
                meetingType: .inPerson,
                meetingDate: "2026-01-15T10:00:00Z",
                createdAt: "2026-01-15T10:30:00Z"
            ),
            MeetingNote(
                id: "note-2", clientId: clientId, prospectId: nil,
                title: "Tax Planning Discussion",
                content: "Discussed ELSS options for Section 80C. Recommended Axis ELSS and Mirae ELSS. Client wants to invest ₹1.5L before March deadline.",
                meetingType: .video,
                meetingDate: "2026-01-28T14:00:00Z",
                createdAt: "2026-01-28T14:45:00Z"
            ),
            MeetingNote(
                id: "note-3", clientId: clientId, prospectId: nil,
                title: "SIP Modification Request",
                content: "Client called to pause SIP in HDFC Small Cap for 3 months due to cash flow constraints. Will resume in April.",
                meetingType: .call,
                meetingDate: "2026-02-05T11:00:00Z",
                createdAt: "2026-02-05T11:15:00Z"
            ),
            MeetingNote(
                id: "note-4", clientId: clientId, prospectId: nil,
                title: "Goal Update - Child Education",
                content: "Updated target amount for child education goal from ₹50L to ₹65L. Added international fund exposure per new plan.",
                meetingType: .email,
                meetingDate: "2026-02-10T09:00:00Z",
                createdAt: "2026-02-10T09:30:00Z"
            )
        ]
    }
}
