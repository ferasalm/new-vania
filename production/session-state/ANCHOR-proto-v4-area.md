# ANCHOR: proto v4 "area" build. Read first after any compaction

Work folder `C:/Users/AUC/opencode-workspace/workspace/new-vania` (the Main checkout). Each build session works on its own branch, which is merged into Main after the user plays it. Game `prototypes/feel-v3`.
Godot `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.
Plan: `production/plans/proto-v4-area-plan.md`. Build rules: `prototypes/feel-v3/design/contract.md` (section 8 overrides). User decisions: `design/decisions.md`.

## Now
- Session 1 mid-flight on `feat/proto-v4-area` (pushed through 366b07a). Lead = Claude Code again (2026-11-19).
- VERIFIED by Claude Code (2026-11-19): lock OK 12 files; main-checkout rerun = SMOKE 135/135, t_data 44/44,
  t_math 11/11, t_rpg 33/33, t_interact_ui 23/36 (13 = S3 UI), t_world 1/4 (S1), t_bosses 2/8 (S4), HAZARD 62/62,
  climb PASS. Test fix 3507398 reviewed: setup-order bugs only, assertions unchanged (fair).
- DONE: step 0 tests (locked), S0 Core 0eb7e2f, S2 Interact 85c33ee; details and the S2 scrap-roll ruling: handoff report.
- RULING (S0, accepted): R.taken keeps src "enemy" at mult 1.0 (legacy hazard_test pins today's full enemy damage); area_damage_mult 0.75 applies to NAMED sources ("ghost", "shot", "machine", ...). S2/S4 briefs must name their sources; bosses pass "boss" (mult 1.0), traps "trap" (raw).
- IN PROGRESS: S1 World builder in worktree `proto-v4-s1` (branch `feat/proto-v4-s1`, cut from 366b07a = S0+S2).
  Brief fixed first (15 rooms; backup `s1-world.md.orig-2026-11-19`). Routes deepseek cf/openrouter and codex all
  failed "no files changed"; the gemini-flash route was writing at 07:19. Log: job tmp `s1-worker.log`.
- DONE (2b3d41e): palette A main (cyan eyes/seams), skin B oxblood optional; `tools/pandora_skins.py`, `design/skins.md`.
- DONE (4fc7709, a5c1cea, pushed): ONE LOOK PER SKIN (user rule): `tools/harmonize_pandora.py` recolours all 115
  hand-made frames to A (head matched per frame -> skin face + cyan eye; originals in `art_proof/harmony/original`),
  seed-9 PixelLab jump re-toned + eye from rig; B baked to `assets/2x/pandora_b`. Jump wired: push-off, 4 air frames
  by vy, land_00 soft / land_01 hard (fall >= land_hard_drop), tuning in tuning.d/anim.json. Suite unchanged
  (smoke 135/135, hazard 62/62, climb PASS, lock OK). Build: `playable-history/2026-11-19-proto-v4-harmony/` (exe).
  WAITING ON USER: play it. PixelLab 29.3 of 40 left.
- S1 (feat/proto-v4-s1, merged area -> f6d9ef6, not pushed): t_world 34/38 after the moth test fix (e43db6a,
  user yes). Left: S4 machine counts (expected) + smoke/climb old-layout checks. Test-writer rewrite running
  (brief `production/briefs/s1-smoke-rewrite.md`, route builder-iq, log job tmp `s1-smoke-worker.log`):
  LEAD reviews every change, logs it, re-locks, then merges s1 -> area.
- DECIDED (user, decisions 25-27): skins, jump sources, attack style (fencer/dancer, J vs I differ, slim blade on hit frames).
- USER (2026-11-19): pass-2 jump 'not graceful enough' -> try other poses from the GIFs; ask before any PixelLab spend (33 left).
- USER RULES (2026-11-19): tests LOCKED from builders; only the lead amends the pack (rare, logged, re-locked, like 3507398); `worker.mjs verify <lock>` before every commit. NEW (2026-11-19): NEVER tune the opus-authored tests - they are the quality gates; if a test fails twice in a row, report it to the user before further changes.

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
- The map check (`design/mapgen2.py`) passes: no room overlap, every exit is matched. Saved build: `playable-history/2026-11-18-feel-v4-backtrack/` (exe + APK), tag `proto-v4-backtrack-2026-11-18`.
