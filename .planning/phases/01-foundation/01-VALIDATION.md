---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-18
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Xcode XCTest (built-in) |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `xcodebuild test -scheme PandaSurvey -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme PandaSurvey -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick build check (`xcodebuild build`)
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | FORM-01 | unit | code formatting test | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | FORM-02 | unit | @AppStorage persistence test | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | FORM-03 | unit | validation logic test | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | FORM-04 | unit | isRunning state test | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | AUTO-01 | manual | WKWebView loads in Simulator | N/A | ⬜ pending |
| TBD | 01 | 1 | AUTO-02 | manual | Check UA and webdriver override | N/A | ⬜ pending |
| TBD | 01 | 1 | DESIGN-01 | manual | Visual inspection of light theme | N/A | ⬜ pending |
| TBD | 01 | 1 | DEPLOY-01 | manual | Sideload to real iPhone | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Xcode project with XCTest target
- [ ] Test stubs for FORM-01 through FORM-04

*WKWebView, design, and deployment requirements are manual-only.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hidden WKWebView loads URL | AUTO-01 | Requires live network + WKWebView runtime | Run app in Simulator, verify console log of page load |
| Anti-detection configured | AUTO-02 | Requires inspecting WKWebView UA at runtime | Run app, evaluateJavaScript to check navigator.webdriver and navigator.userAgent |
| Light theme with green accent | DESIGN-01 | Visual inspection | Screenshot comparison against design spec |
| Sideload to iPhone | DEPLOY-01 | Requires physical device | Build in Xcode, install to connected iPhone |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
