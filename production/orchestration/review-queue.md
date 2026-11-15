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
| — | — | — | — | — |

The authoring table is empty. **SYS-15** landed (its GDD merged — PR #59 at
`24efd09`). **SYS-28** is at PR #58 (gates closed; its sync queued, order 1). 
**ART-BIBLE** is at PR #67 (gates complete; its sync queued as order 2).

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
| — | — | — | — | — | idle |

**Landed 2026-11-15** (removed from the active queue): **ART-BIBLE** — PR #72,
`bc8c6be` (head `8eb621d`; 0 CodeRabbit threads). Registry notes on
`dual_reality_palette_tables` (the D-ORCH-02 pins) and `seam_admission_test`
(D-ORCH-01); the index gained the SYS-11 qualification, the SYS-02 line-36 note
(naming D-ORCH-01 + `5cc1377`), the OQ rider notes and the OQ-M1 rider list.
The full request was
`../new-vania-art-bible/production/session-state/lane-ART-BIBLE-report.md` §3.

**Landed 2026-11-15** (removed from the active queue): **SYS-28** — PR #69,
`a5a1f81` (head `eb85da4`; 4 CodeRabbit threads, all applied + resolved);
registry 77 → 80 entries (`narrative_beat_contract`, `beat_variant_selector`,
`micro_copy_budget`); the index gained the SYS-28 APPROVED row, design order 21
and the 10 request diffs. The full request was
`../new-vania-sys28-narrative-presentation/production/session-state/lane-SYS-28-report.md`.

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
opens the PR, updates the manifest — and **releases the lock only after the
sync PR merges** (`prompts/sync-lane.md` §6; a blocked PR keeps the lock and
the request in place for retry). Never force-push.

## 6. Blocked / waiting

| Lane | Blocker | Type | Owner | Decision | Since |
|---|---|---|---|---|---|
| SYS-16 | SYS-07-REWORK (IP-17) | hard dependency | systems-designer + lead-programmer | D-ORCH-03 | 2026-11-14 |
| SYS-17 | SYS-07-REWORK + SYS-16 | hard dependency | systems-designer + lead-programmer | D-ORCH-03 | 2026-11-14 |

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
