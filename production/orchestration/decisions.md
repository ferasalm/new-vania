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

- **Decision (user, 2026-11-16)**: **ACCEPT both.** ADR-0002 (Save & Serialization) and ADR-0003 (Audio Core) flip `Proposed` → `Accepted`; the two `docs/framework/technical-preferences.md` rows flip with them; the prepared acceptance records in the review log §5 get signed. The flip executes with the orchestrator's next receipt (a `docs(adr)` commit naming D-ORCH-06).
- **Status**: **RESOLVED.**

### D-ORCH-07 — CR-SAV-01: the close-save exit path (four clauses)

- **Decision (user, 2026-11-16)**: approved as filed — the four clauses: AC-SAV-23 clause 1 (a completed commit restores the suspension snapshot even after the bound); the fallback only where the write is abandoned before its rename, interrupted before step 5, or fails on the exit path; TR-SAV-014's join; clause (c)'s code-assertion scoped to a process that survives to observe it. No mechanism change.
- **Status**: **RESOLVED** — a recorded SYS-03 rider at its next doc touch.

### D-ORCH-08 — CR-AUD-03: the mono fold is a 30th file

- **Decision (user, 2026-11-16)**: approved — the counts line 29 → 30, the §G.6 Score row, AC-AUD-32's scope, and the three loop-seam fallback rows as ADR-0003 authors them.
- **Status**: **RESOLVED** — a SYS-04 rider.

### D-ORCH-09 — CR-AUD-04: the load-complete ownership

- **Decision (user, 2026-11-16)**: approved — TR-AUD-002's load-complete seam is **SYS-05's**, not SYS-03's; the one-clause SYS-04 correction rides SYS-04's next doc touch and names this decision.
- **Status**: **RESOLVED** — a SYS-04 rider.

### D-ORCH-10 — OQ-AUD-9: the loop lengths vs the seam ceilings

- **Decision (user, 2026-11-16)**: **branch (i)** — re-author any exceeding asset to its rung's ceiling (~78 s beds / ~28 s score pair / 8.5 MB joint). The audio-director executes; branch (ii) (an explicit seamless-loop requirement revision) needs an explicit user call only if an asset cannot be re-authored.
- **Status**: **RESOLVED** (default branch (i)).

### D-ORCH-11 — the SYS-13 deflect's weight

- **Decision (user, 2026-11-16)**: **accepted** — the deflect is a positional tool; the 16.7%-of-pool share stands; no value change, no SYS-08 amendment.
- **Status**: **RESOLVED.**

### D-ORCH-12 — the stagger knob's floor

- **Decision (user, 2026-11-16)**: **keep 500 ms** — the sub-617 outcome stays defined (the counter alone: 6 at ATK 100, 8 at ATK 132); SYS-13 may revisit at its next touch, nothing forced.
- **Status**: **RESOLVED.**

### D-ORCH-15 — the hybrid-prototyping pivot + the prototype design rules (DECIDED by the user, 2026-11-16)

- **The pivot**: the user wants **playable prototypes to judge, not more documents** ("everything that is written doesn't give a clear picture compared to actually playing/testing it"). The sandbox suite is the first deliverable (`prototypes/sandbox/`, PR #88 `fa628cf`; v2 building). The GDD machine **finishes the in-flight lanes, then pauses** until the playtest verdicts stabilize the design.
- **The prototype design rules (user, from the v1 playtest)**: real sprites from the concept art + the downloaded packs; **ONE attack button** (attack/clash/counter on the same button, context by timing); **no fall damage and no death from falling** (falls = a soft reset to the last safe spot); **no room locks outside boss arenas** (no DMC-style fight locks); **every boss door looks special** (a consistent, taught door language); mini-bosses from the downloaded packs; the user must be able to test it themselves (cold-start launch, no build steps).
- **Status**: **DECIDED** — active; the rules govern all prototypes.

### D-ORCH-16 — SYS-05's feasibility brief (DECIDED by the user, 2026-11-16)

- **Decision**: **approved as presented** (Option A). The four load-bearing recommendations (the Stinger grant beat at the first cache activation; Loading as the eighth context; the load-complete gate shape; the generalized spawn anchor) + OQ-DR-1 ratified verbatim. Executed: the SYS-05 GDD landed at PR #87 (gates closed).
- **Status**: **DECIDED.**

### D-ORCH-17 — SYS-24's feasibility brief (DECIDED by the user, 2026-11-16)

- **Decision**: **approved as presented** (Option A). The eight design decisions (the caps law, the settings-persistence split, the chip geometry, the bible-list accept/decline set, the envelope join, the per-script label caps, the truth-temperature accent, `TEXT_SCALE`). Executed: the HUD GDD is at PR #86 (gates closed).
- **Status**: **DECIDED.**

### D-ORCH-18 — ONE attack button: the combat input revision direction (DECIDED by the user, 2026-11-16)

- **The change**: attack, clash, AND counter move to a single button — context comes from timing (tap = strike; pressed into an incoming strike = clash; pressed on the telegraph-flash cue = counter). The separate light/heavy/counter buttons go away.
- **Why it is a decision**: this revises the frozen SYS-01 input contract (the eight verbs, the audited layout table) and SYS-08's clash/counter wiring. Per the pivot, **the prototype validates it first**; the contract revision executes into SYS-01/SYS-08 when the GDD machine resumes, with the commits naming D-ORCH-18.
- **Status**: **DECIDED — direction; execution deferred to the resume (prototype validates first).**

### D-ORCH-19 — Arnetria, the Mirror Queen: the Denial fight redesign (DECIDED by the user, 2026-11-16)

- **The change**: the Denial boss is **Arnetria, the mirror queen**. The damage she takes is **stored** (the bar does not move — the lie); she spawns **mirrors**; destroying a mirror in time deals her ALL the stored damage at once; failing the timer **clears** the stored damage. This **replaces** SYS-14's R1 crack route (the 3-sweep whiff counter).
- **Why it is a decision**: SYS-14's GDD (PR #82, landed) authors the crack route; this is a contract revision to it. The prototype validates first; the SYS-14 revision executes at the resume (the commit names D-ORCH-19). The blindfold/mirror-visor concept render is the visual anchor.
- **Status**: **DECIDED — direction; execution deferred to the resume.**

### D-ORCH-20 — no fall damage, no death from falling (DECIDED by the user, 2026-11-16)

- **The change**: falls deal no damage and never kill; a fall is a soft reset to the last safe standing spot. This revises the lethal-pit construction in frozen SYS-02/SYS-07 (`env_void_damage` 20, "the pit still lethal by construction").
- **Status**: **DECIDED — direction; the contract revision executes at the resume.**

### D-ORCH-21 — the production-scope direction + Twine (DECIDED by the user, 2026-11-16)

- **Longer and richer**: the GDDs' detail supports **more parts and a longer game** — aim for a longer, richer experience than a single short MVP arc.
- **Backtracking**: the player backtracks into familiar places that have **changed** (re-affirmed; SYS-10's world-mutation epochs are the machinery).
- **Twine**: the story and decision tree are authored in **Twine** (installed on Windows); the narrative team owns the `.twine` sources as the canonical branching draft, feeding the dialogue/beat GDDs.
- **Status**: **DECIDED — standing direction.**

### D-ORCH-22 — the asset license authorization (DECIDED by the user, 2026-11-16)

- **The authorization**: every downloaded pack may be used — **all assets came from itch.io or MIT-licensed GitHub repos; none is copyrighted or obtained illegally** (user verification, 2026-11-16). The license sweep records it: per-pack evidence rows + `assets/<pack>/LICENSE` + `assets/CREDITS.md`; per-pack promotion into `assets/` happens on use.
- **The provenance recall + no-exception re-affirmation (2026-11-16, later the same day)**: the user recalls downloading the assets **from itch.io, from the creator Ansimuz**, and re-affirms **all assets at hand may be used, with no exception**. The seven previously `provenance pending` rows are attributed on that recall (Ansimuz via itch.io); their store-page/license-text capture stays open as the asset-audit gate, and any row whose attribution the capture contradicts is corrected at promotion time.
- **Status**: **DECIDED — standing authorization (amended: provenance recalled, no exception).**

### D-ORCH-23 — the TD-ADR verdict on ADR-0004 (DECIDED by the technical-director, 2026-11-16)

- **Verdict**: **ACCEPT WITH CONDITIONS** — C1 (§4d: the producer's door `CombatBodyPort.apply_damage`, the 32-slot event ring as the batch, `EVENT_RING_FULL`, the pooled `HealthEvent` union — resolves the TR-CMB-031 conflict), C2 (§8b: `heal()` = admission 0/1, `heal_phase()` = the application; the applied amount on the `HealEdge`), C3 (§4/§4d + register item 6: the freeze-onset assert is the composition root's; `HealthPort` stays five-method). All three + the editorial batch applied in the receipt PR; **ADR-0004 flipped to Accepted in the same PR**.
- **Rulings recorded in the log §10**: the nine judged items approved; **O-HD-7 ruled — no namespace, amend AC-HD-08** (SYS-07's next doc touch); **O-HD-9 — resolution (i) recommended (the body is session-only at MVP), batched to the user**; CR-HD-01/CR-HD-02 substance ratified; O-HD-11's split ratified; **six new story-gate obligations O-HD-12…17**; probes #6/#4/#5 run first; **ADR-0005 (the composition root / tick director) queued as the next ADR** — it gates the first SYS-07 integration story; S5: `tr-registry.yaml` is empty and blocks every story until `/architecture-review` populates it.
- **Status**: **DECIDED (TD verdict executed).** Open sub-items for the user batch: the O-HD-9 recommendation (resolution (i)) and the CR-HD-01/02 nod.

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

### D-ORCH-24 — feel first: prototype v3 is tuned by playing; the verdict log outranks the documents (DECIDED by the user, 2026-11-16)

- **The change**: **Feel first.** The user rejected prototype v2 after playing
  it. Prototype v3 (`prototypes/feel-v3/`) is tuned by playing, not by copying
  numbers from the documents. The playtest verdict log
  (`production/playtests/VERDICTS.md`) outranks the design documents. The
  frozen movement and combat documents will be revised after the user approves
  the feel (stage 4). The design-document queue stays paused until then.
  Everything put to the user for approval follows
  `.agents/rules/plain-language.md`.
- **Status**: **done** — standing direction.

### D-ORCH-25 — concept art is reference only; ask the user before making art; Pandora-001 and three bars (DECIDED by the user, 2026-11-16)

- **The change**: Everything under `design/art/` and `assets/processed/` is **concept**, not
  game-ready art. Game art is redrawn, or reused from the owned asset packs and edited to fit.
  Before drawing or choosing art, an agent **asks the user** what they want to see; the
  current concept art is not enough and the user will supply more when asked. The protagonist
  is **Pandora-001**. The player has three bars: **HP**, **Energy** (attacks and backdashes),
  and **MP** (special attacks such as Up + Attack). The record is
  `production/playtests/VERDICTS.md`.
- **Status**: **DECIDED — standing direction.**
