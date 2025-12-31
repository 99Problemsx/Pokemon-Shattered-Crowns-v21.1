# Night Tileset System

Automatisches Laden von Nacht-Varianten für Tilesets, Autotiles und Character Graphics.

## 🌙 Wie es funktioniert

Bei Nacht (wenn `PBDayNight.isNight?` true ist) lädt das System automatisch `_n` Varianten:

- **Tilesets**: `Graphics/Tilesets/Outside.png` → `Graphics/Tilesets/Outside_n.png`
- **Autotiles**: `Graphics/Autotiles/Water.png` → `Graphics/Autotiles/Water_n.png`
- **Characters**: `Graphics/Characters/door.png` → `Graphics/Characters/door_n.png`

## 📝 Setup

### 1. Tileset für Nacht vorbereiten

1. Kopiere dein Tileset (z.B. `Outside.png`)
2. Benenne die Kopie um zu `Outside_n.png`
3. Bearbeite die `_n` Version:
   - **Fenster**: Hellgelb/warm färben (#FFFF99 oder ähnlich)
   - **Lampen**: Heller machen
   - **Leuchtende Objekte**: Aufhellen

### 2. Beispiel: Fenster-Tiles anpassen

**Tag-Version** (`Outside.png`):

- Fenster: Dunkelblau/grau (#4A6B8A)
- Nicht leuchtend

**Nacht-Version** (`Outside_n.png`):

- Fenster: Hellgelb (#FFFF99)
- Leuchtet warm

### 3. Optional: Character Graphics

Für leuchtende Türen, Fenster als Events:

- `door.png` → `door_n.png` (heller)
- `window.png` → `window_n.png` (leuchtend)

## 🎨 Beispiel-Workflow

```
Graphics/
  Tilesets/
    Outside.png          # Tag-Version (dunkle Fenster)
    Outside_n.png        # Nacht-Version (helle Fenster)
  Autotiles/
    Water.png            # Tag-Wasser
    Water_n.png          # Nacht-Wasser (dunkler/bläulicher)
  Characters/
    door_light.png       # Tür Tag
    door_light_n.png     # Tür Nacht (leuchtend)
```

## 🔧 Map-spezifische Konfiguration

Um Nacht-Tilesets für bestimmte Maps zu **deaktivieren**:

```ruby
# In map_metadata.txt oder PBS-Datei:
[MapID]
DisableNightTileset = true
```

Beispiel: Indoor-Maps, die immer gleich aussehen sollen.

## 🐛 Debug-Befehle

- **Strg+Shift+N**: Zeigt Night Tileset Status an
  - Map ID
  - Tag/Nacht State
  - Ob für diese Map deaktiviert

## ⚙️ Technische Details

Das System:

1. Prüft alle 30 Sekunden (1800 Frames), ob Tag/Nacht gewechselt hat
2. Lädt automatisch `_n` Varianten, wenn vorhanden
3. Fällt zurück auf normale Grafik, wenn keine `_n` Version existiert
4. Funktioniert mit **Animated Tilesets** (mehrere Frames)

## 💡 Kombination mit Dynamic Lighting

**Perfektes Setup:**

1. **Night Tilesets**: Fenster im Tileset werden gelb
2. **Light Rectangles**: Licht-Rechtecke über Fenster platzieren
3. **Night Tone**: Dunkler Screen-Tone bei Nacht

**Ergebnis**: Fenster leuchten warm und realistisch! 🏠✨

## 🎯 Best Practices

### Fenster-Farben:

- **Tag**: Dunkelblau/Grau (#4A6B8A, #6B7A8A)
- **Nacht**: Hellgelb/Warm (#FFFF99, #FFE680, #FFFFCC)

### Straßenlaternen:

- **Tag**: Aus/dunkel
- **Nacht**: Leuchtend gelb

### Wasser:

- **Tag**: Helles Blau
- **Nacht**: Dunkles Blau/Violett

### Gras:

- **Tag**: Sattgrün
- **Nacht**: Dunkelgrün/Bläulich
