# SYS-28 Narrative Presentation — review log

> The lane's running log. Authoring entries first; the CD gate, the three seats,
> the spot-check, and the micro-check append below in order.

## 2026-11-15 — lane start (authoring phase)

- **Prompt**: `production/orchestration/prompts/lanes/SYS-28.md` v1.0.0, hash
  `e2e9a0f20532` — **matches** the manifest SYS-28 row (v1.0.0 /
  `e2e9a0f20532`, model GLM). Verified.
- **Worktree**: `../new-vania-sys28-narrative-presentation`, branch
  `docs/sys28-narrative-presentation`, clean at `9e20653` (the verified base
  SHA; `git merge-base --is-ancestor` PASS). `npm install` skipped — no
  hooks/tests run before the gate phase; re-run if needed then.
- **Manifest row**: dependencies `[SYS-05, SYS-10, SYS-09]`,
  `dependencies_waived: [SYS-05]`, dependency_note "SYS-05 is a pre-shaped
  contract; ratify at authoring." STATE §2 lists SYS-28 QUEUED; the review
  queue shows 0/2 three-seat slots in use — this lane takes the first slot.
- **Execution mode**: autonomous authoring per the launch instruction — the
  context + feasibility brief and each section draft are presented here and in
  the transcript as they are written; no per-section approval wait. Checkpoint
  commits + pushes on the lane branch are pre-authorized.

### Context + feasibility brief (presented for the record)

**Consumed contracts (read once, read-only):**

1. **SYS-02 `room-world-structure.md`** (APPROVED 2026-11-13):
   - **TR-RWS-021** — two logs at MVP (SYS-28's "2–3"): L1 the Vestibule log
     (RM-01, the run's establishing text) and L2 the Sanctum log (RM-04, the
     threshold log, the flip's trigger). Placed as `READ` interactables; the
     ack → the Reading context (SYS-05's); **the text and presentation are
     SYS-28's**; SYS-02 owns the placement and the flag edge L2's read sets
     (`sanctum_log_read`). Test: the text-boundary audit (no log text in
     `src/world/`).
   - **TR-RWS-019** — the terminal: SYS-02 places/prompts; **SYS-15 owns the
     terminal's surface** (MEMORY CACHED, the spending, the designation
     counter); SYS-05 owns the Reading context it opens (the ADR's non-ack
     row, queued to the next gate-entry phase).
   - **TR-RWS-020** — memory fragments M1–M4: **SYS-20 owns the fragment
     content, the counter and the presentation** ("Memory X/4"); the ack sets
     the pickup in the world-truth source list.
   - **TR-RWS-014** — the story-threshold: L2's READ ack opens the Reading
     context; when the Reading **closes**, `sanctum_log_read` sets and SYS-10
     applies the epoch 0→1. The close is the completion edge.
   - **TR-RWS-018** — the label law: `READ`/`TAKE`/`CACHE` Class A ≤ 6 chars;
     `LOCKED` Class B ≤ 8. SYS-02's labels are the mechanics words.
   - Edge case (RM-04 holds both): one context at a time — the terminal's
     request queues behind an open Reading, applies after the close.
   - SYS-02's UI section: the Reading surfaces are SYS-05/SYS-28's; the world
     word list beyond the mechanics words belongs to narrative.
2. **SYS-09 `dual-reality-state.md`** (landed 2026-11-14):
   - **TR-DR-007** — the tell registry: per-room rows, tell types
     {SYMMETRY, DEAD_CONDUIT, ERROR_CODE}, novelty kinds {STATE_DELTA,
     RE_READING}; the authored allocation RM-01 ×1 … RM-06 ×0 (arena = 0);
     tells are stateless; RM-04's tell = the error plate on the terminal's
     wall ("the cache is older than the epoch claims").
   - **TR-DR-008** — the elicitation rules: no feedback loop, ever — the game
     never points back post-flip (no highlight, flashback, codex entry); no
     tell-inspection mechanic.
   - **TR-DR-010** — the co-ownership seam: SYS-10 owns the semantic linkage
     + the telegraph-*text* surface; the term-2 binding — the log may
     dramatize the truth in the house's own voice, but may **never inventory
     the tells, name their surfaces, or confirm that the player noticed**.
   - **TR-DR-014** — the not-do list: no tutorialization of the flip (no
     popup, hint, or objective text); no re-trigger; post-flip re-reading is
     narrative-only, zero edges.
3. **SYS-10 `world-mutation-epochs.md`** (APPROVED 2026-11-14):
   - **TR-WME-008** — the telegraph-text requirements: SYS-10 owns the
     requirements, **SYS-28 owns the text, SYS-28 countersigns at the
     batch review (carried to this authoring gate)**. The L2 log may
     dramatize the truth in the house's own voice and may allude obliquely;
     may never inventory the tells, name their surfaces, or confirm
     noticing. **The epoch-invariant text rule**: L2 is a single
     epoch-invariant authored text — no epoch-conditional variants. Tests:
     the allusion audit (a named review item on SYS-28's L2 draft, SYS-28 +
     qa-lead); the epoch-invariance fixture (the L2 record identical at both
     epochs — automated, fails the build); the boundary audit.
   - **F-WME-02** — the delta namespace: exactly three MVP names
     (`REVEAL_CISTERN.GATE_OPEN.rm03_partition`, `…ZONE_MATERIALIZE.cold_corridor`,
     `…INTERACT_EXPOSE.M4`).
4. **SYS-11 `seam-borders.md`** (APPROVED 2026-11-14): the seam/M4 region
   carries **no text surface** — SYS-28 is listed under "no interface (…no
   text…)"; the reveal is wordless by design (no prompt, no VFX, no HUD
   mark); M4's grief tint is the only color the corridor admits. My text
   must never narrate the seam and M4's memory text obeys the budget +
   order-neutrality, content is SYS-20's.
5. **SYS-05 `game-flow-session.md`** — **NOT landed; pre-shaped contract,
   waived, ratified at this authoring** (the manifest dependency_note): the
   session loop hub → briefing → dive → report → contract → spend (linear
   stub at MVP — the hub door is `LOCKED`, SYS-02's RM-01 row); the Reading
   contexts ride ADR-0001's non-ack row ("Log/reading/cache terminal" —
   queued to the next gate-entry phase); **SYS-09's close ≡ completion input
   (OQ-DR-1): the Reading's close ≡ completion at MVP, no dismiss
   affordance — ratify or amend at authoring**; SYS-05 owns the contexts,
   the refusal flow's navigation, `load_complete`.
6. **SYS-03 `save-serialization.md`** (APPROVED 2026-11-14): the closed
   refusal vocabulary (10 `REFUSE_*` codes + 6 `SAVE_FAILED_*` codes); the
   codes are a **stable API, not display text**; SYS-03 never writes a
   string the player reads; SYS-05 owns the flow, SYS-24 renders the
   surface. **The display lines need an author — that is this lane** (the
   mapping code → display row). The `.bak` recovery: "the surface reports
   that the previous save was recovered."
7. **SYS-07 `health-damage.md`** (APPROVED 2026-11-12): **TR-HD-023** — the
   death edge never auto-transitions; SYS-15 presents the screen (monochrome
   glitch, **SYSTEM OFFLINE**, the quiet lowercase line *you are destroyed*,
   the **cause row printed from the `DeathRecord`**); the options contract
   pins the three rows **RECONSTRUCT AT THE NEURAL TERMINAL / DRAW THE
   RESTORE MODULE (greys, never hides) / QUIT**. SYS-07's OQ#8: "the SYS-15
   System Offline screen — …the lowercase *you are destroyed* ruling |
   SYS-15 + SYS-28 | At SYS-15 authoring" — **SYS-28 co-owns the lowercase
   ruling** (carried to SYS-15's gate).
8. **`game-concept.md`** (frozen): anti-pillar "we will NOT do
   cutscene-driven storytelling — story lives in logs, environments, boss
   encounters"; the session bookends (court briefing; the **report to the
   demon lord — dramatic irony, text-only**); diegetic serial numbers (the
   death counter stamped on the chassis, "MEMORY CACHED" as printed output,
   sigil-red strictly reserved); the MVP = 1 zone, 2–3 logs, 3–4 memories,
   one cache station; `Remade Every Death` and `Read, Then Strike` pillars.
9. **Index/manifest**: SYS-28 row (Presentation, MVP "Yes (2–3 logs)",
   depends SYS-05, owner writer); the dependency-map bullet's benchmark-audit
   rider (2026-11-14): **the micro-copy budget (≤ 3 short lines per
   terminal/log/memory beat, diegetic android-diagnostics framing) +
   alternate out-of-order discovery log states (IP-8)**; design order #21,
   "MVP-minimal; Sprint-1 background lane"; the index SYS-28 row records
   SYS-10's TR-WME-008 publication and my countersign duty.
10. Engine pin: Godot 4.7.2 (`docs/engine-reference/godot/VERSION.md`).

**Open questions entering authoring (resolved in-doc or recorded as OQs):**

- **OQ-A (resolved)** — the Reading context vs the budget: ratify SYS-09's
  close ≡ completion verbatim (no dismiss affordance; the close IS the
  completion). The budget is designed to honor it: a field beat is ≤ 3 lines
  of ≤ 46 chars (~138 chars ≈ ≤ 12 s at the 12-cps floor) — readable in one
  sitting, no scroll fatigue, no pagination at MVP.
- **OQ-B (resolved)** — the memory text: SYS-20 owns the content (TR-RWS-020);
  SYS-28 owns the beat contract (budget, order-neutrality, the no-spoiler
  law) that SYS-20's rows obey. The memory-text copy rows land at SYS-20's
  authoring gate (a carried obligation, not a placeholder here).
- **OQ-C (resolved)** — the "2–3 logs" count: MVP ships exactly **2** (L1,
  L2 — TR-RWS-021's placements); the third is index headroom requiring a
  SYS-02 placement row. Recorded, not ambiguous.
- **OQ-D (resolved)** — the terminal print ("MEMORY CACHED"): SYS-15 owns the
  surface and the phrase (TR-RWS-019; the concept's diegetic print doctrine);
  SYS-28 owns the print-voice law the phrase obeys + the print's trigger law
  (prints only on `save_completed` — the print never lies).
- **OQ-E (resolved)** — the briefing/report: VS surfaces; the contract
  (owner, trigger, structure, budgets, the irony rule) authored here; the
  literal copy is authored at SYS-05's authoring gate (registered-but-absent
  rows — the SYS-03 namespace precedent; not placeholders).
- **OQ-F (resolved)** — the death/revive text: SYS-15 owns the screen, the
  fiction and the phrases (TR-HD-023); SYS-28 owns the print-voice law and
  co-owns the lowercase quiet-line ruling at SYS-15's gate (SYS-07's OQ#8).
- **The countersign (duty, not OQ)** — SYS-28's countersign of TR-WME-008,
  carried from the SYS-09/SYS-10 batch to this authoring gate: **granted
  2026-11-15** — the requirements ratified verbatim (the three ban clauses +
  the epoch-invariant text rule); recorded in §Countersign below and in the
  lane report (the sync lane carries it to the SYS-10 index row).

**Proposed section plan** (the house GDD shape):

- Header/Status/Contracts · Overview · Player Fantasy
- Detailed Design — Core Rules: **13 TR-NAR** (the text-only law; the print
  voice; the micro-copy budget's class table; the beat data model + the text
  boundary; the variant-selector derivation; the MVP log allocation + L2
  under TR-WME-008; the Reading context ratification; the out-of-order
  no-spoiler law; the surfaces ledger with owners + failure paths; the
  not-do list; degenerate strategies; the VS session beats; the refusal
  display-copy mapping)
- States and Transitions (the Reading overlay FSM — deliberately two states;
  the variant derivation, not state; the beat lifecycle)
- Interactions with Other Systems (the boundary table)
- Formulas — **3 F-NAR** (variant_selector; line_budget; reading_estimate),
  each with variables/types/ranges, an Output clause, worked examples
- Edge Cases (If → outcome)
- Dependencies (+ the bidirectional-consistency corrections for the sync lane)
- Tuning Knobs (copy-side; SYS-02's validation law consumed)
- Visual/Audio Requirements (the text renders nothing; the overlay's visual
  law; the grief-tint adjacency; the photosensitivity consumption)
- UI Requirements (the copy law + the presentation law; geometry is SYS-24's)
- Acceptance Criteria — **15 ACs** (13 smoke = 8 LINT + 5 GUT; 0 device —
  the overlay legibility is SYS-24's device audit, carried; 2 MVP-lock
  playtest codes; 0 VS), counts printed and reproducible
- Open Questions — 5

**MVP authored copy (this lane's text deliverable)**: L1 default + L1 alt
(the out-of-order alternate state, keyed on `sanctum_log_read`), L2 (the
threshold log, epoch-invariant), the 16 refusal/save-failure display lines +
the recovery line. The memory texts (SYS-20), the terminal phrase and the
death fiction (SYS-15) are owned lanes' content under this GDD's laws.

**No user decision required** to proceed: no frozen contract is edited; the
countersign and the ratifications are consumptions. Two carried items land at
other lanes' gates (SYS-15's lowercase co-ruling; SYS-20's memory content) —
recorded, not blocking here.

— *Lane runner, SYS-28 (GLM), 2026-11-15*

## Countersign — SYS-28's TR-WME-008 ratification (the carried duty)

**GRANTED 2026-11-15.** SYS-28 ratifies SYS-10's telegraph-text requirements
(**TR-WME-008**) verbatim at this authoring gate, as the batch carried:

1. **The three ban clauses** — the L2 threshold log (and, by this GDD's
   generalization, every narrative beat) may never (i) inventory the tells,
   (ii) name their surfaces, (iii) confirm that the player noticed.
2. **The epoch-invariant text rule** — L2 is a single epoch-invariant
   authored text; no epoch-conditional variants.
3. **The allusion audit** — a named review item on SYS-28's L2 draft
   (SYS-28 + qa-lead); it runs at this GDD's review gate (§Three-seat review
   below records the result) with the mechanical greps (the epoch-invariance
   fixture + the boundary audit) automated in CI.

No amendment is made to TR-WME-008; nothing is added to SYS-10's contract.
This countersign closes the batch's carried item (SYS-10's Open Question 1
and the carried-obligations ledger). The systems-index sync request carries
the grant to SYS-10's row.

## 2026-11-15 — authoring checkpoint

- Authored `design/gdd/narrative-presentation.md` in full: 13 TR-NAR / 3
  F-NAR / 6 V-NAR / 15 ACs (13 smoke: 8 LINT + 5 GUT · 0 device · 2
  MVP-lock · 0 VS) / 5 OQs. The MVP copy authored: L1 (two states), L2, the
  17 refusal/save-failure/recovery display lines. Counts printed in the AC
  section's coverage line and the gate manifest.
- Cross-checked against `design/registry/entities.yaml` (read-only): no
  existing entry collides; the sync request (the report §) adds
  `narrative_beat_contract` (entities), `beat_variant_selector` (formulas),
  `micro_copy_budget` (constants).
- Ratifications recorded: SYS-05's close ≡ completion input ratified verbatim
  (TR-NAR-007); SYS-15's pre-shaped System Offline shape consumed
  (TR-NAR-009/013); TR-WME-008 countersigned (§Countersign above).
- **Authored copy re-verified mechanically**: all 26 authored lines ≤ 46
  chars (max 45); beat totals 91 / 107 / 117 chars; reading estimates
  8 / 9 / 10 s at the 12-cps floor — all inside the FIELD budget. The
  refusal rows: max 39 chars, single-line each.

## 2026-11-15 — gate phase opens

- **Fallback record (contract §3.6)**: the nested subagent tool is
  unavailable in this session (the harness exposes no Task/subagent spawn in
  the tool catalog; the `execute` code-mode catalog confirms — only
  MCP_DOCKER + opencode session tools). **Every seat pass is therefore run
  by the lane runner itself, in a separate pass, with the seat's neutral
  brief, and is recorded below.** No seat is skipped. The runner is GLM
  (the manifest model) — the creative/CD routing is honored; the
  technical/QA seats run under the documented fallback (the DS-only routing
  is a subagent-spawn property; the fallback pass is recorded as such, and
  the routing-rule's GLM→DS ban is not implicated — no DS model was
  invoked anywhere).

### CD gate — CD-GDD-ALIGN (the cd-gate brief, GLM; fallback pass 1)

- **Read**: the document in full; `game-concept.md` (the pillars, the
  anti-pillars, the MVP definition, the fantasy); the consumed contracts
  (TR-RWS-021/019/020/014/018 · TR-DR-007/008/010/014 · TR-WME-008 · the
  SYS-11 no-interface row · TR-SAV-020/022 · TR-HD-023 · the index row +
  the dependency map).
- **Check results**: pillar service — every mechanic names its pillar (the
  budget → Read-Then-Strike; the print voice → the diegetic doctrine; the
  no-spoiler law → D-6's tell contract; the refusal lines → Remade Every
  Death's honesty; L2 → the One-World-Two-Truths spine). Anti-pillar — no
  cutscene pattern introduced (the text-only law is the anti-pillar's
  enforcement); the reading budget is a copy lint, never a player-facing
  timer (no speed pressure). Player fantasy — the attributable death prose,
  the house's dramatization, the irony bookends contracted; no drift. Scope
  — MVP is honest: 2 logs, 17 display lines, 3 laws; the VS session copy is
  registered-but-absent (the SYS-03 namespace precedent), the device gate
  honestly 0 with the legibility carried to SYS-24. Contract alignment —
  TR-WME-008 countersigned verbatim; OQ-DR-1 ratified (SYS-05 keeps the
  amend right); the option rows verbatim; the codes stay API; SYS-11's
  no-text honored; the boundary audit's generalization is additive (SYS-02's
  audit untouched). Tone/voice — the registers closed, the print doctrine
  held, the copy passes the voice read.
- **Verdict: APPROVED** (0 blockers).
- **Recommendations (non-blocking, recorded)**: (1) print the envelope
  not-join explicitly in TR-NAR-001 (the SYS-02 precedent's wording) —
  applied in the repair pass; (2) name the telemetry rate-limit constant —
  applied in the repair pass; (3) one line in TR-NAR-006 recording why L1's
  flag-keyed alternate is legal under term 2 (the flag is the flip's
  trigger, the alt never references a tell) — applied in the repair pass.

### Three-seat review (fallback passes 2–4, run sequentially per §3.6)

**Seat 1 — creative (the creative brief; GLM; fallback pass 2)**

- **Check results**: fantasy delivery — the house's paperwork carries the
  "win by reading the world" fantasy; the budget is the discipline that
  keeps reading a room's flavor, not a chore; L2 is the payoff beat and the
  flip's trigger (the reading matters mechanically — via SYS-02's close
  edge, not the text). Legibility — the overlay is two states; the
  ARCHIVED stamp explains the variant change diegetically; the refusal
  lines are printable at a glance. Decision texture — no decisions from
  text by law (a presentation system's honest shape); the read/skip choice
  is free and untracked. Pacing/feel — the instant print matches the
  diagnostic frame (the anti-cutscene stance made sensory); no typewriter
  romance. Scope discipline — the MVP surface set is small and the VS
  content is explicitly absent. Pillar/anti-pillar — held. Narrative/world
  coherence — the registers are closed; the concept's diegetic doctrine
  (MEMORY CACHED as printed output, the sigil-red reservation, the death
  counter) is consumed, never contradicted.
- **Verdict: APPROVED** (0 blockers).
- **Recommendations (recorded)**: (1) the memory texts carry the Five
  Goodbyes burden at SYS-20 — the permutation fixture should re-run with
  the real rows at SYS-20's gate (already OQ-NAR-5; no change); (2) the
  death-cause row's copy law could name one worked format example at
  SYS-15's gate rather than here (ownership correct; no change).

**Seat 2 — technical (the technical brief; DS routing under fallback,
pass 3)**

- **Blockers found (3, all valid, repaired below)**:
  1. **TR-NAR-004's schema does not bind the keyed variant's id** —
     F-NAR-01 says "k's declared variant id" but the `NarrativeBeat` block
     only shows `variants {default, <keyed>}` with no field naming which
     variant is the keyed one; the copy section uses `post_threshold`, so
     the binding exists in prose but not in the data model. An implementer
     would guess. **Fix**: name the field (`keyed_variant_id`, present iff
     `selector_key ≠ none`, validated to resolve in `variants`) and make
     F-NAR-01 reference it.
  2. **AC-NAR-03's orphan-row check conflicts with AC-NAR-12** — the
     boot lint fails "a dangling row (no placement)" while the SESSION
     rows are intentionally registered-but-absent (no placement at MVP).
     As written the two fixtures contradict. **Fix**: scope the orphan
     check to FIELD/DEATH rows; SESSION rows are the recorded exception.
  3. **The AC-NAR-14/15 eligibility rule diverges from the house pattern**
     — the house rule (SYS-02's E1, AC-WME-13's preamble) is "fewer than 3
     eligible → the run is topped up", not merely "reports unevaluated".
     **Fix**: align the preamble wording (top up, then evaluate; never a
     pass by default).
- **Recommendations (one-line, non-gating, applied)**: (1) print the
  envelope not-join in TR-NAR-001 (the CD recommendation, same fix);
  (2) name the telemetry rate-limit constant (`NAR_TELEMETRY_RATE_LIMIT_MS`
  60000) in TR-NAR-001/V-NAR-01; (3) cite `TR-JCE-027`'s rate-limit
  pattern as the shape consumed — folded into (2)'s wording.
- **Counts re-derived**: 13 TR / 3 F / 6 V / 15 ACs; the partition sums
  13+0+2+0 = 15 ✓. Formula audit: variables typed+ranged, Output clauses,
  worked examples, the ceil honored, zero ms→tick conversions ✓.

**Seat 3 — QA (the qa brief; DS routing under fallback, pass 4)**

- **Blockers found (0 new beyond the technical seat's #3 — the eligibility
  rule is the same defect seen from the QA side; one blocker, counted
  once)**:
  1. **The eligibility preamble** (the technical seat's blocker 3; the
     top-up rule). Repaired below.
- **Check results**: AC coverage — every TR has ≥ 1 AC, every AC cites its
  TR(s), no orphan AC. Falsifiability — every AC has a GIVEN/WHEN/THEN with
  a countable assertion; the negatives are seeded (the violating row, the
  unmapped code, the row-less placement). Test types — [LINT] for greps, a
  [GUT] for fixtures, a [PLAYTEST] for the codes; no DEVICE AC exists; no
  pixel assertion in a GUT AC. Gate partition — 13+0+2+0 = 15, printed and
  reproducible. Boundaries — every edge case carries a fixture or a named
  playtest question; every missing-input path is tested (AC-NAR-09 + the
  surface table). Counts — reproduce. Placeholders — none: the deferred
  copy is registered-but-absent with its own lint (AC-NAR-12) and named
  owner gates (OQ-NAR-4/5), the SYS-03 namespace precedent. Playtest
  rubric — elicitors, tokens, thresholds, sample size, the unevaluated
  rules present.
- **Verdict: NEEDS REVISION** (1 blocker — shared with the technical seat's
  #3) → repaired below.
