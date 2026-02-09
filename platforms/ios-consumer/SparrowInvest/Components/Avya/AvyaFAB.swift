//
//  AvyaFAB.swift
//  SparrowInvest
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
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Main button
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
                    .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)

                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Avya FAB Container (for overlay positioning)

struct AvyaFABContainer: View {
    @Binding var showAvyaChat: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                AvyaFAB {
                    showAvyaChat = true
                }
                .padding(.trailing, 16)
                .padding(.bottom, 90) // Above tab bar
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(uiColor: .systemGroupedBackground)
            .ignoresSafeArea()

        AvyaFABContainer(showAvyaChat: .constant(false))
    }
}
