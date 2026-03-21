# Quick Task 1: Create iPhone sideloading README - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Task Boundary

Create a beginner-friendly INSTALL.md at the repo root with step-by-step instructions for sideloading the PandaAutomator app onto an iPhone via Xcode.

</domain>

<decisions>
## Implementation Decisions

### File Placement
- Create a new `INSTALL.md` at the repo root (not inside PandaAutomator/ folder)
- Separate from any future project README

### Audience & Tone
- Beginner-friendly: assumes no prior Xcode experience
- Explicit menu paths and step-by-step numbered instructions
- Clear section headings for each major phase (prerequisites, Xcode setup, device setup, install, verify)

### Troubleshooting
- Include a troubleshooting section covering common issues:
  - "Untrusted Developer" error and how to resolve via Settings
  - Device not appearing in Xcode simulator list
  - Provisioning profile / signing errors
  - App crashes on launch

### Content — User-Provided Steps (locked)
The core steps from the user (must appear in the guide):
1. Open the `.xcodeproj` in Xcode
2. Click PandaAutomator under Targets
3. Go to Signing & Capabilities
4. Check "Automatically manage signing"
5. Set Team from [none] to your account
6. Sign in with Apple ID for development certificate
7. Plug iPhone into MacBook, trust the device
8. Select your iPhone as the run destination (not a simulator)
9. Click Run
10. On iPhone: Settings → General → VPN & Device Management → verify/trust the app
11. Run again from Xcode
12. Wait for install to complete, disconnect iPhone
13. Done — app is installed

### Claude's Discretion
- Exact markdown formatting and section structure
- Whether to add a "Prerequisites" section (Xcode version, macOS version, Apple ID)
- Whether to mention free vs paid Apple Developer account limitations (7-day re-signing)

</decisions>

<specifics>
## Specific Ideas

- User explicitly listed the sideloading steps — these are the canonical steps to document
- Branch context: this is on `panda-automator-Iphone` branch

</specifics>
