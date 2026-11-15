# Prototype SFX — Selected Files (drop-in package)

Selected SFX for `prototypes/sandbox` (the three rooms + the menu), picked from the
licensed audio library. The wiring map is **WIRING.md** (event → file → bus → gain);
the honest gaps are **GAPS.md**. This file records *what was copied, from where, and
under which license*.

Branch: `feat/prototype-sfx-plan` · Date: 2026-11-16 · Owner: sound-designer

## The selection method — a documented constraint

**Nothing was listened to.** Selection was made by (a) filename semantics,
(b) `ffprobe` metadata (duration, channels, sample rate), and (c) `ffmpeg astats`
peak/RMS levels. **The user re-picks every file by ear at playtest** — these are
placeholders chosen for semantic and duration fit, not final sound design. The
per-event gain column in WIRING.md is data (one number per event), computed from the
measured peak of each file so the mix lands in a sane place before the ear pass.

## Where the files came from

The repo commits only `LICENSE` records under `assets/audio/<pack>/`; the pack
contents themselves are staged in the git-ignored `inbox/` tree until promotion
(`assets/LICENSE-MANIFEST.md` promotion rule). Every file below was **copied**
(bit-identical, MD5-verified, originals untouched) from the pack's inbox location.
Use authorization: **user decision D-ORCH-22** (all packs cleared, 2026-11-16).

## Per-file table

| File (under `selected/`) | Event (see WIRING.md) | Pack / source | License | Duration | Peak dBFS | Size |
|---|---|---|---|---|---|---|
| `duel/attack.ogg` | light hit | Gothicvania — cemetery demo `sounds/` (series entry) | CC0 (`assets/umbrella/Gothicvania/LICENSE`) | 0.285 s | −8.6 | 6.5 KB |
| `duel/shock.wav` | heavy hit | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.393 s | −0.2 | 33.9 KB |
| `duel/error.wav` | counter-clash | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.327 s | −0.7 | 28.2 KB |
| `duel/land.wav` | the 1200 ms knockdown | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.214 s | −3.2 | 18.5 KB |
| `duel/kill.ogg` | enemy defeat (supplemental) | Gothicvania — cemetery demo `sounds/` (series entry) | CC0 (`assets/umbrella/Gothicvania/LICENSE`) | 0.393 s | −7.0 | 7.5 KB |
| `duel/hurt.wav` | player hurt (supplemental) | metroidvania-godot-4-main `music_and_sounds/` | MIT © 2023 Heart Gamedev LLC | 0.374 s | 0.0 (clips) | 32.4 KB |
| `cache/open-terminal.wav` | terminal interact | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.315 s | −3.0 | 27.1 KB |
| `cache/pick-important.wav` | module grant (first ack) | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 1.015 s | −2.9 | 87.5 KB |
| `denial/open-door.wav` | boss door open | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 42.6 s file, audible 0–0.86 s | −13.7 | 3.67 MB |
| `denial/rise.ogg` | mini-boss title card | Gothicvania — cemetery demo `sounds/` (series entry) | CC0 (`assets/umbrella/Gothicvania/LICENSE`) | 0.441 s | −10.0 | 10.5 KB |
| `denial/beam.ogg` | Arnetria's ring sweep | Warped City — Phaser demo `assets/sounds/` (series entry) | CC0 (`assets/umbrella/Warped City/LICENSE`) | 0.422 s | −4.3 | 5.6 KB |
| `denial/Laser_Shoot.wav` | Arnetria's lifted ring | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.566 s | −3.8 | 48.8 KB |
| `denial/explosion.ogg` | the crack beat | Warped City — Phaser demo `assets/sounds/` (series entry) | CC0 (`assets/umbrella/Warped City/LICENSE`) | 0.723 s | −2.5 | 13.8 KB |
| `denial/unpause.wav` | phase release | metroidvania-godot-4-main `music_and_sounds/` | MIT © 2023 Heart Gamedev LLC | 0.272 s | −6.1 | 23.5 KB |
| `shared/death.wav` | death (SYSTEM OFFLINE) | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 42.6 s file, audible 0–2.03 s | −6.7 | 3.67 MB |
| `shared/alien.wav` | the offline hum (1000 ms) | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 3.528 s | −10.0 | 304 KB |
| `shared/powerup.wav` | revive | metroidvania-godot-4-main `music_and_sounds/` | MIT © 2023 Heart Gamedev LLC | 0.286 s | −6.0 | 24.8 KB |
| `shared/switch.wav` | designation stamp | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.335 s | −0.0 | 28.9 KB |
| `shared/click.wav` | menu move | metroidvania-godot-4-main `music_and_sounds/` | MIT © 2023 Heart Gamedev LLC | 0.076 s | −6.0 | 6.7 KB |
| `shared/topen.wav` | menu confirm | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.315 s | −3.0 | 27.1 KB |
| `shared/close-terminal.wav` | quit | Super Grotto Escape — Godot demo project `Audio/` | MIT © 2022 Luis Zuno | 0.315 s | −3.0 | 27.1 KB |

Total: 21 files, 8.1 MB. All files are **mono, 44.1 kHz** — WAVs are 16-bit PCM,
Ogg are Vorbis — matching SYS-04's one-shot import pins (ADR-0003 §10).

Inbox source paths (for the audit; originals stay in place):

| Pack | Inbox path |
|---|---|
| Super Grotto Escape (demo project) | `inbox/downloads/organized/projects/SGE_GODOT_PROJECT/SuperGrottoEscapeGodotProject/Audio/` |
| metroidvania-godot-4-main | `inbox/downloads/organized/projects/metroidvania-godot-4-main/music_and_sounds/` |
| Gothicvania (cemetery demo sounds) | `inbox/downloads/organized/projects/gothicvania-cemetery-files/gothicvania-cemetery-files/Assets/Phaser Demo/assets/sounds/` |
| Warped City (Phaser demo sounds) | `inbox/downloads/organized/projects/Warped City Phaser/Warped City Phaser/assets/sounds/` |

## License notes

- **MIT notices (required by the license, carried here for the copies):**

  > MIT License — Copyright (c) 2022 Luis zuno. Permission is hereby granted, free
  > of charge, to any person obtaining a copy of this software and associated
  > documentation files (the "Software"), to deal in the Software without
  > restriction, including without limitation the rights to use, copy, modify,
  > merge, publish, distribute, sublicense, and/or sell copies of the Software, and
  > to permit persons to whom the Software is furnished to do so, subject to the
  > following conditions: The above copyright notice and this permission notice
  > shall be included in all copies or substantial portions of the Software.
  > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  > IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  > FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  > AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  > LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  > OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  > SOFTWARE.

  > MIT License — Copyright (c) 2023 Heart Gamedev LLC. (Same grant and conditions
  > as above: copies and substantial portions carry the copyright and permission
  > notice; the Software is provided "AS IS", without warranty.)

- **Gothicvania and Warped City** (Luis Zuno / Ansimuz): CC0 — credit appreciated,
  not required; the credit line lives in `assets/CREDITS.md`.
- **Every file resolves to a recorded license** — no `provenance pending` pack is
  used in this selection. The seven pending rows in `assets/CREDITS.md` stay
  untouched by this package.

## Known quirks (recorded, not fixed)

- **`shared/death.wav` and `denial/open-door.wav` carry a ~40 s silent tail** after
  2.03 s / 0.86 s of audio (42.6 s files, ~3.67 MB each). They were copied
  **bit-identical** on purpose: the pack file stays auditable against the source
  hash, and WIRING.md makes the hard stop mandatory (2100 ms / 900 ms) so no voice
  slot is held by silence. A trimmed variant (~180 KB each) is a trivial follow-up
  if the repo should stay lean — a derived file would then lose the hash identity.
- **`duel/hurt.wav` peaks at 0 dBFS** (marginal clipping in the source). The wiring
  pulls it −5 dB; the user's ear pass may replace the file entirely.
- The five short SGE terminal-family beeps (`open-terminal`, `topen`,
  `close-terminal`, plus the unused `terminal`) are distinct files (MD5-verified) at
  the same length — likely pitch variants of one design. They are used as
  interact / confirm / quit — the ear pass should verify they actually differ.

## Considered and excluded

- **Sewers pack (`Sewers pack files/Assets/Sounds/`)** — has a `public-license.pdf`
  whose text is font-encoded and could not be extracted in this pass, and the pack
  is not a row in `assets/LICENSE-MANIFEST.md`. Per the manifest's own law ("no
  author, URL or license text … was guessed") its sounds (notably
  `player-death.wav`, 1.103 s) are **excluded**. If someone extracts the PDF text
  later, `player-death.wav` is the strongest replacement candidate for
  `shared/death.wav`.
- **GothicVania-town music (`rpg_village02_loop`)** — requires credit (Pascal
  Belisle) and has no role in this SFX pass. Avoided.
- **All music tracks in the nine `assets/audio/` packs** — out of scope: the brief
  is SFX for the sandbox events; no music selection was requested.
