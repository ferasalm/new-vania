# Routing playbook for proto-v4 (written 2026-11-20)

- **This file:** `production/orchestration/ROUTING-PLAYBOOK.md`. Plan with task cards and appendices: `production/plans/2026-11-20-execution-plan.md`. Slice log: `production/orchestration/pipeline-log.md`. Journal: `pipeline-journal.md`. Progress for the user: `production/TLDR.md` (local, untracked).
- For proto-v4 work this playbook overrides the "Routing" lines in `.claude/rules/studio-ops.md` (cheap workers first still applies; the roster and gate rules here are concrete).
- Read this after every autocompact or new chat, together with `production/session-state/active.md` and the tail of `pipeline-log.md`.
- Routes that a preflight probe marks unavailable are listed under "Preflight results" at the end; skip them and take the next route in 1.2.

## Part 1: The routing playbook

### 1.1 Who does what (decision record: best model, why, why not)
| Role | Model and how to call it | Use it for | Why this one | Why not / limits |
|---|---|---|---|---|
| **Lead and executor** | Sonnet 5.5 (this session) | plan, briefs, gates, git and `gh`, user questions, small edits (about 15 lines in 2 files or fewer), final decisions | cheapest model that can orchestrate well | design judgement and risky architecture go to the advisor |
| **Gate writer** | Codex Sol (important tasks) or Sonnet (small ones) | the tests and checks that decide whether a task passes | a weak model can write a test that always passes, or weaken it; the writer must be stronger than the builder | never DeepSeek, GLM or Gemini; works from the spec only, never from the implementation |
| **Advisor** | Opus 5.5 via `/advisor opus` (the user runs it once; saved as `advisorModel`) | **three consults only** (see 1.4) | strong judgement; it reads the whole transcript | each consult re-reads the whole transcript at Opus rates, uncached. Keep chats small. Never use Opus as the main model or as a subagent |
| **Reader (Claude)** | Haiku through `Agent` (`Explore` or `general-purpose`, `model: "haiku"`, effort medium or xhigh, never max) | wide read-only sweeps, running the Godot suites and returning counts, reading logs, doc updates with exact text | cheap and fast; keeps big outputs out of the lead chat | max effort used 19 times the output in a past run; no judgement; cap tool calls in the brief |
| **Builder (code)** | DeepSeek v4.1 flash, effort max, OpenCode on Cloudflare: `worker.mjs run builder-iq <brief> --write --dir <worktree> --no-claude` | GDScript, Node scripts, JSON data, tests written from a spec | free of every weekly limit; precise; passed locked tests in past runs | weak at tone and design; about 700 s for 460 lines; **at most 3 OpenCode workers at once** (5 failed, 6 crashed); needs the working folder set (see 1.7) |
| **Builder (words)** | GLM 5.3 flash, OpenCode: `worker.mjs run builder-eq <brief> --write --dir <worktree> --no-claude` | help text, UX copy, plain-language descriptions | free; good at plain prose | slow; no code |
| **Scout and reviewer** | Gemini 3.8 flash, effort high, agy: `agy -p "<brief>" --model gemini-3.8-flash --effort high --mode plan` (read-only) | independent review of diffs, test-versus-spec checks, inventories, reading screenshots, CodeRabbit triage | different family from DeepSeek; free; reads files | about 20 s start-up; times out on big briefs (keep each under about 400 s of work); invents sources, so **no web lookups**; split big reviews by file |
| **Codex Sol** | GPT-6.2-Sol, effort medium: `codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium ...` (see 1.7) | **gate (test) writing for important tasks**; image sheets through its image tool; the one hardest slice if DeepSeek fails twice; the single independent review of the biggest PR | strongest non-Claude model; OS sandbox; stronger than the builders it checks | Codex weekly 15% left: **up to 5 Sol calls until the weekly % is measured** (each call costs about 60k tokens and about 100 s before any work, so batch: 2 gate batches, 1 batch of art sheets, 1 review, 1 fallback). After the first call and after each milestone ask the user for the weekly %; stop Codex at 5% left. Not routed in `routing.json` (only Luna is), so call it directly |
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
timeout 600 codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium -s workspace-write --skip-git-repo-check --ephemeral --ignore-user-config --color never -C <wt> -o <out.md> - < <brief.md>
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

## Preflight results (T0, 2026-11-20; update when a route changes)
| Route | Result | Note |
|---|---|---|
| `worker.mjs doctor` | all routers READY | OpenCode v2.2.7 (cloudflare, openrouter), agy, claude, codex, hermes |
| DeepSeek v4.1 flash (OpenCode, max) | OK, 31 s | `worker.mjs ask <kind> <brief FILE>` takes a file path, not text, and runs read-only (plan mode). Building needs `run ... --write --dir <wt>` |
| Gemini 3.8 flash high (agy) | OK | `agy -p "<text>" --model gemini-3.8-flash --effort high --mode plan` |
| Codex Terra (`gpt-6.1-terra`) | OK, exits normally | about 35k tokens for a one-word reply |
| Codex Sol (`gpt-6.2-sol`) | **works only with `--ignore-user-config`** | without it `codex exec` answers but never exits (reconnect loop, marketplace and models refresh time out; killed at 140 s). With it: exit 0 in 100 s, 62k tokens for one word. Always wrap in `timeout`, pass `--ignore-user-config`, and read results from the worktree or the `-o` file |
| Codex image tool | **not proven** | the first attempt (no `--ignore-user-config`) timed out at 280 s and wrote no file. Retry once at the start of T4 with `--ignore-user-config` and `timeout 400`; if it fails, skip the art sheets and tell the user |
| Free virtual memory | 13,914 MB | above the 2,000 MB floor |
| Python Pillow | 12.0.0 | available for the icon slicer |
| Network | slow at probe time (github 8 s) | explains the Codex timeouts; recheck before long Codex runs |
Codex calls used in T0: 4 (Terra 1, Sol 3; two of them timed out). Ask the user for the Codex weekly % before the next Sol call.
