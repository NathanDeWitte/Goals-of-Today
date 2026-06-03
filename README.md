# Goals of Today

A tiny macOS widget: a floating panel in the top-right corner of your screen,
always visible above other apps, showing your goals for today.

<img width="2056" height="1329" alt="Screenshot 2026-06-03 at 15 58 34" src="https://github.com/user-attachments/assets/504a45ef-20c0-44c4-bf67-a24b4b09acc8" />


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
