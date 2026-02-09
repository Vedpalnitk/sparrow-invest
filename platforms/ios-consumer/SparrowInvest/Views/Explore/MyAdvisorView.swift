//
//  MyAdvisorView.swift
//  SparrowInvest
//
//  Dedicated view for managed users to see their assigned advisor
//

import SwiftUI

struct MyAdvisorView: View {
    @EnvironmentObject var advisorStore: AdvisorStore
    @Environment(\.colorScheme) private var colorScheme

    private var advisor: Advisor? {
        advisorStore.assignedAdvisor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.large) {
                // Advisor Profile Header
                advisorHeader

                // Quick Actions
                quickActions

                // Stats Section
                statsSection

                // Specializations
                if let specs = advisor?.specializations, !specs.isEmpty {
                    specializationsSection(specs)
                }

                // Languages
                if let languages = advisor?.languages, !languages.isEmpty {
                    languagesSection(languages)
                }

                // Contact Info
                contactInfoSection
            }
            .padding(AppTheme.Spacing.medium)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Your Advisor")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Advisor Header

    private var advisorHeader: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(advisor?.initials ?? "AD")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.green)
            }

            // Name & Region
            VStack(spacing: 4) {
                Text(advisor?.name ?? "Your Advisor")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Financial Advisor")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)

                if let region = advisor?.region {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(region)
                            .font(.system(size: 13, weight: .light))
                    }
                    .foregroundColor(.secondary)
                }
            }

            // Rating & Availability
            HStack(spacing: AppTheme.Spacing.medium) {
                // Rating Badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text(String(format: "%.1f", advisor?.rating ?? 0))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Text("(\(advisor?.reviewCount ?? 0))")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )

                // Availability Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(advisor?.isAvailable == true ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(advisor?.isAvailable == true ? "Available" : "Busy")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(advisor?.isAvailable == true ? .green : .secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill((advisor?.isAvailable == true ? Color.green : Color.gray).opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.large)
        .background(headerBackground)
        .overlay(headerBorder)
        .shadow(color: headerShadow, radius: 12, x: 0, y: 4)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ActionButton(
                icon: "phone.fill",
                label: "Call",
                color: .green
            ) {
                if let phone = advisor?.phone,
                   let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }

            ActionButton(
                icon: "message.fill",
                label: "Message",
                color: .blue
            ) {
                if let phone = advisor?.phone,
                   let url = URL(string: "sms:\(phone.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }

            ActionButton(
                icon: "envelope.fill",
                label: "Email",
                color: .orange
            ) {
                if let email = advisor?.email, let url = URL(string: "mailto:\(email)") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("ADVISOR STATS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            HStack(spacing: AppTheme.Spacing.compact) {
                StatTile(
                    value: "\(advisor?.experienceYears ?? 0)+",
                    label: "Years Exp.",
                    icon: "calendar",
                    color: .blue
                )

                StatTile(
                    value: String(format: "%.1f", advisor?.rating ?? 0),
                    label: "Rating",
                    icon: "star.fill",
                    color: .orange
                )

                StatTile(
                    value: "\(advisor?.reviewCount ?? 0)",
                    label: "Reviews",
                    icon: "text.bubble.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Specializations

    private func specializationsSection(_ specs: [AdvisorSpecialization]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("SPECIALIZATIONS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            FlowLayout(spacing: 8) {
                ForEach(specs, id: \.self) { spec in
                    HStack(spacing: 6) {
                        Image(systemName: spec.icon)
                            .font(.system(size: 10))
                            .foregroundColor(spec.color)
                        Text(spec.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(specBackground(spec.color))
                    .overlay(specBorder(spec.color))
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Languages Section

    private func languagesSection(_ languages: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("LANGUAGES")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(languages, id: \.self) { language in
                    Text(language)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(langBackground)
                        .overlay(langBorder)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Contact Info

    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("CONTACT INFORMATION")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(spacing: 0) {
                if let phone = advisor?.phone {
                    ContactRow(icon: "phone.fill", label: "Phone", value: phone, color: .green)
                    Divider().padding(.leading, 44)
                }

                if let email = advisor?.email {
                    ContactRow(icon: "envelope.fill", label: "Email", value: email, color: .orange)
                    Divider().padding(.leading, 44)
                }

                if let region = advisor?.region {
                    ContactRow(icon: "location.fill", label: "Region", value: region, color: .blue)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Styling

    private var headerShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    private var sectionShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var headerBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var headerBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
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
                .fill(Color.white)
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
    private func specBackground(_ color: Color) -> some View {
        Capsule().fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
    }

    private func specBorder(_ color: Color) -> some View {
        Capsule()
            .stroke(colorScheme == .dark ? color.opacity(0.2) : Color.clear, lineWidth: 0.5)
    }

    @ViewBuilder
    private var langBackground: some View {
        if colorScheme == .dark {
            Capsule().fill(Color.white.opacity(0.06))
        } else {
            Capsule().fill(Color(uiColor: .tertiarySystemFill))
        }
    }

    private var langBorder: some View {
        Capsule()
            .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear, lineWidth: 0.5)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(buttonBackground)
            .overlay(buttonBorder)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    private var buttonBorder: some View {
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

// MARK: - Stat Tile

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(tileBackground)
        .overlay(tileBorder)
        .shadow(color: tileShadow, radius: 8, x: 0, y: 2)
    }

    private var tileShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.06)
    }

    @ViewBuilder
    private var tileBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
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

// MARK: - Contact Row

private struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x - spacing)
            }
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    NavigationStack {
        MyAdvisorView()
            .environmentObject(AdvisorStore())
    }
}
