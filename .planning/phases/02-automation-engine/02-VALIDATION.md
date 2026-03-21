---
phase: 02
slug: automation-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode-bundled) |
| **Config file** | PandaAutomator.xcodeproj (test target: PandaAutomatorTests) |
| **Quick run command** | `xcodebuild test -project PandaAutomator/PandaAutomator.xcodeproj -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PandaAutomatorTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project PandaAutomator/PandaAutomator.xcodeproj -scheme PandaAutomator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -30` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (unit tests only)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-00-01 | 00 | 0 | ALL | scaffold | `xcodebuild test ...` | ❌ W0 | ⬜ pending |
| 02-01-01 | 01 | 1 | AUTO-03 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/AutomationFlowTests` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | AUTO-04, AUTO-05 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/AutomationFlowTests` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 1 | AUTO-06, AUTO-07, AUTO-08 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/AutomationFlowTests` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 1 | AUTO-09 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/JSSnippetTests` | ❌ W0 | ⬜ pending |
| 02-01-05 | 01 | 1 | AUTO-10 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/AutomationFlowTests` | ❌ W0 | ⬜ pending |
| 02-01-06 | 01 | 1 | AUTO-11 | unit | `xcodebuild test ... -only-testing:PandaAutomatorTests/AutomationFlowTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `PandaAutomatorTests/AutomationFlowTests.swift` — covers AUTO-03 through AUTO-11 page handler dispatch logic
- [ ] `PandaAutomatorTests/JSSnippetTests.swift` — covers JS string correctness (element detection, click, fill)
- [ ] `PandaAutomatorTests/NavigationWaitTests.swift` — covers AUTO-09 continuation timeout behavior

*Note: Full integration testing requires a live survey code (single-use). Unit tests validate JS snippet correctness and page-type dispatch logic using mock data. Integration testing must be manual with a real receipt code.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full survey completion | ALL | Requires live single-use survey code | Enter valid code, tap Run, observe survey completes to thank-you page |
| Anti-detection evasion | AUTO-02 | Cannot detect bot detection locally | Verify no CAPTCHA or block pages appear during run |
| Random delay feel | AUTO-11 | Timing perception is subjective | Observe actions have visible human-like pacing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
