# Audio sources — `prototypes/feel-v3/assets/audio/`

Self-contained SFX + music set for the feel-v3 prototype. Every external file below
was **copied** (originals left in place) from the Ansimuz / Heart Gamedev pack library
at `C:/Users/AUC/opencode-workspace/workspace/new-vania/inbox/downloads/organized/`.
The event → file map the game reads is `events.json`.

**Nothing was listened to.** Selection used filename semantics, `ffprobe` duration and
non-auditory signal statistics (spectral centroid, flatness, zero-crossing rate) to
separate impacts/thuds from airy whooshes and to screen out voices. Re-pick by ear at
playtest.

`.../organized/` = `C:/Users/AUC/opencode-workspace/workspace/new-vania/inbox/downloads/organized/`.
Licence PDFs for the `audio/` packs live in the library's `docs/<pack>/` sibling, not
inside the audio folder; the paths below point at the exact file read.

## SFX

| New name | Original full path | Pack | Licence (file read) | Duration | Note |
|---|---|---|---|---|---|
| `sfx/footstep/step_scuff.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/step.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.182 s | current; chosen |
| `sfx/footstep/soft_tap.wav` | `prototypes/feel-v3/assets/audio/sfx/land/made_soft_land.wav` (first-pass generated; copied) | project-local | no external licence | 0.100 s | soft tap alternative |
| `sfx/footstep/boot_thunk.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/topen.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.315 s | harder boot option |
| `sfx/jump/jump_soft.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/jump.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.331 s | current; chosen |
| `sfx/jump/jump_short.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/jump.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.140 s | short synth hop |
| `sfx/jump/jump_riser.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/rise.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.441 s | rising sweep |
| `sfx/land/land_thud.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/land.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.214 s | current; heavy thud |
| `sfx/land/made_soft_land.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.100 s | chosen; soft tap |
| `sfx/land/metal_land.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/open-terminal.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.315 s | metallic clank |
| `sfx/swing/attack_swish.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/attack.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.285 s | current; airy swish |
| `sfx/swing/made_light_swish.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.160 s | chosen; light cloth swish |
| `sfx/swing/made_low_swish.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.200 s | lower, heavier swish |
| `sfx/hit/made_soft_thud.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.140 s | chosen; soft body thud |
| `sfx/hit/made_tick.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.070 s | tiny high tick |
| `sfx/hit/shock_hit.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/shock.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.393 s | current; loud electric hit, kept as option |
| `sfx/hit/bullet_tap.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/bullet.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.336 s | short blip |
| `sfx/hurt/made_low_bump.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.200 s | chosen; low non-voice bump |
| `sfx/hurt/error_blip.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/error.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.327 s | damage buzzer |
| `sfx/hurt/shock_sting.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/shock.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.393 s | electric sting |
| `sfx/enemy_die/kill_pop.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/kill.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.393 s | current; chosen |
| `sfx/enemy_die/enemy_die_zap.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/enemy_die.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.504 s | noisy zap |
| `sfx/enemy_die/explosion_small.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/Explosion.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.348 s | small explosion |
| `sfx/enemy_die/explosion_tiny.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/explosion.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.183 s | tiny pop |
| `sfx/backdash/made_soft_whoosh.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.220 s | chosen; soft air whoosh |
| `sfx/backdash/made_quick_air.wav` | — (first-pass generated; no external source) | project-local | no external licence | 0.140 s | quick air cut |
| `sfx/backdash/rise_sweep.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/rise.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.441 s | current; tonal riser, kept as option |
| `sfx/door/door_creak.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/open-door.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.900 s | current; trimmed from 42.602 s to 0.9 s (creak 0–0.461 s + latch 0.749–0.877 s) |
| `sfx/door/terminal_clank.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/close-terminal.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.315 s | mechanical clank |
| `sfx/door/switch_latch.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/switch.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.335 s | latch click |
| `sfx/ui_move.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/click.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.076 s | unchanged |
| `sfx/ui_confirm.ogg` | `.../organized/projects/GothicVania-town-files/code/phaser-code/assets/sounds/switch.ogg` | GothicVania town (Ansimuz) | CC0 — `projects/GothicVania-town-files/public-license.pdf` (the music in that pack is credit-required per `projects/GothicVania-town-files/Music/readme.txt`; `switch.ogg` is a demo sound, not that music) | 0.115 s | unchanged |
| `sfx/special/magic_shot.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/Laser_Shoot.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.566 s | chosen; energy shot, audible only 0–0.125 s then silence |
| `sfx/special/magic_rise.ogg` | `.../organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/rise.ogg` | Gothicvania — cemetery demo (Ansimuz) | CC0 — `projects/gothicvania-cemetery-files/gothicvania-cemetery-files/public-license.pdf` | 0.441 s | rising tonal sweep (also a `jump` / `backdash` option) |
| `sfx/special/magic_charge.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/powerup.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.286 s | bright sustained shimmer |
| `sfx/pickup/coin_chime.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/Pickup_Coin.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.277 s | chosen; coin chime |
| `sfx/pickup/bright_blip.ogg` | `.../organized/projects/GothicVania-town-files/code/phaser-code/assets/sounds/switch.ogg` | GothicVania town (Ansimuz) | CC0 — `projects/GothicVania-town-files/public-license.pdf` | 0.115 s | short bright blip (same source file as `ui_confirm`) |
| `sfx/pickup/soft_chime.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/unpause.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.272 s | soft tonal blip |
| `sfx/no_energy/dull_click.wav` | `.../organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/switch.wav` | Super Grotto Escape (Ansimuz) | MIT © 2022 Luis Zuno — `projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/LICENSE` | 0.200 s | chosen; trimmed from 0.335 s (content ends at 0.115 s) |
| `sfx/no_energy/tiny_tick.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/click.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.076 s | tiny high tick (same source file as `ui_move`) |
| `sfx/no_energy/soft_denied.wav` | `.../organized/projects/metroidvania-godot-4-main/music_and_sounds/pause.wav` | metroidvania-godot-4-main (Heart Gamedev) | MIT © 2023 Heart Gamedev LLC — `projects/metroidvania-godot-4-main/LICENSE.txt` | 0.240 s | soft low blip; trimmed from 0.273 s with a 60 ms fade-out |

## Music

| New name | Original full path | Pack | Licence (file read) | Duration | Note |
|---|---|---|---|---|---|
| `music/cavern_loop.ogg` | `.../organized/projects/warped-files/Assets/Sound/platformer_level04_loop.ogg` | warped-files (Ansimuz) | CC0 — `projects/warped-files/public-license.pdf` | 78.6 s | chosen room default; darkest candidate (spectral centroid ≈ 1.2 kHz, ≈ 92 BPM) |
| `music/room.ogg` | `.../organized/audio/cyberpunk-street-files/Assets/music/cyberpunk-street.ogg` | cyberpunk-street (Ansimuz) | CC0 — `docs/cyberpunk-street-files/public-license.pdf` | 61.1 s | current; kept as option |
| `music/cyberpunk_city_2.ogg` | `.../organized/audio/Music/cyberpunk city 2.ogg` | cyberpunk city 2 files (Ansimuz) | CC0 — `docs/cyberpunk city 2 files/public-license.pdf` | 64.0 s | moody synth option |
| `music/boss_battle_room.ogg` | `.../organized/audio/TinyRPGMusic/BossBattle.ogg` | TinyRPGMusic (Ansimuz) | "use in personal or commercial projects… credit not required" — `docs/TinyRPGMusic/public-license.txt` | 66.0 s | tense, slow option |
| `music/magic_cliffs.ogg` | `.../organized/audio/Magic-Cliffs-Gamekit/Assets/magic cliffs music/magic cliffs.ogg` | Magic-Cliffs-Gamekit (Ansimuz) | CC0 — `docs/Magic-Cliffs-Gamekit/public-license.pdf` | 96.0 s | brighter fantasy option |
| `music/boss.ogg` | `.../organized/audio/TinyRPGMusic/Boss Fight 2.ogg` | TinyRPGMusic (Ansimuz) | "use in personal or commercial projects… credit not required" — `docs/TinyRPGMusic/public-license.txt` | 88.6 s | unchanged boss track |

## Loudness method

Each option was measured in place with:

```
ffmpeg -i <file> -af volumedetect -f null -
```

`gain_db = -26 - mean_volume` for SFX and `-30 - mean_volume` for music, clamped to
`[-12, +12]` and rounded to one decimal. `volume_db` is the event mix level
(`-12.0` footstep, `-10.0` hit, `-6.0` other SFX, `-8.0` music).

## Weak fits / caveats

- **`door`** — the only door in the library. It is 0.9 s (trimmed from a 42.6 s source
  whose body ends at 0.877 s), so it is the one option above the 0.7 s target; the
  brief's 0.9 s allowance covers it. The other two door options are mechanical
  clanks, not literal doors.
- **`footstep` / `land`** — the library has only one true footstep and one true
  landing thud. The extra options are a soft tap and mechanical clanks; audition them.
- **`backdash` / `swing`** — the library has no dedicated cloth whoosh; the three
  `made_*` noise swishes carry these events, with the old tonal riser kept only as a
  fallback option.
- **`hurt`** — the old `hurt.ogg` is a male voice and is **not** in `events.json`.
  It was removed from the prototype.
- **`enemy_die`** — `explosion_small` and `explosion_tiny` are literal explosions;
  they are alternatives, not the default (`kill_pop`).
- **`special` / `pickup` / `no_energy`** — the three events added for stage 1b. `special`
  options level to −26 dB mean. In `pickup` and `no_energy` the loudest option hits the
  brief's `gain_db` floor of −12.0 (`coin_chime` mean −8.5 dB, `dull_click` mean −9.9 dB),
  so those two sit roughly 4–5 dB above their siblings; audition by ear.
- **`pickup` / `no_energy` reuse two UI files** — `bright_blip` is the same source as
  `ui_confirm`, and `tiny_tick` the same as `ui_move`. They are options, not defaults.

## Excluded

- **Sewers pack** — no readable licence (`public-license.pdf` is font-encoded, not a
  licence row). Not used, same call as `assets/audio/selected/GAPS.md`.
- **`projects/Warped City Godot/Music/cyber_runner.ogg`** and **`projects/Warped City
  Phaser/assets/sounds/*`** — no licence file ships inside those pack folders.
- **`audio/Loose files/Magic Fx 7.ogg`** and **`audio/top-down-fantasy-1/*`** — no
  matching licence document in `docs/` or in the pack folder.
- **`GothicVania-town` music** (`rpg_village02__loop`) — credit-required (Pascal
  Belisle), not used.
- **`metroidvania-godot-4-main/music_and_sounds/hurt.wav`** — low, harmonic, voice-like
  profile (centroid 615 Hz, flatness 0.12); excluded from `hurt` to honour the
  no-voices rule.
