# Review Queue — the WIP / review / sync ledger

> **Updated**: 2026-11-15. **WIP limits**: 2 GDDs in three-seat review · 1
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

The authoring table is empty. **SYS-15** (PR #59, `24efd09`), **SYS-28** (PR
#58, `2ff3096`) and **ART-BIBLE** (PR #67, `ee08e63`) are all landed with their
syncs; **SYS-07-REWORK** landed (PR #75, `3fcedc6` — D-ORCH-03 applied).

## 3. Authored-queued (max 3; waiting for a review slot)

| Lane | Document | Authored | Waiting for | Notes |
|---|---|---|---|---|
| — | — | — | — | — |

## 4. CodeRabbit queue (max 1)

| Lane | PR | Pass | Threads | Dispositions | Status |
|---|---|---|---|---|---|
| — | — | — | — | — | idle |

The SYS-15 (#59: 8 threads) and SYS-28 (#58: 6 threads) lane passes and the
SYS-07-REWORK applied-diff cycles (PR #75: 24 threads across 4 passes) are all
closed with recorded dispositions. The serial-rule deviation of 2026-11-15
(two concurrent lane passes) stands recorded; it did not recur.

Batched cadence: one pass per landed milestone; triage in one batch → one fix
commit → resolve threads manually with recorded dispositions. A confirm pass only
for a Major-class fix batch.

## 5. Shared-file sync queue (max 1 writer)

| Order | Lane | Registry entries | Index row | Requested | Status |
|---|---|---|---|---|---|

**The active sync queue is empty** — the last queued request landed and the lock
is released (STATE §4).

**Landed 2026-11-16** (removed from the active queue): **SYS-05 Game Flow &
Session** — PR #92 squash-merged as `9365b56` (registry 122 → 130: 4 contracts +
3 formulas + `LOAD_STALL_ASSERT_MS`; the index's SYS-05 APPROVED row, design
order 17, the dependency bullet, 13 neighbor notes; 4 CodeRabbit threads, 2
applied + 2 rebutted, all resolved). Its GDD followed per §7 rule 4 as PR #87,
`2164181`. The full request was
`../new-vania-sys05-game-flow-session/production/session-state/lane-SYS-05-report.md`
§A–§C.

**Landed 2026-11-16** (removed from the active queue): **SYS-24 HUD** — PR #89,
`bdc8380` (2 CodeRabbit threads, both applied + resolved).
Registry 119 → 122 entries (3 published contracts: `hud_caps_contract`,
`settings_namespace`, `hud_registration_contract`; 8 `referenced_by` appends; the
envelope `2.45/6.55 → 2.55/6.85`); the index gained the SYS-24 APPROVED row, the
dependency bullet and the SYS-15/16/03/32 row notes (design order 18 unchanged).
Its release edit never landed — the SYS-05 sync's lock transfer (`STATE.md` §4)
records it. The full request was
`../new-vania-sys24-hud/production/session-state/lane-SYS-24-report.md` §A–§B.

**Landed 2026-11-15** (removed from the active queue): **SYS-16 Progression** —
PR #84 squash-merged as `fac409f` (`fa91299` the lock + `e71183a` the sync +
`7590599` the CodeRabbit batch; 5 threads, 5 applied, all resolved). Registry
88 → 113 entries; the index gained the SYS-16 APPROVED row, design order 23, the
dependency bullet, 9 row corrections and the six riders. Its release edit never
landed — the SYS-14 sync's lock transfer (`STATE.md` §4) records it. The full
request was
`../new-vania-sys16-progression/production/session-state/lane-SYS-16-report.md`
§4a–4e.

**Landed 2026-11-15** (removed from the active queue): **SYS-07-REWORK** —
PR #76, `6dd4651` (head `b188b2d`; 4 CodeRabbit threads across 3 passes, all
applied + resolved). Registry 81 → 88 entries (`damage_event` +
`player_max_hp` 20, `hp_per_point` 2, `training_data_l2..l5`,
`damage_ladder_mvp`); 11 value/note updates; the index gained the SYS-07
row/bullet, design order 22, the SYS-16/17 unblock and game-concept's 5th
Gate-2 probe. `spitter_orb_damage` stayed HELD at 8. The full request was
`../new-vania-sys07-baseline-rework/production/session-state/lane-SYS-07-REWORK-report.md`.

**Landed 2026-11-15** (removed from the active queue): **SYS-14 Grief-Boss** —
PR #85, `27aa989` (head `c40a8d1`; 4 CodeRabbit threads, 3 applied + 1 rebutted,
all resolved). Registry 113 → 119 entries (5 published contracts +
`staging_band_denial` + `boss_hp_pool` 60; the request's `boss_kill_award` folded
onto `xp_boss`); the index gained the SYS-14 APPROVED row, design order 14, the
dependency cell + bullet (the stale 300 HP → 60), the 6 neighbor notes and the A12
rider record. Its release edit never landed — the SYS-24 sync's lock transfer
(`STATE.md` §4) records it. The full request was
`../new-vania-sys14-grief-boss-framework/production/session-state/lane-SYS-14-report.md`
§A–§B.

**In flight (order 1: the SYS-05 sync — applied on `chore/sync-sys05`, PR open;
the lock held by transfer from the landed SYS-24 sync)**. Order 1 before it (the
SYS-24 sync) **landed** as `bdc8380` and is removed from the active table above;
its release edit never landed, so the SYS-05 sync's `STATE.md` §4 edit releases
that hold and re-acquires in one edit. **The release to `shared_file_lock: none`
is recorded with the orchestrator's receipt for this sync's merge** — together
with the landing hash. **PR #87 (the SYS-05 GDD) does not gate the release**; it
merges after this sync by review-queue §7 rule 4 and its landing is recorded
separately.
**SYS-05** — 4 contracts (`context_machine`, `load_complete_gate`,
`cache_activation`, `flow_grant_trigger`) + 3 formulas (`gate_priority`,
`load_complete_ready`, `session_anchor`) + 1 constant (`LOAD_STALL_ASSERT_MS`
5000 [1000, 15000]) = the registry's +8 (122 → 130; the report's 119 → 127 was
written against the pre-SYS-24 baseline); the index's SYS-05 tracker row,
design order 17, the dependency bullet, the 13 neighbor row notes and the
ADR-0001 §6 rider record. One writer at a time; each re-acquires the lock in
`STATE.md` §4.

**Landed 2026-11-15** (removed from the active queue): **SYS-07-REWORK riders
mini sync** — PR #80, `fe38c4c` (0 CodeRabbit threads; merged after its
source PR #78 at `b4ec55b` per the mirror-after-source rule).

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

**None blocked.** SYS-17 unblocked (SYS-07-REWORK `3fcedc6` + SYS-16 `6db8c38`
both landed); the entire GDD queue (SYS-17, SYS-12, SYS-20, SYS-25) is PAUSED
by user decision (D-ORCH-15) until the prototype-v2 playtest verdicts.

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
