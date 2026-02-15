import SwiftUI

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var selectedTab = "Generate"
    @State private var clients: [FAClient] = []
    @State private var selectedClient: FAClient?
    @State private var fromDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var toDate = Date()
    @State private var isLoadingClients = true
    @State private var selectedFormat = "PDF"

    @State private var isGenerating = false
    @State private var generatingReport = ""
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage: String?

    @State private var recentReports: [RecentReport] = []

    private let tabs = ["Generate", "Recent"]
    private let formats = ["PDF", "Excel", "CSV"]

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.compact),
        GridItem(.flexible(), spacing: AppTheme.Spacing.compact)
    ]

    private var reportTypes: [(type: String, icon: String, color: Color, description: String)] {
        [
            ("Portfolio Statement", "doc.text.chart.fill", AppTheme.primary, "Complete overview of holdings, allocation & performance"),
            ("Transaction Report", "list.bullet.rectangle.fill", AppTheme.warning, "Full history of all buy, sell & SIP transactions"),
            ("Capital Gains", "indianrupeesign.circle.fill", AppTheme.info, "STCG & LTCG summary for tax filing"),
            ("Performance Report", "chart.line.uptrend.xyaxis", AppTheme.success, "Detailed returns analysis with benchmarks"),
            ("SIP Summary", "arrow.triangle.2.circlepath", AppTheme.info, "Active, paused & completed SIP details"),
            ("Goal Progress", "target", AppTheme.primary, "Goal-wise investment progress & projections")
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                GlassSegmentedControl(items: tabs, selection: $selectedTab)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.small)

                if selectedTab == "Generate" {
                    generateTabContent
                } else {
                    recentTabContent
                }
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .task {
                await loadClients()
                loadRecentReports()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to generate report")
            }
        }
    }

    // MARK: - Generate Tab

    private var generateTabContent: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.medium) {
                // Client Picker
                clientPickerSection

                // Date Range
                dateRangeSection

                // Format Picker
                formatPickerSection

                // Report Types Grid
                if selectedClient != nil {
                    reportTypesGrid
                } else {
                    selectClientPrompt
                }

                Spacer().frame(height: AppTheme.Spacing.xxxLarge)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }

    // MARK: - Recent Tab

    private var recentTabContent: some View {
        ScrollView {
            if recentReports.isEmpty {
                VStack(spacing: AppTheme.Spacing.medium) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text("No recent reports")
                        .font(AppTheme.Typography.headline(iPad ? 20 : 17))
                        .foregroundColor(.secondary)

                    Text("Reports you generate will appear here")
                        .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xxxLarge)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.small) {
                    ForEach(recentReports) { report in
                        recentReportRow(report)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xxxLarge)
            }
        }
    }

    private func recentReportRow(_ report: RecentReport) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(reportColor(report.type).opacity(0.1))
                    .frame(width: iPad ? 44 : 40, height: iPad ? 44 : 40)

                Image(systemName: reportIcon(report.type))
                    .font(.system(size: iPad ? 18 : 16))
                    .foregroundColor(reportColor(report.type))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(report.type)
                    .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                    .foregroundColor(.primary)

                Text(report.clientName)
                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                    .foregroundColor(.secondary)

                HStack(spacing: AppTheme.Spacing.small) {
                    Text(report.format)
                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(Capsule())

                    Text(report.formattedDate)
                        .font(AppTheme.Typography.label(iPad ? 12 : 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                shareRecentReport(report)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                    .padding(8)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Format Picker

    private var formatPickerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("FORMAT")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(AppTheme.primary)
                .tracking(0.5)

            HStack(spacing: 0) {
                ForEach(formats, id: \.self) { format in
                    let isSelected = selectedFormat == format
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFormat = format
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: formatIcon(format))
                                .font(.system(size: 10))
                            Text(format)
                                .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                        }
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isSelected
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(2)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(uiColor: .tertiarySystemFill))
            )
        }
    }

    private func formatIcon(_ format: String) -> String {
        switch format {
        case "PDF": return "doc.fill"
        case "Excel": return "tablecells.fill"
        case "CSV": return "list.bullet.rectangle"
        default: return "doc.fill"
        }
    }

    // MARK: - Client Picker

    private var clientPickerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("SELECT CLIENT")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(AppTheme.primary)
                .tracking(0.5)

            if isLoadingClients {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading clients...")
                        .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(AppTheme.Spacing.compact)
                .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
            } else {
                Menu {
                    ForEach(clients) { client in
                        Button {
                            selectedClient = client
                        } label: {
                            HStack {
                                Text(client.name)
                                if selectedClient?.id == client.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.compact) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 36, height: 36)

                            if let client = selectedClient {
                                Text(client.initials)
                                    .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                                    .foregroundColor(AppTheme.primary)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(selectedClient?.name ?? "Choose a client")
                                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                                .foregroundColor(selectedClient != nil ? .primary : .secondary)

                            if let client = selectedClient {
                                Text("AUM: \(client.formattedAum)")
                                    .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(AppTheme.Spacing.compact)
                }
                .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)
            }
        }
    }

    // MARK: - Date Range

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("DATE RANGE")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(AppTheme.primary)
                .tracking(0.5)

            HStack(spacing: AppTheme.Spacing.compact) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $fromDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("To")
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $toDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        }
    }

    // MARK: - Select Client Prompt

    private var selectClientPrompt: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))

            Text("Select a client to generate reports")
                .font(AppTheme.Typography.caption(iPad ? 16 : 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }

    // MARK: - Report Types Grid

    private var reportTypesGrid: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("REPORT TYPE")
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(AppTheme.primary)
                .tracking(0.5)

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.compact) {
                ForEach(reportTypes, id: \.type) { report in
                    reportCard(
                        type: report.type,
                        icon: report.icon,
                        color: report.color,
                        description: report.description
                    )
                }
            }
        }
    }

    // MARK: - Report Card

    private func reportCard(type: String, icon: String, color: Color, description: String) -> some View {
        let isCurrentlyGenerating = isGenerating && generatingReport == type

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(type)
                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(description)
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                generateReport(type: type)
            } label: {
                HStack(spacing: 4) {
                    if isCurrentlyGenerating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11))
                    }

                    Text(isCurrentlyGenerating ? "Generating..." : "Generate \(selectedFormat)")
                        .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(isGenerating)
            .opacity(isGenerating && !isCurrentlyGenerating ? 0.5 : 1.0)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Load Clients

    private func loadClients() async {
        do {
            let response: PaginatedResponse<FAClient> = try await APIService.shared.get("/clients?limit=100")
            clients = response.data
            isLoadingClients = false
        } catch {
            isLoadingClients = false
        }
    }

    // MARK: - Generate Report

    private func generateReport(type: String) {
        guard let client = selectedClient else { return }

        isGenerating = true
        generatingReport = type

        Task {
            do {
                let detail: FAClientDetail = try await APIService.shared.get("/clients/\(client.id)")
                let url = PdfReportGenerator.generate(type: type, client: detail)

                await MainActor.run {
                    isGenerating = false
                    generatingReport = ""

                    if let url = url {
                        pdfURL = url
                        showShareSheet = true

                        // Save to recent reports
                        let recent = RecentReport(
                            type: type,
                            clientName: client.name,
                            clientId: client.id,
                            format: selectedFormat,
                            date: Date(),
                            filePath: url.path
                        )
                        recentReports.insert(recent, at: 0)
                        saveRecentReports()
                    } else {
                        errorMessage = "Could not generate \(type). Please try again."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    generatingReport = ""
                    errorMessage = "Failed to load client data: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    // MARK: - Recent Reports Helpers

    private func reportColor(_ type: String) -> Color {
        switch type {
        case "Portfolio Statement": return AppTheme.primary
        case "Transaction Report": return AppTheme.warning
        case "Capital Gains": return AppTheme.info
        case "Performance Report": return AppTheme.success
        case "SIP Summary": return AppTheme.info
        case "Goal Progress": return AppTheme.primary
        default: return AppTheme.secondary
        }
    }

    private func reportIcon(_ type: String) -> String {
        switch type {
        case "Portfolio Statement": return "doc.text.chart.fill"
        case "Transaction Report": return "list.bullet.rectangle.fill"
        case "Capital Gains": return "indianrupeesign.circle.fill"
        case "Performance Report": return "chart.line.uptrend.xyaxis"
        case "SIP Summary": return "arrow.triangle.2.circlepath"
        case "Goal Progress": return "target"
        default: return "doc.text"
        }
    }

    private func shareRecentReport(_ report: RecentReport) {
        let url = URL(fileURLWithPath: report.filePath)
        if FileManager.default.fileExists(atPath: report.filePath) {
            pdfURL = url
            showShareSheet = true
        } else {
            errorMessage = "Report file no longer available. Please regenerate."
            showError = true
        }
    }

    private func loadRecentReports() {
        guard let data = UserDefaults.standard.data(forKey: "recentReports"),
              let reports = try? JSONDecoder().decode([RecentReport].self, from: data) else {
            return
        }
        recentReports = reports
    }

    private func saveRecentReports() {
        // Keep only the 20 most recent
        let toSave = Array(recentReports.prefix(20))
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: "recentReports")
        }
    }
}

// MARK: - Recent Report Model

struct RecentReport: Identifiable, Codable {
    let id: String
    let type: String
    let clientName: String
    let clientId: String
    let format: String
    let date: Date
    let filePath: String

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }

    init(type: String, clientName: String, clientId: String, format: String, date: Date, filePath: String) {
        self.id = UUID().uuidString
        self.type = type
        self.clientName = clientName
        self.clientId = clientId
        self.format = format
        self.date = date
        self.filePath = filePath
    }
}
