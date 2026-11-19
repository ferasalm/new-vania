# S1 test rewrite: smoke.gd and climb_test.gd for the 15-room map

You are the test-writer (contract section 4.4, item 5). S1 changed the map on purpose. Rewrite ONLY the checks in
`prototypes/feel-v3/smoke.gd` and `prototypes/feel-v3/climb_test.gd` that the new map makes wrong. The user approved
this rewrite on 2026-11-19; the lead reviews every change before the tests are locked again.

## Source of truth
- `prototypes/feel-v3/design/map.md`: rooms, doors, exits, enemies, items, themes, music areas, the lab rebuild.
- `prototypes/feel-v3/design/contract.md`: hint strings removed by S1 (the four HARD_BANNED strings in
  `tests_v4/t_world.gd` line 31 must not appear in ANY .gd file, smoke.gd included), room data format.
- Expectations come from map.md and the contract, never from what the code happens to do. You may read room files
  and `main.gd` only to find positions and the debug helpers the existing smoke code already uses.

## What to rewrite (from the S1 run, log `tests_v4/logs/s1b_smoke.log`)
1. Line 83 "each of the five areas has its own music": the music areas map.md now defines.
2. Line 102 "nine enemy kinds are placed in the rooms": the kinds map.md places in the before sheet now
   (trolley and orderly arrive in S4; do not expect them yet).
3. Line 103 "every area has its own look": the number of themes map.md defines.
4. Lines 333-337 (the lab leads to save2; the wall-latch relic waits in the lab): map.md rebuilds the lab and moves
   GRIP SERVOS to KN. Check what map.md now says instead. Line 334 crashes today on `room.spawns["A"]`.
5. Line 643 (touching the scythe gives ELEGY-013) if S2's interact flow changed how the scythe is taken.
6. Line 674 ("Far below" toast) and line 985 ("UNTIL THE NEXT UPDATE"): these strings are banned now. Check the
   behaviour (the lever is pulled, the X door stays shut) and whatever toast the contract gives, without the
   banned text appearing anywhere in smoke.gd, not even in a check name or comment.
7. Line 1061 "the pause menu lists all ten rooms": the room count map.md gives.
8. The `_new_area()` walk-through (line 630 on): each step that assumes the old 10-room layout (the church's lower
   door, the library lever, shaft and vault, the ledges, the threshing chapel, the hazard bars and tunnel, the time
   machine and shift, the mirrored rooms after the shift, tester keys 7-0). Keep each step whose route still
   exists in map.md; re-route a step to the room map.md now gives for that feature; drop a step only when map.md
   removes the feature, and say so in the change log.
9. `climb_test.gd`: it looks for a tall wall and a thin ledge in `rooms/lab.txt`, which map.md rebuilds. Point it at
   the room map.md gives for the wall climb (or the tallest climbable wall map.md names), keeping its measurements
   and its pass rule (one wall latch per jump) unchanged.

## Rules
- Do not touch anything else: no game code, rooms, data, tuning, `tests_v4/*`, `hazard_test.gd`.
- Never loosen a check that is not about the map (movement, combat, damage, boss, save, UI). Keep check names
  where the meaning is unchanged.
- Keep `_check("sounds loaded", ...)` exactly as it is: the missing world sounds are a real S1 defect.
- A check that fails because the S1 code is wrong must stay failing. Do not bend a check to the code.
- Write every change to `prototypes/feel-v3/tests_v4/smoke-rewrite-s1.md`: old check (line) -> new check -> the
  map.md or contract line that justifies it. Dropped steps too.

## Run (from prototypes/feel-v3)
```
G="C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . --log-file tests_v4/logs/rw_smoke.log res://smoke.tscn
"$G" --headless --fixed-fps 60 --path . --log-file tests_v4/logs/rw_climb.log res://climb_test.tscn
```
Each quits by itself (allow 10 minutes). Smoke's summary line reads `SMOKE PASS|FAIL passed=N failed=M`.

## Pass condition
- smoke.gd and climb_test.gd contain none of the four banned strings.
- Smoke runs to its summary line with no SCRIPT ERROR; climb runs to its verdict.
- Every remaining failure is listed in the change log as "S1 code defect" (with the evidence) or "S3/S4 scope".

## Report (end of your answer)
1. The change log's table.
2. The summary line of each run.
3. Every remaining failure with your classification.
