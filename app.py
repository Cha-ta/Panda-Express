from flask import Flask, request, jsonify, render_template_string
import csv
import threading
import os

app = Flask(__name__)

HTML = open(os.path.join(os.path.dirname(__file__), 'index.html')).read()

@app.route('/')
def index():
    return render_template_string(HTML)

@app.route('/run', methods=['POST'])
def run_form():
    data = request.json
    email = data.get('email')
    code = data.get('code')  # full 24-char code

    # Split code into groups of 4
    chunks = [code[i:i+4] for i in range(0, len(code), 4)]
    if len(chunks) < 6:
        return jsonify({'status': 'error', 'message': 'Code must be 24 characters long.'})

    # Update CSV with new values
    rows = []
    with open('form_answers.csv', 'r') as f:
        reader = list(csv.DictReader(f))
        fieldnames = ['type', 'name', 'value', 'page']
        for row in reader:
            # Update code fields
            for i, name in enumerate(['CN1','CN2','CN3','CN4','CN5','CN6']):
                if row['name'] == name and row['type'] == 'text':
                    row['value'] = chunks[i]
            # Update email fields
            if row['name'] in ['S000057', 'S000064'] and row['type'] == 'text':
                row['value'] = email
            rows.append(row)

    with open('form_answers.csv', 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    # Run the automation in background thread
    def run_script():
        os.system('python3 script.py')

    thread = threading.Thread(target=run_script)
    thread.start()

    return jsonify({'status': 'success', 'message': 'Form automation started! Check the browser window.'})

if __name__ == '__main__':
    app.run(debug=True, port=5000)