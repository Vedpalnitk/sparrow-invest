//
//  ManualPortfolioEntryView.swift
//  SparrowInvest
//
//  Manual portfolio entry + screenshot upload for self-directed users
//

import SwiftUI
import PhotosUI

struct ManualPortfolioEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0

    // Manual entry fields
    @State private var fundName: String = ""
    @State private var investedAmount: String = ""
    @State private var currentValue: String = ""
    @State private var units: String = ""
    @State private var purchaseDate = Date()

    // Photo upload
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding(AppTheme.Spacing.medium)

                if selectedTab == 0 {
                    manualEntryForm
                } else {
                    screenshotUploadView
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Add Investment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(!isValidEntry)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Manual Entry", "Upload Screenshot"].indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    Text(["Manual Entry", "Upload Screenshot"][index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedTab == index ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == index {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(segmentBackground)
        .overlay(segmentBorder)
        .shadow(color: segmentShadow, radius: 8, x: 0, y: 2)
    }

    // MARK: - Manual Entry Form

    private var manualEntryForm: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Fund Details Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("FUND DETAILS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    VStack(spacing: AppTheme.Spacing.medium) {
                        PortfolioFormField(label: "Fund Name", text: $fundName, placeholder: "e.g., Parag Parikh Flexi Cap")
                        PortfolioFormField(label: "Units", text: $units, placeholder: "e.g., 125.50", keyboardType: .decimalPad)
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                    .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                }

                // Investment Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("INVESTMENT")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    VStack(spacing: AppTheme.Spacing.medium) {
                        PortfolioFormField(label: "Invested Amount", text: $investedAmount, placeholder: "₹", keyboardType: .numberPad)
                        PortfolioFormField(label: "Current Value", text: $currentValue, placeholder: "₹", keyboardType: .numberPad)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Purchase Date")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                    .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                }

                // Return Preview
                if let invested = Double(investedAmount), let current = Double(currentValue), invested > 0 {
                    returnPreview(invested: invested, current: current)
                }
            }
            .padding(AppTheme.Spacing.medium)
        }
    }

    // MARK: - Return Preview

    private func returnPreview(invested: Double, current: Double) -> some View {
        let returnAmount = current - invested
        let returnPercentage = ((current - invested) / invested) * 100
        let isPositive = returnAmount >= 0

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("RETURN PREVIEW")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Return")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text(isPositive ? "+₹\(String(format: "%.0f", returnAmount))" : "-₹\(String(format: "%.0f", abs(returnAmount)))")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(isPositive ? .green : .red)
                        Text("(\(isPositive ? "+" : "")\(String(format: "%.1f", returnPercentage))%)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isPositive ? .green : .red)
                    }
                }

                Spacer()

                Image(systemName: isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isPositive ? .green : .red)
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                (isPositive ? Color.green : Color.red).opacity(colorScheme == .dark ? 0.15 : 0.1),
                in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            )
        }
    }

    // MARK: - Screenshot Upload View

    private var screenshotUploadView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                if let image = selectedImage {
                    // Image Preview
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(AppTheme.CornerRadius.large)

                        if isProcessing {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Processing screenshot...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                Text("Screenshot uploaded successfully")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                Text("We'll extract your portfolio details automatically.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }

                        // Change Photo Button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Choose Different Photo")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                    }
                } else {
                    // Upload Prompt
                    VStack(spacing: AppTheme.Spacing.large) {
                        Spacer()
                            .frame(height: 40)

                        VStack(spacing: AppTheme.Spacing.medium) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "doc.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            }

                            Text("Upload Portfolio Screenshot")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Take a screenshot from your broker app showing your mutual fund holdings")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose Photo")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.large)

                        // Tips
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                            Text("TIPS FOR BEST RESULTS")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                                .tracking(1)

                            VStack(alignment: .leading, spacing: 12) {
                                TipRow(icon: "checkmark.circle.fill", text: "Include fund names and current values")
                                TipRow(icon: "checkmark.circle.fill", text: "Ensure text is clearly visible")
                                TipRow(icon: "checkmark.circle.fill", text: "Crop to show only relevant holdings")
                            }
                            .padding(AppTheme.Spacing.medium)
                            .background(sectionBackground)
                            .overlay(sectionBorder)
                        }
                        .padding(.top, AppTheme.Spacing.medium)

                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.medium)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    isProcessing = true
                    // TODO: Process with OCR/AI
                    try? await Task.sleep(for: .seconds(2))
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - Validation

    private var isValidEntry: Bool {
        if selectedTab == 0 {
            return !fundName.isEmpty && !investedAmount.isEmpty
        } else {
            return selectedImage != nil && !isProcessing
        }
    }

    // MARK: - Actions

    private func saveEntry() {
        // TODO: Save to local storage
        dismiss()
    }

    // MARK: - Styling

    private var sectionShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    private var segmentShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.04)
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color(uiColor: .white))
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }

    @ViewBuilder
    private var segmentBackground: some View {
        if colorScheme == .dark {
            Capsule()
                .fill(Color.black.opacity(0.4))
                .background(Capsule().fill(.ultraThinMaterial))
        } else {
            Capsule().fill(Color.white)
        }
    }

    private var segmentBorder: some View {
        Capsule()
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Portfolio Form Field

private struct PortfolioFormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .keyboardType(keyboardType)
                .padding(14)
                .background(inputBackground)
                .overlay(inputBorder)
        }
    }

    @ViewBuilder
    private var inputBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        }
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
    }
}

// MARK: - Tip Row

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ManualPortfolioEntryView()
}
