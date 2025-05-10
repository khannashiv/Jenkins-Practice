from flask import Blueprint, render_template, request
from .analyzer import analyze_text

main = Blueprint('main', __name__)

@main.route('/', methods=['GET', 'POST'])
def index():
    result = None
    if request.method == 'POST':
        user_text = request.form['text']
        result = analyze_text(user_text)
    return render_template('index.html', result=result)
