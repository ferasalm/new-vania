# Review Queue — the WIP / review / sync ledger

> **Updated**: 2026-11-14. **WIP limits**: 2 GDDs in three-seat review · 1
> CodeRabbit pass · 1 shared-file writer · 3 authored-queued. Pull continuously;
> do not schedule by day.

## 1. Three-seat review slots (max 2)

| Slot | Lane | Document | Phase | Seats | Started | Notes |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | free |

The first lane to reach `CD GATE` takes slot 1; the second takes slot 2. A slot
frees when the lane reaches `SYNC` (the review is closed; the sync is a separate
queue).

## 2. Authoring (no review slot needed)

| Lane | Document | Phase | Owner | Prompt |
|---|---|---|---|---|
| ART-BIBLE | `design/art/art-bible.md` | AUTHORING (parked; D-ORCH-01/02) | art-director + creative-director | v1.0.0 |

SYS-15 left this queue: its GDD is authored, its gates are complete (CD
APPROVED · seats 1+3+2 repaired · spot-check PASS · micro-check PASS), and its
PR (#59) is open with CodeRabbit pending (§4).

## 3. Authored-queued (max 3; waiting for a review slot)

| Lane | Document | Authored | Waiting for | Notes |
|---|---|---|---|---|
| — | — | — | — | — |

## 4. CodeRabbit queue (max 1)

| Lane | PR | Pass | Threads | Dispositions | Status |
|---|---|---|---|---|---|
| SYS-15 | #59 | 1 (initial, 6m48s) | 8 | triage in flight (resumed runner) | fix head pending |
| SYS-28 | #58 | 2 (initial + confirm re-run) | 6 | 5 applied (`3945b64`) + 1 rebutted (DS-seat routing; recorded) | confirm re-running |

Note: the two lane passes ran concurrently — a serial-rule deviation by the
autonomous runners, recorded here and in STATE §3. NEW passes (the sync PRs)
queue behind these recorded dispositions.

Batched cadence: one pass per landed milestone; triage in one batch → one fix
commit → resolve threads manually with recorded dispositions. A confirm pass only
for a Major-class fix batch.

## 5. Shared-file sync queue (max 1 writer)

| Order | Lane | Registry entries | Index row | Requested | Status |
|---|---|---|---|---|---|
| 1 | SYS-28 | +3 (1 contract + 1 formula + 1 constant) | 8 exact diffs (SYS-28 row → APPROVED, design order 21, Foundation bullet, SYS-10 countersign grant, SYS-05 ratification, SYS-02/03/20 notes) | 2026-11-15 | PR open (`chore/sync-shared-files`, base `Main`), awaiting merge |

Full request (read from the lane worktree; `session-state` is gitignored but
on disk):
- SYS-28: `../new-vania-sys28-narrative-presentation/production/session-state/lane-SYS-28-report.md` — counts TR 13 / F 3 / V 6 / ACs 15 (13 smoke = 8 LINT + 5 GUT · 0 device · 2 MVP-lock · 0 VS) / OQs 5.

**Landed 2026-11-15** (removed from the active queue): **SYS-15** — PR #63,
`1e9e524` (head `5f67ee0`; 1 CodeRabbit thread applied — the
`designation_counter` wording narrowed to the GDD's own law; 1 rebuttal — the
fifth-save-event suggestion closed by AC-CSD-19/OQ-SAV-4); registry 70 → 77
entries; the index gained the SYS-15 bullet, the APPROVED MVP row and design
order 12. The full request was
`../new-vania-sys15-cache-stations-death/production/session-state/lane-SYS-15-report.md` §Sync.

**Landed 2026-11-14** (removed from the active queue; the receipts are in
`STATE.md` §11/§12): **SYS-03** — PR #47, `50a9a93` (head `07f9b27`; 3 threads:
2 applied, 1 rebutted) · **SYS-04** — PR #48, `dd33658` (head `6392f84`; admin
merge, required-review-only; 3 threads: 2 applied, 1 rebutted).

The sync lane acquires the lock in `STATE.md`, rebases on `origin/Main`
immediately before the edit, applies serially, validates, commits, pushes,
updates the manifest, releases the lock. Never force-push.

## 6. Blocked / waiting

| Lane | Blocker | Type | Owner | Decision | Since |
|---|---|---|---|---|---|
| SYS-16 | SYS-07-REWORK (IP-17) | hard dependency | systems-designer + lead-programmer | D-ORCH-03 | 2026-11-14 |
| SYS-17 | SYS-07-REWORK + SYS-16 | hard dependency | systems-designer + lead-programmer | D-ORCH-03 | 2026-11-14 |
| ART-BIBLE | SYS-11 OQ-1 direction | user decision | art-director + lead-programmer | D-ORCH-01 | 2026-11-14 |

## 7. Queue rules

1. **A review slot is not a quota.** Start the next lane when a slot frees; do
   not wait for a calendar day.
2. **Authoring can run ahead** by up to 3 authored-queued lanes. Beyond that,
   stop starting new authoring lanes and let the review catch up.
3. **A lane in `REPAIRS` keeps its slot** until the spot-check passes and the
   review closes. A lane in `SYNC` releases its slot.
4. **The sync queue is serial.** A lane may open its PR before the sync lands,
   but it may not merge before the sync lands.
5. **CodeRabbit is serial.** One pass at a time; a second lane waits for the
   first pass's dispositions to be recorded.
6. **Soft blockers switch lanes; hard blockers batch the user.** Never idle.
