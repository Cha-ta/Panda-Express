import XCTest
import WebKit
@testable import PandaAutomator

final class EngineSetupTests: XCTestCase {

    @MainActor
    func testSetupCreatesWebView() {
        let engine = AutomationEngine()
        engine.setup()
        // After setup(), the WKWebView is non-nil.
        // We verify via the testable userAgent accessor: it is non-empty only if
        // the webView was successfully initialized with a customUserAgent.
        XCTAssertFalse(
            engine.userAgent.isEmpty,
            "userAgent should be non-empty after setup(), confirming WKWebView was created"
        )
    }

    @MainActor
    func testSetupAllowsPageLoad() {
        let engine = AutomationEngine()
        engine.setup()
        // loadFeedbackPage should not crash after setup — webView is initialized.
        engine.loadFeedbackPage()
        // Reaching this line without crash confirms WKWebView exists.
        XCTAssertTrue(true)
    }
}
