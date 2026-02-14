import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var deepLinkRouter: DeepLinkRouter
    @AppStorage("themeMode") private var themeMode = "System"

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(deepLinkRouter)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .preferredColorScheme(themeMode == "Light" ? .light : themeMode == "Dark" ? .dark : nil)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(DeepLinkRouter())
}
