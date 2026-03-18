import WebKit

@MainActor
final class JSBridgeHandler: NSObject, WKScriptMessageHandler {

    var onLog: ((String) -> Void)?

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let body = message.body as? String ?? "\(message.body)"
        Task { @MainActor in
            self.onLog?(body)
        }
    }
}
