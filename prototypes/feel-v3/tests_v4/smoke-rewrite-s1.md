# smoke.gd and climb_test.gd: rewrite for the 15-room map (S1)

Approved by the user on 2026-11-19 ("Yes, rewrite them"): only the checks the new map makes wrong.
A worker made the first pass and was stopped by the system (low memory); the lead reviewed every change,
put back the ones the map does not justify, and finished the rest. Source of truth: `design/map.md`.

## smoke.gd

| Old check | New check | Why (map.md / contract) |
|---|---|---|
| nine enemy kinds are placed in the rooms | the six enemy kinds map.md places before S4 are in the rooms | map.md 47-61 (before sheet): hound, ghost, moth, scribe, crab, leech; trolley and orderly arrive with S4 (then 8) |
| every area has its own look (8) | same name, 7 | map.md 236: save2 is off the map, so its own look is gone |
| each of the five areas has its own music | unchanged (worker's replacement removed) | not map-dependent; it passes on S1 |
| the lab leads to the second save room; the wall-latch relic waits in the lab; walking into the relic gives the latch | the lab leads on to the hallway, its upper floor to the ordnance ward; its left door leads to the cache station; no relic in the lab; GRIP SERVOS waits in the kennel; Up at the marker gives the latch | map.md 50, 52, 213 (LA: L1 S2, R1 HW, R0 boss door to OW, relic removed; KN: GRIP SERVOS) |
| the wall latch tests at the lab's tall wall | the same three latch checks at the well's wall | map.md 57, 92 (climb the well, SH) |
| the second save room ends in the boss door; saves; RECONSTRUCT at save2 | the second cache station (vault) has capsule and terminal, saves, RECONSTRUCT there; the hallway ends in the boss door | map.md 236 (save2 off the map), 58 (VA save), 54 (HW R boss door PB) |
| walking into the church's left door says SEALED | it stays shut with its lamp red | contract 379-384 (door lamp red/pale), no hint text (decision 17) |
| a cut pulls the library lever and says "Far below" | a cut pulls the library lever | banned string (t_world.gd:31) |
| after the lever the church door is not locked | same, and its lamp is pale | contract 384 |
| the threshing chapel's right half: 2 crabs, 2 moths, 1 scribe, 2 leeches, 2 pendulums, 2 crushers, 3 vents, 2 spikes | the chapel holds 2 crabs, 2 leeches, 2 pendulums, 2 crushers | map.md 59 |
| at least 3 tiles of safe floor between the floor hazards (and at least 7 of them) | same rule, without the old count of 7 | the gap rule is not about the old map; the count was (worker had dropped the whole check: put back) |
| the bars are gone (cell 46,12) | the bars' own cell | room is 96 wide now (map.md 222) |
| the organ room's way back is a tall open edge | the way back is the low crawl | map.md 61: OR R0 `~` HZ |
| the shifted vault's special door: LOCKED - UNTIL THE NEXT UPDATE | the sealed door to Arnetria stays shut with no candles, lamp red | banned string; map.md VA~ X door to AR, three candles (decision 13) |
| the church/library/hazard rooms are mirrored after the shift; the mirrored way back | the shifted rooms are their own `_shift` files with map.md's exits; the way back chapel > library > church > lab > well > vault | map.md 161-167, section 4 |
| keys 7, 8, 9, 0 go to the shaft, vault, hazard room, time machine | ... to the ordnance ward, the hallway, the Pallbearer and the reliquary | map.md before sheet rows 7-10 |
| the pause menu lists all ten rooms | ... all fifteen before-shift rooms | map.md before sheet (15 rows) |

Put back by the lead (the worker had loosened them; none is about the map): the tunnel checks measure from the
cracked wall's edge again (`> wall_end_x + 3`, `> wall_end_x + 6`), the slide must arrive at the organ room's
right edge (`> width - 60`), she approaches the bars from the vault side (map.md 59: HZ R0 = VA, lever behind the
bars), and no failure text names a cause.

## climb_test.gd

The old test measured a free-standing lab wall with one ledge on each side; map.md moves the wall climb to the
well (SH), a corridor with ledges on one wall, so the route was rewritten for that shape. Kept unchanged: GAPS,
HOLDS, PRESS, AWAY, human timing, one latch per jump, checks a (no latch, no ledge), b (no second latch), c (no
bypass). Lead fix: the wall finder starts above the bottom corridor. Rest: see the climb section below.

## Remaining smoke failures (lead run rv_smoke, 119 passed, 13 failed): S1 code defects

- sounds loaded: 8 world sounds missing (door_lamp, chain_run, boom, dust, cold_air, candle, rattle, winch).
- Up at the GRIP SERVOS marker gives the wall latch.
- walking into the Pallbearer's room starts the fight and locks the door.
- the hazard room: no cracked-wall prop from the `<` cells; the lever `Y` (col 20) stands in front of the bars
  (col 19), not behind them; she stops 16 px short of the bars.
- the slide into the organ room (follows from the missing wall).
- the shift: `interact.gd:220` calls `Organ.charge()`, which does not exist (SCRIPT ERROR), so nothing after the
  YES runs.
- tester keys 7-0 all go to the time machine; InputMap actions room11-room15 do not exist (main.gd:306).
- the pause menu's ROOM_LABELS does not list 15 rooms.
