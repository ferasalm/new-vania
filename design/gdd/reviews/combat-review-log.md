# Review Log — Combat (SYS-08)

> Falsifiability note: each entry records the verdict, blocking items, and scope signal at review time, so re-reviews can verify what was addressed.

## Review — 2026-11-12 — Verdict: NEEDS REVISION

Scope signal: **M** (targeted repair; no design re-open; the user-approved decisions 1–11 held).
Specialists: **technical seat** (fresh-context, general) · **creative seat** (fresh-context, GLM-5.3-Flash via `game-designer`) · **qa seat** (fresh-context, general). The review lead was the orchestrator; the authoring session was not the reviewer. All three seats read `design/gdd/combat.md` against ADR-0001, SYS-01, the approved SYS-06 GDD, the game concept and the prototype report.

**Verdicts.** Technical: **NEEDS REVISION** (8 blockers). QA: **NEEDS REVISION** (8 blockers). Creative: **PASS** (2 recommended). No seat proposed a redesign; the creative seat found the memo's rulings faithful and the language law clean.

### Blocking items at review time

**Technical (8).**

1. **T1 — Clash timing not derivable.** The pull-at-contact model (TR-INP-020) and the active-window-overlap model were mixed: if the pull is at the contact, the attack's active window starts `startup` later; F-CMB-03's "player active 1006–1010" and AC-CMB-10/11 assumed a press-time pull. Fixed: the **contact-time pull** is normative; F-CMB-03 is the projected-active model (`projected_active_start = contact + startup`); the enemy's active must cover `startup + 1`; AC-CMB-10/11 and the edge cases updated.
2. **T2 — Air landing lag missing from the `body_busy` OR.** TR-CMB-007 created a fifth commitment but TR-CMB-021/F-CMB-11 listed four. Fixed: **five commitments** (attack arc, air landing lag, clash lock, player stagger, hit-stop pair); F-CMB-11 and AC-CMB-26 updated; the worst case remains 700.
3. **T3 — Clash-lose double-lock.** The lose branch applied damage + a 500 ms Combat stagger while TR-CMB-026 also sent a `KnockbackOrder`; a power ≥ 2 enemy strike would enter Movement's 1200 ms KNOCKDOWN. Fixed: the lose branch publishes the `DamageEvent` but **no `KnockbackOrder`** — the 500 ms stagger replaces the hit reaction; TR-CMB-012/026, AC-CMB-14 and OQ#2 closed.
4. **T4 — `knockback_power` unused/contradicted.** The enemy contract published a dedicated field but F-CMB-09 used `strike.power`. Fixed: **removed `knockback_power`**; the single `power` drives both the clash and the knockback order; TR-CMB-028, the dependency row, the cross-system inputs and AC-CMB-33 updated.
5. **T5 — `ATTACK_ATK1` state exit at the active end.** The recovery is part of the 22-tick arc and the commitment; the state table ended it one phase early. Fixed: the attack state persists through recovery (chain at the chain point; recovery end otherwise); the table's exit updated.
6. **T6 — "Press expires" overgeneralized.** A press late in a hop/knockback/clash lock is still pending at the lock's end (age ≤ 12). Fixed: the press waits; if the body becomes free within the 200 ms window, it pulls at the lock's end; a press early in the lock expires. The dash/hop/knockback/clash-lock edge cases aligned with SYS-01's "a press inside the window is never lost."
7. **T7 — 84 ms / 5-tick clashability floor wrong.** `ceil(84 × 60 ÷ 1000) = 6` ticks, not 5; the "5-tick" labels contradicted the ceil law. Fixed: 84 ms = **6 ticks**; the per-arc condition is `remaining active ≥ startup + 1` (the 5-tick startup needs 6; the 6-tick startup needs 7); AC-CMB-19, the edge case, the knob and TR-CMB-028 updated.
8. **T8 — F-CMB-02 `arc_end` off by one.** The formula gave 1021 while the example and the 22-tick fixture require 1022 (exclusive). Fixed: `arc_end = active_end + recovery_ticks + 1`; the example and F-CMB-11's lock example corrected.

**QA (8).**

1. **Q1 — No gate manifest.** The 4 DEVICE and 5 PLAYTEST ACs had no gate home and defaulted to smoke by omission. Fixed: the **gate manifest** added — 39 smoke + 4 device + 5 MVP-lock + 0 VS = 48, exactly one gate per AC.
2. **Q2 — W12 undefined.** The perf workload was a sketch. Fixed: W12 defined (2,500 chains + 2,500 counter-clashes + 2,500 double clashes + 2,500 lose/getup cycles; the enemy-strike fixture; the freeze windows; the estimator pointer).
3. **Q3 — 84 ms (same as T7).** Fixed.
4. **Q4 — AC-CMB-38 bars not measurable.** "Bounded churn" and "their bounds" had no thresholds. Fixed: the AC-54 bars (zero net object/resource delta; heap growth ≤ 256 KB; churn ≤ 16 KB / 1,000 ticks) + the named structures' bounds.
5. **Q5 — AC-CMB-39 combined budget incoherent on S_burst.** The combined ≤4.0 ms max holds only on S_base; SYS-01 alone can reach 4.0 ms on a burst tick. Fixed: the combined bar is scoped to **S_base**; the S_burst combined bar is the QA plan's partition; the combined claim is the arithmetic envelope of the three runs, not a single W12 measurement.
6. **Q6 — C1–C7 codes undefined.** The playtest ACs pointed to the SYS-01 Q1–Q4 protocol but defined no Combat codes. Fixed: the **C1–C7 coding table** (inclusion/exclusion sets, the bidirectional negation rule, the SYS-01 AC-63 protocol).
7. **Q7 — AC-CMB-46's "SYS-01 gesture trace's attacks" did not exist.** Fixed: the AC names the **Combat attack trace** (a scripted 600-tick attack/clash trace replayed through the device input path; the trace and the enemy-strike fixture are pinned in the Combat QA plan) and defines the **eligible-contact count**.
8. **Q8 — F-CMB-02 `arc_end` (same as T8).** Fixed.

### Creative seat — PASS

The memo's named fantasy, contract, three anchors, feel rulings, language law and success signature are present and faithful; no feel ruling violates a contract (no Dash i-frames, no clash i-frames, no new verbs, no new i-frame sources beyond backdash + the sized getup, no numbers in player copy, no hints). The Visual/Audio section honors the telegraph doctrine and the sigil-red reservation; the C1–C7 feel ACs are falsifiable. Two recommended items: prefix "AC-20's harness" as **SYS-01 AC-20** (applied); record the negation-use precedent in the language law (recorded, not a blocker).

### Recommended items (recorded, not all applied)

- R1 AC-CMB-12 now tests ATK1 15, ATK2 30 and the "power, not damage" case (applied).
- R2 AC-CMB-13 asserts two `spark_pulse` events (applied; the visual is SYS-29's).
- R3 AC-CMB-15 prefixes **SYS-01 AC-20** (applied).
- R4 AC-CMB-03 asserts the exact tick change (applied).
- R5 AC-CMB-22 asserts `iframe_ticks = 0` (applied).
- R6 AC-CMB-47 has a completion bar (applied).
- R7 The V-CMB invariant table added (applied: V-CMB-01…12).
- R8 Hitbox knobs added (applied: the four provisional rows).
- R9 `facing` is now used (the hitbox side; TR-CMB-001) and `move_refused` removed from the Combat dependency row (applied).
- R10 The air attack is explicitly "a whole arc, not a chain" (applied).
- R11 The hold's "cannot choose ATK2" is clarified (applied).
- R12 The provisional lifetimes now include the crouch/air phases, the lock/stagger, the hit-stop values and the deflect speed (applied).
- R13 AC-CMB-07 remains a compound AC (two clauses); split at the Combat QA plan if the ledger needs clause-units (recorded).
- R14 AC-CMB-46/48 remain device ACs; their GUT halves are covered by AC-CMB-01/02 and the Combat QA plan (recorded).
- R15 The dead i-frame-contact edge case is marked VS/dead at MVP (applied).
- R16 The same-tick direct-tap/hold-repeat coalesce is SYS-01's slot outcome, not a new Combat rule (applied to the edge case).
- R17 The systems-index SYS-08 row and the dependency map now include SYS-13/SYS-29 (applied).
- R18 The AC-CMB-26 wording is "the derived max (700 at defaults)" (applied).

### Revision applied in-session

All 16 blockers were revised in `design/gdd/combat.md` on 2026-11-12. The GDD is **In Review** (not Approved); a diff-scoped re-review is the next gate. Counts after revision: **34 TR-CMB rules · 12 formulas · 48 ACs · 47 edge-case bullets · 10 open questions** (OQ#2 closed). The gate manifest is 39 smoke + 4 device + 5 MVP-lock + 0 VS = 48.

### Sequencing after this review

**Diff-scoped re-review in a fresh session** (the changed sections + the arithmetic/AC fixtures; qa-lead spot-check mandatory) → then SYS-07 Health & Damage, which must consume the `DamageEvent` boundary, the provisional damage values and the `KNOCKDOWN_POWER` 2 threshold; then SYS-29 Juice (the hit-stop pairing and the haptic channel); SYS-13 (the enemy strike contract: `power`, `active_ms ≥ 84`, `telegraph_ms`, hitbox). The hold-repeat contract extension (OQ#7: `repeat_tag` + `stream_origin_tick`) is a one-field SYS-01/ADR amendment before the first Combat story; it does not re-open the SYS-01 review loop.

### Process notes

- The OpenCode shell remains broken machine-wide; the review and landing ran through the documented throwaway Godot OS.execute bridge (untracked; in no commit).
- The three review seats ran as fresh-context subagents; the creative seat used GLM-5.3-Flash (`game-designer`); the technical and QA seats used the default model (`general`). The creative seat wrote no files.
- The authoring session was not the reviewer; the review read the GDD, ADR-0001, the approved Movement GDD, SYS-01 and the prototype report.
