# Goals of Today

A tiny macOS widget: a floating panel in the top-right corner of your screen,
always visible above other apps, showing your goals for today.

Native SwiftUI + AppKit (`NSPanel`), no Electron. Built from the
Claude Design prototype ("Nate's Brain Hack" / Goals Prototype.html), in the
Twin Design System: IBM Plex Sans, white, calm, one purple accent.

## Features

- **Floating panel** — pinned top-right, `level: .floating`, on all Spaces,
  even next to fullscreen apps. You can drag it; it remembers its spot as the
  pin point.
- **Main focus** — one bold primary goal with a purple "MAIN FOCUS" eyebrow
  above it.
- **Side goals** — a compact list below.
- **Inline editing** — click the text and type. Enter or click-away = save,
  Escape = cancel, clearing a side goal = delete.
- **Adding** — "Add a goal" → input field, Enter adds it.
- **Checking off** — purple checkmarks; the progress bar in the footer tracks
  along.
- **All done** — checkmarks turn green, footer shows
  "All done. Nice work." + your streak.
- **Collapse/expand** — arrow in the title bar → pill with main goal +
  progress. Click the pill → back to full view.
- **Persistence** — everything saved in
  `~/Library/Application Support/GoalsOfToday/state.json`.
- **Menu bar item** (✓ icon) — show/hide the panel, toggle "Start at login",
  quit the app. No Dock icon.
- **Start at login** — registers itself as a login item on first launch
  (`SMAppService`); after that you manage it via the menu bar menu or
  System Settings → General → Login Items.

Locked-in tweaks (from the design session): purple accent `#5500ff`,
progress bar footer, comfortable density (300px), top-right.

## Download (prebuilt)

1. Download `GoalsOfToday-x.y.z.zip` from the
   [Releases page](https://github.com/NathanDeWitte/Goals-of-Today/releases/latest).
2. Unzip and drag `GoalsOfToday.app` into your **Applications** folder
   (`/Applications`).
3. **First launch:** the app is not notarized by Apple, so macOS will warn
   you. Right-click the app → **Open** → **Open**. Or via Terminal:

   ```sh
   xattr -d com.apple.quarantine /Applications/GoalsOfToday.app
   ```

After that it launches normally, and at login.

## Build and install from source

```sh
make install     # builds dist/GoalsOfToday.app, copies to /Applications and launches
```

Other targets: `make bundle` (build just the .app), `make release`
(zip for distribution), `make icon` (regenerate AppIcon.icns),
`make clean`.

## Run during development

```sh
swift run
```

(Without the bundle there's no login item; that requires the real .app.)
