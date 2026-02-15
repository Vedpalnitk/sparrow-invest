import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @AppStorage("themeMode") private var themeMode = "System"

    @State private var showClearCacheAlert = false
    @State private var cacheCleared = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private var buildType: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Preferences Section
                    sectionHeader("PREFERENCES")
                    VStack(spacing: 0) {
                        // Theme Picker (Light / Dark / System)
                        themePickerRow

                        menuItem(icon: "globe", title: "Language",
                                 subtitle: "English") {}
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Data Section
                    sectionHeader("DATA")
                    VStack(spacing: 0) {
                        menuItem(icon: "internaldrive", title: "Clear Cache",
                                 subtitle: "Reset cached data") {
                            showClearCacheAlert = true
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // About Section
                    sectionHeader("ABOUT")
                    VStack(spacing: 0) {
                        infoItem(icon: "info.circle", title: "App Version",
                                 value: appVersion)
                        infoItem(icon: "hammer", title: "Build",
                                 value: buildType)
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Legal Section
                    sectionHeader("LEGAL")
                    VStack(spacing: 0) {
                        menuItem(icon: "hand.raised", title: "Privacy Policy",
                                 subtitle: "How we handle your data") {
                            openURL("https://sparrowinvest.com/privacy")
                        }
                        menuItem(icon: "doc.text", title: "Terms of Service",
                                 subtitle: "Usage terms and conditions") {
                            openURL("https://sparrowinvest.com/terms")
                        }
                        menuItem(icon: "building.columns", title: "Regulatory Info",
                                 subtitle: "SEBI & AMFI disclosures") {
                            openURL("https://sparrowinvest.com/regulatory")
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Footer
                    Text("Sparrow Invest FA \(appVersion)")
                        .font(AppTheme.Typography.label(iPad ? 14 : 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .preferredColorScheme(themeMode == "Light" ? .light : themeMode == "Dark" ? .dark : nil)
        .alert("Clear Cache", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will reset preferences to defaults. Your account will remain logged in.")
        }
        .overlay(
            cacheCleared ? cacheToast : nil,
            alignment: .bottom
        )
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.label(iPad ? 13 : 11))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, AppTheme.Spacing.compact)
            .padding(.top, AppTheme.Spacing.small)
    }

    // MARK: - Menu Item

    private func menuItem(
        icon: String, title: String, subtitle: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.compact) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.label(iPad ? 14 : 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, AppTheme.Spacing.compact)
            .padding(.horizontal, AppTheme.Spacing.small)
        }
    }

    // MARK: - Info Item (no chevron)

    private func infoItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.caption(iPad ? 15 : 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    // MARK: - Theme Picker Row

    private var themePickerRow: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: themeIcon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text("Theme")
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.primary)

                Text("Choose appearance")
                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 0) {
                ForEach(["Light", "Dark", "System"], id: \.self) { mode in
                    let isSelected = themeMode == mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeMode = mode
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: themeModeIcon(mode))
                                .font(.system(size: 10))
                            Text(mode)
                                .font(AppTheme.Typography.accent(iPad ? 13 : 11))
                        }
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
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
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }

    private var themeIcon: String {
        switch themeMode {
        case "Light": return "sun.max"
        case "Dark": return "moon"
        default: return "circle.lefthalf.filled"
        }
    }

    private func themeModeIcon(_ mode: String) -> String {
        switch mode {
        case "Light": return "sun.max.fill"
        case "Dark": return "moon.fill"
        default: return "gear"
        }
    }

    // MARK: - Cache Toast

    private var cacheToast: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.success)
            Text("Cache cleared successfully")
                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
        .padding(.bottom, AppTheme.Spacing.xxLarge)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func clearCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()

        withAnimation {
            cacheCleared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                cacheCleared = false
            }
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
