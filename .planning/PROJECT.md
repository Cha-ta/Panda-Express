# Panda Express Feedback Automator — iOS App

## What This Is

A native iOS app that automates the Panda Express feedback survey. The user enters their 24-character survey code and email, and the app uses a hidden WKWebView to navigate through the multi-page feedback form — selecting ratings, filling fields, and submitting — all from the user's own device and IP address. Replaces the current Flask+Playwright web app that has deployment/proxy issues on hosted servers.

## Core Value

The app must reliably automate the entire Panda Express feedback form from start to finish on the user's iPhone, using their own network connection.

## Requirements

### Validated

- ✓ Survey code entry (24 characters, split into 6 chunks of 4) — existing
- ✓ Email entry for receiving validation code — existing
- ✓ Multi-page form navigation with Next button detection — existing
- ✓ Radio button auto-selection (first option / "Highly Satisfied") — existing
- ✓ Yes/No question handling (select "No" to minimize form) — existing
- ✓ Checkbox selection (first 2 options) — existing
- ✓ Textarea filling with positive feedback text — existing
- ✓ Text input filling (email on final pages) — existing
- ✓ Completion detection (thank you page) — existing
- ✓ Anti-detection measures (user agent spoofing, webdriver override) — existing

### Active

- [ ] Native iOS app with SwiftUI interface matching current web UI style (panda branding, dark theme)
- [ ] Hidden WKWebView that loads pandaexpress.com/feedback and automates the form via JavaScript injection
- [ ] Port all script.py automation logic to Swift/JavaScript (element detection, radio clicking, text filling, page navigation)
- [ ] Real-time log output showing detailed progress (page numbers, elements found, actions taken)
- [ ] Email persistence — save email to UserDefaults so user doesn't retype each time
- [ ] Error handling with clear error messages in the log view
- [ ] Deployable via Xcode directly to iPhone (sideloading, no App Store)

### Out of Scope

- App Store distribution — personal project, sideloading via Xcode is fine
- iPad / Mac support — iPhone only
- Multiple survey support — one survey at a time
- Backend server — everything runs on-device
- History of past submissions — no need to track past codes
- Push notifications — user watches the log in real-time

## Context

- The existing Python/Playwright solution works correctly when run locally but has issues on Render (likely IP blocking or Playwright browser issues on hosted infrastructure)
- The key advantage of an iOS app: runs from the user's own IP (WiFi or cellular data), which the Panda Express site is less likely to block
- WKWebView on iOS supports JavaScript injection via `WKUserContentController` and `evaluateJavaScript`, which maps well to Playwright's `page.evaluate()` pattern
- The form at pandaexpress.com/feedback is a multi-page survey with ~15 pages of radio buttons, checkboxes, text inputs, and textareas
- Sideloading via Xcode requires an Apple Developer account (free tier works but app expires after 7 days; paid $99/year account lasts 1 year)

## Constraints

- **Platform**: iOS / Swift / SwiftUI — must run natively on iPhone
- **Deployment**: Xcode sideloading only — no App Store, no TestFlight
- **No server**: All automation runs on-device via WKWebView + JS injection
- **Network**: Uses device's own IP (WiFi or cellular) — this is the whole point

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| WKWebView + JS injection over Playwright | Playwright can't run on iOS; WKWebView is the native equivalent for browser automation | — Pending |
| SwiftUI over UIKit | Modern iOS development, simpler for a straightforward form UI | — Pending |
| Sideload via Xcode over App Store | Personal project, avoids review process and $99 fee (if using free tier) | — Pending |
| Hidden web view (not visible) | User doesn't need to see the form, just the log output | — Pending |

---
*Last updated: 2026-03-18 after initialization*
