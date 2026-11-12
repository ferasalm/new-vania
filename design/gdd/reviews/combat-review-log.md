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

## Re-review — 2026-11-12 — Verdict: PASS (after in-session repair)

Scope signal: **S** (diff-scoped: the changed sections from the 16-blocker revision + the arithmetic/AC fixtures; no design re-open). Fresh session; the review lead was the orchestrator, not the authoring session. Seats: **technical** (fresh-context, DeepSeek V4.1 Flash via `general`) and the **mandatory qa-lead spot-check** (fresh-context, DeepSeek V4.1 Flash via `general`). No creative re-review (the design-review creative seat passed; no feel ruling changed).

**Verdict at re-entry: NEEDS REVISION** — 5 blockers (2 regressions introduced by the revision, 3 arithmetic/range defects) + 6 one-clause notes. All were repaired in-session; the post-repair machine audit is **60/60 PASS** and the qa-lead spot-check is **16/16 fix sites, 6/6 fixtures, counts 34/12/48/47/10**. Final verdict: **PASS**.

### The 5 blockers and their repairs

1. **R1 — TR-CMB-001 never pulls a normal attack (regression from T1).** The contact-time pull was made normative, but the rule named only the strike-contact frame and the chain point; an attack pressed on a free body with no incoming strike had no pull trigger and expired silently — contradicting the states table, the dash/hop edge cases, F-CMB-12 and AC-CMB-03/05/46. Fixed: TR-CMB-001, the Interactions row and the ADR ratification row now read **"the strike-contact frame, the chain point, or immediately on the first body-free tick when no contact is pending"**; a held press that never contacts is pulled when its window closes — **never silently lost** (SYS-01's promise).
2. **R2 — AC-CMB-39's W12 was arithmetically impossible (regression from Q2).** 10,000 ticks = 166.7 s, but the four 2,500-cycle sets need ≈ 412,500 ticks (≈ 114 h); a 37-tick chain also cannot start every 36 ticks. Fixed: W12 is now **50 chains (37 t) + 50 counter-clashes (32 t) + 50 double clashes (54 t) + 50 lose-branch cycles (42 t) + 10 clean power-2 → knockdown→getup cycles (78 t) = 9,030 busy ticks**, 970 idle/transition. The lose branch and the getup are separated (the lose branch publishes no `KnockbackOrder`, so it cannot produce a knockdown).
3. **R3 — formula-variable ranges contradicted the knob safe ranges.** F-CMB-02 declared Active 50–120 and Recovery 100–300 while `CROUCH_ATTACK_ACTIVE_MS` is 40–80 and `AIR_ATTACK_RECOVERY_MS` is 80–160; F-CMB-06 declared `ATK.damage` 8–20 while the four damage knobs are 6–14 / 14–26 / 5–12 / 6–14. Fixed: Active **40–120**, Recovery **80–300**, `ATK.damage` **5–26**; TR-CMB-026's "power is 1" is now **"at defaults"** (the power knobs allow 1–2 and 2–3).
4. **R4 — `ATTACK_WINDOW_MS`'s 140 ms floor could not carry the chain-from-first-tick.** The chain point is 11 ticks after ATK1's start; 140 ms = 9 ticks, so the earliest press expired before the chain. At `ATK1_STARTUP_MS = 120` (8 ticks) the chain point is 13 ticks, beyond even the 200 ms default. Fixed: the floor is **183 ms (11 ticks)**; `ATK1_STARTUP_MS` is capped at **116 ms (7 ticks)** so 7 + 5 = the 200 ms window; **V-CMB-13** added (`ms_to_ticks(ATTACK_WINDOW_MS) ≥ ATK1_startup_ticks + ATK1_active_ticks`, dev boot failure).
5. **R5 — F-CMB-01's "overshoot ≤ 1 tick" was false per arc.** ATK1 330 ms → 22 ticks = 366.7 ms (2.20 ticks), air 270 → 300 ms (1.80). Fixed: **"< 1 tick per phase; an arc's total is the sum of its phases' overshoots — 2.2 ticks for ATK1 at 60 tps"**.

### The 6 one-clause notes (all applied)

- **N1 — the clash needs a free body at contact.** TR-CMB-008(a) now requires it (an attack already in its arc cannot clash; its pending press waits for the chain point). The **deflect** inherits the projected-active model (TR-CMB-015, F-CMB-10) — T1 had left the deflect evaluating the contact tick.
- **N2 — the 84 ms floor's justification** is now "the fastest startup **at defaults** is 5 ticks" (the 60 ms crouch corner is 4; the 84 ms floor is the design floor SYS-13 authors to).
- **N3 — TR-CMB-014 / AC-CMB-16 / AC-CMB-47 marked PROVISIONAL — blocked on OQ#7.** SYS-01 does not yet publish `stream_origin_tick`/`repeat_tag`, and its supersede law currently resets the age on every repeat, so the exemption cannot fire until the one-field amendment lands.
- **N4 — state table:** COMBAT_IDLE exits only on "attack pulled" (clash/stagger/hit were unreachable from IDLE); STAGGER gains the "hit" exit (law 2); an **AIR_LANDING** row was added for the fifth commitment.
- **N5 — the two summary enumerations** (Overview, Interactions `body_busy` row) now list all five commitments, including the air landing lag.
- **N6 — the prior entry's "10 open questions"** is corrected here: **10 OQ rows, 9 open (OQ#2 closed)**. The prior entry is not edited (append-only log).

### Recorded obligations (no Combat edit)

- **OQ#7 — the hold-repeat contract extension** (`repeat_tag` + `stream_origin_tick`) is a one-field SYS-01/ADR amendment **before the first Combat story**; it does not re-open the SYS-01 review loop. Until it lands, TR-CMB-014/AC-CMB-16/AC-CMB-47 are PROVISIONAL.
- **SYS-01's verb table** still records "proven 140 combo value" for the attack override while Combat declares 200 ms (legal under SYS-01's override hook; the SYS-01 row must carry 200 when it is next edited).
- **Lose-branch economy note for SYS-07:** the clash-lose branch (500 ms stagger, no `KnockbackOrder`) is deliberately cheaper than a clean power-2 hit (1200 ms knockdown+getup); SYS-07 ratifies the gap when it consumes the `DamageEvent` boundary.

### Machine audit + qa-lead spot-check (post-repair)

- **qa-lead spot-check:** 16/16 claimed fixes present (2 PASS-with-note, both repaired by N5/N1), 6/6 arithmetic fixtures recomputed exactly, counts 34 TR / 12 formulas / 48 ACs / 47 edge bullets / 10 OQ rows, gate manifest 39 + 4 + 5 + 0 = 48 with exactly-one membership. **SPOT-CHECK PASS.**
- **Machine audit (post-repair):** 60/60 — TR/AC/formula uniqueness (34/12/48), every TR cited (slash shorthand expanded; 53 citations, 34 unique), gate membership, edge/OQ counts, the 18 numeric fixtures, the 25 repair-site checks, and zero stale strings (`140–260`, `70–120`, `8–20`, `2,500`, the four-commitment summaries, the IDLE clash exit, the unqualified "fastest startup").
- **CI:** PR #23's five checks + CodeRabbit were green pre-repair; the post-repair push re-runs them.

### Sequencing after this re-review

**SYS-07 Health & Damage** — consumes the `DamageEvent` boundary, the provisional damage values (ATK1 10 / ATK2 20 / crouch 8 / air 10; counter 15/30) and `KNOCKDOWN_POWER = 2`; it ratifies the economy and the lose-branch gap. Then **SYS-29 Juice** (the hit-stop pairing 70/90/40 and the haptic channel), then **SYS-13** (the enemy strike contract: `power` 1–3, `active_ms ≥ 84`, `telegraph_ms`, hitbox; the unclashable flag). OQ-M1/OQ-M2 remain the recorded Movement-side one-clause edits.

### Process notes (re-review)

- The OpenCode shell remains broken machine-wide; the review, the repair, the audit and the landing run through the documented throwaway Godot OS.execute bridge (untracked; in no commit).
- Both seats ran as fresh-context subagents on **DeepSeek V4.1 Flash** (technical + QA/left-brained routing per the user's instruction); the review lead is the orchestrator. Neither seat edited a file; the repair was applied by the review lead under the user's approval.

## Post-review CodeRabbit pass — 2026-11-12 — 14 threads adjudicated

CodeRabbit reviewed PR #23's full commit range (the Combat diff plus the SYS-06 commits carried on the branch). **None of the reviewer-provided "Prompt for AI Agents" blocks was executed**; each finding was verified against the current text first.

### Combat — 4 valid findings, all repaired

1. **`worst_case_arc_ms` must be the longest *consecutive* busy interval.** The clash lock starts after the attack's startup, and the body is continuously busy across both: 6 + 42 ticks = **800 ms**, not 700. Fixed: TR-CMB-021, F-CMB-11, V-CMB-05 and AC-CMB-26 now use `max(arc, air_landing_lag, max_startup + clash_lock, stagger) = 800`; the Interact derivation uses 800 + margin; `design/registry/entities.yaml`'s `combat_worst_case_arc_ms` is 800. The combined `body_busy` max stays 1200 (Movement's knockdown).
2. **Same-x knockback direction.** `sign(target_x − source_x)` is 0 when the bodies share an x-coordinate, outside Movement's `{−1, +1}` facing contract. Fixed: TR-CMB-026 / F-CMB-09 fall back to `source.facing` (the strike's direction); AC-CMB-31 asserts the same-x case is never `dir = 0`.
3. **The active-start edge case contradicted F-CMB-03.** The edge case said any active window that started before the pull is a hit; F-CMB-03 permits a clash when the remaining active still covers the projected active start. Fixed: the edge case now defers to F-CMB-03's overlap condition and keeps the hit only when the remaining active is shorter than startup + 1.
4. **AC-CMB-19's contact tick was unspecified.** A 6-tick strike contacted on its second active tick has 5 remaining < 6 and cannot be clashed. Fixed: the successful case pins **first-active-tick contact**; a later-contact case asserts not-clashable.

### Combat — 2 already addressed

- The `ATTACK_WINDOW_MS` floor vs the chain point and the W12 interval were both marked **✅ Addressed in commit `1edbe98`** (this re-review's R4/R2 repairs). No further change.

### Systems index — 1 valid finding, repaired

- **SYS-08 ↔ SYS-29 cycle.** Added the cycle note: SYS-08 → SYS-29 is **soft at design** (the hit-stop clock is a contract; a stub suffices) and SYS-29 → SYS-08 is **soft** (read-only commitment state); the design order SYS-08 → SYS-29 stands.

### Movement — 7 threads, adjudicated (not repaired in this Combat PR)

- **Refuted — registry (1):** both entries exist in `design/registry/entities.yaml` — `knockdown_power` (line 273, value 2) and `backdash_iframe_ms` (line 285, value 140). No gap.
- **Already addressed / stale (3):** the dash-jump exception is in the current text (movement.md line 146); AC-MOV-14 carries both branches (committed/airborne vs grounded body-free, line 685); the jump-cut finding has no MVP impact (`JUMP_CUT_RATIO = 1.0`; the r² note is a future hybrid option — a wording clarification is recorded).
- **Valid, recorded for the Movement batch (3):**
  - **OQ-M3 — same-wall climb:** the `WALL_JUMP_REARM_MS` gap only delays; a player can steer back to the same wall while still above the jump origin and gain height each cycle. Fix direction: same-wall re-arm requires falling to or below the previous wall jump's origin height (or a per-wall cap). Sites: TR-MOV-014, the wall-jump state row, F-MOV-08, AC-MOV-49, the two edge cases.
  - **OQ-M4 — air-attack steering:** F-MOV-03 has no committed branch, so air control still accelerates during an air attack; Combat's "no steering" (TR-CMB-007) needs Movement to preserve `v_x` while `body_busy ∧ no scripted arc`.
  - **OQ-M5 — discrete knockback fixture:** the semi-implicit integrator gives **14.8 px (power 1) / 63.3 px (power 2)**, not the continuous 16.9 / 67.6; AC-MOV-22 (and movement.md line 204's "discrete values") must assert the discrete pair.

### Post-repair audit

**71/71 PASS** — the 34/12/48/47/10 ledger, the gate manifest, all 19 numeric fixtures (including the 800 ms consecutive interval), the 25 re-review repair-site checks, the 10 CodeRabbit repair-site checks, and zero stale strings. The review log's counts are unchanged (34 TR / 12 formulas / 48 ACs / 47 edge bullets / 10 OQ rows).

### Process notes (post-review)

- The shell remains broken; the adjudication ran through the documented throwaway Godot bridge (untracked). Thread replies + resolutions were posted via the GitHub API; no reviewer prompt was executed.
