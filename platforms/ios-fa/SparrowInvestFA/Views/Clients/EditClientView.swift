import SwiftUI

struct EditClientView: View {
    let clientId: String
    var onClientUpdated: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var pan = ""
    @State private var riskProfile = "Moderate"
    @State private var address = ""

    @State private var isLoadingClient = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage: String?

    let riskProfiles = ["Conservative", "Moderate", "Aggressive", "Very Aggressive"]

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingClient {
                    VStack {
                        Spacer()
                        ProgressView("Loading client...")
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.medium) {
                            // Personal Information Section
                            formSection(
                                title: "Personal Information",
                                subtitle: "Basic client details",
                                icon: "person"
                            ) {
                                formField("NAME", text: $name, icon: "person")
                                formField("EMAIL", text: $email, icon: "envelope", keyboard: .emailAddress)
                                formField("PHONE", text: $phone, icon: "phone", keyboard: .phonePad)
                            }

                            // KYC Details Section
                            formSection(
                                title: "KYC Details",
                                subtitle: "Identity verification",
                                icon: "creditcard"
                            ) {
                                formField("PAN NUMBER", text: $pan, icon: "creditcard")
                            }

                            // Risk Profile Section
                            formSection(
                                title: "Risk Profile",
                                subtitle: "Investment risk tolerance",
                                icon: "shield"
                            ) {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                                    Text("RISK PROFILE")
                                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                        .foregroundColor(AppTheme.primary)

                                    Picker("Risk Profile", selection: $riskProfile) {
                                        ForEach(riskProfiles, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }

                            // Address Section
                            formSection(
                                title: "Address",
                                subtitle: "Correspondence address",
                                icon: "house"
                            ) {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
                                    Text("ADDRESS")
                                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                                        .foregroundColor(AppTheme.primary)

                                    TextEditor(text: $address)
                                        .font(AppTheme.Typography.body(iPad ? 17 : 15))
                                        .frame(minHeight: 80)
                                        .scrollContentBackground(.hidden)
                                        .padding(AppTheme.Spacing.small)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }

                            // Save Button
                            Button {
                                Task { await saveClient() }
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 16))
                                        Text("Save Changes")
                                            .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.primaryGradient)
                                .clipShape(Capsule())
                            }
                            .disabled(name.isEmpty || email.isEmpty || isSaving)
                            .opacity(name.isEmpty || email.isEmpty ? 0.6 : 1.0)
                            .padding(.top, AppTheme.Spacing.small)

                            Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                        }
                        .padding(AppTheme.Spacing.medium)
                    }
                }
            }
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .task { await loadClient() }
        }
    }

    // MARK: - Form Section

    private func formSection<Content: View>(
        title: String, subtitle: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                }
            }

            content()
        }
        .glassCard()
    }

    // MARK: - Form Field

    private func formField(_ label: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.micro) {
            Text(label)
                .font(AppTheme.Typography.label(iPad ? 13 : 11))
                .foregroundColor(AppTheme.primary)

            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                TextField(label.capitalized, text: text)
                    .font(AppTheme.Typography.body(iPad ? 17 : 15))
                    .keyboardType(keyboard)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .frame(height: 48)
            .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: 0)
        }
    }

    // MARK: - Load Client

    private func loadClient() async {
        isLoadingClient = true
        do {
            let client: FAClientDetail = try await APIService.shared.get("/clients/\(clientId)")
            name = client.name
            email = client.email
            phone = client.phone ?? ""
            pan = client.panNumber ?? ""
            riskProfile = client.riskProfile ?? "Moderate"
            address = client.address ?? ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingClient = false
    }

    // MARK: - Save Client

    private func saveClient() async {
        isSaving = true
        do {
            let request = UpdateClientRequest(
                name: name,
                email: email,
                phone: phone.isEmpty ? nil : phone,
                panNumber: pan.isEmpty ? nil : pan,
                riskProfile: riskProfile,
                address: address.isEmpty ? nil : address
            )
            let _: FAClient = try await APIService.shared.put("/clients/\(clientId)", body: request)
            onClientUpdated?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isSaving = false
    }
}
