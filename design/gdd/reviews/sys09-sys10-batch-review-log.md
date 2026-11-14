# SYS-09 + SYS-10 — Batch Co-Review Log (the Mechanism A pilot)

## The batch's structure

- **Documents**: SYS-09 `design/gdd/dual-reality-state.md` (landed, PR #41 — re-affirmed on this surface) + SYS-10 `design/gdd/world-mutation-epochs.md` (the document under review, authored this session).
- **Session**: S1-002b (SYS-10's authoring session, kickoff `production/session-state/sys10-kickoff-prompt.md`). Worktree `new-vania-sys10-world-mutation`, branch `docs/sys10-world-mutation` (from origin/Main `778b35d`).
- **Pre-review gates**: SYS-10's CD-GDD-ALIGN **CONCERNS** (4 findings, none REJECT-class) → **REVISED in-session** (C1 the language-law exemptions + two rewordings; C2 the positive permanence tokens coded; C3 the seam-vocabulary level note; C4 the OQ-DR-8 countersign routing).
- **Routing**: creative → GLM-5.3-Flash · technical/QA → deepseek-v4.1-flash-1017. All three seats are fresh sessions (no authoring context); each read both documents in full.
- **Baseline (frozen, pre-registered)**: 6 rounds / 2 elapsed days for the pair; pass ≤ 4 rounds / ≤ 1 day with zero escaped blockers — **the saving is a range, never banked**. Day 1 = 2026-11-14.
- **Scope signal**: SYS-10 — 11 TR-WME · 2 F-WME · 6 V-WME · 14 ACs (gate 12+0+2+0) · 2 playtest codes · 5 OQs; SYS-09 — 15 TR-DR · 7 F-DR · 7 V-DR · 27 ACs (gate 19+4+4+0). The planned World Mutation & Epochs ADR carries the mechanism decisions downstream.

## Review #1 — 2026-11-14 — Per-document verdicts

| Seat | SYS-10 (under review) | SYS-09 (re-affirmed) |
|---|---|---|
| **Creative** | **APPROVED** — 0 blocking / 4 recommended / 3 notes | **APPROVED** — 0 / 0 / 2 notes |
| **Technical** | **NEEDS REVISION** — 8 blocking / 10 recommended / 4 notes | **NEEDS REVISION** — 3 blocking / 4 recommended / 2 notes |
| **QA (qa-lead)** | **NEEDS REVISION** — 4 blocking / 4 recommended / 4 notes | **APPROVED** — 0 blocking / 1 recommended / 3 notes |

**SYS-09's qa-lead PASS line: ISSUABLE** (0 blocking; the counts, the gate manifest, and the four SYS-10-facing cross-references verify) — **one recorded condition: it does not survive a ratified session cap** without the AC-DR-08 same-session qualifier. **SYS-10's qa-lead PASS line: NOT issuable** — gates on WME-B1…B4 (+ the rider count if a fourth rider publishes).

### The seat lists

**CREATIVE (SYS-10 APPROVED · SYS-09 APPROVED re-affirmed).** Validated holds: the settlement fantasy is the mechanical home of the "one" in the spine pillar; the co-ownership carve honest (SYS-10 claims only the state half; "the noticing was SYS-09's moment; the quiet after is this system's"); term-2 composition (the three bans + the epoch-invariant text rule close the post-flip re-read channel); the scoping recorded as decisions with re-open conditions; the language registers compose at the seams. Findings — WME-CD-1 (rec) the phantom "G8" citation (SYS-09 publishes G1–G7 only) · WME-CD-2 (rec) the latched-resume vs session-cap composition unstated · WME-CD-3 (rec) the SotN pillar tie missing · WME-CD-4 (rec) the attribution-priming hazard in the shared session script · WME-CD-N1 (note) the D-4 map row stale in both dependency tables · WME-CD-N2 (note) RM-02/RM-04's `novelty_kind` inferable but unprinted · WME-CD-N3 (note) the SYS-28 countersign cannot be discharged at this surface (carried). SYS-09 notes: DR-CD-N1 the E1 row's Reading wording superseded on the load path (rider (iii); fold at the next touch — done this batch) · DR-CD-N2 the D-4 acknowledgment (same as N1).

**TECHNICAL (SYS-10 NEEDS REVISION · SYS-09 NEEDS REVISION — all three SYS-09 blockers are rider-landing-site gaps).** Validated holds (re-derived): F-WME-01's three worked examples; F-WME-02's three keys; the counts (11/2/6/14, gate 12+0+2+0); the single-store model consistent everywhere; the five per-state outcomes exhaustive; the closure check resolves; ordering law 1 matches E1 verbatim; the reconcile chain matches AC-DR-08; the tell-lint composition; OQ-DR-2 within the published delegation; the registry ↔ GDD values; TR-JCE-002's freeze-source half. SYS-10 blockers: B1/B1b the session cap (contradicts AC-DR-08/AC-WME-06(b)/TR-WME-010; unimplementable without a state the honesty clause strains) · B2 the resume's edge identity vs G2/G7 · B3 the phantom G8 · B4 the resume trigger undefined (the predicate's request-unacked term vs the acked-then-aborted path) · B5 no ClockPort · B6 "~0.5 s" vs `GLITCH_TAIL_MS` 120 [80,200] · B7 the load path can fire E1 inside LOADING (no context gate) · B8 RECONCILE(pending) assigns no state. Recommended: R1 the V-WME-05 law cite (law 5, not 4) · R2 the hardcoded `:= 1` vs `m.to_epoch` · R3 V-WME-05/06 uncited in AC-WME-04 · R4 SETTLED's exit false · R5 F-WME-01's output mapping incomplete · R6 presence-vs-reach noun alignment · R7 AC-WME-07's print order · R8 "no re-request" wording · R9 the replay-hash scope · R10 the punctuality invariant has no ADR home (a §5 rider). Notes: N1 the watchdog fires on legal play under the cap · N2 the registry's G8 · N3 the threshold table's consumed_by · N4 "unsatisfiable" overstates. SYS-09 blockers (batch-caused): B-S1 the "one/only failure exit" claims now false (rider (ii)) · B-S2 G2 vs the resume re-raise · B-S3 the save laws unconditional vs the cap. Recommended: R-S1 the stored-triple phrasing vs derived · R-S2 E1's literal Reading condition · R-S3 the tell table's kinds/refs unprinted · R-S4 the SYS-10 status stale. Notes: N-S1 (→ B6), N-S2 (→ R-S1 + the index).

**QA/qa-lead (SYS-10 NEEDS REVISION · SYS-09 APPROVED).** Verified clean: the coverage (all rules/formulas/invariants AC'd, no double-count within a document); the integration twins assert the fake-invisible half; the "SYS-10 mock contract" label resolves AC-DR-05; the reconciliation's five states + the read-scope audit executable; the V-WME-01/02/03 negatives enumerated; the gate manifest exactly-one; device-0 defensible with the carried round-trip obligation; the failure paths owned; the abstention fixtures real; no placeholders. SYS-10 blockers: WME-B1 the session cap (the same cluster as B1) · WME-B2 the "every V-WME conjunct" universal over-claims (V-WME-06 has no fixture) · WME-B3 no abort edge-trace AC · WME-B4 the priming ban vs the design-test utterance. Recommended: WME-R1 the G8 count-citation coupling · WME-R2 the RM-03 refs unprinted · WME-R3 the review-lint item inside a smoke AC · WME-R4 the permanence-probe discriminator unprinted. Notes: WME-N1 the AC order · WME-N2 the AC-WME-11 restatement · WME-N3 the ≥5 precondition inside AC-WME-13 · WME-N4 the test-line over-claim. SYS-09: DR-R1 (rec) the riders' landing edits not enumerated on SYS-09's text (the rider-landing checklist) · DR-N1 the derived-pending resolution recorded · DR-N2 the AC-DR-14/15 duplicate clause · DR-N3 the watchdog/reconciliation pair named.

### The recorded ledger items

- **C3 — the cross-document tells verdict: CONSISTENT, end-to-end.** SYS-09's authored allocation 1/1/2/1/1/0 (TR-DR-007 = registry `epoch0_tell_registry` = AC-DR-11's fixture) ↔ SYS-10's delta namespace (exactly three deltas; RM-03's two tells both trace `REVEAL_CISTERN.GATE_OPEN.rm03_partition`; `ZONE_MATERIALIZE.cold_corridor` and `INTERACT_EXPOSE.M4` deliberately tell-free — the gate tell's same-room visible payoff, satisfying term 2's same-room traceability without violating the anti-saturation law) ↔ the telegraph-text requirements (TR-DR-010's binding ≡ TR-WME-008's three bans + the epoch-invariant rule). The two traceability levels (room-novelty→tell bidirectional; ref→delta one-directional) compose exactly as documented. No ungoverned tell surface; neither half claims the other's.
- **SYS-03's five source families (the ledger item): VERIFIED.** The reconciliation contract consumes exactly `truth_flags` + `truth_epoch` (the read-scope audit makes it mechanical — AC-WME-06); no sixth family; SYS-03's serialization surface unchanged; the absent-key default and the out-of-range hand-off published contract-first; the real-file round-trip twin carried to SYS-03's authoring gate.
- **SYS-04's IP-7 edge (the ledger item): VERIFIED with one fix.** E3b `ambient_shift` is SYS-10's emission pinned to `epoch_swap`'s tick with the receding-first composition; the abort case named (the bed stays put); the "~0.5 s" post-abort figure was defective (B6) and is re-anchored to SYS-09's `GLITCH_TAIL_MS` with SYS-29's conversion family — SYS-04's composition surface is unchanged by the fix.

## Review #1 — Resolution record (2026-11-14, in-session) — the worklist

**User decisions at the resolution:** the **session cap withdrawn** (the seats' convergence — the re-fire stays bounded by G2/E4's derived single-shot per save lifetime; SYS-09's AC-DR-08 untouched); the **full repair pass approved** (blockers + accepted recommendations + notes).

| # | Finding | Resolution |
|---|---|---|
| 1 | B1/B1b/WME-B1/B-S3 (the session cap) | **Withdrawn** — law 2 now reads "one epoch store per save lifetime; the deferral-gap re-fire is the same logical flip completing"; TR-WME-010's save-scumming entry rewritten honestly (nearly unreachable at MVP; only a state-(b) save re-fires; the story's own replay); the registry's cap note removed; SYS-09's save laws untouched (the condition on SYS-09's PASS dissolves) |
| 2 | B3/WME-R1/WME-CD-1/N2 (the phantom G8) | **Repointed** (not minted — no rider-count change): TR-WME-004/006, TR-WME-010, the edge case, and the registry now cite "the same-logical-flip doctrine — SYS-09's G2 + the deferral-gap edge case / AC-DR-08" |
| 3 | B2/B-S2 (the resume's edge identity) | Rider (i) expanded: **the resume re-runs the E1–E7 sequence for the same logical flip — E1 re-fires at R′; G2's "exactly once" reads per landed flip; G7's fire-once reads per run**; SYS-09's G2 and G7 gain the one-clause amendments (the rider-landing edits) |
| 4 | B-S1 (the failure-exit claims) | SYS-09's transition laws 3–4 amended: the failure exits named (the extension cap's + the commit-abort's — rider (ii)) |
| 5 | B4 (the predicate's abort term) | TR-WME-003's standing-request predicate: `pending ∧ ¬settled ∧ ¬awaiting-τ0 ∧ tail-cleared ∧ no operation in flight` (the unacked path re-emits directly; the acked-then-aborted path re-enters) |
| 6 | B5 (no ClockPort) | `ClockPort` added to TR-WME-001's port list (read: the wall tick + the elapsed-ms stamp — SYS-29's publication through SYS-09's contract) |
| 7 | B6 (the ~0.5 s figure) | The post-abort wait re-anchored to SYS-09's `GLITCH_TAIL_MS` with SYS-29's `freeze_ticks` conversion family, consumed — the 0.5 s figure deleted; SYS-10 still converts no ms→ticks |
| 8 | B7/WME-B4-adjacent/R-S2 (the LOADING-context gate) | Rider (iii) expanded: E1's eligibility = request-presence **∧ the GAMEPLAY context gate** (SYS-05's gate; ADR-0001 §3's law); SYS-09's E1 row amended ("a flip request is present … AND the context is GAMEPLAY"; the Reading close preserved as the fresh-path instance) |
| 9 | B8 (RECONCILE's state) | RECONCILE(pending) → **IDLE** (the request pending; observed at the first post-load GAMEPLAY tick); IDLE's entry cell covers the load-reconcile-with-pending path |
| 10 | WME-B2 (the V-WME universal) | AC-WME-02 reworded to "every V-WME-01/02/03 conjunct" + **V-WME-06's negative added** (a throw across the signal boundary fails the seam test) |
| 11 | WME-B3 (the abort edge-trace) | AC-WME-04 gains the **abort edge-trace fixture** (the rider (ii) observable: `freeze_open` fired; E3/E3b/E4/E5/E7 absent; `freeze_close` at the force-release boundary; the latched park; one assert + one telemetry; the resume as a fresh-source raise) |
| 12 | WME-B4 (the priming collision) | The preamble reworked: the ban scopes to the *coded probes*; the design-test utterance **exempted by name and pinned after SYS-09's AC-DR-26 protocol completes**; its answer stays a separate scored datum |
| 13 | R1 (the law cite) | V-WME-05's why-cell → "SYS-10's transition law 5 (SYS-09's transition law 4 is the render-side face)"; TR-WME-004's cite disambiguated |
| 14 | R2 | The store generalised: `truth_epoch := m.to_epoch` (1 at MVP) |
| 15 | R3 | AC-WME-04's cite gains V-WME-05/06 |
| 16 | R4 | SETTLED's exit corrected (a load re-enters RECONCILE → SETTLED or IDLE per the derived pending) |
| 17 | R5 | F-WME-01's Output Range prints the full five-way mapping with (e) as abort-before-predicate |
| 18 | R6 | The presence/reach noun alignment recorded in TR-WME-002 (SYS-09's G1 "presence" = the render side; SYS-10's "reach" = the mechanics side; one effect, two faces) |
| 19 | R7 (the AC print order) | **Accepted, no edit** — the AC-DR-27 precedent covers the out-of-order print (SYS-09's own AC set does it) |
| 20 | R8 | "no re-request from a failed sequencer" → "no new request is minted from the failed handshake; the standing predicate's re-emission is the repair" |
| 21 | R9 | The latched-resume fixture's hash scoped to the post-resume choreography (the abort's force-release prefix is the declared offset) |
| 22 | R10 (the ADR §5 home) | The invariant recorded as SYS-10-published; **the ADR-0001 §5 rider (naming the boundary phase) rides the planned World Mutation ADR** (the OQ-M1 pattern) — recorded in the Dependencies row |
| 23 | R-S1 (+N-S2) | SYS-09's three save-law sites amended: `{epoch A, flag set}` with the derived-pending note (SYS-10's OQ-DR-2 answer); the systems-index contradiction dissolves |
| 24 | R-S3 (+WME-CD-N2/WME-R2) | SYS-09's tell table prints the kinds + refs for all five rows (RM-02/RM-04 = `RE_READING`; RM-03's two = `STATE_DELTA` → `REVEAL_CISTERN.GATE_OPEN.rm03_partition`); SYS-10's AC-WME-08 prints the ref inline |
| 25 | R-S4 | SYS-09's Contracts line + Dependencies row + Interactions row sync to SYS-10's In-Design status + the riders |
| 26 | DR-N2 | AC-DR-15's duplicate V-DR-06 clause removed (kept on AC-DR-14) |
| 27 | WME-R3 | The allusion audit re-homed: a named review item on SYS-28's draft (SYS-28 + qa-lead); the smoke AC keeps the two mechanical fixtures |
| 28 | WME-R4 | The permanence-probe discriminator printed (interrogative/uncertainty = probe; declarative past-tense = accept) |
| 29 | WME-N3 | The ≥5-eligible precondition printed inside AC-WME-13 |
| 30 | WME-N4 | TR-WME-010's test line cites the cross-referenced homes (AC-DR-17/AC-RWS-09; AC-WME-02) |
| 31 | WME-CD-2 | **Dissolved** by the cap's withdrawal (no composition clause needed) |
| 32 | WME-CD-3 | The SotN pillar tie added to SYS-10's pillar-ties line |
| 33 | WME-CD-4 | AC-WME-14's collection channel pinned (unprompted callouts + the neutral debrief; the design-test answers excluded) |
| 34 | WME-CD-N1/DR-CD-N2 | The D-4 acknowledgment added to SYS-10's SYS-25 dependency row |
| 35 | N3 (the registry's consumed_by) | SYS-02 dropped from `mutation_threshold_table.consumed_by` |
| 36 | N4 | "unsatisfiable otherwise" → "otherwise E1 shifts a tick and the determinism fixture breaks" |
| 37 | WME-N1 | **Dissolved** by the cap's withdrawal (no watchdog-on-legal-play) |
| 38 | DR-N3 | Recorded, no action (the watchdog/reconciliation pair named in SYS-10's Tuning Knobs) |

## The riders' record (the batch's contract publication)

The **three riders** are published as contract ADDITIONS on SYS-09's landed text (the G7-sanctioned path — recorded here, never silent), with the rider-landing edits applied to SYS-09's document in this batch:

- **(i) The latched-resume state + resume intake** — the resume re-runs the E1–E7 sequence for the same logical flip (E1 re-fires at R′; G2 reads per landed flip; G7 reads per run). SYS-09 sites: G2, G7.
- **(ii) The commit-abort failure family** — a second force-release trigger joining the extension cap's, owned by SYS-09's sequencer on SYS-10's `aborted` outcome; the success edges never fire; `freeze_close` derives at the force-release boundary. SYS-09 sites: transition laws 3–4.
- **(iii) The E1 eligibility = request-presence ∧ the GAMEPLAY context gate** — the Reading-close wording preserved as the fresh-path instance. SYS-09 site: the E1 row.

**Countersigns (this batch's duties):** SYS-01's owner + technical-director for OQ-DR-7 (iv) (the freeze-scoped discard rider) · SYS-29's owner for (v) (the extension-raise contract) · game-designer for the OQ-DR-8 ruling · SYS-28 for TR-WME-008 (**CARRIED to SYS-28's authoring gate** — no SYS-28 seat exists on this pilot; WME-CD-N3). The countersign results are recorded below when they return.

## Spot-checks and re-verification

### The mandatory spot-check #1 (deepseek qa-lead) on the 38-row repair pass — **FAIL (4 blockers, all residue) → all fixed**

- **33/38 APPLIED-CORRECTLY**; 2 NOT-FOUND (the deferral-gap edge case's G8 cite; the abort edge case's ~0.5 s figure), 1 MISAPPLIED (SYS-09's Interactions SYS-03 row still carried the stored `pending-flip` triple), 2 NEW-DAMAGE (AC-WME-11 still carried the withdrawn cap whole, plus row 37's watchdog clause). The recomputations all verified (the counts both sides; F-WME-01's five-way output mapping; the rider texts' agreement across the documents).
- **All 4 blockers + 5 advisories fixed in-session** (9 edits): AC-WME-11's repeat-load fixture (the cap text replaced whole); SYS-09's Interactions SYS-03 row (`{epoch A, flag set}` + the derived-pending note); the abort edge case (`GLITCH_TAIL_MS` + the same-logical-flip second-run semantics); the G8 cite repointed; SETTLED's row (the session-scope residue + the corrected exit); AC-WME-02's cite gains V-WME-06; the threshold table's `consumed_by` (SYS-02 as a validation source, not a consumer); OQ-1's SYS-28-carried correction (the "all resolved" claim fixed); the systems-index SYS-10 row's cap clause replaced with the withdrawn-cap record.

### Micro spot-check #2 (deepseek qa-lead, the 9-edit fix-up delta) — **all 9 APPLIED-CORRECTLY; 1 residual blocker → fixed**

- The sweep: the withdrawn-cap residue **CLEAN** across all four files; riders (i)/(iii) agree across the documents. **DR-B1**: SYS-09's TR-DR-005 invariants still claimed "the single documented failure exit" (the repair row 4 had scoped to transition laws 3–4; the invariants sentence inside TR-DR-005 was untouched) → fixed (both failure exits named; the success-path qualifier intact). Two non-blocking observations applied as courtesy edits (SYS-09's OQ-DR-2 row marked **RESOLVED** — derived at load, no field; the LATCHED-PARKED rider-(i) state note added after the states laws).

### Micro spot-check #3 (deepseek qa-lead, the 3-edit delta) — **PASS**

- 3/3 APPLIED-CORRECTLY (the TR-DR-005 invariants' full-line extract verified — "single documented failure exit" 0 occurrences file-wide; the OQ-DR-2 row; the LATCHED-PARKED note consistent with G2/rider (ii)); the counts reproduce both sides; no new blocker. **Advisory A1 (non-blocking, recorded):** LATCHED-PARKED is declared in prose, not as a States-table row — a one-row addition at the next full pass (a failure-path-only state; not a gate item).

### Fresh-seat re-verification

*(pending)*
