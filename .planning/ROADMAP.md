# Roadmap: Panda Express Feedback Automator — iOS App

## Overview

Three phases that build bottom-up: a validated Xcode project with the SwiftUI form shell and hidden WKWebView infrastructure (Phase 1), the full JavaScript automation engine that drives the survey form end-to-end (Phase 2), and a polished feedback layer with real-time logging and clear success/error reporting (Phase 3). Each phase ends with something the user can verify on a real iPhone before the next phase begins.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Xcode project, SwiftUI form UI, hidden WKWebView scaffolding, and app branding (completed 2026-03-18)
- [ ] **Phase 2: Automation Engine** - Full JavaScript automation port driving the Panda Express survey form end-to-end
- [ ] **Phase 3: Feedback & Logging** - Real-time log view, error surfacing, and completion state reporting

## Phase Details

### Phase 1: Foundation
**Goal**: A buildable, sideloadable iOS app with the complete SwiftUI form UI, a hidden WKWebView that loads pandaexpress.com/feedback, and anti-detection configured — ready to accept automation logic
**Depends on**: Nothing (first phase)
**Requirements**: FORM-01, FORM-02, FORM-03, FORM-04, AUTO-01, AUTO-02, DESIGN-01, DEPLOY-01
**Success Criteria** (what must be TRUE):
  1. User can enter a 24-character survey code via a segmented input (6 groups of 4) and see validation reject incomplete codes
  2. User can enter an email address that is pre-filled from the previous session on next launch
  3. The Run button is disabled when inputs are invalid or automation is active; inputs are locked during a run
  4. The app builds in Xcode and installs to a real iPhone via sideloading with no signing errors
  5. The hidden WKWebView loads pandaexpress.com/feedback with a clean Mobile Safari user agent (no bundle name leakage) and the navigator.webdriver override injected before any page request
**Plans**: 3 plans
Plans:
- [ ] 01-00-PLAN.md — XCTest target and 6 unit test stub files (Wave 0 prerequisite)
- [ ] 01-01-PLAN.md — AutomationEngine with hidden WKWebView and anti-detection, ViewModel with validation and state, test implementations
- [ ] 01-02-PLAN.md — SwiftUI form UI, panda branding, asset catalog, and human verification checkpoint

### Phase 2: Automation Engine
**Goal**: The app runs the complete Panda Express feedback survey from code entry to thank-you page, with correct handling of every form element type — replicating script.py behavior entirely
**Depends on**: Phase 1
**Requirements**: AUTO-03, AUTO-04, AUTO-05, AUTO-06, AUTO-07, AUTO-08, AUTO-09, AUTO-10, AUTO-11
**Success Criteria** (what must be TRUE):
  1. User enters a valid survey code and email, taps Run, and the app navigates through all survey pages without manual intervention
  2. Every radio question receives the first option ("Highly Satisfied") selected; every Yes/No question receives "No"
  3. Checkbox pages have the first 2 options checked; textarea fields are filled with positive feedback text; email fields receive the user's email
  4. The app detects the thank-you page and stops automatically, without continuing to navigate beyond completion
  5. Random 0.5-1.5s delays are applied between actions so the form is not driven at machine speed
**Plans**: 3 plans
Plans:
- [ ] 02-00-PLAN.md — Wave 0 test scaffolds (AutomationFlowTests, JSSnippetTests, NavigationWaitTests)
- [ ] 02-01-PLAN.md — JSSnippets.swift and PageHandler.swift (JS constants + page classification types)
- [ ] 02-02-PLAN.md — AutomationEngine async run() loop, ViewModel wiring, and human verification

### Phase 3: Feedback & Logging
**Goal**: The user can observe every action the automation takes in real time and knows clearly whether the survey completed successfully or failed with a specific reason
**Depends on**: Phase 2
**Requirements**: LOG-01, LOG-02, LOG-03
**Success Criteria** (what must be TRUE):
  1. A scrolling log view updates in real time during automation, showing each action (page number, element found, action taken) as it happens
  2. Network failures, JavaScript errors, and element-not-found conditions appear as clearly labeled error lines in the log — not as silent hangs
  3. When automation finishes, the user sees an unambiguous success message (survey complete) or failure message (what went wrong) without reading through all log lines
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 4/4 | Complete   | 2026-03-21 |
| 2. Automation Engine | 0/3 | Planning complete | - |
| 3. Feedback & Logging | 0/TBD | Not started | - |
