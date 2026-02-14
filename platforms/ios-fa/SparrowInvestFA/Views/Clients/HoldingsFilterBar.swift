import SwiftUI

struct HoldingsFilterBar: View {
    @Binding var selectedCategory: String
    @Binding var sortBy: String
    @Binding var sortAscending: Bool
    @Environment(\.colorScheme) private var colorScheme

    private let categories = ["All", "Equity", "Debt", "Hybrid"]
    private let sortOptions = ["Value", "Returns", "Invested"]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Category Filter Chips
            GlassSegmentedControl(items: categories, selection: $selectedCategory)

            // Sort Controls
            HStack(spacing: AppTheme.Spacing.small) {
                // Sort Menu
                Menu {
                    ForEach(sortOptions, id: \.self) { option in
                        Button {
                            sortBy = option
                        } label: {
                            HStack {
                                Text(option)
                                if sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.micro) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11))

                        Text("Sort: \(sortBy)")
                            .font(AppTheme.Typography.label(12))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.compact)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(UIColor.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.5), lineWidth: 1)
                    )
                }

                // Ascending/Descending Toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sortAscending.toggle()
                    }
                } label: {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                }

                Spacer()
            }
        }
    }

}

// MARK: - Preview

#Preview {
    VStack {
        HoldingsFilterBar(
            selectedCategory: .constant("All"),
            sortBy: .constant("Value"),
            sortAscending: .constant(false)
        )
    }
}
