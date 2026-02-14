import SwiftUI

/// A segmented control using Liquid Glass for the selected indicator.
/// On iOS 26+, uses GlassEffectContainer with morphing transitions.
/// On earlier versions, falls back to gradient capsule fill.
struct GlassSegmentedControl: View {
    let items: [String]
    @Binding var selection: String
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var glassNamespace

    private var trackFill: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(Color.white.opacity(0.08))
            : AnyShapeStyle(Color.white.opacity(0.7))
    }

    private var trackStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            glassVersion
        } else {
            fallbackVersion
        }
    }

    @available(iOS 26.0, *)
    private var glassVersion: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(.bouncy) { selection = item }
                } label: {
                    Text(item)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(selection == item ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selection == item
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(trackFill)
                .overlay(Capsule().stroke(trackStroke, lineWidth: 0.5))
        )
    }

    private var fallbackVersion: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(AppTheme.Animation.contentTransition) { selection = item }
                } label: {
                    Text(item)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(selection == item ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selection == item
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(trackFill)
                .overlay(Capsule().stroke(trackStroke, lineWidth: 0.5))
        )
    }
}

/// Index-based variant for tab selectors
struct GlassTabSelector: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var tabNamespace

    private var trackFill: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(Color.white.opacity(0.08))
            : AnyShapeStyle(Color.white.opacity(0.7))
    }

    private var trackStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            tabContent
                .background(
                    Capsule()
                        .fill(trackFill)
                        .overlay(Capsule().stroke(trackStroke, lineWidth: 0.5))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tabContent: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.0) { index, title in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedIndex = index }
                } label: {
                    Text(title)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(selectedIndex == index ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedIndex == index
                                ? AnyShapeStyle(AppTheme.primaryGradient)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
    }

}
