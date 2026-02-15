import SwiftUI

@main
struct SparrowInvestFAApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(deepLinkRouter)
                .environmentObject(coordinator)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
        .commands {
            CommandMenu("Navigate") {
                Button("Dashboard") { coordinator.navigate(to: .dashboard) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Clients") { coordinator.navigate(to: .clients) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Transactions") { coordinator.navigate(to: .transactions) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Insights") { coordinator.navigate(to: .insights) }
                    .keyboardShortcut("4", modifiers: .command)
                Divider()
                Button("Fund Universe") { coordinator.navigate(to: .fundUniverse) }
                    .keyboardShortcut("5", modifiers: .command)
                Button("Reports") { coordinator.navigate(to: .reports) }
                    .keyboardShortcut("6", modifiers: .command)
            }
            CommandMenu("Actions") {
                Button("Toggle Avya AI") { coordinator.showAvyaChat.toggle() }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }

        WindowGroup("Client Detail", for: String.self) { $clientId in
            if let clientId {
                NavigationStack {
                    ClientDetailView(clientId: clientId)
                        .environmentObject(authManager)
                }
            }
        }
    }
}

// MARK: - Deep Link Router

@MainActor
class DeepLinkRouter: ObservableObject {
    @Published var pendingDestination: DeepLinkDestination?

    enum DeepLinkDestination: Equatable {
        case client(id: String)
        case transaction(id: String)
        case chat(query: String?)

        static func == (lhs: DeepLinkDestination, rhs: DeepLinkDestination) -> Bool {
            switch (lhs, rhs) {
            case (.client(let a), .client(let b)): return a == b
            case (.transaction(let a), .transaction(let b)): return a == b
            case (.chat(let a), .chat(let b)): return a == b
            default: return false
            }
        }
    }

    func handle(url: URL) {
        guard url.scheme == "sparrowinvest" else { return }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "client":
            if let clientId = pathComponents.first, !clientId.isEmpty {
                pendingDestination = .client(id: clientId)
                NotificationCenter.default.post(
                    name: .deepLinkNavigate,
                    object: nil,
                    userInfo: ["destination": "client", "id": clientId]
                )
            }

        case "transaction":
            if let transactionId = pathComponents.first, !transactionId.isEmpty {
                pendingDestination = .transaction(id: transactionId)
                NotificationCenter.default.post(
                    name: .deepLinkNavigate,
                    object: nil,
                    userInfo: ["destination": "transaction", "id": transactionId]
                )
            }

        case "chat":
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "query" })?.value
            pendingDestination = .chat(query: query)
            NotificationCenter.default.post(
                name: .deepLinkNavigate,
                object: nil,
                userInfo: ["destination": "chat", "query": query ?? ""]
            )

        default:
            break
        }
    }

    func clearDestination() {
        pendingDestination = nil
    }
}

extension Notification.Name {
    static let deepLinkNavigate = Notification.Name("deepLinkNavigate")
}
