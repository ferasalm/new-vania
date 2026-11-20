# ANCHOR: proto v4 "area" build. Read first after any compaction

Work folder `C:/Users/AUC/opencode-workspace/workspace/new-vania` (the Main checkout). Each build session works on its own branch, which is merged into Main after the user plays it. Game `prototypes/feel-v3`.
Godot `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.
Plan: `production/plans/proto-v4-area-plan.md`. Build rules: `prototypes/feel-v3/design/contract.md` (section 8 overrides). User decisions: `design/decisions.md`.

## Now
- Way of working (user, 2026-11-20, SUPERSEDES the older "Claude builds directly" rule): route by cost. Sonnet leads and executes; workers build; gates are written by a stronger model than the builder. Read `production/orchestration/ROUTING-PLAYBOOK.md` and `production/plans/2026-11-20-execution-plan.md` first. One task per chat; hand off at ~220k.
  Task order and every ask with its status: `production/plans/proto-v4-asks-ledger.md` (read it first).
- DONE task 1 (rooms fix + merge, XP, orb pull, hint text), commits 951957e..b48567a on feat/proto-v4-area, pushed.
  Build `playable-history/2026-11-19-proto-v4-rooms/` (exe + APK + ABOUT), tag `proto-v4-rooms-2026-11-19`.
  WAITING ON USER: play it.
- IN PROGRESS task 2: standing J + I done as LEVEL slashes (user: horizontal; I = J left-handed, no dance),
  commit 89eb789, tag proto-v4-level-slash-2026-11-19. Weapon is its own layer from frames.json hero.weapon
  keys (angle, or yaw + tilt for a level swing). WAITING ON USER: play it, judge the hands.
  Air attacks stay as they are (user). Ledger rows N1-N11. State: active.md.
- DONE OpenCode quick fixes Q1-Q7 (N1-N7), build `playable-history/2026-11-19-proto-v4-quick-fixes/`. WAITING ON USER: play.
- DONE Claude B1 chat (2026-11-19): moth smoke 3.0 s (N12), scrap+orbs wait-then-fly (N13), weapon frames (N14), F4 notes (N15),
  F2 room builder + red warnings + F3 map builder (N8). Tests d0-d6 in tests_dev/. WAITING ON USER: play it.
  NEXT: the menus (N16-N18) are in PR #105 and the leveling ruling (N19-N21) is settled in PR #107 (automatic growth, no points). Remaining: the user's verdicts on PRs #105-#107, then B2 art (N9-N11, handoff-2026-11-19-next.md), then the Studio (N22-N26).
- Room guards: `prototypes/feel-v3/tools/roomreach.py .` (can she reach every item and exit; run from feel-v3)
  and `tools/roomcheck.py .` (door headroom, low spots). Run both after any room edit.
- RULING (S0, accepted): R.taken keeps src "enemy" at mult 1.0; area_damage_mult 0.75 applies to NAMED sources.
- USER RULES: tests LOCKED (`tests_v4/locks/step0.json` 12 files, `step1.json` smoke + climb); `worker.mjs verify
  <lock>` before every commit. NEVER tune the opus-authored tests; a test failing twice in a row goes to the user first.

## Step 0 rulings (lead, 2026-11-19): what the test pack fixes about the contract
- The six tests hold contract 4.2's content, regrouped per the anchor: t_data = static files + S0 tuning; t_math = rpg_math formulas + the R damage trio; t_rpg = W/R behaviour (xp, levels, stats, Sutures, gear, forwarding, snapshots, award_kill, spawner, main.gd <= 600 lines, SYSTEMS); t_interact_ui = S2 interact + S3 UI; t_world = S1 world (rooms, exits, counts, reachability, banned strings, backdrops, filter, respawn, shift, candles, visited); t_bosses = S4 machines + S5 + S6 + S7 + S8. t_anim/t_voice are NOT in the 12-file pack; added in their own sessions if needed.
- No separate harness.gd / run_all.sh in step 0 (the anchor fixes exactly 12 files); the smoke.gd check pattern is copied into each t_*.gd. Summary format `<file> PASS x/y` (anchor) overrides contract 4.1's `TEST ...` line.
- Stat ids/gains per ruling 3: vigor/power/guard/stamina/magic with +10 HP, +8 ATK, +3 DEF, +8 EN, +8% special, +6 MP; tests accept the contract's older keys (vit_hp, str_atk, end_def, end_en, mag_special, mag_mp) as fallbacks, and pin the gains.
- Sutures are NEVER refilled (ruling 1): t_data requires items.json suture.refill_at_terminal == false; t_interact_ui requires a terminal to leave the Suture count unchanged (contract 4.2's "terminal refills Sutures" is overruled).
- Gear follows rpg-items v2: coupler_034/governor_207/regulator_000 modules (DRIVE/FRAME), restore_module fixed CORE, cerement_112/pall_090/tether_06 harnesses (TORSO/LIMBS). Contract 2.6's draft line (coupler as harness, restore_unit, scrap_loom) is superseded; restore_unit accepted as alias.
- Weak-respawn wait key weak_respawn_s (fallback respawn_time) must equal 10 (ruling 9). Recall share recall_xp_share (fallback recall_xp_mult) = 0.25. Scrap chance follows contract 2.7's linear scrap_chance (rpg-items F7's 0.95 cap is not used; the t_interact_ui low*0.9 arithmetic confirms the contract formula).
- Banned strings: the first four are hard failures after S1; the last two ("ITS HANDS ARE YOUR STAIRS", "IT WILL NOT LET GO") print as expected notes until S5 (contract 4.2's expected-failure note).
- enemies.json drop chance_keys are checked in t_interact_ui (S2 owns those tuning keys); t_data checks xp_keys, item fields, gear effect keys (S0-owned).

## Commands
- Builders `worker.mjs run builder-iq ... --no-claude` (cf/openrouter deepseek-flash), text `builder-eq --no-claude`, scouts `scout-light`/`scout-deep` (Gemini Flash, can see images). Serial only. Sprite drawing needs the user's yes at every art gate.
- At session end: all tests run; export exe + APK; copy both to `playable-history/<date>-proto-v4-s1/` with ABOUT.txt; tag `proto-v4-s1-<date>` and push; user plays; verdicts into `production/playtests/VERDICTS.md`; after the user's yes, backup tag on Main, PR into Main, merge; next session starts a new branch.
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
- Task 1 (2026-11-19): smoke 145/145, climb PASS, hazard 62/62, t_rpg 33/33, t_data 44/44, t_math 11/11;
  expected fails (later tasks): t_world 35/38 machines, t_interact_ui 23/36 menus/map, t_bosses 2/8 machines + Pallbearer.
- Quick fixes Q1-Q7 (2026-11-19): smoke 145/145, climb PASS, hazard 62/62, t_rpg 33/33, t_data 44/44, t_math 11/11;
  expected fails: t_world 35/38, t_bosses 2/8, t_interact_ui 34/39 (better: every menu check green).
- B1 chat (2026-11-19): same locked counts as above; d0 15, d1 20, d4 19, d5 9, d6 21, q1 11, q2 9, q3 24 all pass; main.gd 597 lines.
- The map check (`design/mapgen2.py`) passes: no room overlap, every exit is matched. Saved build: `playable-history/2026-11-18-feel-v4-backtrack/` (exe + APK), tag `proto-v4-backtrack-2026-11-18`.
