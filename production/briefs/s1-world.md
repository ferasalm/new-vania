# BRIEF: S1 World (proto v4 "area", session 1, after S2)

Revised 2026-11-19 by the Claude Code lead: S2 Interact is already merged, so your worktree holds
S0 + S2. Room count fixed to 15 (map.md and the locked test agree; contract 374 says 14 by mistake).
The two main.gd hint strings are already gone, so those t_world checks pass now.

You are implementing slice **S1 World** for `prototypes/feel-v3` (Godot 4.7.2, GDScript).
Work ONLY in the worktree given via --dir. Never run git commands; the lead reviews and commits.
You cannot run Godot or any command: return every file you create or change IN FULL, paths
relative to the worktree root (e.g. `prototypes/feel-v3/rooms/lab.txt`).

## Attached files (everything you may assume)
contract.md (whole - esp. sections S1 World, 2.8 Room file changes, 8 rulings), map.md (whole -
sections 2, 3, 4, 5 are your room authority), tests_v4/t_world.gd (LOCKED test = your
executable spec), room.gd, shift.gd, door.gd, props.gd, ambience.gd (the S0 first version you
now own), main.gd (for the two hook lines only), interact.gd (S2-owned: read it for
`register(node, kind, label, cb, reach)` / `unregister(node)`; do not edit it), tools/mirror_room.py, and today's room files
as format examples (church, library, shaft, hazard, vault, timemachine, boss).

## The locked test is the bar
Never edit anything under `tests_v4/`, nor smoke.gd, hazard_test.gd, climb_test.gd. If a test
expectation contradicts map.md or the contract, STOP and report; do not bend the code to a
guess and do not edit the test.
After S1, `res://tests_v4/t_world.tscn` must PASS (exit 0) EXCEPT these known later-slice
failures, which you leave failing and list in your report:
- the lab/lab_shift enemy-count checks that name trolley/orderly (S4 adds those machines),
- the banned strings "ITS HANDS ARE YOUR STAIRS" and "IT WILL NOT LET GO" print as expected
  notes until S5.
The strings "GRIP SERVOS ONLINE -" and "E (or SWAP)" are already absent; keep it so. You do not
touch main.gd beyond your two hook lines.
S2 files are not yours: interact.gd, loot.gd, pickup.gd, pickup_card.gd, repair.gd,
data/items.json, data/gear.json, tuning.d/items.json, assets/audio/events.d/items.json. In
data/enemies.json add only glyph fields; keep S2's drops entries exactly as they are.

## What S1 builds (contract S1; map.md is the room authority)
- **Rooms**: 15 rooms before the shift and 11 after, exactly as map.md sections 2 and 4 tables
  say (ids, tile sizes, exits with side/at/target/needs, enemies max 2 kinds, hazards,
  pickups, saves). Each shifted room is its own `<room>_shift.txt`; `vault_restored.txt` with
  its door to `arnetria`. `shaft_shift.txt` via tools/mirror_room.py. New glyphs per contract
  2.8: B bricked arch, `:` one-way shutter, digits 1-9 markers; enemy letters come from
  enemies.json glyph fields; the existing letters stay valid. KN holds a plain `wall_jump`
  ITEM marker until S6 (rooms_meta mark type item).
- **rooms_meta.json**: fill the before sheet (today's 10 rooms updated to the map.md tables),
  the full after sheet (11 rooms), restored = base before + arnetria. Keep cell_tiles [24,14].
  Every room: code, title, cell, entry, save, boss (where a boss spawns), respawn, music,
  exits, marks, decor (the cue entries). Exit kinds from the closed list.
- **Gates**: the lever door (CH/SH), the bars (Elegy's reach only), the cracked wall (3 hits,
  any weapon), the low tunnel (slide), the winch (stops every HZ trap for good), the three
  candles and the X door (3 candles open it), the one-way shutter (opens only from HZ~).
  Doors, levers, candles and the winch register with G.main.interact.
- **No hand-holding text (decision 17)**: delete the hint strings at props.gd:54
  ("Far below, a door grinds open."), door.gd:57 (the locked-door text incl.
  "UNTIL THE NEXT UPDATE") and room.gd's "LOCKED - UNTIL THE NEXT UPDATE". Replace with cues:
  door lamp red -> pale, chain run + distant boom, dust, cold air, candle flicker, claw marks
  (decor). Keep story lines (MEMORY CACHED, NO SIGNAL, LAID TO REST).
- **Backdrops**: room.gd must expose `backdrop_rects() -> Array[Rect2]` and the wall must cover
  the full room with no gap: church 1152 x 256 px, boss 480 x 224 px. Flat placeholder art is
  fine (the art pass comes later); the geometry must be right.
- **Library filter**: shift.gd mode 2 stops cubing the brightness; add
  `shift_library_strength` 0.45 (0-1, 0.05) and `mode_params(file_id) -> Dictionary` exposing
  a brightness value that is LINEAR in that strength (the test checks it is not strength^3).
- **Weak respawn (decision 18 / ruling 9)**: new respawn.gd - weak enemies (weak: true in
  enemies.json) come back while she stays in the room. `respawn.pending: Array`,
  `respawn.debug_tick(sec: float)`, `respawn.live_weak() -> int`. Returns out of her sight,
  never within `respawn_distance` 96 px, never more alive than the room started with, not in
  save/boss rooms or GA; a faint rattle `respawn_warning` 1.0 s before, then a
  `respawn_attack_delay` 1.0 s pause before its first attack; timers stop while paused;
  every other enemy returns on re-entry as today. Tuning key `weak_respawn_s` 10 (3-120, 1) -
  ruling 9 sets 10, not the contract's 25.
- **The shift**: `W.start_shift()` loads the `_shift` files (W.sheet "after");
  `W.end_shift()` loads `vault_restored` (sheet "restored") while levers/doors/bars/winch keep
  their state; rewards already taken stay taken; entering a room marks it visited (W.visited).
- **shift.gd interface**: set_room(file_id), restore(seconds) (awaitable, the tear runs
  backwards, colour drains in `shift_restore_time` 12 tolls), mode_params(file_id).
- **door/props interfaces**: door.lamp ("red"|"pale"|"off"), door.refuse(); props Candle
  (light(), lights a sconce on the X door, sets W.flag("candle_n"), n = 1, 2, 3), Winch,
  Shutter, Decor; ambience.cue(name, at).
- **tuning.d/world.json**: weak_respawn_s 10 (3-120, 1), respawn_warning 1.0 (0.35-2.5, 0.1),
  respawn_distance 96 (32-200, 8), respawn_attack_delay 1.0 (0-3, 0.1),
  shift_library_strength 0.45 (0-1, 0.05), shift_restore_time 12 (4-30, 1),
  lamp_blink 0.5 (0.2-1.5, 0.05). Same 6-field schema as tuning.json; never duplicate a key
  that exists in tuning.json or tuning.d/rpg.json.
- **assets/audio/events.d/world.json**: the cue sounds (door lamp, chain run, boom, dust,
  cold air, candle, rattle). Silent when a file is missing (audio.gd already behaves so).
- **main.gd hooks (ONLY these two lines)**: ROOMS comes from W.room_list("before") and ENTRY
  from the meta `entry` field. Nothing else in main.gd.

## Hard rules
- Match existing style: tabs, `# PROTOTYPE - NOT FOR PRODUCTION` header on new files, plain
  GDScript, values through T.v, no class_name on new scripts, no paid services, no art
  generation. Placeholder visuals are fine; geometry and data must be exact.
- Do not break what works: smoke.tscn must stay SMOKE PASS 135/135 and hazard_test/climb_test
  must still pass, WITHOUT edits to those files. Note: smoke.gd's room checks are ALLOWED to
  change room counts - but YOU still may not edit smoke.gd; if smoke fails because of the new
  room list, STOP and report (the lead re-locks an updated smoke check per contract 4.4.5).

## What the lead verifies after you return
- t_world.tscn PASS except the listed later-slice failures; smoke 135/135; hazard/climb pass;
  every room loads in every sheet; the diff touches only S1 owner files + the two main.gd lines.

## Report
End with: what you built, the exact t_world failures you left for later slices, and anything
open with a reason.
