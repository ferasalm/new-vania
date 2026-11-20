# Execution plan 2026-11-20: ship the area, the Library, automatic leveling, and the Studio

## In plain words
- **What you get, in order:** (1) the area checkpoint as a draft pull request with checks and CodeRabbit; (2) your two-screen Library in its own PR; (3) automatic leveling in its own PR; (4) a **Studio**: one folder holding every asset, a thumbnail and a "?" on everything, and a room builder where you can select, move, copy, rotate and resize things.
- **Who does the work:** Sonnet leads, briefs and checks. Most coding goes to the free workers (OpenCode DeepSeek, agy Gemini). **The tests that gate each task are written by a stronger model (Codex Sol, or Sonnet), never by the worker that builds, and I check them for cheating.** Codex also makes two image sheets (a Studio look and an icon set), in batches. Haiku reads and runs tests. Opus only advises at three checkpoints (you run `/advisor opus` once).
- **Your money and time:** Claude weekly use is 86% (resets in about 19.5 hours). Every task ends at a pushed checkpoint. At 96% I finish the current check, write the handoff, and keep going only with the free workers.
- **Safety:** nothing merges without your yes. The locked tests change only as you approved. No host settings are touched.
- **Your progress file:** `production/TLDR.md` (bullets in plain words, updated after every task and slice). Read it any time.
- **Saved for later:** the routing rules go to `production/orchestration/ROUTING-PLAYBOOK.md`, this plan to `production/plans/2026-11-20-execution-plan.md`, and the day's log to `production/orchestration/pipeline-log.md`.
- **If you say no:** nothing runs.

---

## Part 0: Situation

- Branch `feat/proto-v4-area`, tip `dc952e8`, 63 commits ahead of `origin/Main` (`7a7beaa`). **No PR exists** (checked 2026-11-20). Repo `ferasalm/new-vania`, default branch `Main`. `gh` is logged in as `ferasalm`.
- Validation so far: clean-checkout CI 5/5 at `9ebe113`. At `dc952e8`: smoke 145/145, pause tabs 9/9, map integration 32/32, hazard 62/62, pickup 13/13, weapon frames 28/28.
- `.coderabbit.yaml` has `auto_review.drafts: false` and `base_branches: [Main]`. CodeRabbit **never starts by itself** on a draft or on a PR whose base is not `Main`. Post `@coderabbitai review`.
- The main checkout holds untracked user files (two skill folders `.agents/skills/ocgs-code-review` and `ocgs-help`, `.codex/`, `tools/codex/`, `.uid` files, logs). **Never delete, move or stage them.** They break the local Claude mirror check, so CI runs in clean checkouts.
- Existing clean CI checkout: `prototypes/feel-v3/.godot/area-ci-9ebe113` (detached, clean, no `node_modules`; Node finds the parent's).
- Usage now (`usage.mjs`, 2026-11-20): Claude 5h 24%, weekly 86%. Codex weekly about 15% left. agy and OpenCode have no weekly limit. Free virtual memory 10 GB (OpenCode crashes near 250 MB).
- Godot: `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- Your decisions this session: Library = your layout in its own PR; locked-test changes approved ("replace and re-lock", numbers not pinned); growth numbers = your proposal (+6 HP, +4 EN, +5% damage, +1.5% less damage per level); asset folder = **generated library folder (copies)**; moveable = **select/move/copy/paste plus rotate and free placement**.
- What Codex improved (commit `6554c96`, 17 files): shared drafts between F2 and F3, safe saves, a Builders button, a workspace shell. Builders already move placed images and single markers. They do **not** have: a populated asset palette (the three builder asset folders are empty), terrain block select, copy/paste, resize or rotate, a help system (only one-line tooltips), marks/exits editing, or Android support. We extend this code; we do not rewrite it.
- Asset inventory (scout): 1,389 files, 98 MB under `prototypes/feel-v3/assets` (1,241 PNG, 80 WAV, 22 OGG, 24 GIF, plus source files); 197 files in root `assets/`; concept art in `design/art/concepts`. Outside that: `tools/models/bank` 602 MB (3D), `inbox/` 1.8 GB (22k raw downloads). No fonts or voice files exist.

### Priority ladder (do in this order; stop at a pushed checkpoint when the budget says so)
| # | Task | Claude weekly budget (rough) |
|---|---|---|
| T0 | Setup: memory, playbook, preflight probes | 1% |
| T1 | Ship the area PR (draft, CI, CodeRabbit) | 1.5% |
| T2 | Your Library in the game (own PR) | 1% |
| T3 | Automatic leveling (own PR) | 2.5% |
| T4 | Studio milestone 1: library folder, catalog, palette, thumbnails, help system | 3% |
| T5 | Studio milestone 2: select, move, copy, paste, rotate, resize | 3% |
| T6 | Studio milestone 3: help text for everything, map and tuning wiring, launcher | 2% |
| T7 | Pipeline review (is this workflow worth keeping?) | 1% |
Total about 15%, which is more than the 14% left. The weekly limit resets in about 19.5 hours, so T5 to T7 may finish after the reset. **Stop-line:** at 96% weekly finish the current gate, write state, run only free workers. At 98% write the handoff and stop.

---

## Part 1: The routing playbook (T0 saves this part verbatim as `production/orchestration/ROUTING-PLAYBOOK.md`)

### 1.1 Who does what (decision record: best model, why, why not)
| Role | Model and how to call it | Use it for | Why this one | Why not / limits |
|---|---|---|---|---|
| **Lead and executor** | Sonnet 5.5 (this session) | plan, briefs, gates, git and `gh`, user questions, small edits (about 15 lines in 2 files or fewer), final decisions | cheapest model that can orchestrate well | design judgement and risky architecture go to the advisor |
| **Gate writer** | Codex Sol (important tasks) or Sonnet (small ones) | the tests and checks that decide whether a task passes | a weak model can write a test that always passes, or weaken it; the writer must be stronger than the builder | never DeepSeek, GLM or Gemini; works from the spec only, never from the implementation |
| **Advisor** | Opus 5.5 via `/advisor opus` (the user runs it once; saved as `advisorModel`) | **three consults only** (see 1.4) | strong judgement; it reads the whole transcript | each consult re-reads the whole transcript at Opus rates, uncached. Keep chats small. Never use Opus as the main model or as a subagent |
| **Reader (Claude)** | Haiku through `Agent` (`Explore` or `general-purpose`, `model: "haiku"`, effort medium or xhigh, never max) | wide read-only sweeps, running the Godot suites and returning counts, reading logs, doc updates with exact text | cheap and fast; keeps big outputs out of the lead chat | max effort used 19 times the output in a past run; no judgement; cap tool calls in the brief |
| **Builder (code)** | DeepSeek v4.1 flash, effort max, OpenCode on Cloudflare: `worker.mjs run builder-iq <brief> --write --dir <worktree> --no-claude` | GDScript, Node scripts, JSON data, tests written from a spec | free of every weekly limit; precise; passed locked tests in past runs | weak at tone and design; about 700 s for 460 lines; **at most 3 OpenCode workers at once** (5 failed, 6 crashed); needs the working folder set (see 1.6) |
| **Builder (words)** | GLM 5.3 flash, OpenCode: `worker.mjs run builder-eq <brief> --write --dir <worktree> --no-claude` | help text, UX copy, plain-language descriptions | free; good at plain prose | slow; no code |
| **Scout and reviewer** | Gemini 3.8 flash, effort high, agy: `agy -p "<brief>" --model gemini-3.8-flash --effort high --mode plan` (read-only) | independent review of diffs, test-versus-spec checks, inventories, reading screenshots, CodeRabbit triage | different family from DeepSeek; free; reads files | about 20 s start-up; times out on big briefs (keep each under about 400 s of work); invents sources, so **no web lookups**; split big reviews by file |
| **Codex Sol** | GPT-6.2-Sol, effort medium: `codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium ...` (see 1.7) | **gate (test) writing for important tasks**; image sheets through its image tool; the one hardest slice if DeepSeek fails twice; the single independent review of the biggest PR | strongest non-Claude model; OS sandbox; stronger than the builders it checks | Codex weekly 15% left: **up to 8 Sol calls today** (about 4 gate batches, 2 image sheets, 1 review, 1 fallback). After the first call and after each milestone ask the user for the weekly %; stop Codex at 5% left. Not routed in `routing.json` (only Luna is), so call it directly |
| **Codex Terra** | GPT-6.1-Terra, effort medium | screenshot readability review, if Sonnet cannot judge a batch of images | sees images | at most 1 call today |
| **Codex Luna** | GPT-6-Luna, effort low or medium | cheap lookups; fallback scout | cheap | weak reasoning; at most 2 calls today |
| **Claude builder (fallback)** | `Agent` with `subagent_type: builder` (Haiku xhigh) | only when every non-Claude route failed twice | works inside Claude | spends Claude weekly; last resort |

**Review rule:** a builder's work is reviewed by a different model family, never by itself. DeepSeek work goes to Gemini (high) first. The largest PR gets one Codex Sol read-only review. CodeRabbit is the second reviewer on every PR.

### 1.2 The routing decision (step "Evaluate, then route")
1. Taste, feel or an edge case the user must decide? Ask with `AskUserQuestion` (see 1.4 step P7). If it is an architecture choice, consult the advisor first.
2. About 15 lines in 2 files or fewer, location known? **Sonnet edits it directly.** No worker; the brief would cost as much as the edit.
3. Read-only fact finding over many files, or big logs, or running the test suites? **Haiku** (needs Bash and a summary) or **Gemini** (reads files, free). Prefer Gemini when no Claude tool is needed.
4. Code or data to a spec, 40 lines or more, or needing large reads? **DeepSeek builder** in a worktree, after the gates exist.
4b. A test, check or gate? **Never** DeepSeek, GLM or Gemini (a weak writer can write a test that always passes). Important tasks (T3 leveling, the library script, selection and transforms): **Codex Sol** writes it from the spec only. Small ones: **Sonnet** writes it. Sonnet reads every gate in full before it is locked.
5. Prose, help text, UX copy? **GLM**.
6. DeepSeek failed twice on the same step, or the change crosses many systems? **Codex Sol**. If Sol also fails twice: stop and ask the user.
7. Review? Different family from the builder (1.1).
8. Visual check? Sonnet opens one or two screenshots. For a batch, Gemini or Codex Terra.
**Subagent rule:** spawn a subagent (Haiku, or a worker process) only when the edit is big (more than about 150 lines or more than 3 files) or needs large reads (more than about 20k tokens of output) that would bloat this chat. Never for small edits.

### 1.3 POGR review: good to use? Yes, as the skeleton; do not load the skill
`.claude/skills/pogr/SKILL.md` (Plan, Orchestrate, Gate, Review) is sound: non-overlapping slices with file ownership, a brief template, "two failures in a row, stop", a gate record, at most 3 workers, a final report. We copy its brief template (1.7) and its rules. We do **not** run the skill (about 6k tokens of overhead each time). Changes for this job:
| POGR says | Here |
|---|---|
| the lead reads every diff | too costly at 86% weekly. The lead reads `git diff --stat`, the independent reviewer's report, the test output, and only the hunks the reviewer flags |
| tiers are generic; the harness config picks the model | the concrete roster in 1.1 |
| context limits from CONTEXT-POLICY (soft 250k, hard 350k) | update state at **200k** and on any autocompact warning; write the handoff at 300k |
| no usage metering | `usage.mjs` start and end around every task; log it |
| no advisor | three advisor gates (1.4) |
| yes/no gates for the user | keep, but ask with `AskUserQuestion` only at taste and edge cases; the merge question is always asked |
| tests written by whoever builds | tests written by a **stronger** model, with mutants and a grep guard (1.5) |
| CI, PR, CodeRabbit | unchanged: `.agents/skills/ci-pr/SKILL.md` |

### 1.4 The task loop (do every step, in this order, for every task)
| Step | What | Who | Artifact |
|---|---|---|---|
| P0 Evaluate | Read `production/session-state/active.md`, this playbook, and the task card. Restate the task in one line. Rate the risk: low, medium or high | Sonnet | active.md line "in progress" |
| P1 Route | Apply 1.2 to every slice. Write why and why not into the log | Sonnet. **Advisor consult 1** if the risk is high | pipeline-log row |
| P2 Plan | Slice table: ID, goal, owner, files owned, test command, pass condition, depends on. No file in two slices. At most 3 OpenCode workers at once | Sonnet | slice table in the task card |
| P3 Organize | Worktree, branch, `node_modules` junction, Godot `--import`, baseline suite counts, `usage.mjs --start` | Sonnet (commands); Haiku runs the baseline suite | baseline file in scratchpad |
| P4 Gate first | Tests first, written from the spec only (never from the implementation) by a **stronger model than the builder**: Codex Sol for important tasks, Sonnet for small ones. Sonnet reads the changed tests in full. They must **fail on the old code and on the mutants** (1.5). Lock them | Codex Sol or Sonnet writes; Sonnet reads; Haiku runs the mutants; Sonnet locks | locked test files |
| P5 Brief and run | Write the brief file (1.7) in its own step; start the worker in a later step. While it runs, write the next brief. **Do not poll.** | Sonnet writes, worker builds | `production/briefs/2026-11-20/<slice>.md` (never committed) |
| P6 Receive | Read the worker's report (under 300 words), `git -C <wt> status --short`, `git diff --stat`, and the last lines of the test output. Check the **main checkout is unchanged**. Never read a raw worker log whole | Sonnet | gate record line |
| P7 Ask | Taste or edge case: `AskUserQuestion`, at most 4 questions, recommended option first, plain words, per the plain-language rule | Sonnet | recorded decision |
| P8 Finalize | Full suite (Haiku runs it, returns counts and the first failure). Canonical re-lock if tests changed. Screenshots for anything visual. **Advisor consult 2 if a gate failed twice** | Haiku, Sonnet | suite table |
| P9 Review | One independent review by a different family, under 300 words, with the rubric in 1.5. Fix once. A second review only if a fix changed logic | Gemini, or Codex Sol for the largest PR | review note |
| P10 Deliver | Commits, push, PR. Message to the user starting with `## In plain words`: what is in the build, what is NOT in it (from the ledger), where the build is, what to try. Ask for the verdict in plain text and **keep working** on independent tasks; do not idle | Sonnet | PR, `playable-history/<date>-<name>/` build, tag |
| P11 State | Update `production/TLDR.md` (for the user), `active.md`, the ledger rows, `pipeline-log.md`, and one journal line, **after every finished task and slice, when a slice starts, when context passes 200k, and on every autocompact warning** | Sonnet | files on disk |
| P12 Ship | `ci-pr` phases: `npm run ci`, `gh pr checks`, CodeRabbit (at most 2 rounds; triage by a Gemini scout), backup tag, then the merge question. **Advisor consult 3** before marking a PR ready | Sonnet | merged PR (only after the user's yes) |

**Advisor consults:** only these three: (1) before committing to the plan of a high-risk task, (2) after a gate fails twice, (3) before marking a PR ready. Before each consult, write the state to files so the transcript is short.

### 1.5 Gates, locked tests, reviews
- **Locked files** are never edited by a builder. Locks store **absolute paths of the main checkout** (`tests_v4/locks/step0.json`, `step1.json`). In a worktree:
  1. Guard: `git -C <wt> diff --name-only origin/feat/proto-v4-area -- prototypes/feel-v3/tests_v4 prototypes/feel-v3/smoke.gd prototypes/feel-v3/smoke.tscn prototypes/feel-v3/climb_test.gd prototypes/feel-v3/climb_test.tscn` must be empty, except for the files the user approved (T3: only `t_data.gd`, `t_rpg.gd`, `t_interact_ui.gd`, `locks/step0.json`).
  2. New or changed tests: `node "$USERPROFILE/.claude/skills/lean-orchestrator/tools/worker.mjs" lock <worktree test files> --out <scratchpad>/<task>-lock.json`, then `verify <that file>` after every build.
  3. The committed `step0.json` must use main-checkout paths. After the final tests are green, run `worker.mjs lock <the 12 files, worktree paths> --out <scratchpad>/step0-wt.json`, then `sed 's#new-vania-<topic>#new-vania#g' <scratchpad>/step0-wt.json > prototypes/feel-v3/tests_v4/locks/step0.json`. The hashes stay valid because the file contents are the same.
- **Anti-cheat for tests (weak models cut corners):**
  1. A stronger model writes the gate; a different, weaker one builds. The builder never edits a test (the lock and the git guard above).
  2. **Fail first:** every new check must fail on the old code. Record it.
  3. **Mutants:** for each key behavior, Haiku applies one deliberately wrong change in the task worktree (for example `growth()` returns 0; a special ignores ATK), runs the one test scene, and restores the file with `git checkout -- <file>`. Each mutant must fail at least one check. A mutant that passes means the test is too weak: send it back to the writer.
  4. **Value independence:** tests compute their expected numbers from tuning and data files, not from the code under test. After the build, change one tuning value in the worktree (for example `level_hp` 6 to 7), run the test, and confirm it still passes; then restore the file. Hard-coded outputs fail this.
  5. **Grep guard on every test diff:** no `skip`, no `return` before the last check, no `_check(..., true, ...)` with a literal true, no empty test body, and at least as many `_check` calls as the task card lists.
  6. The builder brief and the reviewer rubric both forbid output that is hard-coded or special-cased to match a test, and code that detects a test run.
- **Pass conditions** come from the plan: a count (`34/39`), an exit code, or a screenshot. "Should work" is not a pass. No output means **not run**.
- **Two failures on the same step: stop.** Take the fallback in the brief (next route, smaller slice). If none: ask the user.
- **Reviewer rubric (every review brief carries it):** (1) does the diff do what the task card says and nothing else; (2) any edit outside the owned files; (3) any weakened, skipped or deleted test; (4) numbers hard-coded that belong in tuning or data files; (5) anything in the "NOT in it" list that slipped in; (6) public functions without doc comments; (7) outputs hard-coded or special-cased to match a test, or code that detects a test run. Reply: verdict, then findings as `file:line, claim, severity`, under 300 words.
- **Fewer reviews, not weaker ones:** quality comes from exact briefs, tests first, locked gates and the three advisor consults. Each PR gets one independent review plus CodeRabbit. Deterministic checks (roomreach, smoke) replace review where they cover the risk (T2).

### 1.6 State, logging, thresholds
- `production/TLDR.md` (**for the user**; local and not committed, so it adds no commit noise): bullets in plain words, under 40 lines, rewritten after every task and slice, with the sections `Now`, `Done`, `Next`, `Waiting on you`, `Budget` (Claude weekly %, Codex calls), `Links` (PRs, builds, files to look at), `Risks`. Update it first, before the other state files.
- `production/session-state/active.md` (under 4 KB): the task board, one line per task or slice: `T3-S2 | in progress | DS#2 | brief path | next step`. Status words only: done, in progress, planned, not planned, waiting on user.
- `production/orchestration/pipeline-log.md` (append only, one row per slice): `date | task | slice | route (model, effort) | why | wall minutes | Claude weekly change | Codex calls | first pass? | rework rounds | gate result | reviewer findings (real/total) | note`.
- `production/orchestration/pipeline-journal.md`: after each task, at most 3 lines: worked, failed, change next time.
- After an autocompact or a new chat: **read the files, not the summary**: `active.md`, this playbook, the task card, `pipeline-log.md` tail.
- Handoff file: `production/session-state/handoff-2026-11-20-<topic>.md` with the start prompt (goal, worktree and branch, files to read in order, the single next step with its command, files not to touch, last check results).
- Usage: `cd "$USERPROFILE/.claude/skills/lean-orchestrator" && node tools/usage.mjs --start` before a task and `--end` after (same folder). For Codex, count calls and ask the user for the weekly % after the first Sol call.

### 1.7 Commands and the brief template
```bash
# repo root: C:/Users/AUC/opencode-workspace/workspace/new-vania  (call it $R)
# worktree stacked on the area branch (after the area branch is pushed):
git -C "$R" worktree add ../new-vania-<topic> -b <type>/<topic> origin/feat/proto-v4-area
powershell -NoProfile -Command "New-Item -ItemType Junction -Path 'C:\Users\AUC\opencode-workspace\workspace\new-vania-<topic>\node_modules' -Target 'C:\Users\AUC\opencode-workspace\workspace\new-vania\node_modules'"
ls <wt>/.opencode            # generated links must exist; if not, stop and ask
"$G" --headless --path <wt>/prototypes/feel-v3 --import --log-file <wt>/prototypes/feel-v3/tests_v4/logs/import.log
# DeepSeek builder (foreground, never background; check flags once with: node <tools>/worker.mjs --help)
node "$USERPROFILE/.claude/skills/lean-orchestrator/tools/worker.mjs" run builder-iq <brief.md> --write --dir <wt> --no-claude
# GLM words
node "$USERPROFILE/.claude/skills/lean-orchestrator/tools/worker.mjs" run builder-eq <brief.md> --write --dir <wt> --no-claude
# Gemini high, read-only (run from the worktree so it can read files)
agy -p "$(cat <brief.md>)" --model gemini-3.8-flash --effort high --mode plan
# Codex Sol: gate writer (brief says FILES YOU OWN = the test files only; -s workspace-write), reviewer (-s read-only), or builder. Brief on stdin.
# Codex image sheet: same command; the brief says "use your image generation tool to make ONE sheet of ..., save it as <path>.png". Probe first (T0). Never one image per request.
codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium -s workspace-write --skip-git-repo-check --ephemeral --color never -C <wt> -o <out.md> - < <brief.md>
```
Rules for workers: after every OpenCode run read the diff **in the intended worktree** and check the main checkout is clean (OpenCode once ignored `--dir`). A run that exits 0 with "no files changed" may still have written: read the diff before retrying. Never start a worker in the same message that writes its brief. Free virtual memory must stay above 2 GB before a retry.

**Brief template** (every field filled; a worker has seen nothing else):
```text
BRIEF <task>-<slice>: <short name>        ROUTE: <model, effort>        TIME LIMIT: <minutes>
GOAL: <one plain sentence>
WORKTREE: <path>    BRANCH: <name>
FILES YOU OWN: <exact paths; you may create or change only these>
READ FIRST: <at most 3 paths, with the part to read>
CHANGE: <numbered steps, with function signatures>
CONSTRAINTS: no edits outside FILES YOU OWN; no git; locked tests are read-only (a failing test means the code is wrong);
  numbers go to tuning or data files; doc comment on every public function; save to disk in the first 5 minutes; budget about 15 tool calls then write the file in one go.
CHECK: <command> -> PASS means: <pass condition>
IF IT FAILS TWICE: stop, report the exact error, do not try a third way.
REPORT (under 300 words): status word, files changed, last lines of the check output, anything not run (say "not run").
```

### 1.8 Stop rules
Same step fails twice: stop and ask, recommended option first. Weekly 96%: finish the gate, write state, free workers only. Weekly 98%: handoff and stop. Context 200k: state update. Context 300k: handoff. Anything outside the workspace, paid tools (PixelLab, ElevenLabs), deleting, overwriting, merging, history changes: ask first. Never commit to `Main`. Never force-push. Never `git clean` or `reset --hard`. The user removes worktrees and branches. Stage in a separate command, then commit, then push.

---

## Part 2: Task cards

### T0: Setup (Sonnet, about 25 tool calls, Haiku for nothing)
**Write-set (one approval covers all):** memory files and `MEMORY.md`; `production/TLDR.md`; `production/orchestration/ROUTING-PLAYBOOK.md`, `production/orchestration/pipeline-log.md`, `production/orchestration/pipeline-journal.md`; `production/plans/2026-11-20-execution-plan.md`; one line in `.claude/rules/studio-ops.md`; ledger rows in `production/plans/proto-v4-asks-ledger.md`; `production/session-state/active.md`; `production/briefs/2026-11-20/`. No host settings, no `routing.json`, no `~/.claude` skill files.
1. **Memory** (user-level memory dir):
   - new `feedback-delegate-under-budget.md` (feedback): 2026-11-20 the user reversed "Claude builds directly" because Claude weekly was at 85%: route by cost. Sonnet executes, `/advisor opus` advises at gates, Haiku for exploration and test runs, OpenCode DeepSeek, agy Gemini and Codex for builds and reviews. No subagents for small edits. Update state after every task, at 200k tokens and on autocompact warnings (autocompact runs near 300-400k). Do the first pass right so reviews stay few. **Why** and **How to apply** lines.
   - new `reference-routing-playbook.md` (reference): `production/orchestration/ROUTING-PLAYBOOK.md`, the plan copy, and `pipeline-log.md`.
   - new `project-studio-library-wishlist.md` (project): the user's wish for one asset folder plus builders, thumbnails and "?" on everything, moveable terrain, rotate and free placement; scope is features, not bug hunting.
   - edit `feedback-claude-builds-directly.md`: add "Superseded 2026-11-20 by [[feedback-delegate-under-budget]]; the one-task-per-chat rule stays." Add the three pointers to `MEMORY.md`.
2. **Docs** (worktree-free, in the main checkout on `feat/proto-v4-area`): write the playbook (Part 1 verbatim), copy this plan, create the empty log and journal with their headers, create `production/TLDR.md` (sections in 1.6; never committed), add one line to `.claude/rules/studio-ops.md` under "Routing": `For proto-v4 work the routing in production/orchestration/ROUTING-PLAYBOOK.md overrides the two lines above.` Add ledger rows N22-N26 (below) with status `in progress`.
   - N22 One folder with every asset (generated library, copies). N23 Thumbnail on every asset and on rooms. N24 "?" help on every function and asset, with limits. N25 Moveable terrain and assets: select, move, copy, paste, duplicate, resize, rotate, free placement for decor. N26 Builder and assets easy to use from one place (launcher and README).
3. **Preflight probes** (the "is it really usable" check; one cheap request each; log the result):
   - `node <tools>/worker.mjs doctor`.
   - OpenCode DeepSeek: `worker.mjs ask deepseek-flash "Reply with the word OK"`.
   - agy: `agy -p "Reply with the word OK" --model gemini-3.8-flash --effort high --mode plan`.
   - Codex ids: `codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium -s read-only --skip-git-repo-check --ephemeral --color never -C . -o <scratchpad>/p.md - <<< "Reply with the word OK"`. Repeat once with `gpt-6.1-terra`. **If an id is rejected, mark it unavailable in the playbook and use the next route.**
   - Free memory: `powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory/1024)"` must be above 2000 (MB).
   - Codex image tool: ask Sol to make **one** 64 by 64 test icon with its image generation tool and save it to `<scratchpad>/p.png`. If the tool is not available in `codex exec`, mark it unavailable, skip the art sheets, and tell the user.
   - Python imaging (for slicing the icon sheet): `python -c "import PIL; print(PIL.__version__)"`. If it is missing, the slicer uses Godot (`Image.get_region`) instead.
4. Commit and push on `feat/proto-v4-area`: stage in one command (`git add production/orchestration/ROUTING-PLAYBOOK.md production/orchestration/pipeline-log.md production/orchestration/pipeline-journal.md production/plans/2026-11-20-execution-plan.md .claude/rules/studio-ops.md production/plans/proto-v4-asks-ledger.md`), commit in the next (`docs(orchestration): routing playbook and execution plan for 2026-11-20`, with the attribution line), then push. `active.md` is updated locally (it is mostly ignored; use `git add -u` only if it is tracked and changed).
5. `usage.mjs --start`. Ask the user to run `/advisor opus` if it is not set (check with the user; do not edit settings).
**Gate:** playbook and plan exist in the repo; probes logged; push done. **Checkpoint:** active.md "T0 done".

### T1: Ship the area PR (Sonnet; Phase A below)
Route: Sonnet runs the commands (outputs are short). CodeRabbit triage: Gemini scout (`scout-deep`), one call per round. Fixes: Sonnet directly if small. Review: CodeRabbit and the user (the branch was already validated; no extra independent review). Ask: only the merge question. Deliver: PR link, CI table, CodeRabbit table, in/NOT-in list.
**While CI and CodeRabbit wait, start T2 and the T3/T4 test writing. Never idle.**

### T2: Your Library in the game (Sonnet directly; Phase B below)
Route: Sonnet edits directly (one text file, one JSON edit, one new test); no worker. Review: deterministic (roomreach, roomcheck, a walk test in both directions, smoke); CodeRabbit. Ask: only if roomreach flags the user's layout (show the F2 red warning and ask; never redesign it). Deliver: build in `playable-history/2026-11-20-proto-v4-library/` (exe and APK), tag, and "please walk Church to Library and back".

### T3: Automatic leveling (Phase C and Appendix E below)
| Slice | Who | Files owned | Check | Depends |
|---|---|---|---|---|
| T3-W | **Codex Sol** (gate writer, `-s workspace-write`, the three test files only; Sonnet writes them directly if Sol is unavailable) | `tests_v4/t_data.gd`, `t_rpg.gd`, `t_interact_ui.gd` | the new checks **fail** on the old code; grep guard clean | none |
| T3-R | Sonnet reads the changed parts of the three test files in full; Haiku runs the mutants and the value-independence check (1.5) | none (scratch edits restored with `git checkout`) | every mutant fails a check; report under 300 words | T3-W |
| T3-B | DeepSeek builder | `rpg.gd`, `menu.gd`, `hud.gd`, `data/levels.json`, `tuning.d/rpg.json` | `t_data`, `t_rpg`, `t_math`, `t_interact_ui` pass; no new failure | T3-R |
| T3-D | Haiku (docs with exact text) | `design/decisions.md`, `design/rpg-items.md`, `design/contract.md` | text matches Appendix C4 | T3-B |
Sonnet keeps: the lock, the baseline comparison, the screenshot, the ledger rows, git. Review (P9): Gemini high on the diff against Appendix C and E. Advisor consult 3 before the PR is marked ready. Deliver: build in `playable-history/2026-11-20-proto-v4-autolevel/` (exe and APK), tag, in/NOT-in list.

### T4, T5, T6: the Studio (Appendix D has the slice tables, API lines and tests)
**Art sheets (first thing in T4; Codex image tool; batches only).** (1) ONE UI look sheet: a mock of the Studio screen (palette with thumbnails and categories, the "?" popup, the selection toolbar) in a dark, readable style. (2) ONE icon sheet: about 24 icons on a grid at 64 pixels each (audio, 3D model, source file, concept art, folder, not placeable, "?", select, move, copy, paste, rotate, scale, delete, duplicate, search, favourite, warning, and so on). Sonnet (or Gemini) evaluates each sheet once; at most one re-roll per sheet; keep or drop in one pass. The look sheet goes to you (its path is in `TLDR.md`), and Sonnet turns it into text in the S2 and S3 briefs (colours, spacing, icon size), because DeepSeek cannot see images. The icon sheet is sliced by a small script (`tools/slice_icons.py`, owned by S2) into `editor/icons/<name>.png`, used for non-image assets and toolbar buttons. Budget: at most 2 image calls plus 1 re-roll. Game sprites (crouch slash, hair and scarf, wall latch) are **not** in this plan; Codex reference sheets for them can be tried later (the art-coherence rules in the memory notes apply).
One branch `feat/proto-v4-studio`, one worktree `../new-vania-studio`, one PR opened as a draft after milestone 1 and marked ready after milestone 3. Each milestone ends with a pushed commit, a green suite and a screenshot set. Reviews: Gemini high per milestone (split by slice); **one Codex Sol read-only review** of the whole PR at the end; CodeRabbit once when the PR is ready. Ask: only the verdict after each milestone, in plain text. Deliver: `playable-history/2026-11-20-proto-v4-studio-m<N>/` (exe only; the builders are desktop-only) and a tag per milestone.

### T7: Pipeline review (is this workflow worth keeping?)
Run after T6, or at the stop-line, whichever comes first. Inputs: `pipeline-log.md`, `pipeline-journal.md`, the usage deltas, `~/.claude/skills/lean-orchestrator/METRICS.csv` and `LESSONS.md` (read only). Three read-only reviewers from three families, each under 400 words, each given only those files:
- cost and speed: Gemini high (Claude weekly points per task, worker minutes, Codex calls, idle time).
- quality: Codex Luna medium (first-pass rate, rework rounds, reviewer findings that were real, CodeRabbit findings per PR, defects found after review, test-cheating incidents such as mutants that passed or grep-guard hits).
- process: Haiku scout (compare with earlier runs in METRICS.csv; which rules were followed and which were skipped).
Sonnet synthesizes one page: `production/orchestration/pipeline-review-2026-11-20.md`, with a verdict per routing choice (keep, change, drop), the numbers, and the playbook edits made. One advisor consult on the synthesis. Ask the user before adding lines to the user-level `LESSONS.md` (outside the workspace).

---

## Part 3: Risks and mitigations
| # | Risk | Mitigation |
|---|---|---|
| 1 | Claude budget runs out mid-task | priority ladder, stop-lines (96%, 98%), every task ends at a pushed checkpoint, free workers continue |
| 2 | A route is down or slow (OpenCode slot, agy timeout, Codex id rejected) | preflight probes; at most 3 OpenCode workers; fallbacks in 1.2; two failures then ask |
| 3 | A worker edits files it does not own | ownership list in the brief; `git status` in the worktree and the main checkout after every run; worktrees only |
| 4 | Locked-test paths are absolute | 1.5: temp locks in worktrees, canonical re-lock with `sed`, git-diff guard |
| 5 | A new worktree has no Godot import cache | `--import` once at P3; allow a few minutes |
| 6 | Studio folder bloats the exported game | `studio/.gdignore` is mandatory; compare the exe size with the previous build; the library folder is gitignored and regenerated |
| 7 | Rotating solid images would break collision | rotate and free placement only for decor layers (back and front); solid and tile images stay on the grid; the "?" help states this limit |
| 8 | Many slices touch `room_builder.gd` | one owner per wave; S3 extracts the palette first; S6 then S7 run in order |
| 9 | Context bloat | reports under 300 words; grep and tail instead of whole logs; one screenshot per claim; Haiku runs suites |
| 10 | A weak model drifts from the spec or **cheats on a test** (an always-passing test, a hard-coded output) | a stronger model writes the gates; fail-first, mutants, value independence and the grep guard (1.5); locks; independent review with the cheating item in the rubric |
| 11 | Branch conflicts on shared state files | task branches never touch the ledger or `active.md`; the lead updates them in the main checkout |
| 12 | The advisor re-reads a long transcript | three consults only; state written to files first; small chats |
| 13 | `npm run ci` fails in a worktree | `node_modules` junction; use a clean worktree (never the main checkout, which has the mirror collision) |
| 14 | CodeRabbit does not start | post `@coderabbitai review` by hand on every PR |
| 15 | CRLF line endings on Windows break replaces | check after any scripted replace that the change landed |
| 16 | Android cannot run the builders | documented limit; shown in the "?" help |
| 17 | Builder bugs distract the work | scope is features. A bug found goes to a list in the journal and is fixed only if it blocks a gate |
| 18 | The Codex image tool is not available in `codex exec`, or its sheets look wrong | probe in T0; if unavailable, skip the sheets and tell the user; one re-roll at most; the Studio works without them (generated generic icons) |
| 19 | The Codex weekly budget runs out | up to 8 Sol calls; ask for the % after call 1 and after each milestone; stop at 5% left; Sonnet writes the gates if Codex is gone |

---

## Part 4: User actions and verification
- **You do now:** run `/advisor opus` (or `claude --advisor opus`) if it is not set; approve this plan. Read `production/TLDR.md` any time for progress. Later: play the Library build, the leveling build, and the Studio builds.
- **Verification per task:** T1 CI table (5/5 expected) and PR link; T2 walk test both directions, roomreach, smoke 145/145; T3 suites in Appendix C3 plus a screenshot of the CHARACTER tab at level 1 and level 5; T4 to T6 the slice tests plus screenshots (palette, "?" popup, selection box, rotated image), exe size compared with the last build, and `node tools/asset_library.mjs --dry-run` counts.

---

# Appendices: task detail

## Phase A: ship the area checkpoint (T1)
A1. Preflight (read-only):
```bash
cd C:/Users/AUC/opencode-workspace/workspace/new-vania
git fetch origin --quiet
git rev-parse HEAD origin/feat/proto-v4-area
gh pr list --head feat/proto-v4-area --state all --json number,state,isDraft,url
```
The tip is the T0 docs commit once pushed. If a PR now exists, reuse it and skip A3.

A2. Clean-checkout CI at the pushed tip, in the existing detached worktree:
```bash
W=prototypes/feel-v3/.godot/area-ci-9ebe113
git -C "$W" status --short          # must be empty
git -C "$W" checkout --detach <pushed tip>
cd "$W" && npm run ci -- --skip-install
```
Pass means every step exits 0 (expect 5/5). If a step fails only for a missing module, run `npm ci` once in `$W`, then rerun. A real failure: stop and report.

A3. Open the draft (you authorized this). Body in `<scratchpad>/area-pr-body.md`:
- **Summary:** S0 core, S1 world, S2 interact; F2 room builder and F3 map builder with shared drafts; F4 screenshot notes; pause MAP tab and dev teleport; EQUIPMENT gear list; pickup capacity fix; weapon frame sync; Library route to Church restored (`dc952e8`); the routing playbook and plan docs.
- **In this PR / NOT in this PR**, from `production/plans/proto-v4-asks-ledger.md`. NOT: automatic leveling (N19-N21), crouch level slash (N9), hair and scarf (N10), wall latch (N11), item placing and exit editing in F3, your two-cell Library (kept in `6554c96`, in its own PR), the Studio.
- **Validation:** the counts above and the A2 result.
- **Risk and rollback:** prototype-only paths plus docs; backup tag on `Main` before the merge; merge commit, so one revert undoes it.
- **Refs:** the ledger. End the body with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
```bash
gh pr create --draft --repo ferasalm/new-vania --base Main --head feat/proto-v4-area \
  --title "feat(feel-v4): area checkpoint with builders, pause map and gear" \
  --body-file <scratchpad>/area-pr-body.md
```
If GitHub or the harness asks for approval, show that prompt to the user as it is. Do not work around it.

A4. Checks: `gh pr checks <N> --repo ferasalm/new-vania --watch --interval 30`. On a failure: `gh run view <id> --log-failed`; fix in the main checkout on `feat/proto-v4-area` (small), stage, commit, push.

A5. CodeRabbit: `gh pr comment <N> --body "@coderabbitai review"` (drafts are skipped). Triage by a Gemini scout (`scout-deep`): give it the PR number; it fetches `gh api repos/ferasalm/new-vania/pulls/<N>/comments --paginate` and `.../reviews --paginate`, checks each finding against the code, and returns a table: file:line, claim, real? (evidence), proposed action. Real bug: fix and push. Style point covered by `.claude/rules/prototype-code.md` (prototype code has relaxed standards): reply with that rule. False positive: reply with evidence. **Two rounds at most, then ask the user.**

A6. Merge gate (G2). Show: PR link, CI result, CodeRabbit table, in/NOT-in list. Ask one question: "May I mark PR #N ready, tag Main and merge it?" Only after a yes:
```bash
gh pr ready <N>
git tag -a backup/new-vania-Main-pre-pr<N>-20261120 -m "Revert point before PR #<N>" origin/Main
git push origin backup/new-vania-Main-pre-pr<N>-20261120
gh pr merge <N> --repo ferasalm/new-vania --merge      # no --delete-branch
```
Do not pull `Main` into the main checkout. Update `active.md` with the PR number, merge commit and tag.

## Phase B: your two-cell Library goes into the game (T2)
Facts (checked): between `6554c96` and `dc952e8` only `rooms/library.txt` differs. `rooms/library.props.json` is `[]` in both. `cell_tiles` is 24 by 14, so the draft (48 by 28) is 2 cells wide and 2 tall. Its doors: top-left `D` at row 12 (cell row 0), top-right `D` at row 12 (cell row 0), lower-left `D` at row 25 (cell row 1). It holds marks `1` (suture, behind the `B` column) and `L` (lever), one `m` and one `n`. Current meta `sheets.before.library`: `"cell": [32, 48, 2, 3]`, exits `L0 to scriptorium`, `L2 to church`, `R0 to save`, `L1 bricked`. `library_shift` has its own file and does not change.

B1. Worktree stacked on the area branch (section 1.7 commands, topic `library`, branch `fix/proto-v4-library-two-cell`).

B2. Write the check first (Sonnet, new file `prototypes/feel-v3/tests_dev/d7_library_route.gd` and `.tscn`, copying the pattern of `tests_dev/d6_map.gd`). It checks: (a) Church right door: she arrives in the Library at its **lower-left** door (x under 60, in the lower cell); (b) walking left through that door: she arrives in the Church at its right door; (c) Library top-left leads to the scriptorium and top-right to the save room. Run it with the current three-cell Library (passes), then with only `library.txt` swapped (must **fail** on a or b). Record both.

B3. The change: `git show 6554c96:prototypes/feel-v3/rooms/library.txt > prototypes/feel-v3/rooms/library.txt` (verbatim; do not edit your layout). In `data/rooms_meta.json`, `sheets.before.library`: `"cell": [32, 48, 2, 2]`; exits become `L0 to scriptorium (door)`, `L1 to church (door)`, `R0 to save (door)`; remove the `L2 to church` and the `L1 bricked` entries; keep `marks`.

B4. Checks from `<wt>/prototypes/feel-v3` (all must pass): `python tools/roomreach.py .`, `python tools/roomcheck.py .`, d7 (a, b, c), locked smoke 145/145 (it walks Church to Library), climb PASS, `d6_map` 32/32, `d5_checks`, `t_world`. Locked-file guard (1.5) must be empty. **If roomreach flags something unreachable in your layout, do not redesign it: stop, show the spot, ask.**

B5. Commit `fix(feel-v4): use the user's two-cell Library` (`Refs: production/plans/proto-v4-asks-ledger.md (N8)`), push, open the PR with base `feat/proto-v4-area`, post `@coderabbitai review`. Build the exe and APK into `playable-history/2026-11-20-proto-v4-library/` with `ABOUT.txt`, tag `proto-v4-library-2026-11-20`, push the tag. Merge only after you play it and say yes. If the area PR has merged, retarget with `gh pr edit <N> --base Main`.

## Shared commands (used by T2, T3 and the Studio)
`G="C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"`. Run from `<wt>/prototypes/feel-v3`. Never pipe Godot output; use `--log-file`. `tests_v4/logs/` is untracked: never stage it.
**Full suite in one Bash call** (timeout 600000), one summary line per suite (Haiku runs it and returns only the lines):
```bash
cd <wt>/prototypes/feel-v3
G="C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
for s in tests_v4/t_data tests_v4/t_math tests_v4/t_rpg tests_v4/t_interact_ui tests_v4/t_world tests_v4/t_bosses \
         smoke hazard_test tests_quick/pause_tabs tests_quick/q3_weapon_frames tests_quick/q7_shot tests_dev/d5_checks tests_dev/d6_map; do
  n=$(basename $s); "$G" --headless --path . --log-file tests_v4/logs/run_$n.log res://$s.tscn >/dev/null 2>&1
  echo "$n: $(grep -E 'PASS|FAIL' tests_v4/logs/run_$n.log | tail -1)"
done
"$G" --headless --fixed-fps 60 --path . --log-file tests_v4/logs/run_climb.log res://climb_test.tscn >/dev/null 2>&1
echo "climb: $(grep -E 'PASS|FAIL' tests_v4/logs/run_climb.log | tail -1)"
```
Add the new `tests_dev/d*` scenes of the task to the loop. For a failing suite read only its failing lines: `grep -n FAIL tests_v4/logs/run_<n>.log | head -20`. "Pause tabs 9/9" needs a windowed run with `-- shots`; headless gives 7/7. Report whichever you ran.
Build: `"$G" --headless --path . --export-release "Windows Desktop" build/windows/new-vania-feel-v4.exe` and `"$G" --headless --path . --export-release "Android" build/android/new-vania-feel-v4.apk`. Copy both into `C:/Users/AUC/opencode-workspace/playable-history/<date>-<name>/` with `ABOUT.txt` (what is in it and what is NOT). Never overwrite an existing folder.

## Phase C: automatic leveling (T3)
### The design (your decision; numbers checked)
Each level above 1 adds **+6 HP, +4 EN, +5% attack, +1.5% defence**. Specials use the same attack percent (the level part only; the flat COUPLER and REGULATOR bonus stays on sword hits, as today). MP is the base 60 plus gear only. A level-up still refills HP, EN and MP. There are no points, no AUTO, no MAGIC stat, no reset, and no menu opens. All stats come from `R.level`, so old snapshots keep level, XP, items and gear.
Pacing check: a full clear of today's rooms gives level 4 before the Pallbearer, level 5 after it, level 7 after Arnetria (90 / 170 / 316 XP). Level 10 needs 540 XP, so levels 8 to 10 only come from farming.
| Level | HP | EN | MP | ATK % (Dirge 10 becomes) | DEF % | SPC % (blade wave 30 becomes) |
|---|---|---|---|---|---|---|
| 1 | 100 | 100 | 60 | 100 (10) | 0 | 100 (30) |
| 4 | 118 | 112 | 60 | 115 (12) | 4.5 | 115 (35) |
| 5 | 124 | 116 | 60 | 120 (12) | 6 | 120 (36) |
| 7 | 136 | 124 | 60 | 130 (13) | 9 | 130 (39) |
| 10 | 154 | 136 | 60 | 145 (15) | 13.5 | 145 (44) |
**GDD comparison (`design/rpg-items.md` section 3.2, the old automatic split):** level 5: HP 130, EN 100, ATK 124, DEF 3; level 7: 140, 108, 132, 6; level 10: 160, 108, 148, 9. Sword hits match (12, 13, 15). HP is about 5% lower. EN is higher (124 against 108 at level 7). DEF is about double. Specials are 10 to 25% stronger because they follow ATK (your ruling). You saw this and **kept your numbers**. All values are tunable in F1; no locked test pins them.

### C0. Worktree and baseline
Worktree `../new-vania-autolevel`, branch `feat/proto-v4-autolevel`, from `origin/feat/proto-v4-area` (1.7). Haiku runs the full suite and saves the counts to `<scratchpad>/c-baseline.txt`. `t_interact_ui` is not fully green today (34/39 was last recorded): list its failing check names; they must be the same afterwards, with no new failure.

### C1. Tests first (T3-W, T3-R)
Codex Sol (gate writer; `-s workspace-write`; the three test files only; the brief is Appendix E plus the old test lines) writes the changes listed in Appendix E. If Sol is unavailable, Sonnet writes them. Sonnet reads the changed parts of all three files in full. Run them against the **old** code: the new checks must fail; record it. Run the mutants and the value-independence check (1.5), then the grep guard. Then lock: temp lock file in the scratchpad (1.5). Do not touch `t_math`, `t_world`, `t_bosses`, `smoke`, `climb_test` or `hazard_test`.

### C2. Code and data (T3-B)
- `data/levels.json`: keep `base`. Replace `stats` and `auto_order` with `"growth": {"hp": {"label":"HP","key":"level_hp","help":"..."}, "en": {...,"key":"level_en"}, "atk": {...,"key":"level_atk"}, "def": {...,"key":"level_def"}}`. Each entry has a one-sentence `help`.
- `tuning.d/rpg.json`: remove `points_per_level`, `vigor_hp`, `power_atk`, `guard_def`, `stamina_en`, `magic_special`, `magic_mp`. Add `level_hp` (6, 0 to 20, step 1, "Each level: health +", "6 is a little more than one ghost touch."), `level_en` (4, 0 to 15, step 1, "Each level: energy +", "A swing costs 12, so three levels add one swing."), `level_atk` (5, 0 to 15, step 1, "Each level: damage %", "Sword hits and specials. 5 makes a Dirge hit of 10 into 12 by level 5."), `level_def` (1.5, 0 to 5, step 0.5, "Each level: less damage %", "Enemy hits only, not traps. Never above Defence: most."). Reword the `help` of `start_level` ("For testing; her stats grow with the level.") and `levelup_refill` ("1 refills all three bars at once; 0 only raises her stats.").
- `rpg.gd` (autoload `R`): remove `STATS`, `points`, `alloc`, `spend()`, `auto_allocate()`, `_stats_dict()`. Change `signal leveled(level: int)`. Add `func growth(kind: String) -> float` returning `float(level - 1) * T.v(levels.growth[kind].key)`, or 0 when missing. `max_hp` = base + growth("hp") + gear, floored as today. `max_en` = base + growth("en") + gear. `max_mp` = base + gear only. `atk` = 100 + growth("atk") + gear. `def` = min(cap, growth("def") + gear). `special_pct` = 100 + growth("atk"). `add_xp`: no points; set `level` before `_refill()` (already the order); emit `leveled(level)` and `stats_changed`. `snapshot` and `reset`: drop points and alloc. `restore` and `debug_set`: ignore old `points` and `alloc` keys. Update the header comment.
- `hud.gd:112-116`: drop the `+N PTS` suffix.
- `menu.gd`: rewrite `_character_rows()` (`:391-402`); every row has `cb: null`. Rows: `LV n   XP x   NEXT y` (`NEXT MAX` at the cap; use `RpgMath.xp_total`), `HP`, `EN`, `MP`, `ATK %`, `DEF %`, `SPC %`, and `NEXT LEVEL  HP +6  EN +4  ATK +5%  DEF +1.5%` (read from tuning; left out at the cap). Delete `_spend`, `_auto` (`:405-411`) and `offer_points` (`:188-190`). Add a small `_pct(v)` that prints `4.5` or `4`, and use it for DEF on CHARACTER and in the EQUIPMENT summary row (`:441-457`). Do not restyle anything. The `debug_rows`, `debug_tap` and `debug_press` hooks stay.
- `main.gd`: **no change** (597 lines; the locked limit is 600).
- Sweep: `grep -rn -E "R\.(points|alloc|spend|auto_allocate|STATS)|offer_points|points_per_level|vigor_hp|power_atk|guard_def|stamina_en|magic_special|magic_mp" --include=*.gd --include=*.json --include=*.tscn .` (exclude `.godot/` and `_dbg/`) returns nothing outside the design docs.

### C3. Verify
`t_data`, `t_rpg`, `t_math` pass. `t_interact_ui` has no failure beyond the baseline list. `t_world`, `t_bosses`, smoke 145/145, hazard 62/62, climb PASS, `q7_shot` 13/13, `q3_weapon_frames` 28/28, `d5_checks`, `d6_map` pass. Run the guard in 1.5. Canonical re-lock of `step0.json` (1.5 step 3), then `worker.mjs verify` in the main checkout is meaningful only after the merge, so also run `node -e` to compare the hashes of the 12 worktree files with the new lock. Screenshot proof: run `tests_quick/q4_menu_shot.tscn` windowed; open the CHARACTER tab PNG at level 1 and at level 5 (`R.debug_set({"level":5})` in the probe or the F1 `start_level`).

### C4. Docs (one Haiku subagent, `model: "haiku"`, effort low, exact text in the brief)
- `design/decisions.md`: a new dated decision (2026-11-20, user): automatic leveling replaces decision 6; it covers N19 and N20. Add a row to the "GDD statement / Now" departures table for `design/gdd/health-damage.md:30` and `:73` ("a training point is a choice you make at the cache, not a curve that happens to you"): now automatic growth every level, no points.
- `design/rpg-items.md` section 3.1, 3.2 and the CHARACTER UI spec (`:312-318`): a "Superseded 2026-11-20" note plus the growth table above. Do not rewrite the rest.
- `design/contract.md` R interface (`:332-339`): a one-line superseded note.
The lead updates the ledger: C14 and D7 done (automatic); N19 not planned (no points to reset); N20 done; N21 done (CHARACTER shows LV, XP, NEXT, HP, EN, MP, ATK, DEF, SPC); and `active.md`.

### C5. Ship
Commit 1: `test(feel-v4): check automatic level growth instead of point spending` (the 3 tests and `step0.json`). Commit 2: `feat(feel-v4): grow Pandora's stats automatically at each level-up` (code, data, docs). Each has `Refs: production/plans/proto-v4-asks-ledger.md (C14, D7, N19-N21)`. Push. Open the PR with base `feat/proto-v4-area`; post `@coderabbitai review`; two rounds at most. Build into `playable-history/2026-11-20-proto-v4-autolevel/`, tag `proto-v4-autolevel-2026-11-20`, push the tag. **NOT in it:** your Library (own PR), N9 crouch slash, N10 hair and scarf, N11 wall latch, D1 balance pass, a level-up banner. Merge only after you play it and say yes; retarget to `Main` after the area PR merges.

## Appendix D: the Studio (T4, T5, T6)
**Scope: features, not bug hunting.** Known limits are written into the "?" help.
**The folder:** `prototypes/feel-v3/studio/` holds `README.md`, `.gdignore` (**mandatory**: stops Godot importing and exporting the copies), `catalog.json` (tracked), `help/help.json` (tracked), `open-studio.cmd` (starts the game with `-- --builder-workspace=<repo path>`; regenerates the library if it is missing), and `library/` (copies; **gitignored**, regenerated by `node tools/asset_library.mjs`). The builder code stays in `prototypes/feel-v3/editor/` because Godot needs it inside the project; the README says so.
**What the library copies:** every image, sound and source file under `prototypes/feel-v3/assets/` and root `assets/`, plus `design/art/concepts/`. **Catalog only, not copied** (too big, or raw): `tools/models/bank` (602 MB of 3D), `inbox/` (1.8 GB of downloads), `tools/pristine`, `art_proof/`, `shots/`, `_dbg/`. The README states this plainly.
**Category map** (path prefix to library folder): `assets/{pandora,hero,hero_v2,sprites-pandora,2x/pandora,2x/pandora_b}` to `characters/pandora/<variant>`; `assets/{hound,ghost,choir,spitter,warden,crab,leech,moth,organ,scribe}` and `2x/` copies to `enemies/<name>/<1x|2x>`; `assets/boss`, `2x/boss` to `bosses`; `assets/env`, `2x/env` to `environment/<1x|2x>`; `fx`, `weapon`, `items`, `palettes` to the same names; `audio/music` and `audio/sfx/**` to `audio/music` and `audio/sfx/<sub>`; `references`, `hero_2d_base`, `pandora_proportion_study`, `hero_3d_preview` to `source/<name>`; root `assets/{art,processed,audio,umbrella}` to `root-assets/<name>`; `design/art/concepts` to `concepts`; anything else to `other`.

### Slices, owners and tests (non-overlapping files)
| Slice | Who | Files owned | Behavior and API | Tests (written first, locked) | Depends |
|---|---|---|---|---|---|
| **H1a-c** | Gemini high, three read-only scouts | none (return text) | facts sheets: every control, key, tool and option with exact label, what it does, limits visible in code, `file:line`. H1a `room_builder.gd`; H1b `map_builder.gd`, `dev_hub.gd`, `note_tool.gd`; H1c `tuning_panel.gd`, `props_layer.gd`, `room_doc.gd`. Sonnet saves them to `production/briefs/2026-11-20/H1*-facts.md` | none | none |
| **S1** library script | DeepSeek | `tools/asset_library.mjs`, `tools/asset_library.test.mjs`, `studio/README.md`, `studio/.gdignore`, one `.gitignore` line `prototypes/feel-v3/studio/library/` | `node tools/asset_library.mjs [--dry-run] [--src <dir>] [--out <dir>]`: scans the sources, copies by the category map, writes `studio/catalog.json`: `{version, generated, categories:[{id,count}], entries:[{id,name,category,sub,kind:"image\|audio\|source\|3d\|inbox",path,source,w,h,bytes,tags,placeable:"tiles\|props\|backdrops\|null",help_key}]}`. Idempotent. Never writes outside `studio/`. Catalog-only kinds are never copied | `node --test tools/asset_library.test.mjs`: fixture tree maps correctly; a second run changes nothing; `--dry-run` writes nothing; `bank` and `inbox` are catalog-only; schema valid; real run: image count equals the number found under the sources | none |
| **S2** help system | DeepSeek | `editor/ed_help.gd`, `editor/workspace_shell.gd`, `tools/slice_icons.py`, `editor/icons/*.png`, `studio/help/README.md`, a 5-entry seed `studio/help/help.json`, `tests_dev/d8_help.gd` and `.tscn` | `EdHelp.attach(control, key)`, `EdHelp.show(key)`, `EdHelp.has(key)`. A popup shows title, optional thumbnail (catalog id), "What it is", "How to use", "Limits" (bullets), "Keys". A missing key shows "No help written yet" and never crashes. `Shell.button(parent, label, action, tooltip, help_key := "")` adds a small "?" button when `help_key` is set | d8: loads a fixture json; show and hide; missing key; a button with `help_key` gets a "?" child; headless | none |
| **S3** palette | DeepSeek | `editor/ed_catalog.gd`, `editor/ed_palette.gd`, `editor/room_builder.gd`, `editor/ed_assets.gd`, `tests_dev/d9_palette.gd` and `.tscn` | the palette code moves from `room_builder.gd` into `ed_palette.gd`. `EdCatalog.load(root)`, `categories()`, `search(text, category)`, `entry(id)`. A search box, a category tree, 48 px thumbnails with a cache, a recent list, an info pane (name, category, size, source). Placeable entries (`placeable` set) place as props; the rest are shown with "not placeable: <reason>". Every item has a "?" with key `asset:<id>`. `EdAssets` scans `studio/library` first, then `assets/editor` | d9 with a fixture catalog: categories and counts; search by name, tag and category; a placeable entry adds a prop; a non-placeable one does not; thumbnail cache hit; "?" key resolves | S1, S2 |
| **S4** map thumbnails | DeepSeek | `editor/ed_thumbs.gd`, `editor/map_builder.gd`, `tests_dev/d10_thumbs.gd` and `.tscn` | `EdThumbs.room(doc_or_text, scale)` returns a texture: one coloured pixel per cell (terrain, hazard, enemy, door, mark), scaled. F3 room list shows it; every F3 button gets a help key | d10: a known small room gives the expected pixel colours at known cells; the F3 list items carry a texture; help keys resolve | S2 |
| **S5** tuning "?" | DeepSeek | `tuning_panel.gd`, `tests_dev/d11_tuning_help.gd` and `.tscn` | each row gets a "?" showing label, help, range, default and saved value | d11: for every tuning key the popup text contains its `help`; no crash on the choice pickers | S2 |
| **S6** select and move | DeepSeek | `editor/ed_selection.gd`, `editor/room_doc.gd`, `editor/room_builder.gd`, `tests_dev/d12_selection.gd` and `.tscn` | Shift-drag box over terrain cells, markers, enemies, traps and images; move, copy, paste, delete, duplicate; Ctrl+C, Ctrl+X, Ctrl+V; arrow nudge; clipboard in memory. `RoomDoc.cut_region(rect)`, `RoomDoc.paste_region(origin, block)` | d12: a region move keeps cells and images and undoes in one step; copy and paste; paste past the edge is clipped with a message; each operation is one undo step; the saved text round-trips | S3 |
| **S7** rotate, resize, free | DeepSeek | `editor/props_layer.gd`, `editor/room_doc.gd`, `editor/room_builder.gd`, `tests_dev/d13_props_xform.gd` and `.tscn` | props gain optional `rot` (degrees, -180 to 180) and `scale` (0.25 to 4, steps of 0.25); free (off-grid) position. **Decor layers only (back, front).** Solid and tile images stay on the grid and ignore rotate, scale and free placement, with a message. R key and buttons rotate by 15 degrees; scale keys; a "free" toggle. Missing fields mean no change, so old rooms load and draw exactly as before | d13: round trip of `rot`, `scale`, free x,y; an old file without them draws unchanged; a solid image refuses rotation; the drawn node's transform matches the data | S6 |
| **S8** help text | GLM | `studio/help/help.json` | one entry per function, key, glyph, tool and asset category (about 150), from the H1 facts and the final code: plain words, what it is, how to use it, limits (for example "decor only", "desktop only", "grid snap"). No jargon | d14 (S9) | S7, H1 |
| **S9** wiring and launcher | DeepSeek | `editor/dev_hub.gd`, `studio/open-studio.cmd`, `studio/README.md`, `tests_dev/d14_help_coverage.gd` and `.tscn` | every builder control has a help key; a "Studio" entry in the Dev hub shows the library path; the launcher | d14: every control created by F2, F3 and the tuning panel has a key with an entry; every catalog category has help | S8 |

**Gate writers:** Codex Sol writes the tests for S1, S3, S6 and S7 (the important ones). Sonnet writes d8, d10, d11 and d14. DeepSeek, GLM and Gemini never write tests. Every gate goes through fail-first, mutants, value independence and the grep guard (1.5) before it is locked.

### Waves (never more than 3 OpenCode workers at once)
| Wave | Runs | Gate before the next |
|---|---|---|
| W2 | Codex Sol: T3 tests (call 1); tests for S1 and S3 (call 2); the two art sheets (calls 3 and 4). Sonnet writes the tests for S2, S4, S5. agy H1a, H1b, H1c | tests fail on old code; Sonnet reads every gate in full; mutants; grep guard; locks |
| W3 | DS#1 T3-B; DS#2 S1; DS#3 S2; Sonnet reviews T3 | T3 suite green, S1 and S2 tests green; T3 review; T3 PR |
| W4 | S3, S4, S5 in parallel (DS#1, #2, #3), against the locked tests | d9, d10, d11 green; value-independence check; milestone 1 review; draft PR; build and tag M1 |
| W5 | Codex Sol: tests for S6 and S7 (one batch); Sonnet reads, runs mutants, locks; then S6; then S7 | d12, d13 green; milestone 2 review; build and tag M2 |
| W6 | S8 (GLM) then S9 (DeepSeek); Haiku runs the full suite; Gemini and Codex Sol reviews | d14 green; full suite; Sol review fixed once; CodeRabbit; build and tag M3 |
If Sol is needed as a fallback builder (DeepSeek failed twice on a slice), it takes only that slice, in the same worktree after the failed diff is saved to the scratchpad and the files are restored from git.

## Appendix E: approved changeset for the locked tests (user approved 2026-11-20: "replace and re-lock"; numbers not pinned)
Only these edits. Anything else in a locked file needs a new approval. `_tv(key)` returns NAN for a missing key, so a missing key fails the check.

**`tests_v4/t_data.gd`** (10 old checks become 5)
- `:12-13`: replace `STAT_IDS` and `AUTO_ORDER` with `const GROWTH_IDS := ["hp", "en", "atk", "def"]` and `const GONE_KEYS := ["points_per_level", "vigor_hp", "power_atk", "guard_def", "stamina_en", "magic_special", "magic_mp"]`.
- `:151-156` and `:158` (7 checks) become 2: `"every level raises HP, EN, ATK and DEF (gain above 0)"` (`_tv(k) > 0` for `level_hp`, `level_en`, `level_atk`, `level_def`) and `"no points, MAGIC or AUTO keys remain in tuning"` (no `GONE_KEYS` entry is in `T.data`). `:157` and `:159-164` stay.
- `:336-355` (3 checks) become 3; `"levels.json base points at the real tuning keys"` stays. `"levels.json growth names HP, EN, ATK and DEF"` (exactly the four `GROWTH_IDS`); `"every growth entry points at a real tuning key"` (each has `label`, `help`, `key`, and `T.data.has(key)`); `"levels.json has no stats or AUTO order (no manual allocation)"`.

**`tests_v4/t_rpg.gd`** (7 old checks become 7, plus wording)
- `:91` becomes `func _on_leveled(_lvl: int) -> void:`.
- `:114` `r_needs`: remove `"spend"` and `"auto_allocate"`; add `"growth"`. `:119` props: remove `"points"` and `"alloc"`.
- `:133` name becomes `"R.reset() starts her at level 1"`. `:136-138` becomes `"add_xp(20) at L1 gives L2 and exactly one leveled"` (drop the points term). `:141-144` becomes `"add_xp(70) from L1 gives L3"`.
- `:152-166` refill: read `max_hp`, `max_en` and `max_mp` **after** `add_xp(20)`. Name and the rest stay.
- `:168-208` (the six spend checks and the AUTO check) become one block, `# --- automatic growth (user decision 2026-11-20) ---`: `_reset_all()`, read the L1 values, `add_xp(90)` (level 4, three levels of growth). Checks: (1) max HP is 3 times `level_hp` higher; (2) max EN is 3 times `level_en` higher; (3) ATK is 3 times `level_atk` higher; (4) DEF is 3 times `level_def` higher, compared with `min(def_cap, ...)`; (5) MP does not grow with levels; (6) `special_pct == atk` with no gear and `hit_damage(30, true) == int(round(30 * atk / 100))`; (7) `"an old save with points loads: level, XP, items and gear kept; stats come from the level"`: `restore()` with `{"level": 6, "xp": 210, "points": 3, "alloc": {"vigor": 4, "power": 2, "guard": 0, "stamina": 0, "magic": 1}, "items": {"suture": 2}, "owned_gear": ["<harness id>"], "equip": {"harness1": "<harness id>"}}`, then assert level 6, xp 210, `count("suture") == 2`, `equip.harness1` kept, and `max_hp == player_hp + 5 * level_hp`. Take the harness id from `data/gear.json`; pick one with no HP effect (for example the CEREMENT harness).

**`tests_v4/t_interact_ui.gd`** (3 old checks become 3)
- `:7` header: "the level-up offer" becomes "no level-up prompt". `:462` becomes `"CHARACTER shows her stats"`; `:466` becomes `"a level-up opens no menu"` (the no-menu fallback names).
- `:504-533`: `_reset_all()`; open CHARACTER and save `rows1`; close; `add_xp(20)`; open CHARACTER again and save `rows2`; close. Check `"CHARACTER shows LV XP NEXT HP EN MP ATK DEF SPC, with no AUTO or points row"` (every label in `rows2`; neither `AUTO` nor `PTS`). Check `"the ATK row grows after a level-up"` (`rows1` contains `ATK 100%`; `rows2` contains `"ATK %d%%" % int(round(atk()))`, which is `ATK 105%`).
- `:615-626`: `_reset_all()`, close the menu if open, `add_xp(20)`, wait 5 frames. Check `"a level-up opens no menu"`: `not menu.is_open and not get_tree().paused`.

**Re-lock:** the same 12 paths into `tests_v4/locks/step0.json` (canonical paths, 1.5). `step1.json` does not change. Name these edits in the PR body as "locked test changes approved by the user on 2026-11-20".

## Commits
End every commit message with the attribution line from the current system reminder (Co-Authored-By). End PR bodies with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Stage in a separate command, then commit, then push. Never `git add production/briefs`, `tests_v4/logs`, or the user's untracked files.
