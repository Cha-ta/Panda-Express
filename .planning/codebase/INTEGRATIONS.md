# External Integrations

**Analysis Date:** 2026-03-18

## APIs & External Services

**Survey Platform:**
- Panda Express Feedback Form - Target website for survey automation
  - URL: `https://pandaexpress.com/feedback`
  - Method: Automated form submission via Playwright browser automation
  - Integration location: `script.py` line 22

**Email Delivery:**
- Not detected - Coupon codes are automatically emailed by Panda Express after survey completion; no outbound email integration from this application

## Data Storage

**Databases:**
- Not detected - No database integration; application is stateless

**File Storage:**
- Local filesystem only
  - Static assets served from project root: `pandaEating.png` (background image)
  - HTML template served directly from filesystem: `index.html`
  - Error screenshots optionally saved locally: `error_screenshot.png` (line 258 in `script.py`)

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None - Application is public with no user authentication

**Survey Code Validation:**
- Client-side validation only (24-character code check in `app.py` line 27)
- Code passed directly to automation script as CLI argument

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- Console logging only via print statements
- Captured from subprocess execution: `script.py` stdout/stderr logged in `app.py` lines 41-44
- Error screenshots saved to project root on automation failure

## CI/CD & Deployment

**Hosting:**
- Render platform

**Deployment Configuration:**
- `render.yaml` defines web service named "form-automator"
- Build: Python dependencies installed via pip, Playwright Chromium browser installed
- Start: Gunicorn WSGI server

## Environment Configuration

**Required env vars (Development):**
- `PORT` - HTTP server port (optional, defaults to 5000)

**Required env vars (Render Production):**
- `PYTHON_VERSION` - Set to 3.11.0
- `PLAYWRIGHT_BROWSERS_PATH` - Set to `/opt/render/project/src/.playwright` for browser cache

**Secrets location:**
- Not detected - No API keys, database credentials, or secrets required
- Application requires no secret configuration

## Webhooks & Callbacks

**Incoming:**
- `POST /run` endpoint in `app.py` - Receives JSON form submission with email and code
  - Payload: `{"email": "string", "code": "string"}`
  - Returns: `{"status": "success|error", "message": "string"}`

**Outgoing:**
- None - Application does not make outbound API calls beyond HTTP form submission to pandaexpress.com

## External Library Requirements

**Playwright:**
- SDK: `playwright` Python package (requirement in `requirements.txt`)
- Browser: Chromium (installed via `python -m playwright install chromium`)
- Version: Latest (specified in requirements.txt without version pin)

---

*Integration audit: 2026-03-18*
