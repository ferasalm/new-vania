# PROTOTYPE - NOT FOR PRODUCTION
# Feel v3 — stage 1: the body

Date: 2026-11-16 · Status: **in progress — waiting on the user's playtest verdict**

## In plain words

This is a small playable test with two rooms. It exists to answer one question:
**does the heroine feel good to move and fight with?** Nothing else is being judged
yet. The heroine and the enemies are stand-in art from packs we own; Pandora's own
animated art comes after the feel is approved.

It replaces prototype v2 (`prototypes/sandbox/`), which the user played and rejected.
The reasons are recorded in `production/playtests/VERDICTS.md`.

## How to play

Double-click `play.cmd` in this folder. Or run:

```
"C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64.exe" --path prototypes/feel-v3
```

| Key | What it does |
|---|---|
| `A` / `D` (or arrows) | run left / right |
| `K` (or Space) | jump — hold for a high jump, tap for a short hop |
| `J` and `I` | attack — alternate the two for faster chains; works in the air |
| `L` (or `Q`, Shift) | backdash |
| `S` + `K` | drop down through a thin ledge |
| `F1` | the tuning panel |
| `R` | restart from the first room |

The keys match the user's emulator layout (K = B, J = Y, I = X, L = A, Q = L).
A gamepad also works (A jump, X / Y attack, B or left shoulder backdash).

## The tuning panel (F1)

Sliders for every feel number: run speed, jump power, gravity, short hop, backdash,
attack length, chain speed, reach, hit pause, screen shake, enemy speed. Drag one and
the game changes at once. Point at a slider to read what it does. **Save** writes the
values to `tuning.json`; **Reset** goes back to the last saved values.

## What is in it

- Room 1: a long hall with ledges at three heights, two hell-hounds, one ghost, and a
  door on the far right.
- Room 2: a tall room you climb by ledges, two hounds and two ghosts.
- The hound flashes orange, then charges. The ghost drifts through walls toward you
  and backs off after it touches you.
- A hit makes the heroine flinch for a fifth of a second. There is no knockdown.
- Enemies come back when you re-enter a room.

## What is not in it yet

Stage 2 (more rooms, demons and machines), stage 3 (the boss, with counter as an
optional bonus) and stage 4 (writing the approved numbers into the design documents).
The heroine has no crouch and no backdash picture of her own (it reuses a jump frame).

## For developers

- All feel numbers live in `tuning.json`. Rooms are text grids in `rooms/*.txt`
  (legend at the top of `room.gd`).
- Self-test: `godot --headless --path prototypes/feel-v3 res://smoke.tscn` prints
  18 checks and `SMOKE PASS`. Add `-- shots` without `--headless` to save screenshots
  to `shots/`.
- Art is copied in by `tools/build_assets.py` (sources in `assets/SOURCES.md` and
  `assets/audio/SOURCES.md`). Sprites and sounds load as raw files, so there is no
  import step.
- Sounds were chosen by file name and length, not by ear. `backdash` and `door` are
  weak fits; re-pick them after the playtest.

## Findings

None yet. To be filled in from the user's verdict.
