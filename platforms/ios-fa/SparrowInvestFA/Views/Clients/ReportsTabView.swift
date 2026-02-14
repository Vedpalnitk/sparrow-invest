import SwiftUI

struct ReportsTabView: View {
    let client: FAClientDetail
    @Environment(\.colorScheme) private var colorScheme

    @State private var isGenerating = false
    @State private var generatingReport = ""
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.compact),
        GridItem(.flexible(), spacing: AppTheme.Spacing.compact)
    ]

    private var reportTypes: [(type: String, icon: String, color: Color, description: String)] {
        [
            ("Portfolio Summary", "doc.text.chart.fill", AppTheme.primary, "Complete overview of holdings, allocation and performance"),
            ("Performance Report", "chart.line.uptrend.xyaxis", AppTheme.success, "Detailed returns analysis with benchmarks"),
            ("Tax Statement", "indianrupeesign.circle.fill", AppTheme.info, "Capital gains and tax-relevant transactions"),
            ("Transaction Statement", "list.bullet.rectangle.fill", AppTheme.warning, "Full history of all transactions")
        ]
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Section Header
            HStack {
                Text("Generate Reports")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.medium)

            // Report Types Grid
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
            .padding(.horizontal, AppTheme.Spacing.medium)
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

    // MARK: - Report Card

    private func reportCard(type: String, icon: String, color: Color, description: String) -> some View {
        let isCurrentlyGenerating = isGenerating && generatingReport == type

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            // Title
            Text(type)
                .font(AppTheme.Typography.accent(13))
                .foregroundColor(.primary)
                .lineLimit(1)

            // Description
            Text(description)
                .font(AppTheme.Typography.label(11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Generate Button
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

                    Text(isCurrentlyGenerating ? "Generating..." : "Generate")
                        .font(AppTheme.Typography.accent(12))
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

    // MARK: - Generate Report

    private func generateReport(type: String) {
        isGenerating = true
        generatingReport = type

        DispatchQueue.global(qos: .userInitiated).async {
            let url = PdfReportGenerator.generate(type: type, client: client)

            DispatchQueue.main.async {
                isGenerating = false
                generatingReport = ""

                if let url = url {
                    pdfURL = url
                    showShareSheet = true
                } else {
                    errorMessage = "Could not generate \(type). Please try again."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ScrollView {
        ReportsTabView(client: FAClientDetail(
            id: "1", name: "Priya Patel", email: "priya@demo.com",
            phone: "+919876543210", aum: 2_450_000, returns: 12.5,
            holdings: [
                Holding(id: "h1", fundName: "HDFC Mid-Cap Opportunities", currentValue: 500000, investedValue: 400000, returns: 100000, returnsPercentage: 25.0),
                Holding(id: "h2", fundName: "Axis Bluechip Fund", currentValue: 300000, investedValue: 280000, returns: 20000, returnsPercentage: 7.14)
            ],
            sips: [
                FASip(id: "s1", fundName: "HDFC Mid-Cap", amount: 10000)
            ],
            recentTransactions: [
                FATransaction(id: "t1", clientId: "1", clientName: "Priya Patel", fundName: "HDFC Mid-Cap", type: "Buy", amount: 50000, status: "Completed", date: "2025-01-15")
            ]
        ))
    }
}
