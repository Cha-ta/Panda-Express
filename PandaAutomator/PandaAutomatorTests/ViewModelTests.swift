import XCTest
@testable import PandaAutomator

final class ViewModelTests: XCTestCase {

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
    func testIsRunningDefaultsFalse() {
        XCTAssertFalse(viewModel.isRunning)
    }

    @MainActor
    func testStartAutomationSetsIsRunningTrue() {
        viewModel.surveyCode = "1234-5678-9012-3456-7890-1234"
        viewModel.email = "test@example.com"
        viewModel.startAutomation()
        XCTAssertTrue(viewModel.isRunning)
    }
}
