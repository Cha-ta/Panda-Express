import XCTest
@testable import PandaAutomator

final class JSSnippetTests: XCTestCase {

    // MARK: - detectPageElements JS Snippet Tests (AUTO-05, AUTO-06, AUTO-07, AUTO-08)

    func testDetectPageElementsContainsRadioQuery() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("input[type=\"radio\"]"), "detectPageElements JS must query for radio inputs")
    }

    func testDetectPageElementsContainsCheckboxQuery() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("input[type=\"checkbox\"]"), "detectPageElements JS must query for checkbox inputs")
    }

    func testDetectPageElementsContainsTextInputQuery() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("input[type=\"text\"]"), "detectPageElements JS must query for text inputs")
    }

    func testDetectPageElementsReturnsJSON() {
        let js = JSSnippets.detectPageElements
        XCTAssertTrue(js.contains("JSON.stringify"), "detectPageElements JS must return JSON via JSON.stringify")
    }

    // MARK: - clickNext JS Snippet Tests (AUTO-10)

    func testClickNextContainsAllSelectors() {
        let js = JSSnippets.clickNext
        XCTAssertTrue(js.contains("#NextButton"), "clickNext must try #NextButton selector")
        XCTAssertTrue(js.contains("input[value=\"Next\"]"), "clickNext must try input[value=\"Next\"] selector")
        XCTAssertTrue(js.contains(".NextButton"), "clickNext must try .NextButton selector")
    }

    // MARK: - isFinishPage JS Snippet Tests (AUTO-09)

    func testIsFinishPageContainsIndicators() {
        let js = JSSnippets.isFinishPage
        XCTAssertTrue(
            js.lowercased().contains("your validation code"),
            "isFinishPage JS must detect 'your validation code' text"
        )
        XCTAssertTrue(
            js.lowercased().contains("thank you for completing"),
            "isFinishPage JS must detect 'thank you for completing' text"
        )
    }

    // MARK: - Interaction JS Snippet Tests (AUTO-03, AUTO-04, AUTO-05)

    func testFillTextInputDispatchesEvents() {
        let js = JSSnippets.fillTextInput(name: "test", value: "val")
        XCTAssertTrue(js.contains("dispatchEvent"), "fillTextInput must dispatch events for React compatibility")
        XCTAssertTrue(js.contains("new Event('input'"), "fillTextInput must dispatch an 'input' event")
    }

    func testClickRadioUsesIdDotValue() {
        let js = JSSnippets.clickRadio(name: "Q1", value: "5")
        XCTAssertTrue(js.contains("Q1.5"), "clickRadio must target element by name.value pattern (Q1.5)")
    }
}
