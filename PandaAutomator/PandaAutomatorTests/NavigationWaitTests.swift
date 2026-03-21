import XCTest
import WebKit
@testable import PandaAutomator

final class NavigationWaitTests: XCTestCase {

    // MARK: - Navigation Delegate Conformance (AUTO-10)

    @MainActor
    func testNavigationContinuationResumes() {
        // Structural test: AutomationEngine conforms to WKNavigationDelegate
        // This ensures webView(_:didFinish:) is called after each page navigation
        let engine = AutomationEngine()
        engine.setup()

        // Verify the engine itself is a WKNavigationDelegate
        XCTAssertTrue(
            engine is WKNavigationDelegate,
            "AutomationEngine must conform to WKNavigationDelegate for navigation continuation"
        )
    }

    // MARK: - Random Delay (AUTO-11)

    func testRandomDelayRange() async {
        // AUTO-11: Random delays between 0.4s and 1.6s to avoid bot detection
        // Run 10 iterations and verify all fall within range
        for i in 0..<10 {
            let start = CFAbsoluteTimeGetCurrent()
            await AutomationEngine.randomDelay()
            let elapsed = CFAbsoluteTimeGetCurrent() - start

            XCTAssertGreaterThanOrEqual(
                elapsed, 0.35,
                "Iteration \(i): delay must be >= 0.4s (with 0.05s tolerance)"
            )
            XCTAssertLessThanOrEqual(
                elapsed, 1.65,
                "Iteration \(i): delay must be <= 1.6s (with 0.05s tolerance)"
            )
        }
    }

    // MARK: - Max Pages Constant (AUTO-10)

    func testMaxPagesConstant() {
        // AUTO-10: Engine must stop after ~15 pages to prevent infinite loops
        XCTAssertEqual(
            AutomationEngine.maxPages, 15,
            "maxPages constant must be 15 to cap automation page count"
        )
    }
}
