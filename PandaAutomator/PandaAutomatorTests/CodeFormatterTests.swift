import XCTest
@testable import PandaAutomator

final class CodeFormatterTests: XCTestCase {

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
    func testFormatCodeWithDashesInsertsDashesEvery4Chars() {
        let result = viewModel.formatCodeWithDashes("12345678")
        XCTAssertEqual(result, "1234-5678")
    }

    @MainActor
    func testFormatCodeStripsExistingDashesBeforeReformatting() {
        // Already-formatted input should produce the same formatted output
        let result = viewModel.formatCodeWithDashes("1234-5678-9012")
        XCTAssertEqual(result, "1234-5678-9012")
    }

    @MainActor
    func testFormatCodeCapsAt24AlphanumericCharacters() {
        // 30 chars of input — should cap at first 24 then insert dashes
        let input = "123456789012345678901234567890"
        let result = viewModel.formatCodeWithDashes(input)
        // 24 chars + 5 dashes (every 4) = "1234-5678-9012-3456-7890-1234"
        XCTAssertEqual(result, "1234-5678-9012-3456-7890-1234")
        // Strip dashes to check length
        let clean = result.replacingOccurrences(of: "-", with: "")
        XCTAssertEqual(clean.count, 24)
    }

    @MainActor
    func testFormatCodeUppercasesInput() {
        let result = viewModel.formatCodeWithDashes("abcd")
        XCTAssertEqual(result, "ABCD")
    }
}
