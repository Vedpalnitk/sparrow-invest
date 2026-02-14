import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeMode") private var themeMode = "System"

    @State private var showNotifications = false
    @State private var showSecurity = false
    @State private var showHelpSupport = false
    @State private var showSettings = false
    @State private var showActionCenter = false
    @State private var showSipManagement = false
    @State private var showReports = false
    @State private var showCalculators = false
    @State private var showProspects = false
    @State private var showFundUniverse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // User Info
                    userCard

                    // Menu Section 1
                    VStack(spacing: 0) {
                        menuItem(icon: "bell.badge", title: "Action Center",
                                 subtitle: "Failed SIPs, pending actions") { showActionCenter = true }
                        menuItem(icon: "arrow.triangle.2.circlepath", title: "SIP Management",
                                 subtitle: "View all SIPs") { showSipManagement = true }
                        menuItem(icon: "chart.bar.doc.horizontal", title: "Reports",
                                 subtitle: "Generate & share reports") { showReports = true }
                        menuItem(icon: "function", title: "Calculators",
                                 subtitle: "SIP, lumpsum & more") { showCalculators = true }
                        menuItem(icon: "bell", title: "Notifications",
                                 subtitle: "Manage alerts") { showNotifications = true }
                        menuToggle(icon: "moon", title: "Dark Mode", isOn: darkModeBinding)
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Business Section
                    VStack(spacing: 0) {
                        menuItem(icon: "person.crop.circle.badge.questionmark", title: "Prospects",
                                 subtitle: "Sales pipeline & leads") { showProspects = true }
                        menuItem(icon: "globe", title: "Fund Universe",
                                 subtitle: "Browse funds by category") { showFundUniverse = true }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Menu Section 2
                    VStack(spacing: 0) {
                        menuItem(icon: "lock.shield", title: "Security",
                                 subtitle: "Password & PIN") { showSecurity = true }
                        menuItem(icon: "questionmark.circle", title: "Help & Support") { showHelpSupport = true }
                        menuItem(icon: "gearshape", title: "Settings") { showSettings = true }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.small)

                    // Logout
                    Button {
                        authManager.logout()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.compact) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.error)

                            Text("Logout")
                                .font(AppTheme.Typography.accent(15))
                                .foregroundColor(AppTheme.error)

                            Spacer()
                        }
                    }
                    .glassCard(cornerRadius: AppTheme.CornerRadius.large)

                    // Version
                    Text("Sparrow FA v1.0.0")
                        .font(AppTheme.Typography.label(12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("More")
        }
        .preferredColorScheme(themeMode == "Light" ? .light : themeMode == "Dark" ? .dark : nil)
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationsView()
        }
        .fullScreenCover(isPresented: $showSecurity) {
            SecurityView()
        }
        .fullScreenCover(isPresented: $showHelpSupport) {
            HelpSupportView()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showActionCenter) {
            ActionCenterView()
        }
        .fullScreenCover(isPresented: $showSipManagement) {
            SipListView()
        }
        .fullScreenCover(isPresented: $showReports) {
            ReportsView()
        }
        .fullScreenCover(isPresented: $showCalculators) {
            CalculatorsView()
        }
        .fullScreenCover(isPresented: $showProspects) {
            ProspectsView()
        }
        .fullScreenCover(isPresented: $showFundUniverse) {
            FundUniverseView()
        }
    }

    private var darkModeBinding: Binding<Bool> {
        Binding(
            get: { themeMode == "Dark" },
            set: { themeMode = $0 ? "Dark" : "System" }
        )
    }

    private var userCard: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.user?.displayName ?? "Financial Advisor")
                    .font(AppTheme.Typography.headline(16))
                    .foregroundColor(.primary)

                Text(authManager.user?.email ?? "")
                    .font(AppTheme.Typography.caption(13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }

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
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.label(12))
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

    private func menuToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)

            Text(title)
                .font(AppTheme.Typography.accent(15))
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, AppTheme.Spacing.compact)
        .padding(.horizontal, AppTheme.Spacing.small)
    }
}
