# Technology Stack

**Analysis Date:** 2026-03-18

## Languages

**Primary:**
- Python 3.11.0 - Backend API, automation scripts, and web server

## Runtime

**Environment:**
- Python 3.11.0

**Package Manager:**
- pip
- Lockfile: not present (uses requirements.txt only)

## Frameworks

**Core:**
- Flask - Web server framework for HTTP routing and request handling
- Playwright (sync API) - Browser automation for form filling and survey completion

**Build/Deployment:**
- Gunicorn - WSGI HTTP server for production deployment

## Key Dependencies

**Critical:**
- Flask - Web framework for handling form submissions and static file serving (`app.py`)
- Playwright - Browser automation library using Chromium for interacting with Panda Express feedback forms (`script.py`)
- Gunicorn - Production WSGI server specified in Render deployment configuration (`render.yaml`)

**Standard Library Only:**
- argparse - CLI argument parsing for survey code and email parameters
- threading - Background execution of automation scripts from Flask threads
- subprocess - Process management for running `script.py` from `app.py`
- os, sys, time, random - System utilities and timing

## Configuration

**Environment:**
- `PORT` - HTTP server port (defaults to 5000 if not set)
- `PLAYWRIGHT_BROWSERS_PATH` - Path to Playwright browser binaries for Render deployments
- `PYTHON_VERSION` - Explicitly set to 3.11.0 for Render

**Build:**
- `.python-version` - File pinning Python to 3.11.0 for build consistency
- `render.yaml` - Render deployment configuration with build/start commands

## Platform Requirements

**Development:**
- Python 3.11+
- pip for package management
- Playwright browsers must be installed: `python -m playwright install chromium`

**Production:**
- Render hosting platform
- Build command: `pip install -r requirements.txt && PLAYWRIGHT_BROWSERS_PATH=/opt/render/project/src/.playwright python -m playwright install chromium`
- Start command: `gunicorn app:app`
- Environment variables set in `render.yaml` for browser path and Python version

---

*Stack analysis: 2026-03-18*
