# Handoff: proto-v4 session 1 (OpenCode → Claude Code), 2026-11-19

Authoritative ledger: `production/session-state/ANCHOR-proto-v4-area.md` (kept under 60 lines).
Plan: `production/plans/proto-v4-area-plan.md`. Contract: `prototypes/feel-v3/design/contract.md` (section 8 rulings override 1–7).

## Where to work
- **Main checkout:** `C:\Users\AUC\opencode-workspace\workspace\new-vania` — continue here.
- **Worktrees** (`C:\Users\AUC\.local\share\opencode\worktree\bbecc4\`):
  - `proto-v4-s0` — S0 Core, done + merged.
  - `proto-v4-s1` — **empty, waiting for the S1 World builder.**
  - `proto-v4-s2` — S2 source; merged; test logs in `prototypes\feel-v3\tests_v4\logs\s2_*.log`.
- Branch state (`feat/proto-v4-area`, **pushed**): `0eb7e2f` S0 Core → `85c33ee` S2 Interact → `56f7e5b` housekeeping (anchor, .gitignore, blender mcp config).
- **Not merged into Main** — that waits until the user plays the session-1 build and says yes.

## What is done
1. **Step 0 test pack** (locked, untouchable): 6 scenes × .gd/.tscn in `prototypes/feel-v3/tests_v4/`; lock file `tests_v4/locks/step0.json`; verify with
   `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs verify prototypes/feel-v3/tests_v4/locks/step0.json` → must print `OK 12 files unchanged` before every commit.
2. **S0 Core** (commit `0eb7e2f`): W/R/Db autoloads, rpg_math, data stubs, spawner, arena, interact/loot/ambience/projectiles v1, main.gd 872→558 lines, SYSTEMS, debug_enter/enter, lock/unlock, input actions (H quick, G repair, M map).
3. **S2 Interact** (commit `85c33ee`, 11 files only): interact.gd (Up pickup card, nearest-wins, quick key H, special show), pickup.gd, pickup_card.gd, repair.gd (hold-to-heal, stopped done|hit|moved|empty), loot.gd (scrap/orb/rare drops), items/gear/enemies data fills, tuning.d/items.json, events.d/items.json; arena.gd relic+scythe now go through loot.spawn_pickup with silent touch (smoke pins touch pickups). main.gd needed NO edit — the two hint strings were already absent post-S0 (brief's :234/:436 refs were stale).
4. **Lead completion ruling on S2**: the delivered scrap roll sat behind the soul-orb draw and missed the locked scrap-rate check by 0.001; the lead moved the scrap roll before the orb roll in `loot.gd` (free design choice: primary drop rolls first; test file untouched, lock verified). Recorded in ANCHOR.
5. **User rules recorded 2026-11-19**: never tune the opus-authored tests (quality gates); if a test fails twice in a row, report before further changes; builders never edit `tests_v4/`, `smoke.gd`, `hazard_test.gd`, `climb_test.gd`.

## Verification evidence
| Gate | Result |
|---|---|
| SMOKE | PASS 135/135 |
| t_data | PASS 44/44 |
| t_math | PASS 11/11 |
| t_rpg | PASS 33/33 |
| t_interact_ui | 23/36 — the 13 fails are ALL the S3 UI half (menu, minimap, name plate, dialog box) — expected until session 2 |
| hazard_test | PASS 62/62 |
| climb_test | exit 0 |
| lock | OK 12 files unchanged |

- **Fully green in the S2 worktree** on the exact tree of `85c33ee` (logs `s2_*.log`).
- **Post-merge main-checkout rerun NOT complete**: a log-path bug (--log-file given repo-root-relative from workdir `prototypes\feel-v3`) made Godot fail to open the log files; only climb exit 0 was recorded. **Rerun the suite before trusting the merge** (commands below, workdir must be `prototypes\feel-v3`).

## Do this first in Claude Code (verification rerun)
PowerShell, from `C:\Users\AUC\opencode-workspace\workspace\new-vania\prototypes\feel-v3`:
```powershell
$G = "C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64_console.exe"
node "$env:USERPROFILE\.claude\skills\lean-orchestrator\tools\worker.mjs" verify tests_v4/locks/step0.json
& $G --headless --path . --import
# log paths are relative to THIS directory (no prototypes/feel-v3 prefix!):
& $G --headless --path . --log-file tests_v4/logs/h_smoke.log res://smoke.tscn
& $G --headless --path . --log-file tests_v4/logs/h_t_data.log res://tests_v4/t_data.tscn
& $G --headless --path . --log-file tests_v4/logs/h_t_math.log res://tests_v4/t_math.tscn
& $G --headless --path . --log-file tests_v4/logs/h_t_rpg.log res://tests_v4/t_rpg.tscn
& $G --headless --path . --log-file tests_v4/logs/h_t_interact_ui.log res://tests_v4/t_interact_ui.tscn
& $G --headless --path . --log-file tests_v4/logs/h_t_world.log res://tests_v4/t_world.tscn   # FAIL until S1
& $G --headless --path . --log-file tests_v4/logs/h_t_bosses.log res://tests_v4/t_bosses.tscn # FAIL until S4
& $G --headless --path . --log-file tests_v4/logs/h_hazard.log res://hazard_test.tscn
& $G --headless --path . --log-file tests_v4/logs/h_climb.log res://climb_test.tscn
```
Expected after S2 (S1 pending): smoke 135/135; t_data 44/44; t_math 11/11; t_rpg 33/33; t_interact_ui 23/36 (13 UI-half fails = S3); t_world FAIL (S1 owns it — its two hint-string checks already pass since the strings are gone); t_bosses FAIL until S4; hazard 62/62; climb 0. Import noise about `hero_3d_preview`/`pandora_proportion_study` textures is pre-existing and harmless (those pngs are now gitignored; they regenerate in fresh worktrees).
Godot notes: PowerShell has no `&&` (use `;`); don't pipe Godot output through Select-Object (buffers) — use `--log-file` + read the file.

## Next step after the rerun: launch S1 World
One builder slot at a time (parallel launches hang and fail; workers run serially). Background, from repo root:
```powershell
node "$env:USERPROFILE\.claude\skills\lean-orchestrator\tools\worker.mjs" run builder-iq production/briefs/s1-world.md --write --dir "C:\Users\AUC\.local\share\opencode\worktree\bbecc4\proto-v4-s1" --no-claude --timeout 3600 --files prototypes/feel-v3/design/contract.md,prototypes/feel-v3/design/map.md,prototypes/feel-v3/tests_v4/t_world.gd,prototypes/feel-v3/room.gd,prototypes/feel-v3/shift.gd,prototypes/feel-v3/door.gd,prototypes/feel-v3/props.gd,prototypes/feel-v3/ambience.gd,prototypes/feel-v3/main.gd,prototypes/feel-v3/world_state.gd,prototypes/feel-v3/data/enemies.json,prototypes/feel-v3/data/rooms_meta.json,prototypes/feel-v3/tools/mirror_room.py,prototypes/feel-v3/rooms/church.txt,prototypes/feel-v3/rooms/library.txt,prototypes/feel-v3/rooms/shaft.txt,prototypes/feel-v3/rooms/hazard.txt,prototypes/feel-v3/rooms/vault.txt,prototypes/feel-v3/rooms/timemachine.txt,prototypes/feel-v3/rooms/boss.txt
```
Worker notes: the model can NOT run Godot — the lead verifies. First cf route may time out; an openrouter retry usually completes (S2: cf timed out at 2400 s, retry finished at 4472 s, exit 0). Exit 3 → spawn the Claude fallback named in the worker's next line.
S1 verify routine (in the s1 worktree): import → smoke/t_data/t_math/t_rpg must stay green, t_world must pass except the two lab machine-count checks (S4); `git diff --name-only -- prototypes/feel-v3/tests_v4 prototypes/feel-v3/smoke.gd prototypes/feel-v3/hazard_test.gd prototypes/feel-v3/climb_test.gd` must be EMPTY; commit on `feat/proto-v4-s1`; merge into `feat/proto-v4-area` in the main checkout; rerun the suite; push.

## After S1 (session-1 remainder, in order)
1. **Art proof** — palettes A/B/C on her idle frame + stationary jump made BOTH ways (sprites.md sections 3b and 6; user decisions 22/23); show the user as pictures for the palette + method pick. Paid image generation ONLY after the user's explicit yes.
2. glm-flash (builder-eq) finalises the voice-line script (no paid calls).
3. All tests run; export exe + APK; copy to `C:/Users/AUC/opencode-workspace/playable-history/<date>-proto-v4-s1/` with ABOUT.txt; tag `proto-v4-s1-<date>` + push; user plays; verdicts to `production/playtests/VERDICTS.md`.
4. After the user's yes: backup tag on Main, PR into Main, merge. Session 2 = S3 UI, S4 machines, S8, S9 batches 1–3.

## Guards (standing)
- Never edit `tests_v4/` (12 files), `smoke.gd`, `hazard_test.gd`, `climb_test.gd`; only the lead amends the pack (rare, logged, re-locked). Never tune tests to pass.
- Never commit: `assets/hero_2d_base/complete-sprites-reference.png`, `assets/hero_2d_base/pandora-16-bit/`, `assets/hero/`, `assets/references/`, `.usage-start.json`, `tools/models/bank/*.png`, the two `textures/shaded.png` (now in .gitignore), `*.uid` files.
- No rm / reset --hard / clean / force-push. Stage in a separate command, then commit. Conventional commits; body lines ≤ 100 chars; include a Refs line.
- `git switch -c <branch>` before building (commits on Main are hook-blocked). Builders run serially (one slot).
- Paid tools only after the user's yes. Known small gap for S3/S4: `steel_nib` is not in `R.DRIVE` (rpg.gd was outside S2 ownership).
