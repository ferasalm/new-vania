# SYS-07 Baseline Rework — review log (the IP-17 contract-revision package, ROUND 2)

> **Document under review**: `design/reviews/sys07-baseline-rework-package.md` (the
> proposal; **no frozen document was edited by the proposal itself**; the approved
> revision was applied afterwards — see § 6.2 for the applied file set and § 7 for the
> applied-diff gates).
> **Lane**: SYS-07-REWORK · **Branch**: `docs/sys07-baseline-rework` · **Round**: 2
> **Decision**: D-ORCH-03 (round 2 requested 2026-11-15; the user's approval is the
> final gate — this log records the *agent* gates, not the decision).
> **Seat routing**: CD gate → `@cf/zai-org/glm-5.3-flash`; technical seat and the
> diff-scoped micro-checks → `@cf/deepseek-ai/deepseek-v4.1-flash-1017`. Every seat ran
> as a **nested subagent** with the neutral brief and its model passed explicitly
> (§ 3.6 of `prompts/lane-runner.md`; no in-session fallback was used).

## 1. Gate trail — the verdicts

| Gate | Pass | Verdict | Blockers | Disposition |
|---|---|---|---|---|
| **CD-GDD-ALIGN** | 1 | **CONCERNS** | 2 | both repaired (§ 2.1) |
| **CD-GDD-ALIGN** | 2 (fresh seat) | **APPROVED** | 0 | — |
| **Technical seat** | 1 | NEEDS REVISION | 13 | all repaired |
| **Technical seat** | 2 | NEEDS REVISION | 9 | all repaired |
| **Technical seat** | 3 | NEEDS REVISION | 9 | all repaired |
| **Technical seat** | 4 | NEEDS REVISION | 5 | all repaired |
| **Technical seat** | 5 | NEEDS REVISION | 5 | all repaired |
| **Technical seat** | 6 | NEEDS REVISION | 3 | all repaired |
| **Technical seat** | 7 | NEEDS REVISION | 5 | all repaired |
| **Technical seat** | 8 | NEEDS REVISION | 5 | all repaired |
| **Technical seat** | 9 | NEEDS REVISION | 3 | all repaired |
| **Technical seat** | 10 | NEEDS REVISION | 3 | all repaired |
| **Micro-check** (diff-scoped) | 1 | FAIL | 5 | all repaired |
| **Micro-check** (diff-scoped) | 2 | FAIL | 2 | all repaired |
| **Micro-check** (diff-scoped) | 3 (final) | see § 4 | — | the two residual wording contradictions repaired after the verdict |

**The honest summary**: the CD gate closed at APPROVED on the second pass. The technical
seat never returned a clean pass — **every one of its ten passes found real defects, and
every one was repaired** — but the defects narrowed monotonically from structural(the dispatch, the schema, the ladder's validation) to naming and consistency
(a duplicated term, a stale cell, a clamp's scope). **The arithmetic core was verified
green in every pass from #4 onward**: the ladder's columns and chain, the counter's five
values, F-HD-03's taken values, the TTK envelope, the identity law at 0 gear/0 points,
and the § 1 invariants.

**Why the loop was long, recorded candidly**: round 1 was rejected without recorded
objections, so round 2 could not diff against it. The reconstruction (recorded in the
package's § 2) was therefore authored from the frozen GDD, and the seat had to
re-derive an entire economy from scratch — which is exactly the work IP-17 asks for, and
exactly where a single agent's arithmetic drifts. The seat's ten passes are the price of
that reconstruction, and the log keeps every blocker so the application run inherits the
findings rather than re-discovering them.

## 2. CD gate

### 2.1 Pass 1 — CONCERNS (2 blockers)

| # | Blocker | Disposition |
|---|---|---|
| 1 | The Player Fantasy **anchor moments and the success signature** carry frozen absolute numbers and were missing from the diff; applying § 8 as written would leave the fantasy contradicting the tables in the same commit. | **Repaired** — three anchor moments + the signature added as a diff row, with **prose re-derived, not number-swapped** (*"a little more than a tenth"* becomes *exactly* a tenth at 2/20). |
| 2 | **Axis P's rationale had the rounding sign inverted**: rounding 1.2→1 and 2.4→2 makes the light/mid strikes *relatively lighter*, not heavier — so the user was being asked to decide on a false trade. | **Repaired** — § 4.1 now states the correct consequence (chip is more survivable: 20 hits vs 16.7) and the real trade (**the spread widens 1:2:3.33 → 1:2:4**, heavies relatively heavier). This was the most valuable single catch of the whole trail: it was a *user-facing* misstatement. |

### 2.2 Pass 2 — APPROVED (0 blockers, 5 recommendations)

Recommendations applied: the OQ widened to the HP axis; SYS-14 checked (no rider needed —
its GDD is unwritten); the Gate-2 probe routed through the sync request so
game-concept's four-probe list stays single-sourced; Option A's "fully coherent" reworded
to name the SYS-16 residual; § 2 reconciled with § 1's six-row table; a unit typo fixed.

## 3. Technical seat — the blockers, by class

Every blocker is listed in the pass's own words in the seat transcripts; this table keeps
the *class* and the repair, so the application run can check the outcome rather than the
prose.

| Class | Examples (pass) | Repair |
|---|---|---|
| **Arithmetic** | F-HD-03's DEF rows at raw 1/2/4 (1/1/3, not 1/2/3 — pass 1); the ladder's counter columns vs F-HD-11's body (1); the single-arc step is +50%, not +36.7% (2); the knob-row split is 12 rows / 18 symbols (4, 9) | Corrected; the **DEF collapse** became R10 (any `defense ≥ 1` ≡ DEF 25 — a D-1 input) |
| **Schema / dispatch** | the ladder had no column selector (2); `AttackContext` alone could not carry it — `DamageEvent` needed the arc (5); `COUNTER` resolved through the ladder *and* F-HD-11 (6); `ENEMY_STRIKE`/`ENVIRONMENT` were routed into the *dealt* law, destroying F-HD-03's `taken` path (6); `arc = ABILITY` had no producer and no cell for D-3's Stinger (7); `StatBlock.damage_bonus` had no carrier (10) | The **seven-branch total dispatch** (§ 3.1), the pre-dispatch `arc = NONE` rejection, `DamageEvent.arc`, `StatBlock.damage_bonus`, and the module stage (branch 2 only) |
| **Completeness** | SYS-08's knob **safe ranges** would clamp 2/4/2/2 back to 6/14/5/6 (1); `spitter_orb_damage` omitted (1); the TTK envelope asserted rather than derived (1); the duplicated schema copies — the header Contracts line, TR-HD-016, the Dependencies cell (7, 8); the `## Overview`'s fourth copy of the order (9); the VS `hp_max` left on the old scale (7) | All added to § 8's clause rows; the **sweep + exclusion set** published as the completeness test |
| **Downstream staleness** | SYS-13's TR-ENM-005/V-HD-06/the counter ceiling (2); SYS-04's AC-AUD-08 fixtures (3); SYS-29's AC-JCE-18 ratios (3); SYS-02's F-RWS-05/AC-RWS-14 *"100 at the default profile"* (4); SYS-13's orb across TR-ENM-011/F-ENM-07/TR-ENM-024/AC-ENM-18 (5); `enemy_archetype_roster` + `enemy_stagger_ms` + `enemy_strike_contract` in the registry (3, 8, 10) | § 9's rider table and § 10's registry set — **nine riders + nine registry updates** |
| **Validation** | the ladder's row-0 tautology (8); the live-edit resolution stated as both "rejected" and "clamped" (9); the clamp unable to resolve an ATK1 column and able to create an ATK2 violation (10); the boot-vs-live split (10) | **V-HD-12's four checks with the split case resolution** (reject for row-0/row-4/ATK1-crouch-air; clamp-and-revalidate for ATK2/chain) |
| **User-facing honesty** | the package claimed a "one clause" SYS-08 revision when two were needed (5); the gear layer had no transport for a build modifier (8) | § 1's component table now says **two clauses**; the module stage + `StatBlock.damage_bonus` give D-1 a lever |

## 4. Micro-checks (diff-scoped)

- **#1 — FAIL (5)**: the "Not touched" `StatBlock` line; the dropped module terms still
  live in three sites; the term typed as a constant rather than a field; the row-4 pin
  absent from V-HD-12; the extreme-cells row's completeness claim exceeding its
  enumeration. All repaired.
- **#2 — FAIL (2)**: § 3.1 and AC-HD-13 still stated the *generic* clamp that V-HD-12 had
  just scoped. **Repaired after the verdict** (both now mirror V-HD-12's case split).
- **#3 (final) — the confirming checks passed**: items 1, 2, 4, 5 verified clean in
  isolation, no dropped term survives, `StatBlock.damage_bonus` is the single name, and
  **the identity law holds exactly at 0 gear/0 points** (`max(1, dealt + 0) = dealt`,
  `dealt ≥ 2` in branch 2, so the floor never bites). The verdict still returned the two
  § 3.1/AC-HD-13 wording contradictions, which were then repaired.

**Trail state recorded honestly**: the final repair batch (the two wording
contradictions) was applied after the last micro-check verdict and was **not** re-verified
by a further pass. It is a text-only alignment of two sentences to a rule already
verified (V-HD-12's scoped clamp). The **applied-diff review** (§ 13.5 of the package)
is the diff-scoped close for the real edit, and it must re-run these two fixtures.

## 5. Arithmetic appendix (so a spot-check needs only this log)

Every value the package prints, with its derivation from the frozen GDD's own numbers:

| Value | Derivation | Result |
|---|---|---|
| player pool | 100 ÷ 5 | **20** |
| strikes | 6/12/20 ÷ 5, integers | **1 / 2 / 4** |
| weapon table | 10/20/8/10 ÷ 5, integers | **2 / 4 / 2 / 2** |
| counter raw | `floor(move × 1.5)` | **3 / 6** |
| counter dealt (5 steps) | `max(1, ceil(raw × attack ÷ 100))` at 100/108/116/124/132 | **3/4/4/4/4** and **6/7/7/8/8** |
| tiers | 30/60/120/300 ÷ 5 | **6 / 12 / 24 / 60** |
| chain | 2 + 4 | **6** |
| `dps_chain` | 6 × 60 ÷ 37 | **9.73** |
| 60 s integral | `floor(3600 ÷ 37)` = 97 chains × 6 + one ATK1 (2) | **584** |
| single-arc loop | 2 × 60 ÷ 22 | **5.45** |
| TTK | `ceil(tier ÷ 6)` chains × 37 ÷ 60 | **1/2/4/10 chains · 0.617/1.233/2.467/6.167 s** |
| hits-to-kill | arc hits per chain-kill | **2 / 4 / 8 / 20** |
| TTK envelope | chain 4 (knob min) → 10 (ladder row 4) | **T1 1–2 · T2 2–3 · T3 3–6 · boss 6–15** |
| taken at DEF 0/5/25, raw 1/2/4 | `max(1, floor(raw × (100−def) ÷ 100))` | **1/2/4 · 1/1/3 · 1/1/3** |
| taken, out-of-band | raw 20 at DEF 5 / 25 | **19 / 15** |
| heal | 25 ÷ 5 | **5** (at 18/20 → 2 applied, 3 discarded) |
| revive | `ceil(28 × 0.5)` | **14** |
| thresholds | 100/250/450/700 ÷ 5 | **20 / 50 / 90 / 140** |
| awards | 15/35/70/200 ÷ 5 | **3 / 7 / 14 / 40** |
| L2 grind | 7 T1 kills | **21 ≥ 20** (unchanged in kills) |
| `hp_ratio` fixtures | 5/20, 6/20, 7/28 | low · not · low (0.25 inclusive) |
| pit ratio | 8/20 → overkill 12 | **0.60 MID** (the frozen 40/100 mirror); 7/20 → **0.65 HIGH** |
| ladder boss chains | `ceil(60 ÷ chain)` | **10/9/8/7/6** |
| Elegy's ÷5 image | 5/7/4/5 → chain 12 → 10.43 | **+7.2% preserved** |
| knob rows | 12 changed (18 symbols) + 1 reclassified + 1 new + 19 unchanged | **33** (was 32) |
| parity band | 584 ± 10% | **[526, 642]** |
| one chain step | 1 ÷ 6 | **+16.7%** (one ATK1 step: +50%) |

## 6. The user approval and the applied-diff verification (2026-11-15)

### 6.1 The decision

**D-ORCH-03 — APPROVED (option A), recorded 2026-11-15** by the user (the ledger entry
lands on the orchestrator side; this lane names the ID in every commit). The approval
covers the full revised package exactly as presented — the ÷5 rescale (20 HP · strikes
1/2/4 · the weapon table 2/4/2/2 + `DamageEvent.arc`), the SYS-08 co-revision, the
5-step growth ladder, the three `TR-HD-006` gear riders, the mana-free Stinger (M1),
and the parity restatement. **No component swaps.** Both named consequences were
accepted: DEF is decorative for gear (a SYS-16 input, R10) and the L5→L6 handoff is
OQ#20's (R11).

### 6.2 What was applied

| File | Commit | Content |
|---|---|---|
| `design/gdd/health-damage.md` | the SYS-07 revision commit | § 8's full clause inventory: the header (Status/Last Verified/Counts/Contracts), the Player Fantasy (term 4 + the three anchor moments + the success signature, **prose re-derived**), the Overview's six-stage pipeline, TR-HD-003/005/006/007/008/009/010/011/016/021/029/030/033/034/035/037/039, F-HD-01/02/03/06/07/08/09/10/11/13/14 (+ the ledger rows), V-HD-07/12/13/14, the edge cases, the 12 changed knob rows + `ATK_PER_POINT` reclassified + the new `DAMAGE_LADDER_MVP` row, the cross-system inputs, the Interactions cell, the Dependencies rows/bullets, 19 ACs, OQ#5/#6/#10/#13/#14, and the new OQ#20 |
| `design/gdd/combat.md` | the SYS-08 co-revision commit | TR-CMB-004 (the damage column + the re-derived safe ranges), TR-CMB-010, TR-CMB-015, **TR-CMB-025 (`DamageEvent.arc` + the stamping rule)**, F-CMB-06 (the input band **1–4**, the outputs 3/6 with the range 1–8), F-CMB-10's example, the four damage knobs, AC-CMB-12, AC-CMB-17, AC-CMB-30, **the header's D-ORCH-03 declaration**, **the SYS-07 dependency row's status**, and **the SYS-12 status (MVP — D-3; mana-free) + the ABILITY stamper** (the applied-diff review's repairs, § 7) |
| `design/gdd/reviews/sys07-rework-review-log.md` | this commit | this section |

**Not applied, with the reason recorded** (a deliberate, reported deviation from the
package's § 13.2): the **SYS-13 orb value (8 → 2)**. The orb is entangled across five
sites in `enemy-ai-telegraphs.md` — TR-ENM-011's own clause (the value *and* the
"8 sits between P1 6 and P2 12" relation *and* the "band 1 says light" justification),
F-ENM-07's example ("it kills the Spitter for 8"), the "farms orb-deflects" edge
bullet, AC-ENM-18 (the deflected-orb kill), and TR-ENM-005's hp/award roster. A
value-only edit would leave "damage: 2" beside "8 damage sits between P1 6 and P2 12"
in the same sentence — worse than none. **SYS-13's rider must land as one coordinated
doc touch** (§ 9's row): hp 6/12/24, awards 3/7/14, the orb 2, the flash band, the
ceiling 12/18, V-HD-06's `6 < 12 < 24`, and the one-shot claim re-decided. Until it
lands, the registry sync must **not** flip `spitter_orb_damage` (recorded in the lane
report's sync request).

### 6.3 The applied-diff verification (the two flagged fixtures)

The package's final two repairs were applied after the last micro-check and were
**explicitly unverified**; the lane re-ran them on the *applied* text, as the user
required.

**Fixture 2 — AC-HD-13's fixture set vs the applied formulas: PASS.** Re-derived
independently: the ladder's 5×4 table matches the AC column for column; `step()` maps
100/108/116/124/132 → 0–4; the counters reproduce (ATK1 3/4/4/4/4, ATK2 6/7/7/8/8 under
`max(1, ceil(floor(ATK.damage × 1.5) × attack ÷ 100))`); the ABILITY fixture (raw 3 →
ceil(3.96) = **4** at 132) and the DEFLECT fixture (raw 2 → ceil(2.64) = **3** at 132)
hold; the six-stage order string is identical in the AC, TR-HD-005's body and the
Overview; the module stage is identity at 0 modules; the gate partition is
42+3+5+0 = 50 and the counts are 39/15/50/68/**20**.

**Fixture 1 — the live-edit case split: FAIL → repaired → PASS.** The first run found
three real defects in the applied text: (i) F-HD-14's validation sentence stated the
four checks but **not** the load-vs-live split; (ii) the generic **Knob validation law
(V-HD)** — printed twice — still resolved *every* live edit by "clamp + telemetry",
contradicting V-HD-12's reject cases; (iii) AC-HD-13's ATK2 clause omitted the clamp's
direction/magnitude and the residual-violation outcome. All three were repaired: the
split now appears identically in F-HD-14, the V-HD-12 row and AC-HD-13, and both
generic-law copies defer explicitly (*"Except where a specific invariant names a
different resolution: V-HD-12's ladder cases reject … the generic law's 'clamp' is the
default, not a universal"*). The re-run returned **PASS** with zero blockers across all
four sites.

**The header claim is therefore true**: `health-damage.md`'s *"re-verified 2026-11-15
by the applied-diff check (D-ORCH-03)"* stands on the two checks above — and on nothing
more. **The full applied-diff review is owed at this stage** — and was then run and
closed: see **§ 7** (CD APPROVED · technical repaired · qa-lead PASS 7/7 · micro-check
PASS). This paragraph records the status as it stood when the fixtures closed, not the
current one.

### 6.4 The counts after application

39 TR-HD · 15 formulas · 50 ACs · 68 edge bullets · **20 OQ rows** · 15 V-HD ·
**33 knob rows** · gate manifest 42 + 3 + 5 + 0 = 50. The added OQ is #20; the added
knob row is `DAMAGE_LADDER_MVP`; no TR and no AC was added or removed.

## 7. The applied-diff review (the post-application gates, 2026-11-15)

The package's gates (§ 2–§ 4) covered the *proposal*. This section covers the **applied
text** — the two frozen documents as edited — per the lane-runner contract § 3. Every
seat ran as a nested subagent with its model passed explicitly.

| Gate | Pass | Verdict | Disposition |
|---|---|---|---|
| **CD-GDD-ALIGN** (applied) | 1 | **CONCERNS** — 1 blocker | repaired (the `combat.md` header + the SYS-07 dependency row did not declare the co-revision) |
| **CD-GDD-ALIGN** (applied) | 2 | **APPROVED** — 0 blockers, 6 recommendations | closed |
| **Technical seat** (applied) | 1 | **NEEDS REVISION** — 6 blockers | 4 repaired, 2 rebutted (§ 7.2) |
| **Technical seat** (applied) | 2 | **NEEDS REVISION** — 5 blockers | 3 repaired, 2 rebutted (§ 7.3) |
| **qa-lead spot-check** (repair diff) | 1 | **FAIL** — 6 defects | all repaired |
| **qa-lead spot-check** (repair diff) | 2 | **PASS (7/7)** | closed |
| **Final micro-check** (diff-scoped) | 1 | **PASS** — zero blockers | closed |

### 7.1 What the applied-diff review changed

**`combat.md`**: the header now declares the D-ORCH-03 co-revision (values, `arc`, the
SYS-12 status, F-CMB-06's band) and points at this log; the SYS-07 dependency row reads
*"APPROVED 2026-11-12 + the D-ORCH-03 baseline"* (it said *"GDD not written —
PROVISIONAL"*); F-CMB-06's input band is **1–4** (the union of the four re-derived safe
ranges — at `ATK2_DAMAGE` 6 the counter is 9, outside the printed 1–4) with the output
range 1–9; **the SYS-12 status is MVP (D-3), mana-free (M1)**, with Combat named as the
ABILITY arc's publisher and SYS-12 the ability's `raw_damage` owner; AC-CMB-30 gains the
ABILITY fixture; the gate table's VS parenthetical now scopes to *"the Stinger's clash
interaction"*; OQ#9 is scoped the same way.

**`health-damage.md`**: the Interactions `DamageEvent` cell and the Dependencies SYS-08
row print the **six-field** event (they still printed five); TR-HD-037's
`AttackContext` and TR-HD-035's `StatRevision` carry **`damage_bonus`** (the resolver was
not self-contained without it — `StatBlock` is not an input); F-HD-02 branch 2 reads
`attack_context.damage_bonus`; **term 10** (TR-HD-017 and F-HD-15) is the **immune-kind
predicate only** — the cap and the floor are clamps in F-HD-04, and the floor's release
lives in F-HD-05's edge, so an over-cap hit applies capped (AC-HD-23) instead of being
rejected; F-HD-03's range reads **0–25 at MVP / 0–40 at VS** with the Variables line
stating the input domain vs the clamp; TR-HD-008's energy fixture matches AC-HD-08
verbatim (**45 → 50 at L1**, 85 → 90 at L5 — the old 50 → 55 was impossible at the cap);
F-HD-02's pre-dispatch is an event-level rejection (the "last good config" rule belongs
to V-HD); the `ATK_PER_POINT` gloss no longer claims a VS shared step; the cross-system
inputs mark the registry values as pending the sync; `Last Updated` is 2026-11-15.

### 7.2 The rebuttals (recorded, never a silent skip)

- **TR-HD-030's charge-spend timing** (the commit says *"the charge is spent on the
  commit"* while the body-wait path can expire — so an expiry may or may not refund).
  **Rebutted as pre-existing and out of this revision's scope**: the sentence is
  unchanged from the 2026-11-12 approval, the revision touches nothing in TR-HD-030, and
  the repair is a *behavioural* choice (when the charge is spent) that a contract
  revision should not smuggle in. **Carried**: owner SYS-07 + SYS-01, trigger *before
  the first heal story*; the candidate resolution (spend at application; an expiry spends
  nothing, preserving "never waste" and V-HD-08) is recorded here for that touch.
- **`combat.md`'s `worst_case_arc_ms` printed as 700 and 800** (the ADR ratification
  table and the Not-knobs line say 700; TR-CMB-021, F-CMB-11, AC-CMB-26 and the
  registry's `combat_worst_case_arc_ms` say **800**, which is the correct derivation).
  **Rebutted as pre-existing and out of scope**: no clause of the revision touches it.
  **Carried**: owner lead-programmer (SYS-08), the next SYS-08 doc touch; the registry
  constant 800 is the operative tiebreaker.
- **The `decisions.md` ledger still reads D-ORCH-03 OPEN** (the seat cannot see the
  orchestrator's boundary PR). **Not a defect of this branch**: the orchestrator lands
  that ledger entry on its side (explicitly delegated at the approval); this lane names
  the ID in every commit and does not edit the orchestration ledger. Recorded so the
  lag is visible until the boundary PR lands.

### 7.3 The CD gate's closing note

The CD seat's second pass **APPROVED** the applied text and recorded that *"this verdict
closes the post-application CD gate owed by review-log § 6.3"*. Its six recommendations
are non-blocking and are routed: the SYS-13 rider (already carried), Combat OQ#5's
ratification note, the IP-15 sweep of combat.md's Stinger VS pins (partly done by the
SYS-12 repair), the module stage's branch-2 boundary as a SYS-16 input, the review log's
F-CMB-06 shorthand (corrected in § 6.2 above), and the identity law's three phrasings
("no harness" / "no gear" / "no modules" — one term at the next touch).

### 7.4 The CodeRabbit batch (PR #75)

One pass, triaged in one batch, one fix commit (`60a0c16`), every thread resolved with a
recorded disposition. **14 threads** on the first review (`f6ec1a0`):

| Disposition | Count | Findings |
|---|---|---|
| **Already fixed** in `67a14ed` (the applied-diff repair commit that landed after CodeRabbit's snapshot) | 3 | the `DamageResolver`'s `damage_bonus` input; F-CMB-06's range (now 1–4 / 1–8 — the confirmed value, see § 7.5); the SYS-12 MVP scope at all four Combat sites — two of these the bot auto-resolved |
| **Fixed** in `60a0c16` | 4 | the package's status header (now HISTORICAL — approved and applied); the review log's document-under-review header; 19 split Markdown table rows; F-HD-02's >132-with-a-module case (attack above the cap holds row 4) |
| **Deferred** (the sync lane / the coordinated SYS-13 rider) | 5 | the registry's four damage values + `spitter_orb_damage`; SYS-13's counter fixture, strike table, roster and orb clause; SYS-15's cache point-spend rider |
| **Rebutted** (recorded, not skipped) | 2 | the "formula template" request (not this corpus's template — all 15 formulas use the inline form, and converting four would break the document's consistency and exceed the approved scope); the player-profile cap ≥ 20 validation (TR-HD-012's fixture already gives the player the ∅ cap/immune defaults, so the pit cannot be clamped — a new invariant is out of scope) |

**Why the deferred five are not fixes here**: `design/registry/entities.yaml` and
`design/gdd/systems-index.md` are shared files under the single-writer law (the sync lane
applies them), and `enemy-ai-telegraphs.md`'s orb/hp/award/ceiling clauses are one
coordinated SYS-13 doc touch — a value-only edit there would leave its own sentence
contradicting itself. Both routes are recorded in § 6.2, § 9 and the lane report; the
threads are resolved with the disposition, not silently.

**The confirm pass** (CodeRabbit's re-review of `60a0c16`) posted **5 more threads**, all
valid and all closed in `270b9ad`:

| Finding | Disposition |
|---|---|
| F-CMB-06's output range ignored the multiplier's own 1.2–2.0 range (6 × 2.0 = 12) | **Fixed** — the range is **1–12** |
| The TTK envelope did not cover a module build (a `damage_bonus` of 1 puts a 24-HP T3 in two chains) | **Fixed** — the envelope is scoped to the **no-gear build**; a module build is measured against the parity bands (matching § 7b(4)'s Warden guardrail) |
| A player-targeted `DEFLECT` skipped defense mitigation (TR-HD-018 names only `ENVIRONMENT`) | **Fixed** — a `DEFLECT` routes by its **target**: `taken` when the target carries defense, the dealt law otherwise |
| § 6.3's "still owed" read as current | **Fixed** — marked as the status at that stage, pointing at § 7 |
| The six-field `DamageEvent` is not in the registry | **Deferred to the sync** — the registry has **no `DamageEvent` entry at all**, so it needs a new one (the sync lane's write); added to the sync request |

**Totals across both passes**: 19 threads, all resolved — 7 fixed before the review
landed (`67a14ed`), 8 fixed in the triage commits (`60a0c16`, `270b9ad`), 6 deferred to
the sync / the SYS-13 rider, 2 rebutted with the reason. No thread was resolved without a
recorded disposition.

### 7.5 The post-update CodeRabbit cycle (after the `Main` merge)

The branch update moved the head and CodeRabbit re-reviewed. It opened **2 threads, both
Minor, both valid, both about text this revision introduced** — and the first exposed a
genuine application error.

**Thread 1 — `combat.md`: the ATK knob joint constraint.** The seat observed that the
independent ranges permit `ATK1_DAMAGE + ATK2_DAMAGE` up to 9 while the SYS-07 ladder
requires row 0's chain to stay below row 1's 7. **Valid — and worse than stated**: the
applied text carried the *wider* ranges (`1–3 / 3–6 / 1–3 / 1–3`), which are the
package's § 8 early row, while the **approved package's § 3** specifies the narrowed
`1–2 / 3–4 / 1–2 / 1–2` — the technical seat had already found that the wide set breaks
the ATK2 column (ATK2 5 → row 1's 4) as well as the chain. **Fixed** by restoring the
approved ranges and stating the joint constraint in **both ATK rows and TR-CMB-004**:
`ATK1_DAMAGE + ATK2_DAMAGE ≤ 6`. F-CMB-06's band follows to **1–4** with the output
range **1–8** (superseding the 1–6 / 1–12 figures the earlier threads produced from the
wide set). **Every permitted pair verified**: (1,3) → chain 4 · (1,4) → 5 · (2,3) → 5 ·
(2,4) → 6 — all strictly below row 1's 7; ATK1 ≤ 2 < row 1's 3; ATK2 ≤ 4 = row 1's 4;
crouch/air ≤ 2; row 4's chain 10 ≤ 10. Every legal configuration passes V-HD-12.

**Thread 2 — `health-damage.md`: the DEFLECT enemy-attacker branch.** The enemy-target
arm of the dealt percent law assumed the player was the attacker; TR-HD-019/AC-HD-21 also
allow an enemy's deflected orb to hit another enemy, and no `attack` was defined for that
case. **Valid. Fixed** with one clause: the percent law's `attack` is **the attacker's** —
the player's 100–132 for a player-deflected orb, and **100 (the identity) for any
non-player attacker** — so an enemy-vs-enemy deflect keeps the orb's raw and a player's
orb keeps its raw at MVP (`attack` 100). The player-attacker behaviour is unchanged.

Both threads are resolved with these dispositions; the counts are unchanged
(39/15/50/68/20 · 33 knobs · 42+3+5+0; SYS-08 34/12/48 · 39+4+5+0).

**The sync landed in the same window** (PR #76, `6dd4651`): the registry now mirrors the
revision — the strike table, the four arc damages, the roster, the stagger note, the void
note, the four new constants and the new `damage_event` entity — and `spitter_orb_damage`
is correctly still **8** (the hold). The systems-index SYS-07 row, the design-order note
and the SYS-16/17 unblocking clause are in. **One sync correction is owed** (the shared
file is the sync lane's to write): the index's SYS-07 dependency bullet still prints
*"the heal item (Suture 25 × 3 charges …)"* — the Suture is **5** — and the bullet's
envelope/count sentence should be re-read against the row. Recorded here and in the lane
report.

## 8. The residual risks the seats did not block (recorded for the user)

- **R10 — the DEF axis collapses** at the low baseline (any `defense ≥ 1` ≡ DEF 25). The
  package turns this into a **D-1 input** rather than hiding it: a Chassis Module must not
  use `defense` as its lever; the levers are `StatBlock.damage_bonus`, the gear-aggregated
  `attack`/`hp_max`, and behavioural modifiers.
- **R11 — the L5→L6 handoff** is delegated to SYS-16 with a stated requirement (the VS
  sheet must be monotonic in both the `attack` stat — the frozen VS curve gives 130 at L6 —
  and the dealt value). The candidate rule is flat at L6; the handoff needs an authored
  repair, not a rule.
- **The strike table loses its tuning room** (P1 fixed at 1) — the lever moves to the pool
  and the tiers.
- **SYS-13's orb call**: at 2 the deflected orb no longer one-shots a Spitter
  (F-ENM-07/TR-ENM-024/AC-ENM-18) and its flash band moves to 2 — SYS-13's to re-decide.
