# PROTOTYPE - NOT FOR PRODUCTION
# Feel v3 - the mini game (10 rooms, two save rooms, a boss, a time machine)

Date: 2026-11-16 - Status: **in progress** - patch on branch feat/proto-v3-patch (hits, wall latch, two save rooms, SYSTEM OFFLINE, phone controls)

## In plain words

A small version of the whole game. You walk through a ruined church, climb a haunted
library, rest in a save room, cross a cold lab past a big brute, rest in a second save room, then open a special door and
fight a boss. Each place has its own look and its own music. Doors sit in the edge of the
room: walk up, the door slides open, walk off the screen.

Beating the boss gives you its scythe, Elegy-013, and a way back opens: a lever in the library
unseals the church's lower door, a long well leads up to a hidden station, and a ruined chapel
full of traps hides a machine. Switch the machine on and the world answers: the whole map is
drawn backwards and wrong, the rooms you knew change their doors, and the voices start.

## How to play

Double-click `play.cmd` (needs Godot 4.7.2), or run the standalone Windows build
`build/windows/new-vania-feel-v4.exe` (no Godot needed; rebuild it with
`godot --headless --path . --export-release "Windows Desktop" build/windows/new-vania-feel-v4.exe`).
Pandora's frames come from your own GIFs in `assets/sprites-pandora/`
(`python tools/build_pandora_v3.py` rebuilds them into `assets/2x/pandora/`).

| Key | What it does |
|---|---|
| `A` / `D` | run |
| `K` (or Space) | jump - hold for high, tap for a hop |
| `K` at a wall, holding toward it | wall grip (needs the GRIP SERVOS relic): she clings and slides slowly. Press `K` again to kick up and away |
| `J` and `I` | attack - right hand, left hand; alternate for faster chains with Dirge-042 (with Elegy-013 both keys do the same heavy cut); works in the air |
| `S` | crouch; `J` or `I` while crouching is a low attack |
| `W` + `J` | the special (Up + Attack): a blade wave with Dirge-042 (costs MP); the Requiem with Elegy-013 |
| `Q` (or `U`) / `L` (or `O`) | backdash to the left / to the right (she faces away from where she dashes) |
| `S` + `K` (Down + Jump) | slide; on a thin platform it drops through instead |
| `E` (or Tab) | swap weapon: Dirge-042 (fast short sword) / Elegy-013 (slow, strong, two-handed scythe). Does nothing until the boss has dropped the scythe and you have picked it up (the SWAP button on the phone is dim until then) |
| `W` at the brain cache station (middle of a save room) | heal fully and save |
| `S` + `K` | drop through a thin ledge |
| `Esc` or `P` | pause menu (Start on a gamepad). The music holds and goes on from the same spot |
| `1`-`6` | tester shortcut: jump to church, library, cache 002, lab, cache 003, boss |
| `7` `8` `9` `0` | tester shortcut: the marrow well, cache station 004, the threshing chapel, the organ of hours |
| `W` beside a lever or the machine | pull the library lever / switch on the time machine (it asks first: W or S picks YES or NO, `J` confirms) |
| `F1` | tuning panel (every number, every sound, each area's music) |
| `R` | RECONSTRUCT: the same as after a defeat, but without dying |

## On an Android phone

The shareable build is `build/android/new-vania-feel-v4.apk` (debug-signed, arm64). Copy it
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
- **<BD / BD>** - backdash to the left / to the right.
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
6. **The Pallbearer** (boss). Beating it leaves its scythe floating where it fell. Walk into it: Elegy-013 is yours.
7. **The Marrow Well** (shaft): reached from the church's lower left door, which stays sealed until you cut the lever in the library (it sits on the climb; press W beside it or cut it). A tall well with ledges every six tiles. A plain jump rises about four tiles, so a ledge is out of reach without the wall grip: latch the wall, kick up and away, land on the next ledge. At the top is a hole into the vault.
8. **Cache Station 004** (vault): a save room with a brain cache station and a terminal. The hole in its floor drops back into the well (and from the well the top opening leads up into it). Its left door leads on to the chapel. After the shift its right edge shows a locked special door: LOCKED - UNTIL THE NEXT UPDATE.
9. **The Threshing Chapel** (hazard room): long hall of swinging pendulums, crushers, flame vents and spike strips, with crabs, moths, scribes and leeches. Iron bars cut it in two; the lever that raises them sits behind the bars, out of reach of the short sword: only the long Elegy-013 cut reaches it (the blade wave never does). On the left end a cracked wall takes three cuts to break; behind it is a low tunnel only a slide fits through. Standing, she is stopped. The tunnel ends in the time machine room.
10. **The Organ of Hours** (time machine room): a dead pipe organ. Stand beside it and press W: THE MACHINE asks "Are you sure you want to activate this machine?" with YES and NO (NO is picked first). Choose YES.

In both save rooms her feet now stand on the painted floor. Before, she floated above it.

### After the shift

- The screen tears, flashes white, then settles into a rough, grainy picture. Each room has its own colour filter: red in the chapel, inverted and red in the library, sick green in the church, deep blue in the well, red and black in the vault, violet in the machine room.
- The ordinary music stops. A low drone runs, and every 8 to 20 seconds a whisper or a chant is heard.
- The library and the church are drawn mirrored. The way through changes: chapel, library (top left door), church (bottom left door), well, vault. The church's lower door is open.
- The terminals are dead: they say NO SIGNAL and neither heal nor save.
- Dying wakes her next to the machine. She is also saved there.
- The vault's right-hand special door cannot be opened yet.


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

Two attacks use the scythe it keeps (the same Elegy-013 you win from it). A hand lifts it,
glows orange, and a lane line shows the height. **The reap**: a huge slash crosses the room at
chest height (crouch or slide under it); every second reap is low (jump it). **The throw**: the
scythe spins across the room at one height and comes back at the other, so you duck one pass
and hop the other. The slash is drawn as a bright crescent, because the scythe picture is too tall to dodge by ducking.
When it dies, the scythe drops: you win Elegy-013. (Until then the E key does nothing.)

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
It also covers the new area: the sealed door and the lever, the well and its ledges, up and down between the well and the vault, the bars, the cracked wall, the slide-only tunnel, the YES/NO question, the shift, the mirrored rooms and the new boss attacks.

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

