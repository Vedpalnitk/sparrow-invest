import SwiftUI

// MARK: - Insight Tab Bar

struct InsightTabBar: View {
    @Binding var selectedTab: Int
    let healthCount: Int
    let rebalancingCount: Int
    let goalCount: Int
    let taxCount: Int

    var body: some View {
        GlassTabSelector(
            tabs: ["Health", "Rebalance", "Goals", "Tax"],
            selectedIndex: $selectedTab
        )
    }
}

// MARK: - InsightTab Model

private struct InsightTab: Identifiable {
    let index: Int
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var id: Int { index }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = 0

        var body: some View {
            VStack(spacing: AppTheme.Spacing.large) {
                InsightTabBar(
                    selectedTab: $selected,
                    healthCount: 3,
                    rebalancingCount: 5,
                    goalCount: 2,
                    taxCount: 1
                )

                Text("Selected tab: \(selected)")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
