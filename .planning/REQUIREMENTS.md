# Requirements: Panda Express Feedback Automator — iOS App

**Defined:** 2026-03-18
**Core Value:** Reliably automate the entire Panda Express feedback form from start to finish on the user's iPhone, using their own network connection.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Form UI

- [ ] **FORM-01**: User can enter 24-character survey code via segmented input (6 groups of 4)
- [ ] **FORM-02**: User can enter email address, pre-filled from last use (@AppStorage)
- [ ] **FORM-03**: App validates code length (24 chars) and email format before running
- [ ] **FORM-04**: Inputs and Run button are disabled while automation is active

### Automation Engine

- [ ] **AUTO-01**: App creates a hidden WKWebView attached to the window hierarchy
- [ ] **AUTO-02**: App injects anti-detection (navigator.webdriver override at documentStart, clean Mobile Safari user agent)
- [ ] **AUTO-03**: App navigates to pandaexpress.com/feedback and enters survey code chunks
- [ ] **AUTO-04**: App selects first radio option ("Highly Satisfied") for all rating questions
- [ ] **AUTO-05**: App selects "No" for single Yes/No radio questions to minimize form
- [ ] **AUTO-06**: App checks first 2 checkboxes on checkbox pages
- [ ] **AUTO-07**: App fills textareas with positive feedback text
- [ ] **AUTO-08**: App fills text inputs with user's email on email pages
- [ ] **AUTO-09**: App clicks Next button and waits for page load between pages
- [ ] **AUTO-10**: App detects completion (thank-you page) and stops
- [ ] **AUTO-11**: App adds random 0.5-1.5s delays between actions

### Feedback & Logging

- [ ] **LOG-01**: App shows real-time scrolling log of automation actions
- [ ] **LOG-02**: App surfaces errors (network, JS, element-not-found) clearly in the log
- [ ] **LOG-03**: App shows clear success or failure message when automation finishes

### Visual Design

- [ ] **DESIGN-01**: App uses dark theme with Panda Express branding matching current web UI

### Deployment

- [ ] **DEPLOY-01**: App is buildable and installable via Xcode sideloading to iPhone

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Feedback Enhancements

- **LOG-04**: Log lines include HH:mm:ss timestamps
- **LOG-05**: Page progress indicator ("Page 3 of ~15") during automation

### Configuration

- **CONFIG-01**: Configurable feedback text (currently hardcoded)
- **CONFIG-02**: Re-sign workflow documentation or automation for 7-day sideload expiry

## Out of Scope

| Feature | Reason |
|---------|--------|
| App Store / TestFlight distribution | Personal project; automation apps routinely rejected under guideline 4.2 |
| iPad / Mac support | iPhone-only use case; doubles UI testing surface |
| Visible WKWebView | Risk of accidental taps breaking automation; log view provides all needed info |
| Submission history / database | Codes are single-use; no recurring value from tracking past submissions |
| Multiple concurrent surveys | WKWebView memory pressure + race conditions; one-at-a-time is correct |
| Push / local notifications | User watches log in real-time; adds permission prompt complexity |
| Retry logic | Masks real errors that need human attention; wastes survey codes |
| Settings screen | One-screen app; hardcoded values are fine for personal use |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FORM-01 | — | Pending |
| FORM-02 | — | Pending |
| FORM-03 | — | Pending |
| FORM-04 | — | Pending |
| AUTO-01 | — | Pending |
| AUTO-02 | — | Pending |
| AUTO-03 | — | Pending |
| AUTO-04 | — | Pending |
| AUTO-05 | — | Pending |
| AUTO-06 | — | Pending |
| AUTO-07 | — | Pending |
| AUTO-08 | — | Pending |
| AUTO-09 | — | Pending |
| AUTO-10 | — | Pending |
| AUTO-11 | — | Pending |
| LOG-01 | — | Pending |
| LOG-02 | — | Pending |
| LOG-03 | — | Pending |
| DESIGN-01 | — | Pending |
| DEPLOY-01 | — | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 0
- Unmapped: 20 ⚠️

---
*Requirements defined: 2026-03-18*
*Last updated: 2026-03-18 after initial definition*
