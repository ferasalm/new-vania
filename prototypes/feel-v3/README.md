# PROTOTYPE - NOT FOR PRODUCTION
# Feel v3 - the mini game (6 rooms, two save rooms, a boss)

Date: 2026-11-16 - Status: **in progress** - patch on branch feat/proto-v3-patch (hits, wall latch, two save rooms, SYSTEM OFFLINE, phone controls)

## In plain words

A small version of the whole game. You walk through a ruined church, climb a haunted
library, rest in a save room, cross a cold lab past a big brute, rest in a second save room, then open a special door and
fight a boss. Each place has its own look and its own music. Doors sit in the edge of the
room: walk up, the door slides open, walk off the screen.

## How to play

Double-click `play.cmd`. The first time it builds Pandora's frames from the reference
sheet in `assets/references/` (they are not stored in the repository, see "Art").

| Key | What it does |
|---|---|
| `A` / `D` | run |
| `K` (or Space) | jump - hold for high, tap for a hop |
| `K` at a wall, holding toward it | wall grip (needs the GRIP SERVOS relic): she clings and slides slowly. Press `K` again to kick up and away |
| `J` and `I` | attack - right hand, left hand; alternate for faster chains with Dirge-042 (with Elegy-013 both keys do the same heavy cut); works in the air |
| `S` | crouch; `J` or `I` while crouching is a low attack |
| `W` + `J` | the special (Up + Attack): a blade wave with Dirge-042 (costs MP); the Requiem with Elegy-013 |
| `L` (or `Q`, Shift) | backdash |
| `E` (or Tab) | swap weapon: Dirge-042 (fast short sword) / Elegy-013 (slow, strong, two-handed scythe) |
| `W` at the brain cache station (middle of a save room) | heal fully and save |
| `S` + `K` | drop through a thin ledge |
| `Esc` or `P` | pause menu (Start on a gamepad). The music holds and goes on from the same spot |
| `1`-`6` | tester shortcut: jump to church, library, cache 002, lab, cache 003, boss |
| `F1` | tuning panel (every number, every sound, each area's music) |
| `R` | RECONSTRUCT: the same as after a defeat, but without dying |

## On an Android phone

The shareable build is `build/android/new-vania-feel-v3.apk` (debug-signed, arm64). Copy it
to the phone, open it, allow "install unknown apps" for the app you opened it from, and
install. The game locks to landscape. Full install/build notes: `ANDROID.md`.

Touch controls (the prototype's take on `design/gdd/input-control-mapping.md`). The buttons sit in a diamond under the right thumb, like Bloodstained: Ritual of the Night on a phone: ATK on the left, JUMP at the bottom, BACK on the right, SPEC on top, and SWAP lower left of them. Pause is in the top-right corner.

- **Left 42% - floating stick.** It appears where your thumb lands. Push down and hold
  90 ms to crouch. Flick back, release, flick back again to backdash. The stick can also be set to "fixed" (see Pause > CONTROLS).
- **ATK** (attack) - one button; it alternates the hands, so the fast two-hand chain is still
  there. Largest and innermost, as the GDD asks.
- **JUMP** - hold for a high jump, tap for a hop. At a wall, with the stick held toward it, JUMP makes her cling (needs the GRIP SERVOS relic); JUMP again kicks her away.
- **SPEC** - the special (keyboard's Up + Attack): a blade wave with Dirge-042, the Requiem with Elegy-013.
- **SWAP** - Dirge-042 / Elegy-013.
- **BACK** - the accessibility direct backdash press.
- **CACHE bubble** - appears at the brain cache station; tap it to heal and save.
- **Pause** (top-right corner) - resume, restart, or jump straight to one of the six rooms. It also has RECONSTRUCT and QUIT.
- **Pause > CONTROLS** - drag any button or the stick to a new place. Tap a button, then SMALLER / BIGGER sets its size and FAINTER / SOLID how see-through it is. Switch the stick between "floats" (appears under the thumb) and "fixed". RESET goes back; DONE saves. The layout is remembered on the phone.

The keyboard and gamepad still work; the touch layer only appears on a phone, a
touchscreen, or when launched with `--touch`.

## The rooms

1. **The Nave of Ash** (church): hounds and ghosts.
2. **The Unread Stacks** (library): a climb, five storeys, with winged choirs and spitters.
3. **Cache Station 002** (save room): two capsules on the left (one holds a sleeping body, the one next to it is empty), the brain cache station in the middle (stand there and press W, or tap CACHE, to heal and save), and the terminal on the right.
4. **Specimen Hall** (lab): catwalks over machines, the GRIP SERVOS relic, then the warden (the mini boss).
5. **Cache Station 003** (save room): the same layout as 002, with violet light and amber warning lamps.
6. **The Pallbearer** (boss).

In both save rooms her feet now stand on the painted floor. Before, she floated above it.

## The wall grip (GRIP SERVOS)

A relic in the lab, "GRIP SERVOS", gives her the wall grip. It is found before the warden
(the mini boss). Jump at a wall and hold toward it: she clings and slowly slides. Press
jump again: she kicks up and away. The grip lasts about 1.2 seconds, then gives out. A tall
wall right after the relic needs it.

Five sliders on the F1 panel: how long she holds, slide speed, wall-jump height, push away,
and "no-steer time".

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

## Weapons, hits and the special attack

**Hits follow the weapon you see.** A cut lands exactly where the weapon picture passes:
from her hand to the tip, through the whole swing. That includes enemies above her or on
higher ground. Three sliders on the F1 panel, WEAPONS page, set this:

- "Weapon reach vs. the picture": 1.0 is exactly what you see.
- "Hit forgiveness": extra help for near misses, in pixels. 4 by default.
- "Show hit areas": set to 1 to draw where the blade cuts in yellow, what can be hit in
  red, and her own box in green.

The old "reach" sliders are gone.

**Dirge-042** (fast short sword): J and I alternate for faster chains. Its special is the
blade wave (15 MP).

**Elegy-013** (slow, strong, two-handed scythe): J and I do the same single heavy cut. There
is no speed bonus for alternating. It does twice the damage of Dirge-042 and costs 1.5 times
as much energy. The sliders are "Elegy: damage x Dirge" and "Elegy: energy x Dirge". Its
special is the Requiem: the scythe spins round her twice and cuts everything near her up to
four times (25 MP by default).

**The special** is Up + Attack (`W` + `J` on the keyboard). MP is taken only at the moment
the special really goes off. Being hit no longer cancels it (she still loses HP). Landing
from a jump no longer cancels it either.

## Death: SYSTEM OFFLINE

When her health runs out, the picture turns grey and breaks up. Two choices appear:
RECONSTRUCT and QUIT. Pick one with W/S, then J or K, or tap it.

RECONSTRUCT builds a new Pandora in the empty capsule of the last save room she cached in.
If she never cached, it is the church start. She steps out with full bars.

Her name is shown at the top left, above the bars. It counts up each time: PANDORA-001, then
PANDORA-002, and so on. The R key does the same without dying.

## Art

- **Pandora**: `tools/build_pandora.py` recolours the user's Order of Ecclesia reference
  sheet by colour role (silver-white hair, near-black suit, cyan lines, dark scarf) into a
  complete Pandora sheet (`assets/hero/pandora_sheet.png`, every pose of the source) and cuts
  the game's animations from it. **These poses are traced from a commercial game, and this
  repository is public, so `assets/hero/` is git-ignored: placeholder only, to be redrawn
  before anything is shown outside.**
- **Pandora redraw (planned, not started)**: the heroine frames in the game are still the ones traced from Order of Ecclesia. New original frames, drawn only from our own base picture (`assets/references/pandora-001-sprite.jpg`), are the next job. A first attempt on 2026-11-16 was stopped before it produced any frames.
- **Weapons**: cut down from the Dirge-042 and Elegy-013 concept pictures to game size. The
  weapon is its own sprite: it appears in the swinging hand, sweeps, is held out at the end
  of the cut, then fades. No attack frame can be cropped any more.
- **Places, doors, boss, extra enemies**: `tools/build_world.py` (library pack, lab pack,
  the mini-boss picture), then `tools/aseprite_correct.py`.
- **Save rooms**: the save-room pictures (both rooms) are built by `tools/build_save_rooms.py`.
- Numbers: `tools/add_tuning.py` added 46 sliders (enemies, boss, doors) to `tuning.json`.
- The older tools (`build_assets.py`, `build_stage1b.py`, `bake_pandora.py`,
  `bake_weapons.py`) made the previous heroine and are no longer part of the build.

## Self-test

`godot --headless --path prototypes/feel-v3 res://smoke.tscn` prints the checks (self-test: see the latest run) and
`SMOKE PASS`. Add `-- shots` without `--headless` to save screenshots to `shots/`.

## The three bars (stage 1b)

- **HP** (sand): her health.
- **EN, Energy** (green): every attack and backdash spends some. It refills by itself after a
  short rest. With too little Energy the attack does not come out and the bar blinks red. With Elegy-013 the attacks cost 1.5 times as much.
- **MP** (blue): only the special spends it, and only when it really goes off. Defeated enemies sometimes leave a blue orb that
  flies to her and gives MP back. With too little MP, Up + Attack is a normal swing.

## The tuning panel (F1)

Three pages: **FEEL** has a slider for every feel number — run speed, jump power,
gravity, short hop, backdash, attack length, chain speed, hit pause, screen
shake, enemy speed, and since stage 1b the crouch height, the Energy and MP amounts
and costs, the special attack and the orbs (how long an orb hangs before flying to
her is a slider too). **WEAPONS** picks the weapon in hand and sets the two-handed
feel, and holds the three hit sliders (see the weapons section above). Drag a slider and the game changes at once. Point at a slider to read what it
does.

The **SOUNDS** page lists each moment that makes a sound and the music. `<` and `>`
try the other options for that moment and play them; the two small sliders are its
loudness and its pitch variety (how much each repeat differs). The two-handed weapon
has its own swing sound ("Heavy swing"). Options named "made ..." are soft sounds
generated for this prototype.

**Save** writes the feel values to `tuning.json` and the sound choices to
`assets/audio/events.json`; **Reset** goes back to the last saved feel values and sound choices. After a
playtest, `git diff` on those two files shows exactly what the user chose.

