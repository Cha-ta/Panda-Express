# Phase 1: Foundation - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Xcode project with SwiftUI form UI, hidden WKWebView that loads pandaexpress.com/feedback, anti-detection configured, and Panda branding. Ready to accept automation logic in Phase 2. No automation JS in this phase — just the shell.

</domain>

<decisions>
## Implementation Decisions

### Visual Style — Light Mode
- Light mode with green accents (NOT dark like the web UI)
- Use iOS system green (`Color.green`) as the accent color
- All SF Pro font — no custom fonts, fully native iOS feel
- Panda image (pandaEating.png) as a subtle faded background/watermark behind the form, very light opacity
- Panda image also used as the app icon on the home screen

### Form Styling
- iOS-style grouped form sections (like Settings app) — most native approach
- Filled green Run button with white text — solid primary action
- "Show logs" toggle lives inside the form area (not in nav bar), near the other form elements

### App Title & Nav
- Navigation bar title: "Panda" (shortened from "Panda Survey")
- Subtitle can appear in the form section area

### Code Input
- Single text field for the full 24-character code (NOT 6 separate fields)
- Auto-inserts dashes every 4 characters as user types (display: `1234-5678-9012-3456-7890-1234`)
- Full default keyboard (codes may contain letters)
- Strips dashes internally before passing to automation

### Email Input
- Single email text field with email keyboard
- Persisted via @AppStorage — pre-filled on next launch

### Layout & Log Area
- Single-screen app, no navigation stack
- Form at top: code input, email input, Run button, Show logs toggle
- "Show logs" checkbox toggle — when checked, a scrollable log box appears below the form
- Log box takes bottom half of screen when visible
- Log box scrolls independently — scrolling logs does not scroll the main view
- When logs hidden, form is the only visible content

### Claude's Discretion
- Exact panda watermark opacity and positioning
- Grouped form section labels and dividers
- Status indicator design (spinner, checkmark on completion)
- Exact spacing and padding values
- How the "Show logs" toggle looks (checkbox, switch, or SF Symbol)

</decisions>

<specifics>
## Specific Ideas

- Title is just "Panda" in the nav bar — short and clean
- Code input auto-formats with dashes like a credit card field: `1234-5678-9012-3456-7890-1234`
- The log box is a contained scrollable area that doesn't affect the rest of the view — similar to a terminal output box
- Light/green palette is a deliberate departure from the dark web UI — should feel fresh and iOS-native

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pandaEating.png` (2.1MB): Use for both app icon and subtle background watermark
- `index.html` CSS variables: Reference for green accent values, though switching from dark to light mode

### Established Patterns
- Web UI: 6 separate code input fields with auto-advance — iOS version consolidates to single field with dash formatting
- Web UI: DM Mono + Syne fonts — iOS version uses all SF Pro (native)

### Integration Points
- WKWebView will be hidden (zero-frame or off-screen) — no visible browser UI
- Log area (Phase 3) will plug into the log box area defined in this phase's layout

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-18*
