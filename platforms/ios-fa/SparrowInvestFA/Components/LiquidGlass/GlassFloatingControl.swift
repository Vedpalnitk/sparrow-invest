import SwiftUI

/// Floating button with interactive Liquid Glass effect.
/// On iOS 26+, gets press-scale, bounce, shimmer, and touch-point illumination.
struct GlassFloatingButton: View {
    let icon: String
    let label: String?
    let action: () -> Void
    var tintColor: Color? = nil

    init(icon: String, label: String? = nil, tintColor: Color? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.tintColor = tintColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                if let label {
                    Text(label)
                        .font(AppTheme.Typography.accent(14))
                }
            }
            .foregroundColor(tintColor ?? AppTheme.primary)
            .padding(.horizontal, label != nil ? AppTheme.Spacing.medium : AppTheme.Spacing.compact)
            .padding(.vertical, AppTheme.Spacing.compact)
            .liquidGlassInteractive(in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Icon-only button with interactive glass
struct GlassIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: size, height: size)
                .liquidGlassInteractive(in: Circle())
        }
        .buttonStyle(.plain)
    }
}
