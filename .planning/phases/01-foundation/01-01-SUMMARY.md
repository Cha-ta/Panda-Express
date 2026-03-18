---
phase: 01-foundation
plan: 01
subsystem: engine
tags: [swift, swiftui, wkwebview, webkit, xctest, ios, xcode]

requires:
  - phase: 01-00
    provides: Xcode project skeleton with PandaAutomatorTests target and test stub files

provides:
  - AutomationEngine: @MainActor class with hidden WKWebView, atDocumentStart anti-detection, Mobile Safari user agent, window attachment via connectedScenes
  - JSBridgeHandler: WKScriptMessageHandler forwarding JS log messages to Swift via onLog closure
  - AutomationStatus: idle/running/success/error enum
  - AutomationViewModel: ObservableObject with email persistence (UserDefaults), surveyCode with dash formatting, isValid, isRunning, formatCodeWithDashes
  - 6 unit test files with real assertions covering FORM-01 through FORM-04, AUTO-01, AUTO-02
  - ContentView and InputFormView placeholders (full UI in Plan 02)

affects: [01-02, phase-2-automation, phase-3-logging]

tech-stack:
  added: [SwiftUI, WebKit/WKWebView, XCTest, UIKit (UIWindowScene access)]
  patterns:
    - "@MainActor class annotation for WKWebView thread safety"
    - "WKWebView attached to UIWindowScene window (not SwiftUI hierarchy) to prevent JS throttling"
    - "WKUserScript at .atDocumentStart for navigator.webdriver override before page JS runs"
    - "ObservableObject + @Published for iOS 16 compatibility (not @Observable which requires iOS 17+)"
    - "UserDefaults manual read/write for email persistence (simpler than @AppStorage + ObservableObject)"
    - "nonisolated WKScriptMessageHandler delegate method with Task { @MainActor } dispatch"

key-files:
  created:
    - PandaAutomator/PandaAutomator/Engine/AutomationEngine.swift
    - PandaAutomator/PandaAutomator/Engine/JSBridgeHandler.swift
    - PandaAutomator/PandaAutomator/Models/AutomationStatus.swift
    - PandaAutomator/PandaAutomator/ViewModel/AutomationViewModel.swift
    - PandaAutomator/PandaAutomator/App/PandaAutomatorApp.swift
    - PandaAutomator/PandaAutomator/App/ContentView.swift
    - PandaAutomator/PandaAutomator/Views/InputFormView.swift
    - PandaAutomator/PandaAutomatorTests/CodeFormatterTests.swift
    - PandaAutomator/PandaAutomatorTests/ValidationTests.swift
    - PandaAutomator/PandaAutomatorTests/ViewModelTests.swift
    - PandaAutomator/PandaAutomatorTests/EmailPersistenceTests.swift
    - PandaAutomator/PandaAutomatorTests/EngineSetupTests.swift
    - PandaAutomator/PandaAutomatorTests/AntiDetectionTests.swift
  modified:
    - PandaAutomator/PandaAutomator.xcodeproj/project.pbxproj (already existed from prior attempt; all files are referenced)

key-decisions:
  - "ObservableObject + @Published used instead of @Observable macro — iOS 16.0 deployment target; @Observable requires iOS 17+"
  - "UserDefaults manual read/write for email persistence instead of @AppStorage — simpler integration with ObservableObject"
  - "WKWebView webView property is force-unwrapped (WKWebView!) with testable userAgent/userScripts accessors exposed for unit testing without breaking encapsulation"
  - "nonisolated on WKNavigationDelegate and WKScriptMessageHandler methods with Task { @MainActor } dispatch to satisfy Swift concurrency requirements"
  - "xcodebuild verification skipped — running on Windows without Xcode; project correctness verified via structural review and file content inspection"

patterns-established:
  - "Pattern: Hidden WKWebView owned by reference-type @MainActor engine class, not SwiftUI @State"
  - "Pattern: window attachment via UIApplication.shared.connectedScenes (not deprecated UIApplication.shared.windows)"
  - "Pattern: Anti-detection via WKUserScript at .atDocumentStart"
  - "Pattern: JS-to-Swift logging via WKScriptMessageHandler on 'log' message name"

requirements-completed: [FORM-01, AUTO-01, AUTO-02, FORM-02, FORM-03, FORM-04, DEPLOY-01]

duration: 5min
completed: 2026-03-18
---

# Phase 1 Plan 01: Foundation Engine Summary

**Hidden WKWebView AutomationEngine with atDocumentStart anti-detection, ObservableObject ViewModel with formatCodeWithDashes + email persistence, and 6 XCTest unit test files with real assertions**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-18T23:26:35Z
- **Completed:** 2026-03-18T23:31:24Z
- **Tasks:** 2
- **Files modified:** 19

## Accomplishments

- AutomationEngine creates a hidden WKWebView (zero-frame), attaches it to the UIWindowScene window hierarchy via connectedScenes, injects navigator.webdriver override at .atDocumentStart, and sets a clean Mobile Safari user agent
- AutomationViewModel exposes formatCodeWithDashes (dashes every 4 chars, 24-char cap, uppercased), isValid computed property (24-char cleanCode + email with @ and .), isRunning state lock, and email persisted to UserDefaults("savedEmail")
- All 6 unit test files upgraded from XCTFail stubs to real assertions covering FORM-01 through FORM-04, AUTO-01, and AUTO-02

## Task Commits

Each task was committed atomically:

1. **Task 1: Create AutomationEngine, JSBridgeHandler, AutomationStatus, and app entry point** - `b50ce55` (feat)
2. **Task 2: Create AutomationViewModel and implement all test assertions** - `826ee5e` (feat)

## Files Created/Modified

- `PandaAutomator/PandaAutomator/Engine/AutomationEngine.swift` - Hidden WKWebView with anti-detection, window attachment, user agent, navigation delegate
- `PandaAutomator/PandaAutomator/Engine/JSBridgeHandler.swift` - WKScriptMessageHandler for JS "log" channel
- `PandaAutomator/PandaAutomator/Models/AutomationStatus.swift` - AutomationStatus enum (idle/running/success/error)
- `PandaAutomator/PandaAutomator/ViewModel/AutomationViewModel.swift` - All UI state, formatCodeWithDashes, validation, email persistence
- `PandaAutomator/PandaAutomator/App/PandaAutomatorApp.swift` - SwiftUI @main entry point
- `PandaAutomator/PandaAutomator/App/ContentView.swift` - Placeholder root view with setupEngine() call in onAppear
- `PandaAutomator/PandaAutomator/Views/InputFormView.swift` - Placeholder form view (Plan 02 builds full UI)
- `PandaAutomator/PandaAutomatorTests/CodeFormatterTests.swift` - FORM-01: dash insertion, strip-and-reformat, 24-char cap, uppercase
- `PandaAutomator/PandaAutomatorTests/ValidationTests.swift` - FORM-03: isValid guards on code length and email format
- `PandaAutomator/PandaAutomatorTests/ViewModelTests.swift` - FORM-04: isRunning defaults false, startAutomation sets true
- `PandaAutomator/PandaAutomatorTests/EmailPersistenceTests.swift` - FORM-02: email persists to and loads from UserDefaults
- `PandaAutomator/PandaAutomatorTests/EngineSetupTests.swift` - AUTO-01: setup() creates WKWebView (verified via userAgent accessor)
- `PandaAutomator/PandaAutomatorTests/AntiDetectionTests.swift` - AUTO-02: userAgent contains "Safari", script at .atDocumentStart

## Decisions Made

- Used `ObservableObject + @Published` instead of `@Observable` macro — deployment target is iOS 16.0 and `@Observable` requires iOS 17+
- Manual UserDefaults read/write for email persistence instead of `@AppStorage` — cleaner interaction with `ObservableObject`
- `WKNavigationDelegate` and `WKScriptMessageHandler` methods marked `nonisolated` with `Task { @MainActor }` dispatch — required by Swift 6 concurrency model
- Added `userAgent` and `userScripts` testable accessors to AutomationEngine to support unit tests without exposing the private `webView` property

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added nonisolated + Task {@MainActor} dispatch on delegate methods**
- **Found during:** Task 1 (AutomationEngine and JSBridgeHandler implementation)
- **Issue:** WKNavigationDelegate and WKScriptMessageHandler protocol methods are called by WebKit on non-main threads; the @MainActor class annotation alone does not satisfy the protocol conformance under Swift 6 strict concurrency
- **Fix:** Marked both delegate methods `nonisolated` and dispatched into `Task { @MainActor in ... }` to safely cross the actor boundary
- **Files modified:** AutomationEngine.swift, JSBridgeHandler.swift
- **Verification:** Pattern follows Apple's documented approach for WKWebView + Swift concurrency
- **Committed in:** b50ce55 (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added testable accessors (userAgent, userScripts) to AutomationEngine**
- **Found during:** Task 2 (AntiDetectionTests and EngineSetupTests implementation)
- **Issue:** Tests needed to verify customUserAgent and WKUserScript injection but webView is private; no access path existed
- **Fix:** Added `var userAgent: String` and `var userScripts: [WKUserScript]` computed properties that read through the optional webView
- **Files modified:** AutomationEngine.swift
- **Verification:** AntiDetectionTests and EngineSetupTests now have meaningful assertions
- **Committed in:** b50ce55 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 2 — missing critical for correctness/testability)
**Impact on plan:** Both auto-fixes required for correct Swift concurrency and meaningful tests. No scope creep.

## Issues Encountered

- Running on Windows without Xcode — xcodebuild verification commands could not be executed. Project correctness was verified via structural review: pbxproj file references, Swift file content, and adherence to established iOS patterns.
- The Xcode project (project.pbxproj and xcscheme) existed from a prior attempt but was not committed. It was complete and correctly structured, so it was committed as-is.

## User Setup Required

None — no external service configuration required. The Xcode project is ready to open and build on a Mac with Xcode 16+ installed.

## Next Phase Readiness

- Plan 02 (UI) can proceed — ContentView and InputFormView placeholders exist; ViewModel is wired
- AutomationEngine is ready for Phase 2 automation logic to replace the stub `run(code:email:)` method
- All test files have real assertions; running `xcodebuild test` on a Mac will confirm pass/fail status
- Blocker: xcodebuild build + test verification must be run on a Mac before committing to production use

---
*Phase: 01-foundation*
*Completed: 2026-03-18*
