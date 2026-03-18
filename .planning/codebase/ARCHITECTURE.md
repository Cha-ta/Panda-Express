# Architecture

**Analysis Date:** 2026-03-18

## Pattern Overview

**Overall:** Two-tier client-server with subprocess orchestration

**Key Characteristics:**
- HTTP web server (Flask) serving form UI and coordinating automation requests
- Asynchronous subprocess execution using Python threading
- Browser automation via Playwright for form completion
- Stateless request handling with no persistent state between submissions
- Single-page HTML served directly by Flask

## Layers

**Presentation Layer:**
- Purpose: Provide user interface for form submission
- Location: `index.html`
- Contains: HTML structure, CSS styling, JavaScript event handling
- Depends on: Flask `/` and `/images/` routes
- Used by: End users accessing web application

**API/Request Handler Layer:**
- Purpose: Accept form submissions and coordinate automation execution
- Location: `app.py` routes (lines 20-50)
- Contains: Flask route handlers (`/run` POST endpoint), request validation, subprocess invocation
- Depends on: Flask framework, Python subprocess module, threading module
- Used by: Frontend JavaScript making AJAX requests

**Automation Execution Layer:**
- Purpose: Execute browser automation workflow against Panda Express feedback form
- Location: `script.py`
- Contains: Playwright browser control, form element detection via JavaScript injection, intelligent form filling logic
- Depends on: Playwright sync API, argparse for CLI arguments
- Used by: Flask app.py via subprocess

**Browser Control Sub-layer:**
- Purpose: Manage headless Chromium browser and page interactions
- Location: `script.py` (lines 166-179)
- Contains: Browser launch configuration, context creation, anti-detection measures
- Depends on: Playwright sync_playwright API
- Used by: Page automation logic

## Data Flow

**Form Submission Flow:**

1. User enters email and 24-character code in index.html form
2. JavaScript validates inputs client-side
3. AJAX POST request sent to `/run` endpoint with JSON payload
4. Flask handler (`run_form()`) validates email format and code length
5. If valid, subprocess spawned in daemon thread running `script.py`
6. Script receives email and code as CLI arguments
7. Script launches headless browser and navigates to form URL
8. Browser automation proceeds through multi-page form, filling fields
9. Responses sent immediately to client (success/error)
10. Automation continues in background; client receives no real-time updates

**State Management:**
- No session state maintained between requests
- No in-memory cache of form state
- Each automation run is independent
- Email and code passed as command-line arguments (no CSV file conflicts)

## Key Abstractions

**Form Element Detection:**
- Purpose: Dynamically identify form structure and field types on current page
- Examples: `get_page_elements()` (lines 24-51)
- Pattern: JavaScript injection via `page.evaluate()` to query DOM and return structured metadata about radio groups, checkboxes, text inputs, textareas

**Page Navigation Pattern:**
- Purpose: Advance through multi-page form with flexible button detection
- Examples: `click_next()` (lines 130-143)
- Pattern: Try multiple selector strategies until button found; wait for network idle state before continuing

**Field Filling Strategies:**
- Purpose: Apply context-aware filling logic based on form state
- Examples: `click_all_radios_first_option()` (lines 53-77), `fill_all_text_inputs()` (lines 96-111), `fill_all_textareas()` (lines 113-128)
- Pattern: Query page for elements by type, iterate through collection, fill with appropriate values

**Completion Detection:**
- Purpose: Recognize when form is successfully submitted
- Examples: `is_finish_page()` (lines 145-164)
- Pattern: Check for absence of Next button AND presence of completion indicators in page text

## Entry Points

**Web Application Entry:**
- Location: `app.py` (lines 52-54)
- Triggers: Application startup (gunicorn invokes `app:app`)
- Responsibilities: Initialize Flask app, bind to port from environment variable, start HTTP server

**Form Page Request:**
- Location: `app.py` `/` route (lines 12-14)
- Triggers: GET request to root path
- Responsibilities: Load and serve `index.html` as plain HTML response

**Form Submission Trigger:**
- Location: `app.py` `/run` POST route (lines 20-50)
- Triggers: AJAX POST from frontend with email and code
- Responsibilities: Validate inputs, spawn background thread, return immediate response

**Automation Script Entry:**
- Location: `script.py` (lines 1-14)
- Triggers: Subprocess invocation with `--email` and `--code` arguments
- Responsibilities: Parse CLI arguments, initialize browser, execute form automation loop

## Error Handling

**Strategy:** Try-catch with screenshot fallback and subprocess stderr capture

**Patterns:**
- Flask validation returns JSON error responses with descriptive messages (lines 27-30)
- Script.py wraps entire automation in try-except block (lines 183-259)
- On script error, saves browser screenshot to `error_screenshot.png` for debugging
- Flask subprocess captures stdout and stderr, logs to console for server-side debugging
- No retry logic; failed automation simply stops at current page

## Cross-Cutting Concerns

**Logging:** Console print statements throughout script.py showing page numbers, elements found, actions taken; Flask app prints subprocess exit codes and output

**Validation:** Email format check and fixed code length requirement (24 characters) in Flask handler

**Anti-Detection:** Headless browser launched with flags to disable automation detection, custom user agent spoofing, webdriver property override via context script injection (lines 167-178)

---

*Architecture analysis: 2026-03-18*
