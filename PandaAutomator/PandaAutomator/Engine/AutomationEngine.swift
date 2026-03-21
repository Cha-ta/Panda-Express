import UIKit
import WebKit

@MainActor
class AutomationEngine: NSObject {

    private var webView: WKWebView!
    private let bridgeHandler = JSBridgeHandler()

    var onLog: ((String) -> Void)? {
        didSet {
            bridgeHandler.onLog = onLog
        }
    }

    func setup() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        // Anti-detection scripts injected BEFORE page JS runs
        let antiDetectSource = """
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
        """
        let antiDetect = WKUserScript(
            source: antiDetectSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(antiDetect)
        controller.add(bridgeHandler, name: "log")

        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // CRITICAL: must be in window hierarchy or JS is throttled
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        scene?.windows.first?.addSubview(webView)
    }

    func loadFeedbackPage() {
        guard let url = URL(string: "https://www.pandaexpress.com/feedback") else { return }
        webView.load(URLRequest(url: url))
    }

    /// Phase 2 fills in the real automation logic.
    func run(code: String, email: String) {
        loadFeedbackPage()
    }

    // MARK: - Constants

    /// Maximum pages before stopping automation loop (safety cap).
    static let maxPages = 15

    /// Random delay between actions to appear human-like (0.5-1.5s).
    /// Matches script.py human_delay().
    static func randomDelay() async {
        let nanoseconds = UInt64.random(in: 500_000_000...1_500_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    // MARK: - Testable Accessors

    /// Exposed for unit tests (AntiDetectionTests).
    var userAgent: String {
        webView?.customUserAgent ?? ""
    }

    /// Exposed for unit tests (AntiDetectionTests).
    var userScripts: [WKUserScript] {
        webView?.configuration.userContentController.userScripts ?? []
    }
}

extension AutomationEngine: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.onLog?("Page loaded")
        }
    }
}
