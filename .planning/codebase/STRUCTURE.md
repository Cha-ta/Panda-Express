# Codebase Structure

**Analysis Date:** 2026-03-18

## Directory Layout

```
Panda-Express/
├── app.py                    # Flask web server and API routes
├── script.py                 # Playwright automation script (subprocess runner)
├── index.html                # Frontend UI (single page application)
├── pandaEating.png           # Background image asset
├── requirements.txt          # Python dependencies (Flask, Playwright, Gunicorn)
├── render.yaml               # Render.com deployment configuration
├── .python-version           # Python version pinning (3.11.0)
├── README.md                 # Project documentation
├── .git/                     # Git repository metadata
└── .planning/
    └── codebase/             # Analysis documents directory
```

## Directory Purposes

**Project Root:**
- Purpose: Container for all application files and configuration
- Contains: Python application code, frontend assets, deployment config, dependency manifests
- Key files: `app.py`, `script.py`, `index.html`

**.planning/codebase/:**
- Purpose: Store architecture and codebase analysis documents
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md
- Generated: Yes
- Committed: Yes (documentation, not application code)

## Key File Locations

**Entry Points:**
- `app.py`: Web server entry point; Flask application initialization and route handlers
- `script.py`: Automation script entry point; executed as subprocess with CLI arguments
- `index.html`: Frontend entry point; served as static HTML by Flask

**Configuration:**
- `requirements.txt`: Python package dependencies
- `render.yaml`: Production deployment configuration (build and start commands)
- `.python-version`: Python version specification for runtime

**Core Logic:**
- `app.py`: HTTP server logic and subprocess orchestration (54 lines)
- `script.py`: Browser automation and form filling logic (262 lines)

**Assets:**
- `pandaEating.png`: Background image for web UI (2.1 MB)

**Documentation:**
- `README.md`: Project overview and usage instructions

## Naming Conventions

**Files:**
- Python modules: lowercase with underscores (`app.py`, `script.py`)
- HTML/Assets: lowercase with underscores or hyphens (`index.html`, `pandaEating.png`)
- Configuration: dotfiles for version/environment (`.python-version`, `.env` [if used])

**Functions:**
- Utility functions: snake_case, descriptive names indicating purpose
  - Example: `get_page_elements()`, `click_all_radios_first_option()`, `fill_all_text_inputs()`
- Variables: snake_case, descriptive names
  - Example: `email`, `code`, `chunks`, `page_num`, `radio_names`
- Constants: UPPERCASE with underscores
  - Example: `FORM_URL`

**Routes:**
- Web endpoints: leading slash, lowercase, descriptive path
  - Example: `/`, `/run`, `/images/<filename>`

## Where to Add New Code

**New Feature (e.g., additional automation step):**
- Primary code: `script.py` - add new helper function for page interaction
- Tests: None currently established (see TESTING.md)
- Example location: Add new function after line 165, before the main automation loop (lines 166-261)

**New Route/Endpoint:**
- Implementation: `app.py` - add new `@app.route()` function
- Location: After line 18, before the `/run` route (line 20)
- Pattern: Follow existing route pattern with `@app.route()` decorator and function definition

**New Helper/Utility Function:**
- Automation helpers: `script.py` (lines 6-164 contain all helper functions)
- Flask utilities: `app.py` (currently no separate utility file; add functions before routes if needed)

**User Interface Changes:**
- HTML/CSS: `index.html` - modify or extend the form structure
- JavaScript: `index.html` `<script>` section (embedded in same file)
- Assets: Place new images in project root, reference via `/images/<filename>` route

**Configuration:**
- Environment variables: Add to `render.yaml` under `envVars` section
- New dependencies: Add package name to `requirements.txt`
- Python version: Update `.python-version` file if needed

## Special Directories

**.git/:**
- Purpose: Git version control repository
- Generated: Yes
- Committed: N/A (git metadata)

**.planning/codebase/:**
- Purpose: Documentation directory for architecture analysis
- Generated: Yes (by GSD mapping commands)
- Committed: Yes (markdown documents)

## File Interdependencies

**app.py Dependencies:**
- `index.html` (loaded at line 10 as string, served at line 14)
- `script.py` (invoked via subprocess at line 35)
- `pandaEating.png` (referenced in index.html, served via line 17-18 route)

**script.py Dependencies:**
- External: Playwright library, Chromium browser
- No local file dependencies

**index.html Dependencies:**
- `pandaEating.png` (background image at line 24)
- `app.py` routes: `/` (page load), `/run` (form submission), `/images/pandaEating.png` (image)

---

*Structure analysis: 2026-03-18*
