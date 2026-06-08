# CLAUDE.md

## Personal Claude Code instructions

You are not my assistant.
You are my advisor who happens to be smarter than me.
Follow these rules in every reply:

1. Never start with agreement. Your first sentence must challenge my assumption, point out what I'm missing, or ask a question that exposes a gap in my thinking.

2. Rate your confidence. Before any claim, tag it [Certain] if you have hard evidence, [Likely] if it's a strong inference, [Guessing] if you are filling gaps. If most of your reply is guessing, say so first.

3. Kill these phrases for good: "Great question", "You're absolutely right", "That makes a lot of sense", "Absolutely", "Definitely". If you catch yourself typing one, delete and rewrite.

4. Disagree with structure. When I'm wrong, say: "I disagree because [reason]. Here's what I'd do instead [alternative]. The risk in your approach is [specific downside]."

5. Give me the uncomfortable answer first. If there's a truth I probably don't want to hear, lead with it. First line, not buried in paragraph three.

6. No warm up paragraphs. Skip "There are several ways to look at this". Start with the most useful thing you can say.

7. If I push back, don't fold. Hold your position unless I give you genuinely new information. "But I really think" is not new information.


## What this is

A tiny macOS menu-bar widget: a borderless floating panel pinned top-right, always above other apps and on all Spaces, showing today's goals. Native SwiftUI + AppKit (`NSPanel`), no Dock icon (`LSUIElement`). Swift 5.9, macOS 14+. Built from a Claude Design prototype in the "Twin Design System" (IBM Plex Sans, one purple accent `#5500ff`).

## Commands

```sh
swift run         # run during development (no login item — that needs the real .app bundle)
make bundle       # build dist/GoalsOfToday.app (release build + codesign --sign -)
make install      # bundle, kill running instance, copy to /Applications, launch
make release      # zip the bundle for distribution (ditto preserves the signature)
make icon         # regenerate packaging/AppIcon.icns from scripts/make-icon.swift
make clean        # rm -rf .build dist
```

There are no tests. `swift build -c release` is the only compile check (run via `make build`).

The app version lives in `packaging/Info.plist` (`CFBundleShortVersionString`); the Makefile reads it for the release zip name. Bump it there when releasing.

## Architecture

Four source files under `Sources/GoalsOfToday/`, plus self-hosted IBM Plex fonts in `Resources/fonts` (copied into the bundle via `Package.swift` `resources:`).

- **`main.swift`** — `AppDelegate` owns the `FloatingPanel` (an `NSPanel` subclass) and the menu-bar `NSStatusItem`. This is where all the AppKit/window behavior lives:
  - The panel is `.borderless`, `.nonactivatingPanel` — it floats above everything but does **not** steal focus from other apps when you click checkboxes. `canBecomeKey` is overridden to `true` so inline editing can still take keystrokes.
  - **Pin-point sizing:** the panel is anchored by its top-right corner (`topRight`). `contentSizeChanged` keeps that corner fixed while content grows/shrinks. Crucially, the window does **not** track the collapse/expand animation frame-by-frame (that jitters); it jumps to the largest size seen, then shrinks to fit in one step after a 0.25s settle. `windowDidMove` re-adopts the pin point when the user drags the panel.
  - A hidden main menu (`setUpMainMenu`) exists only to route ⌘C/⌘V/⌘X/⌘A/undo into text fields — without an Edit menu these shortcuts are dead in an `LSUIElement` app.
  - **Login item** via `SMAppService.mainApp`, auto-registered once on first launch — but only when `isBundled` (running from a real `.app`, detected by `Bundle.main.bundleIdentifier != nil`). `swift run` has no login item.

- **`Model.swift`** — `GoalsStore` (`ObservableObject`) is the single source of truth: `mains` (always ≥1), `sides`, `streak`, `collapsed`. Persists to `~/Library/Application Support/GoalsOfToday/state.json`, debounced 200ms off `objectWillChange`. The `Snapshot` Codable has a legacy `main` field for migrating the old single-main format to `mains`. Invariant: there is always at least one main goal (deleting/clearing the last main is a no-op — see `commit`/`delete`).

- **`Theme.swift`** — Twin Design System colors and type. Every color is a `dynamic(light, dark)` pair resolved against the system appearance (`NSAppearance.isDark`); the panel follows light/dark mode automatically. `Theme.plex(size, weight)` returns the registered IBM Plex font; `registerFonts()` (called at launch) registers the bundled `.ttf`s via Core Text.

- **`GoalsPanelView.swift`** — the whole SwiftUI view tree and all small components (`CheckBox`, `GoalRow`, `EditableText`, `AddField`, `ProgressBar`, etc.). Two layouts driven by `store.collapsed`: full (`body_`) vs. a single-goal pill (`compactBody`). Inline editing is `EditableText` (a SwiftUI `TextField` standing in for the prototype's `contenteditable`): Enter/click-away commits, Escape cancels, clearing a side goal deletes it. `MakeWindowKey` is a workaround — because the panel is non-activating, clicking + doesn't make the window key, so a freshly inserted text field couldn't type until this `NSViewRepresentable` forces `makeKey()`.

## Conventions

- Comments are intentionally dense around the AppKit window hacks (focus, sizing, animation) — these encode non-obvious macOS behavior. Preserve the reasoning when editing those areas.
- Some inline comments are still in Dutch (e.g. "tweak: Accent = paars"); the user-facing UI strings are English. Match the existing English for any new UI text.
