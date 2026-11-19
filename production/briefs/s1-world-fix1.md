# S1 World: fix round 1

You are continuing S1 World in this worktree (branch `feat/proto-v4-s1`). Your first pass is committed as
`b36f2cf`. Read `production/briefs/s1-world.md` (the full S1 brief, unchanged) and `prototypes/feel-v3/design/map.md`
(the source of truth for rooms, doors, exits and enemy counts). Then fix the failures below.

## Rules (unchanged from the S1 brief)
1. Never edit `prototypes/feel-v3/tests_v4/`, `smoke.gd`, `hazard_test.gd` or `climb_test.gd`.
2. Never edit the S2 files: interact.gd, loot.gd, pickup.gd, pickup_card.gd, repair.gd, data/items.json,
   data/gear.json, tuning.d/items.json, events.d/items.json. In data/enemies.json add only `glyph` fields.
3. If a test expectation contradicts map.md or the contract, stop and report it; do not bend the code to a guess.
4. Gameplay values go in `tuning.d/world.json`, never hardcoded.

## Run the tests (from prototypes/feel-v3)
```
G="C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . --log-file tests_v4/logs/fix1_t_world.log res://tests_v4/t_world.tscn
"$G" --headless --path . --log-file tests_v4/logs/fix1_smoke.log res://smoke.tscn
```
Each test quits by itself (allow up to 10 minutes).
Near the end each log has a PASS or FAIL line with counts (`t_world FAIL 21/38`, `SMOKE FAIL passed=40 failed=4`). Every `FAIL` line names the check and the evidence.

## Failures to fix (t_world was 21/38 after pass 1)
1. **Crash, fix first.** `main.gd:229` sets `room.doors[side].sealed_msg`, but `door.gd` has no `sealed_msg`.
   This SCRIPT ERROR stops smoke at 40/44 and breaks several t_world checks. Give door.gd the property.
2. **No enemies spawn anywhere.** Smoke says "nine enemy kinds are placed in the rooms ([])" and every t_world
   count reads `got {}` (church, library, shaft_shift, church_shift ...). Enemy glyphs in the room files must
   spawn their enemies again, and data/enemies.json needs the `glyph` field per kind (contract section 2).
3. **Meta cells and exits missing for the after rooms.** "timemachine_shift / vault_shift / shaft_shift /
   lab_shift / arnetria no meta cell"; every after door shows `meta=false`. Add their entries to
   `data/rooms_meta.json` exactly as map.md gives them, with exits that match the room files both ways.
4. **Library size:** the room is 768 x 704 px but its meta cell is [32, 48, 2, 3]. Make the room file and the
   meta agree with map.md (the test compares round(width / 24) and round(height / 14) to the cell).
5. **Shift files:** "entering the church after the shift loads its _shift file (file_id=church)".
   After the shift every room with a `_shift` file must load it.
6. **Reachability after the shift:** all 10 unsealed rooms must be reachable from OR~ (now 9 are unreachable).
7. **Candles and the X door:** "2 candles leave the X door locked and 3 open it (xdoor=false two=true
   three_open=false)" and "AR needs the three candles (with 0=false with 3=false)". The vault_shift door to
   arnetria is `kind: "sealed_x"` and opens at 3 candles (contract 2.8).
8. **Restored vault:** "the restored vault loads with its door to AR (file_id=vault exit_to_arnetria=false)".
9. **Respawn:** "a weak enemy returns after the wait when she stays far away", "a moth does not return until
   she re-enters", "a paused tree does not advance the respawn timer". See respawn.gd and contract 2.9.
10. **Enemy counts (before, after, restored)** must match map.md for every room except the machine kinds.

## Known failures that are NOT yours (leave them; the lead handles them)
- Counts that need `trolley` or `orderly` (lab, lab_shift, gallery, kennel_shift): those kinds arrive in S4.
  Place every other kind in those rooms as map.md says.
- t_world line 352 does not list `sealed_x` among door kinds, so the `vault_shift right -> arnetria` door
  entry fails there. Keep the kind `sealed_x`; do not change it to pass the test.
- "the four S1 hint strings are gone from the scripts" fails only on `smoke.gd`; the lead rewrites smoke.gd.
- Smoke checks about the old 10-room layout (save2, the five music areas, the lab relic, the mirrored
  library, ROOM_LABELS) are rewritten by the lead. Do not edit smoke.gd.

## Pass condition
- t_world: every check passes except the three items in the list above.
- Smoke runs to its last line with no SCRIPT ERROR (its old-layout checks may still fail).
- t_data 44/44, t_math 11/11, t_rpg 33/33 stay green; t_interact_ui stays at 23/36 or better.

## Report (at the end of your answer)
1. What you changed, per failure number above.
2. The last line of each log you ran.
3. Anything in map.md or the tests you think is contradictory, with file:line.
