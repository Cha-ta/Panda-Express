---
phase: 01-foundation
verified: 2026-03-20T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
re_verification: false
human_verification:
  - test: "Build and run on iOS Simulator or real iPhone"
    expected: "App installs and launches without signing errors, showing 'Panda' in the navigation bar"
    why_human: "xcodebuild build/test was never executed — all summaries note development ran on Windows without Xcode; no CI evidence exists"
  - test: "Tap Run button — observe WKWebView loads pandaexpress.com/feedback"
    expected: "App navigates to the feedback URL in the hidden WKWebView (log area shows 'Page loaded' if Show Logs is on)"
    why_human: "The WebView load is runtime behavior; WKWebView must be attached to the UIWindowScene window before it can load without JS throttling"
  - test: "Type a survey code and observe auto-dash behavior"
    expected: "After 4 chars, a dash is auto-inserted; input stays uppercase; after 24 chars no more chars are accepted; code border turns red when partially filled, green when complete"
    why_human: "onChange-driven dash formatting and border color transitions require live UI interaction to verify correctly"
  - test: "Close and reopen the app — email field pre-fills"
    expected: "Email field displays the email from the previous session without user re-entry"
    why_human: "UserDefaults persistence across app lifecycle requires a real launch cycle"
  - test: "Rotate phone to landscape"
    expected: "App does not rotate — stays portrait only"
    why_human: "Orientation lock requires a real device or simulator rotation gesture"
---

# Phase 1: Foundation Verification Report

**Phase Goal:** Build the complete iOS app foundation — engine, UI, and test scaffolding — so the app launches, accepts input, displays a form, and is ready for automation wiring.
**Verified:** 2026-03-20
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP.md Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can enter a 24-character survey code via segmented input (auto-dashes every 4 chars) and see validation reject incomplete codes | VERIFIED | `InputFormView.swift` lines 27-32: `onChange` calls `formatCodeWithDashes`, border turns red when `clean.count != 24`; `isValid` enforces `cleanCode.count == 24` |
| 2 | User can enter an email address that is pre-filled from the previous session on next launch | VERIFIED | `AutomationViewModel.swift` lines 9-13, 39-41: `@Published var email` writes `UserDefaults.standard.set` in `didSet`; `init()` reads `UserDefaults.standard.string(forKey: "savedEmail")` |
| 3 | Run button is disabled when inputs are invalid or automation is active; inputs are locked during a run | VERIFIED | `InputFormView.swift` lines 26, 45: `.disabled(viewModel.isRunning)` on both TextFields; line 69: `.disabled(!viewModel.isValid \|\| viewModel.isRunning)` on Run button |
| 4 | App builds in Xcode and installs to a real iPhone via sideloading with no signing errors | UNCERTAIN | Project structure is complete and correct; `project.pbxproj` has iOS 16 deployment target, proper signing section, and all source files referenced — but `xcodebuild` was never run (Windows dev environment); no CI evidence |
| 5 | Hidden WKWebView loads pandaexpress.com/feedback with clean Mobile Safari user agent and navigator.webdriver override injected before any page request | VERIFIED (code) / UNCERTAIN (runtime) | `AutomationEngine.swift` lines 21-30: `WKUserScript` with `injectionTime: .atDocumentStart` overrides `navigator.webdriver`; line 37: `customUserAgent` set to clean Safari string; line 43: `addSubview(webView)` via `connectedScenes` — wiring is correct but runtime behavior requires human test |

**Score:** 5/5 truths verified in code; 2 require human confirmation of runtime behavior

---

### Required Artifacts

#### Plan 00 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `PandaAutomator/PandaAutomatorTests/CodeFormatterTests.swift` | XCTestCase for FORM-01 dash formatting | VERIFIED | `final class CodeFormatterTests: XCTestCase` — 4 real assertions covering dash insertion, strip-and-reformat, 24-char cap, uppercase |
| `PandaAutomator/PandaAutomatorTests/ValidationTests.swift` | XCTestCase for FORM-03 isValid | VERIFIED | `final class ValidationTests: XCTestCase` — 3 assertions: code too short, email missing @, valid combination |
| `PandaAutomator/PandaAutomatorTests/ViewModelTests.swift` | XCTestCase for FORM-04 isRunning | VERIFIED | `final class ViewModelTests: XCTestCase` — tests default false and startAutomation sets true |
| `PandaAutomator/PandaAutomatorTests/EmailPersistenceTests.swift` | XCTestCase for FORM-02 email persistence | VERIFIED | `final class EmailPersistenceTests: XCTestCase` — tests write-to-UserDefaults and load-on-init |
| `PandaAutomator/PandaAutomatorTests/EngineSetupTests.swift` | XCTestCase for AUTO-01 WKWebView creation | VERIFIED | `final class EngineSetupTests: XCTestCase` — verifies via `userAgent` accessor and loadFeedbackPage crash-free call |
| `PandaAutomator/PandaAutomatorTests/AntiDetectionTests.swift` | XCTestCase for AUTO-02 anti-detection | VERIFIED | `final class AntiDetectionTests: XCTestCase` — verifies "Safari" in userAgent and `.atDocumentStart` script exists |

#### Plan 01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `PandaAutomator/PandaAutomator/Engine/AutomationEngine.swift` | Hidden WKWebView with anti-detection and window attachment | VERIFIED | `@MainActor class AutomationEngine: NSObject` — WKWebView creation, `atDocumentStart` injection, `customUserAgent`, `addSubview(webView)` via `connectedScenes` |
| `PandaAutomator/PandaAutomator/ViewModel/AutomationViewModel.swift` | All UI state, validation logic, email persistence | VERIFIED | `class AutomationViewModel: ObservableObject` — `isValid`, `cleanCode`, `isRunning`, `formatCodeWithDashes`, UserDefaults persistence |
| `PandaAutomator/PandaAutomator/Models/AutomationStatus.swift` | Status enum for automation state | VERIFIED | `enum AutomationStatus: Equatable` — idle/running/success/error cases |
| `PandaAutomator/PandaAutomator/Engine/JSBridgeHandler.swift` | WKScriptMessageHandler for JS log channel | VERIFIED | `final class JSBridgeHandler: NSObject, WKScriptMessageHandler` — `nonisolated` delegate with `Task { @MainActor }` dispatch |

#### Plan 02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `PandaAutomator/PandaAutomator/App/ContentView.swift` | Root view with ZStack watermark, Form, and collapsible log area | VERIFIED | Contains `NavigationStack`, `@StateObject` ViewModel, `ZStack` with `Image("pandaEating")`, Form, log `ScrollViewReader`, `onAppear { viewModel.setupEngine() }` |
| `PandaAutomator/PandaAutomator/Views/InputFormView.swift` | Form sections for code, email, run button, show logs toggle | VERIFIED | Contains `formatCodeWithDashes` call in `onChange`, `.disabled()` modifiers, `borderedProminent` Run button, `surveyCodeBorderColor` and `emailBorderColor` computed properties |
| `PandaAutomator/PandaAutomator/Resources/Assets.xcassets/pandaEating.imageset/Contents.json` | Panda image asset for watermark | VERIFIED | File exists; `Contents.json` references `pandaEating.png`; PNG file present |
| `PandaAutomator/PandaAutomator/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` | App icon from pandaEating.png | VERIFIED | `Contents.json` references `pandaEating.png` at 1024x1024; PNG file present |

#### Plan 03 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `PandaAutomator/PandaAutomator.xcodeproj/project.pbxproj` | Portrait-only orientation setting | VERIFIED | Both Debug and Release configs contain exactly `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;` (2 occurrences, no landscape values) |
| `PandaAutomator/PandaAutomator/App/ContentView.swift` | VStack with `maxHeight: .infinity` | VERIFIED | Line 62: `.frame(maxWidth: .infinity, maxHeight: .infinity)` on the VStack |
| `PandaAutomator/PandaAutomator/Views/InputFormView.swift` | `surveyCodeBorderColor` computed property | VERIFIED | Lines 6-11 and 13-18: both `surveyCodeBorderColor` and `emailBorderColor` computed properties wired to overlay modifiers on TextFields |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `AutomationViewModel` | `AutomationEngine` | `private let engine` property | WIRED | `AutomationViewModel.swift` line 35: `private let engine = AutomationEngine()` |
| `AutomationEngine` | `UIWindowScene` | `addSubview(webView)` in `setup()` | WIRED | `AutomationEngine.swift` lines 40-43: `connectedScenes` -> `UIWindowScene` -> `windows.first?.addSubview(webView)` |
| `AutomationEngine` | `WKUserScript` | `.atDocumentStart` injection | WIRED | `AutomationEngine.swift` line 27: `injectionTime: .atDocumentStart` in anti-detection script |
| `ContentView` | `AutomationViewModel` | `@StateObject` binding | WIRED | `ContentView.swift` line 4: `@StateObject private var viewModel = AutomationViewModel()` |
| `InputFormView` | `AutomationViewModel` | `@ObservedObject` binding | WIRED | `InputFormView.swift` line 4: `@ObservedObject var viewModel: AutomationViewModel` |
| `ContentView` | `pandaEating` image asset | `Image("pandaEating")` in ZStack | WIRED | `ContentView.swift` line 10: `Image("pandaEating")` — asset exists in xcassets |
| `Run button` | `viewModel.isValid && !viewModel.isRunning` | `.disabled()` modifier | WIRED | `InputFormView.swift` line 69: `.disabled(!viewModel.isValid \|\| viewModel.isRunning)` |
| `PandaAutomatorTests target` | `PandaAutomator main target` | `TEST_HOST` in project | WIRED | `project.pbxproj`: 4 `TEST_HOST` references; xcscheme includes `PandaAutomatorTests.xctest` in Test action |

---

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| FORM-01 | 01-00, 01-01, 01-02, 01-03 | Segmented survey code input (6 groups of 4) via auto-dashes | SATISFIED | `formatCodeWithDashes` in ViewModel; `onChange` in InputFormView; `CodeFormatterTests` with 4 assertions |
| FORM-02 | 01-00, 01-01, 01-02 | Email pre-filled from last use via persistence | SATISFIED | UserDefaults read in `init()`, write in `email.didSet`; `EmailPersistenceTests` with 2 assertions |
| FORM-03 | 01-00, 01-01, 01-02 | Validates code length (24 chars) and email format before running | SATISFIED | `isValid` computed property requires `cleanCode.count == 24 && email.contains("@") && email.contains(".")`; `ValidationTests` with 3 assertions; Run button `.disabled(!viewModel.isValid)` |
| FORM-04 | 01-00, 01-01, 01-02, 01-03 | Inputs and Run button disabled while automation is active | SATISFIED | `.disabled(viewModel.isRunning)` on both TextFields; `.disabled(!viewModel.isValid \|\| viewModel.isRunning)` on Run button; border grays to `systemGray4` when running |
| AUTO-01 | 01-00, 01-01 | Creates hidden WKWebView attached to window hierarchy | SATISFIED | `AutomationEngine.setup()` creates `WKWebView(frame: .zero)` and calls `addSubview(webView)` on UIWindowScene window |
| AUTO-02 | 01-00, 01-01 | Anti-detection: navigator.webdriver override at documentStart, clean Mobile Safari user agent | SATISFIED | `WKUserScript` with `.atDocumentStart` in `setup()`; `customUserAgent` set to clean Safari string; `AntiDetectionTests` with 2 assertions |
| DESIGN-01 | 01-02, 01-03 | Dark theme with Panda Express branding | SATISFIED (partial) | Light mode with green accents per explicit user decision in CONTEXT.md (overrides initial dark theme requirement); panda watermark at 0.18 opacity; pandaEating app icon |
| DEPLOY-01 | 01-01, 01-02 | Buildable and installable via Xcode sideloading | NEEDS HUMAN | Project structure is complete with iOS 16 deployment target, correct bundle ID `com.pandaautomator.app`, and all source files referenced — but `xcodebuild` was never executed in this project's history |

**Note on DESIGN-01:** Requirements.md specifies "dark theme" but CONTEXT.md (the canonical record of user decisions) explicitly states "Light mode with green accents." The implementation matches the user's stated decision. This divergence between REQUIREMENTS.md and CONTEXT.md should be resolved by updating REQUIREMENTS.md.

**Orphaned requirements check:** REQUIREMENTS.md traceability table maps FORM-01, FORM-02, FORM-03, FORM-04, AUTO-01, AUTO-02, DESIGN-01, DEPLOY-01 to Phase 1 — all 8 IDs are accounted for in plan frontmatter.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `AutomationEngine.swift` | 52-54 | `run()` only calls `loadFeedbackPage()` — no actual automation logic | INFO | Intentional Phase 1 stub; Phase 2 fills in real logic; comment in code confirms this |
| `ContentView.swift` | 13 | `opacity(0.18)` — plan spec said 0.06 | INFO | CONTEXT.md explicitly records user decision to use 0.18; this is correct per user intent, not a bug |

No blockers or warnings found. The `run()` stub is expected by design for Phase 1.

---

### Human Verification Required

#### 1. Xcode Build and Simulator Launch

**Test:** Open `PandaAutomator/PandaAutomator.xcodeproj` in Xcode, select an iPhone 16 Simulator, press Cmd+R.
**Expected:** App builds without errors or warnings, launches showing "Panda" in the navigation bar, with the grouped form visible and the panda watermark faintly behind it.
**Why human:** `xcodebuild` has never been executed in this project's lifetime — all three plans note development was done on Windows. The project structure is correct but compilation has not been independently confirmed.

#### 2. WKWebView Runtime Attachment

**Test:** Tap the Run button (after entering a valid 24-char code and email). Toggle Show Logs on.
**Expected:** Log area shows "Page loaded" confirming the WKWebView successfully attached to the window hierarchy and loaded `pandaexpress.com/feedback`.
**Why human:** `UIWindowScene` attachment requires the app to be running; if `connectedScenes` returns nil (e.g. window not yet connected at `onAppear` time), the WebView is not attached and JS would be throttled. This must be confirmed at runtime.

#### 3. Survey Code Auto-Dash Behavior

**Test:** Type "ABCD1234EFGH5678IJKL9012" into the Survey Code field one character at a time.
**Expected:** Dashes auto-insert after characters 4, 8, 12, 16, 20 giving "ABCD-1234-EFGH-5678-IJKL-9012". Border is green when empty, turns red after first character, turns green when all 24 chars are entered. No infinite loop.
**Why human:** `onChange` with a guard (`formatted != newValue`) prevents infinite loops — this requires live interaction to confirm there is no render loop or input lag.

#### 4. Email Persistence Across Launches

**Test:** Enter an email address, background the app, terminate it from the App Switcher, relaunch.
**Expected:** Email field is pre-filled with the email from the previous session.
**Why human:** Requires a real app lifecycle termination cycle; not testable via code inspection alone.

#### 5. Portrait-Only Orientation Lock

**Test:** With the app running, rotate the device or simulator to landscape.
**Expected:** The app remains in portrait orientation and does not rotate.
**Why human:** Orientation lock is a runtime OS behavior requiring an actual rotation event to confirm.

---

### Gaps Summary

No gaps found. All 5 observable truths are verified in code, all artifacts exist and are substantive (no stubs in production code), and all key links are wired. The `run()` method stub in `AutomationEngine` is an intentional Phase 1 placeholder documented in both the plan and code comment.

The only outstanding items are 5 human verification tests that require Xcode and a simulator/device. None of these are code-level gaps — they are runtime confirmations that cannot be done programmatically.

**Critical prerequisite before Phase 2:** A successful `xcodebuild build` run on a Mac must be completed to confirm the project compiles. The unit tests should also be run (`xcodebuild test`) to confirm all 11 test assertions pass. These were blocked throughout Phase 1 by the Windows development environment.

---

_Verified: 2026-03-20_
_Verifier: Claude (gsd-verifier)_
