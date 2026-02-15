import SwiftUI

struct AddInsurancePolicySheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    let clientId: String
    @ObservedObject var store: InsuranceStore

    @State private var policyNumber = ""
    @State private var provider = ""
    @State private var selectedType = "TERM_LIFE"
    @State private var sumAssured = ""
    @State private var premiumAmount = ""
    @State private var premiumFrequency = "ANNUAL"
    @State private var startDate = Date()
    @State private var maturityDate = Date()
    @State private var hasMaturityDate = false
    @State private var nominees = ""
    @State private var notes = ""
    @State private var isSaving = false

    private let policyTypes = [
        ("TERM_LIFE", "Term Life"),
        ("WHOLE_LIFE", "Whole Life"),
        ("ENDOWMENT", "Endowment"),
        ("ULIP", "ULIP"),
        ("HEALTH", "Health"),
        ("CRITICAL_ILLNESS", "Critical Illness"),
        ("PERSONAL_ACCIDENT", "Personal Accident"),
        ("OTHER", "Other"),
    ]

    private let frequencies = [
        ("MONTHLY", "Monthly"),
        ("QUARTERLY", "Quarterly"),
        ("HALF_YEARLY", "Half Yearly"),
        ("ANNUAL", "Annual"),
        ("SINGLE", "Single Premium"),
    ]

    private var isValid: Bool {
        !policyNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !provider.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(sumAssured) != nil && Double(sumAssured)! > 0 &&
        Double(premiumAmount) != nil && Double(premiumAmount)! > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Policy Details
                    sectionCard(title: "Policy Details", icon: "doc.text") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            fieldRow(label: "Policy Number", placeholder: "e.g. LIC-87654321", text: $policyNumber)
                            fieldRow(label: "Provider", placeholder: "e.g. LIC, HDFC Life, Star Health", text: $provider)

                            // Type Picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Policy Type")
                                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Spacing.small) {
                                        ForEach(policyTypes, id: \.0) { (value, label) in
                                            Button {
                                                selectedType = value
                                            } label: {
                                                Text(label)
                                                    .font(AppTheme.Typography.accent(iPad ? 14 : 12))
                                                    .foregroundColor(selectedType == value ? .white : AppTheme.primary)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        selectedType == value
                                                            ? AnyShapeStyle(AppTheme.primaryGradient)
                                                            : AnyShapeStyle(AppTheme.primary.opacity(0.1))
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

                    // Coverage & Premium
                    sectionCard(title: "Coverage & Premium", icon: "indianrupeesign.circle") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            fieldRow(label: "Sum Assured (₹)", placeholder: "e.g. 10000000", text: $sumAssured)
                                .keyboardType(.numberPad)
                            fieldRow(label: "Premium Amount (₹)", placeholder: "e.g. 12000", text: $premiumAmount)
                                .keyboardType(.numberPad)

                            // Frequency
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium Frequency")
                                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                    .foregroundColor(.secondary)

                                Picker("Frequency", selection: $premiumFrequency) {
                                    ForEach(frequencies, id: \.0) { (value, label) in
                                        Text(label).tag(value)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }

                    // Dates
                    sectionCard(title: "Dates", icon: "calendar") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                .font(AppTheme.Typography.body(iPad ? 16 : 14))

                            Toggle("Has Maturity Date", isOn: $hasMaturityDate)
                                .font(AppTheme.Typography.body(iPad ? 16 : 14))

                            if hasMaturityDate {
                                DatePicker("Maturity Date", selection: $maturityDate, displayedComponents: .date)
                                    .font(AppTheme.Typography.body(iPad ? 16 : 14))
                            }
                        }
                    }

                    // Optional Info
                    sectionCard(title: "Additional Info", icon: "person.2") {
                        VStack(spacing: AppTheme.Spacing.compact) {
                            fieldRow(label: "Nominees", placeholder: "e.g. Spouse - 100%", text: $nominees)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                    .foregroundColor(.secondary)

                                TextEditor(text: $notes)
                                    .font(AppTheme.Typography.body(iPad ? 16 : 14))
                                    .frame(minHeight: 60)
                                    .scrollContentBackground(.hidden)
                                    .padding(AppTheme.Spacing.compact)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                                    )
                            }
                        }
                    }

                    // Save Button
                    Button {
                        savePolicy()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Save Policy")
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
            .navigationTitle("Add Insurance Policy")
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

    // MARK: - Field Row

    private func fieldRow(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                .foregroundColor(.secondary)

            TextField(placeholder, text: text)
                .font(AppTheme.Typography.body(iPad ? 17 : 15))
                .textFieldStyle(.plain)
                .padding(AppTheme.Spacing.compact)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                )
        }
    }

    // MARK: - Save

    private func savePolicy() {
        isSaving = true

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let request = CreateInsurancePolicyRequest(
            policyNumber: policyNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            provider: provider.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            status: nil,
            sumAssured: Double(sumAssured) ?? 0,
            premiumAmount: Double(premiumAmount) ?? 0,
            premiumFrequency: premiumFrequency,
            startDate: dateFormatter.string(from: startDate),
            maturityDate: hasMaturityDate ? dateFormatter.string(from: maturityDate) : nil,
            nominees: nominees.isEmpty ? nil : nominees,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            let success = await store.createPolicy(clientId: clientId, request: request)
            isSaving = false
            if success {
                await store.loadGapAnalysis(clientId: clientId)
                dismiss()
            }
        }
    }
}
