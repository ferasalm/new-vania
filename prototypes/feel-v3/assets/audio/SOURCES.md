# Audio sources — `prototypes/feel-v3/assets/audio/`

Self-contained SFX + music set for the feel-v3 prototype. Every file below was
**copied** (originals left in place) from the Ansimuz / Heart Gamedev pack library
at `C:/Users/AUC/opencode-workspace/workspace/new-vania/inbox/downloads/organized/`.
The event → file map the game reads is `events.json`.

**Nothing was listened to.** Selection used filename semantics and `ffprobe`
duration only — same method and same caveat as `assets/audio/selected/README.md`.
Re-pick by ear at playtest.

| New name | Original full path | Pack | Licence (file read) |
|---|---|---|---|
| `sfx/footstep.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/step.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` |
| `sfx/jump.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/jump.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` |
| `sfx/land.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/land.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` |
| `sfx/swing.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/attack.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` |
| `sfx/hit.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/shock.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` |
| `sfx/hurt.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/hurt.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` |
| `sfx/enemy_die.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/kill.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` |
| `sfx/backdash.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/rise.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` |
| `sfx/door.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/open-door.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` |
| `sfx/ui_move.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/click.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` |
| `sfx/ui_confirm.ogg` | `.../organized/projects/GothicVania-town-files/code/phaser-code/assets/sounds/switch.ogg` | GothicVania town (Ansimuz) | CC0 — `projects/GothicVania-town-files/public-license.pdf` (the music in that pack is credit-required per `projects/GothicVania-town-files/Music/readme.txt`; `switch.ogg` is a demo sound, not that music) |
| `music/room.ogg` | `.../organized/audio/cyberpunk-street-files/Assets/music/cyberpunk-street.ogg` | cyberpunk-street (Ansimuz) | CC0 — `docs/cyberpunk-street-files/public-license.pdf` (licence sits in the library's `docs/` sibling, not inside the audio folder) |
| `music/boss.ogg` | `.../organized/audio/TinyRPGMusic/Boss Fight 2.ogg` | TinyRPGMusic (Ansimuz) | "You may use these assets in personal or commercial projects… Credit no required but appreciated" — `docs/TinyRPGMusic/public-license.txt` (licence sits in `docs/`, not inside the audio folder) |

`.../organized/` = `C:/Users/AUC/opencode-workspace/workspace/new-vania/inbox/downloads/organized/`.

## Durations

| File | Duration | Note |
|---|---|---|
| `sfx/footstep.wav` | 0.182 s | |
| `sfx/jump.ogg` | 0.331 s | |
| `sfx/land.wav` | 0.214 s | |
| `sfx/swing.ogg` | 0.285 s | |
| `sfx/hit.wav` | 0.393 s | |
| `sfx/hurt.ogg` | 0.515 s | |
| `sfx/enemy_die.ogg` | 0.393 s | |
| `sfx/backdash.ogg` | 0.441 s | **weak fit** — an enemy riser, not a dash whoosh |
| `sfx/door.wav` | 42.602 s (audible 0–0.86 s) | **weak fit** — right meaning, but the source carries ~40 s of digital silence; stop the player at ~900 ms or it holds a voice |
| `sfx/ui_move.wav` | 0.076 s | |
| `sfx/ui_confirm.ogg` | 0.115 s | |
| `music/room.ogg` | 61.1 s | |
| `music/boss.ogg` | 88.6 s | |

## Weak fits

- **`backdash`** — no pack ships a dash whoosh. `rise.ogg` (a rising sweep) is the
  closest short, airy move; it reads as a dash only at speed and with the
  `pitch_random` jitter in `events.json`.
- **`door`** — `open-door.wav` is the only door in the library and it is a 42.6 s
  file whose body ends at 0.86 s. Copied bit-identical; the game must hard-stop it.

## Excluded

- **Sewers pack** — no readable licence (`public-license.pdf` is font-encoded, not a
  `assets/LICENSE-MANIFEST.md` row). Not used, same call as `assets/audio/selected/GAPS.md`.
- **`projects/Warped City Godot/Music/cyber_runner.ogg`** and **`projects/Warped City
  Phaser/assets/sounds/*`** — no licence file ships inside those pack folders.
- **`GothicVania-town` music** (`rpg_village02__loop`) — credit-required (Pascal
  Belisle), not used.
