# Phase 1: Foundation - Research

**Researched:** 2026-03-18
**Domain:** Native iOS SwiftUI app with hidden WKWebView, anti-detection configuration, and Panda branding
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Visual Style — Light Mode**
- Light mode with green accents (NOT dark like the web UI)
- Use iOS system green (`Color.green`) as the accent color
- All SF Pro font — no custom fonts, fully native iOS feel
- Panda image (pandaEating.png) as a subtle faded background/watermark behind the form, very light opacity
- Panda image also used as the app icon on the home screen

**Form Styling**
- iOS-style grouped form sections (like Settings app) — most native approach
- Filled green Run button with white text — solid primary action
- "Show logs" toggle lives inside the form area (not in nav bar), near the other form elements

**App Title & Nav**
- Navigation bar title: "Panda" (shortened from "Panda Survey")
- Subtitle can appear in the form section area

**Code Input**
- Single text field for the full 24-character code (NOT 6 separate fields)
- Auto-inserts dashes every 4 characters as user types (display: `1234-5678-9012-3456-7890-1234`)
- Full default keyboard (codes may contain letters)
- Strips dashes internally before passing to automation

**Email Input**
- Single email text field with email keyboard
- Persisted via @AppStorage — pre-filled on next launch

**Layout & Log Area**
- Single-screen app, no navigation stack
- Form at top: code input, email input, Run button, Show logs toggle
- "Show logs" checkbox toggle — when checked, a scrollable log box appears below the form
- Log box takes bottom half of screen when visible
- Log box scrolls independently — scrolling logs does not scroll the main view
- When logs hidden, form is the only visible content

### Claude's Discretion
- Exact panda watermark opacity and positioning
- Grouped form section labels and dividers
- Status indicator design (spinner, checkmark on completion)
- Exact spacing and padding values
- How the "Show logs" toggle looks (checkbox, switch, or SF Symbol)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FORM-01 | User can enter 24-character survey code via single field with auto-dashes (6 groups of 4) | SwiftUI TextField with `onChange` modifier for dash insertion; strip dashes before use |
| FORM-02 | User can enter email address, pre-filled from last use (@AppStorage) | `@AppStorage("savedEmail")` on ViewModel property; TextField with `.emailAddress` keyboardType |
| FORM-03 | App validates code length (24 chars) and email format before running | Computed property on ViewModel; disable Run button binding to `isValid` bool |
| FORM-04 | Inputs and Run button are disabled while automation is active | `.disabled(viewModel.isRunning)` on form fields and button; driven by ViewModel `isRunning: Bool` |
| AUTO-01 | App creates a hidden WKWebView attached to the window hierarchy | `WKWebView(frame: .zero)` owned by `AutomationEngine`; attached to UIWindowScene window — critical for JS execution |
| AUTO-02 | App injects anti-detection (navigator.webdriver override at documentStart, clean Mobile Safari user agent) | `WKUserScript` with `.atDocumentStart` injection time; `webView.customUserAgent` set before first load |
| DESIGN-01 | App uses light theme with Panda Express branding (overrides REQUIREMENTS.md dark-theme spec per CONTEXT.md) | SwiftUI native components, `Color.green` accent, `pandaEating.png` watermark and app icon |
| DEPLOY-01 | App is buildable and installable via Xcode sideloading to iPhone | Xcode 26.3, iOS 16.0 deployment target, Personal Team signing; no third-party dependencies |
</phase_requirements>

---

## Summary

Phase 1 establishes the complete iOS app shell: an Xcode project with SwiftUI form UI, a hidden WKWebView attached to the window hierarchy, anti-detection pre-configured, and all Panda branding in place. No automation JavaScript executes in this phase — the WKWebView simply loads `pandaexpress.com/feedback` to prove the stack works end-to-end.

The stack is entirely Apple system frameworks (SwiftUI + WebKit). No SPM packages are needed. The critical structural decision is that the hidden `WKWebView` must be owned by a reference-type `AutomationEngine` class annotated `@MainActor`, and must be added as a zero-frame subview to the app's `UIWindowScene` window — not held as a SwiftUI `@State` value. This single architectural choice prevents the three most common WKWebView automation failures (throttled JS, deallocation mid-run, main-thread crashes).

The UI is a single-screen SwiftUI `Form` with grouped sections (Settings-style), a green filled Run button, and a collapsible log area that occupies the bottom half of the screen when revealed. The panda image serves as both app icon and a low-opacity watermark behind the form.

**Primary recommendation:** Build the `AutomationEngine` class with window-attached WKWebView first, verify `didFinishNavigation` fires on a real device, then layer the SwiftUI form on top. Don't build UI before confirming the WebView stack works on hardware.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.2.4 (Xcode 26.3) | Primary language | Only sensible choice for native iOS; Swift 6 strict concurrency enforces safe UI/background separation critical for WKWebView |
| SwiftUI | iOS 16+ APIs | All visible UI — form, log area, button | Modern declarative UI; `Form` with grouped style maps directly to the Settings-app look required |
| WKWebView (WebKit) | iOS 16+ (ships with OS) | Hidden browser that runs the survey | Only in-process browser available on iOS; full JS injection, navigation delegate, message passing |
| Xcode | 26.3 | IDE, compiler, signer, device deployer | Required; no alternatives |

### Supporting APIs

| API | Availability | Purpose | When to Use |
|-----|-------------|---------|-------------|
| `WKUserContentController` + `WKUserScript` | iOS 8+ | Inject `navigator.webdriver` override at `documentStart` | Set up during `WKWebViewConfiguration` before any load |
| `WKNavigationDelegate` / `didFinishNavigation` | iOS 8+ | Detect when each page finishes loading | Trigger automation steps (Phase 2); in Phase 1, just confirm it fires |
| `WKScriptMessageHandler` | iOS 8+ | Receive `postMessage` log lines from JS | Register `"log"` handler; Phase 3 fully uses it; Phase 1 wires the channel |
| `callAsyncJavaScript(_:arguments:in:in:completionHandler:)` | iOS 14+ | Execute async JS + receive resolved value | Preferred for all automation actions in Phase 2 |
| `@AppStorage` | iOS 14+ | Persist email across launches | `@AppStorage("savedEmail")` — automatic read/write of UserDefaults; no explicit save code |
| `@MainActor` | Swift 5.5+ | Enforce main-thread isolation on WKWebView class | Annotate `AutomationEngine` class; prevents runtime crashes |

### No Third-Party Dependencies

The entire stack is Apple system frameworks. Do not add any SPM packages. `import WebKit` is the only non-default import needed.

**Xcode project setup:**
```
1. File → New Project → iOS → App → SwiftUI interface
2. Deployment Target: iOS 16.0
3. Signing & Capabilities → Team: Personal Team (free Apple ID)
4. Bundle Identifier: com.[yourname].pandaautomator  (use one ID consistently)
5. WebKit framework: auto-imported via `import WebKit`
6. No SPM packages required
```

---

## Architecture Patterns

### Recommended Project Structure

```
PandaAutomator/
├── App/
│   ├── PandaAutomatorApp.swift       # @main entry point
│   └── ContentView.swift             # Root view — Form + conditional LogView
├── Views/
│   └── InputFormView.swift           # Survey code, email, Run button, Show Logs toggle
├── ViewModel/
│   └── AutomationViewModel.swift     # @Observable, owns AutomationEngine, all UI state
├── Engine/
│   ├── AutomationEngine.swift        # WKWebView creation, window attachment, user agent
│   └── JSBridgeHandler.swift         # WKScriptMessageHandler implementation
├── Models/
│   └── AutomationStatus.swift        # Enum: idle / running / success / error
└── Resources/
    └── Assets.xcassets               # App icon (pandaEating.png), accent color
```

Phase 1 creates all files above. `Scripts/automation.js` and `PageStepRunner.swift` are Phase 2 additions.

### Pattern 1: Hidden WKWebView Attached to Window

**What:** `WKWebView(frame: .zero)` owned by the Engine class, added to the `UIWindowScene` window — never visible, never in SwiftUI view hierarchy, but always in the window hierarchy so WebKit does not throttle it.

**When to use:** Always. This is the only correct way to run a hidden WKWebView on iOS.

```swift
// AutomationEngine.swift
@MainActor
class AutomationEngine: NSObject {
    private var webView: WKWebView!

    func setup() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()

        // Anti-detection script injected BEFORE page JS runs
        let antiDetect = WKUserScript(
            source: "Object.defineProperty(navigator, 'webdriver', { get: () => undefined });",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(antiDetect)
        controller.add(self, name: "log")

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
}
```

### Pattern 2: @Observable ViewModel as Single Source of Truth

**What:** One `@Observable` class holds all UI state. SwiftUI views bind to it. The Engine mutates it. No view struct holds mutable automation state.

```swift
// AutomationViewModel.swift
import Observation

@Observable
@MainActor
class AutomationViewModel {
    @ObservationIgnored @AppStorage("savedEmail") var email: String = ""
    var surveyCode: String = ""          // raw input, dashes included for display
    var isRunning: Bool = false
    var showLogs: Bool = false
    var logMessages: [String] = []
    var status: AutomationStatus = .idle

    // Computed: strip dashes, validate length for FORM-03
    var cleanCode: String { surveyCode.replacingOccurrences(of: "-", with: "") }
    var isValid: Bool { cleanCode.count == 24 && email.contains("@") }

    private let engine = AutomationEngine()

    func startAutomation() {
        guard isValid else { return }
        isRunning = true
        engine.run(code: cleanCode, email: email)
    }

    func appendLog(_ message: String) {
        logMessages.append(message)
    }
}
```

### Pattern 3: Code Field Auto-Dash Formatting (FORM-01)

**What:** Single TextField that inserts a dash after every 4 characters as the user types. Raw input is always available by stripping dashes.

**When to use:** For FORM-01 — replaces the 6-field web approach with a credit-card-style single field.

```swift
// InputFormView.swift
TextField("1234-5678-9012-3456-7890-1234", text: $viewModel.surveyCode)
    .keyboardType(.default)          // codes may contain letters
    .onChange(of: viewModel.surveyCode) { _, newValue in
        viewModel.surveyCode = formatCodeWithDashes(newValue)
    }

func formatCodeWithDashes(_ input: String) -> String {
    // Strip existing dashes, keep alphanumeric only
    let clean = input.replacingOccurrences(of: "-", with: "")
        .prefix(24)
        .uppercased()
    // Reinsert dashes every 4 chars
    var result = ""
    for (i, char) in clean.enumerated() {
        if i > 0 && i % 4 == 0 { result.append("-") }
        result.append(char)
    }
    return result
}
```

### Pattern 4: Collapsible Log Area (FORM-04 + Layout decision)

**What:** `showLogs` Bool in ViewModel drives a `if viewModel.showLogs` block that renders an independent `ScrollView` in the bottom half. The outer view does not scroll — log area scrolls independently.

```swift
// ContentView.swift
VStack(spacing: 0) {
    // Form occupies top portion — not scrollable at outer level
    Form {
        // ... sections ...
        Toggle("Show logs", isOn: $viewModel.showLogs)
    }
    .frame(maxHeight: viewModel.showLogs ? UIScreen.main.bounds.height * 0.5 : .infinity)

    if viewModel.showLogs {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(viewModel.logMessages.enumerated()), id: \.offset) { i, msg in
                        Text(msg)
                            .font(.system(.caption, design: .monospaced))
                            .id(i)
                    }
                }
                .padding(8)
            }
            .onChange(of: viewModel.logMessages.count) { _, _ in
                proxy.scrollTo(viewModel.logMessages.count - 1, anchor: .bottom)
            }
        }
        .background(Color(.systemBackground))
        .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
    }
}
```

### Pattern 5: Panda Watermark Background (DESIGN-01)

**What:** `ZStack` with `pandaEating.png` behind the `Form`, rendered at very low opacity so it reads as a brand texture rather than a distraction.

```swift
// ContentView.swift
ZStack {
    // Watermark behind everything
    Image("pandaEating")
        .resizable()
        .scaledToFill()
        .opacity(0.06)          // Claude's discretion: 0.04–0.08 range
        .ignoresSafeArea()
        .allowsHitTesting(false)

    Form { /* ... */ }
}
.tint(.green)  // iOS system green accent across all interactive elements
```

### Anti-Patterns to Avoid

- **Storing WKWebView in a SwiftUI @State:** SwiftUI structs recreate frequently; the WKWebView gets deallocated mid-session. Own it in a reference-type Engine class.
- **Not attaching WKWebView to UIWindowScene:** A WKWebView held only in memory without a superview silently throttles JS and navigation. Always call `window.addSubview(webView)` during setup.
- **Injecting navigator.webdriver override at `atDocumentEnd`:** By that time the page's own JS has already checked `navigator.webdriver`. Must use `atDocumentStart`.
- **Setting customUserAgent after the first load:** The user agent is cached. Set it on the configuration or immediately after init, before `load()`.
- **Using `UIApplication.shared.windows.first` on iOS 15+:** Deprecated. Use `connectedScenes` API shown in Pattern 1.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Email persistence across launches | Custom file/database | `@AppStorage("savedEmail")` | One line; automatic; handles UserDefaults migration |
| Threading safety on WKWebView | Manual DispatchQueue.main wrappers | `@MainActor` class annotation | Swift 6 enforces this at compile time; manual dispatch is error-prone |
| JS→Swift communication | URL scheme hijacking or polling evaluateJavaScript | `WKScriptMessageHandler` + `postMessage` | Cleaner, async, no navigation side effects |
| Async JS execution | Callback-nested `evaluateJavaScript` | `callAsyncJavaScript` (iOS 14+) | Handles Promises natively; arguments dict prevents injection bugs |
| Code format validation | Regex parser | Computed `cleanCode.count == 24` | Sufficient for a 24-char alphanumeric code; no edge cases |

**Key insight:** Every automation-adjacent problem in this stack has a WebKit API designed for it. The engineering challenge is wiring existing APIs correctly, not building novel solutions.

---

## Common Pitfalls

### Pitfall 1: WKWebView Not in Window Hierarchy
**What goes wrong:** `didFinishNavigation` never fires; `evaluateJavaScript` returns nothing; network requests don't appear in proxy tools.
**Why it happens:** WKWebView needs a superview chain reaching `UIWindow` to remain active. Zero-frame is fine; no superview is not.
**How to avoid:** During `AutomationEngine.setup()`, add the webView to the first `UIWindowScene` window immediately after creation (Pattern 1 above).
**Warning signs:** Works in Simulator, fails on device; navigation delegate never called.

### Pitfall 2: evaluateJavaScript Called Off Main Thread
**What goes wrong:** Runtime crash: `WKWebView must be used from main thread only`. With Swift 6, surfaces as compile-time `@MainActor` violation.
**Why it happens:** Automation logic wrapped in `Task {}` without `@MainActor` propagation.
**How to avoid:** Annotate `AutomationEngine` with `@MainActor`. Treat all WKWebView calls like UIKit calls.
**Warning signs:** Xcode Main Thread Checker violations; intermittent crashes on device.

### Pitfall 3: navigator.webdriver Injected Too Late
**What goes wrong:** Survey site detects automation and shows CAPTCHA or redirects.
**Why it happens:** Using `atDocumentEnd` or injecting via `evaluateJavaScript` after load — the page's own JS has already run the check.
**How to avoid:** Always use `WKUserScript(injectionTime: .atDocumentStart)` for the webdriver override.
**Warning signs:** App loads a page but not the actual survey form; HTTP 403 or CAPTCHA visible.

### Pitfall 4: Sideload Expires After 7 Days (Free Account)
**What goes wrong:** App stops launching entirely with no warning. User must reconnect to Mac.
**Why it happens:** Free Apple Developer provisioning profiles have a hard 7-day expiry.
**How to avoid:** Document this in setup instructions. Consider $99/year paid account for 1-year profiles.
**Warning signs:** App icon shows "Not Available"; device shows "Unable to verify app."

### Pitfall 5: evaluateJavaScript Crash on Void Return
**What goes wrong:** `EXC_BAD_ACCESS` or fatal unwrap when JS returns nothing.
**Why it happens:** Swift bridging does not correctly handle void/nil as a success return.
**How to avoid:** Append `; true` to all void scripts, or use `callAsyncJavaScript` exclusively.
**Warning signs:** Crash only on scripts that click or submit (not on read-only scripts).

---

## Code Examples

### App Icon from pandaEating.png
```
Assets.xcassets → AppIcon → drag pandaEating.png to the 1024×1024 slot
Xcode generates all required sizes automatically.
```

### Anti-Detection Setup (complete, production-ready)
```swift
// Source: PITFALLS.md + Apple Developer Docs
let antiDetect = WKUserScript(
    source: """
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3] });
    """,
    injectionTime: .atDocumentStart,
    forMainFrameOnly: true
)
controller.addUserScript(antiDetect)

webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
```

### FORM-03 Validation
```swift
// Disable Run button when inputs are invalid
Button("Run") { viewModel.startAutomation() }
    .buttonStyle(.borderedProminent)
    .tint(.green)
    .disabled(!viewModel.isValid || viewModel.isRunning)
```

### iOS Grouped Form (Settings-style)
```swift
Form {
    Section("Survey Code") {
        TextField("1234-5678-9012-3456-7890-1234", text: $viewModel.surveyCode)
            .onChange(of: viewModel.surveyCode) { _, v in
                viewModel.surveyCode = formatCodeWithDashes(v)
            }
    }
    Section("Email") {
        TextField("you@example.com", text: $viewModel.email)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
    Section {
        Button("Run") { viewModel.startAutomation() }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.isValid || viewModel.isRunning)
        Toggle("Show logs", isOn: $viewModel.showLogs)
    }
}
.formStyle(.grouped)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UIWebView` | `WKWebView` | iOS 12 deprecated, iOS 15 removed | Must use WKWebView; UIWebView will crash/reject |
| `evaluateJavaScript` callbacks | `callAsyncJavaScript` + Swift async/await | iOS 14+ | Sequential automation is clean; no callback nesting |
| `@ObservableObject` + `@Published` | `@Observable` macro | iOS 17 | Simpler syntax; iOS 16 target requires checking — use `@ObservableObject` if iOS 16 support needed |
| `UIApplication.shared.windows.first` | `connectedScenes` API | iOS 15 deprecated | Must use scene-based window access |
| Native SwiftUI `WebView`/`WebPage` | Not yet usable | iOS 26 only | Requires iOS 26 minimum; skip for iOS 16 target |

**Critical note on `@Observable`:** Available iOS 17+. Since deployment target is iOS 16.0, use `@ObservableObject` with `@Published` properties, OR verify the minimum iOS version and bump to 17 if acceptable. Research recommends staying at iOS 16 and using `@ObservableObject`.

**Deprecated/outdated:**
- `UIWebView`: Removed in iOS 15. Do not use.
- `UIApplication.shared.windows`: Deprecated iOS 15. Use `connectedScenes`.
- Swift 5 language mode in Xcode 26: Missing concurrency safety. Use Swift 6 mode.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — Xcode unit test target (XCTest) to be added in Wave 0 |
| Config file | `PandaAutomatorTests/` target in Xcode project |
| Quick run command | `xcodebuild test -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | Same — test suite is small for this phase |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FORM-01 | `formatCodeWithDashes` inserts dashes every 4 chars, strips on clean | unit | `xcodebuild test -only-testing:PandaAutomatorTests/CodeFormatterTests` | Wave 0 |
| FORM-02 | `@AppStorage` email is read back after simulated app relaunch | unit | `xcodebuild test -only-testing:PandaAutomatorTests/EmailPersistenceTests` | Wave 0 |
| FORM-03 | `isValid` false when code < 24 chars or email lacks `@` | unit | `xcodebuild test -only-testing:PandaAutomatorTests/ValidationTests` | Wave 0 |
| FORM-04 | `isRunning = true` disables button (binding test) | unit | `xcodebuild test -only-testing:PandaAutomatorTests/ViewModelTests` | Wave 0 |
| AUTO-01 | WKWebView is added to window hierarchy on Engine.setup() | unit | `xcodebuild test -only-testing:PandaAutomatorTests/EngineSetupTests` | Wave 0 |
| AUTO-02 | User agent contains "Safari" and webdriver script injected at documentStart | unit | `xcodebuild test -only-testing:PandaAutomatorTests/AntiDetectionTests` | Wave 0 |
| DESIGN-01 | App compiles and launches without crash | smoke | `xcodebuild build -scheme PandaAutomator` | Wave 0 |
| DEPLOY-01 | App builds without signing errors | smoke | `xcodebuild build -scheme PandaAutomator -destination 'generic/platform=iOS'` | Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** Full test suite above
- **Phase gate:** All tests green + real device confirms `didFinishNavigation` fires before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `PandaAutomatorTests/CodeFormatterTests.swift` — covers FORM-01
- [ ] `PandaAutomatorTests/ValidationTests.swift` — covers FORM-03
- [ ] `PandaAutomatorTests/ViewModelTests.swift` — covers FORM-04
- [ ] `PandaAutomatorTests/EmailPersistenceTests.swift` — covers FORM-02
- [ ] `PandaAutomatorTests/EngineSetupTests.swift` — covers AUTO-01
- [ ] `PandaAutomatorTests/AntiDetectionTests.swift` — covers AUTO-02
- [ ] XCTest target: Add `PandaAutomatorTests` target in Xcode project settings

---

## Open Questions

1. **`@Observable` vs `@ObservableObject`**
   - What we know: `@Observable` (Observation framework) requires iOS 17+; deployment target is iOS 16.0
   - What's unclear: Whether to bump deployment target to iOS 17 (covers ~95%+ of active iPhones) or stay at iOS 16
   - Recommendation: Default to `@ObservableObject` + `@Published` for iOS 16 compatibility; planner can note as a decision point

2. **`UIWindowScene` window access during app launch**
   - What we know: `connectedScenes` may not be populated if `AutomationEngine.setup()` is called before the first scene is fully connected
   - What's unclear: Exact timing of scene availability relative to ViewModel init
   - Recommendation: Call `engine.setup()` from `onAppear` of the root view, not from `init()`

3. **pandaEating.png app icon sizing**
   - What we know: Asset is 2.1MB JPEG; Xcode requires PNG or JPEG at 1024×1024 for App Icon
   - What's unclear: Whether the image's aspect ratio and composition work well as a square icon
   - Recommendation: Add to `AppIcon` asset in Xcassets and preview on device before finalizing

---

## Sources

### Primary (HIGH confidence)
- STACK.md (pre-researched 2026-03-18) — full stack, version numbers, API availability
- ARCHITECTURE.md (pre-researched 2026-03-18) — component structure, data flow, code patterns
- PITFALLS.md (pre-researched 2026-03-18) — all pitfalls with recovery strategies
- [Apple Developer: callAsyncJavaScript](https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript) — iOS 14+ availability
- [Apple Developer: WKNavigationDelegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate)
- [Apple Developer: WKUserContentController](https://developer.apple.com/documentation/webkit/wkusercontentcontroller)

### Secondary (MEDIUM confidence)
- [Apple Developer Forums — WKWebView JS throttling without window hierarchy](https://developer.apple.com/forums/thread/111247)
- [Filip Němeček — WKWebView headless mode](https://nemecek.be/blog/19/using-wkwebview-in-headless-mode)
- [xcodereleases.com — Xcode 26.3 / Swift 6.2.4 current stable](https://xcodereleases.com/)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Apple system frameworks only; all APIs stable since iOS 14+; verified against official docs
- Architecture: HIGH — patterns verified in ARCHITECTURE.md with Apple documentation links
- Pitfalls: HIGH — most pitfalls verified against Apple Developer Forums and official docs
- UI patterns: HIGH — SwiftUI Form/grouped style is the standard iOS approach; well documented

**Research date:** 2026-03-18
**Valid until:** 2026-09-18 (stable APIs; WebKit/SwiftUI rarely breaks patterns between minor iOS versions)
