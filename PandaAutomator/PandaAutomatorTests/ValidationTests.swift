import XCTest
@testable import PandaAutomator

final class ValidationTests: XCTestCase {

    private var viewModel: AutomationViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = AutomationViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    @MainActor
    func testIsValidFalseWhenCodeTooShort() {
        viewModel.surveyCode = "1234-5678"
        viewModel.email = "test@example.com"
        XCTAssertFalse(viewModel.isValid)
    }

    @MainActor
    func testIsValidFalseWhenEmailMissingAt() {
        // 24-char code
        viewModel.surveyCode = "1234-5678-9012-3456-7890-1234"
        viewModel.email = "testexample.com"
        XCTAssertFalse(viewModel.isValid)
    }

    @MainActor
    func testIsValidTrueWhen24CharsAndValidEmail() {
        viewModel.surveyCode = "1234-5678-9012-3456-7890-1234"
        viewModel.email = "test@example.com"
        XCTAssertTrue(viewModel.isValid)
    }
}
