import WebKit

@MainActor
final class JSBridgeHandler: NSObject, WKScriptMessageHandler {

    var onLog: ((String) -> Void)?

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor in
            let body = message.body as? String ?? "\(message.body)"
            self.onLog?(body)
        }
    }
}
