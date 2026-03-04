import csv
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://pandaexpress.com/feedback")  # replace with your URL

    with open('form_answers.csv') as f:
        rows = list(csv.DictReader(f))

    pages = sorted(set(int(row['page']) for row in rows))

    for pg in pages:
        page_rows = [r for r in rows if int(r['page']) == pg]

        for row in page_rows:
            if row['type'] == 'radio':
                page.click(f"input[name='{row['name']}'][value='{row['value']}']")
            elif row['type'] == 'checkbox':
                page.check(f"input[name='{row['name']}'][value='{row['value']}']")
            elif row['type'] == 'text':
                page.fill(f"input[name='{row['name']}']", row['value'])
            elif row['type'] == 'textarea':
                page.fill(f"textarea[name='{row['name']}']", row['value'])
            elif row['type'] == 'next':
                page.click(f"#{row['name']}")