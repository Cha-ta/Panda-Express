import UIKit
import WebKit

@MainActor
class AutomationEngine: NSObject {

    private var webView: WKWebView!
    private let bridgeHandler = JSBridgeHandler()

    // MARK: - Navigation Continuation

    /// Bridges WKNavigationDelegate callbacks to async/await.
    private var navigationContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Constants

    /// Maximum pages before stopping automation loop (safety cap matching script.py).
    static let maxPages = 15

    /// Default positive feedback text matching script.py line 241.
    private let feedbackText = "Great food and excellent service!"

    // MARK: - Callbacks

    var onLog: ((String) -> Void)? {
        didSet {
            bridgeHandler.onLog = onLog
        }
    }

    // MARK: - Setup

    func setup() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        // Anti-detection scripts injected BEFORE page JS runs
        let antiDetectSource = """
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
        """
        let antiDetect = WKUserScript(
            source: antiDetectSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(antiDetect)
        controller.add(bridgeHandler, name: "log")

        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // CRITICAL: must be in window hierarchy or JS is throttled
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        scene?.windows.first?.addSubview(webView)
    }

    func loadFeedbackPage() {
        guard let url = URL(string: "https://www.pandaexpress.com/feedback") else { return }
        webView.load(URLRequest(url: url))
    }

    // MARK: - Automation Run Loop

    /// Complete async automation loop. Navigates through all survey pages.
    /// Ports script.py main loop (lines 183-261).
    func run(code: String, email: String) async -> AutomationResult {
        loadFeedbackPage()
        await waitForNavigation()
        await randomDelay()

        for pageNum in 0..<Self.maxPages {
            onLog?("=== PAGE \(pageNum) ===")

            // Finish check after page 0 (matches script.py line 191)
            if pageNum > 0 {
                let finished = await isFinishPage()
                if finished {
                    onLog?("SUCCESS: Form completed!")
                    return .success
                }
            }

            guard let elements = await detectPageElements() else {
                onLog?("ERROR: Could not detect page elements")
                return .error("Could not detect page elements on page \(pageNum)")
            }

            let pageType = classifyPage(elements: elements, pageNum: pageNum)
            onLog?("Page type: \(pageType), radios: \(elements.radioCount), checkboxes: \(elements.checkboxCount), texts: \(elements.textInputCount), textareas: \(elements.textareaCount)")

            await handlePage(pageNum: pageNum, pageType: pageType, elements: elements, code: code, email: email)
            await randomDelay()

            guard await clickNext() else {
                onLog?("Could not find Next button, stopping")
                return .error("Next button not found on page \(pageNum)")
            }
            await waitForNavigation()
        }

        onLog?("Reached max pages (\(Self.maxPages)), stopping")
        return .maxPagesReached
    }

    // MARK: - Navigation Wait

    /// Waits for WKNavigationDelegate didFinish callback via CheckedContinuation.
    /// Includes a timeout race to prevent Pitfall 2 (hanging forever).
    private func waitForNavigation(timeout: TimeInterval = 15) async {
        await withCheckedContinuation { continuation in
            self.navigationContinuation = continuation
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if self.navigationContinuation != nil {
                    self.navigationContinuation?.resume()
                    self.navigationContinuation = nil
                    self.onLog?("WARNING: Navigation timeout after \(timeout)s")
                }
            }
        }
    }

    // MARK: - Random Delay

    /// Random delay between actions to appear human-like (0.5-1.5s).
    /// Matches script.py human_delay() and AUTO-11.
    /// NOTE: Internal (not private) so NavigationWaitTests can call it.
    static func randomDelay() async {
        let nanoseconds = UInt64.random(in: 500_000_000...1_500_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    /// Instance method wrapper for convenience in the run loop.
    func randomDelay() async {
        await Self.randomDelay()
    }

    // MARK: - Page Detection

    /// Evaluates JSSnippets.detectPageElements and decodes the result into PageElements.
    private func detectPageElements() async -> PageElements? {
        do {
            let result = try await webView.evaluateJavaScript(JSSnippets.detectPageElements)
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8) else {
                onLog?("WARNING: detectPageElements returned non-string result")
                return nil
            }
            let elements = try JSONDecoder().decode(PageElements.self, from: data)
            onLog?("Detected: \(elements.radioCount) radios, \(elements.checkboxCount) checkboxes, \(elements.textInputCount) texts, \(elements.textareaCount) textareas")
            return elements
        } catch {
            onLog?("ERROR: detectPageElements failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Checks if the current page is the finish/thank-you page.
    private func isFinishPage() async -> Bool {
        do {
            let result = try await webView.evaluateJavaScript(JSSnippets.isFinishPage)
            return result as? Bool ?? false
        } catch {
            onLog?("WARNING: isFinishPage check failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Clicks the Next button using fallback selectors.
    private func clickNext() async -> Bool {
        do {
            let result = try await webView.evaluateJavaScript(JSSnippets.clickNext)
            if let selector = result as? String {
                onLog?("Clicked Next via: \(selector)")
                return true
            }
            onLog?("Next button not found")
            return false
        } catch {
            onLog?("ERROR: clickNext failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Page Handlers

    /// Dispatches page-specific form filling based on classified page type.
    private func handlePage(pageNum: Int, pageType: PageType, elements: PageElements, code: String, email: String) async {
        switch pageType {
        case .codeEntry:
            await handleCodeEntry(code: code)
        case .radioSatisfaction:
            await handleRadioSatisfaction(elements: elements)
        case .radioYesNo:
            await handleRadioYesNo(elements: elements)
        case .checkbox:
            await handleCheckbox(elements: elements)
        case .textarea:
            await handleTextarea(elements: elements)
        case .emailInput:
            await handleEmailInput(elements: elements, email: email)
        case .unknown:
            onLog?("No actionable elements found on page \(pageNum)")
        }
    }

    /// Code entry: fills 6 text inputs with 4-char code chunks.
    private func handleCodeEntry(code: String) async {
        let chunks = chunkCode(code)
        for (i, chunk) in chunks.enumerated() {
            do {
                try await webView.evaluateJavaScript(JSSnippets.fillTextByIndex(index: i, value: chunk))
                onLog?("Filled code chunk \(i): \(chunk)")
            } catch {
                onLog?("WARNING: Failed to fill code chunk \(i): \(error.localizedDescription)")
            }
            if i < chunks.count - 1 {
                await randomDelay()
            }
        }
    }

    /// Radio satisfaction: selects first option for each radio group.
    private func handleRadioSatisfaction(elements: PageElements) async {
        for (i, name) in elements.radioNames.enumerated() {
            do {
                let result = try await webView.evaluateJavaScript(JSSnippets.getRadioValues(name: name))
                if let jsonString = result as? String,
                   let data = jsonString.data(using: .utf8),
                   let values = try? JSONDecoder().decode([String].self, from: data),
                   let firstValue = values.first {
                    try await webView.evaluateJavaScript(JSSnippets.clickRadio(name: name, value: firstValue))
                    onLog?("Radio \(name): selected '\(firstValue)'")
                } else {
                    onLog?("WARNING: No values found for radio \(name)")
                }
            } catch {
                onLog?("WARNING: Failed to handle radio \(name): \(error.localizedDescription)")
            }
            if i < elements.radioNames.count - 1 {
                await randomDelay()
            }
        }
    }

    /// Radio yes/no: selects "No" (index 1) if exactly 2 values, else first option.
    /// Matches script.py lines 207-228.
    private func handleRadioYesNo(elements: PageElements) async {
        guard let name = elements.radioNames.first else {
            onLog?("WARNING: radioYesNo page but no radio names found")
            return
        }
        do {
            let result = try await webView.evaluateJavaScript(JSSnippets.getRadioValues(name: name))
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let values = try? JSONDecoder().decode([String].self, from: data),
               !values.isEmpty {
                // If exactly 2 values, pick index 1 ("No"); otherwise first option
                let selectedIndex = values.count == 2 ? 1 : 0
                let selectedValue = values[selectedIndex]
                try await webView.evaluateJavaScript(JSSnippets.clickRadio(name: name, value: selectedValue))
                onLog?("YesNo \(name): selected '\(selectedValue)' (index \(selectedIndex))")
            } else {
                onLog?("WARNING: No values found for yesNo radio \(name)")
            }
        } catch {
            onLog?("WARNING: Failed to handle yesNo radio \(name): \(error.localizedDescription)")
        }
    }

    /// Checkbox: checks first 2 checkboxes.
    private func handleCheckbox(elements: PageElements) async {
        let toCheck = elements.checkboxes.prefix(2)
        for (i, cb) in toCheck.enumerated() {
            let cbId = cb.id.isEmpty ? "\(cb.name).\(cb.value)" : cb.id
            do {
                try await webView.evaluateJavaScript(JSSnippets.clickCheckbox(id: cbId))
                onLog?("Checked checkbox: \(cbId)")
            } catch {
                onLog?("WARNING: Failed to check checkbox \(cbId): \(error.localizedDescription)")
            }
            if i < toCheck.count - 1 {
                await randomDelay()
            }
        }
    }

    /// Textarea: fills with positive feedback text.
    private func handleTextarea(elements: PageElements) async {
        for (i, name) in elements.textareas.enumerated() {
            do {
                try await webView.evaluateJavaScript(JSSnippets.fillTextarea(name: name, value: feedbackText))
                onLog?("Filled textarea: \(name)")
            } catch {
                onLog?("WARNING: Failed to fill textarea \(name): \(error.localizedDescription)")
            }
            if i < elements.textareas.count - 1 {
                await randomDelay()
            }
        }
    }

    /// Email input: fills with user email.
    private func handleEmailInput(elements: PageElements, email: String) async {
        for (i, name) in elements.textInputs.enumerated() {
            do {
                try await webView.evaluateJavaScript(JSSnippets.fillTextInput(name: name, value: email))
                onLog?("Filled email input: \(name)")
            } catch {
                onLog?("WARNING: Failed to fill email input \(name): \(error.localizedDescription)")
            }
            if i < elements.textInputs.count - 1 {
                await randomDelay()
            }
        }
    }

    // MARK: - Testable Accessors

    /// Exposed for unit tests (AntiDetectionTests).
    var userAgent: String {
        webView?.customUserAgent ?? ""
    }

    /// Exposed for unit tests (AntiDetectionTests).
    var userScripts: [WKUserScript] {
        webView?.configuration.userContentController.userScripts ?? []
    }
}

extension AutomationEngine: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.onLog?("Page loaded")
            self.navigationContinuation?.resume()
            self.navigationContinuation = nil
        }
    }
}
