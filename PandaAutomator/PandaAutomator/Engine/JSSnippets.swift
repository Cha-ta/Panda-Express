import Foundation

/// Namespace for all JavaScript snippets used by the automation engine.
/// Ported verbatim from script.py selectors and logic.
/// All JS expressions are IIFEs that return a value (never void) per Pitfall 1.
enum JSSnippets {

    // MARK: - Page Detection

    /// Detects all form elements on the current page.
    /// Returns JSON string matching script.py get_page_elements() (lines 24-51).
    static let detectPageElements: String = """
    (() => {
        const radios = document.querySelectorAll('input[type="radio"]');
        const radioNames = [...new Set(Array.from(radios).map(r => r.name))];

        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        const checkboxList = Array.from(checkboxes).map(c => ({name: c.name, value: c.value, id: c.id}));

        const textInputs = document.querySelectorAll('input[type="text"]:not([readonly])');
        const textList = Array.from(textInputs).map(i => i.name);

        const textareas = document.querySelectorAll('textarea');
        const textareaList = Array.from(textareas).map(t => t.name);

        return JSON.stringify({
            radioCount: radioNames.length,
            radioNames: radioNames,
            checkboxCount: checkboxList.length,
            checkboxes: checkboxList,
            textInputCount: textList.length,
            textInputs: textList,
            textareaCount: textareaList.length,
            textareas: textareaList
        });
    })()
    """

    /// Checks if the current page is the finish/thank-you page.
    /// Returns Bool. Ports script.py is_finish_page() (lines 145-164).
    static let isFinishPage: String = """
    (() => {
        const hasNext = document.querySelector('#NextButton') !== null;
        if (hasNext) return false;
        const text = document.body.innerText.toLowerCase();
        const indicators = [
            'your validation code',
            'thank you for completing',
            'survey complete',
            'your code will be emailed',
            'we appreciate your feedback'
        ];
        return indicators.some(i => text.includes(i));
    })()
    """

    /// Clicks the Next button using fallback selectors.
    /// Returns matched selector string or null. Ports script.py click_next() (lines 130-143).
    /// Note: Playwright-only :has-text replaced with JS innerText check.
    static let clickNext: String = """
    (() => {
        const selectors = ['#NextButton', 'input[value="Next"]', '.NextButton'];
        for (const sel of selectors) {
            const el = document.querySelector(sel);
            if (el) { el.click(); return sel; }
        }
        const buttons = document.querySelectorAll('button');
        for (const btn of buttons) {
            if (btn.innerText.trim().includes('Next')) {
                btn.click();
                return 'button:Next';
            }
        }
        return null;
    })()
    """

    // MARK: - Form Interaction

    /// Sets a text input value by name and dispatches synthetic events.
    /// Returns true/false. Ports script.py fill pattern with event dispatch (Pitfall 4).
    static func fillTextInput(name: String, value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
            const input = document.querySelector('input[name="\(escapedName)"]');
            if (!input) return false;
            input.value = '\(escapedValue)';
            input.dispatchEvent(new Event('input', {bubbles: true}));
            input.dispatchEvent(new Event('change', {bubbles: true}));
            return true;
        })()
        """
    }

    /// Clicks a radio button by element ID using name.value pattern.
    /// Returns true. Matches script.py line 74: getElementById('{name}.{value}').click().
    static func clickRadio(name: String, value: String) -> String {
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => { document.getElementById('\(escapedName).\(escapedValue)').click(); return true; })()
        """
    }

    /// Clicks a checkbox by element ID.
    /// Returns true. Matches script.py line 236: getElementById('{id}').click().
    static func clickCheckbox(id: String) -> String {
        let escapedId = id.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => { document.getElementById('\(escapedId)').click(); return true; })()
        """
    }

    /// Sets a textarea value by name and dispatches synthetic events.
    /// Returns true/false.
    static func fillTextarea(name: String, value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
            const ta = document.querySelector('textarea[name="\(escapedName)"]');
            if (!ta) return false;
            ta.value = '\(escapedValue)';
            ta.dispatchEvent(new Event('input', {bubbles: true}));
            ta.dispatchEvent(new Event('change', {bubbles: true}));
            return true;
        })()
        """
    }

    /// Returns array of values for a radio group name.
    /// Returns JSON.stringify(array). Matches script.py lines 63-68.
    static func getRadioValues(name: String) -> String {
        let escapedName = name.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
            const radios = document.querySelectorAll('input[type="radio"][name="\(escapedName)"]');
            return JSON.stringify(Array.from(radios).map(r => r.value));
        })()
        """
    }

    /// Fills the nth text input by index (for code entry chunks).
    /// Returns true/false. Matches script.py fill_text_by_index().
    static func fillTextByIndex(index: Int, value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        return """
        (() => {
            const inputs = document.querySelectorAll('input[type="text"]:not([readonly])');
            if (\(index) >= inputs.length) return false;
            const input = inputs[\(index)];
            input.value = '\(escapedValue)';
            input.dispatchEvent(new Event('input', {bubbles: true}));
            input.dispatchEvent(new Event('change', {bubbles: true}));
            return true;
        })()
        """
    }
}
