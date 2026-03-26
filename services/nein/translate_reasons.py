import json
import urllib.request
import time
from deep_translator import GoogleTranslator

def main():
    print("Fetching original reasons.json...")
    url = "https://raw.githubusercontent.com/hotheadhacker/no-as-a-service/main/reasons.json"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        reasons = json.loads(response.read().decode())

    print(f"Loaded {len(reasons)} reasons. Starting translation...")
    
    translator = GoogleTranslator(source='en', target='de')
    translated = []
    
    batch_separator = " ||| "
    current_batch = []
    current_len = 0

    for r in reasons:
        r_text = r.replace(" ||| ", " ")
        if current_len + len(r_text) + 5 > 4000:
            text_to_translate = batch_separator.join(current_batch)
            res = translator.translate(text_to_translate)
            if res:
                translated.extend([s.strip() for s in res.split(batch_separator)])
            
            current_batch = [r_text]
            current_len = len(r_text)
            time.sleep(0.5)
        else:
            current_batch.append(r_text)
            current_len += len(r_text) + 5

    if current_batch:
        text_to_translate = batch_separator.join(current_batch)
        res = translator.translate(text_to_translate)
        if res:
            translated.extend([s.strip() for s in res.split(batch_separator)])

    translated = [t for t in translated if t]

    with open('/app/excuses.json', 'w', encoding='utf-8') as f:
        json.dump(translated, f, ensure_ascii=False, indent=4)

    print(f"Successfully translated {len(translated)} reasons. Saved to excuses.json.")

if __name__ == '__main__':
    main()
