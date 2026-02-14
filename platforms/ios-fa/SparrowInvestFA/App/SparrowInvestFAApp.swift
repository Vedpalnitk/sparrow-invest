import SwiftUI

@main
struct SparrowInvestFAApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var deepLinkRouter = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
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
