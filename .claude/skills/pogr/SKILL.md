---
name: pogr
description: "Plan, Orchestrate, Gate, Review: run any job with more than one step as non-overlapping slices given to the cheapest workers that can do them well, with a check on every slice and a full review at the end."
argument-hint: "[goal in one sentence] [--budget <minutes or usage>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TodoWrite
agent: producer
---

# POGR: Plan, Orchestrate, Gate, Review

POGR is the house way to run a job that has more than one step. The session
that runs this skill is **the lead**. The lead plans, hands out slices, checks
every result and reviews the whole. Workers build.

Follow the four phases in order. Do every numbered step. Do not skip a step
because it looks obvious.

**Status words, always:** done | in progress | planned | not planned | waiting on user.

**This skill points to the house rules. It does not replace them:**

| Topic | Read |
|---|---|
| Collaboration, checkpoints, coding standards | `AGENTS.md` |
| Context budget and handoff modes | `production/orchestration/CONTEXT-POLICY.md` |
| Worktree, commit, PR, CodeRabbit, merge commands | `/ci-pr` (`.agents/skills/ci-pr/SKILL.md`) |
| A full spec-to-ship pipeline with a Dev and QA loop | `.agents/skills/agents-orchestrator/SKILL.md` |
| Claude Code routing and gates G1 to G3 | `.claude/rules/studio-ops.md` (Claude Code only) |
| Writing or changing a skill | `docs/authoring-skills.md` |

If this skill and `AGENTS.md` disagree, `AGENTS.md` wins. Tell the user.

---

## When not to use it

- **One-step tasks.** One file, one change, one check: just do it.
- **A question.** Answer it. Do not plan.
- **A talk about what the user wants.** That is a conversation, not a job. Run
  POGR after the goal is clear.
- **A job that a dedicated skill already covers end to end** (for example
  `/dev-story` for one story). Use that skill. POGR may wrap several of them.

Rule of thumb: if you cannot name at least two slices, do not use POGR.

---

## Phase 1: PLAN

Nothing is written or changed in this phase except the plan itself.

1. **Restate the goal** in one plain sentence. Show it to the user. If you
   cannot write it in one sentence, ask one Yes / No question with the
   question tool and wait.
2. **Read-only sweep.** Search first, then read at most the few parts you need.
   Find: the files the job touches, the test commands that exist, the current
   branch and worktree, and the state file
   `production/session-state/active.md`. Change nothing.
3. **Split the work into slices.** Slices must not overlap: no file belongs to
   two slices. Write one row per slice:

   | Field | Rule |
   |---|---|
   | ID | S1, S2, ... |
   | Goal | One plain sentence. |
   | Owner | A role from the tier table in Phase 2. |
   | Files it owns | Exact paths. A new file counts. Nobody else writes them. |
   | Test command | One command that can be pasted and run. |
   | Pass condition | What the output must show, for example `58/58 passed` or `exit code 0`. |
   | Depends on | Slice IDs that must finish first, or `none`. |

   If two slices need the same file, merge them or give the file to one slice
   and make the other wait for it.
4. **Name what the lead keeps.** The lead always keeps: the plan, the briefs,
   every gate, the review, all git work in a shared worktree, every question to
   the user, and any work where feel or judgement decides the result.
5. **Set a budget and a stop time.** Write both down: a time or usage budget
   (for example 90 minutes) and a clock time when work stops and the handoff is
   written. Keep the last 10 percent of the budget for Phase 4. Context limits
   come from `production/orchestration/CONTEXT-POLICY.md`.
6. **List what needs a yes first** (see Phase 3, step 6). Ask now, not halfway.
7. **Write the plan** to `production/session-state/active.md`: goal, slice
   table, what the lead keeps, budget, stop time, open questions. Keep the file
   under 4 KB. Ask the user "May I write the plan to
   `production/session-state/active.md`?" unless they already said yes.

**Plan gate:** show the slice table and ask one Yes / No question: "Start with
this plan?" Do not start Phase 2 before a yes.

---

## Phase 2: ORCHESTRATE

### Step 1: Write one brief per slice

Use this template every time. Do not leave a field empty. A brief must make
sense to a worker that has seen nothing else.

```text
BRIEF <slice ID>: <short name>
GOAL: <one plain sentence>
FILES YOU OWN: <exact paths; you may create or change only these>
READ FIRST: <at most 3 paths, with the part to read>
CHANGE: <the exact change, as numbered steps>
CONSTRAINTS:
- Do not touch any file outside FILES YOU OWN.
- Do not run git. (Leave this line out only if the worker has its own worktree.)
- Do not weaken, skip or delete a test.
- <job rules: legal, style, paths that must never be opened>
CHECK: <the test command> -> PASS means: <pass condition>
IF IT FAILS TWICE: stop. Report the exact error. Do not try a third way.
REPORT (at most <N> words): status word, files changed, the check output
(last lines, copied), and anything you did not run, marked "not run".
```

### Step 2: Pick the cheapest worker that can do the slice well

Choose by role. Which model sits behind a role is set in the harness
configuration, not in this skill.

| Tier | Role | Give it |
|---|---|---|
| 1 | **Lead** (this session) | Plan, briefs, gates, review, git, user questions, feel and judgement. |
| 2 | **Builder** | Build or fix to a brief that has a test and a pass condition. |
| 3 | **Test-writer** | Write the check from the brief only, before the build. |
| 4 | **Scout** | Read-only fact finding. Returns short answers with the file and line. |

Start at the lowest tier that fits. Move a slice up one tier only after it has
failed its check twice.

| Harness | How to reach the Builder, Test-writer and Scout roles |
|---|---|
| OpenCode | The Task tool. Name the OCGS agent that owns the files (see `docs/framework/agent-roster.md`). Use a read-only agent for Scout work. |
| Claude Code | The Task tool (called `Agent` there). Follow the routing order in `.claude/rules/studio-ops.md`: outside workers first, then the fallback helpers. |
| oh-my-pi | Its built-in task tool, with the OCGS agents generated into `.omp/agents/`. |
| Pi | No subagents. The lead does every role itself. See Step 5. |

### Step 3: Decide how many run at once

- Default: **3** workers at the same time. Never more than **5**.
- Only slices with `Depends on: none`, or whose dependencies are done, may start.
- Two workers never hold the same file. Check the slice table before each start.
- Every worker either has its own worktree or shares one with the git rule in
  Step 4.

### Step 4: Keep the rules while work runs

1. **File ownership is strict.** A worker that needs a file it does not own
   stops and reports. The lead decides: change the plan, or do that edit itself.
2. **Only the lead uses git in a shared worktree.** Workers there do not stage,
   commit, stash, switch branch or push. A worker with its own worktree may
   commit there if its brief says so.
3. **Never wait idle.** While workers run, the lead writes the next briefs,
   prepares the checks, or does its own slice. The lead does not edit a file a
   worker owns.
4. **Refill slots from a queue.** Keep the slices that are not started in an
   ordered list. When a worker reports, gate its slice (Phase 3) and start the
   next slice from the list in the same step.
5. **Update the plan.** Mark each slice with a status word in
   `production/session-state/active.md` when it starts and when it passes.

### Step 5: When the harness has no subagents

Run the same plan in order, one slice at a time:

1. Sort the slices so that dependencies come first.
2. For each slice: write the brief anyway, act as the worker and follow the
   brief, run the check, then gate it (Phase 3) before the next slice starts.
3. Keep the ownership rule: while on slice S2, do not edit the files of S3.
4. Update `production/session-state/active.md` after each slice, so a new
   session can go on from the file.

---

## Phase 3: GATE

A gate is the check between "the worker says it is done" and "it is done".

1. **A slice is done only when its check ran and the lead saw the result.** The
   lead runs the test command itself, or reads the copied output in the report
   and spot-checks it. "Should work" is not a result. No output means
   **not run**, and the slice stays in progress.
2. **Tests first where possible.** The check is written before the build. After
   the build starts, nobody weakens it: no deleted cases, no skipped cases, no
   lowered numbers. If a test is wrong, the lead fixes the test in its own
   step and says so in the review.
3. **Two failures in a row on the same step: stop.** Take the fallback written
   in the brief (a higher tier, a smaller slice, or a different route). If
   there is no fallback, ask the user. Never try a third time the same way.
4. **Questions to the user are Yes / No.** Ask one at a time with the question
   tool. Put the recommended answer first. Give one sentence of reason.
5. **Never more than five approvals at once.** If more than five things need a
   yes, group them or ask in rounds.
6. **These always need a yes first:**
   - anything outside the workspace (host settings, other repositories,
     scheduled tasks);
   - anything that costs money (paid generation, paid API calls);
   - anything that is hard to undo (delete, overwrite, merge, publish, history
     changes).
7. **Checkpoint at each gate passed.** The lead stages the files of that slice
   in one command, commits in the next command, then pushes. Use a Conventional
   Commit message. Never commit to the default branch. Commands and hook rules
   are in `/ci-pr`.

### Gate record

Add one line per slice to `production/session-state/active.md`:

```text
S2 | done | check: <command> | result: 58/58 passed | commit: <short hash> | pushed: yes
```

---

## Phase 4: REVIEW

Start this phase when every slice has passed its gate, or when the stop time
is reached, whichever comes first.

1. **Read every diff.** The lead reads all changes from all workers. Look for:
   edits outside the owned files, weakened tests, leftover debug code, and
   values written into code that belong in data files.
2. **Run the full checks**, not only the slice checks: the whole test suite and
   the project validators (for this framework: `npm run ci`).
3. **Look at pictures for anything visual.** Take screenshots and open them. A
   passing test does not prove that something looks right.
4. **State plainly what was not run.** Write "not run: <check> because
   <reason>" for each one. Never report an unrun check as passed.
5. **Pull request and review.** Open the PR with `/ci-pr`. At most **two**
   CodeRabbit rounds. If findings are still open after round two, stop and ask
   the user.
6. **Backup tag, then a yes, then merge.** Create the backup tag first. Ask the
   user "Merge PR #<n>?" and wait for a yes. No merge without it. The user
   removes worktrees and branches.
7. **Update `production/session-state/active.md`:** what is done, what is not,
   key decisions, open questions. Move finished history to
   `production/session-state/archive/`.
8. **Write the handoff** with a start prompt that can be pasted into a fresh
   session. It must give: the goal, the worktree and branch, the state files to
   read in order, the single next step with its command, the files that must
   not be touched, and the checks with their last results. The full list is in
   `production/orchestration/CONTEXT-POLICY.md`, section 5.
9. **Save lessons.** Write three lines at most: what worked, what failed, what
   to change next time. Add them to the "Field notes" section of this skill
   (edit `.agents/skills/pogr/SKILL.md`, then run `npm run claude:sync`) or to
   the handoff file.

### Final report template

```markdown
## POGR report: <goal>
Status: done | in progress | waiting on user
| Slice | Status | Check | Result | Commit |
|---|---|---|---|---|
Not run: <list, or "nothing">
Still rough: <honest list>
Needs a yes: <list, or "nothing">
Next step: <one command or one sentence>
```

---

## Worked example

Goal: "Add a double jump to the prototype and show it on the phone build."

**PLAN.** Sweep finds `player.gd`, `smoke.gd`, `touch_ui.gd`. Budget 60
minutes, stop at 21:00.

| ID | Goal | Owner | Files it owns | Test command | Pass condition | Depends on |
|---|---|---|---|---|---|---|
| S1 | Add a failing test for the second jump | Test-writer | `smoke.gd` | `godot --headless --path proto res://smoke.tscn` | New case listed and FAIL | none |
| S2 | Make the second jump work | Builder | `player.gd` | same command | All cases PASS | S1 |
| S3 | Add a jump hint to the touch buttons | Builder | `touch_ui.gd` | same command, plus one screenshot | All PASS, hint visible | none |

Lead keeps: the feel of the jump height, all git, the phone build, the review.

**ORCHESTRATE.** S1 and S3 start together. S2 waits in the queue. While they
run, the lead writes the S2 brief. S1 reports; the lead gates it and starts S2
in the same step.

**GATE.** S2 fails twice (jump fires on the ground). The lead stops the retry,
takes the fallback (move S2 up one tier), and it passes: 59/59. One checkpoint
commit and push per slice.

**REVIEW.** The lead reads three diffs, runs the full suite, opens the S3
screenshot, and writes "not run: phone build on a real device". PR opened, one
CodeRabbit round, backup tag, then: "Merge PR #12?" The lead waits for the yes.

On a harness without subagents the same plan runs as S1, then S3, then S2,
with a gate after each.

---

## Recommended Next Steps

- `/ci-pr`: ship the reviewed work through a pull request.
- `/story-done`: close a story that a POGR run finished.
- `/retrospective`: turn saved lessons into process changes.

---

## Field notes

Lessons from real POGR runs. Newest first. Keep each note to one or two lines.

_Pending: to be filled from the first sprint (2026-11-16)._
