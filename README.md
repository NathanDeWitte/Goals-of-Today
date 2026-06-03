# Goals of today

Een piepklein macOS-widgetje: een zwevend paneel rechtsboven op je scherm,
áltijd zichtbaar over andere apps heen, met je doelen van vandaag.

Native SwiftUI + AppKit (`NSPanel`), geen Electron. Gebouwd naar het
Claude Design-prototype ("Nate's Brain Hack" / Goals Prototype.html), in het
Twin Design System: IBM Plex Sans, wit, rustig, één paarse accent.

## Features

- **Zwevend paneel** — pinned rechtsboven, `level: .floating`, op alle Spaces,
  ook naast fullscreen-apps. Verslepen mag; hij onthoudt z'n plek als pin-punt.
- **Main focus** — één vet hoofddoel met paarse "MAIN FOCUS"-eyebrow erboven.
- **Side goals** — compacte lijst eronder.
- **Inline bewerken** — klik op de tekst en typ. Enter of klik-weg = opslaan,
  Escape = annuleren, side goal leegmaken = verwijderen.
- **Toevoegen** — "Voeg een doel toe" → invoerveld, Enter voegt toe.
- **Afvinken** — paarse vinkjes; voortgangsbalk in de footer loopt mee.
- **Alles klaar** — vinkjes worden groen, footer toont
  "Alles klaar. Mooi werk." + je reeks.
- **In-/uitklappen** — pijltje in de titelbalk → pilletje met hoofddoel +
  voortgang. Klik de pil → weer volledig.
- **Persistentie** — alles bewaard in
  `~/Library/Application Support/GoalsOfToday/state.json`.
- **Menubalk-item** (✓-icoon) — paneel tonen/verbergen, app stoppen.
  Geen Dock-icoon.

Vastgezette tweaks (uit de design-sessie): paars accent `#5500ff`,
voortgangsbalk-footer, ruime dichtheid (300px), rechtsboven.

## Draaien

```sh
swift run
```

## Bouwen (release)

```sh
swift build -c release
.build/release/GoalsOfToday
```
