# Feel v3 on Android

The prototype on a phone: the same rooms, enemies and boss as the desktop build, with a
touch rig built from `design/gdd/input-control-mapping.md` where the prototype has the
verb. The gameplay code is unchanged; the touch layer feeds the same InputMap actions the
keyboard uses.

## The file

`build/android/new-vania-feel-v3.apk`

- Debug-signed, `arm64-v8a`, package `com.ferasalm.newvania.feelv3`.
- Android 7.0 or newer (minSdk 24). The game locks to sensor landscape.
- **Do not publish this APK.** It contains the placeholder hero frames traced from the
  Order of Ecclesia reference sheet (`assets/hero/` is git-ignored for that reason) and
  music whose licence is not confirmed. Share it by hand with people playtesting the
  prototype, not on a store or a public link.

## Install

1. Copy the APK to the phone (USB, Drive, WhatsApp, anything).
2. Open it from the phone's file manager.
3. Android asks to allow "install unknown apps" for the app that opened it. Allow it for
   that app only, then tap Install.
4. Open **New Vania - Feel v3** and turn the phone sideways.

If an older copy is installed and Android says "app not installed", uninstall the old one
first (the debug signature is stable, so normal updates install over it).

## Controls

The buttons sit in a diamond under the right thumb, like Bloodstained: Ritual of the Night on a phone: ATK on the left, JUMP at the bottom, BACK on the right, SPEC on top, and SWAP lower left of them. Pause is in the top-right corner.

| Touch | What it does |
|---|---|
| Floating stick (left 42%) | move. It appears where your thumb lands. Can be set to "fixed" under Pause > CONTROLS |
| Stick pushed down, held 90 ms | crouch; the down-zone uses the GDD's 25 deg entry / 45 deg exit cone |
| Down + JUMP on a thin ledge | drop through |
| ATK | attack; one button, alternating hands, so the faster two-hand chain works. With Elegy-013 each press is one heavy cut |
| JUMP | hold = high jump, tap = hop. At a wall, with the stick held toward it, JUMP makes her cling (needs the GRIP SERVOS relic); JUMP again kicks her away |
| SPEC | the special (the keyboard's Up + Attack): blade wave with Dirge-042, the Requiem with Elegy-013 |
| SWAP | Dirge-042 / Elegy-013 |
| BACK | backdash (the accessibility direct press; the double-tap-back stick gesture also works) |
| CACHE bubble | heal and save at the brain cache station; it appears next to it when she is close |
| Pause (top-right corner) | resume, restart, jump to one of the six rooms, RECONSTRUCT, or QUIT |
| Pause > CONTROLS | drag buttons and the stick; SMALLER / BIGGER and FAINTER / SOLID for a tapped button; stick "floats" or "fixed"; RESET; DONE saves. Remembered on the phone |

Keyboard and gamepad still work on desktop, as described in README.md. On desktop the touch layer can be shown
with `--touch` (mouse clicks become touches because
`input_devices/pointing/emulate_touch_from_mouse` is on).

## Build it again

The project is `prototypes/feel-v3`; the preset is `export_presets.cfg` (Android, arm64,
debug keystore).

1. Godot 4.7.2 editor + its Android export templates in
   `%APPDATA%\Godot\export_templates\4.7.2\`.
2. JDK 17. Set **Editor Settings > Export > Android > Java SDK Path**.
3. Android SDK with `platform-tools`, `build-tools;35.0.0`, `platforms;android-35`. Set
   **Android SDK Path**.
4. A debug keystore (Godot's default is
   `%APPDATA%\Godot\keystores\debug.keystore`, alias `androiddebugkey`, password `android`).
5. Hero frames are not in the repository. Build them once with `play.cmd`, or copy
   `assets/hero/*.png` from a checkout that has them. The save-room pictures are built by
   `tools/build_save_rooms.py`.
6. Export:

```bat
"C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64_console.exe" ^
  --headless --path . --export-debug "Android" build/android/new-vania-feel-v3.apk
```

The export packs the raw PNG/JSON/TXT/OGG/WAV files (`include_filter` in
`export_presets.cfg`) because the prototype loads them at runtime through `FileAccess`;
`assets/references/` and `shots/` are excluded.

## Known limits (prototype scope)

- The touch layer draws in the game's 384x216 viewport, so it scales with the integer
  stretch and sits inside the 16:9 band. The production two-canvas/dp model (GDD
  TR-INP-059) is not implemented here; bars on very wide phones are black.
- The F1 tuning panel is desktop-only. The pause menu's room jump (all six rooms) covers phone testing.
- Debug build: larger than a release build and debuggable. Not for a store.
