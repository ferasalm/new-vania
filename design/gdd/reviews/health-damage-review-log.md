# Review Log — Health & Damage (SYS-07)

> Falsifiability note: each entry records the verdict, blocking items, and scope signal at review time, so a later pass can verify what was addressed. This log is append-only; the review entry is not edited after the fact.

## Review — 2026-11-12 — Verdict: NEEDS REVISION → revised in-session → qa-lead spot-check PASS

Scope signal: **M** (targeted repair; no design re-open; the user-locked Plan B scope held: resolver + StatBlock identity law + MVP level 1–5 points-only + HP bar + damage numbers + heal item/quickslot + System Offline + Dirge-042 + weapon parity; the nine-stat sheet, energy consumers, mana, elements, crit and agility stayed VS).

Specialists: **creative seat** (fresh-context, GLM-5.3-Flash via `game-designer`) · **technical seat** (fresh-context, DeepSeek V4.1 Flash via `general`) · **QA seat** (fresh-context, DeepSeek V4.1 Flash via `general`). The **qa-lead spot-check** was a fresh-context DeepSeek V4.1 Flash seat (stand-in disclosed: the `qa-lead` agent is not a subagent type in this harness; the verification brief was the qa-lead's). The review lead was the orchestrator; the authoring session was not the reviewer. All three seats read `design/gdd/health-damage.md` against ADR-0001, the approved SYS-06 and SYS-08 GDDs, SYS-01, the game concept and the systems index.

**Verdicts at review.** Creative: **NEEDS REVISION** (3 blockers). Technical: **NEEDS REVISION** (13 blockers). QA: **NEEDS REVISION** (11 blockers). No seat proposed a redesign; the creative seat called the named fantasy, the death beat and the language discipline "the strongest part of the document"; the technical and QA seats found arithmetic, contract and testability failures, not scope or architecture failures.

### Blocking items at review time

**Creative (3).**

1. **C1 — a heal and a lethal hit can collide in the same tick.** TR-HD-030 applied the heal on the commit tick; TR-HD-020 ordered only damage events; the clock law split pools (`logic_tick`) from the damage phase (`physics_tick`). A 5-HP body, a 20-damage strike and a 25 heal in one tick had two outcomes depending on an invisible ordering — "a death whose cause is a race". Fixed: **the heal/use phase resolves after the damage phase in the same tick**; a heal on a DEAD target is refused and the charge preserved; TR-HD-020, V-HD-15, the edge case and AC-HD-22 carry it.
2. **C2 — the training-point model and F-HD-14 contradicted each other.** F-HD-14 auto-grew `attack = 100 + 8×(L−1)` and `hp_max = 100 + 8×(L−1)` while TR-HD-007 spent points; "L5 132/132" was unreachable under the spend model, and the +8 ATK fixture failed. Fixed: **points-only** — a level-up banks one point; the point is the only stat growth at MVP; 4 ATK → 132/100, chain 41; 4 HP → 100/132; 2/2 → 116/116; F-HD-14 and the knobs (`ATK_PER_POINT`/`HP_PER_POINT`) rewritten.
3. **C3 — the restore module had no MVP faucet, carry cap, or starting state.** The death screen's third option could be greyed forever. Fixed: **the first cache activation grants one restore module; carry cap 1; enemies do not drop modules**; TR-HD-025/031/032, AC-HD-27/34 and OQ#6 updated.

**Technical (13).** *(Process note: the technical seat's enumeration was transmitted truncated at T11; T1–T11 are reconstructed from its arithmetic, contract and testability audits, which name every site. The substance, not the seat's numbering, is authoritative.)*

1. **T1 — the heal arithmetic was wrong.** 25 at 90/100 applies **10**, discards **15** (not "15 applied, 10 discarded"); the charge is consumed on a legal use. F-HD-06/AC-HD-31 fixed.
2. **T2 — the progression contradiction** (same as C2/Q1). Fixed by the points-only model.
3. **T3 — the chain cycle is 37 ticks, not 48.** Combat's W12/AC-CMB-39 measures ATK1 start → ATK2 end with ATK1's recovery cancelled: 6+5+6+5+15 = **37 ticks**. Every DPS/TTK number moved: Dirge 48.65 dmg/s, the 60 s integral 2920, T1–boss 0.617/1.233/2.467/6.167 s. F-HD-10/13, TR-HD-034, AC-HD-36 fixed.
4. **T4 — AC-HD-14's floor clause was wrong.** DEF 100 clamps to 25 → 4/9/15, not 1; the floor-1 case is raw 1 at DEF 25 → floor(0.75) = 0 → 1. Fixed.
5. **T5 — the parity precision and harness.** "+9.9%" was exactly +10.0% under the Dirge denominator; the 60 s integral was 2244, not 2250; the harness frame was undefined. Fixed: the rate law (`48.65` / `52.17`, +7.2%), the 60 s integral (2920 / 3120), the light loop's +10.0% inclusive boundary, and the harness frame (infinite-HP dummy, no knockback, hit-stop excluded, melee reach).
6. **T6 — F-HD-12 was power-2-only.** Power 1 gives 430–680 ms vs a clean 180, not 250–500 vs 1200. Fixed: the **delta is always 250–500 ms** (the stagger elapsed); both power bands stated; AC-HD-50 added.
7. **T7 — the MVP gear/suit and the VS curve/points ambiguity.** The MVP had no gear source but the document carried `MVP_SUIT_DEF_BONUS`, a gear-swap AC and "gear ids" in the save list; the VS curve's +8 points would reach 366 at L20. Fixed: **MVP has no gear** (DEF is a VS stat; the formula is unit-tested at DEF 5/25); the suit removed; the VS curve/points question routed to OQ#5.
8. **T8 — the `ENVIRONMENT` source law was unenforceable.** "ENVIRONMENT may not carry a Combat source" had no field. Fixed: the reserved sentinel **`ENV` (entity id 0)**; `kind = ENVIRONMENT ⟺ source = ENV`; the target is never `ENV`; the 11-term gate.
9. **T9 — the damage phase's position was unpinned.** "Applies on the contact tick before the freeze" was an assertion, not an architecture. Fixed: **after Combat's contact detection and before the hit-stop freeze onset, in the same `physics_tick`, on the contact `logic_tick`**; the ADR pins the node; AC-HD-30 asserts contact → damage → freeze.
10. **T10 — the RNG determinism claim was incoherent.** The key included `swing_seq`, which the `DamageEvent` does not carry; `FixedRngPort` and "a third seed" were mutually exclusive; MVP has no rolls. Fixed: **the RNG is inert at MVP**; the VS hash key is `(logic_tick, attacker_id, defender_id, contact_tick)`; `FixedRngPort` = 0.5; the test-seam schemas published; AC-HD-39 rewritten.
11. **T11 — the perf envelope was false.** 2.0 + 1.0 + 1.0 + 0.75 = **4.75 > 4.0**; "the AC-54 family" mislabelled AC-53 (tick) vs AC-54 (allocation); W13 was undefined. Fixed: SYS-07 0.25/0.75; the four-system envelope **1.85 p99.9 / 4.75 max** recorded as OQ#19; W13 defined inline; AC-HD-40/41 corrected.
12. **T12 — OQ#1 moved the wrong ledger unit and omitted the chip timing symbol.** AC-42 is the Stinger's VS AC, not a chip clause; `CHIP_HOLD_COMMIT_MS` was absent from the cross-system inputs; SYS-24 was marked soft although the heal needs the chip. Fixed: the **six** chip units move; AC-42 stays VS; `CHIP_HOLD_COMMIT_MS` listed; SYS-24 "hard for the chip".
13. **T13 — SYS-08 was marked APPROVED while two amendments are pending.** A story author would implement the approved lose branch and the approved "no floating number" line. Fixed: the row reads **"APPROVED + OQ#2/#3 pending"**; OQ#2 names TR-CMB-012's rule **and test clause**, AC-CMB-14, the "not a shield" rationale and a **new** Combat OQ (not the resolved OQ#2).

**QA (11).**

1. **Q1 — the L5 progression arithmetic** (same as C2/T2). Fixed by the points-only model.
2. **Q2 — AC-HD-41's combined envelope was arithmetically false and W13 undefined** (same as T11). Fixed.
3. **Q3 — traceability failed the document's own law.** TR-HD-005/013/039 had no AC; F-HD-07/11/12 had no AC; there was no traceability AC; the counts were not stated. Fixed: AC-HD-13 cites TR-HD-005/F-HD-11; AC-HD-15 cites TR-HD-013; **AC-HD-49** is the traceability audit; F-HD-07 in AC-HD-37; F-HD-12 in AC-HD-50; the counts in the header.
4. **Q4 — the smoke gate contained VS content and the parity harness had no frame.** AC-HD-09 asserted the VS machine payoff; AC-HD-36 ran Elegy (VS); the harness was undefined. Fixed: AC-HD-09 cites OQ#13; AC-HD-36 is Dirge-only with the frame defined; Elegy is a VS record.
5. **Q5 — the playtest gate was not executable.** D5/D6 had no guaranteed denominators; "six playtest ACs" vs 5; the negation rule was only "bidirectional". Fixed: **five ACs / six codes**; the session scripts guarantee a lost clash and a cache spend; the denominators are the eligible testers; the SYS-01 negation rule (3 tokens, set-membership first, logged) copied.
6. **Q6 — the test seam was not buildable and the determinism test incoherent** (same as T10). Fixed.
7. **Q7 — the pit/void kill contradicted F-HD-03.** At DEF 5, `raw = hp_max` was mitigated to 125 and left 7 HP. Fixed: **`ENVIRONMENT` bypasses DEF and the i-frame lock**; the void applies `raw = hp_max`; the edge fires; AC-HD-20.
8. **Q8 — AC-HD-28 asserted behavior SYS-07 does not own and used the wrong timing point.** Fixed: the AC asserts the non-ack request, the next gate-entry phase and no damage on the transition frame; the buffer/verb assertions are cited to SYS-01 AC-59 / AC-CMB-29.
9. **Q9 — the heal charge was ambiguous** (same as T1). Fixed: two clean cases (90 HP: 10 applied, 15 discarded, one charge; full HP: refused, charge remains) with `quick_charges` asserted.
10. **Q10 — three fixtures were wrong.** AC-HD-14's floor clause; AC-HD-08 had no regen rate/duration; AC-HD-11 used 20–40 vs 20–41. Fixed: raw 1 at DEF 25 → 1; 50→55 after 60 logic ticks and a 30-tick freeze; the 20–41 envelope.
11. **Q11 — the VS ACs were counted but not testable.** Fixed: the gate manifest's VS row is **0**; the VS content is a "VS record" list + the OQ rows; the total is 50.

### Recommended items (recorded, not all applied)

- **R1** — print the death cause from the `DeathRecord` on the System Offline screen (applied: TR-HD-023 and the Visual/Audio section).
- **R2** — state the heal's commitment profile (applied: the chip publishes no `body_busy`; the use is not interruptible between the commit and the application).
- **R3** — the death sting is the fiction's glitch magnitude, not an alarm (applied: Visual/Audio).
- **R4** — the counter's persistence across quit/reload (routed to OQ#8).
- **R5** — the RNG port is inert at MVP (applied: TR-HD-037).
- **R6** — the `DamageNumber.world_pos` anchor port (applied: `HealthPort.anchor(id)`).
- **R7** — the `HealEdge`/`StatRevision` schemas (applied: TR-HD-035).
- **R8** — `CACHE_REFILL` used in F-HD-06/08 (applied).
- **R9** — the `PLAYER_MAX_HP` base range (applied: 60–160, points-only max 132).
- **R10** — the 20–41 standard (applied).
- **R11** — AC-HD-13's ATK1 counter values (applied: 15/17/18/19/20).
- **R12** — the `DeathRecord` archived on the revive path (applied: TR-HD-025).
- **R13** — the restore-module acquisition and the cache-context point spend (applied: TR-HD-025/032).
- **R14** — the lose-branch "optional mastery" consequence (applied: F-HD-12, AC-HD-50; the non-punishing archetype is a recorded bestiary advantage).
- **R15** — the VS curve/points question (routed to OQ#5).
- **R16** — the AC-06 recompute spy (applied).
- **R17** — the `ATK_BASE` naming (applied: `PLAYER_ATK_BASE`).
- **R18** — the AC-13/Overview pipeline wording (applied: the branch form).

### Revision applied in-session

All 27 blockers (3 creative + 13 technical + 11 QA) were revised in `design/gdd/health-damage.md` on 2026-11-12. The user-locked Plan B scope held; no design re-open; the three cross-GDD amendments remain **recorded obligations** (OQ#1–#3), not edits to the approved Combat GDD or the unfrozen SYS-01 GDD. Counts after revision: **39 TR-HD rules · 15 formulas · 50 ACs · 67 edge-case bullets · 19 open questions · 15 V-HD invariants · 32 knob rows**. The gate manifest is 42 smoke + 3 device + 5 MVP-lock + 0 VS = 50.

### Post-repair verification (qa-lead spot-check)

- **Claim sites:** 19/19 claimed repairs present and correct (C1–C3, T1–T13, Q1–Q11 with the duplicates counted once); no failed site.
- **Counts:** 39 TR / 15 formulas / 50 ACs / 67 edge bullets / 19 OQ rows / 15 V-HD / 32 knob rows — the header, TR-HD-039 and AC-HD-49 agree.
- **Gate manifest:** 42 + 3 + 5 + 0 = 50; exactly one gate per AC; no gap, no duplicate; no DEVICE AC defaulting to smoke; no playtest AC in smoke; VS = 0.
- **Arithmetic:** ATK 108/116/124/132 → 11/22/9/11 (33), 12/24/10/12 (36), 13/25/10/13 (38), 14/27/11/14 (41); counters 17/18/19/20; DEF 0/5/25 → 6/12/20, 5/11/19, 4/9/15; heal 10 applied/15 discarded; revive 66; TTK 0.617/1.233/2.467/6.167; chain 37, 48.65, 2920; Elegy 69, 52.17, +7.2%; light loop 27.27/30.0 (+10.0%); envelope 1.85/4.75; 4 ATK points → 132/100, 4 HP points → 100/132, 2/2 → 116/116.
- **Residual strings:** none of `64 edge`, `30 knob`, `37.5`, `2250`, `48 ticks`, `9.9%`, `8.0 s`, `third seed`, `AC-42 … move`, `PLAYER_ATK_PER_LEVEL`, `MVP_SUIT`, `the charge still consumed`, `the AC-54 family bars`, `gear swap`, `DEF 100 … 1`, `six playtest ACs` remain. `swing_seq` occurs once, as the intentional prohibition.
- **Verdict: SPOT-CHECK PASS.** Three non-claim follow-ups were closed: this review log; the AC-13/Overview pipeline wording; the `ATK_BASE` → `PLAYER_ATK_BASE` naming.

### Recorded obligations (no edit to the approved/unfrozen GDDs in this PR)

- **OQ#1 — the Quick-use chip promotion (SYS-01).** The chip moves VS → MVP; the six chip ledger units move (AC-33 chip, AC-35, AC-36 chip, AC-37 chip, AC-60 chip, AC-69 chip); AC-42 stays VS (the Stinger); the 96-unit AC→gate ledger must be re-derived; `CHIP_HOLD_COMMIT_MS` joins the cross-system inputs. **Blocking before the first SYS-07 story.**
- **OQ#2 — the clash-lose amendment (SYS-08).** TR-CMB-012's rule and test clause, AC-CMB-14, the "not a shield" rationale, a new Combat OQ; the lose branch is **0 damage + 500 ms stagger**, the follow-up carries the damage. **Blocking before the first Combat story.**
- **OQ#3 — the damage-numbers reversal (SYS-08 Visual/Audio).** "not a floating number at MVP" is superseded.
- **OQ#4 — SYS-13's follow-up, power legibility and `soul_class`.** At least one clash-capable archetype whose follow-up lands inside 500 ms; the follow-up telegraph ≥ 250 ms from the stagger start; the strike's power legible; `soul_class` on every enemy type.
- **OQ#19 — the four-system perf envelope re-baseline.** AC-CMB-39's three-system max 4.0 ms becomes 4.75 ms with SYS-07's 0.75; the QA plan's S_base/S_burst partition must name the four-system claim.

### Sequencing after this review

**SYS-07 is APPROVED (2026-11-12 — review NEEDS REVISION, all 27 blockers revised in-session, qa-lead spot-check PASS).** The next design work is **SYS-29 Juice** (the hit-stop pairing 70/90/40, the haptic channel, the clash sparks, the damage-number render), then **SYS-13** (the enemy strike contract: `power` 1–3, `active_ms ≥ 84`, `telegraph_ms`, hitbox, `facing`; the long-active power-1 heavy; the unclashable flag; the follow-up punish; the power legibility; the `soul_class` tags; the answerability review backdash·clash·crouch), then **SYS-32 camera** last. The carried obligations stand: OQ#7 (`repeat_tag` + `stream_origin_tick`, before the first Combat story); SYS-01's "proven 140 → 200" row; the Movement batch OQ-M1/M2/M3/M4/M5/M6.

### Process notes

- The OpenCode shell remains broken machine-wide ("The system cannot find the path specified" on every spawn, foreground and background). The **Godot MCP server did not attach in this session** (`godot_get_godot_version` / `godot_run_project` absent from the tool catalog; the `godot` server is configured in `opencode.json` but not loaded), so the documented throwaway OS.execute bridge had no launcher. All artifacts were authored with the write/edit tools; the branch/PR landing is prepared as an exact command list for the user (or the next session with a working shell/MCP).
- The three review seats ran as fresh-context subagents; the creative seat used **GLM-5.3-Flash** (`game-designer`); the technical and QA seats used **DeepSeek V4.1 Flash** (`general`); the qa-lead spot-check was a fresh DeepSeek V4.1 Flash seat (stand-in disclosed). None of the seats edited a file.
- The authoring session was not the reviewer. The creative **authoring consult** (the RPG-ideas assessment memo) was a separate `game-designer` session and did not participate in the review.
- No reviewer-provided "Prompt for AI Agents" block was executed; every finding was verified against the text before repair.
