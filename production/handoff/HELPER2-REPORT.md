# Helper 2 report (feel-v3: climb, screens, touch, HUD)

Status words: done | in progress | planned | not run.
All numbers below are measured in the running game (Godot 4.7.2 headless), none are hand calculation.

## 1. Lab wall climb - baseline measured (done), fix (in progress)

Test: `prototypes/feel-v3/climb_test.gd` + `climb_test.tscn` (new files).
Run from the worktree root (16 s with `--fixed-fps 60`, about 2 min without it, so keep the flag):

    timeout 110 <godot> --headless --fixed-fps 60 --path prototypes/feel-v3 res://climb_test.tscn

Options after `--`: `verbose`, and any `<tuning_key>=<number>` to try numbers without touching tuning.json.
Note: `Engine.time_scale` must not be used to speed a test up; it stretched the physics step (measured: slide 6x too fast).

How it plays: holds the direction toward the wall the whole time, jumps from the floor next to the wall,
and after every latch waits "gap" frames, then holds jump for "hold" frames.

Baseline, tuning.json as it is (wall 8 tiles = 128 px; raw output in `production/handoff/helper2-climb-baseline.txt`):

| side | jump held | gap after latch | over? | time | wall jumps | peak / needed |
|---|---|---|---|---|---|---|
| left | 6 f | 10 f | yes | 5.07 s | 8 | 150 / 128 |
| left | 6 f | 15 f | yes | 6.40 s | 9 | 146 / 128 |
| left | 6 f | 20 f | yes | 7.90 s | 10 | 139 / 128 |
| left | 6 f | 30 f | NO | - | 10 (10 s limit) | 103 / 128 |
| left | 12 f | 10-30 f | yes | 2.22-3.22 s | 3 | 138-156 / 128 |
| left | 20 f | 10-30 f | yes | 1.95-2.55 s | 2 | 149-163 / 128 |
| right | 6 f | 10 f | yes | 5.07 s | 8 | 150 / 128 |
| right | 6 f | 15 f | yes | 6.40 s | 9 | 146 / 128 |
| right | 6 f | 20 f | yes | 7.90 s | 10 | 139 / 128 |
| right | 6 f | 30 f | NO | - | 10 (10 s limit) | 103 / 128 |
| right | 12 f | 10-30 f | yes | 2.32-3.22 s | 3 | 138-160 / 128 |
| right | 20 f | 10-30 f | yes | 1.95-2.55 s | 2 | 149-163 / 128 |

Verdict: **CLIMB FAIL** for players who tap jump. Holding jump 12 frames or longer is comfortable (2-3 wall jumps).
A 6-frame tap gains only about 13 px per wall jump (verbose log: latch heights 31, 45, 58, 71 ...), so it takes
8-10 wall jumps and fails outright with a 30-frame gap.
Cause (seen in the log, and in player.gd line 258): letting go of jump cuts the rise to `jump_cut` (0.4) for wall jumps too.

Fix options are being measured now; see section 1b below when it appears.

## 1b. Climb fix - measured (done; lead must apply the player.gd lines)

Three options measured with the same test (24 tries each: 2 sides x hold 6/12/20 f x gap 10/15/20/30 f):

| option | tries failed | most wall jumps | 6-frame tapper | verdict |
|---|---|---|---|---|
| as it is now | 2 of 24 | 10 | 8-10 wall jumps, 5.1-7.9 s, fails at 30 f gap | CLIMB FAIL |
| **A. a wall jump is never cut short by letting go of jump** (`-- nocut`) | 0 | 3 | 2 wall jumps in 1.60-1.73 s (slow), 3 in 2.65-3.37 s (sloppy) | **CLIMB PASS** |
| B. `wall_jump_velocity` 300 -> 420 (slider maximum), nothing else | 0 | 4 | 3 wall jumps 2.2-2.7 s, 4 at 30 f gap | CLIMB PASS, but a held wall jump then out-jumps a floor jump |
| `wall_jump_velocity` 360 | 0 | 6 | 4-6 wall jumps | CLIMB FAIL |

Raw output of A: `production/handoff/helper2-climb-nocut.txt`. Recommended: **A**. The room (rooms/lab.txt) is left unchanged:
with A every timing gets over in 2-3 wall jumps from both sides, and a room-only fix cannot help a tapper
(a tapped floor jump only reaches 31 px, under 2 tiles).

The gate also holds (measured, relic not granted): full jumps from the floor peak at 65 px of the 128 px needed on both
sides; running jumps off the nearby ledges (columns 36, 42, 49 on the left, 68 on the right) all fail to get over.

### Exact lines for the lead - player.gd (option A)

1. Find the line
   `var _steer_lock := 0.0      # after a wall jump she cannot steer back at once`
   insert after it:
   `var _kicked := false        # rising from a wall jump: letting go of jump does not cut it short`
2. Find the line (4 tabs deep, in the "wall" state)
   `				_steer_lock = T.v("wall_jump_lock")`
   insert after it, same indent:
   `				_kicked = true`
3. Find the line
   `	_coyote = T.v("coyote_time") if on_floor else maxf(0.0, _coyote - delta)`
   insert after it:
   ```
   	if on_floor:
   		_kicked = false
   ```
4. Replace the line
   `	if Input.is_action_just_released("jump") and velocity.y < 0.0:`
   with
   `	if Input.is_action_just_released("jump") and velocity.y < 0.0 and not _kicked:`

How A was measured without editing player.gd: `-- nocut` sets `jump_cut` to 1 from the kick until she lands, which is
the same thing these four lines do. A run with the lines really applied (in a private copy) is noted below if it was done.

## 1c. The proposed lines really applied, and new self-test checks (done)

The four player.gd lines above were then applied for real, in memory only (the real script object's source is swapped
before the game loads; nothing on disk changes): `-- patched`. Result is identical to the `nocut` run:
24 of 24 tries get over, 2-3 wall jumps, 1.60-3.37 s, gate holds, **CLIMB PASS**
(`production/handoff/helper2-climb-patched.txt`).

    timeout 110 <godot> --headless --fixed-fps 60 --path prototypes/feel-v3 res://climb_test.tscn -- patched

New self-test checks for smoke.gd (3 checks, 60 lines):
- anchor line in smoke.gd: `	_check("the latch gives out by itself", p.state != "wall", "state=%s" % p.state)`
- insert after it: the whole content of `production/handoff/helper2-smoke-insert.txt` (tabs already right).

Measured with the normal self-test run through `climb_test_smoke.tscn` (smoke.gd + these lines, in memory):
- with the player.gd lines: **61 of 61 pass** ("tapping jump climbs the tall wall from the left / right in at most 4 wall
  jumps": 2 wall jumps, 98 frames each; "without the relic the tall wall stops her": reached 65 of 128 px).
- with today's player.gd (`-- smokeonly`): 59 pass, the 2 climb checks FAIL (9 wall jumps, 370 frames). So the new checks
  catch the problem, and they must go in together with the player.gd lines, not before.
- The normal self-test on disk, untouched: 58 of 58, 75 s real time (run 22:36).

To apply both in one go (checks every anchor first; tested on scratch copies, not run on the real files):

    python production/handoff/helper2_apply.py            (dry run)
    python production/handoff/helper2_apply.py --write    (writes player.gd and smoke.gd)

The single source for all proposed lines is `prototypes/feel-v3/climb_test_patch.gd`.
Tip for every helper: `--fixed-fps 60` runs the self-test in about 4 s instead of 75 s (same physics steps).

## 2c/2d/2e. Offline screen, CONTROLS editor, HUD - scripted checks (done headless 22:43; pictures: see section 3)

Test: `prototypes/feel-v3/shot_h2.gd` + `.tscn` (new). Pretend fingers go through `Input.parse_input_event`
(InputEventScreenTouch / ScreenDrag), the same road a real finger takes; buttons are pressed by a finger tap in their middle.

    timeout 100 <godot> --headless --fixed-fps 60 --path prototypes/feel-v3 res://shot_h2.tscn -- touch layout=h2_test.json
    (then the same line with  phase=2  added: a NEW process reads the saved layout back, then RESET, then removes the test file)

Result after my fixes: run 1 **36 of 36**, run 2 (the restart) **7 of 7**. The test uses its own layout file
(`user://h2_test.json`, removed at the end); the player's `touch_layout.json` is never touched (none exists on this machine).

What was really exercised by finger events:
- play: stick drag walks her (40 px in 20 frames); ATK tap swings.
- OFFLINE: Down key moves to QUIT; a finger tap on RECONSTRUCT rebuilds her (room=save, PANDORA-002).
- pause: corner button pauses; all 10 menu buttons on screen (lowest ends at y=187 of 216).
- editor: drag ATK to (200,100); BIGGER x2 + SMALLER x1 = radius 20 -> 22; tap JUMP then SMALLER = only JUMP 20 -> 18;
  drag stick to (100,120); FAINTER x2 = 1.00 -> 0.70; STICK: FLOATS -> FIXED; nothing written before DONE; DONE writes the file.
- restart (new process): file read back exactly; old ATK place does nothing, new place swings; fixed stick answers the
  first touch; moved pause button pauses; RESET restores every default and deletes the file.
- HUD, 7 situations (church with area name, lab with the long relic message 339 px wide, boss fight with boss bar and a
  message, save room, MEMORY CACHED, after a rebuild, the player's own layout): no two boxes overlap (bars, name, defeated,
  weapon, area name, message, boss name, boss bar, 6 touch buttons, stick, cache bubble), nothing off screen.

Bugs found by the first run and fixed in my files:
1. offline.gd: the two buttons were really 31 px tall, not 22, so RECONSTRUCT and QUIT overlapped by 3 px, and the picked
   button grew 2 px wider ("> RECONSTRUCT <" = 122 px in a 120 px button), so it twitched. Now 136 px wide, stacked by
   their real height: (124,110) and (124,147), 136x31 each.
2. touch.gd editor: the pause button could not be picked up at all (any press above y=24 was ignored). Now only presses
   on the editor's own button row are ignored; the pause button drags like the others.
3. touch.gd editor: a control could be dragged half off the screen (centre only kept 8 px in). Now the whole circle stays
   on screen and out from under the editor's button row; also when it is made BIGGER at an edge, and when a file is loaded.
4. touch.gd: new `layout=<file>` option (test only) so tests never write the player's layout file.

Still rough (not fixed): the stick has one size (SMALLER / BIGGER do nothing when the stick is picked, measured);
controls may be dragged on top of each other (nothing stops it).
