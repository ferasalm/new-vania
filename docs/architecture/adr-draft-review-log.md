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
| CD (ADR alignment) | GLM-5.3-Flash | **APPROVED** (0 blockers) | **CONCERNS** (2 blockers) |
| Three-seat · creative | GLM-5.3-Flash | **APPROVED** (0 blockers) | **APPROVED** (0 blockers) |
| Three-seat · technical | DS | **NEEDS REVISION** (7 blockers) | **NEEDS REVISION** (7 blockers) |
| Three-seat · QA | DS | **NEEDS REVISION** (7 blockers) | **NEEDS REVISION** (6 blockers) |
| Repairs | — | **20 applied** + 3 rebuttals | **22 applied** + 0 rebuttals |
| qa-lead spot-check | DS | _pending_ | _pending_ |
| Final micro-check | DS | _pending_ | _pending_ |
| `/architecture-review` (traceability + cross-ADR) | DS | _pending_ | _pending_ |

All four seats ran against the **same draft** (commit `114da98`) in one batch, and
every seat read the draft once in full. The CD gate and the panel were dispatched
together: the CD verdict arrived with the panel's and no CD blocker required a
restructuring, so no seat's verdict was invalidated by the other's.

## 3 · Repairs — the worklist

### ADR-0002 (save)

| # | Blocker | Source | Disposition |
|---|---|---|---|
| 1 | R1/§3's "one canonical byte stream" was **false**: the file is the 5-key envelope, the hash covers `{schema_version, payload}` — two byte streams, as the twin's `envelope()` proves | tech 1 | **APPLIED** — §3 restates the law as "the hashed fragment is a byte-identical substring of the file" (fragment vs projection); R1 restated |
| 2 | §5/§8 put serialization on the game thread, contradicting TR-SAV-010 ("step 1 … on the worker") and TR-SAV-012 ("the bytes are produced off-thread") | tech 2, QA 1 | **APPLIED** — the job carries the **deep copy**; `canon()` + hash run on the worker; §8 restates TR-SAV-012's split (copy synchronous, bytes off-thread) |
| 3 | The close-save could be overwritten by a **pending** same-slot job (guard (a) covered only an in-flight write) | tech 3 | **APPLIED** — guard (c): the pending job is superseded and drained before the synchronous write |
| 4 | `register_namespace(owner, shape, migration_step)` (TR-SAV-004) was missing, and the namespace↔migration composition was undefined | tech 4, CD rec 1 | **APPLIED** — §7 now defines both APIs + the composition rule (`migration_step = k` requires `MIGRATIONS[k−1]`), with `cache` as the worked example |
| 5 | No `Error`→`SAVE_FAILED_*` classification; a bool + `get_error()` cannot separate full from read-only | tech 5, QA 1 | **APPLIED** — §5a's ordered classification table + register items 9/10 (the pre-flight mechanism) |
| 6 | §13 item 1 marked `DOCUMENTED` with no repo citation (the JSON float model is in the GDD, not the snapshot) | tech 6, QA 3 | **APPLIED** — `PROBE-PENDING` with a Method (parse the three payloads, assert `TYPE_FLOAT` → `TYPE_INT`) |
| 7 | The register had no Method/Owner; several probes had no pass threshold | QA 5 | **APPLIED** — 10 items, each with Method + Owner + a pass condition |
| 8 | Items 8/9 `DOCUMENTED` without documentation (item 8's own parenthetical conceded the device AC is the proof) | QA 4 | **APPLIED** — item 8 → `PROBE-PENDING` (device method, both platforms); item 9 folded into it |
| 9 | `REFUSE_FLOAT` vs `REFUSE_TYPE` both claim `3.5` at a `String` key — two ACs could disagree | QA 2 | **APPLIED** — §6a states the precedence (non-integral anywhere → `REFUSE_FLOAT`; integral at a non-int key → `REFUSE_TYPE`) |
| 10 | Validation 1 and 5 were unfalsifiable / contradicted their own ACs | QA 6 | **APPLIED** — criterion 1 now cites the step-3/6 re-read + a second-serializer grep; criterion 5's gating bound is the element count, the 0.5 ms stays AC-SAV-10's non-gating probe |
| 11 | Validation 14/15 were story-gate criteria inside the acceptance list (AC-SAV-24 is "reference twin only"; "zero PROBE-PENDING" is false at acceptance) | QA 7 | **APPLIED** — the list is split into **ADR acceptance** (1–13) and **story gate** (14–15) |
| 12 | "the three recorded hashes" — the digests live in F-SAV-01's worked-example table, not in the twin's source | tech 7 | **APPLIED** — cited to F-SAV-01, with the note that a fixture copies the **full** digests from there, never this ADR's truncated prefixes |
| 13 | Minor, all applied | CD/tech/QA recs | `get_sha256()` removed (rejected: the hash input is the projection, not the file); `NOTIFICATION_APPLICATION_FOCUS_OUT` removed from the used-APIs row and named as *not* an exit; §11 cites AC-SAV-13 for the sweep order; §9 names SYS-29 as the `FreezeState` owner; counts corrected to **7 resolved / 4 carried**; a V-invariant coverage line added; TR-SAV-004/017 citations corrected; the 32-vs-34 risk marked **Occurred** with the registry correction routed to the sync lane; Last Verified records the discrepancy |

**Rebuttals (ADR-0002).**

1. *"`integrity_verdict(bytes)` hides the parse→normalize→hash ordering; pass the
   parsed+normalized payload."* — **Not applied.** The signature is deliberately
   bytes-in: F-SAV-04 is the verdict **over bytes**, and its rows 0–2 (parse,
   version-is-int, every-number-integral) are *inside* it precisely because they
   are the minimum that makes a hash computable. Moving normalization outside the
   verdict would relocate the law into a caller. §6's nine steps are the internal
   order and are documented.
2. *"Criterion 8's 'pure' migrations have no audit; add a LINT."* — **Not
   applied.** §7's doc comment forbids store/clock/singleton reads and AC-SAV-26's
   audit family is the GDD's own static surface. A purity LINT would be a new audit
   the GDD does not have, and this ADR adds no audit.
3. *Creative seat's four recommendations* (bind SYS-15's print to
   `save_completed`; word the first-boot `EMPTY` outcome as "first boot"; make the
   freeze-skip record queryable for Gate 2; a code→sentence fixture) — **Not
   applied here.** All four are SYS-15/SYS-24 surface obligations, outside this
   ADR's scope; routed to those lanes in the report.

### ADR-0003 (audio)

| # | Blocker | Source | Disposition |
|---|---|---|---|
| 1 | The diagram re-timed **E7 to 134** (E7 is at 119; 134 is `arrive_end`) — an implementer would resume 15 ticks late | tech 1 | **APPLIED** — the diagram labels 119 as `E6 + E7` and 134 as `arrive_end`, with an explicit note |
| 2 | §4 called MONO "a Master-bus stage", contradicting the one-effect law, and left the interface undefined | tech 2 | **APPLIED** — `MonoStage` is a **Music-voice stream strategy** with a defined interface; the native Master effect is the named upgrade path |
| 3 | The MONO fold is a **30th file** while the GDD counts 29 and AC-AUD-32 audits "every asset … match §G.6" — a frozen count was being reinterpreted | tech 3, CD 1 | **APPLIED** — **CR-AUD-03 filed** (counts 29→30, the §G.6 mono-encode row, AC-AUD-32's scope); §10's table carries the fold's own row; the counts line and the risk table carry the CR. The decision stands either way (fallback: the native effect, 29 files) |
| 4 | Probe 2's `AudioEffectCapture` was a second `AudioEffect`, contradicting §3/§10 | tech 4 | **APPLIED** — the probe runs in a **dev-only probe scene on a dedicated probe layout**, explicitly exempt; the one-effect law governs the shipping layout |
| 5 | `max_polyphony = 1` vs four voices declaring `Max conc. = 2` — the mapping was undefined and the pool arithmetic left no room | tech 5 | **APPLIED** — a conc-2 voice occupies **two slots from the same pool**; each slot is individually stealable; the retrigger floor is evaluated per voice before admission |
| 6 | The WAV fallback's arithmetic omitted the fold's 0.55 MB (84 s → a 10 MB breach) | tech 6, QA rec | **APPLIED** — ~78 s (10 − 1.1 − 0.55 − 1.5 = 6.85 MB), plus the residency cost against the 16 MB runtime bar |
| 7 | Items 5/7/8 marked `DOCUMENTED` on citations the repo does not contain | tech 7, QA 2 | **APPLIED** — all three `PROBE-PENDING` with methods; item 5 is measured as an extra instrument during AC-AUD-21's device run; only item 6 stays `DOCUMENTED` (the one the snapshot actually pins) |
| 8 | The probes' `Blocks` cited ACs that do not test the probe's claim (item 2 → AC-AUD-30, item 3 → AC-AUD-22, item 4 → AC-AUD-02) | QA 3 | **APPLIED** — `Blocks` now names what the probe **gates** (the import, the stage, the tick bar), not an unrelated AC |
| 9 | Probe pass criteria were undefined ("the seam threshold", "does not click", "does not zipper") | QA 4 | **APPLIED** — `SEAM_DELTA_MAX`, `ZIPPER_DELTA_MAX`, exact-tick assertions, and a 1,000-request / 20-trial shape where a trial count is needed |
| 10 | The MONO decision added two uncovered failure paths (the swap click; the fold's missing asset) and criterion 11 cited AC-AUD-22 for a click assertion AC-AUD-22 does not make | QA 5 | **APPLIED** — the fold's `AUD_ASSET_MISSING` path is named in §4 (no new record ID: it is §G.8's asset class), and criterion 11 now cites AC-AUD-22 **plus** the swap's own fixture |
| 11 | Validation 17 ("zero `PROBE-PENDING`") is false by construction at acceptance | QA 6 | **APPLIED** — the list is split into **ADR acceptance** (1–15) and **story gate** (16–17) |
| 12 | The traceability row said "the **eight** one-shot voices" for TR-AUD-015…021, which own **eleven** | QA 1 | **APPLIED** — relabelled "the eleven", with the per-TR voice mapping printed |
| 13 | O-AUD-1 silently re-pointed TR-AUD-002's publisher (SYS-03 → SYS-05) with no revision route | CD 2 | **APPLIED** — **CR-AUD-04 filed** (TR-AUD-002's load-complete row is a one-clause correction to a frozen GDD); O-AUD-1 remains the carrying obligation; no frozen text edited |
| 14 | Minor, all applied | CD/tech/QA recs + creative | §8 names `AUD_DUCK_BUS_MISSING`; SYS-15's third exit recorded as an **assumption** beside O-AUD-1; §11's room activation is the **named exception** to R9 (no record, no distinct behaviour); §2 and §11 agree on "five publishers + the clock"; §6's `min()` case makes the floor hold **zero, never negative**; §3 warns that `modules/audio.md`'s own Tween example is the forbidden pattern; a V-invariant coverage line added; the CRs appear in the counts line, the risk table and Related; the creative seat's three in-lane recommendations applied (the MONO swap **defers out of [E1, E7]**, the fold's loudness is RMS-matched, and "no stereo asset without a fold" is a pipeline rule) |

**Rebuttals (ADR-0003).** None material — every blocker and every in-lane
recommendation was applied. Three recommendations are **deferred, not rejected**:
a GUT for the bus group map (AC-AUD-22's device assertion is the GDD's; a GUT would
be an addition), the `MVP_FLIP_TO_EPOCH` boot-assert fixture (a story detail), and
AC-AUD-20's re-pin owner (the audio-director's sound-bible pass, recorded there).

## 4 · Rebuttals

Recorded in §3's two rebuttal lists (three for ADR-0002, none for ADR-0003).

## 5 · Final verdict

**Both ADRs: `Proposed` — gates complete, acceptance pending the technical-director's
TD-ADR verdict.** The `/architecture-review` returned `CONCERNS` with **zero
blockers**; an advisory review verdict does not replace the TD-ADR gate, and a
`Status: Accepted` would let story-readiness start stories against these decisions
early. The acceptance text is prepared below; flipping the two status lines is the
TD's step (or the orchestrator's, on the TD's word).

### The gate trail

| Gate | ADR-0002 | ADR-0003 |
|---|---|---|
| CD (GLM) | APPROVED, 0 blockers | CONCERNS, 2 blockers → both repaired (CR-AUD-03/04 filed; §4's MonoStage redefined) |
| creative (GLM) | APPROVED, 0 blockers | APPROVED, 0 blockers (3 in-lane recommendations applied) |
| technical (DS) | NEEDS REVISION, 7 blockers → all applied | NEEDS REVISION, 7 blockers → all applied |
| QA (DS) | NEEDS REVISION, 7 blockers → all applied | NEEDS REVISION, 6 blockers → all applied |
| qa-lead spot-check | #1 **FAIL** (5 of 13 rows misapplied) → repaired → **#2 PASS** (8/8) | same batch |
| final micro-check | #1 FAIL (3) · #2 FAIL (1) · #3 FAIL (2) · **#4 PASS (0 blockers)** | same batch |
| `/architecture-review` | **CONCERNS, 0 blockers**, 10 recommendations → all applied; confirm pass verified 8 APPLIED + 2 MISAPPLIED → both closed | same gate, pair-scoped |
| CodeRabbit | 10 threads, all 10 valid, all applied + resolved | same pass |
| CodeRabbit wave 2 (repair pass) | **5 threads, all 5 valid, all applied + resolved** (§8) | same pass |
| Repair-pass gates | technical (DS) **NEEDS REVISION (6) → all applied** · spot-check (DS) **PASS 11/11** · micro-check **#1 FAIL (1) → #2 FAIL (2) → #3 FAIL (1) → #4 PASS → #5 PASS (0)** | same batch |

### The prepared acceptance record (unsigned)

On the TD-ADR verdict, both ADRs become **Accepted**, on this record:

- the architecture review's `CONCERNS` with **zero blockers**, every recommendation
  applied and confirmed;
- the complete lane gate trail above (42 review blockers + 10 CodeRabbit findings,
  all applied; 3 written rebuttals, none silent);
- the **carried obligations** named below — implementation gates, not status gates.

**Carried obligations (named, not silently accepted).**

| ID | What | Owner | Blocks |
|---|---|---|---|
| SYS-03 engine half | the 34 fixtures in-engine; `TYPE_INT` after the normalization pass; F-SAV-01's three digests | the first SYS-03 story | that story |
| CR-SAV-01 | **the close-save exit path's frozen-text reconciliation, in four clauses**: AC-SAV-23 clause 1 gains "the commit that completes — including after `SAVE_JOIN_TIMEOUT_MS` — restores the suspension snapshot; where it is abandoned before its rename, interrupted before step 5, or fails on the exit path, the fallback applies"; clause (b) gains the matching "only when"; TR-SAV-014's "joined at shutdown" gains "…except on the abandonment path"; clause (c)'s code-assertion is scoped to a process that survives to observe it | the user (batched) | the exit path's AC/TR wording — not the mechanism |
| O-AUD-1 | `restored_epoch` on SYS-05's `load_complete` + its post-flip-load assertion | SYS-05's authoring | the post-flip-load bed |
| CR-AUD-03 | the mono fold = a 30th file (counts 29→30, the §G.6 row, AC-AUD-32's scope) | the user (batched) | the first audio story's asset count (enforced by its story gate) |
| CR-AUD-04 | TR-AUD-002's load-complete publisher (SYS-03 → SYS-05) | the user (batched) | nothing in the ADR; a reader's misdirection |
| OQ-AUD-9 | **any looped asset whose authored duration exceeds its rung's ceiling** (beds ~78 s combined; the score pair ~28 s) — re-author to the ceiling, or an explicit scoped revision of the seamless-loop requirement | the audio-director | the first audio asset whose loop exceeds its rung; the ladder's ceilings are priced either way |
| Probe registers | 9 `PROBE-PENDING` (save) / 7 (audio) with Methods and Owners | the named owners | the first story per ADR |

**Counts at this record.** ADR-0002: 26 TR-SAV / 4 F-SAV / 9 V-SAV / 26 ACs
consumed, 0 added; 10 probe items; 3 rebuttals; **1 CR filed** (CR-SAV-01).
ADR-0003: 39 TR-AUD / 7 F-AUD / 7 V-AUD / 32 ACs consumed, 0 added; 8 probe items;
0 rebuttals; 2 CRs filed; **1 open question filed** (OQ-AUD-9).

## 6 · Sync notes (for the orchestrator; not edited here)

Nothing here touches `design/registry/entities.yaml` or `design/gdd/systems-index.md`,
and this lane produced **no** registry entry and **no** index row — ADRs are not
registry entities. The notes below are corrections the owning lanes should apply:

1. **`save_roundtrip_twin` says 32/32; the twin runs 34/34.** `node
   tests/save-twin/save_twin.mjs` prints 34 `PASS` lines; the GDD's header and gate
   manifest both say 34/34. The registry's `values` line should read **34/34**.
2. **SYS-04's §K.3 dependency table is stale on two rows**: SYS-03 is listed
   "Not Started" (it landed 2026-11-14, PR #45) and SYS-15 is listed "Not Started"
   (it is authored — `design/gdd/cache-stations-death.md`, TR-CSD-015/AC-CSD-15).
   Neither affects a decision; both mislead a reader.
3. **`docs/architecture/tr-registry.yaml` is still empty** (`requirements: []`).
   ADR-0001 governed 26+ SYS-01 TRs and did not populate it; these two ADRs govern
   26 + 39 more. The TR population is `/architecture-review`'s write, not this
   lane's — flagged so the architecture-review run does not assume it was done.
4. **`docs/framework/technical-preferences.md`'s "Architecture Decisions Log"**
   gained ADR-0002 and ADR-0003 rows (the established index convention; ADR-0001
   is listed there). That is a docs index, not a shared design file — recorded here
   because it is outside `docs/architecture/`.
5. **`SAVE_MIN_FREE_BYTES`** is an ADR-local constant with no GDD knob entry (it is
   in neither the knob table nor the "not knobs" list). If it ever becomes
   player-tunable it needs a GDD knob entry; otherwise it stays a constant.
6. **SYS-07's Health/Damage ADR is the next candidate** (see §0's scope table) —
   not drafted in this pass.

## 7 · Notes on the review definition used

- The lane prompt's review definition (CD · creative · technical · QA ·
  spot-check · micro-check) was applied **per ADR**, with the CD gate and the
  three-seat panel dispatched in one batch against the same draft commit and each
  seat returning **two verdicts** (one per document). The `/architecture-review`
  obligation was run **pair-scoped** (its real scope is cross-ADR), twice: a first
  pass and a confirm.
- **Models**: CD + creative on `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`;
  technical, QA, spot-check, micro-check and architecture-review on
  `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`. Every seat was
  a **nested subagent** with its model passed explicitly; no seat was run
  in-session.
- **Cost note, recorded honestly**: the spot-check/micro-check loop took four
  micro-check passes. Each found a real residual (a contradiction between a repair
  and its duplicate elsewhere in the document). The loop is the reason the final
  state has zero blockers; it is also the main cost of this lane.

## 8 · Repair pass — the second CodeRabbit wave

**What arrived.** After the confirm pass, CodeRabbit's re-review opened **5 new
threads** (16 total on PR #79; the first batch resolved 11). Severity: **3 Major**,
all three on ADR-0003's loop-seam fallback, and **2 Minor**, both on ADR-0002. All
five were **valid**: none was a duplicate of the first batch, none was a false
positive, and two of the three Majors were arithmetic/logic gaps that the first
batch's own repair had left open.

### 8.1 The five dispositions

| # | Thread | Sev | Where | Finding | Disposition |
|---|---|---|---|---|---|
| 1 | `PRRT_…oW22` | Minor | adr-0002 §3 | the hash-coverage sentence said only `state_hash` was outside the hash, contradicting §3's own "informational, outside the hash" line for `game_version`/`saved_at_utc` | **APPLIED** — §3 now names **all three** excluded values (`game_version`, `saved_at_utc`, `state_hash`) and says `schema_version` + the whole payload are inside; a new validation criterion asserts the count of three |
| 2 | `PRRT_…oYv-` | Minor | adr-0002 §5 | an abandoned close-save can still commit (the step-5 rename survives the timeout), contradicting R4 + the exit policy ("the last station autosave is returned") | **APPLIED** — **one behaviour, two regimes**, with a **step-3b fence** (§8.2) |
| 3 | `PRRT_…oW23` | Major | adr-0003 §10 | if the mono fold fails the seam probe the fallback replaces the stereo score with WAV but leaves `MUS_HOUSE_LOOP_MONO` on Ogg — MONO keeps playing the rejected loop | **APPLIED** — the fold gets its own specified **and budgeted** fallback row; **the pair moves together, always** (§8.3) |
| 4 | `PRRT_…oW26` | Major | adr-0003 §10 | the WAV score fallback fails SYS-04 §G.6's import audit (the score row pins Ogg) | **APPLIED** — the **audit rule is defined in the ADR** (two-row table + a manifest declaration + gate evidence), **conditional on CR-AUD-03's widened scope**; the GDD is **not** edited; the rider is recorded (§8.4) |
| 5 | `PRRT_…oW29` | Major | adr-0003 §10 | a score longer than 38 s kept Ogg even with a seam delta above `SEAM_DELTA_MAX`, and a *recorded* delta is not a seamless loop | **APPLIED** — the pass condition is now **absolute and per asset**; the ladder is fully budgeted; the un-priceable case is **OQ-AUD-9** for the audio-director, with a fail-safe default (§8.3) |

### 8.2 Thread 2 — the choice, and why it is neither of the two offered

The thread offered two behaviours: (i) a cancellation check before step 5 + the
fence in the step table, or (ii) amend R4/the exit policy to allow a late commit.
**Neither is implementable alone**, and that is what the repair states:

- **(i) alone is a promise the platform cannot keep.** A fence cannot *un-issue* a
  `rename_absolute` the kernel is already executing — and a blocked rename is
  precisely the syscall the 250 ms bound fires on. "The write never lands" would be
  the same class of aspirational claim the exit policy already exists to avoid.
- **(ii) alone leaves the common case silently rewriting the slot.** The typical
  timeout blocks at step 2 (the `store_*`), not at a rename; without a fence that
  write resumes later and commits, which the old exit policy's wording forbade
  while the mechanism allowed it — the contradiction the thread found.

**The behaviour adopted**: abandonment is decided at **one fence (step 3b)** placed
immediately before the first destructive operation, so **an abandoned write never
*starts* a commit** and the slot keeps the last station autosave; and **a commit
already in flight ends in one of two bounded states** — the suspension snapshot (it
completes) or the previous generation (the platform's kill lands between steps 4
and 5, so step 5's row promotes the `.bak`). Never torn; never older than the last
station save. R4 and the exit policy are restated to match, and the step table
carries the fence as **row 3b, explicitly not a seventh step** (TR-SAV-010's shape
is unchanged).

**Why this keeps AC-SAV-23 coherent** — and the one thing the repair had to *file*
rather than read: regime 1 (delivered, attempted, abandoned) is a **fourth case**
the frozen AC's "only when" excludes. Its *recovered state* is clause (c)'s
(the previous good state), but **no code is observable** — the process is exiting.
The ADR does not reinterpret the AC and does not invent a seventh `SAVE_FAILED_*`
code (R7 freezes six): it files **CR-SAV-01**, four clauses — AC-SAV-23's clause 1,
clause (b), TR-SAV-014's "joined at shutdown" (skipping that join on the abandonment
path is the whole point: joining would be a second unbounded wait), and clause (c)'s
code-assertion, which is scoped to a process that survives to observe it.

**Two refinements the confirm pass then forced, both recorded because they were my
errors, not the reviewer's:**

1. **Key the CR to the commit's outcome, not to the timeout.** The first draft said
   the fallback applies when the close-save "did not commit within
   `SAVE_JOIN_TIMEOUT_MS`" — which classifies the *late commit* §5b explicitly
   permits (a rename already in flight that completes) as a fallback, when it
   actually restores the **better** state. The clause now reads "the commit that
   **completes** — including after the bound — restores the suspension snapshot;
   where it is abandoned before its rename, interrupted before step 5, or fails on
   the exit path, the fallback applies".
2. **The exit path is commit-point-exact, not a range.** A failure at **steps 1–4**
   leaves the slot **unchanged** (a step-4 rename is atomic, so `.sav` is untouched
   — there is nothing to promote); a failure at **step 5** leaves `.sav` missing
   with `.bak` present, so the sweep promotes it; a failure at **step 6** is
   post-commit and its own rollback promotes the `.bak`. My first wording said
   "steps 4–5 → promotion", which would have had an implementer assert a promotion
   for a step-4 failure.

### 8.3 The three ADR-0003 threads as ONE design

The three threads interlock, so they were repaired as one fallback design rather
than three patches. The design has four parts:

1. **The pass condition is absolute and per asset.** A seam delta above
   `SEAM_DELTA_MAX` **never ships on any rung**; a recorded delta is evidence of a
   failure, never a waiver (this deletes the old "accepted for the score alone").
   `SEAM_DELTA_MAX` is calibrated **on the asset's own material** — the old
   definition ("the bed's own interior") would have failed a legitimate score
   forever, because the new absolute gate judges the score too.
2. **The fold always follows the score.** The score's stereo + mono encodings are
   one **pair**: an Ogg fold beside a WAV score keeps the rejected loop playable on
   the one path the MONO toggle exists to reveal. So the pair moves together, and
   its WAV cost is the **pair's** — which is exactly what makes the old ~38 s
   ceiling wrong.
3. **One budgeted ladder**, with a ceiling in seconds per rung (10 MB bar, one-shots
   1.5 MB fixed, WAV 88.2 kB/s mono / 176.4 stereo):

   | Rung | Ceiling |
   |---|---|
   | beds WAV only (score pair Ogg) | **T_beds ≤ ~78 s** combined |
   | score pair WAV (beds Ogg) | **T_score ≤ ~28 s** (7.4 MB ÷ 264.6 kB/s) |
   | all WAV | **88.2·T_beds + 264.6·T_score ≤ 8,500 kB** (~96 s of beds if the score takes none) |

   Two arithmetic corrections, both the same kind: the score's ceiling was priced at
   176.4 kB/s with the fold left on Ogg (**~38 s → ~28 s**), and the shared pool
   released only the score's 1.1 MB (**7.95 → 8.5 MB**). The ladder's **first** rung
   is not a format change at all — it is the authoring fix, because a WAV switch
   cannot repair an authoring seam (register item 8 uses the same tolerance).
4. **The un-priceable case is filed, not decided.** The score's loop length is the
   sound bible's and is not yet authored; the beds' `~1.1 MB` Ogg pin implies
   ~110–140 s, longer than the beds-fail rung allows. **Any looped asset over its
   rung's ceiling** therefore has no rung that meets both the seamless requirement
   and the bar → **OQ-AUD-9** for the audio-director (re-author to the ceiling, or
   an explicit scoped revision of the seamless requirement), with **re-author as the
   fail-safe default**. Branch (ii) is named honestly: it ships a seam that fails
   the *current* threshold and is legal only once the requirement is revised — it is
   not a waiver and this ADR never takes it.

### 8.4 Riders filed (nothing frozen was edited)

1. **CR-AUD-03's scope is widened** to carry, besides the mono fold's count and
   §G.6 row, **the three fallback rows** (beds; the score pair's stereo + mono) and
   AC-AUD-32's THEN clause ("match §G.6's row **or**, where the import manifest
   declares `fallback_probe2`, that class's fallback row"). Until it lands the audit
   runs §G.6 literally — a passing state, because no asset sits on a fallback row
   until probe 2 fails and the rung is chosen.
2. **The declaration lives in `assets/audio/import-pins.yaml`**, a project-owned
   committed manifest, **not** in an `.import` `[params]` block — the importer
   regenerates those on every reimport, so a custom key there is not durable.
3. **`OQ-AUD-9`** is filed in the ADR's namespace (the GDD's table runs OQ-AUD-1…8)
   and rides the next SYS-04 touch, exactly as CR-AUD-03/04 do.
4. **`CR-SAV-01`** is filed for SYS-03's next touch (three clauses, §8.2).

### 8.5 The repair batch's gates

| Gate | Seat model | Verdict |
|---|---|---|
| technical (DS) on the repair diff | `deepseek-v4.1-flash` | **NEEDS REVISION — 6 blockers**, all applied: the AC-SAV-23 clause-1 scope (→ CR-SAV-01), "a commit always finishes" (→ the two bounded outcomes), the audit rule reinterpreting a frozen AC (→ conditional on CR-AUD-03), `SEAM_DELTA_MAX` borrowed across asset classes (→ per asset), the beds' ceiling with no fail-safe (→ OQ-AUD-9 widened), and `fallback_probe2` in a regenerated `.params` (→ the manifest) |
| repairs applied | — | 6 blockers + 5 of 8 recommendations |
| qa-lead spot-check (DS) on the repair diff | `deepseek-v4.1-flash` | **PASS — 11/11 rows** (5 threads + 6 blockers), 0 regressions |
| micro-check #1 (DS) | `deepseek-v4.1-flash` | **FAIL (1)** — CR-SAV-01 under-scoped (clause 1 too, not just clause (b)) |
| micro-check #2 (DS) | `deepseek-v4.1-flash` | **FAIL (2)** — the "timed wait on §5's Semaphore" had no completion signal to wait on; "joined at shutdown" vs "the join is skipped" stated as two laws |
| micro-check #3 (DS) | `deepseek-v4.1-flash` | **FAIL (1)** — the completion post was not job-specific (a stale/other-slot post satisfied the wait) |
| micro-check #4 (DS) | `deepseek-v4.1-flash` | **PASS (0 blockers)** |
| micro-check #5 (DS) | `deepseek-v4.1-flash` | **PASS (0 blockers)** — the six post-pass edits; 2 notes applied (the `completed_seq` seq-gap, and `Semaphore.wait`'s timeout marked unverified with the poll fallback) |
| CodeRabbit confirm pass #1 | — | **4 new threads, all valid, all applied** (§8.6) |
| technical (DS) on the wave-3 delta | `deepseek-v4.1-flash` | **NEEDS REVISION — 2 blockers**, both applied: register item 8 was a corrupted table splice, and the commit-outcome enumeration omitted the *failed* write on the exit path |
| qa-lead spot-check (DS) on the wave-3 delta | `deepseek-v4.1-flash` | **PASS — 10/10 rows** |
| micro-check on the wave-3 delta | `deepseek-v4.1-flash` | **FAIL (3)** — a step-4 failure is not a `.bak` promotion; clause 1's "steps 2–5" excluded step 6's rollback; clause (c) was left unamended → then **PASS (0 blockers)** |
| CodeRabbit confirm pass #2 | — | **PASS**, no new threads |

**The loop, recorded honestly.** Five micro-check passes for five threads: the
first three each found a real residual *created by the repair itself* (an
under-scoped CR, a wait with no signal, a post that was not job-specific). That is
the same pattern as the first batch — a repair's own new claims are the risk, not
the text it touched — and it is why the loop is not optional for a Major-class
batch.

### 8.6 The confirm passes

**Confirm pass #1** ran on the wave-2 commit and opened **4 more threads** — all
valid, all applied in `12accc0`, all resolved:

| # | Sev | Finding | Disposition |
|---|---|---|---|
| 6 | Major | CR-SAV-01 keyed the fallback to the *timeout*, but §5b permits a late commit that restores the better state | **APPLIED** — keyed to the commit's outcome (§8.2's refinement 1) |
| 7 | Major | the seam threshold (the asset's loudest interior transient) would pass an audible click: an 0.8 interior transient licenses a 0.5 jump at a quiet loop point | **APPLIED** — `seam_pass()`: a boundary-local **step** bound and **slope** bound over the seam's own 50 ms windows (each excluding the seam's own pair/triple, so neither is vacuous), plus `SEAM_DELTA_MAX` as the scalar interior-peak **third conjunct**; contiguity is a precondition and the seam index comes from the authored `loop_end` |
| 8 | Major | the ~42 s figure was presented as an independent native ceiling | **APPLIED** — it is rung-specific (beds on Ogg); the fold-declined + beds-failed branch gets `88.2·T_beds + 176.4·T_score ≤ 8,500 kB`, and 70 s + 42 s + one-shots is priced at ≈ 15.1 MB against the **10 MB disk** bar |
| 9 | Minor | probe 2 did not name the mono fold as its own capture target | **APPLIED** — every looped file is its own capture (5 seams: 3 beds + the score pair), and a **fold-only failure is a pair failure**, never a fold-only swap |

**Confirm pass #2** ran on `12accc0`: **PASS**, no new threads. `UNRESOLVED=0`; every
thread in both waves was resolved by reply with its disposition. The wave's commit
hashes are in the lane report §6.
