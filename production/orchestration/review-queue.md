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
| SYS-15 | #59 | 1 (in flight) | — | — | pending |

Batched cadence: one pass per landed milestone; triage in one batch → one fix
commit → resolve threads manually with recorded dispositions. A confirm pass only
for a Major-class fix batch.

## 5. Shared-file sync queue (max 1 writer)

| Order | Lane | Registry entries | Index row | Requested | Status |
|---|---|---|---|---|---|
| 1 | SYS-15 | +7 (5 contracts/doctrine + 2 knobs) + 1 rider on `duck_request_contract` | SYS-15 dependency-map bullet + MVP row → APPROVED + design order 12 | 2026-11-15 | queued |

Full request: `../new-vania-sys15-cache-stations-death/production/session-state/lane-SYS-15-report.md` §Sync (the exact YAML + rows). Counts for validation: TR 20 / F 4 / V 7 / ACs 26 (21 smoke = 17 GUT + 4 LINT · 3 device · 2 lock · 0 VS) / OQs 9; registry N + 7, no renames/retypes.

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
