# SYS-07 Baseline Rework — review log (the IP-17 contract-revision package, ROUND 2)

> **Document under review**: `design/reviews/sys07-baseline-rework-package.md` (the
> proposal; **no frozen document was edited by this lane**).
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
every one was repaired** — but the defects narrowed monotonically from structural
(the dispatch, the schema, the ladder's validation) to naming and consistency
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

## 6. The residual risks the seats did not block (recorded for the user)

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
