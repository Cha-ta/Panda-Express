# Stack Research

**Domain:** Native iOS app with hidden WKWebView browser automation + JavaScript injection
**Researched:** 2026-03-18
**Confidence:** HIGH (core WebKit/Swift APIs are stable; version numbers verified against xcodereleases.com and official release notes)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.2.4 (bundled with Xcode 26.3) | Primary language | The only sensible choice for native iOS. Swift 6 strict concurrency enforces safe UI/background separation — critical because WKWebView callbacks arrive on unpredictable threads. |
| SwiftUI | iOS 16+ APIs | UI layer (survey code entry, log view, email field) | Modern declarative UI that handles state binding and list updates with minimal code. The log output and form inputs map directly to `ScrollView` + `List`. Use SwiftUI for all visible UI. |
| WKWebView (WebKit) | iOS 16+ | Hidden browser that navigates pandaexpress.com/feedback and executes automation JS | The only in-process browser available on iOS. Maps 1:1 to Playwright's `page.evaluate()` pattern. Supports JS injection, custom user agents, navigation delegates, and message passing. |
| Xcode | 26.3 (current stable) | IDE, build tool, signer, device deployer | Required. Handles code signing for sideloading via Personal Team (free Apple ID). No alternatives. |

### Supporting Libraries / APIs

| Library / API | Availability | Purpose | When to Use |
|---------------|-------------|---------|-------------|
| `WKUserContentController` + `WKUserScript` | iOS 8+ | Inject a JS script on every page load at document end — equivalent to Playwright's `addInitScript()` | Use for injecting the `navigator.webdriver` override script that runs before page logic detects automation |
| `WKWebView.evaluateJavaScript(_:completionHandler:)` | iOS 8+ | Fire one-off JS and receive a return value synchronously in a completion handler | Use for simple read operations: check if `document.readyState` is complete, read the current page title |
| `WKWebView.callAsyncJavaScript(_:arguments:in:in:completionHandler:)` | iOS 14+ | Execute async JS (including `await`, Promises) and receive the resolved value | **Preferred for all automation actions** — clicking buttons, filling inputs, waiting for DOM changes. Handles Promises natively so you avoid callback nesting. Pass survey code / email as `arguments` dict to avoid string interpolation injection bugs. |
| `WKScriptMessageHandler` + `WKScriptMessageHandlerWithReply` | iOS 8+ / iOS 14+ | Receive messages from JS running inside the page back to Swift | Use for real-time log streaming: inject a JS `window.webkit.messageHandlers.log.postMessage(msg)` call and surface it in the SwiftUI log view. `WithReply` variant (iOS 14+) is preferred — it supports async handlers and eliminates manual ACK tracking. |
| `WKNavigationDelegate` | iOS 8+ | Detect when each survey page finishes loading (`didFinishNavigation`) | Use to trigger the next automation step after page navigation completes. The automation state machine lives here. |
| `WKWebViewConfiguration` | iOS 8+ | Configure user content controller, custom user agent, JS preferences before the view is created | Must be configured before `WKWebView` init — cannot be changed after. Set `customUserAgent` here. |
| `UserDefaults` | All iOS | Persist user's email address between launches | Standard iOS persistence for lightweight values. No third-party library needed. |
| `@MainActor` | Swift 5.5+ / Xcode 16 | Ensure all WKWebView and SwiftUI state mutations happen on the main thread | Xcode 26 / Swift 6 enforces this strictly. Annotate your `WebAutomationController` class with `@MainActor` to silence concurrency warnings and prevent crashes. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 26.3 | Everything: editor, compiler, simulator, device signing | Download from the Mac App Store or developer.apple.com. Free. Requires macOS Sequoia or later. |
| Apple ID (free, no paid membership) | Sign the app for sideloading via Personal Team | Free accounts allow 3 sideloaded apps per device, provisioning profiles expire every 7 days. Re-run from Xcode after 7 days to re-sign. For a personal project used daily, consider the $99/year paid account (profiles last 1 year). |
| iPhone Developer Mode | Allow Xcode-built apps to run on your personal iPhone | Enable at Settings > Privacy & Security > Developer Mode. Required since iOS 16. One-time setup. |
| Xcode Simulator | Run the app without a physical device during development | Useful for UI iteration, but WKWebView behaviour (user agents, network) differs from real hardware. Test actual survey automation on a real device. |

---

## Installation / Project Setup

This is a native Xcode project. No package manager commands apply.

```
Project Setup Steps:
1. Open Xcode 26, create new project → App → choose SwiftUI interface
2. Set Deployment Target: iOS 16.0 (covers all iPhones from iPhone 8 onward,
   widely adopted, unlocks all APIs needed — callAsyncJavaScript, WKScriptMessageHandlerWithReply)
3. Signing & Capabilities → Team: select your personal Apple ID (Personal Team)
4. No SPM dependencies required — everything needed is in WebKit and SwiftUI (system frameworks)
5. Add WebKit.framework to Linked Frameworks if Xcode does not auto-import
6. Connect iPhone via USB, select as run destination, press Run
```

No third-party dependencies. The entire stack is Apple system frameworks.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| WKWebView + JS injection | Playwright / Selenium on iOS | Never — Playwright requires a Node.js process and cannot run on-device in an iOS app sandbox. |
| WKWebView + JS injection | SFSafariViewController | Never for automation — SFSafariViewController runs in a separate Safari process; you cannot inject JS or read its DOM. |
| WKWebView + JS injection | ASWebAuthenticationSession | Never — authentication-only, no JS access. |
| SwiftUI | UIKit | Use UIKit if you need WKWebView features that SwiftUI wraps awkwardly (you don't — this app's UI is simple enough that SwiftUI is fine and UIKit boilerplate would add noise). |
| `callAsyncJavaScript` | `evaluateJavaScript` | Use `evaluateJavaScript` only for simple read-only queries on iOS 13 and below. For iOS 14+ with any async/await JS, `callAsyncJavaScript` is strictly better. |
| Native `WebView`/`WebPage` SwiftUI (iOS 26) | UIViewRepresentable wrapper around WKWebView | Use the native SwiftUI `WebView`/`WebPage` APIs **only** if you set iOS 26 as minimum deployment target. Since the goal is to support current iPhones running iOS 16+, the `UIViewRepresentable` wrapper around `WKWebView` is the right choice now. |
| `WKScriptMessageHandlerWithReply` | URL scheme hijacking for JS→Swift messages | `WKScriptMessageHandlerWithReply` is cleaner, supported since iOS 14, and doesn't require intercepting navigation events. Avoid URL scheme hacks. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `UIWebView` | Deprecated in iOS 12, removed in iOS 15. App will be rejected. | `WKWebView` |
| String interpolation to build JS from user input | Allows injection attacks and breaks on special characters in the survey code or email (apostrophes, `+` signs, etc.) | `callAsyncJavaScript(_:arguments:...)` — pass values as the `arguments: [String: Any]` dict; WebKit handles escaping. |
| `WKWebView` inside a visible `ScrollView` | Creates nested scrolling conflicts that are hard to resolve in SwiftUI | Set `webView.scrollView.isScrollEnabled = false` and size the hidden WKWebView to a fixed off-screen frame (e.g., 1×1 pt off-screen). The user never sees it. |
| iOS 26 `WebView`/`WebPage` SwiftUI APIs | Currently requires iOS 26 minimum, which excludes iPhones running iOS 16-25 — too restrictive for a personal tool you'll use on your current device. | `UIViewRepresentable` wrapping `WKWebView` with `iOS 16` deployment target. |
| Swift 5 language mode with Xcode 26 | Xcode 26/Swift 6 will still compile in Swift 5 mode, but you lose the concurrency safety guarantees that prevent WKWebView delegate crashes. | Enable Swift 6 language mode from project settings. Address the handful of `@MainActor` warnings it surfaces — they point to real threading bugs. |
| Third-party "automation" libraries (e.g., Turbolinks-iOS) | These are navigation managers, not automation frameworks. They don't expose the low-level JS injection and delegate hooks needed here. | Direct `WKWebView` API. |

---

## Stack Patterns by Variant

**If targeting iOS 16-17 (current phones today):**
- Use `UIViewRepresentable` wrapper around `WKWebView`
- Use `callAsyncJavaScript` (available iOS 14+) for all automation steps
- Use `WKScriptMessageHandlerWithReply` for JS→Swift log messages

**If you upgrade the deployment target to iOS 26 in a future version:**
- Replace `UIViewRepresentable` with SwiftUI native `WebPage` API
- `WebPage.callJavaScript()` replaces the direct `WKWebView` calls
- Not worth doing now — no user benefit, and it blocks the app on current iOS versions

**If you want a 1-year provisioning profile (stop re-signing every 7 days):**
- Purchase $99/year Apple Developer Program membership
- Set Signing to your paid team in Xcode → Signing & Capabilities
- App will run for 365 days without re-signing

---

## Version Compatibility

| Component | Version | Compatible With | Notes |
|-----------|---------|-----------------|-------|
| Xcode 26.3 | 26.3 | macOS Sequoia 15.x | Current stable as of 2026-03-18. Swift 6.2.4 bundled. |
| iOS deployment target | 16.0 | iPhone 8 and newer | All WKWebView APIs used (callAsyncJavaScript, WKScriptMessageHandlerWithReply) available on iOS 14+. Setting 16.0 gives headroom and covers ~97% of active iPhones. |
| Swift | 6.2.4 | Xcode 26.3 | Use Swift 6 language mode. Enable in Build Settings → Swift Language Version. |
| WebKit / WKWebView | Ships with iOS, no separate versioning | iOS 16+ | All APIs used are stable since iOS 14. No deprecation risk. |
| `callAsyncJavaScript` | iOS 14+ | iOS 16+ target | No compatibility issues with iOS 16 minimum target. |
| `WKScriptMessageHandlerWithReply` | iOS 14+ | iOS 16+ target | No compatibility issues. |
| Native SwiftUI `WebView`/`WebPage` | iOS 26+ only | NOT compatible with iOS 16 target | Do not use. Future option only. |

---

## Sources

- [xcodereleases.com](https://xcodereleases.com/) — Verified Xcode 26.3 as current stable (2026-02-26), Swift 6.2.4 bundled. HIGH confidence.
- [Apple Developer: callAsyncJavaScript](https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript) — iOS 14+ availability. HIGH confidence.
- [Apple Developer: WKNavigationDelegate](https://developer.apple.com/documentation/webkit/wknavigationdelegate) — `didFinishNavigation` signature. HIGH confidence.
- [Apple Developer: Adopting Swift 6](https://developer.apple.com/documentation/swift/adoptingswift6) — `@MainActor` annotation strategy for WKWebView delegates. HIGH confidence.
- [Swift Senpai: Web View JavaScript Injection](https://swiftsenpai.com/development/web-view-javascript-injection/) — `WKUserScript` pattern, `.atDocumentEnd` timing. MEDIUM confidence (community blog, verified against Apple docs).
- [DEV Community: WWDC 2025 WebKit for SwiftUI](https://dev.to/arshtechpro/wwdc-2025-webkit-for-swiftui-2igc) — Native SwiftUI WebView requires iOS 26+. MEDIUM confidence.
- [DEV Community: How iOS Sideloading Works in 2025](https://dev.to/1_king_0b1e1f8bfe6d1/how-ios-sideloading-actually-works-in-2025-dev-certs-altstore-and-the-eu-exception-1m2h) — Free account limits (7-day expiry, 3 apps). MEDIUM confidence.
- [Apple: Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/?id=02212025a) — Xcode 16/iOS 18 SDK requirement for App Store (not applicable here, sideload only). HIGH confidence.

---

*Stack research for: Panda Express Feedback Automator — iOS App (native WKWebView automation)*
*Researched: 2026-03-18*
