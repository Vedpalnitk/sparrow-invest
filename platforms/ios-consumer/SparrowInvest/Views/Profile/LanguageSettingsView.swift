import SwiftUI

struct LanguageOption: Identifiable {
    let id: String // language code
    let name: String // English name
    let nativeName: String // Name in native script
}

struct LanguageSettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @Environment(\.colorScheme) private var colorScheme

    private let languages: [LanguageOption] = [
        LanguageOption(id: "en", name: "English", nativeName: "English"),
        LanguageOption(id: "hi", name: "Hindi", nativeName: "\u{0939}\u{093F}\u{0928}\u{094D}\u{0926}\u{0940}"),
        LanguageOption(id: "ta", name: "Tamil", nativeName: "\u{0BA4}\u{0BAE}\u{0BBF}\u{0BB4}\u{0BCD}"),
        LanguageOption(id: "te", name: "Telugu", nativeName: "\u{0C24}\u{0C46}\u{0C32}\u{0C41}\u{0C17}\u{0C41}"),
        LanguageOption(id: "kn", name: "Kannada", nativeName: "\u{0C95}\u{0CA8}\u{0CCD}\u{0CA8}\u{0CA1}"),
        LanguageOption(id: "mr", name: "Marathi", nativeName: "\u{092E}\u{0930}\u{093E}\u{0920}\u{0940}"),
        LanguageOption(id: "bn", name: "Bengali", nativeName: "\u{09AC}\u{09BE}\u{0982}\u{09B2}\u{09BE}"),
        LanguageOption(id: "gu", name: "Gujarati", nativeName: "\u{0A97}\u{0AC1}\u{0A9C}\u{0AB0}\u{0ABE}\u{0AA4}\u{0AC0}")
    ]

    private var sectionShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xLarge) {
                // Language List Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("LANGUAGE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    VStack(spacing: 0) {
                        ForEach(Array(languages.enumerated()), id: \.element.id) { index, language in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedLanguage = language.id
                                }
                            } label: {
                                HStack(spacing: AppTheme.Spacing.medium) {
                                    // Icon Container
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 32, height: 32)

                                        Text(languageFlag(for: language.id))
                                            .font(.system(size: 16))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language.name)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(.primary)

                                        Text(language.nativeName)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if selectedLanguage == language.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.blue)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(AppTheme.Spacing.medium)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if index < languages.count - 1 {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                    .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                }

                // Note Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("NOTE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    HStack(spacing: AppTheme.Spacing.compact) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)

                        Text("Language support coming soon. Currently English only.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(AppTheme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                    .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                }
            }
            .padding(AppTheme.Spacing.medium)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func languageFlag(for code: String) -> String {
        switch code {
        case "en": return "A"
        case "hi": return "\u{0905}"
        case "ta": return "\u{0B85}"
        case "te": return "\u{0C05}"
        case "kn": return "\u{0C85}"
        case "mr": return "\u{0905}"
        case "bn": return "\u{0985}"
        case "gu": return "\u{0A85}"
        default: return "A"
        }
    }

    // MARK: - Background & Border

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
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
