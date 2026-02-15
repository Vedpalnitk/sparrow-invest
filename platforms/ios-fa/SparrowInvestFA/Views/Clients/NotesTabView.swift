import SwiftUI

struct NotesTabView: View {
    let clientId: String
    @StateObject private var store = NotesStore()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var showAddNote = false
    @State private var expandedNoteId: String?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Header
            HStack {
                Text("Meeting Notes (\(store.notes.count))")
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showAddNote = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Note")
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xxxLarge)
            } else if store.notes.isEmpty {
                emptyState
            } else {
                ForEach(store.notes) { note in
                    noteCard(note)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(clientId: clientId, store: store)
        }
        .task {
            await store.loadNotes(clientId: clientId)
        }
    }

    // MARK: - Note Card

    private func noteCard(_ note: MeetingNote) -> some View {
        let isExpanded = expandedNoteId == note.id

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(note.meetingType.color.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: note.meetingType.icon)
                        .font(.system(size: 13))
                        .foregroundColor(note.meetingType.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(note.title)
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(note.meetingType.label)
                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                        .foregroundColor(note.meetingType.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(note.meetingType.color.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(formatDate(note.meetingDate))
                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                    .foregroundColor(.secondary)
            }

            // Content
            Text(note.content)
                .font(AppTheme.Typography.body(iPad ? 15 : 13))
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 3)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedNoteId = isExpanded ? nil : note.id
                    }
                }
        }
        .padding(.leading, 4)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(note.meetingType.color)
                .frame(width: 4)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    _ = await store.deleteNote(clientId: clientId, noteId: note.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No meeting notes")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Tap \"Add Note\" to record your client interactions")
                .font(AppTheme.Typography.body(iPad ? 16 : 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }

    // MARK: - Helpers

    private func formatDate(_ isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: isoDate) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM yyyy"
            return out.string(from: date)
        }
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        if let date = dateOnly.date(from: String(isoDate.prefix(10))) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM yyyy"
            return out.string(from: date)
        }
        return isoDate
    }
}
