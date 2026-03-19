# Panda Express Survey Automator

Automatically completes Panda Express feedback surveys to receive free entrée coupon codes.

## Features

- **Dynamic Form Detection** — Automatically detects form fields regardless of changing field names
- **Smart Answer Selection** — Selects "Highly Satisfied" for rating questions, "No" for Yes/No questions to minimize form length
- **Anti-Detection Measures** — Masks Playwright fingerprint to avoid bot detection
- **Human-Like Behavior** — Random delays between actions to appear natural
- **Web Interface** — Simple web UI to submit survey codes and emails

## Requirements

- Python 3.11+
- Playwright
- Flask

## Installation

```bash
# Clone the repository
git clone https://github.com/Cha-ta/Panda-Express.git
cd Panda-Express

# Install dependencies
pip install -r requirements.txt

# Install Playwright browsers
python -m playwright install chromium
```

## Usage

### Command Line

```bash
python3 script.py --email "your@email.com" --code "240640854263012301131206"
```

```PowerShell
python script.py --email "your@email.com" --code "240640854263012301131206"
```

- `--email` — Email address to receive the coupon code
- `--code` — 24-digit survey code from your Panda Express receipt

### Web Interface

```bash
python3 app.py
```

```PowerShell
python app.py
```

Then open http://localhost:5000 in your browser.

## How It Works

1. **Enter Survey Code** — The script navigates to pandaexpress.com/feedback and enters the 24-digit code from your receipt
2. **Auto-Fill Survey** — Dynamically detects all form fields (radios, checkboxes, text inputs, textareas) and fills them appropriately
3. **Submit Email** — Enters your email address on the final page
4. **Receive Coupon** — Coupon code is emailed within 24 hours

## Project Structure

```
├── app.py           # Flask web server
├── script.py        # Playwright automation script
├── index.html       # Web interface
├── requirements.txt # Python dependencies
```

## Anti-Detection Features

- Custom Chrome user agent
- `navigator.webdriver` set to `undefined`
- `--disable-blink-features=AutomationControlled` flag
- Random delays between actions (0.5-1.5 seconds)
- Page load wait after navigation

## Notes

- Survey codes are one-time use
- Coupon codes expire ~12 days after generation
- Valid at participating Panda Express locations
- Cannot be combined with other offers

## License

MIT
