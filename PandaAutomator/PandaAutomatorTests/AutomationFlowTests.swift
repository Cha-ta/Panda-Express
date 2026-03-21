import XCTest
@testable import PandaAutomator

final class AutomationFlowTests: XCTestCase {

    // MARK: - Page Classification Tests (AUTO-03 through AUTO-08)

    func testCodeEntryPage() {
        // AUTO-03: Code entry page has 6 text inputs, no radios/checkboxes/textareas
        let elements = PageElements(
            radioCount: 0,
            radioNames: [],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 6,
            textInputs: ["input1", "input2", "input3", "input4", "input5", "input6"],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 0)
        XCTAssertEqual(result, .codeEntry, "Page 0 with 6 text inputs should be classified as codeEntry")
    }

    func testRadioSatisfactionPage() {
        // AUTO-05: Multiple radio groups -> satisfaction page
        let elements = PageElements(
            radioCount: 3,
            radioNames: ["Q1", "Q2", "Q3"],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 0,
            textInputs: [],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 2)
        XCTAssertEqual(result, .radioSatisfaction, "Page with 3 radio groups should be classified as radioSatisfaction")
    }

    func testRadioYesNoPage() {
        // AUTO-06: 1 radio group with exactly 2 values -> yes/no page
        let elements = PageElements(
            radioCount: 1,
            radioNames: ["YesNo"],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 0,
            textInputs: [],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 3)
        XCTAssertEqual(result, .radioYesNo, "Page with 1 radio group should be classified as radioYesNo")
    }

    func testCheckboxPage() {
        // AUTO-07: Checkboxes present, no radios
        let elements = PageElements(
            radioCount: 0,
            radioNames: [],
            checkboxCount: 5,
            checkboxes: [
                CheckboxInfo(name: "cb1", value: "1", id: "cb1"),
                CheckboxInfo(name: "cb2", value: "2", id: "cb2"),
                CheckboxInfo(name: "cb3", value: "3", id: "cb3"),
                CheckboxInfo(name: "cb4", value: "4", id: "cb4"),
                CheckboxInfo(name: "cb5", value: "5", id: "cb5"),
            ],
            textInputCount: 0,
            textInputs: [],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 5)
        XCTAssertEqual(result, .checkbox, "Page with 5 checkboxes and no radios should be classified as checkbox")
    }

    func testTextareaPage() {
        // AUTO-08: Textareas present, no radios/checkboxes/text inputs
        let elements = PageElements(
            radioCount: 0,
            radioNames: [],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 0,
            textInputs: [],
            textareaCount: 2,
            textareas: ["feedback1", "feedback2"]
        )
        let result = classifyPage(elements: elements, pageNum: 7)
        XCTAssertEqual(result, .textarea, "Page with 2 textareas and nothing else should be classified as textarea")
    }

    func testEmailInputPage() {
        // AUTO-04: Text inputs < 6, no radios/checkboxes/textareas -> email page
        let elements = PageElements(
            radioCount: 0,
            radioNames: [],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 2,
            textInputs: ["email", "confirm"],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 10)
        XCTAssertEqual(result, .emailInput, "Page with 2 text inputs (< 6) should be classified as emailInput")
    }

    func testFinishDetectionPriority() {
        // AUTO-09: Page with no elements after page 0 returns unknown (finish is separate)
        let elements = PageElements(
            radioCount: 0,
            radioNames: [],
            checkboxCount: 0,
            checkboxes: [],
            textInputCount: 0,
            textInputs: [],
            textareaCount: 0,
            textareas: []
        )
        let result = classifyPage(elements: elements, pageNum: 12)
        XCTAssertEqual(result, .unknown, "Page with no elements should be classified as unknown (finish detection is separate)")
    }

    func testCodeChunking() {
        // AUTO-03: 24-char code splits into 6 chunks of 4
        let code = "ABCD1234EFGH5678IJKL9012"
        let chunks = stride(from: 0, to: code.count, by: 4).map { offset -> String in
            let start = code.index(code.startIndex, offsetBy: offset)
            let end = code.index(start, offsetBy: 4, limitedBy: code.endIndex) ?? code.endIndex
            return String(code[start..<end])
        }
        XCTAssertEqual(chunks.count, 6, "24-char code should produce 6 chunks")
        XCTAssertEqual(chunks, ["ABCD", "1234", "EFGH", "5678", "IJKL", "9012"], "Chunks should be 4 chars each in order")
    }
}
