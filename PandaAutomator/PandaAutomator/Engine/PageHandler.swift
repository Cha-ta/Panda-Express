import Foundation

/// Checkbox element metadata decoded from JS detection results.
struct CheckboxInfo: Decodable {
    let name: String
    let value: String
    let id: String
}

/// Form element counts and metadata for the current page.
/// Matches the JSON structure returned by JSSnippets.detectPageElements.
struct PageElements: Decodable {
    let radioCount: Int
    let radioNames: [String]
    let checkboxCount: Int
    let checkboxes: [CheckboxInfo]
    let textInputCount: Int
    let textInputs: [String]
    let textareaCount: Int
    let textareas: [String]
}

/// Page types recognized by the automation engine.
/// Mirrors script.py's page dispatch logic (lines 198-245).
enum PageType: Equatable {
    case codeEntry
    case radioSatisfaction
    case radioYesNo
    case checkbox
    case textarea
    case emailInput
    case unknown
}

/// Classifies the current page based on detected form elements.
/// Priority order matches script.py: code entry > radio > checkbox > textarea > email.
///
/// - Parameters:
///   - elements: The detected page elements from JSSnippets.detectPageElements.
///   - pageNum: Zero-based page index (page 0 is the code entry page).
/// - Returns: The classified page type for dispatch.
func classifyPage(elements: PageElements, pageNum: Int) -> PageType {
    // Page 0 with 6 text inputs is code entry
    if pageNum == 0 && elements.textInputCount == 6 {
        return .codeEntry
    }

    // Radio buttons take priority
    if elements.radioCount > 0 {
        if elements.radioCount == 1 {
            return .radioYesNo
        } else {
            return .radioSatisfaction
        }
    }

    // Checkboxes next
    if elements.checkboxCount > 0 {
        return .checkbox
    }

    // Textareas (feedback)
    if elements.textareaCount > 0 {
        return .textarea
    }

    // Text inputs < 6 (email page)
    if elements.textInputCount > 0 && elements.textInputCount < 6 {
        return .emailInput
    }

    return .unknown
}

/// Splits a 24-character survey code into 6 chunks of 4 characters.
/// Used by the engine for code entry page (matches script.py line 20).
///
/// - Parameter code: The 24-character survey code.
/// - Returns: Array of 6 four-character strings.
func chunkCode(_ code: String) -> [String] {
    stride(from: 0, to: code.count, by: 4).map { offset -> String in
        let start = code.index(code.startIndex, offsetBy: offset)
        let end = code.index(start, offsetBy: 4, limitedBy: code.endIndex) ?? code.endIndex
        return String(code[start..<end])
    }
}
