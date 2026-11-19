# ANCHOR: proto v4 "area" build. Read first after any compaction

Work folder `C:/Users/AUC/opencode-workspace/workspace/new-vania` (the Main checkout). Each build session works on its own branch, which is merged into Main after the user plays it. Game `prototypes/feel-v3`.
Godot `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.
Plan: `production/plans/proto-v4-area-plan.md`. Build rules: `prototypes/feel-v3/design/contract.md` (section 8 overrides). User decisions: `design/decisions.md`.

## Now
- Session 1 mid-flight on `feat/proto-v4-area` (pushed through 56f7e5b: 0eb7e2f S0 -> 85c33ee S2 -> 56f7e5b housekeeping). HANDOFF: the user continues in Claude Code; full report at `production/reports/2026-11-19-proto-v4-session1-handoff.md`. NOTE: the post-merge main-checkout suite rerun did NOT complete (log-path bug; only climb exit 0 recorded) - rerun the whole suite there before trusting the merge; the S2 worktree run on the identical tree was fully green.
- DONE: step 0 (tests written, locked in `tests_v4/locks/step0.json`, committed); baseline import + SMOKE PASS 135/135.
- DONE: S0 Core (builder-iq deepseek, worktree branch `feat/proto-v4-s0`, merged 0eb7e2f). Verified in main checkout: SMOKE PASS 135/135, t_data 44/44, t_math 11/11, t_rpg 33/33, HAZARD 62/62, climb exit 0, lock verify OK. main.gd 872 -> 558 lines. Autoloads now T, G, Sfx, Db, W, R.
- Two step-0 self-check bugs found by the S0 builder were fixed by the lead and re-locked (commit 3507398): t_math now runs boss/ghost/hit_damage at DEF 0 before the trap check spends points; t_rpg drains all 18 level-10 points before asserting spend-refusal. Check names/expectations unchanged.
- RULING (S0, accepted): R.taken keeps src "enemy" at mult 1.0 (legacy hazard_test pins today's full enemy damage); area_damage_mult 0.75 applies to NAMED sources ("ghost", "shot", "machine", ...). S2/S4 briefs must name their sources; bosses pass "boss" (mult 1.0), traps "trap" (raw).
- DONE: S2 Interact (builder-iq deepseek; cf route timed out at 2400 s, openrouter retry finished in 4472 s, branch `feat/proto-v4-s2`). Delivered interact/loot/pickup/pickup_card/repair.gd, items/gear/enemies, tuning.d/items.json, events.d/items.json; arena relic+scythe now go through loot.spawn_pickup with a silent touch path (smoke pins touch pickup); main.gd needed no edit (the two hint strings were already absent post-S0; the brief's :234/:436 refs were stale). LEAD COMPLETION RULING: the delivered scrap roll sat behind the soul-orb draw and missed the locked scrap-rate check by 0.001; moved the scrap roll before the orb roll in loot.roll_drops (free design choice, primary drop first; test untouched). Verified in worktree: SMOKE 135/135, t_data 44/44, t_math 11/11, t_rpg 33/33, t_interact_ui 23/36 (13 UI-half fails = S3, expected), HAZARD 62/62, climb 0, lock OK. For S3/S4: steel_nib is not in R.DRIVE (rpg.gd was outside S2 ownership).
- NEXT (in Claude Code): 1) verify lock, import, rerun the full suite (commands in the handoff report; run from `prototypes/feel-v3`, log paths relative to it); 2) launch the S1 World builder serially (`--timeout 3600`, brief `production/briefs/s1-world.md`, worktree `proto-v4-s1`, files list in the report); 3) after S1 verifies+merges: art proof (palettes A/B/C + jump two ways, user's eyes; nothing paid without yes) -> voice script (glm-flash) -> exports -> playtest -> PR.
- USER RULES (2026-11-19): tests LOCKED from builders; only the lead amends the pack (rare, logged, re-locked, like 3507398); `worker.mjs verify <lock>` before every commit. NEW (2026-11-19): NEVER tune the opus-authored tests - they are the quality gates; if a test fails twice in a row, report it to the user before further changes.
- Expected test state now (S2 in, S1 pending): t_data/t_math/t_rpg PASS; t_interact_ui 23/36 (UI half = S3 FAIL); t_world waits on S1 (its two hint-string checks already pass); t_bosses FAIL until S4.

## OpenCode mode (user, 2026-11-19)
- The lead is the OpenCode session. Builders: `worker.mjs run builder-iq ... --no-claude` (cf deepseek-flash), text: `builder-eq --no-claude` (cf glm-flash), scouts: `scout-light`/`scout-deep` (agy Gemini Flash, which can see images: use it to review frame contact sheets).
- A deepseek subagent may be used directly for IQ-heavy tasks (user, 2026-11-19).
- The plan's Claude roles (Sonnet, Haiku, Opus) are replaced by these. Sprite drawing still needs the user's approval at every art gate.

## Step 0 rulings (lead, 2026-11-19): what the test pack fixes about the contract
- The six tests hold contract 4.2's content, regrouped per the anchor: t_data = static files + S0 tuning; t_math = rpg_math formulas + the R damage trio; t_rpg = W/R behaviour (xp, levels, stats, Sutures, gear, forwarding, snapshots, award_kill, spawner, main.gd <= 600 lines, SYSTEMS); t_interact_ui = S2 interact + S3 UI; t_world = S1 world (rooms, exits, counts, reachability, banned strings, backdrops, filter, respawn, shift, candles, visited); t_bosses = S4 machines + S5 + S6 + S7 + S8. t_anim/t_voice are NOT in the 12-file pack; added in their own sessions if needed.
- No separate harness.gd / run_all.sh in step 0 (the anchor fixes exactly 12 files); the smoke.gd check pattern is copied into each t_*.gd. Summary format `<file> PASS x/y` (anchor) overrides contract 4.1's `TEST ...` line.
- Stat ids/gains per ruling 3: vigor/power/guard/stamina/magic with +10 HP, +8 ATK, +3 DEF, +8 EN, +8% special, +6 MP; tests accept the contract's older keys (vit_hp, str_atk, end_def, end_en, mag_special, mag_mp) as fallbacks, and pin the gains.
- Sutures are NEVER refilled (ruling 1): t_data requires items.json suture.refill_at_terminal == false; t_interact_ui requires a terminal to leave the Suture count unchanged (contract 4.2's "terminal refills Sutures" is overruled).
- Gear follows rpg-items v2: coupler_034/governor_207/regulator_000 modules (DRIVE/FRAME), restore_module fixed CORE, cerement_112/pall_090/tether_06 harnesses (TORSO/LIMBS). Contract 2.6's draft line (coupler as harness, restore_unit, scrap_loom) is superseded; restore_unit accepted as alias.
- Weak-respawn wait key weak_respawn_s (fallback respawn_time) must equal 10 (ruling 9). Recall share recall_xp_share (fallback recall_xp_mult) = 0.25. Scrap chance follows contract 2.7's linear scrap_chance (rpg-items F7's 0.95 cap is not used; the t_interact_ui low*0.9 arithmetic confirms the contract formula).
- Banned strings: the first four are hard failures after S1; the last two ("ITS HANDS ARE YOUR STAIRS", "IT WILL NOT LET GO") print as expected notes until S5 (contract 4.2's expected-failure note).
- enemies.json drop chance_keys are checked in t_interact_ui (S2 owns those tuning keys); t_data checks xp_keys, item fields, gear effect keys (S0-owned).

## Start of build session 1 (in order)
1. Branch done (see Now). 2. Usage: none to track in OpenCode. 3. `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs verify <step-0 lock file>` - must report all intact. 4. Baseline: from `prototypes/feel-v3`, `<godot> --headless --path . --import`, then smoke `res://smoke.tscn` (expect 135/135), and each `res://tests_v4/t_*.tscn` (record the counts). 5. Session 1 = S0 alone, then S1 + S2 in parallel, with the art proof alongside S0 (plan, "Session 1").
- At session end: all tests run; export exe + APK; copy both to `playable-history/<date>-proto-v4-s1/` with ABOUT.txt; tag `proto-v4-s1-<date>` and push; user plays; verdicts into `production/playtests/VERDICTS.md`; after the user's yes, backup tag on Main, PR into Main, merge; next session starts a new branch.

## Commands
- Headless test: `<godot> --headless --path prototypes/feel-v3 res://tests_v4/t_world.tscn --log-file <tmp>/t_world.log` (PowerShell: no `&&`, use `;`; don't pipe Godot output through Select-Object - it buffers; rely on --log-file).
- Climb test: `--headless --fixed-fps 60 --path . res://climb_test.tscn`. Screenshots: run smoke windowed with `-- shots`.
- Workers: `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs run builder-iq <brief> --write --dir <worktree>`; exit 3 means spawn the Claude fallback named in its NEXT line.
- History: copy the exe and APK into `C:/Users/AUC/opencode-workspace/playable-history/<date>-proto-v4-s<N>/` with an ABOUT.txt; `play-history.cmd` lists them. Tag `proto-v4-s<N>-<date>` and push the tag.

## Guards
- Stage in a separate command, then commit. Never commit: `assets/hero_2d_base/complete-sprites-reference.png`, `assets/hero_2d_base/pandora-16-bit/`, `assets/hero/`, `assets/references/`, `.usage-start.json`.
- No rm / reset --hard / clean / force-push; move aside. Stay inside `workspace/new-vania`. The untracked reference art (`assets/hero_2d_base/pandora-16-bit/`, the rig) stays untracked.
- Every Agent call sets a model. Paid tools only after the user's yes.
- The user has no game-dev experience: plain words, status words done / in progress / planned / not planned / waiting on user.
- After each slice: update this file (Now, Verified, Next) and keep it under 60 lines.

## Verified
- The map check (`design/mapgen2.py`) passes: no room overlap, every exit is matched.
- Saved build: `playable-history/2026-11-18-feel-v4-backtrack/` (exe + APK), tag `proto-v4-backtrack-2026-11-18`.

## Open (waiting on user, asked in session 1)
- Palette A / B / C, and the sprite method (redraw over pose, or rig + cleanup), both shown on the stationary jump.
