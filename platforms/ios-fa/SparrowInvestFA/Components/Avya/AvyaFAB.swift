//
//  AvyaFAB.swift
//  SparrowInvestFA
//
//  Floating Action Button for Avya AI Assistant
//

import SwiftUI

struct AvyaFAB: View {
    let action: () -> Void
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                // Breathing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: colorScheme == .dark
                                ? [Color(hex: "2D2660").opacity(0.4), Color(hex: "1E3A5F").opacity(0.15), Color.clear]
                                : [Color(hex: "6366F1").opacity(0.3), Color(hex: "3B82F6").opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Gradient circle matching the Avya AI card
                Circle()
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(hex: "2D2660"), Color(hex: "1E3A5F"), Color(hex: "0E4D5C")]
                                : [Color(hex: "6366F1"), Color(hex: "3B82F6"), Color(hex: "06B6D4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color(hex: "6366F1").opacity(colorScheme == .dark ? 0.2 : 0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(AppTheme.Animation.fabBreathing) {
                isAnimating = true
            }
        }
    }
}

struct AvyaFABContainer: View {
    @Binding var showAvyaChat: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                AvyaFAB {
                    showAvyaChat = true
                }
                .padding(.trailing, sizeClass == .regular ? 24 : 16)
                .padding(.bottom, sizeClass == .regular ? 24 : 90)
            }
        }
    }
}

#Preview {
    ZStack {
        AppTheme.groupedBackground
            .ignoresSafeArea()

        AvyaFABContainer(showAvyaChat: .constant(false))
    }
}
