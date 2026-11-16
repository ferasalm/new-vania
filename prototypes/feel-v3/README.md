# PROTOTYPE - NOT FOR PRODUCTION
# Feel v3 - the mini game (4 rooms, a save room, a boss)

Date: 2026-11-16 - Status: **waiting on user** (built, self-test 40/40, not yet played by the user)

## In plain words

A small version of the whole game. You walk through a ruined church, climb a haunted
library, rest in a save room, cross a cold lab past a big brute, open a special door and
fight a boss. Each place has its own look and its own music. Doors sit in the edge of the
room: walk up, the door slides open, walk off the screen.

## How to play

Double-click `play.cmd`. The first time it builds Pandora's frames from the reference
sheet in `assets/references/` (they are not stored in the repository, see "Art").

| Key | What it does |
|---|---|
| `A` / `D` | run |
| `K` (or Space) | jump - hold for high, tap for a hop |
| `J` and `I` | attack - right hand, left hand; alternate for faster chains; works in the air |
| `S` | crouch; `J` or `I` while crouching is a low attack |
| `W` + `J` | the special: a blade wave (costs MP) |
| `L` (or `Q`, Shift) | backdash |
| `E` (or Tab) | swap weapon: Dirge-042 (fast short sword) / Elegy-013 (slow, strong scythe) |
| `W` at the terminal | save room: heal fully and save |
| `S` + `K` | drop through a thin ledge |
| `1`-`5` | tester shortcut: jump to church, library, save room, lab, boss |
| `F1` | tuning panel (every number, every sound, each area's music) |
| `R` | restart (from the save room once you have saved) |

## The rooms

1. **The Nave of Ash** (church): hounds and ghosts.
2. **The Unread Stacks** (library): a climb, five storeys, with winged choirs and spitters.
3. **Cache Station 002** (save room): the terminal.
4. **Specimen Hall** (lab): catwalks over machines, then the warden, then the boss door.
5. **The Pallbearer** (boss).

## The enemies - each has two attacks and two ways of moving, and blinks orange first

- **Hound**: walks a beat; charges along the floor, or pounces when you are high or far.
- **Ghost**: drifts through walls at you; vanishes, reappears behind you and shrieks.
- **Choir**: hovers out of reach; throws three feathers, or dives through you.
- **Spitter**: sits and lobs arcing shots; sprays a burst if you hug it; hops to a new spot.
- **Warden**: walks you down; lunges with its claws, or leaps and sends two waves along the floor.

## The boss - its attacks are your stairs

The Pallbearer floats too high to hit. Its two golden hands fight for it. A hand that
slams the floor stays stuck for about three seconds: stand on it, jump, and cut the body.
Hitting a hand hurts it only a little. It also slides a hand along the floor (jump it)
and throws golden bolts (crouch under the high ones, jump the low ones). Under half
health it gets faster and claps both hands together where you stand.

## Art

- **Pandora**: `tools/build_pandora.py` recolours the user's Order of Ecclesia reference
  sheet by colour role (silver-white hair, near-black suit, cyan lines, dark scarf) into a
  complete Pandora sheet (`assets/hero/pandora_sheet.png`, every pose of the source) and cuts
  the game's animations from it. **These poses are traced from a commercial game, and this
  repository is public, so `assets/hero/` is git-ignored: placeholder only, to be redrawn
  before anything is shown outside.**
- **Weapons**: cut down from the Dirge-042 and Elegy-013 concept pictures to game size. The
  weapon is its own sprite: it appears in the swinging hand, sweeps, is held out at the end
  of the cut, then fades. No attack frame can be cropped any more.
- **Places, doors, boss, extra enemies**: `tools/build_world.py` (library pack, lab pack, the
  save-room picture, the mini-boss picture), then `tools/aseprite_correct.py`.
- Numbers: `tools/add_tuning.py` added 46 sliders (enemies, boss, doors) to `tuning.json`.
- The older tools (`build_assets.py`, `build_stage1b.py`, `bake_pandora.py`,
  `bake_weapons.py`) made the previous heroine and are no longer part of the build.

## Self-test

`godot --headless --path prototypes/feel-v3 res://smoke.tscn` prints 40 checks and
`SMOKE PASS`. Add `-- shots` without `--headless` to save screenshots to `shots/`.

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

