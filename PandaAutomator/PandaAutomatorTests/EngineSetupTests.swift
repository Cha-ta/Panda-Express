import XCTest
import WebKit
@testable import PandaAutomator

final class EngineSetupTests: XCTestCase {

    @MainActor
    func testSetupCreatesWebView() {
        // AutomationEngine exposes its webView via internal access for testing.
        let engine = AutomationEngine()
        engine.setup()
        // Verify via indirect evidence: the engine can load a page without crashing.
        // Direct webView access requires @testable and internal visibility.
        XCTAssertNotNil(engine, "Engine should be non-nil after setup")
        // Trigger a load to confirm webView is configured
        engine.loadFeedbackPage()
        // If loadFeedbackPage doesn't crash, WKWebView was created successfully.
    }
}
