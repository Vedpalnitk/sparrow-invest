import SwiftUI

// MARK: - Pending Actions Banner

struct PendingActionsBanner: View {
    let actions: [PendingAction]

    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    var body: some View {
        if actions.isEmpty {
            EmptyView()
        } else {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(spacing: AppTheme.Spacing.small) {
                    ForEach(actions) { action in
                        actionRow(action)
                    }
                }
                .padding(.top, AppTheme.Spacing.small)
            } label: {
                HStack(spacing: AppTheme.Spacing.small) {
                    Text("Pending Actions")
                        .font(AppTheme.Typography.accent(15))
                        .foregroundColor(.primary)

                    // Count badge
                    Text("\(actions.count)")
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(AppTheme.error))

                    Spacer()
                }
            }
            .tint(AppTheme.primary)
            .glassCard()
        }
    }

    // MARK: - Action Row

    private func actionRow(_ action: PendingAction) -> some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Priority color accent (left border)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: action.priority.color))
                .frame(width: 3, height: 40)

            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(Color(hex: action.priority.color).opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: action.typeIcon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: action.priority.color))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.micro) {
                    // Priority dot
                    Circle()
                        .fill(Color(hex: action.priority.color))
                        .frame(width: 6, height: 6)

                    Text(action.title)
                        .font(AppTheme.Typography.accent(13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Text(action.message)
                    .font(AppTheme.Typography.label(11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .listItemCard()
    }
}
