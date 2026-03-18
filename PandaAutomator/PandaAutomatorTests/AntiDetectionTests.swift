import XCTest
import WebKit
@testable import PandaAutomator

final class AntiDetectionTests: XCTestCase {

    @MainActor
    func testUserAgentContainsSafari() {
        let engine = AutomationEngine()
        engine.setup()
        XCTAssertTrue(
            engine.userAgent.contains("Safari"),
            "Custom user agent should contain 'Safari'"
        )
    }

    @MainActor
    func testWebdriverScriptInjectedAtDocumentStart() {
        let engine = AutomationEngine()
        engine.setup()
        let scripts = engine.userScripts
        let hasDocumentStartScript = scripts.contains {
            $0.injectionTime == .atDocumentStart
        }
        XCTAssertTrue(
            hasDocumentStartScript,
            "At least one user script should be injected at document start"
        )
    }
}
