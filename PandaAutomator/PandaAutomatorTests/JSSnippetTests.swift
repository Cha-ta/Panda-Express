import XCTest
@testable import PandaAutomator

final class JSSnippetTests: XCTestCase {

    // MARK: - detectPageElements

    func testDetectPageElementsIsIIFE() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("(() =>"), "Must be wrapped in IIFE")
        XCTAssertTrue(js.contains("})()"), "IIFE must self-invoke")
    }

    func testDetectPageElementsReturnsJSON() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("JSON.stringify"), "detectPageElements JS must return JSON via JSON.stringify")
    }

    func testDetectPageElementsQueriesAllElementTypes() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("input[type=\"radio\"]"), "Must query radio inputs")
        XCTAssertTrue(js.contains("input[type=\"checkbox\"]"), "Must query checkbox inputs")
        XCTAssertTrue(js.contains("input[type=\"text\"]:not([readonly])"), "Must query non-readonly text inputs")
        XCTAssertTrue(js.contains("textarea"), "Must query textareas")
    }

    func testDetectPageElementsReturnsExpectedFields() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("radioCount"), "Must include radioCount")
        XCTAssertTrue(js.contains("radioNames"), "Must include radioNames")
        XCTAssertTrue(js.contains("checkboxCount"), "Must include checkboxCount")
        XCTAssertTrue(js.contains("checkboxes"), "Must include checkboxes")
        XCTAssertTrue(js.contains("textInputCount"), "Must include textInputCount")
        XCTAssertTrue(js.contains("textInputs"), "Must include textInputs")
        XCTAssertTrue(js.contains("textareaCount"), "Must include textareaCount")
        XCTAssertTrue(js.contains("textareas"), "Must include textareas")
    }

    // MARK: - isFinishPage

    func testIsFinishPageIsIIFE() {
        let js = JSSnippets.isFinishPage
        XCTAssertTrue(js.contains("(() =>"), "Must be wrapped in IIFE")
        XCTAssertTrue(js.contains("})()"), "IIFE must self-invoke")
    }

    func testIsFinishPageChecksNextButton() {
        let js = JSSnippets.isFinishPage
        XCTAssertTrue(js.contains("#NextButton"), "Must check for #NextButton")
    }

    func testIsFinishPageChecksAllIndicators() {
        let js = JSSnippets.isFinishPage
        XCTAssertTrue(js.lowercased().contains("your validation code"), "Must check 'your validation code'")
        XCTAssertTrue(js.lowercased().contains("thank you for completing"), "Must check 'thank you for completing'")
        XCTAssertTrue(js.lowercased().contains("survey complete"), "Must check 'survey complete'")
        XCTAssertTrue(js.lowercased().contains("your code will be emailed"), "Must check 'your code will be emailed'")
        XCTAssertTrue(js.lowercased().contains("we appreciate your feedback"), "Must check 'we appreciate your feedback'")
    }

    // MARK: - clickNext

    func testClickNextIsIIFE() {
        let js = JSSnippets.clickNext
        XCTAssertTrue(js.contains("(() =>"), "Must be wrapped in IIFE")
        XCTAssertTrue(js.contains("})()"), "IIFE must self-invoke")
    }

    func testClickNextTriesAllSelectors() {
        let js = JSSnippets.clickNext
        XCTAssertTrue(js.contains("#NextButton"), "Must try #NextButton")
        XCTAssertTrue(js.contains("input[value=\"Next\"]"), "Must try input[value='Next']")
        XCTAssertTrue(js.contains(".NextButton"), "Must try .NextButton")
    }

    func testClickNextNoPlaywrightPseudoSelectors() {
        let js = JSSnippets.clickNext
        XCTAssertFalse(js.contains(":has-text"), "Must NOT use Playwright-only :has-text pseudo-selector")
    }

    func testClickNextHandlesButtonElement() {
        let js = JSSnippets.clickNext
        XCTAssertTrue(js.contains("button"), "Must handle button elements with Next text")
    }

    // MARK: - fillTextInput

    func testFillTextInputDispatchesEvents() {
        let js = JSSnippets.fillTextInput(name: "testField", value: "testValue")
        XCTAssertTrue(js.contains("dispatchEvent"), "Must dispatch events")
        XCTAssertTrue(js.contains("new Event('input'"), "Must dispatch input event")
        XCTAssertTrue(js.contains("new Event('change'"), "Must dispatch change event")
        XCTAssertTrue(js.contains("bubbles"), "Events must bubble")
    }

    func testFillTextInputUsesCorrectSelector() {
        let js = JSSnippets.fillTextInput(name: "email", value: "test@example.com")
        XCTAssertTrue(js.contains("email"), "Must use the provided name in selector")
    }

    func testFillTextInputReturnsValue() {
        let js = JSSnippets.fillTextInput(name: "f", value: "v")
        XCTAssertTrue(js.contains("return"), "Must return a value (not void)")
    }

    // MARK: - clickRadio

    func testClickRadioUsesIdDotValue() {
        let js = JSSnippets.clickRadio(name: "R001234", value: "1")
        XCTAssertTrue(js.contains("getElementById"), "Must use getElementById")
        XCTAssertTrue(js.contains("R001234.1"), "Must use name.value format for ID")
    }

    func testClickRadioReturnsValue() {
        let js = JSSnippets.clickRadio(name: "R001234", value: "1")
        XCTAssertTrue(js.contains("return"), "Must return a value")
    }

    // MARK: - clickCheckbox

    func testClickCheckboxUsesGetElementById() {
        let js = JSSnippets.clickCheckbox(id: "CB_001")
        XCTAssertTrue(js.contains("getElementById"), "Must use getElementById")
        XCTAssertTrue(js.contains("CB_001"), "Must use the provided ID")
    }

    func testClickCheckboxReturnsValue() {
        let js = JSSnippets.clickCheckbox(id: "CB_001")
        XCTAssertTrue(js.contains("return"), "Must return a value")
    }

    // MARK: - fillTextarea

    func testFillTextareaDispatchesEvents() {
        let js = JSSnippets.fillTextarea(name: "comments", value: "Great food!")
        XCTAssertTrue(js.contains("dispatchEvent"), "Must dispatch events")
        XCTAssertTrue(js.contains("new Event('input'"), "Must dispatch input event")
        XCTAssertTrue(js.contains("new Event('change'"), "Must dispatch change event")
    }

    func testFillTextareaUsesCorrectSelector() {
        let js = JSSnippets.fillTextarea(name: "comments", value: "Great food!")
        XCTAssertTrue(js.contains("textarea[name=\"comments\"]"), "Must query textarea by name")
    }

    func testFillTextareaReturnsValue() {
        let js = JSSnippets.fillTextarea(name: "c", value: "v")
        XCTAssertTrue(js.contains("return"), "Must return a value")
    }

    // MARK: - getRadioValues

    func testGetRadioValuesQueriesCorrectSelector() {
        let js = JSSnippets.getRadioValues(name: "R001234")
        XCTAssertTrue(js.contains("input[type=\"radio\"][name=\"R001234\"]"), "Must query radio by name")
    }

    func testGetRadioValuesReturnsJSONStringify() {
        let js = JSSnippets.getRadioValues(name: "R001234")
        XCTAssertTrue(js.contains("JSON.stringify"), "Must return JSON.stringify array")
    }

    // MARK: - fillTextByIndex

    func testFillTextByIndexUsesCorrectIndex() {
        let js = JSSnippets.fillTextByIndex(index: 3, value: "ABCD")
        XCTAssertTrue(js.contains("[3]"), "Must access element at provided index")
        XCTAssertTrue(js.contains("ABCD"), "Must use the provided value")
    }

    func testFillTextByIndexDispatchesEvents() {
        let js = JSSnippets.fillTextByIndex(index: 0, value: "test")
        XCTAssertTrue(js.contains("dispatchEvent"), "Must dispatch events")
        XCTAssertTrue(js.contains("new Event('input'"), "Must dispatch input event")
        XCTAssertTrue(js.contains("new Event('change'"), "Must dispatch change event")
    }

    func testFillTextByIndexQueriesNonReadonly() {
        let js = JSSnippets.fillTextByIndex(index: 0, value: "test")
        XCTAssertTrue(js.contains("input[type=\"text\"]:not([readonly])"), "Must query non-readonly text inputs")
    }

    func testFillTextByIndexReturnsValue() {
        let js = JSSnippets.fillTextByIndex(index: 0, value: "test")
        XCTAssertTrue(js.contains("return"), "Must return a value")
    }
}
