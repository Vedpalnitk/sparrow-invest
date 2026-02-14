import SwiftUI
import WebKit

// MARK: - Transaction Platform

enum TransactionPlatform: String, CaseIterable {
    case bseStarMF
    case mfu

    var title: String {
        switch self {
        case .bseStarMF: return "BSE Star MF"
        case .mfu: return "MF Utilities"
        }
    }

    var url: URL {
        switch self {
        case .bseStarMF: return URL(string: "https://www.bsestarmf.in")!
        case .mfu: return URL(string: "https://www.mfuonline.com")!
        }
    }
}

// MARK: - Platform WebView

struct PlatformWebView: View {
    let platform: TransactionPlatform
    @Environment(\.dismiss) private var dismiss
    @State private var loadingProgress: Double = 0
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var webView: WKWebView?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                if isLoading {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(AppTheme.primaryGradient)
                            .frame(width: geo.size.width * loadingProgress, height: 3)
                            .animation(.easeInOut(duration: 0.25), value: loadingProgress)
                    }
                    .frame(height: 3)
                }

                // WebView
                WebViewRepresentable(
                    url: platform.url,
                    loadingProgress: $loadingProgress,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    webView: $webView
                )
            }
            .navigationTitle(platform.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        webView?.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .foregroundColor(canGoBack ? .primary : .secondary.opacity(0.4))
                    }
                    .disabled(!canGoBack)

                    Button {
                        webView?.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// MARK: - WebView Representable

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var loadingProgress: Double
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        HTTPCookieStorage.shared.cookieAcceptPolicy = .always

        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.allowsBackForwardNavigationGestures = true

        DispatchQueue.main.async {
            self.webView = wkWebView
        }

        context.coordinator.observeProgress(of: wkWebView)
        wkWebView.load(URLRequest(url: url))
        return wkWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable
        private var progressObservation: NSKeyValueObservation?

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func observeProgress(of webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.loadingProgress = webView.estimatedProgress
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
            }
        }

        deinit {
            progressObservation?.invalidate()
        }
    }
}
