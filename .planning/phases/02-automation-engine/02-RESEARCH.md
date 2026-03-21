# Phase 2: Automation Engine - Research

**Researched:** 2026-03-20
**Domain:** WKWebView JavaScript injection, form automation, navigation state management
**Confidence:** HIGH

## Summary

Phase 2 ports the existing Python/Playwright `script.py` logic into native Swift, driving a hidden WKWebView through the Panda Express feedback survey. The Phase 1 foundation already provides the WKWebView setup, anti-detection scripts, navigation delegate, and JS bridge handler. The core work is implementing a page-by-page state machine that detects form element types, fills them via `evaluateJavaScript`, clicks Next, waits for navigation to complete, and repeats until the thank-you page is detected.

The Python script is the authoritative reference for survey structure and element selection logic. It handles 5 distinct page types: code entry (6 text inputs), radio satisfaction questions (first option), yes/no radio questions (select "No"), checkbox pages (first 2 checked), textarea/email pages. The navigation loop runs up to 15 pages with a finish-page detector checking for absence of `#NextButton` plus completion text indicators.

**Primary recommendation:** Implement automation as an async Swift method on `AutomationEngine` using `evaluateJavaScript` with async/await (the method has native async overloads since iOS 15). Use a continuation-based wrapper on `WKNavigationDelegate.didFinish` to await page loads after clicking Next. Port all JS selectors verbatim from `script.py` -- they are known-working against the live form.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTO-03 | Navigate to pandaexpress.com/feedback and enter survey code chunks | `loadFeedbackPage()` already exists; JS fills 6 text inputs by index -- port `fill_text_by_index` logic |
| AUTO-04 | Select first radio option ("Highly Satisfied") for all rating questions | Port `click_all_radios_first_option` -- uses `document.getElementById('{name}.{value}').click()` pattern |
| AUTO-05 | Select "No" for single Yes/No radio questions | Port yes/no detection: 1 radio group with exactly 2 values, select index 1 |
| AUTO-06 | Check first 2 checkboxes on checkbox pages | Port checkbox logic: `document.getElementById('{id}').click()` for first 2 |
| AUTO-07 | Fill textareas with positive feedback text | Port `fill_all_textareas` -- query `textarea` elements, set value via JS |
| AUTO-08 | Fill text inputs with user email on email pages | Port `fill_all_text_inputs` for pages with < 6 text inputs |
| AUTO-09 | Click Next button and wait for page load between pages | Port `click_next` selectors + use navigation delegate continuation for load wait |
| AUTO-10 | Detect completion (thank-you page) and stop | Port `is_finish_page` -- no `#NextButton` + body text contains finish indicators |
| AUTO-11 | Add random 0.5-1.5s delays between actions | `Task.sleep(nanoseconds:)` with `UInt64.random(in:)` for 0.5-1.5s range |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WebKit (WKWebView) | iOS 16+ | Headless browser for form automation | Already in use from Phase 1; only viable browser engine on iOS |
| Swift Concurrency | Swift 5.5+ | async/await for sequential automation steps | Native language feature; `evaluateJavaScript` has async overload since iOS 15 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation (Task.sleep) | iOS 16+ | Random delays between actions | AUTO-11 human-like timing |
| WKNavigationDelegate | iOS 8+ | Detect page load completion after Next click | AUTO-09 page transition |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `evaluateJavaScript` | `callAsyncJavaScript` | More powerful (supports arguments, promises) but overkill -- all our JS is simple DOM queries; `evaluateJavaScript` matches script.py patterns directly |
| WKNavigationDelegate for load detection | Polling `document.readyState` via JS | Fragile; delegate is the proper WebKit mechanism |
| Single monolithic JS bundle | Per-action JS evaluation calls | Per-action is easier to debug, matches script.py structure, allows Swift-side logging between steps |

## Architecture Patterns

### Recommended Project Structure
```
PandaAutomator/Engine/
    AutomationEngine.swift      # Existing -- add run() implementation + page handlers
    JSBridgeHandler.swift       # Existing -- no changes needed
    PageHandler.swift           # NEW: Element detection + page-type dispatch
    JSSnippets.swift            # NEW: All JavaScript strings as static constants
```

### Pattern 1: Async Page Loop with Navigation Continuation
**What:** The `run()` method becomes an async function that loops through pages. After each Next click, it awaits a continuation that resolves when `WKNavigationDelegate.didFinish` fires.
**When to use:** Every page transition (AUTO-09).
**Example:**
```swift
// AutomationEngine.swift
func run(code: String, email: String) async {
    loadFeedbackPage()
    await waitForNavigation()  // initial page load

    for pageNum in 0..<maxPages {
        if pageNum > 0 && await isFinishPage() {
            onLog?("SUCCESS: Form completed!")
            return
        }

        let elements = await detectPageElements()
        await handlePage(pageNum: pageNum, elements: elements, code: code, email: email)
        await randomDelay()

        guard await clickNext() else {
            onLog?("Next button not found, stopping")
            return
        }
        await waitForNavigation()
    }
}
```

### Pattern 2: Navigation Continuation
**What:** Store a `CheckedContinuation` that the `didFinish` delegate method resumes. This bridges callback-based WebKit navigation to async/await.
**When to use:** After every Next button click.
**Example:**
```swift
private var navigationContinuation: CheckedContinuation<Void, Never>?

func waitForNavigation() async {
    await withCheckedContinuation { continuation in
        self.navigationContinuation = continuation
    }
}

// In WKNavigationDelegate:
nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    Task { @MainActor in
        self.navigationContinuation?.resume()
        self.navigationContinuation = nil
    }
}
```

### Pattern 3: Element Detection via JS (Port from script.py)
**What:** A single JS evaluation returns a dictionary of all form elements on the current page, matching the Python `get_page_elements()` function exactly.
**When to use:** At the start of every page iteration.
**Example:**
```swift
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

func detectPageElements() async -> PageElements {
    let js = """
    (() => {
        const radios = document.querySelectorAll('input[type="radio"]');
        const radioNames = [...new Set(Array.from(radios).map(r => r.name))];
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        const checkboxList = Array.from(checkboxes).map(c => ({name: c.name, value: c.value, id: c.id}));
        const textInputs = document.querySelectorAll('input[type="text"]:not([readonly])');
        const textList = Array.from(textInputs).map(i => i.name);
        const textareas = document.querySelectorAll('textarea');
        const textareaList = Array.from(textareas).map(t => t.name);
        return JSON.stringify({
            radioCount: radioNames.length, radioNames: radioNames,
            checkboxCount: checkboxList.length, checkboxes: checkboxList,
            textInputCount: textList.length, textInputs: textList,
            textareaCount: textareaList.length, textareas: textareaList
        });
    })()
    """;
    // evaluateJavaScript returns Any?, cast to String, then decode
}
```

### Pattern 4: Page Type Dispatch (Direct Port of script.py Logic)
**What:** A switch/if-else chain that mirrors `script.py`'s page handling: page 0 code entry, radio pages, checkbox pages, textarea pages, email pages.
**When to use:** Core automation loop body.

### Anti-Patterns to Avoid
- **Injecting a single giant JS automation script:** Loses Swift-side control and logging; impossible to add delays between steps from Swift; harder to debug. Keep JS snippets small and drive sequencing from Swift.
- **Using `page` content world:** Always use `.defaultClient` world (or omit the parameter) for injected JS to avoid conflicts with the website's own scripts.
- **Forgetting to await navigation after Next click:** The page DOM will be from the OLD page if you evaluate JS before the new page loads. Always `await waitForNavigation()`.
- **Setting values via `.value =` without triggering events:** Some form frameworks (React/Angular) do not detect programmatic `.value` changes. Use `.click()` for radio/checkbox (matching script.py) and for text inputs use `input.value = 'x'; input.dispatchEvent(new Event('input', {bubbles: true}))` to trigger form framework detection.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async/await for evaluateJavaScript | Callback-based chains | Native async overload (iOS 15+) | Built-in, no wrapping needed since our target is iOS 16+ |
| Navigation wait | Polling loops with sleep | CheckedContinuation + WKNavigationDelegate | Proper event-driven approach; polling wastes CPU and is timing-fragile |
| JSON parsing of JS results | Manual string parsing | JSONDecoder with Codable structs | Type-safe, handles edge cases |
| Random delay | Custom timer/dispatch | `Task.sleep(nanoseconds:)` | Cooperative cancellation, no thread blocking |

**Key insight:** The entire automation logic already exists in `script.py`. The job is translation, not invention. Port selectors and logic verbatim rather than guessing at form structure.

## Common Pitfalls

### Pitfall 1: evaluateJavaScript Returns Nil for Void-Returning JS
**What goes wrong:** `evaluateJavaScript` with async/await crashes if the JS expression does not return a value (known WebKit bug in some iOS versions).
**Why it happens:** The async overload uses a continuation internally that fails on nil results.
**How to avoid:** Always return a value from JS expressions, even if just `true` or `'done'`. For click operations: `(() => { document.getElementById('x').click(); return true; })()`.
**Warning signs:** EXC_BAD_ACCESS crashes during click/fill operations.

### Pitfall 2: Navigation Continuation Never Resumes
**What goes wrong:** `waitForNavigation()` hangs forever if the page does not trigger a full navigation (e.g., SPA-style in-page transition, or JS error prevents navigation).
**Why it happens:** `didFinish` only fires for full page loads, not DOM updates.
**How to avoid:** Add a timeout to the continuation (e.g., 15 seconds). Use `withCheckedContinuation` wrapped in a `Task` with `Task.sleep` timeout race.
**Warning signs:** App freezes after clicking Next on a particular page.

### Pitfall 3: JS Execution on Wrong Page
**What goes wrong:** JS runs against the old DOM because the new page has not loaded yet.
**Why it happens:** `evaluateJavaScript` fires immediately; if called before navigation completes, it hits stale content.
**How to avoid:** Always await navigation completion before any JS evaluation on the new page.
**Warning signs:** "Element not found" errors, detecting wrong element counts.

### Pitfall 4: Text Input Values Not Detected by Form Framework
**What goes wrong:** The form appears filled but clicking Next shows validation errors ("field required").
**Why it happens:** The survey form likely uses a JS framework that listens for `input` or `change` events, not just `.value` changes.
**How to avoid:** After setting `.value`, dispatch synthetic events: `input.dispatchEvent(new Event('input', {bubbles: true})); input.dispatchEvent(new Event('change', {bubbles: true}))`.
**Warning signs:** Survey shows validation errors despite visually filled fields.

### Pitfall 5: WKWebView Throttling When Backgrounded
**What goes wrong:** JS execution slows dramatically or stops.
**Why it happens:** iOS throttles WKWebView when the app is not in foreground or the webview is not in the window hierarchy.
**How to avoid:** Phase 1 already attaches the webview to the window. Ensure user keeps app in foreground during automation (expected behavior for this app).
**Warning signs:** Automation takes 10x longer than expected.

### Pitfall 6: MainActor Isolation with Async
**What goes wrong:** Concurrency warnings or runtime crashes when calling `evaluateJavaScript` from wrong context.
**Why it happens:** `AutomationEngine` is `@MainActor`-isolated, and `evaluateJavaScript` must run on main thread.
**How to avoid:** Keep `AutomationEngine` as `@MainActor` (already is). All async methods on the class automatically run on MainActor. No need for manual dispatch.
**Warning signs:** Purple runtime warnings about main thread violations.

## Code Examples

Verified patterns from the existing codebase and script.py:

### Random Delay (AUTO-11)
```swift
func randomDelay() async {
    let nanoseconds = UInt64.random(in: 500_000_000...1_500_000_000)  // 0.5-1.5s
    try? await Task.sleep(nanoseconds: nanoseconds)
}
```

### Click Next Button (AUTO-09) -- Port of script.py click_next
```swift
func clickNext() async -> Bool {
    let js = """
    (() => {
        const selectors = ['#NextButton', 'input[value="Next"]', '.NextButton'];
        for (const sel of selectors) {
            const el = document.querySelector(sel);
            if (el) { el.click(); return sel; }
        }
        return null;
    })()
    """
    let result = try? await webView.evaluateJavaScript(js)
    if let selector = result as? String {
        onLog?("Clicked next: \(selector)")
        return true
    }
    onLog?("Next button not found!")
    return false
}
```

### Finish Page Detection (AUTO-10) -- Port of script.py is_finish_page
```swift
func isFinishPage() async -> Bool {
    let js = """
    (() => {
        const hasNext = document.querySelector('#NextButton') !== null;
        if (hasNext) return false;
        const text = document.body.innerText.toLowerCase();
        const indicators = [
            'your validation code',
            'thank you for completing',
            'survey complete',
            'your code will be emailed',
            'we appreciate your feedback'
        ];
        return indicators.some(i => text.includes(i));
    })()
    """
    return (try? await webView.evaluateJavaScript(js)) as? Bool ?? false
}
```

### Fill Text Input with Event Dispatch (AUTO-03, AUTO-08)
```swift
func fillTextInput(name: String, value: String) async {
    let js = """
    (() => {
        const input = document.querySelector('input[name="\(name)"]');
        if (!input) return false;
        input.value = '\(value)';
        input.dispatchEvent(new Event('input', {bubbles: true}));
        input.dispatchEvent(new Event('change', {bubbles: true}));
        return true;
    })()
    """
    let _ = try? await webView.evaluateJavaScript(js)
}
```

### Radio Button Click (AUTO-04, AUTO-05)
```swift
func clickRadio(name: String, value: String) async {
    let inputId = "\(name).\(value)"
    let js = "(() => { document.getElementById('\(inputId)').click(); return true; })()"
    let _ = try? await webView.evaluateJavaScript(js)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `evaluateJavaScript` with completion handler | `evaluateJavaScript` async overload | iOS 15 / Swift 5.5 | Can use async/await natively, no callback nesting |
| `UIApplication.shared.windows` | `connectedScenes` API | iOS 15 deprecation | Phase 1 already uses correct approach |
| Manual string interpolation for JS | Static JS constants with parameter substitution | Best practice | Prevents injection bugs, easier to test |

**Deprecated/outdated:**
- `UIWebView`: Removed entirely; WKWebView is the only option
- `evaluateJavaScript` completion handler pattern: Still works but async overload is cleaner

## Open Questions

1. **Survey form selectors may have changed since script.py was written**
   - What we know: script.py uses specific selectors (`#NextButton`, `input[type="radio"][name="..."]`, element IDs like `{name}.{value}`)
   - What's unclear: Whether the live form has been updated since the Python script last worked
   - Recommendation: Port selectors as-is from script.py; if they fail, the log will show "element not found" and we can adjust. STATE.md already flags this as a known concern.

2. **Exact page count of the survey**
   - What we know: script.py uses max_pages=15; STATE.md says "~15 (estimate)"
   - What's unclear: Whether the count varies by response path (selecting "No" on yes/no questions may skip follow-up pages)
   - Recommendation: Keep max_pages=15 as a safety cap; rely on finish-page detection for actual termination

3. **Text input filling vs form framework events**
   - What we know: script.py uses Playwright's `page.fill()` which automatically dispatches events; our WKWebView JS must manually dispatch events
   - What's unclear: Exact events the survey form framework requires
   - Recommendation: Dispatch both `input` and `change` events after setting `.value`; if validation fails, also try `blur` and `keyup`

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode-bundled) |
| Config file | PandaAutomator.xcodeproj (test target: PandaAutomatorTests) |
| Quick run command | `xcodebuild test -project PandaAutomator/PandaAutomator.xcodeproj -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PandaAutomatorTests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -project PandaAutomator/PandaAutomator.xcodeproj -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTO-03 | Code entry fills 6 text inputs | unit | Test JS snippet produces correct fill calls for chunked code | No -- Wave 0 |
| AUTO-04 | First radio option selected for rating questions | unit | Test page handler selects index 0 for multi-radio pages | No -- Wave 0 |
| AUTO-05 | "No" selected for yes/no questions | unit | Test page handler selects index 1 when radioCount==1 and values==2 | No -- Wave 0 |
| AUTO-06 | First 2 checkboxes checked | unit | Test page handler clicks first 2 checkbox IDs | No -- Wave 0 |
| AUTO-07 | Textareas filled with feedback text | unit | Test JS snippet fills all textareas | No -- Wave 0 |
| AUTO-08 | Email filled in text inputs | unit | Test page handler fills email for textInputCount < 6 | No -- Wave 0 |
| AUTO-09 | Next button clicked + navigation waited | unit | Test clickNext JS tries all selector fallbacks | No -- Wave 0 |
| AUTO-10 | Finish page detected | unit | Test isFinishPage JS returns true for each indicator string | No -- Wave 0 |
| AUTO-11 | Random delays between actions | unit | Test delay range is 0.5-1.5s | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command (unit tests only)
- **Per wave merge:** Full suite command
- **Phase gate:** Full suite green before verification

### Wave 0 Gaps
- [ ] `PandaAutomatorTests/AutomationFlowTests.swift` -- covers AUTO-03 through AUTO-11 page handler dispatch logic
- [ ] `PandaAutomatorTests/JSSnippetTests.swift` -- covers JS string correctness (element detection, click, fill)
- [ ] `PandaAutomatorTests/NavigationWaitTests.swift` -- covers AUTO-09 continuation timeout behavior

**Note:** Full integration testing requires a live survey code, which is single-use. Unit tests should validate JS snippet correctness and page-type dispatch logic using mock PageElements structs. Integration testing must be manual with a real receipt code.

## Sources

### Primary (HIGH confidence)
- [Apple evaluateJavaScript docs](https://developer.apple.com/documentation/webkit/wkwebview/evaluatejavascript(_:completionhandler:)) -- API reference, async overload availability
- [Apple callAsyncJavaScript docs](https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript) -- alternative API (not recommended for this use case)
- [Apple webView(_:didFinish:) docs](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webview(_:didfinish:)) -- navigation completion detection
- Existing `script.py` in project root -- authoritative reference for selectors, page logic, form structure

### Secondary (MEDIUM confidence)
- [Hacking with Swift -- evaluateJavaScript](https://www.hackingwithswift.com/example-code/wkwebview/how-to-run-javascript-on-a-wkwebview-with-evaluatejavascript) -- usage patterns
- [Apple Developer Forums -- evaluateJavaScript crash](https://developer.apple.com/forums/thread/701553) -- known issue with nil returns
- [Swift Forums -- concurrency warnings](https://forums.swift.org/t/concurrency-warning-when-using-wkwebview-evaluatejavascript-and-async-let/76836) -- MainActor threading

### Tertiary (LOW confidence)
- [Survey structure blog posts](https://surveysaga.com/pandaexpress-com-feedback/) -- general survey flow description (not verified against live form)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- WKWebView is the only option on iOS; async/await is built-in Swift
- Architecture: HIGH -- direct port of working script.py; patterns are well-established
- Pitfalls: HIGH -- known WebKit issues well-documented in Apple forums; threading model clear
- Selectors: MEDIUM -- script.py selectors are known-working but form may have been updated

**Research date:** 2026-03-20
**Valid until:** 2026-04-03 (14 days -- survey form structure could change; WebKit APIs are stable)
