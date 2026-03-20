# Phase 1: Foundation - Context

**Gathered:** 2026-03-20 (updated from 2026-03-18)
**Status:** Ready for planning

<domain>
## Phase Boundary

Xcode project with SwiftUI form UI, hidden WKWebView that loads pandaexpress.com/feedback, anti-detection configured, and Panda branding. Ready to accept automation logic in Phase 2. No automation JS in this phase — just the shell.

</domain>

<decisions>
## Implementation Decisions

### Orientation
- **Portrait only** — lock the app to portrait orientation in Xcode project settings (no landscape support)
- Portrait is the primary and only design target

### Background / Wallpaper
- `pandaEating.png` fills the entire screen edge-to-edge as a wallpaper (`scaledToFill`, `ignoresSafeArea`)
- Opacity: ~0.18 — present but not distracting
- `scrollContentBackground(.hidden)` removes the Form's opaque scroll background so panda is visible through the gaps between sections

### Form Cell Style
- Section cells (white boxes containing text fields) are **fully opaque** — solid white
- Panda wallpaper shows through the **gray gaps between sections** only (default iOS grouped form gap color)
- Section header labels stay **default iOS gray** — no green tint on headers

### Input Borders
- Each TextField has a visible **green rounded border** (`Color.green.opacity(0.6)`, cornerRadius 6, lineWidth 1.5)
- Border is **static** — does not change on focus/tap
- Border **grays out** when the field is disabled (automation is running)
- Border turns **red** when the field has partial but invalid content (e.g., survey code partially typed but not yet valid)

### Form Layout (Portrait-First)
- The Form is a **scrollable view** — user can scroll to reach the Run button and Show Logs toggle if keyboard or log box pushes content down
- No forced height constraints on the Form — it fills available space and scrolls naturally
- All three sections (Survey Code, Email, Run+Toggle) must be reachable in portrait without going to landscape

### Survey Code Input
- Single text field for the full 24-character code (NOT 6 separate fields)
- Auto-inserts dashes every 4 characters as user types: `1234-5678-9012-3456-7890-1234`
- Full default keyboard (codes may contain letters)
- Strips dashes internally before passing to automation

### Email Input
- Single email text field with email keyboard
- Persisted via UserDefaults — pre-filled on next launch

### Log Box
- **Light style** — matches the form (light/secondary system background, dark text)
- Fixed height: **160pt** (~8 lines visible at once)
- Rounded border (thin separator stroke, cornerRadius 8)
- Monospace caption font
- **Color-coded log lines:** errors → red, success/completion → green, normal steps → default text color
- Auto-scrolls to latest entry
- Appears below the form when "Show Logs" toggle is on; collapses completely when off

### Run Button & Show Logs Toggle
- Run button: filled green with white text (`.borderedProminent`, `.tint(.green)`)
- Run button disabled when inputs are invalid or automation is running
- "Show Logs" toggle lives inside the form section alongside the Run button
- During automation: Run button replaced by a spinner + "Running..." text

### App Title & Nav
- Navigation bar title: "Panda"
- `.tint(.green)` throughout

### Claude's Discretion
- Exact padding/spacing values
- Precise red/gray border opacity values for disabled/invalid states
- Status indicator design details (spinner style)

</decisions>

<specifics>
## Specific Ideas

- Code input auto-formats like a credit card field: `1234-5678-9012-3456-7890-1234`
- Log box should feel like a contained output area — compact, scrollable, never takes over the screen
- The wallpaper shows through the gray gaps between form sections — panda is present but doesn't compete with text readability
- Portrait is the ONLY orientation — lock it in project settings so the app never rotates

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pandaEating.png`: Used for app icon and full-screen wallpaper background
- `AutomationViewModel`: `@Published isRunning`, `isValid`, `showLogs`, `logMessages`, `surveyCode`, `email` — all UI state centralized here

### Established Patterns
- `ObservableObject` + `@Published` for all state (iOS 16 target — no `@Observable`)
- `onChange` with single-param closure (iOS 16 compatible — NOT two-param form)
- `UserDefaults` for email persistence (not `@AppStorage`)
- `scrollContentBackground(.hidden)` on Form for transparent scroll background

### Integration Points
- Log box plugs into `viewModel.logMessages` — array already exists
- WKWebView is hidden (zero-frame) and does not appear in SwiftUI view hierarchy
- `viewModel.isRunning` gates both UI disabled states and border color logic

### Known Issues to Fix
- Form is cut off at bottom in portrait mode — needs `.frame(maxHeight: .infinity)` on the Form or its container to fill available space within NavigationStack
- Orientation lock must be set in Xcode project settings (target deployment info), not in SwiftUI code
- Input border color states (red for invalid, gray for disabled) not yet implemented — static green only

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context updated: 2026-03-20*
