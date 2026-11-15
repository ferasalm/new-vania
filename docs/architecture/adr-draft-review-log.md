# ADR-DRAFT — review log

> **Lane**: ADR-DRAFT (support) · **Branch**: `docs/adr-draft` · **Worktree**:
> `../new-vania-adr-draft` · **Base**: `origin/Main` `3fcedc6`.
> **Prompt**: `prompts/lanes/ADR-DRAFT.md` v1.0.0 / `9c08ed965d14` (matches the
> manifest row).
> **Log location note**: the lane contract names `design/gdd/reviews/<lane>-review-log.md`
> "or the lane's named log". This lane's documents are ADRs, not GDDs, so the log
> lives beside them in `docs/architecture/`.

## 0 · Context + feasibility brief (pre-authoring)

**Scope for this pass (orchestrator adjustment, recorded).**

| GDD | State | ADR | Why |
|---|---|---|---|
| SYS-03 Save & Serialization | APPROVED 2026-11-14 (landed) | **ADR-0002** | The GDD's §Dependencies names four ADR obligations: the writer's thread shape, the byte layout + canonicalization, the migration registration API, the platform path helper |
| SYS-04 Audio Core | APPROVED 2026-11-15 (landed) | **ADR-0003** | §G.6 "the engine-side import flags and the playback mechanism are the ADR's"; §H.4 "MONO … the engine mechanism is the ADR's"; two probes explicitly gate the ADR |
| SYS-05 Game Flow | **NOT authored** (lane QUEUED) | — | **No ADR drafted.** Its lane is QUEUED in the manifest; there is no contract to decide against. Recorded as a gap (§6) |
| SYS-07 Health & Damage | APPROVED 2026-11-12; rework landed | — | **Next candidate.** The GDD flags its own ADR raw material; **not drafted in this pass** per the orchestrator's scope. Recorded as the follow-up (§6) |

**Consumed contracts (read once each).** SYS-03 GDD (26 TR-SAV / 4 F-SAV /
9 V-SAV / 26 ACs); SYS-04 GDD (39 TR-AUD / 7 F-AUD / 7 V-AUD / 32 ACs);
ADR-0001 (the pattern + §3 freeze + §5 tick boundary); the registry entries
`save_contract`, `save_roundtrip_twin`, `audio_bus_contract`,
`ambient_bed_contract`, `audio_edge_list`, `duck_request_contract`; the engine
snapshots (`VERSION.md`, `breaking-changes.md`, `modules/audio.md`); the systems
index rows for SYS-03/SYS-04 + the dependency map; `technical-preferences.md`.

**Section plan (both ADRs, ADR-0001's section order).** Status · Date · Last
Verified · Decision Makers · Summary · Engine Compatibility · ADR Dependencies ·
Context (Problem / Current State / Constraints / Requirements) · Decision (N
numbered decisions + architecture diagram + key interfaces + implementation
guidelines) · Alternatives Considered · Consequences · Risks · Performance
Implications · Migration Plan · Validation Criteria · GDD Requirements Addressed
· Related. Plus the ADR-0001 **engine verification register** pattern, because
both documents rest on post-cutoff API behaviour.

**Feasibility findings (pre-authoring).**

1. **SYS-03's twin is 34/34, not 32/32.** `node tests/save-twin/save_twin.mjs`
   prints 34 `PASS` lines and the GDD's header and §Gate manifest both say 34/34;
   the registry entry `save_roundtrip_twin` says **32/32**. The twin's own output
   is the authority. → sync note (§6), not an edit here.
2. **CR-AUD-02 is now resolvable.** The audio GDD asked SYS-03 (then Not Started)
   for `restored_epoch` on a load-complete payload. SYS-03 has landed and
   publishes no load-complete event (`restore_complete` + `load_result` only);
   `load_complete` is **SYS-05's**. The request resolves to SYS-05's authoring —
   ADR-0003 §12 records it as carried obligation **O-AUD-1**. No frozen text is
   edited.
3. **The audio GDD's §K.3 still lists SYS-03 as "Not Started"** — stale since
   2026-11-14. → sync note (§6).
4. **TR-AUD-038/039 are numbered out of sequence** (they appear in §E.3 and §F.4,
   after 037). Not a defect; recorded so a future audit does not read it as a
   missing ID.

## 1 · Draft checkpoint

- `docs/architecture/adr-0002-save-serialization.md` — `Status: Proposed`.
- `docs/architecture/adr-0003-audio-core.md` — `Status: Proposed`.
- Both add **no** TR, formula or AC: they consume the GDDs' counts and decide
  mechanism only (the no-implementation law: no stories, no epics, no control
  manifest).

## 2 · Gate trail

| Gate | Seat model | ADR-0002 | ADR-0003 |
|---|---|---|---|
| CD (ADR alignment) | GLM-5.3-Flash | _pending_ | _pending_ |
| Three-seat · creative | GLM-5.3-Flash | _pending_ | _pending_ |
| Three-seat · technical | DS | _pending_ | _pending_ |
| Three-seat · QA | DS | _pending_ | _pending_ |
| Repairs | — | _pending_ | _pending_ |
| qa-lead spot-check | DS | _pending_ | _pending_ |
| Final micro-check | DS | _pending_ | _pending_ |
| `/architecture-review` (traceability + cross-ADR) | DS | _pending_ | _pending_ |

## 3 · Repairs

_pending_

## 4 · Rebuttals

_pending_

## 5 · Final verdict

_pending_

## 6 · Sync notes (for the orchestrator; not edited here)

_pending_
