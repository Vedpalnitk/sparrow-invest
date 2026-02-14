import SwiftUI

// MARK: - Health Score Ring

struct HealthScoreRing: View {
    let score: Int
    var size: CGFloat = 80

    @State private var animatedProgress: CGFloat = 0

    private var progress: Double {
        Double(score) / 100.0
    }

    private var ringColor: Color {
        if score >= 80 { return AppTheme.success }
        if score >= 60 { return AppTheme.warning }
        return AppTheme.error
    }

    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [ringColor.opacity(0.6), ringColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )

            // Foreground ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(AppTheme.Typography.numeric(22))
                    .foregroundColor(.primary)

                Text("/ 100")
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = 0
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppTheme.Spacing.xLarge) {
        HealthScoreRing(score: 92)
        HealthScoreRing(score: 68)
        HealthScoreRing(score: 45, size: 60)
    }
    .padding()
}
