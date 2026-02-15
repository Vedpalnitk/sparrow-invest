import SwiftUI

struct AddNoteSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    let clientId: String?
    let prospectId: String?
    @ObservedObject var store: NotesStore
    var onProspectNoteAdded: ((MeetingNote) -> Void)?

    @State private var title = ""
    @State private var content = ""
    @State private var meetingType: MeetingType = .call
    @State private var meetingDate = Date()
    @State private var isSaving = false

    // Client init
    init(clientId: String, store: NotesStore) {
        self.clientId = clientId
        self.prospectId = nil
        self.store = store
        self.onProspectNoteAdded = nil
    }

    // Prospect init
    init(prospectId: String, store: NotesStore, onNoteAdded: @escaping (MeetingNote) -> Void) {
        self.clientId = nil
        self.prospectId = prospectId
        self.store = store
        self.onProspectNoteAdded = onNoteAdded
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Meeting Details
                    sectionCard(title: "Meeting Details", icon: "calendar") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            // Title
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title")
                                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                    .foregroundColor(.secondary)

                                TextField("e.g. Portfolio Review", text: $title)
                                    .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                    .textFieldStyle(.plain)
                                    .padding(AppTheme.Spacing.compact)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                                    )
                            }

                            // Date
                            DatePicker(
                                "Meeting Date",
                                selection: $meetingDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .font(AppTheme.Typography.body(iPad ? 16 : 14))

                            // Meeting Type
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Type")
                                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Spacing.small) {
                                        ForEach(MeetingType.allCases, id: \.self) { type in
                                            Button {
                                                meetingType = type
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: type.icon)
                                                        .font(.system(size: 11))
                                                    Text(type.label)
                                                        .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                                                }
                                                .foregroundColor(meetingType == type ? .white : type.color)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    meetingType == type
                                                        ? AnyShapeStyle(type.color)
                                                        : AnyShapeStyle(type.color.opacity(0.12))
                                                )
                                                .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Notes Content
                    sectionCard(title: "Notes", icon: "note.text") {
                        TextEditor(text: $content)
                            .font(AppTheme.Typography.body(iPad ? 16 : 14))
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .padding(AppTheme.Spacing.compact)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                            )
                    }

                    // Save Button
                    Button {
                        saveNote()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Save Note")
                                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.primaryGradient)
                        .clipShape(Capsule())
                        .opacity(isValid ? 1 : 0.5)
                    }
                    .disabled(!isValid || isSaving)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.large)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Add Meeting Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                }

                Text(title)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Save

    private func saveNote() {
        isSaving = true

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: meetingDate)

        let request = CreateNoteRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            meetingType: meetingType.rawValue,
            meetingDate: dateString
        )

        if let clientId {
            Task {
                let success = await store.createNote(clientId: clientId, request: request)
                isSaving = false
                if success { dismiss() }
            }
        } else if let prospectId {
            let note = store.addProspectNote(prospectId: prospectId, request: request)
            onProspectNoteAdded?(note)
            isSaving = false
            dismiss()
        }
    }
}
