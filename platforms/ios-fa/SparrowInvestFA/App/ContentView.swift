import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Sparrow Invest FA")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Financial Advisor Portal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    ContentView()
}
