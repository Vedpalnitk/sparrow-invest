import SwiftUI

/// Bottom floating action bar with Liquid Glass effect.
/// Use for contextual actions on detail screens.
struct GlassActionBar<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            content
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
        .frame(maxWidth: .infinity)
        .liquidGlassNavigation(
            in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
        )
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.small)
    }
}
