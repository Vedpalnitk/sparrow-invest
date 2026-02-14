import SwiftUI
import UIKit

// MARK: - iOS 26 Liquid Glass Theme

enum AppTheme {
    // MARK: - Primary Colors (Android FA aligned, adaptive for dark mode)
    static let primary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "93C5FD") : UIColor(hex: "2563EB")
    })
    static let primaryLight = Color(hex: "60A5FA")
    static let primaryDark = Color(hex: "1D4ED8")
    static let secondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "7DD3FC") : UIColor(hex: "06B6D4")
    })
    static let accent = Color(hex: "14B8A6")

    // MARK: - Semantic Colors
    static let success = Color(hex: "10B981")
    static let successLight = Color(hex: "34D399")
    static let warning = Color(hex: "F59E0B")
    static let warningLight = Color(hex: "FBBF24")
    static let error = Color(hex: "EF4444")
    static let errorLight = Color(hex: "F87171")
    static let info = Color(hex: "8B5CF6")

    // MARK: - Fund Category Colors
    static let equityColor = Color(hex: "2563EB")
    static let debtColor = Color(hex: "10B981")
    static let hybridColor = Color(hex: "F59E0B")
    static let elssColor = Color(hex: "8B5CF6")
    static let indexColor = Color(hex: "14B8A6")
    static let goldColor = Color(hex: "EAB308")

    // MARK: - Asset Class Colors (Chart segments)
    static let assetEquity = Color(hex: "3B82F6")
    static let assetDebt = Color(hex: "10B981")
    static let assetHybrid = Color(hex: "8B5CF6")
    static let assetGold = Color(hex: "F59E0B")
    static let assetInternational = Color(hex: "EC4899")
    static let assetLiquid = Color(hex: "06B6D4")
    static let assetOther = Color(hex: "94A3B8")

    // MARK: - Status Colors
    static let pendingColor = Color(hex: "F59E0B")
    static let approvedColor = Color(hex: "10B981")
    static let rejectedColor = Color(hex: "EF4444")
    static let executedColor = Color(hex: "3B82F6")

    // MARK: - Text Colors (System Dynamic)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Background Colors (System Dynamic)
    static let background = Color(uiColor: .systemBackground)
    static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    // MARK: - Fill Colors
    static let primaryFill = Color(uiColor: .systemFill)
    static let secondaryFill = Color(uiColor: .secondarySystemFill)
    static let tertiaryFill = Color(uiColor: .tertiarySystemFill)

    // MARK: - Adaptive Gradient Colors (auto-switch for dark mode)

    private static let gradientBlueStart = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "1E3A5F") : UIColor(hex: "2563EB")
    })
    private static let gradientCyanEnd = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "0E4D5C") : UIColor(hex: "06B6D4")
    })
    private static let gradientGreenStart = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "0F3D2E") : UIColor(hex: "10B981")
    })
    private static let gradientGreenEnd = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "164D3A") : UIColor(hex: "34D399")
    })
    private static let gradientWarmStart = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "5C3D0A") : UIColor(hex: "F59E0B")
    })
    private static let gradientWarmEnd = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "6B4D12") : UIColor(hex: "FBBF24")
    })

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientBlueStart, gradientCyanEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [gradientGreenStart, gradientGreenEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [gradientWarmStart, gradientWarmEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var blueGlassGradient: LinearGradient {
        LinearGradient(
            colors: [gradientBlueStart.opacity(0.1), gradientCyanEnd.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle page background for Liquid Glass effect — gives cards something to refract against
    static func pageBackground(colorScheme: ColorScheme) -> some View {
        Group {
            if colorScheme == .dark {
                Color(uiColor: .systemBackground)
            } else {
                ZStack {
                    Color(uiColor: .systemBackground)
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "EFF6FF").opacity(0.7), location: 0),
                            .init(color: Color(hex: "F0F9FF").opacity(0.5), location: 0.3),
                            .init(color: Color(hex: "F8FAFC"), location: 0.6),
                            .init(color: Color(hex: "F1F5F9").opacity(0.4), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Avya AI Brand
    static let avyaIndigo = Color(hex: "6366F1")

    private static let avyaIndigoAdaptive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "2D2660") : UIColor(hex: "6366F1")
    })
    private static let avyaBlueAdaptive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "1E3A5F") : UIColor(hex: "3B82F6")
    })
    private static let avyaCyanAdaptive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "0E4D5C") : UIColor(hex: "06B6D4")
    })

    static var avyaGradient: LinearGradient {
        LinearGradient(
            colors: [avyaIndigoAdaptive, avyaBlueAdaptive, avyaCyanAdaptive],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    static var avyaBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [avyaIndigoAdaptive, avyaBlueAdaptive],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Avya AI Golden Theme
    static let avyaGold = Color(hex: "F59E0B")
    static var avyaGoldenGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "B8860B"), .orange, Color(hex: "DAA520")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    static var avyaGoldenHighlight: LinearGradient {
        LinearGradient(
            colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Third-Party Brand Colors
    static let whatsAppGreen = Color(hex: "25D366")

    // MARK: - Typography (SF Pro Light + DIN Alternate)
    struct Typography {
        // Text font: SF Pro Light (system font)
        private static func sfProLight(_ size: CGFloat) -> Font {
            .system(size: size, weight: .light, design: .default)
        }

        // Text font: SF Pro with specific weight
        private static func sfPro(_ size: CGFloat, weight: Font.Weight) -> Font {
            .system(size: size, weight: weight, design: .default)
        }

        // Display - Hero numbers, large financial values (SF Pro Light)
        static func display(_ size: CGFloat = 32) -> Font {
            sfProLight(size)
        }

        // Title - Page titles, major section headers (SF Pro Regular for authority)
        static func title(_ size: CGFloat = 24) -> Font {
            sfPro(size, weight: .regular)
        }

        // Headline - Card titles, subsection headers (SF Pro Regular for clarity)
        static func headline(_ size: CGFloat = 17) -> Font {
            sfPro(size, weight: .regular)
        }

        // Body - Main content text (SF Pro Light for elegance)
        static func body(_ size: CGFloat = 15) -> Font {
            sfProLight(size)
        }

        // Caption - Secondary descriptions, help text (SF Pro Light)
        static func caption(_ size: CGFloat = 13) -> Font {
            sfProLight(size)
        }

        // Label - Small UI labels, form labels, badges (SF Pro Regular for legibility)
        static func label(_ size: CGFloat = 12) -> Font {
            sfPro(size, weight: .regular)
        }

        // Numeric - Financial values, stats, KPIs (SF Pro Light)
        static func numeric(_ size: CGFloat = 20) -> Font {
            sfProLight(size)
        }

        // Accent - Emphasis text, interactive elements (SF Pro Regular)
        static func accent(_ size: CGFloat = 14) -> Font {
            sfPro(size, weight: .regular)
        }

        // MARK: - Dashboard Text Constants
        enum DashboardText {
            static let heroLabel = Typography.label(11)
            static let heroValue = Typography.display(34)
            static let heroStat = Typography.accent(14)
            static let sectionTitle = Typography.headline(17)
            static let kpiValue = Typography.numeric(24)
            static let kpiLabel = Typography.label(11)
            static let cardName = Typography.accent(14)
            static let cardSubtext = Typography.caption(12)
            static let cardValue = Typography.numeric(16)
        }
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let xxLarge: CGFloat = 24
        static let hero: CGFloat = 32
    }

    // MARK: - Spacing
    enum Spacing {
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let compact: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let hero: CGFloat = 60
    }

    // MARK: - Animation Constants
    enum Animation {
        static let glassMorph: SwiftUI.Animation = .bouncy
        static let contentTransition: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let chartDraw: SwiftUI.Animation = .easeOut(duration: 1.0)
        static let cardAppear: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.8)
        static let fabBreathing: SwiftUI.Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    }

    // MARK: - Helpers
    static func returnColor(_ value: Double) -> Color {
        if value > 0 { return success }
        if value < 0 { return error }
        return .secondary
    }

    static func statusColor(_ status: String) -> Color {
        switch status.uppercased() {
        case "PENDING": return pendingColor
        case "APPROVED", "COMPLETED": return approvedColor
        case "REJECTED", "FAILED", "CANCELLED": return rejectedColor
        case "EXECUTED", "PROCESSING": return executedColor
        case "ACTIVE": return success
        case "PAUSED": return warning
        default: return .secondary
        }
    }

    static func formatCurrency(_ value: Double) -> String {
        if value >= 10_000_000 {
            return String(format: "%.2f Cr", value / 10_000_000)
        } else if value >= 100_000 {
            return String(format: "%.2f L", value / 100_000)
        } else if value >= 1_000 {
            return String(format: "%.1f K", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    static func formatCurrencyWithSymbol(_ value: Double) -> String {
        return "\u{20B9}\(formatCurrency(value))"
    }
}

// MARK: - Glass Card Modifier (Liquid Glass)

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = AppTheme.CornerRadius.xLarge
    var padding: CGFloat = AppTheme.Spacing.medium

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(cardBackground)
            .overlay(cardBorder.allowsHitTesting(false))
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            // Liquid Glass: translucent white with material blur
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.thinMaterial)
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                    // Light mode: glass refraction — white catch-light into blue-grey shadow edge
                    : LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: Color(hex: "CBD5E1").opacity(0.6), location: 0.3),
                            .init(color: Color(hex: "94A3B8").opacity(0.35), location: 0.65),
                            .init(color: .white.opacity(0.7), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: colorScheme == .dark ? 1 : 1
            )
    }
}

// MARK: - List Item Card Modifier

struct ListItemCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = AppTheme.CornerRadius.medium

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.compact)
            .background(cardBackground)
            .overlay(cardBorder.allowsHitTesting(false))
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            // Liquid Glass: lighter translucency for nested items
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.25), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    // Light mode: subtle glass edge for list items
                    : LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: Color(hex: "CBD5E1").opacity(0.5), location: 0.35),
                            .init(color: Color(hex: "94A3B8").opacity(0.25), location: 0.7),
                            .init(color: .white.opacity(0.6), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: colorScheme == .dark ? 1 : 0.75
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Primary glass card - white in light, frosted glass in dark
    func glassCard(
        cornerRadius: CGFloat = AppTheme.CornerRadius.xLarge,
        padding: CGFloat = AppTheme.Spacing.medium
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// List item card - subtle styling for nested rows
    func listItemCard(cornerRadius: CGFloat = AppTheme.CornerRadius.medium) -> some View {
        modifier(ListItemCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass View Extensions

extension View {
    /// Liquid Glass for navigation elements (tab bars, toolbars, floating controls)
    @ViewBuilder
    func liquidGlassNavigation(in shape: some Shape = Capsule()) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Interactive Liquid Glass with press-scale, bounce, shimmer effects
    @ViewBuilder
    func liquidGlassInteractive(in shape: some Shape = Circle()) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    /// Tinted Liquid Glass for semantic navigation controls
    @ViewBuilder
    func liquidGlassTinted(_ color: Color, in shape: some Shape = Capsule()) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(color), in: shape)
        } else {
            self
                .background(color.opacity(0.15), in: shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

// MARK: - Number Formatting

extension Double {
    var formattedCurrency: String {
        AppTheme.formatCurrencyWithSymbol(self)
    }

    var formattedPercent: String {
        String(format: "%+.1f%%", self)
    }

    var formattedReturn: String {
        String(format: "%+.2f%%", self)
    }

    var compactCurrencyFormatted: String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""
        if absValue >= 10_000_000 {
            return "\(sign)₹\(String(format: "%.1f", absValue / 10_000_000)) Cr"
        } else if absValue >= 100_000 {
            return "\(sign)₹\(String(format: "%.1f", absValue / 100_000)) L"
        } else if absValue >= 1_000 {
            return "\(sign)₹\(String(format: "%.0f", absValue / 1_000))K"
        } else {
            return formattedCurrency
        }
    }
}
