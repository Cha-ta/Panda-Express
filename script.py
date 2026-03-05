import argparse
import time
import random
from playwright.sync_api import sync_playwright

def human_delay():
    """Random pause between actions to appear more human-like"""
    time.sleep(random.uniform(0.5, 1.5))

# Parse arguments passed from app.py
parser = argparse.ArgumentParser()
parser.add_argument('--email', required=True)
parser.add_argument('--code', required=True)
args = parser.parse_args()

email = args.email
code = args.code

# Split code into 6 chunks of 4
chunks = [code[i:i+4] for i in range(0, 24, 4)]

FORM_URL = "https://pandaexpress.com/feedback"

def get_page_elements(page):
    """Detect all form elements on the current page."""
    return page.evaluate("""
        () => {
            const radios = document.querySelectorAll('input[type="radio"]');
            const radioNames = [...new Set(Array.from(radios).map(r => r.name))];
            
            const checkboxes = document.querySelectorAll('input[type="checkbox"]');
            const checkboxList = Array.from(checkboxes).map(c => ({name: c.name, value: c.value, id: c.id}));
            
            const textInputs = document.querySelectorAll('input[type="text"]:not([readonly])');
            const textList = Array.from(textInputs).map(i => i.name);
            
            const textareas = document.querySelectorAll('textarea');
            const textareaList = Array.from(textareas).map(t => t.name);
            
            return {
                radioCount: radioNames.length,
                radioNames: radioNames,
                checkboxCount: checkboxList.length,
                checkboxes: checkboxList,
                textInputCount: textList.length,
                textInputs: textList,
                textareaCount: textareaList.length,
                textareas: textareaList
            };
        }
    """)

def click_all_radios_first_option(page):
    """Click the first option (index 0 = usually 'Highly Satisfied') for all radio questions."""
    radio_names = page.evaluate("""
        () => {
            const radios = document.querySelectorAll('input[type="radio"]');
            return [...new Set(Array.from(radios).map(r => r.name))];
        }
    """)
    
    for name in radio_names:
        values = page.evaluate(f"""
            () => {{
                const radios = document.querySelectorAll('input[type="radio"][name="{name}"]');
                return Array.from(radios).map(r => r.value);
            }}
        """)
        
        if values:
            target_value = values[0]
            input_id = f"{name}.{target_value}"
            print(f"  Clicking radio: name='{name}' value='{target_value}'")
            page.evaluate(f"document.getElementById('{input_id}').click()")
            human_delay()
    
    return len(radio_names)

def fill_text_by_index(page, input_index, value):
    """Fill a specific text input by index."""
    inputs = page.evaluate("""
        () => {
            const inputs = document.querySelectorAll('input[type="text"]:not([readonly])');
            return Array.from(inputs).map(i => i.name);
        }
    """)
    
    if input_index < len(inputs):
        name = inputs[input_index]
        selector = f"input[name='{name}']"
        print(f"  Filling text: {name} = '{value}'")
        page.fill(selector, value)
        return True
    return False

def fill_all_text_inputs(page, value):
    """Fill all text inputs with the same value (e.g., email)."""
    inputs = page.evaluate("""
        () => {
            const inputs = document.querySelectorAll('input[type="text"]:not([readonly])');
            return Array.from(inputs).map(i => i.name);
        }
    """)
    
    for name in inputs:
        selector = f"input[name='{name}']"
        print(f"  Filling text: {name} = '{value}'")
        page.fill(selector, value)
        human_delay()
    
    return len(inputs)

def fill_all_textareas(page, value):
    """Fill all textareas with the same value."""
    textareas = page.evaluate("""
        () => {
            const tas = document.querySelectorAll('textarea');
            return Array.from(tas).map(t => t.name);
        }
    """)
    
    for name in textareas:
        selector = f"textarea[name='{name}']"
        print(f"  Filling textarea: {name} = '{value}'")
        page.fill(selector, value)
        human_delay()
    
    return len(textareas)

def click_next(page):
    """Click the Next button and wait for page load."""
    selectors = ["#NextButton", "input[value='Next']", "button:has-text('Next')", ".NextButton"]
    
    for selector in selectors:
        if page.locator(selector).count() > 0:
            print(f"  Clicking next: {selector}")
            page.click(selector)
            page.wait_for_load_state("networkidle", timeout=15000)
            time.sleep(random.uniform(1, 2))
            return True
    
    print("  Next button not found!")
    return False

def is_finish_page(page):
    """Check if we've reached the finish/thank you page."""
    # Check if NextButton is gone AND we see completion text
    has_next_button = page.locator("#NextButton").count() > 0
    if has_next_button:
        return False
    
    # Look for specific completion indicators
    page_text = page.evaluate("document.body.innerText")
    finish_indicators = [
        "your validation code",
        "thank you for completing",
        "survey complete",
        "your code will be emailed",
        "we appreciate your feedback"
    ]
    for indicator in finish_indicators:
        if indicator.lower() in page_text.lower():
            return True
    return False

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=True,
        args=[
            '--disable-blink-features=AutomationControlled',
            '--no-sandbox',
            '--disable-dev-shm-usage'
        ]
    )
    context = browser.new_context(
        user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    )
    context.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    page = context.new_page()
    page.goto(FORM_URL)
    time.sleep(random.uniform(2, 4))

    try:
        page_num = 0
        max_pages = 15

        while page_num < max_pages:
            print(f"\n=== PAGE {page_num} ===")

            # Only check for finish page after page 0
            if page_num > 0 and is_finish_page(page):
                print("\n SUCCESS: Form completed!")
                break

            elements = get_page_elements(page)
            print(f"  Found: {elements['radioCount']} radio groups, {elements['checkboxCount']} checkboxes, {elements['textInputCount']} text inputs, {elements['textareaCount']} textareas")

            # PAGE 0: Survey code entry (6 text inputs)
            if page_num == 0 and elements['textInputCount'] == 6:
                for i, chunk in enumerate(chunks):
                    fill_text_by_index(page, i, chunk)
                    human_delay()

            # Pages with radio buttons
            elif elements['radioCount'] > 0:
                # For single Yes/No questions (1 radio with 2 options), select "No" (second option)
                if elements['radioCount'] == 1:
                    radio_name = elements['radioNames'][0]
                    values = page.evaluate(f"""
                        () => {{
                            const radios = document.querySelectorAll('input[type="radio"][name="{radio_name}"]');
                            return Array.from(radios).map(r => r.value);
                        }}
                    """)
                    
                    if len(values) == 2:
                        # Yes/No question - select "No" (second option) to minimize form
                        target_value = values[1]
                        input_id = f"{radio_name}.{target_value}"
                        print(f"  Clicking radio (No): name='{radio_name}' value='{target_value}'")
                        page.evaluate(f"document.getElementById('{input_id}').click()")
                        human_delay()
                    else:
                        # Not Yes/No, select first option
                        click_all_radios_first_option(page)
                else:
                    # Multiple radio groups = satisfaction questions
                    click_all_radios_first_option(page)

            # Pages with checkboxes
            elif elements['checkboxCount'] > 0:
                checkboxes = elements['checkboxes']
                for i, cb in enumerate(checkboxes[:2]):
                    input_id = cb['id'] or f"{cb['name']}.{cb['value']}"
                    print(f"  Clicking checkbox: {input_id}")
                    page.evaluate(f"document.getElementById('{input_id}').click()")
                    human_delay()

            # Pages with textareas (feedback)
            elif elements['textareaCount'] > 0:
                fill_all_textareas(page, "Great food and excellent service!")

            # Pages with text inputs (email page)
            elif elements['textInputCount'] > 0 and elements['textInputCount'] < 6:
                fill_all_text_inputs(page, email)

            if not click_next(page):
                print("  Could not find Next button, stopping")
                break

            page_num += 1

        if page_num >= max_pages:
            print(f"\n Reached max pages ({max_pages}), stopping")

    except Exception as e:
        print(f"\n ERROR: {e}")
        page.screenshot(path="error_screenshot.png")
        print("Screenshot saved to error_screenshot.png")

    browser.close()
