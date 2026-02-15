import SwiftUI

struct ActiveSessionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }
    @State private var sessions: [DeviceSession] = DeviceSession.mockData
    @State private var showRevokeAlert = false
    @State private var sessionToRevoke: DeviceSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(sessions) { session in
                        sessionRow(session)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xxxLarge)
            }
            .navigationTitle("Active Sessions")
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
        .alert("Revoke Session", isPresented: $showRevokeAlert) {
            Button("Cancel", role: .cancel) {
                sessionToRevoke = nil
            }
            Button("Revoke", role: .destructive) {
                if let session = sessionToRevoke {
                    revokeSession(session.id)
                }
                sessionToRevoke = nil
            }
        } message: {
            if let session = sessionToRevoke {
                Text("Are you sure you want to revoke the session on \(session.deviceName)? This will log out that device immediately.")
            }
        }
    }

    // MARK: - Session Row

    private func sessionRow(_ session: DeviceSession) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Device icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: deviceIcon(session.deviceType))
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text(session.deviceName)
                        .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                        .foregroundColor(.primary)

                    if session.isCurrent {
                        Text("Current")
                            .font(AppTheme.Typography.label(iPad ? 12 : 10))
                            .foregroundColor(AppTheme.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.success.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(session.lastActive)
                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                    .foregroundColor(.secondary)

                if let location = session.location {
                    Text(location)
                        .font(AppTheme.Typography.label(iPad ? 13 : 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !session.isCurrent {
                Button {
                    sessionToRevoke = session
                    showRevokeAlert = true
                } label: {
                    Text("Revoke")
                        .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        .foregroundColor(AppTheme.error)
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.compact)
    }

    // MARK: - Helpers

    private func deviceIcon(_ type: String) -> String {
        switch type {
        case "ios": return "iphone"
        case "web": return "laptopcomputer"
        case "android": return "apps.iphone"
        default: return "desktopcomputer"
        }
    }

    private func revokeSession(_ id: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            sessions.removeAll { $0.id == id }
        }
    }
}

// MARK: - Device Session Model

struct DeviceSession: Identifiable {
    let id: String
    let deviceName: String
    let deviceType: String
    let lastActive: String
    let isCurrent: Bool
    let location: String?

    static let mockData: [DeviceSession] = [
        DeviceSession(
            id: "s1",
            deviceName: "iPhone 17 Pro",
            deviceType: "ios",
            lastActive: "Active now",
            isCurrent: true,
            location: "Mumbai, IN"
        ),
        DeviceSession(
            id: "s2",
            deviceName: "Chrome on MacOS",
            deviceType: "web",
            lastActive: "2 hours ago",
            isCurrent: false,
            location: "Mumbai, IN"
        ),
        DeviceSession(
            id: "s3",
            deviceName: "Safari on iPad",
            deviceType: "web",
            lastActive: "Yesterday",
            isCurrent: false,
            location: "Delhi, IN"
        ),
    ]
}
