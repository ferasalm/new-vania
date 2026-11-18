# ANCHOR: proto v4 "area" build. Read first after any compaction

Work folder `C:/Users/AUC/opencode-workspace/workspace/new-vania` (the Main checkout). Each build session works on its own branch, which is merged into Main after the user plays it. Game `prototypes/feel-v3`.
Godot `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.
Plan: `production/plans/proto-v4-area-plan.md`. Build rules: `prototypes/feel-v3/design/contract.md` (section 8 overrides). User decisions: `design/decisions.md`.

## Now
- Planning: done (2026-11-19). Merged into Main with PR #104 (feel v4 backtrack, the design pack and the plan).
- Tests: NOT written yet. The Claude test writers were stopped at 85% of the 5-hour limit, before writing any file.
- Next: the user continues in OPENCODE ONLY. Step 0 writes and locks the tests, then build session 1 runs. (waiting on user)

## OpenCode mode (user, 2026-11-19)
- The lead is the OpenCode session. Builders: `worker.mjs run builder-iq ... --no-claude` (cf deepseek-flash), text: `builder-eq --no-claude` (cf glm-flash), scouts: `scout-light`/`scout-deep` (agy Gemini Flash, which can see images: use it to review frame contact sheets).
- The plan's Claude roles (Sonnet, Haiku, Opus) are replaced by these. Sprite drawing still needs the user's approval at every art gate.

## Step 0: write and lock the tests (before any build)
Write 6 headless test scenes in `prototypes/feel-v3/tests_v4/` exactly as `design/contract.md` section 4 (4.1-4.4) lists them: t_data and t_math (static files, formulas), t_rpg and t_interact_ui (RPG and UI behaviour), t_world and t_bosses (map, shift, bosses). Section 8 rulings override. Rules:
- Copy the check pattern from smoke.gd lines 1-90. Each check prints PASS or FAIL; the summary line is "<file> PASS x/y"; quit(0) only when all pass.
- Tests must FAIL now without crashing: no bare names of the new autoloads or scripts at parse time (use get_node_or_null("/root/R"), ResourceLoader.exists + load, has_method + call); no class_name.
- Numbers come through T.v("key"); use the contract's seed hook and test hooks. Each test is run once headless and must reach its summary line.
- Then `worker.mjs lock` on the 12 files, and commit and push the lock with them.

## Start of build session 1 (in order)
1. In `workspace/new-vania`: `git switch Main`, `git pull --ff-only`, then `git switch -c feat/proto-v4-area`. The hook blocks commits on Main. At the end of the session, after the user has played, open a PR into Main and merge it (backup tag on Main first). The next session starts the same way with a new branch.
2. Usage: none to track in OpenCode (Claude's usage.mjs applies only to Claude sessions).
3. `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs verify <the lock file from step 0>`. It must report all intact.
4. Baseline: from `prototypes/feel-v3`, `<godot> --headless --path . --import`, then smoke `res://smoke.tscn` (expect 135/135), and each `res://tests_v4/t_*.tscn` (they fail until the features exist; record the counts).
5. Session 1 = S0 alone, then S1 + S2 in parallel, with the art proof alongside S0 (plan, "Session 1").

## Commands
- Headless test: `<godot> --headless --path prototypes/feel-v3 res://tests_v4/t_world.tscn --log-file <tmp>/t_world.log`
- Climb test: `--headless --fixed-fps 60 --path . res://climb_test.tscn`. Screenshots: run smoke windowed with `-- shots`.
- Workers: `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs run builder-iq <brief> --write --dir <worktree>`; exit 3 means spawn the Claude fallback named in its NEXT line.
- History: copy the exe and APK into `C:/Users/AUC/opencode-workspace/playable-history/<date>-proto-v4-s<N>/` with an ABOUT.txt; `play-history.cmd` lists them. Tag `proto-v4-s<N>-<date>` and push the tag.

## Guards
- Stage in a separate command, then commit. Never commit: `assets/hero_2d_base/complete-sprites-reference.png`, `assets/hero_2d_base/pandora-16-bit/`, `assets/hero/`, `assets/references/`, `.usage-start.json`.
- No rm / reset --hard / clean / force-push; move aside. Stay inside `workspace/new-vania`. The untracked reference art (`assets/hero_2d_base/pandora-16-bit/`, the rig) was copied there on 2026-11-19; it stays untracked.
- Every Agent call sets a model. Paid tools only after the user's yes.
- The user has no game-dev experience: plain words, status words done / in progress / planned / not planned / waiting on user.
- After each slice: update this file (Now, Verified, Next) and keep it under 60 lines.

## Verified
- The map check (`design/mapgen2.py`) passes: no room overlap, every exit is matched.
- Saved build: `playable-history/2026-11-18-feel-v4-backtrack/` (exe + APK), tag `proto-v4-backtrack-2026-11-18`.

## Open (waiting on user, asked in session 1)
- Palette A / B / C, and the sprite method (redraw over pose, or rig + cleanup), both shown on the stationary jump.
