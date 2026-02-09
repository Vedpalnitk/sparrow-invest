//
//  AvyaHomeCard.swift
//  SparrowInvest
//
//  Prominent Avya widget for Home screen
//

import SwiftUI

struct AvyaHomeCard: View {
    let onStartChat: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    private let suggestedPrompts = [
        "How is my portfolio doing?",
        "Should I rebalance?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: AppTheme.Spacing.medium) {
                // Avya Avatar
                ZStack {
                    // Animated rings
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.3),
                                    Color.cyan.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 68, height: 68)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.5 : 1.0)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.3, blue: 0.9),
                                    Color(red: 0.2, green: 0.5, blue: 1.0),
                                    Color(red: 0.0, green: 0.7, blue: 0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Avya")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        // AI Badge
                        Text("AI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }

                    Text("Your intelligent investment companion")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.medium)

            // Divider
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                .frame(height: 1)

            // Quick Prompts
            VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                Text("ASK AVYA")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                    .padding(.top, AppTheme.Spacing.compact)

                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(suggestedPrompts, id: \.self) { prompt in
                        PromptChip(text: prompt, onTap: onStartChat)
                    }
                    Spacer()
                }

                // Start Chat Button
                Button(action: onStartChat) {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14, weight: .medium))

                        Text("Start a conversation")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.3, blue: 0.9),
                                Color(red: 0.2, green: 0.5, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .padding(.top, AppTheme.Spacing.small)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.bottom, AppTheme.Spacing.medium)
        }
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: cardShadow, radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }

    // MARK: - Styling

    private var cardShadow: Color {
        colorScheme == .dark ? .clear : .blue.opacity(0.15)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.98, green: 0.98, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [.purple.opacity(0.4), .blue.opacity(0.2), .cyan.opacity(0.3)]
                        : [.purple.opacity(0.2), .blue.opacity(0.1), .cyan.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Prompt Chip

struct PromptChip: View {
    let text: String
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .primary.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : Color.blue.opacity(0.08),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.15)
                                : Color.blue.opacity(0.15),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        AvyaHomeCard(onStartChat: {})
            .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
