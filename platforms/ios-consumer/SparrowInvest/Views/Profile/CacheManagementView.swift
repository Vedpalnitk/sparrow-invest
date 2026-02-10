import SwiftUI

struct CacheManagementView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var navDataSize: String = "2.3 MB"
    @State private var fundCatalogSize: String = "4.1 MB"
    @State private var imagesCacheSize: String = "8.7 MB"
    @State private var showClearAlert = false
    @State private var clearTarget: String? = nil
    @State private var showSuccess = false
    @State private var successMessage: String = ""

    private var sectionShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    private var totalCacheSize: String {
        let sizes = [navDataSize, fundCatalogSize, imagesCacheSize]
        var totalBytes: Double = 0

        for size in sizes {
            let components = size.split(separator: " ")
            guard components.count == 2, let value = Double(components[0]) else { continue }
            let unit = String(components[1])

            switch unit {
            case "MB": totalBytes += value * 1_000_000
            case "KB": totalBytes += value * 1_000
            case "B": totalBytes += value
            case "GB": totalBytes += value * 1_000_000_000
            default: break
            }
        }

        if totalBytes == 0 { return "0 B" }
        if totalBytes < 1_000 { return String(format: "%.0f B", totalBytes) }
        if totalBytes < 1_000_000 { return String(format: "%.1f KB", totalBytes / 1_000) }
        if totalBytes < 1_000_000_000 { return String(format: "%.1f MB", totalBytes / 1_000_000) }
        return String(format: "%.1f GB", totalBytes / 1_000_000_000)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xLarge) {
                // Storage Usage Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("STORAGE USAGE")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    VStack(spacing: 0) {
                        // NAV Data Row
                        CacheItemRow(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .blue,
                            title: "NAV Data",
                            size: navDataSize,
                            onClear: {
                                clearTarget = "NAV Data"
                                showClearAlert = true
                            }
                        )

                        Divider()
                            .padding(.leading, 52)

                        // Fund Catalog Row
                        CacheItemRow(
                            icon: "folder.fill",
                            iconColor: .orange,
                            title: "Fund Catalog",
                            size: fundCatalogSize,
                            onClear: {
                                clearTarget = "Fund Catalog"
                                showClearAlert = true
                            }
                        )

                        Divider()
                            .padding(.leading, 52)

                        // Images Row
                        CacheItemRow(
                            icon: "photo.fill",
                            iconColor: .purple,
                            title: "Images",
                            size: imagesCacheSize,
                            onClear: {
                                clearTarget = "Images"
                                showClearAlert = true
                            }
                        )

                        Divider()

                        // Total Cache Summary Row
                        HStack(spacing: AppTheme.Spacing.medium) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "internaldrive")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }

                            Text("Total Cache")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            Text(totalCacheSize)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(AppTheme.Spacing.medium)
                    }
                    .background(sectionBackground)
                    .overlay(sectionBorder)
                    .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                }

                // Clear All Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                    Text("ACTIONS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .tracking(1)

                    Button {
                        clearTarget = "All Cache"
                        showClearAlert = true
                    } label: {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "trash.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                            }

                            Text("Clear All Cache")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.red)

                            Spacer()

                            Text(totalCacheSize)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .padding(AppTheme.Spacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(clearAllBackground)
                        .overlay(clearAllBorder)
                        .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }

                // Success Banner
                if showSuccess {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text(successMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(AppTheme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .fill(Color.green.opacity(colorScheme == .dark ? 0.12 : 0.08))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(AppTheme.Spacing.medium)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Storage & Cache")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Clear \(clearTarget ?? "Cache")?",
            isPresented: $showClearAlert
        ) {
            Button("Cancel", role: .cancel) {
                clearTarget = nil
            }
            Button("Clear", role: .destructive) {
                performClear()
            }
        } message: {
            Text("This will remove the cached \(clearTarget?.lowercased() ?? "data"). It will be re-downloaded when needed.")
        }
    }

    // MARK: - Actions

    private func performClear() {
        guard let target = clearTarget else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            switch target {
            case "NAV Data":
                navDataSize = "0 B"
            case "Fund Catalog":
                fundCatalogSize = "0 B"
            case "Images":
                imagesCacheSize = "0 B"
            case "All Cache":
                navDataSize = "0 B"
                fundCatalogSize = "0 B"
                imagesCacheSize = "0 B"
            default:
                break
            }

            successMessage = "\(target) cleared successfully"
            showSuccess = true
        }

        clearTarget = nil

        // Hide success banner after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccess = false
            }
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

    @ViewBuilder
    private var clearAllBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(Color.red.opacity(0.05))
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color(uiColor: .white))
        }
    }

    private var clearAllBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .red.opacity(0.4), location: 0),
                            .init(color: .red.opacity(0.2), location: 0.3),
                            .init(color: .red.opacity(0.1), location: 0.7),
                            .init(color: .red.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .red.opacity(0.2), location: 0),
                            .init(color: .red.opacity(0.15), location: 0.3),
                            .init(color: .red.opacity(0.1), location: 0.7),
                            .init(color: .red.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Cache Item Row

struct CacheItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let size: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)

            Spacer()

            Text(size)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)

            if size != "0 B" {
                Button {
                    onClear()
                } label: {
                    Text("Clear")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Color.blue.opacity(0.1),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        CacheManagementView()
    }
}
