import re
from collections import Counter

def analyze_text(text):
    words = re.findall(r'\b\w+\b', text.lower())
    return {
        'word_count': len(words),
        'char_count': len(text),
        'char_count_no_space': len(text.replace(" ", "")),
        'sentence_count': len(re.findall(r'[.!?]', text)),
        'common_word': Counter(words).most_common(1)[0][0] if words else "N/A"
    }
