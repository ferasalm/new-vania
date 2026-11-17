# Feel v3: where every asset comes from, and whether it may be published

Written 2026-11-16 by Helper 3. Folder covered: `prototypes/feel-v3/assets/`.

**How this was made.** From folder listings and these notes only:
`assets/SOURCES.md`, `assets/audio/SOURCES.md`, `prototypes/sandbox/assets/MANIFEST.txt`,
`assets/LICENSE-MANIFEST.md` (repository root), `tools/build_world.py`, `README.md`, `ANDROID.md`.
No picture or sound was opened. No file in `assets/hero/` or the Shanoa sheet was opened (file names only).

**How to read "Safe to publish".**
- **yes**: a note in the repository names the licence, and it allows publishing.
- **no**: publishing is not allowed, or the origin is a commercial game.
- **not yet**: probably fine, but the licence text is not recorded. Someone must confirm first.

## The short answer

| Must be replaced or confirmed before anything goes public | Why |
|---|---|
| `hero/` (78 files) | Traced from Castlevania: Order of Ecclesia. **Never publish.** |
| `references/` Shanoa sheet | A ripped sheet from a commercial game. **Never publish.** |
| `audio/music/battle_encounter.ogg`, `battle_encounter_2.ogg`, `boss_battle.ogg`, `save_room.ogg` | "Supplied by the user"; no licence note. |
| `env/library_*`, `env/doorframe_library.png`, `env/door_library.png` | Metroidvania Library Asset Pack: licence text not recorded. |
| `warden/` | WereWolf pack: licence text not recorded. |
| `boss/` | Made from `references/mini-boss.png`: origin not recorded. |
| `weapon/`, `env/save_room*.png` | Made from our own concept pictures: how those pictures were made is not recorded. |

`SOURCES.md` in the assets folder is **out of date** about the heroine. It says `hero/` comes from a CC0 pack.
That was the earlier heroine. Today `hero/` is the traced set (see `README.md`, "Art", and `.gitignore`).

## The table

| Folder or file | Files | What it is | Source | Licence | Safe to publish |
|---|---|---|---|---|---|
| `hero/` | 78 | Heroine frames: idle, run, jump, land, attack, attack2, airatk, airatk2, crouch, crouchatk, crouchatk2, backdash, cast, hurt, dead, plus `pandora_sheet.png` | Recoloured and cut from the Order of Ecclesia "Shanoa" sheet by `tools/build_pandora.py` | **None. Traced from a commercial game.** Git-ignored. | **no** |
| `hero_v2/` | 0 at the time of writing | New 2D cut-out heroine (tonight's sprint, Helper 1) | Must come only from our own pictures (`pandora-001-sprite.jpg`, `pandora-001-concept.jpg`) | Ours, if the rule was kept | check `production/session-state/active.md` |
| `hero_3d/` | folder not present at the time of writing | 3D route (tonight's sprint, lead) | 3D model made from our own pictures | Ours, if the rule was kept | check `production/session-state/active.md` |
| `references/DS _ DSi - Castlevania_ Order of Ecclesia - Playable Characters - Shanoa.png` | 1 | The ripped reference sheet | Commercial game | **None.** Git-ignored. | **no** |
| `references/pandora-001-sprite.jpg`, `pandora-001-concept.jpg`, `pandora-001-idle.gif` | 3 | Our own heroine pictures | The user's concept pictures | Ours; how they were made is not recorded here | not yet (confirm origin) |
| `references/dirge-042.jpg`, `elegy-013.jpg` | 2 | Our own weapon concept pictures | The user's concept pictures | Ours; origin not recorded here | not yet (confirm origin) |
| `references/mini-boss.png` | 1 | Picture the boss is cut from | Not recorded | **unknown** | not yet |
| `references/save-room-*.jpg`, `references/Save room/` | 8 | Save-room concept pictures | The user's concept pictures | Ours; origin not recorded here | not yet (confirm origin) |
| `references/Metroidvania Library Asset Pack/` | pack | Library art pack | Ansimuz, itch.io (recalled by the user) | **Licence text not recorded** (`assets/LICENSE-MANIFEST.md`: "license text pending") | not yet |
| `references/Scifi lab Files/` | pack | Lab art pack | Ansimuz, itch.io | Custom permissive: commercial use, changes and sharing allowed, credit not required | yes |
| `references/Battle Encounter.ogg`, `Battle Encounter 2.ogg`, `BossBattle.ogg`, `save-room-music.ogg` | 4 | Music the user supplied | Not recorded | **unknown** | not yet |
| `hound/` | 34 | Hound enemy: idle, walk, run, jump | Ansimuz Legacy Collection, Gothicvania, Hell-Hound | CC0 | yes |
| `ghost/` | 28 | Ghost enemy: idle, chase, shriek, appear, vanish | Ansimuz Legacy Collection, Gothicvania, Ghost | CC0 | yes |
| `choir/` | 11 | Winged choir enemy: idle, attack | Ansimuz Gothicvania Church, angel (through the sandbox prototype) | CC0 | yes |
| `spitter/` | 5 | Spitter enemy: idle | Ansimuz Super Grotto Escape, bat (through the sandbox prototype) | CC0 | yes |
| `warden/` | 11 | Mini boss: idle, run | Ansimuz WereWolf pack (through the sandbox prototype) | **Licence text not recorded** ("license text pending") | not yet |
| `boss/body.png`, `boss/hand.png` | 2 | The Pallbearer | Cut from `references/mini-boss.png` by `tools/build_world.py` | **unknown** | not yet |
| `weapon/dirge.png`, `weapon/elegy.png` | 2 | The two weapons | Cut down from our own concept pictures by `tools/build_world.py` | Ours; origin of the concept pictures not recorded | not yet (confirm origin) |
| `env/church_*` (5), `env/doorframe_church.png`, `env/door_church.png` | 7 | Church walls, tiles, column, ledge | Ansimuz Gothicvania Church | CC0 | yes |
| `env/fort_*` | 4 | Banner, doors, window | Ansimuz Fort of Illusion | CC0 | yes |
| `env/lab_*` (6), `env/doorframe_lab.png`, `env/door_lab.png` | 8 | Lab walls, tiles, ledge, tanks | Ansimuz Sci-Fi Lab | Custom permissive (see above) | yes |
| `env/library_*` (4), `env/doorframe_library.png`, `env/door_library.png` | 6 | Library walls, tiles, ledge, bookcase | Metroidvania Library Asset Pack | **Licence text not recorded** | not yet |
| `env/doorframe_boss.png`, `env/door_boss.png`, `env/doorframe_save.png`, `env/door_save.png` | 4 | Special doors | Built by `tools/build_world.py`; the exact source pictures are not recorded | **unknown** | not yet |
| `env/save_room.png`, `env/save_room2.png` | 2 | The two save-room pictures | Built by `tools/build_save_rooms.py` from our save-room concept pictures | Ours; origin of the concept pictures not recorded | not yet (confirm origin) |
| `fx/burst_*` | 8 | Explosion | Ansimuz Explosion Pack 1 | CC0 | yes |
| `fx/spark_*` | 8 | Spark | Ansimuz Magic Pack 9 | Ansimuz art-pack licence: use allowed, **not as a stand-alone asset download** | yes, inside a game build only |
| `fx/slash_*` | 3 | Cyan slash | Drawn by script for the sandbox prototype | Ours | yes |
| `fx/wave_00.png` | 1 | Blade wave | `SOURCES.md` says: edited from the earlier CC0 heroine attack frame by `tools/build_stage1b.py`. Not re-checked after the heroine changed. | CC0 if the note is still true | not yet (re-check) |
| `audio/sfx/` files named `made_*` and `footstep/soft_tap.wav` | 10 or so | Soft sounds generated for this prototype | Made in this project | Ours | yes |
| `audio/sfx/` from Super Grotto Escape (for example `land_thud.wav`, `door_creak.wav`, `shock_hit.wav`) | see `audio/SOURCES.md` | Sound effects | Ansimuz, Super Grotto Escape Godot project | MIT, © 2022 Luis Zuno. **Keep the licence notice with the game.** | yes, with the notice |
| `audio/sfx/` from metroidvania-godot-4 (for example `step_scuff.wav`, `jump_short.wav`, `ui_move.wav`) | see `audio/SOURCES.md` | Sound effects | Heart Gamedev | MIT, © 2023 Heart Gamedev LLC. **Keep the licence notice with the game.** | yes, with the notice |
| `audio/sfx/` from Gothicvania cemetery and town (for example `jump_soft.ogg`, `attack_swish.ogg`, `kill_pop.ogg`, `ui_confirm.ogg`) | see `audio/SOURCES.md` | Sound effects | Ansimuz | CC0 | yes |
| `audio/music/cavern_loop.ogg`, `room.ogg`, `cyberpunk_city_2.ogg`, `magic_cliffs.ogg` | 4 | Music | Ansimuz (warped, cyberpunk-street, cyberpunk city 2, Magic Cliffs) | CC0 | yes |
| `audio/music/boss.ogg`, `boss_battle_room.ogg` | 2 | Music | Ansimuz TinyRPGMusic | "Personal or commercial projects, credit not required" | yes |
| `audio/music/battle_encounter.ogg`, `battle_encounter_2.ogg`, `boss_battle.ogg`, `save_room.ogg` | 4 | Area music | Copied from `references/` by `tools/build_world.py` ("the area music the user supplied") | **unknown** | not yet |
| `audio/events.json`, `frames.json`, `SOURCES.md`, `audio/SOURCES.md` | 4 | Settings and notes | Written in this project | Ours | yes |

## What this means for the art replacement queue

1. **Heroine** (`hero/`): replace fully. This is the only "no" inside the game build. Tonight's sprint works on it; check `production/session-state/active.md` for the result.
2. **Four music tracks** with unknown origin: ask the user where they came from, or swap them for the CC0 tracks already in `audio/music/`.
3. **Library pack and WereWolf pack**: find the licence text (itch.io page or the download folder) and record it in `assets/LICENSE-MANIFEST.md`.
4. **Boss** (`mini-boss.png`): ask the user where the picture came from.
5. **Our own concept pictures**: write down how each was made (drawn, generated, with which tool) so the licence line can say "ours" without a question mark.

## Not checked

- No file was opened to look at or listen to. Rows marked "yes" rest on the written notes, not on a fresh check of each file.
- Sound effect counts per pack were not totalled; the full per-file list is in `prototypes/feel-v3/assets/audio/SOURCES.md`.
- `hero_v2/` and `hero_3d/` were empty or missing when this was written.
