import SwiftUI

struct ProspectsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var searchQuery = ""
    @State private var selectedStage: ProspectStage?
    @State private var showAddToast = false
    @State private var prospects = MockProspects.prospects
    @State private var selectedProspect: FAProspect?

    private var filteredProspects: [FAProspect] {
        prospects.filter { prospect in
            let matchesSearch = searchQuery.isEmpty ||
                prospect.name.localizedCaseInsensitiveContains(searchQuery) ||
                prospect.email.localizedCaseInsensitiveContains(searchQuery)
            let matchesStage = selectedStage == nil || prospect.stage == selectedStage
            return matchesSearch && matchesStage
        }
    }

    private let activeStages: [ProspectStage] = [
        .discovery, .analysis, .proposal, .negotiation
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        // Pipeline Summary
                        pipelineSummary

                        // Search
                        searchBar

                        // Stage Filters
                        stageFilters

                        // Prospect List
                        if filteredProspects.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: AppTheme.Spacing.small) {
                                ForEach(filteredProspects) { prospect in
                                    Button {
                                        selectedProspect = prospect
                                    } label: {
                                        prospectRow(prospect)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Prospects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showAddToast = false
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.primaryGradient)
                            .clipShape(Circle())
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showAddToast {
                    Text("Add Prospect coming soon")
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.compact)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .padding(.bottom, AppTheme.Spacing.large)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: showAddToast)
                }
            }
            .sheet(item: $selectedProspect) { prospect in
                ProspectDetailSheet(
                    prospect: prospect,
                    onSave: { updated in
                        if let index = prospects.firstIndex(where: { $0.id == updated.id }) {
                            prospects[index] = updated
                        }
                        selectedProspect = nil
                    }
                )
            }
        }
    }

    // MARK: - Pipeline Summary

    private var pipelineSummary: some View {
        let activeProspects = prospects.filter {
            $0.stage != .closedWon && $0.stage != .closedLost
        }
        let totalPipelineValue = activeProspects.reduce(0.0) { $0 + $1.potentialAum }

        let stageCounts: [(String, Int)] = [
            ("Discovery", activeProspects.filter { $0.stage == .discovery }.count),
            ("Analysis", activeProspects.filter { $0.stage == .analysis }.count),
            ("Proposal", activeProspects.filter { $0.stage == .proposal }.count),
            ("Negotiation", activeProspects.filter { $0.stage == .negotiation }.count)
        ]

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Pipeline Overview")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            Text(AppTheme.formatCurrencyWithSymbol(totalPipelineValue))
                .font(AppTheme.Typography.numeric(iPad ? 32 : 28))
                .foregroundColor(AppTheme.primary)

            Text("\(activeProspects.count) active prospects")
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.secondary)

            HStack {
                ForEach(stageCounts, id: \.0) { stage, count in
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                            .foregroundColor(.primary)
                        Text(stage)
                            .font(AppTheme.Typography.label(iPad ? 13 : 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            TextField("Search prospects...", text: $searchQuery)
                .font(AppTheme.Typography.body(iPad ? 17 : 15))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Stage Filters

    private var stageFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                Button {
                    selectedStage = nil
                } label: {
                    Text("All")
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(selectedStage == nil ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedStage == nil
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(activeStages, id: \.self) { stage in
                    Button {
                        selectedStage = stage
                    } label: {
                        Text(stage.label)
                            .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                            .foregroundColor(selectedStage == stage ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedStage == stage
                                    ? AnyShapeStyle(AppTheme.primaryGradient)
                                    : AnyShapeStyle(Color.clear)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
            )
        }
    }

    // MARK: - Prospect Row

    private func prospectRow(_ prospect: FAProspect) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(prospect.name)
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                stageBadge(prospect.stage)
            }

            Text(prospect.email)
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Potential AUM")
                        .font(AppTheme.Typography.label(iPad ? 13 : 10))
                        .foregroundColor(.secondary)
                    Text(AppTheme.formatCurrencyWithSymbol(prospect.potentialAum))
                        .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                        .foregroundColor(AppTheme.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next action")
                        .font(AppTheme.Typography.label(iPad ? 13 : 10))
                        .foregroundColor(.secondary)
                    Text(prospect.nextActionDate)
                        .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                        .foregroundColor(.primary)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Stage Badge

    private func stageBadge(_ stage: ProspectStage) -> some View {
        let color = stageColor(stage)
        return Text(stage.label.uppercased())
            .font(AppTheme.Typography.label(iPad ? 11 : 9))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func stageColor(_ stage: ProspectStage) -> Color {
        switch stage {
        case .discovery: return AppTheme.secondary
        case .analysis: return AppTheme.primary
        case .proposal: return AppTheme.warning
        case .negotiation: return AppTheme.info
        case .closedWon: return AppTheme.success
        case .closedLost: return AppTheme.error
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer().frame(height: AppTheme.Spacing.xxLarge)

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No prospects found")
                .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                .foregroundColor(.primary)

            Text("Try adjusting your search or filters")
                .font(AppTheme.Typography.caption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Prospect Detail Sheet

struct ProspectDetailSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @Environment(\.dismiss) private var dismiss

    let prospect: FAProspect
    let onSave: (FAProspect) -> Void

    @State private var newStage: ProspectStage
    @StateObject private var notesStore = NotesStore()
    @State private var showAddNote = false
    @State private var localMeetingNotes: [MeetingNote] = []

    init(prospect: FAProspect, onSave: @escaping (FAProspect) -> Void) {
        self.prospect = prospect
        self.onSave = onSave
        self._newStage = State(initialValue: prospect.stage)
        self._localMeetingNotes = State(initialValue: prospect.meetingNotes)
    }

    private var stageChanged: Bool {
        newStage != prospect.stage
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    // Header: name + current stage
                    HStack {
                        Text(prospect.name)
                            .font(AppTheme.Typography.headline(iPad ? 26 : 22))
                            .foregroundColor(.primary)

                        Spacer()

                        currentStageBadge
                    }

                    // Info card
                    infoCard

                    // Stage selector
                    stageSelector

                    // Next action & notes
                    notesCard
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.large)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Prospect Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = FAProspect(
                            id: prospect.id,
                            name: prospect.name,
                            email: prospect.email,
                            phone: prospect.phone,
                            potentialAum: prospect.potentialAum,
                            stage: newStage,
                            source: prospect.source,
                            nextAction: prospect.nextAction,
                            nextActionDate: prospect.nextActionDate,
                            notes: prospect.notes,
                            probability: prospect.probability,
                            meetingNotes: notesStore.notes
                        )
                        onSave(updated)
                    }
                    .disabled(!stageChanged && notesStore.notes.count == prospect.meetingNotes.count)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Current Stage Badge

    private var currentStageBadge: some View {
        let color = stageColor(prospect.stage)
        return Text(prospect.stage.label.uppercased())
            .font(AppTheme.Typography.label(iPad ? 11 : 9))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            detailRow(label: "Email", value: prospect.email)
            detailRow(label: "Phone", value: prospect.phone)
            detailRow(label: "Source", value: prospect.source.label)
            detailRow(label: "Potential AUM", value: AppTheme.formatCurrencyWithSymbol(prospect.potentialAum))
            detailRow(label: "Probability", value: "\(prospect.probability)%")
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: - Stage Selector

    private var stageSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Change Stage")
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(ProspectStage.allCases, id: \.self) { stage in
                        Button {
                            newStage = stage
                        } label: {
                            let color = stageColor(stage)
                            Text(stage.label)
                                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                .foregroundColor(newStage == stage ? .white : color)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    newStage == stage
                                        ? AnyShapeStyle(color)
                                        : AnyShapeStyle(color.opacity(0.12))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Notes Card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            detailRow(label: "Next Action", value: prospect.nextAction)
            detailRow(label: "Due Date", value: prospect.nextActionDate)

            VStack(alignment: .leading, spacing: 4) {
                Text("Summary")
                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                    .foregroundColor(.secondary)
                Text(prospect.notes)
                    .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                    .foregroundColor(.primary)
            }

            Divider().padding(.vertical, 4)

            // Meeting Notes
            HStack {
                Text("Meeting Notes (\(notesStore.notes.count))")
                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showAddNote = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Add")
                            .font(AppTheme.Typography.accent(iPad ? 13 : 11))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                }
            }

            if notesStore.notes.isEmpty {
                Text("No meeting notes yet")
                    .font(AppTheme.Typography.caption(iPad ? 14 : 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.small)
            } else {
                ForEach(notesStore.notes) { note in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                        Image(systemName: note.meetingType.icon)
                            .font(.system(size: 11))
                            .foregroundColor(note.meetingType.color)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title)
                                .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(note.content)
                                .font(AppTheme.Typography.caption(iPad ? 13 : 11))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(formatNoteDate(note.meetingDate))
                            .font(AppTheme.Typography.label(iPad ? 11 : 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        .task {
            notesStore.loadProspectNotes(prospectId: prospect.id, existing: localMeetingNotes)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(prospectId: prospect.id, store: notesStore) { newNote in
                localMeetingNotes.insert(newNote, at: 0)
            }
        }
    }

    private func formatNoteDate(_ isoDate: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: isoDate) {
            let out = DateFormatter()
            out.dateFormat = "dd MMM"
            return out.string(from: date)
        }
        return String(isoDate.prefix(10))
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.primary)
        }
    }

    private func stageColor(_ stage: ProspectStage) -> Color {
        switch stage {
        case .discovery: return AppTheme.secondary
        case .analysis: return AppTheme.primary
        case .proposal: return AppTheme.warning
        case .negotiation: return AppTheme.info
        case .closedWon: return AppTheme.success
        case .closedLost: return AppTheme.error
        }
    }
}
