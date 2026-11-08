# VocoLoom — AI Voice Synthesis Platform & Microservice

VocoLoom ist eine modulare Multi-Voice Sprachplattform und TTS-Microservice (basierend auf F5-TTS und Vocos).

## URLs & Ports

- **Web UI & Studio:** `https://vocoloom.orfel.de` (oder `https://voice.orfel.de`)
- **OpenAPI / Swagger Dokumentation:** `https://vocoloom.orfel.de/docs`
- **REST API Endpoint:** `POST https://vocoloom.orfel.de/api/v1/synthesize`
- **Interner Port:** `7860` (gebunden an `127.0.0.1:7860` und `jannik-cloud-net`)

---

## Persistente Daten & Volumes

Die Modelldateien und Voice-Packs werden auf dem Host gespeichert und in den Container gemountet:

- **Host-Pfad:** `/mnt/Jannik-Cloud-Volume-01/vocoloom/voices`
- **Container-Pfad:** `/app/voices`

### Einrichten der ersten Stimme (Jürgen Seiferth)

Kopiere den Ordner `voices/juergen_seiferth/` vom Entwicklungsrechner auf den Server:

```bash
mkdir -p /mnt/Jannik-Cloud-Volume-01/vocoloom/voices
# Nach dem Kopieren liegt dort:
# /mnt/Jannik-Cloud-Volume-01/vocoloom/voices/juergen_seiferth/
#   ├── voice.json
#   ├── model.pt
#   ├── reference.wav
#   ├── reference.txt
#   └── avatar.png
```

Neue Stimmen können jederzeit einfach als Unterordner in `voices/` abgelegt werden und sind ohne Neustart sofort verfügbar.

---

## API Nutzung (REST)

### Stimme auflisten
```bash
curl -X GET https://vocoloom.orfel.de/api/v1/voices
```

### Sprache synthetisieren (WAV-Stream)
```bash
curl -X POST https://vocoloom.orfel.de/api/v1/synthesize \
  -H "Content-Type: application/json" \
  -d '{"voice_id": "juergen_seiferth", "text": "Hömma Kumpel, dat klappt 1a!"}' \
  --output test.wav
```

---

## Hermes Agent Integration

Hermes kann VocoLoom direkt über das `jannik-cloud-net` ansprechen:
- **Interne URL:** `http://vocoloom:7860/api/v1/synthesize`

Tool Definition für Hermes:
```json
{
  "name": "speak_as_juergen",
  "description": "Spricht einen Text mit der originalen 1995 Ruhrpott-Stimme von Jürgen Seiferth und gibt Audiodaten zurück.",
  "parameters": {
    "type": "object",
    "properties": {
      "text": {
        "type": "string",
        "description": "Der zu sprechende Text (idealerweise im authentischen Ruhrpott-Slang)."
      }
    },
    "required": ["text"]
  }
}
```
