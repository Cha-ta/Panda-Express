---
phase: quick-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - INSTALL.md
autonomous: true
requirements: [QUICK-1]
must_haves:
  truths:
    - "A beginner with no Xcode experience can follow INSTALL.md end-to-end to sideload the app"
    - "All 13 user-provided steps appear in numbered order"
    - "Troubleshooting section covers Untrusted Developer, device not appearing, signing errors, and crash on launch"
  artifacts:
    - path: "INSTALL.md"
      provides: "Complete sideloading guide"
      contains: "Signing & Capabilities"
  key_links: []
---

<objective>
Create a beginner-friendly INSTALL.md at the repo root with step-by-step iPhone sideloading instructions via Xcode, including prerequisites, the user's exact 13-step process, and a troubleshooting section.

Purpose: Users with zero Xcode experience need a single document to get PandaAutomator running on their iPhone.
Output: INSTALL.md at repo root.
</objective>

<execution_context>
@/Users/danielvillasenor/.claude/get-shit-done/workflows/execute-plan.md
@/Users/danielvillasenor/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/1-create-iphone-sideloading-readme-with-st/1-CONTEXT.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write INSTALL.md with sideloading guide</name>
  <files>INSTALL.md</files>
  <action>
Create INSTALL.md at the repo root with the following structure:

**Title:** "Installing PandaAutomator on Your iPhone"

**Section 1 — Prerequisites:**
- A Mac running macOS 13 Ventura or later
- Xcode 15 or later (free from the Mac App Store) — mention it is a large download
- An Apple ID (free accounts work, but note the 7-day re-signing limitation: the app expires after 7 days and must be re-installed from Xcode)
- An iPhone with a Lightning or USB-C cable
- This repository cloned or downloaded to your Mac

**Section 2 — Step-by-Step Installation:**
Number every step exactly. These are the user's locked canonical steps — include all 13 in order with beginner-friendly elaboration:

1. Open `PandaAutomator/PandaAutomator.xcodeproj` in Xcode (double-click the file in Finder or use File > Open in Xcode)
2. In the left sidebar (Project Navigator), click **PandaAutomator** under **Targets** (not the top-level project)
3. Select the **Signing & Capabilities** tab at the top of the editor
4. Check the **Automatically manage signing** checkbox
5. In the **Team** dropdown, change from `[None]` to your Apple ID account. If your Apple ID does not appear, proceed to step 6
6. If prompted, sign in with your Apple ID — Xcode will create a free development certificate automatically
7. Plug your iPhone into your Mac with a cable. If the iPhone shows a "Trust This Computer?" dialog, tap **Trust** and enter your passcode
8. In the Xcode toolbar at the top, click the device/simulator selector (it may say "Any iOS Device" or a simulator name) and choose your iPhone from the list
9. Click the **Run** button (the play triangle) or press Cmd+R
10. On your iPhone, the install may fail the first time with an "Untrusted Developer" error — this is normal. Go to **Settings > General > VPN & Device Management**, find the entry under "Developer App," and tap **Trust**
11. Back in Xcode, click **Run** again
12. Wait for the build and install to complete — the app will launch on your iPhone
13. You can now disconnect your iPhone. The app is installed and ready to use

**Section 3 — Troubleshooting:**
Use a table or subsection headings. Cover these issues:

- **"Untrusted Developer" error:** Reiterate step 10. Settings > General > VPN & Device Management > Trust.
- **iPhone not appearing in Xcode device list:** Ensure the cable supports data (not charge-only). Try a different port. Make sure you tapped "Trust" on the iPhone. Restart Xcode if needed.
- **Provisioning profile or signing errors:** Make sure "Automatically manage signing" is checked and a Team is selected. If using a free account, ensure the Bundle Identifier is unique — try changing it to something like `com.yourname.PandaAutomator`.
- **App crashes immediately on launch:** Try Clean Build Folder (Product > Clean Build Folder or Shift+Cmd+K), then Run again. Ensure the iPhone is running iOS 16.0 or later.
- **Free account 7-day expiry:** With a free Apple ID, the app expires after 7 days. Simply re-run from Xcode to reinstall.

**Formatting rules:**
- Use clear markdown headings (## for sections)
- Bold key UI elements (button names, menu paths)
- Keep paragraphs short — one concept per paragraph
- No emojis
  </action>
  <verify>
    <automated>test -f INSTALL.md && grep -q "Signing & Capabilities" INSTALL.md && grep -q "Untrusted Developer" INSTALL.md && grep -q "Troubleshooting" INSTALL.md && grep -c "^[0-9]" INSTALL.md | xargs test 10 -le && echo "PASS"</automated>
  </verify>
  <done>INSTALL.md exists at repo root with all 13 user-provided steps in numbered order, a prerequisites section, and a troubleshooting section covering all four required issues. A beginner could follow the guide without external help.</done>
</task>

</tasks>

<verification>
- INSTALL.md exists at repo root
- All 13 canonical steps present and numbered
- Prerequisites section mentions Xcode, macOS, Apple ID, 7-day limitation
- Troubleshooting covers: Untrusted Developer, device not appearing, signing errors, crash on launch
- No broken markdown formatting
</verification>

<success_criteria>
INSTALL.md is a complete, standalone sideloading guide that a user with zero Xcode experience can follow from start to finish.
</success_criteria>

<output>
After completion, create `.planning/quick/1-create-iphone-sideloading-readme-with-st/1-01-SUMMARY.md`
</output>
