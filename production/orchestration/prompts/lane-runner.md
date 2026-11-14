# Lane Runner — the generic per-lane prompt

> **Use**: one lane runner per lane. The runner works in the lane worktree, runs
> the authoring/review loop, spawns the seats as nested subagents, and reports.
> It never edits shared files outside the sync protocol.

## 0. Preconditions (fail closed)

1. The lane prompt header (`Lane · Branch · Worktree · Version · Hash · Source ·
   Generated`) matches the `manifest.yaml` row for the lane. If not, **stop** and
   ask the orchestrator to regenerate.
2. The worktree exists and `git status --short` is clean (or only the lane's own
   in-flight files). The lane branch is based on the verified base SHA passed in
   the launch message (`git merge-base --is-ancestor <base_sha> HEAD`); if no SHA
   is passed, use the `origin/Main` ref. HEAD need not be the base tip — a
   resumed branch may carry checkpoint commits.
3. `production/orchestration/STATE.md` does not mark the lane `BLOCKED`.
4. The shared-file lock is not held by another lane for the files this lane
   needs. (The lane never writes the shared files; this is only a read check.)

## 1. Context (read once)

- `production/orchestration/STATE.md` — the live state.
- `production/orchestration/manifest.yaml` — the lane row.
- The lane prompt `production/orchestration/prompts/lanes/<ID>.md`.
- The consumed GDDs/registry entries named in the lane block. Do not read the
  whole design corpus.
- `design/gdd/systems-index.md` — the lane row + dependency map.

## 2. Authoring loop

1. Present a **context + feasibility brief** (consumed contracts, open
   questions, section plan). Wait for the user's approval.
2. Author section by section with `/design-system` discipline: Question →
   Options → Decision → Draft → Approval. Write each approved section to file
   immediately.
3. Cross-check new entities/formulas against `design/registry/entities.yaml`
   (read-only; the sync lane writes it).
4. Keep a running review log in the worktree at
   `design/gdd/reviews/<lane>-review-log.md` (or the lane's named log).

## 3. Review loop

### 3.1 CD gate

Spawn the `cd-gate` seat with `production/orchestration/prompts/seat-briefs/cd-gate.md`
and the document path. Model: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`.
CONCERNS or REJECT → revise in-session → re-run. Record the verdict.

### 3.2 Three-seat panel

Spawn three nested subagents **in parallel**:

| Seat | Brief | Model |
|---|---|---|
| creative | `seat-briefs/creative.md` | `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` |
| technical | `seat-briefs/technical.md` | `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` |
| QA | `seat-briefs/qa.md` | `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` |

Each seat reads the document once, in full, and returns the brief's output
format. Do not tell a seat what verdict you want. Do not re-read the whole
document to judge the seat; judge the blockers.

### 3.3 Repairs

Apply every valid blocker in-session. A blocker you believe is invalid gets a
written rebuttal in the review log (the exact location + why), never a silent
skip. Apply the accepted recommendations only if they are one-line, non-gating,
and do not reopen the design.

### 3.4 Mandatory qa-lead spot-check

Spawn the `qa-spot-check` seat with
`seat-briefs/qa-spot-check.md` and the **repair diff** (not the whole document).
Model: deepseek. FAIL → repair → re-run. PASS → record the PASS line.

### 3.5 Final micro-check

A diff-scoped fresh-seat check on the last repair delta, blockers only. Hard bar:
zero blockers. Then **stop**; do not reopen the document. Record the micro-check
PASS.

### 3.6 Fallback

If the nested subagent tool is unavailable, run each seat pass yourself in a
separate pass with the same brief and record the fallback in the review log. Do
not skip a seat.

## 4. Sync handoff

Prepare the sync request in the lane report:

- The exact `entities.yaml` entries (name, status, source, referenced_by,
  attributes) and where they go.
- The exact `systems-index.md` row + the design-order row + the dependency-map
  bullet.
- The diff summary and the counts (TR / formulas / V-invariants / ACs / gate
  partition).

Do **not** edit either shared file. The orchestrator queues the request; the sync
lane applies it.

## 5. PR + CodeRabbit + merge

1. Commit the GDD + the review log with Conventional Commits. Push the branch.
2. Open the PR with `--base Main`. Include the lane ID, the gate trail, and the
   sync status in the body.
3. Run **one** CodeRabbit pass. Triage every finding in one batch → one fix
   commit → resolve threads manually with recorded dispositions. A confirm pass
   only for a Major-class fix batch.
4. Merge only after the sync lands and all required checks are green. Squash-merge
   (`gh pr merge --squash --delete-branch`). If the ONLY blocker is the required
   review (0 unresolved threads, all required checks green), the admin merge is
   pre-authorized — use it once and record the bypass. Bind the merge to the
   verified head SHA with `--match-head-commit <sha>` (`gh pr view <n> --json
   headRefOid` immediately before merging); GitHub rejects the merge if the head
   moved. If it moved, re-run the checks and the review dispositions.
5. Write the landing receipt (the squash hash) in the lane report and in
   `STATE.md` (the orchestrator writes STATE).

## 6. Report

Write `production/session-state/lane-<ID>-report.md` in the worktree:

```markdown
# Lane <ID> — report
- Status: <state machine value>
- Branch / worktree / PR:
- Prompt: <version> / <hash> (matches manifest: yes/no)
- Gate trail: CD <verdict> · creative <verdict> · technical <verdict> · QA <verdict> · spot-check <PASS/FAIL> · micro-check <PASS/FAIL>
- Blockers (hard): <numbered, with owner + decision needed>
- Sync request: <entries/rows + exact diff summary>
- CodeRabbit: <threads / dispositions>
- Landing receipt: <hash or "not merged">
- Next action:
```

Return the same report as your final message. Do not paste the GDD into the
report.

## 7. Hard rules

- Work only in the lane worktree. Never edit the main checkout or another lane.
- Never edit `design/registry/entities.yaml` or `design/gdd/systems-index.md`.
- Never edit a frozen contract without a **recorded, user-approved** contract
  revision (the decision ID in `decisions.md`); the commit names the decision ID.
  A silent edit is forbidden.
- Never touch `design/gdd/world-mutation-epochs.md`,
  `design/gdd/dual-reality-state.md`, their review logs, or
  `docs/sys10-world-mutation`.
- No commits on `Main`; no force-push; conventional commits; PR `--base Main`.
- Speed never skips a gate. A lane is done when the gate record exists, not when
  the text exists.
