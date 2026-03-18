# Project Research Summary

**Project:** Panda Express Feedback Automator — iOS Native App
**Domain:** iOS WKWebView browser automation / JS injection / form filling
**Researched:** 2026-03-18
**Confidence:** HIGH

## Executive Summary

This project ports a working Python/Playwright survey automation script to a native iOS app that runs entirely on-device. The approach is well-understood: embed a hidden WKWebView (frame zero, attached to the window hierarchy), inject JavaScript via `callAsyncJavaScript` to replicate the Playwright `page.evaluate()` pattern, and stream log output back to SwiftUI through `WKScriptMessageHandler`. The entire stack is Apple system frameworks — no third-party dependencies are required. The existing `script.py` is the ground truth for all form selectors, page logic, and JS automation steps; the iOS port is a translation problem, not a design problem.

The recommended architecture has four layers: a SwiftUI form (survey code + email input + log view), an `AutomationViewModel` as the single `@Observable` source of truth, an `AutomationEngine` class that owns and drives the hidden WKWebView, and a bundled `automation.js` file that encapsulates all page-interaction logic. This separation keeps WebKit-specific code isolated, makes the JS testable in a browser console independently of Swift, and ensures the WKWebView is held in a stable reference type (never a SwiftUI value-type struct) to prevent mid-session deallocation.

The primary risks are all known and preventable. The most critical is that a hidden WKWebView must be explicitly attached to the `UIWindow` hierarchy or WebKit will throttle JS execution entirely — a silent failure that looks like a network problem. The second risk is JavaScript injection timing: `didFinishNavigation` fires before dynamically-rendered form elements exist, requiring a polling `waitForElement` pattern rather than direct post-navigation execution. Both risks are addressed at Phase 1/2 setup time with specific code patterns. Bot detection (user agent leakage and `navigator.webdriver` exposure) must be configured before any request is made, mirroring the Python solution's existing approach.

## Key Findings

### Recommended Stack

The entire stack is Apple system frameworks targeting iOS 16+ with Xcode 26.3 and Swift 6. No SPM or CocoaPods dependencies are needed. Swift 6 language mode is recommended (not just available) because its strict concurrency enforcement catches the main-thread violations that WKWebView crashes on — these are real bugs, not warnings to suppress. The iOS 16 deployment target covers ~97% of active iPhones while unlocking every API needed (`callAsyncJavaScript` on iOS 14+, `WKScriptMessageHandlerWithReply` on iOS 14+).

**Core technologies:**
- Swift 6.2.4 / Xcode 26.3: Primary language — strict concurrency prevents WKWebView threading crashes
- SwiftUI (iOS 16+ APIs): UI layer for form inputs and real-time log view — declarative state binding maps cleanly to the app's two-screen layout
- WKWebView (WebKit, ships with iOS): Hidden browser that executes the survey automation — the only in-process browser available in the iOS app sandbox
- `callAsyncJavaScript`: Preferred JS execution method — handles Promises natively, passes arguments safely without string interpolation injection risk
- `WKScriptMessageHandler` / `WKScriptMessageHandlerWithReply`: JS-to-Swift message bridge for real-time log streaming
- `@AppStorage` / `UserDefaults`: Email persistence across launches — no CoreData or external storage needed

### Expected Features

The feature scope is tightly bounded because the existing Python script defines exactly what must be replicated. There is no ambiguity about what "done" looks like.

**Must have (table stakes — app is unusable without these):**
- Survey code entry (24-character, 6×4 segmented input) — the form's entry gate
- Email input with `@AppStorage` persistence — eliminates daily retyping friction
- Hidden WKWebView automation with full script.py parity — radio selection, checkbox, textarea, text input, Yes/No branching, Next button detection
- Completion detection (port `is_finish_page` logic) — automation must know when to stop
- Real-time timestamped log view with auto-scroll — the only visibility the user has into headless automation
- Error surfacing from WKNavigationDelegate failures and JS exceptions
- `isRunning` state guard disabling all inputs during automation
- Anti-detection: clean Mobile Safari `customUserAgent` + `navigator.webdriver` override at `documentStart`

**Should have (polish and reliability — add after end-to-end validation):**
- Page progress counter ("Page 4 / ~15") — requires empirical page count confirmation
- Human-delay simulation with random intervals — mirrors existing Python `random.uniform(0.5, 1.5)` behavior
- Panda-branded dark-theme UI using existing logo assets

**Defer to v2+:**
- Configurable feedback text — only relevant if hardcoded string triggers form rejections
- Re-sign workflow tooling — Xcode Automator/Shortcut to automate the 7-day sideload renewal

**Deliberately excluded (anti-features):**
- Visible WKWebView: adds layout complexity and user-tap risk; log view provides full observability
- Submission history / CoreData persistence: single-use codes have no historical value
- Retry logic: masks real failures (site structure drift, IP block) that require human attention
- iPad / Mac Catalyst: doubles test surface for a personal iPhone-only use case

### Architecture Approach

The architecture follows a strict four-layer separation: SwiftUI views bind to `AutomationViewModel` (`@Observable`), which owns `AutomationEngine`, which exclusively touches `WKWebView`. No SwiftUI view ever imports WebKit. The automation JavaScript lives in a bundled `automation.js` file (not embedded as Swift strings), making it independently editable and testable in a browser console without Swift recompilation. This mirrors the existing `script.py` structure.

**Major components:**
1. `AutomationViewModel` (`@Observable`, `@MainActor`) — single source of truth for all UI state; bridges Engine to Views; holds `logMessages`, `isRunning`, `status`
2. `AutomationEngine` (`class`, `@MainActor`) — owns the hidden `WKWebView(frame: .zero)`; implements `WKNavigationDelegate` and `WKScriptMessageHandler`; drives JS injection sequence
3. `automation.js` (bundled JS file) — page-detection and form-interaction logic ported from `script.py`; calls `window.webkit.messageHandlers.log.postMessage()` for log streaming
4. `InputFormView` + `LogView` (SwiftUI) — form inputs and real-time log output, purely reactive bindings to ViewModel
5. `AutomationStatus` enum — drives UI state transitions (idle / running / success / error) cleanly

**Build order implied by dependencies:**
Models → ViewModel → Engine skeleton → UI views → `automation.js` port → JS injection wiring → JS bridge handler → anti-detection → error handling

### Critical Pitfalls

1. **WKWebView not attached to UIWindow hierarchy** — hidden WKWebView that is not a subview of the active `UIWindow` will silently throttle or stop all JS execution, network requests, and navigation callbacks. Fix: attach with `UIApplication.shared.connectedScenes` window API immediately after creation. Verify on a real device, not just Simulator.

2. **JS injection before DOM elements exist** — `didFinishNavigation` fires before dynamically-rendered form elements exist. Direct post-navigation JS injection silently finds no elements. Fix: inject a `waitForElement(selector, callback)` polling loop (200ms interval, max iterations) rather than executing automation logic directly in `didFinish`.

3. **`evaluateJavaScript` called from background thread** — any WKWebView API call off the main thread crashes. Swift 6 strict concurrency surfaces this as a compile-time warning. Fix: annotate `AutomationEngine` and `AutomationViewModel` with `@MainActor` globally; treat all WKWebView calls as UI operations.

4. **`evaluateJavaScript` crashes on void-returning scripts** — the Swift async bridge fatal-errors when JS returns nothing. Automation click scripts return void. Fix: append `; true` to all injected scripts, or use `callAsyncJavaScript` (iOS 14+) which handles void returns correctly.

5. **Bot detection via user agent leakage** — default WKWebView UA exposes the app bundle name; anti-bot systems detect non-browser UAs and block or redirect. Fix: set `customUserAgent` to a clean Mobile Safari string and inject `navigator.webdriver` override as `WKUserScript` at `atDocumentStart` — must precede any page request.

## Implications for Roadmap

Based on research, a three-phase structure is recommended, matching the build-order dependency chain identified in ARCHITECTURE.md and the pitfall-to-phase mapping in PITFALLS.md.

### Phase 1: Foundation — Project Setup + WKWebView Scaffolding

**Rationale:** Critical infrastructure decisions must be locked in before writing any automation logic. The WKWebView threading model (`@MainActor` everywhere), window hierarchy attachment, and signing configuration (free 7-day vs. paid 1-year) cannot be retrofitted cheaply. Architecture missteps here propagate throughout all subsequent work.

**Delivers:** Compilable Xcode project with a hidden WKWebView that demonstrably loads `pandaexpress.com/feedback`, fires `didFinishNavigation`, and has `@MainActor` isolation enforced throughout.

**Addresses (from FEATURES.md):** Email persistence (`@AppStorage`), `isRunning` state infrastructure, hidden WKWebView lifecycle management

**Avoids (from PITFALLS.md):**
- WKWebView not attached to window hierarchy (Pitfall 1) — verified on real device before moving to Phase 2
- `evaluateJavaScript` on background thread (Pitfall 3) — `@MainActor` annotation established at project creation
- 7-day sideload expiry decision (Pitfall 4) — signing account decision made before first build

**Components built:** `AutomationStatus` + `LogEntry` models, `AutomationViewModel` skeleton, `AutomationEngine` with WKWebView setup + `loadSurveyURL()`, `InputFormView` + `LogView` with placeholder data, `@AppStorage` email persistence

### Phase 2: Automation Engine — JS Port + Page Interaction

**Rationale:** The automation logic is the core deliverable and the highest-complexity work. Building it as Phase 2 means Phase 1 infrastructure (threading, lifecycle, window attachment) is already validated, eliminating the most dangerous failure modes before writing any automation code. The `automation.js` can be developed and tested in a browser console independently of Swift.

**Delivers:** Full form automation parity with `script.py` — the app runs the complete Panda Express feedback survey end-to-end with real-time log output and completion detection.

**Uses (from STACK.md):** `callAsyncJavaScript` for all automation actions, `WKUserContentController` + `WKUserScript` for `navigator.webdriver` override at `documentStart`, `WKScriptMessageHandler` for JS→Swift log streaming, `customUserAgent` for bot detection avoidance

**Implements (from ARCHITECTURE.md):** `AutomationEngine.runPageStep()`, `automation.js` (full port of `script.py` JS logic), `JSBridgeHandler`, `WKNavigationDelegate.didFinishNavigation` → polling → execute pattern

**Avoids (from PITFALLS.md):**
- JS injection before DOM ready (Pitfall 2) — `waitForElement` polling pattern, never fixed delays
- `evaluateJavaScript` void return crash (Pitfall 6) — safe JS wrapper established before any automation scripts written
- Bot detection / user agent leak (Pitfall 5) — `customUserAgent` + `webdriver` override as first setup step

**Includes:** All P1 features from FEATURES.md prioritization matrix

### Phase 3: Polish + Reliability

**Rationale:** Add quality-of-life features after the happy path is confirmed working end-to-end. Attempting polish during Phase 2 risks premature optimization before the core flow is stable.

**Delivers:** Production-quality personal tool with page progress indicators, human delays, cancellation support, session reset between runs, branded UI, and documented re-sign workflow.

**Addresses (from FEATURES.md):** All P2 features (timestamped logs, page progress counter, human-delay simulation, Panda branding), plus Cancel button (UX pitfall from PITFALLS.md), session contamination prevention (Pitfall 7 — cookie reset between runs), security hardening (`#if DEBUG` log guards)

**Defers:** P3 features (configurable feedback text, re-sign tooling) to v2 based on actual usage friction

### Phase Ordering Rationale

- Phase 1 before Phase 2 because the WKWebView window hierarchy attachment and `@MainActor` annotation must be verified on real hardware before automation logic is written — discovering these issues mid-Phase 2 requires architectural rework
- Phase 2 before Phase 3 because polish features (progress counter, human delays, cancellation) require knowing the actual page count and timing characteristics, which are only known after running the full automation end-to-end
- `automation.js` developed during Phase 2 can be tested directly in a browser console against the live Panda Express form before Swift integration, reducing integration risk

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** The exact DOM structure of the Panda Express survey form (selectors, page count, branching logic) — the existing `script.py` is the ground truth but the live form may have drifted. Recommend a live-form selector audit before finalizing the `automation.js` port.
- **Phase 2:** Session persistence behavior between automation runs — PITFALLS.md flags cookie contamination but the exact WKWebsiteDataStore reset API needs verification for the specific survey platform behavior.

Phases with standard patterns (research not needed):
- **Phase 1:** WKWebView setup, `@MainActor` annotation, `@AppStorage` persistence — all well-documented Apple patterns with HIGH confidence sources
- **Phase 3:** SwiftUI branding, timestamped logs, progress counter — standard SwiftUI state patterns, no research needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs are Apple system frameworks with stable availability since iOS 14. Xcode version verified against xcodereleases.com. No third-party dependencies to go stale. |
| Features | HIGH | Existing `script.py` is the ground truth for feature scope. No ambiguity about what parity means. Anti-features explicitly justified. |
| Architecture | HIGH | Core WebKit delegation and messaging patterns verified across Apple Developer docs, WWDC sessions, and multiple community implementations. WKZombie (open-source headless WKWebView framework) confirms the hidden-frame approach is viable. |
| Pitfalls | HIGH | Majority of pitfalls verified against Apple Developer Forums with first-hand reports. WKWebView window hierarchy requirement is a documented behavior, not a heuristic. |

**Overall confidence:** HIGH

### Gaps to Address

- **Live form selector validation:** The `script.py` selectors are accurate as of the time the Python solution was written. The Panda Express survey form may have changed. Recommend a manual walkthrough of the live form (or running `script.py` with logging) to confirm current selectors before Phase 2 begins.
- **Exact page count:** FEATURES.md references "~15 pages" but this is an estimate. The actual page count affects the progress indicator implementation. Confirm empirically during Phase 2 development.
- **Bot detection aggressiveness:** The Python solution's user agent + `webdriver` override is carried forward. If the survey platform has added additional fingerprinting (canvas, font, timing-based detection) since the Python solution was built, additional countermeasures may be needed. This is low probability but should be verified on first end-to-end run.
- **WKWebsiteDataStore reset API:** The correct API call to fully reset session/cookie state between runs needs verification (the pitfall is known; the precise Swift API to fix it needs a code-level check during Phase 3).

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation — `callAsyncJavaScript`, `WKNavigationDelegate`, `WKUserContentController`, `customUserAgent`, `evaluateJavaScript` — official API reference with availability versions
- xcodereleases.com — Xcode 26.3 as current stable, Swift 6.2.4 bundled (verified 2026-02-26)
- Apple Developer: Adopting Swift 6 — `@MainActor` strategy for WKWebView delegates
- Apple Developer Forums — WKWebView JS throttling without window hierarchy (thread/111247)
- Apple Developer Forums — `evaluateJavaScript` crash with nil/void return (thread/701553)
- Existing `script.py` — ground truth for all feature and automation logic

### Secondary (MEDIUM confidence)
- Swift Senpai: Web View JavaScript Injection — `WKUserScript` patterns, injection timing
- DEV Community: WWDC 2025 WebKit for SwiftUI — native SwiftUI `WebView`/`WebPage` requires iOS 26+
- Filip Němeček: iOS 14 WKWebView new features — `callAsyncJavaScript` usage patterns
- Hacking with Swift: Ultimate Guide to WKWebView — lifecycle and threading patterns
- Medium: Messaging Between WKWebView and Native Application in SwiftUI — `WKScriptMessageHandler` patterns

### Tertiary (LOW confidence)
- Capital One Tech / Medium: JavaScript Manipulation on iOS Using WebKit — referenced by multiple sources but returned 403 on direct fetch; patterns cross-validated against Apple docs

---
*Research completed: 2026-03-18*
*Ready for roadmap: yes*
