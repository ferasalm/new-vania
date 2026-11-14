# Orchestration — Operating Manual

> **Status**: MVO (minimum viable orchestration), 2026-11-14. The machine that
> runs the parallel GDD/pre-production lanes. Tracked, not gitignored.
>
> **Read this first**: `STATE.md` (live state) → `manifest.yaml` (source of
> truth) → `prompts/NEXT.md` (the only prompt the user pastes).

## 1. What this is

A nested orchestration system for parallel document lanes:

```text
user
  └─ orchestrator chat (this role)
       ├─ lane runner A (one worktree, one document)
       │    ├─ cd-gate seat
       │    ├─ creative seat
       │    ├─ technical seat
       │    ├─ qa seat
       │    └─ qa spot-check seat
       ├─ lane runner B
       ├─ lane runner C
       └─ sync lane (the only shared-file writer)
```

The main orchestrator **does not author** and **does not read full GDDs**. It
reads `STATE.md` + `manifest.yaml` + lane reports. The lane runner authors and
spawns the seats. The seats are neutral, blockers-only reviewers.

## 2. Lane state machine

```text
QUEUED → AUTHORING → CD GATE → SEATS → REPAIRS → SPOT-CHECK → SYNC → PR → CODERABBIT → MERGED
```

- **QUEUED** — in the manifest, not started. Dependencies met or explicitly
  waived.
- **AUTHORING** — the lane runner is drafting sections; the user approves each
  section.
- **CD GATE** — the `cd-gate` seat (creative/CD routing) has the draft.
- **SEATS** — the three-seat panel (creative, technical, QA) is reading.
- **REPAIRS** — valid blockers are being applied in-session.
- **SPOT-CHECK** — the mandatory qa-lead spot-check on repaired text.
- **SYNC** — the lane's registry/index diff is queued for the single writer.
- **PR** — branch pushed, PR open `--base Main`.
- **CODERABBIT** — one CodeRabbit pass; triage in one batch.
- **MERGED** — squash-merged; the landing receipt is recorded.

Side states: **BLOCKED** (hard blocker), **STANDBY** (support lane, no active
work), **PAUSED** (user decision pending).

A lane may loop `REPAIRS → SPOT-CHECK` until the spot-check passes. The final
micro-check is diff-scoped and capped: blockers only, then stop.

## 3. WIP limits (not daily quotas)

| Resource | Limit |
|---|---|
| GDDs in three-seat review | **2** |
| CodeRabbit passes in flight | **1** |
| Shared-file writers | **1** (the sync lane) |
| AUTHORED-queued lanes (authored, waiting for a review slot) | **3** |
| Active lane runners | **3** (the first wave: ART-BIBLE, SYS-03, SYS-04) |

Authoring can run ahead of review by up to 3 authored-queued lanes. Pull
continuously: when a review slot frees, start the next lane; do not schedule by
day.

## 4. Single-writer sync

Only the **sync lane** edits:

- `design/registry/entities.yaml`
- `design/gdd/systems-index.md`

Every other lane prepares a **sync request** in its report: the exact entries,
the index row, and the diff summary. The SYNC-LANE is the designated writer; the
shared-contract prohibition applies to every other lane. The orchestrator queues
the request in `review-queue.md` and sets `shared_file_lock` in `STATE.md`. The
sync lane:

1. Acquires the lock.
2. `git fetch origin` + `git rebase origin/Main` immediately before the edit.
3. Applies the queued diff serially, one lane at a time.
4. Validates: YAML parse, duplicate-name scan, source/referenced_by consistency,
   index counts, design order, status.
5. Commits, pushes, updates the manifest + STATE, releases the lock.
6. **Never force-pushes.**

## 5. Review budget

- Each seat returns **blockers only** + at most 10 one-line recommendations + a
  short notes list. No praise, no document restatement.
- The creative/CD seats use `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`.
- The technical/QA/spot-check seats use
  `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`.
- The qa-lead spot-check is mandatory on repaired text. FAIL → repair → re-run.
- The final micro-check is diff-scoped: blockers only, zero blockers to pass,
  then stop. Do not reopen the document.
- Review-doctrine: the batch co-review (Mechanism A) and the diff-scoped leaf
  default (Mechanism B) are adopted with conditions — see
  `production/review-doctrine/2026-11-14-right-sizing-review-scope.md`. The
  pending-obligation ledger is read into every review.

## 6. Blocker taxonomy

**Hard** — stop the lane, batch the user decision, switch lanes:

- missing dependency or contract
- contract conflict
- user decision required
- required approval (art-bible direction, contract revision)
- failing required CI
- unresolved Major CodeRabbit thread

**Soft** — switch lanes, never idle:

- review queue wait
- shared-file lock wait
- stale prompt (regenerate)
- a seat recommendation that can be deferred

The orchestrator stops and asks the user **only** for a hard blocker, a contract
revision, an art-bible direction decision, or a required-review refusal on a
future lane PR. Everything else is batched.

## 7. Prompt versioning and the paste-check

Every lane prompt carries a header:

```text
Lane · Branch · Worktree · Version · Hash · Source · Generated
```

The manifest carries the same hash. `prompts/NEXT.md` is the **only** paste
source. Before pasting:

1. Run `node tools/orchestration/render-prompts.mjs --check`.
2. Compare the header in `NEXT.md` with the manifest's `next:` block.
3. If the header or hash does not match, **stop** and regenerate. Never hand-edit
   a generated prompt; edit `lane-kickoff-master.md` and re-render.

## 8. Quality gates (definitions of done)

| Lane type | Definition of done |
|---|---|
| **GDD** | all sections + CD gate + 3 seats + qa-lead spot-check + final micro-check + sync + PR + 1 CodeRabbit pass + merge |
| **Art bible** | art-director + creative-director + user approval + asset-spec handoff |
| **Probe** | verdicts + report |
| **ADR** | accepted + architecture review |
| **Support/QA** | the support package + the owner's sign-off + the normal PR gate |

Speed never skips a gate. A lane is not done because the text exists; it is done
when the gate record exists.

## 9. Frozen contracts

The landed GDDs are frozen: SYS-01, SYS-02, SYS-06, SYS-07, SYS-08, SYS-09,
SYS-10, SYS-11, SYS-13, SYS-29, SYS-32, and the game concept. A change is a
**contract-revision request** in `decisions.md`, batched for the user. A
recorded, user-approved revision (the decision ID in `decisions.md`) is the only
way a lane edits a frozen document; the commit names the decision ID. No silent
edits.

Never touch `design/gdd/world-mutation-epochs.md`,
`design/gdd/dual-reality-state.md`, their review logs, or
`docs/sys10-world-mutation`.

## 10. Git rules

- No commits on `Main`. Branch + PR `--base Main` + squash-merge.
- Conventional Commits; header ≤ 100 chars; body wrapped at 100; reference the
  lane ID and the design doc.
- Never force-push.
- Worktrees: `npm run task:new -- <type>/<topic>` creates
  `../new-vania-<topic>` from a fresh `origin/Main`.
- **Admin-merge pre-authorization**: if the ONLY blocker is the required review
  (0 unresolved threads, all required checks green), the user pre-authorizes one
  `gh pr merge --squash --delete-branch --admin`. Pin the merge to the verified
  head SHA (`gh pr view <n> --json headRefOid` immediately before merging); if
  the head moved, re-run the checks. Record the bypass in the landing receipt.
  Any other blocker is diagnosed, not bypassed.

## 11. File map

| Path | Purpose |
|---|---|
| `README.md` | this manual |
| `STATE.md` | the single live state/log |
| `manifest.yaml` | the single source of truth for lanes/prompts |
| `review-queue.md` | the WIP/review/sync ledger |
| `decisions.md` | the batched user-decision queue |
| `lane-kickoff-master.md` | the master prompt with all lane blocks |
| `prompts/lane-runner.md` | the generic per-lane runner |
| `prompts/sync-lane.md` | the single shared-file writer |
| `prompts/orchestrator-loop.md` | the short repeatable orchestrator prompt |
| `prompts/NEXT.md` | the one prompt the user pastes (generated) |
| `prompts/seat-briefs/*.md` | the neutral seat briefs |
| `prompts/lanes/*.md` | the per-lane prompts (generated) |
| `landings/*.md` | landing receipts and preserved lane states |
| `../../tools/orchestration/render-prompts.mjs` | the prompt renderer/checker |

## 12. The orchestrator loop (short form)

1. Read `STATE.md` + `manifest.yaml`.
2. Check blockers; resolve soft blockers by switching lanes.
3. Launch the next lane runner(s) within the WIP limits.
4. Do not author. Do not read full GDDs.
5. Update `STATE.md` at every lane boundary.
6. Batch user decisions in `decisions.md`.
7. Stop only on a hard blocker.
8. Keep `NEXT.md` current; the user pastes only from it.
