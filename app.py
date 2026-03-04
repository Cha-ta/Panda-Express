from flask import Flask, request, jsonify, render_template_string
import threading
import os
import subprocess

app = Flask(__name__)

with open(os.path.join(os.path.dirname(__file__), 'index.html')) as f:
    HTML = f.read()

@app.route('/')
def index():
    return render_template_string(HTML)

@app.route('/run', methods=['POST'])
def run_form():
    data = request.json
    email = data.get('email', '').strip()
    code = data.get('code', '').strip()

    # Validate
    if len(code) != 24:
        return jsonify({'status': 'error', 'message': 'Code must be exactly 24 characters.'})
    if not email or '@' not in email:
        return jsonify({'status': 'error', 'message': 'Please enter a valid email address.'})

    # Run automation — pass email and code directly as arguments
    # No CSV writing = no conflict between simultaneous users
    def run_script():
        script_path = os.path.join(os.path.dirname(__file__), 'script.py')
        subprocess.run([
            'python3', script_path,
            '--email', email,
            '--code', code
        ])

    thread = threading.Thread(target=run_script)
    thread.daemon = True
    thread.start()

    return jsonify({'status': 'success', 'message': 'Automation started! The form is being filled out in the background.'})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)