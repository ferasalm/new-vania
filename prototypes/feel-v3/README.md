# PROTOTYPE - NOT FOR PRODUCTION
# Feel v3 — stages 1 and 1b (the body) and the weapons stage

Date: 2026-11-16 · Status: **in progress — stages 1 and 1b approved; weapons waiting on the user's playtest verdict**

## In plain words

This is a small playable test with two rooms. It exists to answer one question:
**does the heroine feel good to move and fight with?** Nothing else is being judged
yet. The heroine and the enemies are stand-in art from packs we own; Pandora's own
animated art comes after the feel is approved.

It replaces prototype v2 (`prototypes/sandbox/`), which the user played and rejected.
The reasons are recorded in `production/playtests/VERDICTS.md`.

## How to play

Double-click `play.cmd` in this folder. It finds Godot by itself (the `GODOT` variable if
set, then the workspace copy, then `godot` on the PATH). Or run Godot yourself with the
full path of this folder:

```
godot --path "<full path to>/prototypes/feel-v3"
```

| Key | What it does |
|---|---|
| `A` / `D` (or arrows) | run left / right |
| `K` (or Space) | jump — hold for a high jump, tap for a short hop |
| `J` and `I` | attack — `J` swings her right hand, `I` her left; alternate the two for faster chains; works in the air |
| `S` (or Down) | crouch — she gets shorter; `J` or `I` while crouching is a low attack |
| `W` + `J` or `I` (Up + Attack) | the special: a blade wave that flies forward and cuts through enemies; costs MP |
| `L` (or `Q`, Shift) | backdash |
| `S` + `K` | drop down through a thin ledge |
| `F1` | the tuning panel |
| `R` | restart from the first room |

The keys match the user's emulator layout (K = B, J = Y, I = X, L = A, Q = L).
A gamepad also works (A jump, X / Y attack, B or left shoulder backdash).

## Weapons (the new stage)

She carries **one** weapon, equipped in both hands, like the heroine of Order of
Ecclesia: the blade materializes in the hand that swings it and is gone after.
`J` is the right hand, `I` the left. She never holds two weapons; chaining `J` and
`I` is the same blade passing from hand to hand.

- **Dirge-042** (the starting short sword): quick swings, the fast `J`-`I` two-hit
  combo from stage 1.
- **Elegy-013** (the two-handed blade): slower, stronger, longer reach. One swing
  hits harder than one short-sword swing; the combo breathes slower too.

Switch between them on the **WEAPONS** page of the F1 panel — `<` and `>` pick the
weapon in hand, and the sliders set the two-handed feel (swing length, damage, reach,
Energy per swing, chain speed). The change applies at once, even mid-fight.

## The three bars (stage 1b)

- **HP** (sand): her health.
- **EN, Energy** (green): every attack and backdash spends some. It refills by itself after a
  short rest. With too little Energy the attack does not come out and the bar blinks red.
- **MP** (blue): only the special spends it. Defeated enemies sometimes leave a blue orb that
  flies to her and gives MP back. With too little MP, Up + Attack is a normal swing.

## The tuning panel (F1)

Three pages: **FEEL** has a slider for every feel number — run speed, jump power,
gravity, short hop, backdash, attack length, chain speed, reach, hit pause, screen
shake, enemy speed, and since stage 1b the crouch height, the Energy and MP amounts
and costs, the special attack and the orbs (how long an orb hangs before flying to
her is a slider too). **WEAPONS** picks the weapon in hand and sets the two-handed
feel. Drag a slider and the game changes at once. Point at a slider to read what it
does.

The **SOUNDS** page lists each moment that makes a sound and the music. `<` and `>`
try the other options for that moment and play them; the two small sliders are its
loudness and its pitch variety (how much each repeat differs). The two-handed weapon
has its own swing sound ("Heavy swing"). Options named "made ..." are soft sounds
generated for this prototype.

**Save** writes the feel values to `tuning.json` and the sound choices to
`assets/audio/events.json`; **Reset** goes back to the last saved feel values and sound choices. After a
playtest, `git diff` on those two files shows exactly what the user chose.

## What is in it

- Room 1: a long hall with ledges at three heights, two hell-hounds, one ghost, and a
  door on the far right.
- Room 2: a tall room you climb by ledges, two hounds and two ghosts.
- The two weapons above, switchable in the panel.
- The hound flashes orange, then charges. The ghost drifts through walls toward you
  and backs off after it touches you.
- A hit makes the heroine flinch for a fifth of a second. There is no knockdown.
- Enemies come back when you re-enter a room.

## What is not in it yet

Stage 2 (more rooms, demons and machines), stage 3 (the boss, with counter as an
optional bonus) and stage 4 (writing the approved numbers into the design documents).
Lament (the second two-handed weapon) and the ranged weapons come later.
The crouch, the low attack and the special are quick edits of the pack heroine's one
attack strip (`tools/build_stage1b.py`); the two-handed swings are the same strip
recoloured (`tools/build_weapons.py`); the backdash reuses a jump frame. All of it is
replaced when Pandora-001 is drawn.

## For developers

- All feel numbers live in `tuning.json`. Rooms are text grids in `rooms/*.txt`
  (legend at the top of `room.gd`).
- Self-test: `godot --headless --path prototypes/feel-v3 res://smoke.tscn` prints
  44 checks and `SMOKE PASS`. Add `-- shots` without `--headless` to save screenshots
  to `shots/`.
- Art is copied in by `tools/build_assets.py` (sources in `assets/SOURCES.md` and
  `assets/audio/SOURCES.md`). Sprites and sounds load as raw files, so there is no
  import step. Stage 1b stand-in frames are made by `tools/build_stage1b.py` and the
  two-handed swings by `tools/build_weapons.py` (run both after `build_assets.py`).
- Sounds were chosen by file name and length, not by ear. `backdash` and `door` are
  weak fits; re-pick them after the playtest.

## Findings

- 2026-11-16, stage 1: the user approved the feel (movement, jump, backdash, attack, chains)
  after tuning six values with the sliders, and rejected the sounds. Details and the saved
  values are in `production/playtests/VERDICTS.md`.
