# Architecture Research

**Domain:** iOS native app with hidden WKWebView automation
**Researched:** 2026-03-18
**Confidence:** HIGH (core WebKit APIs are stable and well-documented; patterns verified across multiple official and community sources)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                       SwiftUI Layer                          │
├──────────────────────┬──────────────────────────────────────┤
│   ContentView        │           LogView                     │
│   (form inputs)      │     (scrolling log output)            │
│   - survey code      │     - real-time automation events     │
│   - email field      │     - status / error messages         │
│   - Start button     │                                       │
└──────────┬───────────┴─────────────────┬────────────────────┘
           │ binds to                    │ binds to
┌──────────▼─────────────────────────────▼────────────────────┐
│                    AutomationViewModel                        │
│         (@Observable / ObservableObject)                      │
│   - surveyCode: String      - email: String                  │
│   - logMessages: [String]   - isRunning: Bool                │
│   - errorMessage: String?   - status: AutomationStatus       │
│                                                               │
│   + startAutomation()       + appendLog(_ message: String)   │
│   + cancelAutomation()                                        │
└──────────────────────────┬──────────────────────────────────┘
                           │ owns + drives
┌──────────────────────────▼──────────────────────────────────┐
│                    AutomationEngine                           │
│         (class, runs on MainActor)                            │
│                                                               │
│   - webView: WKWebView (hidden, off-screen)                  │
│   - config: WKWebViewConfiguration                           │
│   - userContentController: WKUserContentController           │
│                                                               │
│   + loadSurveyURL()                                          │
│   + injectAndExecuteStep()                                    │
│   + evaluateJS(_ script: String) async -> Any?               │
│   + callAsyncJS(_ function: String) async -> Any?            │
└───────────┬──────────────────────────────┬───────────────────┘
            │ WKNavigationDelegate         │ WKScriptMessageHandler
            │ didFinishNavigation          │ receives postMessage
┌───────────▼──────────────────────────────▼───────────────────┐
│                       WKWebView                               │
│         (frame: .zero — invisible to user)                    │
│                                                               │
│   Loads: pandaexpress.com/feedback                            │
│   Executes: injected JavaScript automation scripts            │
│   Sends back: window.webkit.messageHandlers.log.postMessage   │
└──────────────────────────────────────────────────────────────┘
            │ HTTP over device network (WiFi / cellular)
┌───────────▼──────────────────────────────────────────────────┐
│              pandaexpress.com/feedback                        │
│         Multi-page survey form (external)                     │
└──────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| `ContentView` | User-facing input form; survey code, email, start/stop button | SwiftUI `View` |
| `LogView` | Real-time scrolling log of automation progress | SwiftUI `ScrollView` + `Text` |
| `AutomationViewModel` | Single source of truth for all UI state; bridges Engine to Views | `@Observable` class |
| `AutomationEngine` | Owns the hidden WKWebView; drives the automation sequence | `class`, `@MainActor` |
| `WKWebView` (hidden) | Renders pandaexpress.com; executes injected JavaScript | `WKWebView(frame: .zero)` |
| `WKUserContentController` | Registers message handlers (JS→Swift) and user scripts | Part of `WKWebViewConfiguration` |
| `AutomationScript.js` | Bundled JavaScript that detects page state and acts on the form | `.js` file in app bundle |
| `UserDefaults` / `@AppStorage` | Persists email across app launches | `@AppStorage("savedEmail")` |

## Recommended Project Structure

```
PandaAutomator/
├── App/
│   ├── PandaAutomatorApp.swift       # @main entry point
│   └── ContentView.swift             # Root view with tab or stack nav
├── Views/
│   ├── InputFormView.swift           # Survey code + email fields + Start button
│   └── LogView.swift                 # Real-time log scroll view
├── ViewModel/
│   └── AutomationViewModel.swift     # @Observable, owns AutomationEngine
├── Engine/
│   ├── AutomationEngine.swift        # WKWebView creation, JS orchestration
│   ├── PageStepRunner.swift          # Runs one "step" per page (optional split)
│   └── JSBridgeHandler.swift         # WKScriptMessageHandler implementation
├── Scripts/
│   └── automation.js                 # Bundled JavaScript automation logic
├── Models/
│   ├── AutomationStatus.swift        # Enum: idle / running / success / error
│   └── LogEntry.swift                # Struct for timestamped log lines
└── Resources/
    └── Assets.xcassets               # App icon, color assets
```

### Structure Rationale

- **Engine/:** Isolates all WebKit-specific code. The ViewModel never imports WebKit directly — the Engine is the only component that touches WKWebView. This keeps testability clean.
- **Scripts/:** Storing the automation JavaScript as a bundled `.js` file (loaded via `Bundle.main`) keeps it editable without Swift recompilation and mirrors the existing Python `script.py` structure.
- **ViewModel/:** Single `@Observable` class is the contract between UI and Engine. SwiftUI views bind to it; the Engine reports back through it.
- **Models/:** `AutomationStatus` enum drives UI state transitions cleanly (show spinner, show checkmark, show error).

## Architectural Patterns

### Pattern 1: Hidden WKWebView (Frame Zero)

**What:** WKWebView is created with `CGRect.zero` and never added to the visible view hierarchy. It functions as a headless browser embedded in-process.

**When to use:** When the user should not see the browser UI but the app needs real browser rendering (JS execution, cookie management, real network stack).

**Trade-offs:** Simpler than UIViewRepresentable wrapper since no visible rendering is needed. WKWebView must still be retained by a strong reference (usually the Engine class property) or it is deallocated.

**Example:**
```swift
// AutomationEngine.swift
class AutomationEngine: NSObject {
    private var webView: WKWebView!

    func setup() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(self, name: "log")         // JS → Swift log channel
        controller.add(self, name: "pageReady")   // JS signals page is ready
        config.userContentController = controller
        config.applicationNameForUserAgent = "..."

        // frame: .zero — invisible, but fully functional
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)..."
    }
}
```

### Pattern 2: NavigationDelegate-Triggered JS Injection

**What:** `WKNavigationDelegate.webView(_:didFinish:)` fires when each page fully loads. The Engine injects JavaScript here to detect what page has loaded and act on it.

**When to use:** For multi-page form automation where each page is a separate navigation event. This is the equivalent of Playwright's `page.waitForNavigation()` + `page.evaluate()` pattern.

**Trade-offs:** Simple and reliable for full-page navigations. Does not cover SPAs that update the DOM without navigating. For SPAs, polling via `evaluateJavaScript` in a loop is the fallback.

**Example:**
```swift
// AutomationEngine.swift — WKNavigationDelegate
func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    Task { @MainActor in
        await runPageStep()
    }
}

func runPageStep() async {
    // Inject override to suppress webdriver detection
    _ = try? await webView.evaluateJavaScript(
        "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
    )
    // Load and execute the bundled automation script
    if let scriptURL = Bundle.main.url(forResource: "automation", withExtension: "js"),
       let scriptContent = try? String(contentsOf: scriptURL) {
        _ = try? await webView.evaluateJavaScript(scriptContent)
    }
}
```

### Pattern 3: JS→Swift Message Bridge for Log Streaming

**What:** The bundled JavaScript calls `window.webkit.messageHandlers.log.postMessage("message text")` to stream progress back to the native app in real time. Swift receives these via `WKScriptMessageHandler`.

**When to use:** Any time the web-side script needs to report progress, errors, or page state back to the UI. Replaces the Python `print()` / Flask log streaming pattern.

**Trade-offs:** One-way (JS → Swift). Fast and lightweight. The handler fires on the main thread by default — append directly to `@Published` log array without `DispatchQueue.main.async`.

**Example:**
```swift
// JSBridgeHandler.swift
extension AutomationEngine: WKScriptMessageHandler {
    func userContentController(
        _ controller: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? String else { return }
        switch message.name {
        case "log":
            viewModel.appendLog(body)
        case "pageReady":
            // JS signals it detected the thank-you page
            viewModel.status = .success
        default:
            break
        }
    }
}
```

```javascript
// automation.js (bundled, runs inside WKWebView)
function log(msg) {
    window.webkit.messageHandlers.log.postMessage(msg);
}

// Example page action
const radios = document.querySelectorAll('input[type="radio"]');
if (radios.length > 0) {
    radios[0].click();
    log(`Clicked radio: ${radios[0].value}`);
}
```

### Pattern 4: Async/Await JavaScript Evaluation

**What:** iOS 14+ provides `evaluateJavaScript(_:in:in:completionHandler:)` and `callAsyncJavaScript(_:arguments:in:in:completionHandler:)`. With Swift concurrency, these can be wrapped or called as async-throwing functions.

**When to use:** Sequential step execution where each JS call must complete before the next. Avoids nested callback hell.

**Trade-offs:** `evaluateJavaScript` must be called on the main thread. `callAsyncJavaScript` handles JS Promises natively, useful if the injected script awaits DOM changes.

**Example:**
```swift
// Async wrapper (common pattern)
extension WKWebView {
    @MainActor
    func evaluate(_ js: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(js) { result, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: result) }
            }
        }
    }
}
```

## Data Flow

### Automation Start Flow

```
User taps "Start"
    ↓
ContentView → AutomationViewModel.startAutomation(code:email:)
    ↓
AutomationViewModel → AutomationEngine.run(code:email:)
    ↓
AutomationEngine sets webView.customUserAgent
AutomationEngine loads URLRequest(url: pandaexpress.com/feedback?code=...)
    ↓
WKWebView fires didFinishNavigation (page loaded)
    ↓
AutomationEngine.runPageStep() — evaluates automation.js
    ↓
automation.js detects page type → clicks radios/fills fields → clicks Next
    ↓
automation.js calls window.webkit.messageHandlers.log.postMessage("Page 1: clicked 5 radios")
    ↓
JSBridgeHandler.userContentController → AutomationViewModel.appendLog()
    ↓
LogView updates (SwiftUI reactive binding)
    ↓
WKWebView navigates to next page → repeat from didFinishNavigation
    ↓
automation.js detects thank-you page → postMessage on "pageReady" channel
    ↓
AutomationViewModel.status = .success → ContentView shows success state
```

### State Management

```
AutomationViewModel (@Observable)
    ↓ reads (SwiftUI bindings)
ContentView / LogView

AutomationEngine mutations
    ↓ writes to
AutomationViewModel.logMessages / status / isRunning

UserDefaults (@AppStorage)
    ↔ email: String  (persisted across launches, two-way via @AppStorage)
```

### Key Data Flows

1. **Survey code entry to URL construction:** ViewModel holds raw code string → Engine constructs URL with query param before loading.
2. **JavaScript log messages:** JS `postMessage` → `WKScriptMessageHandler` callback → ViewModel `@Published` array → SwiftUI `ScrollView` re-renders.
3. **Page completion detection:** JS detects thank-you page text → posts to "pageReady" handler → ViewModel sets `.success` status → Engine tears down (no further JS injection).
4. **Email persistence:** `@AppStorage("savedEmail")` in ViewModel automatically reads/writes `UserDefaults.standard` — no explicit save/load code needed.

## Scaling Considerations

This is a single-user on-device app. "Scaling" here means resilience to survey form changes, not user volume.

| Concern | Now | If Form Changes |
|---------|-----|-----------------|
| Page detection logic | Hardcoded selectors in `automation.js` | Update `.js` file only; no Swift recompile |
| New page types | Add a new `case` in JS detection logic | JS file change only |
| Anti-detection drift | `customUserAgent` + `navigator.webdriver` override | May need new JS overrides |
| Session cookies | WKWebView handles automatically | Non-issue unless site clears cookies mid-form |

## Anti-Patterns

### Anti-Pattern 1: Visible WKWebView via UIViewRepresentable

**What people do:** Wrap WKWebView in `UIViewRepresentable` to embed it in the SwiftUI view hierarchy, making it visible.

**Why it's wrong:** The user doesn't need to see the form. Visible WKWebView adds layout complexity, UIViewRepresentable Coordinator boilerplate, and risks the user accidentally tapping the form. The hidden-frame approach is simpler.

**Do this instead:** Create `WKWebView(frame: .zero)` directly in the Engine class. Hold a strong reference on the class. Never add it to any view hierarchy.

### Anti-Pattern 2: Injecting JavaScript Before Page Load Completes

**What people do:** Call `evaluateJavaScript` immediately after `webView.load()` without waiting for `didFinishNavigation`.

**Why it's wrong:** The DOM is not ready. JS selectors return null, clicks silently fail, and the automation appears to work but does nothing.

**Do this instead:** Always trigger JS injection from `webView(_:didFinish:)`. If the page uses dynamic loading (content added after DOMContentLoaded), poll with a short `setTimeout` in the JS itself before acting.

### Anti-Pattern 3: Storing WKWebView Inside a SwiftUI View Struct

**What people do:** Create a `WKWebView` as a `@State` property inside a SwiftUI `View`.

**Why it's wrong:** SwiftUI View structs are value types recreated frequently. A WKWebView stored as `@State` gets recreated on state changes, tearing down active page sessions mid-automation.

**Do this instead:** Own the WKWebView in a reference type (`class`) — the Engine or ViewModel — which has a stable lifetime tied to the app session.

### Anti-Pattern 4: Synchronous/Blocking JavaScript Pattern

**What people do:** Use the old callback-based `evaluateJavaScript` in nested completion handlers for sequential steps.

**Why it's wrong:** Deeply nested callbacks become unmaintainable quickly. Error propagation is difficult.

**Do this instead:** Wrap `evaluateJavaScript` in an `async throws` extension and use `await` for sequential step execution. Use `callAsyncJavaScript` when the JS itself is async (returns a Promise).

### Anti-Pattern 5: Running JavaScript in `.page` Content World

**What people do:** Use `WKContentWorld.page` (the website's own JS environment) for injected scripts.

**Why it's wrong:** Injected variables and functions can collide with the site's own JavaScript, causing unpredictable behavior.

**Do this instead:** Use `WKContentWorld.defaultClient` for injected automation scripts. This creates an isolated JS sandbox that can still manipulate the DOM (via document API) but cannot conflict with the page's own JS globals.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| pandaexpress.com/feedback | HTTP via WKWebView's built-in network stack | Uses device's own IP (WiFi or cellular); no proxy needed |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| ViewModel ↔ Engine | Direct method calls + closure callbacks | Engine is owned by ViewModel; no protocol indirection needed at this scale |
| Engine ↔ WKWebView | `evaluateJavaScript`, `load()`, `navigationDelegate` | All calls must be on MainActor / main thread |
| WKWebView ↔ automation.js | `WKScriptMessageHandler` postMessage (JS→Swift); `evaluateJavaScript` (Swift→JS) | Bidirectional; JS is the "client", Swift is the "host" |
| ViewModel ↔ SwiftUI Views | `@Observable` bindings (iOS 17+) or `@ObservableObject` / `@Published` | Reactive; no explicit notification code needed |
| Email ↔ UserDefaults | `@AppStorage("savedEmail")` | Automatic; surveyCode is NOT persisted (new code each time) |

## Build Order Implications

Component dependencies determine build order:

1. **Models** (`AutomationStatus`, `LogEntry`) — no dependencies; define first.
2. **AutomationViewModel** — depends on Models; foundation for all bindings.
3. **AutomationEngine** skeleton — WKWebView setup, delegate wiring, basic `loadURL()` without JS yet.
4. **UI (InputFormView + LogView)** — binds to ViewModel; can be built and tested with placeholder log data before Engine works.
5. **automation.js** — JavaScript port of `script.py`; independent of Swift; testable in browser console against the live form.
6. **JS injection + page step runner** — connects Engine to `automation.js`; the critical integration point.
7. **JSBridgeHandler (message handler)** — completes the JS→Swift log streaming path.
8. **Anti-detection measures** — `customUserAgent` and `navigator.webdriver` override; add after basic flow works.
9. **Error handling + cancellation** — add after happy path is complete.

## Sources

- [WKUserContentController — Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkusercontentcontroller)
- [evaluateJavaScript(_:in:contentWorld:) — Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkwebview/3824704-evaluatejavascript)
- [callAsyncJavaScript — Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript)
- [webView(_:didFinish:) — Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wknavigationdelegate/1455629-webview)
- [Discover WKWebView enhancements (WWDC20) — Apple Developer](https://developer.apple.com/videos/play/wwdc2020/10188/)
- [JavaScript Manipulation on iOS Using WebKit — Capital One Tech / Medium](https://medium.com/capital-one-tech/javascript-manipulation-on-ios-using-webkit-2b1115e7e405) (MEDIUM confidence — 403 on direct fetch, referenced by multiple sources)
- [iOS 14: What is new for WKWebView — Filip Němeček](https://nemecek.be/blog/32/ios-14-what-is-new-for-wkwebview)
- [WKZombie headless WKWebView automation framework — GitHub](https://github.com/mkoehnke/WKZombie)
- [Retrieving data from WKWebView and passing to SwiftUI — Dustin Knopoff](https://dustinknopoff.dev/articles/js-swift-talking/)
- [Messaging Between WKWebView and Native Application in SwiftUI — Medium](https://medium.com/@yeeedward/messaging-between-wkwebview-and-native-application-in-swiftui-e985f0bfacf)
- [The Ultimate Guide to WKWebView — Hacking with Swift](https://www.hackingwithswift.com/articles/112/the-ultimate-guide-to-wkwebview)

---
*Architecture research for: iOS WKWebView automation app (Panda Express feedback survey)*
*Researched: 2026-03-18*
