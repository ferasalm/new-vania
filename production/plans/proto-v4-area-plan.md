# Proto v4 "area": three-session build plan

Status: planned (approved by the user 2026-11-19). Game: `prototypes/feel-v3`.
Design pack: `prototypes/feel-v3/design/`. `contract.md` holds the build rules; its section 8 (lead rulings) overrides earlier sections. `decisions.md` holds the user's 24 decisions.
Tests: `prototypes/feel-v3/tests_v4/`, written and locked first (step 0 in `production/session-state/ANCHOR-proto-v4-area.md`); builders must not edit them.
Harness: from 2026-11-19 the work continues in OpenCode only (see "OpenCode mode" in the ANCHOR); the Claude roles below map to OpenCode workers there.

## In plain words

- Three build sessions. Each one ends with a version the user plays, and that version is saved forever in `playable-history/`.
- Session 1: the foundation, every room of both maps, taking things with Up, pickup cards, XP and levels, drops, scrap and self-repair. The user also picks Pandora's new palette and the sprite method (both shown on her jump).
- Session 2: menus and maps, the two machine enemies, the cyborg mini-boss and his bolt pistol, refights, rebuild-here, and most of her new 16-bit frames.
- Session 3: the reworked Pallbearer, the werewolf, Arnetria with her dialogue and the end of the shift, the last frames, and her voice.
- Builders never edit the tests. A feature is done when its tests pass and the user has played it.

## The user's 16 comments, and where they are built

| # | Ask | Slice | Session |
|---|---|---|---|
| 1 | Backdrops without black gaps | S1 | 1 |
| 2 | Gentle shift filters (the library) | S1 | 1 |
| 3 | Sprites: 134 new true-16-bit frames, new palette, hand-on-hip idle, Elegy's own moves, death, repair, pistol | S9 | proof 1; batches 2 and 3 |
| 4 | Hazard room: 4 traps, 2 enemy kinds, reward; weak enemies return after 10 s | S1 | 1 |
| 5 | Library: 3 doors, hazard monsters, healing item; Up for every pickup | S1, S2 | 1 |
| 6 | Both maps designed (`design/map.md`); corner and full map screens | S1, S3 | 1, 2 |
| 7 | THE PALLBEARER rework | S5 | 3 |
| 8 | No hand-holding text | S1 | 1 |
| 9 | Lab: save, hallway, hidden harness room, Pallbearer, werewolf; special pickup show | S1, S2, S6 | 1, 3 |
| 10 | Pickup card; LEXICON CORE enemy names | S2 | 1 |
| 11 | ITEMS and EQUIPMENT menus | S3 | 2 |
| 12 | Winch loft turns the traps off | S1 | 1 |
| 13 | Post-shift map reorganised; three candles | S1 | 1 |
| 14 | RPG: levels, 2 points, 5 stats, 2 harness + 2 module slots, orbs, scrap, Sutures, rare drops | S0, S2, S3 | 1, 2 |
| 15 | Arnetria, dialogue, the end of the shift, cracked visor | S7 | 3 |
| 16 | RECALL refights | S8 | 2 |
| + | Machine enemies, SEXTON-19 and the bolt pistol, the restore module, her voice | S4, S8, S10 | 2, 3 |

Until THE UNMUZZLED exists (session 3), the wall jump is a plain Up pickup in his room, so every session's build plays through.

## Who does what (user rules, 2026-11-19)

| Work | Who |
|---|---|
| Decisions, briefs, diff review, test runs, playtest gates | lead (main session) |
| Design questions that need judgement | an Opus agent, only when one comes up |
| Slice coordination: reasoning-heavy slices (S0, S1, S5, S6, S7) | `sub-orchestrator-sonnet` |
| Slice coordination: coding-only slices (S2, S3, S4, S8) | `sub-orchestrator` (Haiku xhigh) |
| Code | OpenCode first: `worker.mjs run builder-iq` (cf deepseek-flash); Claude `builder` (Haiku xhigh) when it fails |
| Text, names, dialogue polish | `worker.mjs run builder-eq` (cf glm-flash) |
| Scouting | `worker.mjs run scout-light` / `scout-deep` (agy Gemini Flash) |
| Drawing frames | Sonnet (it sees images); the lead reviews contact sheets; the user approves |
| Voice | ElevenLabs, only after the user's yes on 3 sample lines |
| Tests needing knowledge + reasoning + coding / reasoning / pure coding | Opus / Sonnet / Haiku xhigh (done in planning) |

Every Agent call sets `model`. Never `general-purpose`, `Explore` or `Plan` for delegated work.

## Session 1: foundation, world, taking things, art proof

1. Start: in `workspace/new-vania`, on branch `feat/proto-v4-area` made from an up-to-date Main (the user's untracked reference art was copied there on 2026-11-19). Run `worker.mjs verify` on the test lock.
2. S0 Core runs alone (contract S0): the autoloads `W` and `R`, the data files and `rpg_math.gd`, with main.gd cut down. No change in behaviour: old smoke 66/66, climb and hazard tests still pass; t_data and t_math S0 checks pass.
3. Alongside S0 (no shared files): the art proof. Palettes A, B and C on her idle frame, and the stationary jump made both ways (sprites.md section 6). The user picks a palette and a method. glm-flash finalises the voice-line script (no paid calls).
4. S1 World and S2 Interact in parallel (separate files per the contract).
5. Checkpoint: both map sheets walkable (placeholder art in new rooms is fine), Up pickups with cards, special show, XP and level-ups (points kept, AUTO available), orbs, scrap, self-repair, Sutures with a quickslot key, the new hazard room, the winch, backdrops and filters fixed, hints gone.
6. End: all tests run; export the exe and APK; copy them to `playable-history/<date>-proto-v4-s1/`; tag `proto-v4-s1-<date>`; commit and push; the user plays; verdicts go into `production/playtests/VERDICTS.md`; after the user's yes, a PR into Main is merged (backup tag on Main first), and the next session starts a new branch from Main.

## Session 2: menus, machines, her new body

- S3 UI (pause tabs MAP, CHARACTER, ITEMS, EQUIPMENT, SYSTEM; the minimap; level-up offers CHARACTER; touch).
- S4 Machines: SAWBONES TROLLEY, GRAFTED ORDERLY, SEXTON-19 THE BOLTED in room OW, the BOLT PISTOL (key N, off hand, DIRGE only).
- S8 RECALL and REBUILD HERE.
- S9 batches 1-3: the existing frames converted to the chosen palette and true 16-bit, then the jumps, fall, land, wall jump, Dirge attacks, and the idles (the hand-on-hip turn first).
- Gates: the user approves the looks of both machines and SEXTON-19 before they are drawn.
- End: the same history, tag and playtest steps as session 1.

## Session 3: bosses and the end of the shift

- S5 THE PALLBEARER (HP 330, 3 stages, the body swings the scythe, drawings match the hits).
- S6 THE UNMUZZLED (wall jumps; grants the wall jump; replaces the stand-in pickup).
- S7 ARNETRIA (3 candles, dialogue, the end of the shift, the cracked visor, the organ falls silent).
- S9: the remaining batches (the Elegy set, pistol shots, death, self-repair). S10 voice: 3 sample lines, then the rest after a yes, then wiring.
- Gates: the user approves the looks of the Pallbearer redraw and the Unmuzzled before drawing.
- End: a full run (about 60 minutes), history, tag, a draft PR. The user reviews before any merge.
- If the lead's context passes 230k before S7 is done, finish S7 and its art in a short fourth session.

## Rules for every session

- Context: hand off at about 230k; the hard limit is 295k (autocompact is at 330k). The lead briefs and reviews; sub-orchestrators do the reading.
- Tests are locked (`worker.mjs lock`); run `worker.mjs verify` before every commit. A builder that edits a test fails the slice.
- Stage in a separate command before `git commit`. Never commit `assets/hero_2d_base/complete-sprites-reference.png`, `assets/hero_2d_base/pandora-16-bit/`, `assets/hero/`, `assets/references/` or `.usage-start.json`.
- No `rm`, `reset --hard`, `clean` or force-push. Move files aside instead.
- Paid tools (ElevenLabs, image generation) only after the user's yes.
- Every playable checkpoint goes to `C:/Users/AUC/opencode-workspace/playable-history/` and is never overwritten.

## Risks, in order

1. AI-drawn 16-bit frames may not reach the user's standard. The jump proof (two methods) decides before any batch is drawn.
2. S0 moves state and could break what works now. The old tests must pass first.
3. Room soft-locks: the t_world reachability check guards against them.
4. Merge clashes between parallel slices: exclusive files plus one-line hooks (contract section 3).
5. Boss feel: the lead plays each boss and the user playtests it.
6. Touch menus at 384x216. 7. Undoing the shift. 8. Paid voice. 9. The Android export.
