# Decisions — the batched user-decision queue

> **Rule**: the orchestrator stops and asks the user **only** for a hard blocker,
> a contract revision, an art-bible direction decision, or a required-review
> refusal on a future lane PR. Everything else is batched here and presented at
> the next natural boundary. Do not interrupt for soft blockers.

## Open decisions

### D-ORCH-01 — SYS-11 OQ-1: the purple bridge vs the liminal-grey reservation

- **Lane**: ART-BIBLE (first item).
- **Question**: does the purple bridge become an art-bible-ratified gated tint, or
  does SYS-02's Player Fantasy line 36 get amended and the SYS-11 index row
  qualified?
- **The conflict**: SYS-02's Player Fantasy "Anchor moment — The Wrong Corridor"
  says: *"Beyond it a corridor the color of neither truth — the grey of a place
  between places, a purple bridge holding it together — and the last memory at its
  end."* SYS-09's TR-DR-002 reserves liminal space for greys; SYS-11's OQ-1 and
  TR-DR-012 make the purple a **gated proposal** with the P1–P5+G admission test.
- **Options**:
  - **A. Ratify the purple** as a low-saturation depth tint over the
    `PROV_LIM_*` ramp, only in the wing frame's W/E columns, never the threshold
    band, north row, fill, fixtures, or M4. The P1–P5+G admission test must pass.
  - **B. Amend SYS-02 line 36** ("a purple bridge holding it together" → the
    grey bridge / the bridge of neither truth) and qualify the SYS-11 index row
    (the OQ-M1 rider pattern). The grey `PROV_LIM_*` default ships either way.
- **Recommendation**: **B** is the lower-risk default: the grey ramp already
  ships, the liminal-grey reservation is a load-bearing color-philosophy rule,
  and the purple can still be revisited at the asset-spec pass. **A** is viable
  only if the art-director's admission test passes and the user wants the
  corridor's one chromatic signature.
- **Blocking?** The art bible's first item; the grey default ships either way, so
  it does not block SYS-11's implementation.
- **Status**: **APPROVED (2026-11-15 — user chose B).** The SYS-02 Player
  Fantasy line 36 amendment is pending the executing commit ("a purple bridge
  holding it together" → the grey bridge / the bridge of neither truth) and the
  SYS-11 index row is qualified (the OQ-M1 rider pattern). The grey `PROV_LIM_*`
  default ships. SYS-02 is a
  frozen contract: the edit is the user-approved contract revision, and the
  executing commit must name **D-ORCH-01**.
- **Decision**: _B — amend the line (recorded 2026-11-15)._

### D-ORCH-02 — SYS-11 OQ-4: the `PROV_LIM_*` L gaps + the grief pins

- **Lane**: ART-BIBLE.
- **Question**: approve the four `PROV_LIM_*` L values (with `gap_R ≥ 0.09`), the
  grief tint's C/L, and the grief hue band [330, 20]; or relax the D-gap clause to
  ≥ 0.01; or close the tint.
- **Blocking?** The art bible's palette section; not SYS-11's implementation.
- **Status**: **RESOLVED (2026-11-15 — approved as proposed).** The four
  `PROV_LIM_*` L values (with `gap_R ≥ 0.09`), the grief tint's C/L, and the
  grief hue band [330, 20] stand as specified.
- **Decision**: _approved as proposed (recorded 2026-11-15)._

### D-ORCH-03 — SYS-07-REWORK: the IP-17 baseline contract revision

- **Lane**: SYS-07-REWORK.
- **Question**: approve the low-stat baseline rework package (the reworked
  baseline numbers, the level 1–5 curve, the `TR-HD-006` "MVP has no gear" clause
  correction, the mana reconciliation input, and the ±10% parity situational-break
  OQ) as a contract revision to the frozen SYS-07 GDD.
- **Why it is a decision**: SYS-07 (and the SYS-08 co-revision) are APPROVED,
  frozen contracts. The rework is a revision, not a silent edit.
- **Blocking?** SYS-16 and SYS-17 are blocked until it lands.
- **Status**: **APPROVED — OPTION A (2026-11-15, round 2).** The user approved
  the revised package as presented: the ÷5 low-stat rescale (20 HP · strikes
  1/2/4 · the weapon table 2/4/2/2 + `DamageEvent.arc`), the SYS-08 co-revision,
  the 5-step growth ladder, the three `TR-HD-006` gear riders, mana-free
  Stinger, and the parity restatement. Named consequences accepted: DEF becomes
  decorative for gear (a SYS-16 input) and the L5→L6 handoff moves to OQ#20
  with a stated requirement. **Round-2 round trip** (round 1 was NOT approved —
  the user answered "Revise again"; the round-2 package was reconstructed from
  the frozen SYS-07 GDD, D-7/IP-17 and the five components, and its gate trail
  is CD APPROVED + the technical seat's ten-pass NEEDS-REVISION cycle, all
  repaired; record: `design/gdd/reviews/sys07-rework-review-log.md` on the
  branch, package at `04b889b`).
- **Execution**: **LANDED 2026-11-15.** The package → PR #75 (squash-merged at
  `3fcedc6`): SYS-07 `health-damage.md` + the SYS-08 `combat.md` co-revision,
  every commit naming D-ORCH-03. The applied-diff gates re-ran on the applied
  text (CD APPROVED · technical 9 repaired + 2 rebutted · qa-lead spot-check
  PASS 7/7 · micro-check PASS) and caught defects that existed only in the
  applied text (the resolver's `damage_bonus` transport, a clamp printed as a
  gate, the DEFLECT target routing). CodeRabbit: 24 threads across 4 passes,
  all resolved. The sync landed first (PR #76, `6dd4651`: the registry values,
  `damage_event` + the baseline constants, the index row/unblock, the 5th
  Gate-2 probe; `spitter_orb_damage` HELD at 8). The riders PR
  (`chore/d-orch-03-riders`) + the mini sync (the orb flip + the Suture
  correction) complete the execution. SYS-16 is unblocked; SYS-17 stays
  blocked on SYS-16.
- **Decision**: _A — approve as revised (recorded 2026-11-15; executed and
  landed the same day)._

### D-ORCH-06 — the TD-ADR acceptance verdict (ADR-0002/0003)

- **Lane**: ADR-DRAFT (landed — PR #79, `b991714`).
- **Question**: does the technical-director accept ADR-0002 (Save & Serialization) and ADR-0003 (Audio Core)? On acceptance, the two `Status:` lines + the two `technical-preferences.md` rows flip (the acceptance record is already written in the review log §5).
- **Why it is a decision**: an advisory `/architecture-review` verdict does not admit `Accepted`; the framework's TD-ADR gate does. `Accepted` lets story-readiness start stories against these decisions.
- **Blocking?** Not the merge (they landed as `Proposed`); it gates the first save/audio STORY.
- **Status**: **OPEN** — the user's return.
- **Decision**: _pending._

### D-ORCH-07 — CR-SAV-01: the close-save exit path (four clauses)

- **Lane**: ADR-DRAFT (filed by the repair pass; ADR-0002's two-regime exit policy needs SYS-03's contract to agree).
- **Question**: approve the four close-save exit clauses (AC-SAV-23 clause 1 restores the suspension snapshot even for a commit completing after the bound; the fallback only where the write is abandoned before its rename / interrupted before step 5 / fails on the exit path; TR-SAV-014's join; clause (c)'s code-assertion scoped to a surviving process).
- **Blocking?** The first save story.
- **Status**: **OPEN** — batched.
- **Decision**: _pending._

### D-ORCH-08 — CR-AUD-03: the mono fold is a 30th file

- **Lane**: ADR-DRAFT (ADR-0003's MonoStage fold + the three loop-seam fallback rows need SYS-04's counts/audit to agree).
- **Question**: approve the SYS-04 contract riders (the counts line 29→30, the §G.6 Score row, AC-AUD-32's scope, the three loop-seam fallback rows).
- **Blocking?** The first audio story.
- **Status**: **OPEN** — batched.
- **Decision**: _pending._

### D-ORCH-09 — CR-AUD-04: the load-complete ownership

- **Lane**: ADR-DRAFT. **Question**: correct TR-AUD-002 — the load-complete seam is SYS-05's, not SYS-03's (a one-line contract correction to frozen SYS-04, the commit names the decision ID).
- **Blocking?** The first audio story.
- **Status**: **OPEN** — batched.
- **Decision**: _pending._

### D-ORCH-10 — OQ-AUD-9: the loop lengths against the seam ladder's ceilings

- **Lane**: ADR-DRAFT → the audio-director. **Question**: any looped asset whose authored duration exceeds its rung's ceiling (beds ~78 s combined; the score pair ~28 s) — branch (i) re-author to the ceiling (the fail-safe default, the audio-director's to execute), or branch (ii) an explicit, scoped revision of the seamless-loop requirement (the user decides).
- **Blocking?** The first audio story (branch (ii) only).
- **Status**: **OPEN** — branch (i) is the default if the audio-director finds no exceeding asset.
- **Decision**: _pending._

### D-ORCH-11 — the SYS-13 deflect's weight (the orb's relative share)

- **Lane**: SYS-07-REWORK riders (recorded in the review log §9.3; CodeRabbit corrected the "one-shot" framing — the orb NEVER one-shotted; the deflect's SHARE rose from 13.3% to 16.7% of a T2's pool).
- **Question**: accept the deflect as a positional tool (the shipped reading; recommended — executable inside the current contracts), or lower `ORB_DAMAGE` to 1 (inside the printed 1–2 range), or a deflect bonus (needs a SYS-08 TR-CMB-015 amendment — a contract revision).
- **Blocking?** No — a tuning question; the shipped text says "the kill follows prior damage".
- **Status**: **OPEN** — default: accept.
- **Decision**: _pending._

### D-ORCH-12 — the stagger knob's floor (500 vs 617)

- **Lane**: SYS-07-REWORK riders (review log §9.7): the full ceiling chain needs 617 ms; the knob's legal range starts at 500, so the sub-617 result is now DEFINED (the counter alone: 6 at ATK 100, 8 at 132).
- **Question**: raise the knob's floor to 617, or keep 500 with the defined sub-617 outcome?
- **Blocking?** No — SYS-13's call at its next touch.
- **Status**: **OPEN** — default: keep 500 (the outcome is defined; no forced change).
- **Decision**: _pending._

### D-ORCH-13 — SYS-16: F-HD-10's module-build note (DECIDED autonomously)

- **Question**: is SYS-07's F-HD-10 module-build note a measurement ruler or a hard ±10% ceiling on gear?
- **Decision**: **(i) — the reading stands (a ruler); the gear layer ships as authored; rider (d) lands at SYS-07's next doc touch; the pool-only fallback does not execute** (`WINDOW_EXCEPTION_ENABLED` stays true; the drive payload ships; the fallback criteria stay dormant in TR-PRG-013). **Autonomous 2026-11-15 under the user's away-directive** ("keep working autonomously until I come back") — the runner's recommendation, no frozen-contract edit taken either way; revisit on return before the first gear story if desired.
- **Status**: **DECIDED (autonomous)**.

### D-ORCH-14 — SYS-14: the feasibility brief + the four design calls (DECIDED autonomously)

- **Question**: approve SYS-14's brief (R1 "the lie holds": the phase-1 hp_floor 20 + the 3-sweep crack beat; R4 the ring roster; R11 the scripted death + NO boss-defeated save family at MVP; R6 `soul_class` HUMAN) to begin authoring?
- **Decision**: **A — approved as proposed** (Option C's save-family alternative stays a VS-gated batched request — never an edit to frozen SYS-02/SYS-03). **Autonomous 2026-11-15 under the away-directive**; revisit on return.
- **Status**: **DECIDED (autonomous)**.

## Resolved decisions (this era)

| ID | Lane | Decision | Date | Record |
|---|---|---|---|---|
| D-ORCH-03 | SYS-07-REWORK | Option A — the IP-17 low-stat baseline rework approved (round 2) and applied to SYS-07 + SYS-08 | 2026-11-15 | PR #75 (`3fcedc6`) + sync PR #76 (`6dd4651`); the review log `design/gdd/reviews/sys07-rework-review-log.md` |
| D-ORCH-04 | process | Lane runners spawn as the `lane-runner` agent (nested seats restored); §3.6 demoted to last resort; SYS-15/SYS-28 fallback records stand | 2026-11-15 | PR: `chore/lane-runner-subagent`; `TOOLING.md` §5.1 |
| D-ORCH-05 | SYS-04 | The GDD header flips to APPROVED after the audio-director's countersign; the index row stays | 2026-11-15 | PR: `chore/sys04-countersign` |

### D-ORCH-05 — SYS-04 GDD header: countersign + flip

- **Decision (user-approved 2026-11-15)**: the audio-director countersigns the
  SYS-04 Audio Core GDD (the review log's §D.6 condition) and the header's
  `Status` line flips `In Review` → `APPROVED`; the systems-index row (already
  APPROVED with the condition named) stays unchanged.
- **Status**: **RESOLVED** — the countersign run is in flight (`chore/sys04-countersign`).

### D-ORCH-04 — Nested seat spawning for lane runners (process)

- **Context**: the SYS-15 and SYS-28 lane runners were spawned as OpenCode's
  built-in `general` subagent, which **cannot launch further subagents** (V2
  docs, built-ins table); both fell back to the lane-runner contract §3.6
  (seats as in-session passes on the lane's GLM model). The V2 agents doc
  confirms nesting is a per-agent `subagent` **permission**, not a hard
  recursion guard: "The parent agent's `subagent` permissions control which
  agents it may launch."
- **Decision (user-approved 2026-11-15)**:
  1. Add an `agents.lane-runner` definition to project `opencode.json`
     (`mode: subagent`; `subagent` permission allowed for `*`) and set
     `experimental.subagent_depth: 2` (the schema-verified depth setting; the
     default of one blocks the runner's seats). The
     orchestrator spawns lanes as `agent: "lane-runner"` with the manifest
     model passed explicitly.
  2. Demote the §3.6 in-session fallback in `prompts/lane-runner.md` to a
     last-resort path requiring the orchestrator's explicit order (reported
     costs: seat independence, per-seat model routing, parallelism).
  3. The §3.6 fallback records on SYS-15 (PR #59) and SYS-28 (PR #58) **stand**
     — both gate trails are closed (micro-check PASS); a DS re-pass is NOT
     ordered. Each landing receipt notes the limitation.
- **Blocking?** No — process quality for future lanes.
- **Status**: **RESOLVED** (2026-11-15).

## Standing authorizations

- **Admin-merge pre-authorization** (future lane PRs): if the ONLY blocker is the
  required review (0 unresolved threads, all required checks green), the user
  pre-authorizes **one** `gh pr merge --squash --delete-branch --admin
  --match-head-commit <sha>` per lane PR. Pass the verified head SHA; GitHub
  rejects the merge if the head moved. Record the bypass in the landing receipt.
  Any other blocker is diagnosed, not bypassed.
- **Checkpoint commits**: the user pre-authorizes small conventional checkpoint
  commits + pushes within a lane branch. No commits on `Main`; no force-push.
- **Model-failure fallback** (user decision, 2026-11-15): after 4 failed spawn
  attempts on server-side errors (routing errors, `AiError: Capacity temporarily
  exceeded`, 5xx/rate limits), a technical (DS) lane may fall back to GLM
  autonomously — recorded here. A creative (GLM) lane must never fall back to
  DS without an explicit user decision: park it `PAUSED` and surface the
  decision, or issue a launch package for a parallel chat on the same model.
- **Batched cadence**: one CodeRabbit pass per landed milestone; triage in one
  batch; one fix commit; resolve threads manually; a confirm pass only for a
  Major-class fix batch.

## How to add a decision

1. Add the ID (`D-ORCH-NN`), the lane, the question, the options, the
   recommendation, the blocking status, and the owner.
2. Do **not** interrupt the user for it; batch it.
3. When the user decides, move the row to "Resolved decisions" with the date and
   the record path; update the lane's manifest `next_action`.
4. A contract revision is never applied before the decision is recorded here.
