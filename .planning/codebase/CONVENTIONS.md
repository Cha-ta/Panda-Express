# Coding Conventions

**Analysis Date:** 2026-03-18

## Naming Patterns

**Files:**
- Python scripts: lowercase with underscores (`app.py`, `script.py`)
- HTML files: lowercase (`index.html`)
- Configuration: lowercase (`requirements.txt`, `render.yaml`)

**Functions:**
- Snake_case for all Python functions: `human_delay()`, `get_page_elements()`, `click_all_radios_first_option()`, `fill_text_by_index()`
- Camel case for JavaScript functions: `handleCodeInput()`, `runAutomation()`, `showStatus()`, `hideStatus()`
- Descriptive, verb-first naming that clearly indicates action: `fill_all_textareas()`, `is_finish_page()`, `click_next()`

**Variables:**
- Snake_case in Python: `page_num`, `max_pages`, `radio_names`, `target_value`, `input_id`
- Camel case in JavaScript: `nextId`, `btnText`, `runBtn`
- Single-letter variables used in loops: `i` for index, `p` for browser context
- Constants in UPPERCASE: `FORM_URL`, `HTML`

**Types/Classes:**
- No explicit type annotations in Python code (dynamic typing)
- JavaScript uses lowercase for HTML element IDs: `cn1`, `cn2`, `email`, `spinner`, `status`

## Code Style

**Formatting:**
- 4-space indentation in Python (PEP 8 standard)
- Inline HTML/CSS with embedded JavaScript in single file (`index.html`)
- Line length appears to favor readability over strict column limits
- CSS uses 2-space indentation consistently

**Linting:**
- No linter configuration detected
- Code follows general PEP 8 conventions informally

## Import Organization

**Python order:**
1. Standard library imports: `import argparse`, `import time`, `import random`, `import threading`, `import os`, `import sys`, `import subprocess`
2. Third-party imports: `from flask import Flask, request, jsonify, send_from_directory, Response`, `from playwright.sync_api import sync_playwright`

**JavaScript:**
- No imports (vanilla JavaScript in `index.html`)
- Functions declared inline before use

**Path Aliases:**
- None detected; all paths use absolute file system paths

## Error Handling

**Python patterns:**
- Try-except block at top level: `try:` in main script execution with general `Exception as e` catching (`script.py` lines 183-259)
- Error output via `print()` statements to stdout for logging
- Returns boolean on success/failure: `click_next()` returns `True/False`, `fill_text_by_index()` returns `True/False`
- HTTP error responses use `jsonify({'status': 'error', 'message': '...'})` format

**JavaScript patterns:**
- Try-catch-finally with async/await: `try { } catch(err) { }` in `runAutomation()`
- Status messages displayed to user via `showStatus('error', message)`
- Validation before action execution (lines 322-329 in `index.html`)
- Console errors not explicitly logged

## Logging

**Framework:** `print()` statements to stdout

**Patterns:**
- Status prefixed with action: `print(f"[script.py] exit={result.returncode}")`, `print(f"[script.py stdout] {result.stdout}")`
- Page state logged with page numbers: `print(f"\n=== PAGE {page_num} ===")`
- Element counts logged: `print(f"  Found: {elements['radioCount']} radio groups...")`
- Action logging with details: `print(f"  Clicking radio: name='{name}' value='{target_value}'")`
- Success/failure logged: `print("\n SUCCESS: Form completed!")`, `print(f"\n ERROR: {e}")`
- Indentation indicates nesting level (two spaces for sub-actions under page processing)

## Comments

**When to Comment:**
- Function docstrings explain purpose in plain English: `"""Random pause between actions to appear more human-like"""`
- Inline comments on complex logic: `# Split code into 6 chunks of 4`, `# Only check for finish page after page 0`
- Page flow documented with comments: `# PAGE 0: Survey code entry (6 text inputs)`, `# Pages with radio buttons`
- Validation reasons explained: `# Validate`, `# Run automation — pass email and code directly as arguments`
- Complex selectors documented: `# Check if NextButton is gone AND we see completion text`

**Docstring format:**
- Triple-quoted strings immediately after function definition
- Single-line format used for simple functions
- No type hints in docstrings

## Function Design

**Size:**
- Small, focused functions handling single concerns
- Utility functions: 5-15 lines typically (`human_delay()` = 2 lines, `is_finish_page()` = 19 lines)
- Main script logic: ~90 lines of sequential automation flow in main loop

**Parameters:**
- Functions take `page` as primary parameter for browser interaction: `get_page_elements(page)`, `click_all_radios(page)`
- Functions take minimal parameters; operations scoped to page context
- Index-based selection: `fill_text_by_index(page, input_index, value)`

**Return Values:**
- Automation functions return counts or booleans: `click_next()` returns `True/False`, `get_page_elements()` returns dict with counts
- Text fill functions return count of items processed or boolean success
- Early returns on validation failures in form handlers

## Module Design

**Exports:**
- Flask app exposed: `app = Flask(__name__)` with routes decorated with `@app.route()`
- All Python code in single files; no module imports between `app.py` and `script.py`
- Routes are decorated with Flask decorators: `@app.route('/', methods=['GET'])`, `@app.route('/run', methods=['POST'])`

**Barrel Files:**
- No barrel files; single-file architecture per concern
- `app.py`: Flask server with routes
- `script.py`: Automation logic with helper functions
- `index.html`: Web interface with embedded styles and scripts

## Code Organization

**Inline scripts:**
- JavaScript embedded directly in `<script>` tags at end of HTML
- Styles embedded in `<style>` tag in document head
- HTML structure, CSS, and JavaScript all in single `index.html` file for simplicity

**Function grouping:**
- Helper utilities at top: `human_delay()`
- Form interaction functions grouped together: all `fill_*()`, `click_*()`, `get_*()`, and `is_*()` functions before main execution
- Main execution logic at module level with context managers

**Global state:**
- Configuration constants: `FORM_URL = "https://pandaexpress.com/feedback"`
- Parsed arguments stored in module scope: `email`, `code`, `chunks`
- Browser context created at module level: `with sync_playwright() as p:`

---

*Convention analysis: 2026-03-18*
