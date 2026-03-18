# Pitfalls Research

**Domain:** iOS WKWebView automation / JS injection / Xcode sideloading
**Researched:** 2026-03-18
**Confidence:** HIGH (majority verified against Apple Developer docs, official Apple Forums, and primary sources)

## Critical Pitfalls

### Pitfall 1: Hidden WKWebView Not Attached to Window Hierarchy

**What goes wrong:**
A WKWebView created as a zero-size or offscreen view — but never added to the window — silently throttles or stops JavaScript execution entirely. Network requests may never fire, `evaluateJavaScript` calls return nothing, and `didFinishNavigation` may never fire.

**Why it happens:**
WKWebView uses its `superview`/parent chain to detect whether it is "active." If no parent exists (or the parent is not part of the visible window hierarchy), WebKit conserves resources and throttles JS execution, network activity, and navigation callbacks. Developers assume hidden = zero-frame subview anywhere, but the view must be in the window hierarchy.

**How to avoid:**
Always attach the WKWebView to the application's main window even if the frame is zero-size:
```swift
let webView = WKWebView(frame: .zero)
UIApplication.shared.windows.first?.addSubview(webView)
// iOS 15+ preferred:
UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .first?.windows.first?.addSubview(webView)
```
Never store it only as a `@State` variable inside a SwiftUI view without ensuring it reaches a `UIWindow`.

**Warning signs:**
- `didFinishNavigation` never fires after `load(request:)`
- `evaluateJavaScript` completion handler is never called
- Network tab in Charles/Proxyman shows no outgoing requests
- Works fine in simulator but not on device

**Phase to address:** Phase 1 (WKWebView scaffolding / initial setup)

---

### Pitfall 2: Injecting JavaScript Before the DOM Is Ready

**What goes wrong:**
`didFinishNavigation` fires before the target DOM elements exist — particularly on dynamically-rendered pages (React, Angular, survey platforms with JS-rendered forms). `evaluateJavaScript` runs and finds no elements, silently does nothing, and the automation loop never advances past the first page.

**Why it happens:**
`didFinishNavigation` corresponds roughly to the HTML document load, but JavaScript frameworks may not have rendered their components yet. The Panda Express survey likely uses a JS-heavy form renderer. Developers coming from Playwright assume `page.waitForSelector` semantics exist natively — they do not in WKWebView.

**How to avoid:**
- Do not fire automation scripts directly from `didFinishNavigation`. Instead, inject a polling loop that waits for the target elements to appear before acting:
```javascript
function waitForElement(selector, callback) {
    const el = document.querySelector(selector);
    if (el) { callback(el); return; }
    setTimeout(() => waitForElement(selector, callback), 200);
}
```
- Use `WKUserScript` with `injectionTime: .atDocumentEnd` for setup scripts, but still poll for dynamic content.
- Keep a maximum iteration count to prevent infinite polls on error states.

**Warning signs:**
- Automation returns "0 elements found" immediately after navigation
- Script works with a 2-second `DispatchQueue.main.asyncAfter` hack but fails without it
- Works on first page load but fails on subsequent pages

**Phase to address:** Phase 2 (JavaScript automation engine / page interaction logic)

---

### Pitfall 3: `evaluateJavaScript` Called from Background Thread

**What goes wrong:**
Calling `evaluateJavaScript` or any WKWebView API from a background thread causes a crash: `WKWebView.evaluateJavaScript(_:completionHandler:) must be used from main thread only`. With Swift concurrency, this manifests as a Swift 6 `@MainActor` isolation warning that, if ignored, becomes a runtime crash.

**Why it happens:**
WKWebView is `@MainActor`-isolated. When porting Playwright automation logic (which runs in async task queues) to Swift, developers wrap calls in `Task { }` or `DispatchQueue.global().async` without pulling WKWebView calls back to the main actor.

**How to avoid:**
- Annotate any class that holds a WKWebView with `@MainActor`.
- Use `await MainActor.run { }` when calling from a non-main context.
- Prefer `callAsyncJavaScript` (iOS 14+) which is also `@MainActor`-isolated but handles async JS natively.
- Treat all WKWebView calls as UI calls — same rules as UIKit.

**Warning signs:**
- Xcode shows `Main Thread Checker` violations in the console
- Swift 6 strict concurrency produces `@MainActor` warnings on WKWebView calls
- Intermittent crashes only when running automation during heavy background work

**Phase to address:** Phase 1 (architecture setup) and Phase 2 (automation engine)

---

### Pitfall 4: Sideloaded App Expires After 7 Days (Free Account)

**What goes wrong:**
With a free Apple ID (not paid $99/year Apple Developer Program), sideloaded apps expire after exactly 7 days. The app stops launching entirely — no warning, no graceful failure. The user must reconnect to a Mac, open Xcode, and reinstall.

**Why it happens:**
Free provisioning profiles expire 7 days from issuance. iOS's code-signing verification rejects the app because the signing certificate has expired. Apple deliberately limits free accounts to prevent mass distribution without App Store review.

**How to avoid:**
- Document this constraint explicitly in the app's UI or README — set user expectations upfront.
- If the app will be used regularly by anyone without Xcode access, budget for the $99/year Apple Developer Program membership (1-year certificate, no weekly reinstall).
- Free account also limits registration to 10 App IDs and 3 devices simultaneously — avoid accumulating bundle IDs during development by reusing one bundle identifier consistently.

**Warning signs:**
- App icon grays out and shows "Not Available" label on device after 7 days
- Xcode shows provisioning profile expiry in Signing & Capabilities tab
- Device shows "Unable to verify app" alert on launch

**Phase to address:** Phase 1 (project setup / signing configuration) — decide free vs. paid account before writing any code

---

### Pitfall 5: User Agent Revealing WKWebView Identity Triggering Bot Detection

**What goes wrong:**
By default, WKWebView uses a user agent string that includes the app bundle name and iOS version in a format distinct from Safari/Chrome browsers. Some anti-bot systems (Akamai, Cloudflare, Panda Express's survey platform) detect non-browser user agents and block or redirect the request, causing the form to fail silently or show a CAPTCHA.

**Why it happens:**
The existing Python/Playwright solution already handles this with `navigator.webdriver` override and user agent spoofing. The iOS port must replicate the same override. Developers new to WKWebView assume the browser view looks like Safari — it does not by default when the app name is embedded.

**How to avoid:**
Set a real Safari/Chrome user agent string immediately during WKWebView configuration, before any request is made:
```swift
webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
```
Also inject the `navigator.webdriver` override as a `WKUserScript` at `atDocumentStart`:
```javascript
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
```

**Warning signs:**
- Survey site redirects to an error page immediately on load
- HTTP response status 403 or unexpected redirect to a CAPTCHA
- Works when viewed in Safari but fails in the app

**Phase to address:** Phase 2 (automation engine — anti-detection setup, mirrors existing Python solution)

---

### Pitfall 6: `evaluateJavaScript` Returns `nil` / Crashes on Void-Returning Scripts

**What goes wrong:**
The async `evaluateJavaScript` Swift API crashes with a fatal error when the JavaScript returns nothing (void). This is a known WebKit bug where `nil` is a valid return but the Swift bridging throws `EXC_BAD_ACCESS` or a fatal unwrap error.

**Why it happens:**
Objective-C annotates the return as nullable but Swift's async bridging does not correctly handle `nil` as a success value. The automation logic for clicking radio buttons and submitting forms will frequently call scripts that return nothing.

**How to avoid:**
- Always have JavaScript return an explicit value, even if unused: append `; true` or `; null` to every injected script.
- Or use `callAsyncJavaScript` (iOS 14+) which handles void returns correctly.
- Wrap `evaluateJavaScript` in a try/catch at all call sites.

**Warning signs:**
- App crashes at `evaluateJavaScript` after a script that clicks or submits a form
- No crash during development but crashes on release builds (stricter bridging)
- Works in Simulator but crashes on device (different WebKit process model)

**Phase to address:** Phase 2 (automation engine) — establish the safe JS calling wrapper before writing any automation scripts

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Raw `DispatchQueue.main.asyncAfter(deadline: .now() + 2.0)` timing delays instead of element-polling | Fast to write, works most of the time | Breaks on slow networks or server-side changes; impossible to tune reliably | Never — use polling loops |
| Copying Python `script.py` logic 1:1 as a raw JS string blob | Avoids refactoring effort | Impossible to debug, test, or update; single JS string failure kills entire automation | MVP only, must be replaced |
| Using `UIApplication.shared.windows.first` for window attachment | Simple iOS 13-compatible call | Deprecated in iOS 15; will warn and eventually break | Acceptable short-term; use `connectedScenes` API before first real deployment |
| Free Apple Developer account for sideloading | Zero cost | 7-day expiry requires reinstall weekly; blocks use without Xcode nearby | Acceptable if only you use the app and have Mac nearby; unacceptable for any other user |
| Single WKWebView instance reused across multiple automation runs | Simpler state model | Cookies/session state from previous runs contaminate new runs; survey may reject reused sessions | Acceptable if a `WKWebsiteDataStore.default().removeData(...)` reset is called before each run |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Panda Express survey site | Assuming site structure is stable — Playwright script selector names may drift | Build selectors defensively with fallbacks; log the DOM state when elements are not found |
| WKWebView ↔ Swift messaging | Using `evaluateJavaScript` for two-way communication (polling return values) | Use `WKScriptMessageHandler` to post messages from JS to Swift; use `evaluateJavaScript` only Swift → JS |
| UserDefaults email persistence | Storing email directly without any migration plan | Use a single key constant; always read with a nil-default fallback |
| Swift concurrency + WKWebView | Mixing `async/await` Task context with WKWebView calls without `@MainActor` annotation | Mark the ViewModel/Controller class `@MainActor` globally |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Polling DOM too aggressively (< 100ms interval) | Battery drain; UI thread jank; survey site may flag rapid synthetic events | Use 200–500ms polling intervals; back off on retry | Immediately, on device |
| Creating a new WKWebView per automation run without destroying the old one | Memory grows unboundedly after repeated uses | Keep one WKWebView; call `loadHTMLString("")` or `load(URLRequest(url: about:blank))` to reset; call `removeFromSuperview()` and nil-out when destroying | After ~5–10 runs in a session |
| Injecting large JS blobs on every page navigation | Slight but visible delay before automation starts per page | Bundle automation JS as a `WKUserScript` injected at document start once | N/A — single user, low frequency |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Disabling ATS (`NSAllowsArbitraryLoads: true`) globally in Info.plist | Any HTTP resource can be loaded, weakening TLS enforcement across the whole app | Use `NSAllowsArbitraryLoadsInWebContent` to scope the exception to WKWebView only; pandaexpress.com is HTTPS so this should not be needed at all |
| Logging survey code and email to console in production | Sensitive user data in device logs accessible via Xcode/Console.app | Use `#if DEBUG` guards around detailed log output; in release builds, log only progress state not input values |
| No input validation on survey code before passing to URL | Malformed input could produce confusing failures or unintended navigation | Validate 24-char alphanumeric format before constructing the survey URL |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No progress feedback while WKWebView runs headlessly | User sees a blank "running" state with no indication of which page the survey is on | Log each page transition and element interaction to the real-time log view; show "Page 3 of ~15" |
| App silently fails when survey code is already used | User retries, wasting time | Detect "invalid code" or "already submitted" page text and surface a clear error message immediately |
| No way to cancel an in-progress automation run | User cannot stop a stuck run without force-quitting | Add a Cancel button that stops polling, calls `stopLoading()` on the WKWebView, and resets state |
| App expiry (7-day sideload) with no in-app warning | App suddenly stops launching; user confused | This cannot be shown in-app after expiry, so document it clearly in the README / setup instructions |

---

## "Looks Done But Isn't" Checklist

- [ ] **WKWebView hidden mode:** View appears to work in Simulator — verify it is attached to the window hierarchy on a real device, not just held as a SwiftUI state variable
- [ ] **JS injection timing:** Automation "completes" in testing but may skip pages — verify that every page transition waits for DOM elements, not just for `didFinishNavigation`
- [ ] **User agent spoofing:** App loads the survey page — verify the full survey form is accessible and not a bot-blocked error page by checking the page title/URL after load
- [ ] **navigator.webdriver override:** Injected as a `WKUserScript` at `atDocumentStart`, not after page load (too late — site JS runs before injection)
- [ ] **Void JS return crash:** Automation scripts click buttons — verify every `evaluateJavaScript` call returns a value or is wrapped in try/catch
- [ ] **Session reset between runs:** Second automation run works — verify cookies and session data from run 1 do not contaminate run 2
- [ ] **7-day expiry acknowledged:** App installs and runs — verify which Apple account is used for signing and document reinstall cadence for users

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| WKWebView not attached to window | LOW | Add `UIApplication.shared.connectedScenes` window attachment; fix is one line |
| JS timing race (automation skips pages) | MEDIUM | Replace fixed delays with element-polling pattern throughout automation engine |
| Thread crash on evaluateJavaScript | MEDIUM | Add `@MainActor` to ViewModel; audit all WKWebView call sites |
| Sideload expiry (free account) | LOW (if Xcode available) / HIGH (if not) | Reconnect device to Mac, open Xcode, Run again; or upgrade to paid account |
| Bot detection / site blocking | MEDIUM | Audit and update user agent string; add additional anti-detection JS; test against live site |
| Void JS return crash | LOW | Add `; true` suffix to all void scripts; or migrate to `callAsyncJavaScript` |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| WKWebView not attached to window hierarchy | Phase 1 — WKWebView scaffolding | On real device: `didFinishNavigation` fires within 5s of `load(request:)` |
| JS injection before DOM ready | Phase 2 — Automation engine | Automation reliably finds form elements on all ~15 survey pages without fixed delays |
| evaluateJavaScript on background thread | Phase 1 — Architecture / Phase 2 — Engine | No Main Thread Checker violations; no Swift 6 concurrency warnings |
| Sideload 7-day expiry | Phase 1 — Project setup | Decision on free vs. paid account documented before first build |
| User agent / bot detection | Phase 2 — Anti-detection (mirrors Python solution) | Survey form loads completely; no redirect to error or CAPTCHA page |
| Void JS return crash | Phase 2 — Automation engine | All evaluateJavaScript calls return explicit value or use callAsyncJavaScript |
| Session contamination between runs | Phase 3 — Polish / error handling | Second consecutive run completes without "already submitted" or stale state errors |

---

## Sources

- [Apple Developer Forums — WKWebView JS doesn't run without view hierarchy](https://developer.apple.com/forums/thread/111247)
- [Filip Němeček — Using WKWebView in headless mode](https://nemecek.be/blog/19/using-wkwebview-in-headless-mode)
- [Apple Developer Docs — evaluateJavaScript(_:completionHandler:)](https://developer.apple.com/documentation/webkit/wkwebview/1415017-evaluatejavascript)
- [Apple Developer Docs — callAsyncJavaScript](https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript)
- [Apple Developer Docs — customUserAgent](https://developer.apple.com/documentation/webkit/wkwebview/customuseragent)
- [Apple Developer Forums — evaluateJavaScript crash with async/nil return](https://developer.apple.com/forums/thread/701553)
- [Apple Developer Forums — WKWebView main thread requirement](https://github.com/Cap-go/capacitor-inappbrowser/issues/181)
- [Swift Forums — Swift 6 @MainActor concurrency warning with evaluateJavaScript](https://forums.swift.org/t/concurrency-warning-when-using-wkwebview-evaluatejavascript-and-async-let/76836)
- [Swift Senpai — WKWebView JavaScript injection patterns](https://swiftsenpai.com/development/web-view-javascript-injection/)
- [Apple Developer — Choosing a Membership (free vs paid)](https://developer.apple.com/support/compare-memberships/)
- [myByways — New limitations on free Apple Developer account](https://mybyways.com/blog/new-limitations-imposed-on-free-apple-developer-account)
- [Apple Developer Forums — WKWebView didFinishNavigation timing](https://developer.apple.com/forums/thread/124548)
- [Apple Developer Forums — WKWebView cookie loss in background](https://developer.apple.com/forums/thread/745912)
- [Filip Němeček — iOS 14 WKWebView new features (callAsyncJavaScript)](https://nemecek.be/blog/32/ios-14-what-is-new-for-wkwebview)

---
*Pitfalls research for: iOS WKWebView automation — Panda Express feedback survey app*
*Researched: 2026-03-18*
