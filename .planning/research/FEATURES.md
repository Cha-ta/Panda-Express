# Feature Research

**Domain:** iOS personal-use web automation app (sideloaded, WKWebView form filling)
**Researched:** 2026-03-18
**Confidence:** HIGH — scope is narrow and well-defined; existing Python implementation is the ground truth

---

## Feature Landscape

### Table Stakes (Users Expect These)

These features must exist or the app is unusable. The "user" here is the developer/owner running the sideloaded app on their own iPhone.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Survey code entry (24-char, 6x4 split) | The entire flow is gated behind this input | LOW | Already validated in Python; SwiftUI TextField with character limit, split into 6 segments |
| Email entry with persistence | User re-runs this daily; retyping email every time is friction | LOW | `@AppStorage("userEmail")` persists across launches automatically with zero extra code |
| "Run" button that triggers automation | The primary action — without it there is no app | LOW | Single `Button` in SwiftUI; disables while running to prevent double-tap |
| Real-time log output | User needs to know if the form succeeded or errored; automation takes 30–60s | MEDIUM | Append log lines to a `@State` array; `ScrollViewReader` to auto-scroll to bottom |
| Completion confirmation | User needs to know when automation finishes (success or failure) | LOW | Log entry + visual state change (button re-enable, status badge) |
| Error messages in the log | Network failure, element not found, JS exception — user must see why it stopped | MEDIUM | Catch all WKWebView delegate errors and JS exceptions; propagate to log |
| Input validation before run | 24-char check on code, `@` check on email | LOW | Inline in the Run button action before loading WKWebView |
| Hidden WKWebView executing automation | The entire automation mechanism | HIGH | `WKWebView` added to view hierarchy (zero-size or off-screen); must stay in memory for the full automation session |
| Full form automation parity with script.py | All pages: radio selection, checkbox, textarea, text input, Yes/No branching, Next button | HIGH | Port all JS from script.py verbatim; wrap in Swift `evaluateJavaScript` calls sequenced on `didFinish` delegate |
| Completion detection (thank-you page check) | Automation must know when to stop | MEDIUM | Port `is_finish_page` logic: check for absence of `#NextButton` plus keyword scan via JS |

---

### Differentiators (Competitive Advantage)

This is a single-user personal tool, so "competitive advantage" means quality-of-life improvements that make the daily workflow noticeably better.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Timestamped log lines | Helps debug timing issues (did a page take too long? was a click missed?) | LOW | Prefix each log entry with `HH:mm:ss` from `Date()` |
| Page-by-page progress indicator | Seeing "Page 3 of ~15" is more reassuring than watching raw log scroll | LOW | Track `pageNum` in `@State`; display as subtitle or progress bar |
| Anti-detection: navigator.webdriver override via WKUserScript | Panda Express may fingerprint for automation; existing Python already does this | LOW | Inject at `documentStart` via `WKUserScript` — runs before any page JS loads |
| Anti-detection: realistic iOS user agent | WKWebView's default UA already looks like Mobile Safari; just verify it's not exposing app name | LOW | Set `wkWebView.customUserAgent` to a clean Mobile Safari UA string; prevents app-name leakage |
| Human-delay simulation between JS actions | Reduces bot signature; existing Python does `random.uniform(0.5, 1.5)` sleeps | LOW | `DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.5...1.5))` |
| Panda-branded SwiftUI UI (dark theme, logo) | Matches current web app; familiar to the user; makes the tool feel intentional | LOW | Assets already exist in the web project (`panda-logo.png`); import into Xcode asset catalog |
| Clear "running" vs "idle" visual state | Prevents confusion about whether automation is active | LOW | `@State var isRunning: Bool`; spinner + disabled inputs while running |

---

### Anti-Features (Deliberately NOT Building)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Visible WKWebView (show the form to user) | Seems transparent, lets user watch progress | Introduces layout complexity, scroll conflicts, and accidental user taps that break automation mid-flight | Hidden WKWebView + rich log output gives all the information without the risk |
| Submission history / past codes database | "Nice to track what I've submitted" | Adds CoreData/SwiftData complexity for zero recurring value — codes are single-use and expire | The log view shows the current run; that is sufficient |
| Multiple concurrent surveys | "Run several at once" | WKWebView instances are heavy; concurrent JS injection across multiple sessions creates race conditions and memory pressure | One-at-a-time sequencing is the correct model |
| Push / local notifications on completion | "Notify me when done" | Requires notification permission prompt; adds complexity; user is already watching the log in real-time | The log view auto-scrolls to the completion message |
| Retry logic with exponential backoff | Sounds robust | Masks real errors (site structure change, IP block) that need human attention; silent retries waste the survey code | Surface the error clearly in the log; let the user decide to re-run |
| iPad / Mac Catalyst support | "Would be nice on iPad" | Doubles UI testing surface; layout constraints differ; not the use case | iPhone-only; SwiftUI layout is simpler and the app is used on-the-go |
| App Store / TestFlight distribution | "Share with others" | Triggers App Store review; automation apps are routinely rejected under guideline 4.2 (limited functionality) and 2.5.1 (private API adjacency) | Sideloading via Xcode is the correct distribution model for personal automation tools |
| Settings screen / configuration UI | "Let me configure the feedback text" | Adds navigation stack complexity for a one-screen app; the feedback text ("Great food and excellent service!") is intentionally fixed | Hardcode the strings; change via code if needed |

---

## Feature Dependencies

```
[Email persistence (@AppStorage)]
    └──feeds──> [Email entry field pre-populated on launch]

[Hidden WKWebView lifecycle management]
    └──requires──> [WKNavigationDelegate.didFinish callbacks]
                       └──drives──> [JS injection sequencing (page-by-page automation)]
                                        └──requires──> [evaluateJavaScript / callAsyncJavaScript]

[Anti-detection: WKUserScript at documentStart]
    └──must precede──> [WKWebView.load(URLRequest)] (inject before page JS runs)

[Input validation]
    └──gates──> [Run button / WKWebView load]

[isRunning state]
    └──disables──> [Run button]
    └──disables──> [Code input]
    └──disables──> [Email input]

[Page-by-page progress tracking]
    └──enhances──> [Real-time log output]

[Completion detection (JS keyword scan)]
    └──terminates──> [Navigation loop]
    └──triggers──> [isRunning = false]
```

### Dependency Notes

- **WKWebView lifecycle requires careful memory management:** The web view must be held strongly (as a `@StateObject` or instance variable) for the entire automation session. If it goes out of scope, `evaluateJavaScript` silently fails or crashes.
- **JS injection sequencing requires didFinish:** Each page's JS runs only after `didFinish` fires for that navigation. All automation state (pageNum, isRunning) must be managed in the delegate callbacks, not in async Tasks.
- **Anti-detection script must be injected at documentStart:** Using `WKUserScriptInjectionTime.atDocumentStart` ensures `navigator.webdriver` is overridden before any Panda Express JS can read it. Injecting at `atDocumentEnd` is too late.
- **callAsyncJavaScript is preferred over evaluateJavaScript for complex JS:** For scripts that return nothing (clicks, fills), `evaluateJavaScript` is fine. For scripts that return element data (element detection), use `callAsyncJavaScript` with `arguments:` to avoid string-injection vulnerabilities and nil-unwrap crashes.

---

## MVP Definition

### Launch With (v1)

Minimum set to fully replace the Python/Playwright solution on-device.

- [ ] SwiftUI form: code input (6x4 segments), email input (pre-filled from @AppStorage), Run button — the only screen needed
- [ ] Hidden WKWebView with WKNavigationDelegate wired up
- [ ] Port all script.py JS automation logic: radio clicking, checkbox selection, textarea fill, text input fill, Yes/No branching, Next button detection
- [ ] Completion detection porting (is_finish_page logic)
- [ ] Real-time log view (ScrollView auto-scrolling, timestamped lines)
- [ ] Anti-detection: WKUserScript `navigator.webdriver` override at documentStart
- [ ] Anti-detection: clean Mobile Safari user agent via `customUserAgent`
- [ ] Error handling: WKNavigationDelegate error callbacks surface to log
- [ ] isRunning state guards (disable inputs while running, re-enable on finish/error)

### Add After Validation (v1.x)

Add once the automation is confirmed to run end-to-end reliably.

- [ ] Page progress counter ("Page 4 / ~15") — add once page count is empirically confirmed
- [ ] Human-delay tuning — measure actual timing against bot detection; tighten or widen the random range

### Future Consideration (v2+)

- [ ] Configurable feedback text — only if the hardcoded string starts causing form rejections
- [ ] Re-sign / refresh workflow documentation — the 7-day sideload expiry is a usability pain point; Xcode Automator script or Shortcut to re-sign could be a nice-to-have

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Full automation parity with script.py | HIGH | HIGH | P1 |
| Hidden WKWebView + navigation delegate | HIGH | MEDIUM | P1 |
| Real-time log view | HIGH | LOW | P1 |
| Code + email input form | HIGH | LOW | P1 |
| Email persistence (@AppStorage) | HIGH | LOW | P1 |
| Completion detection | HIGH | LOW | P1 |
| Error surfacing in log | HIGH | LOW | P1 |
| Anti-detection (user agent + webdriver override) | MEDIUM | LOW | P1 |
| isRunning state / disabled inputs | MEDIUM | LOW | P1 |
| Timestamped log lines | LOW | LOW | P2 |
| Page progress indicator | LOW | LOW | P2 |
| Human-delay simulation | MEDIUM | LOW | P2 |
| Panda branding / dark theme | LOW | LOW | P2 |
| Configurable feedback text | LOW | LOW | P3 |
| Re-sign workflow tooling | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch — app does not function without it
- P2: Should have — polish and reliability improvements
- P3: Nice to have — future consideration only

---

## Competitor Feature Analysis

This is a personal-use sideloaded app with no commercial competitors. The relevant "competitor" is the existing Python/Playwright solution it replaces.

| Feature | Python/Playwright (current) | iOS WKWebView App (target) |
|---------|-----------------------------|-----------------------------|
| Survey code entry | CLI arg `--code` | SwiftUI 6x4 segmented TextField |
| Email entry | CLI arg `--email` | SwiftUI TextField + @AppStorage persistence |
| Form automation | Playwright evaluate() calls | WKWebView evaluateJavaScript / callAsyncJavaScript |
| Log output | stdout (terminal only) | Real-time SwiftUI ScrollView on device |
| Deployment | Render (broken) / local Python env | Xcode sideload to personal iPhone |
| Network origin | Render server IP (blocked) | Device personal IP (not blocked) |
| Anti-detection | user agent + webdriver override in browser context | WKUserScript at documentStart + customUserAgent |
| Human delays | random.uniform(0.5, 1.5) | DispatchQueue asyncAfter with random interval |

---

## Sources

- Existing `script.py` — ground truth for all automation logic, JS selectors, and page-handling strategy
- [Injecting JavaScript Into Web View In iOS – Swift Senpai](https://swiftsenpai.com/development/web-view-javascript-injection/)
- [evaluateJavaScript(_:completionHandler:) – Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkwebview/evaluatejavascript(_:completionhandler:))
- [evaluateJavaScript(_:in:contentWorld:) – Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkwebview/3824704-evaluatejavascript)
- [WKNavigationDelegate.webView(_:didFinish:) – Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webview(_:didfinish:))
- [customUserAgent – Apple Developer Documentation](https://developer.apple.com/documentation/webkit/wkwebview/customuseragent)
- [Storing user settings with UserDefaults / @AppStorage – Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/storing-user-settings-with-userdefaults)
- [IOS/Swift: WebView: Javascript Injection, Pop ups, New Tabs, User Agent, and Cookies – Medium](https://medium.com/@itsuki.enjoy/ios-swift-webview-javascript-injection-pop-ups-new-tabs-user-agent-and-cookies-1e46d04262b0)
- [WKWebView evaluateJavaScript limitations thread – Apple Developer Forums](https://developer.apple.com/forums/thread/123128)

---
*Feature research for: iOS web automation app (Panda Express feedback survey)*
*Researched: 2026-03-18*
