# SYS-16 Progression — review log

> Lane `docs/sys16-progression` · document `design/gdd/progression.md` · runner on
> `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` (DS — a technical
> lane) · base `b991714` · prompt v1.0.0 / `dbab34722ade` (header matches the manifest).

## A. Gate trail

| Gate | Seat / model | Verdict | Blockers | Disposition |
|---|---|---|---:|---|
| CD-GDD-ALIGN #1 | creative-director · GLM-5.3-Flash | **CONCERNS** | 1 | repaired (`3516bd8`) |
| CD-GDD-ALIGN #2 | creative-director · GLM-5.3-Flash | **APPROVED** | 0 | 4 recs applied |
| Creative seat | game-designer · GLM-5.3-Flash | **NEEDS REVISION** | 3 | all repaired |
| Technical seat | lead-programmer · DeepSeek V4.1 Flash | **NEEDS REVISION** | 10 | 9 repaired, 1 rebutted-with-rider |
| QA seat | qa-lead · DeepSeek V4.1 Flash | **NEEDS REVISION** | 10 | all repaired |
| qa-lead spot-check | qa-lead · DeepSeek V4.1 Flash | **PASS (round 4)** | 0 | §F — rounds 1–3 FAILed (3, then 4, then 1 blocker), all repaired |
| Final micro-check | fresh seat · DeepSeek V4.1 Flash | **PASS (round 2)** | 0 | §G — round 1 FAIL (1 blocker), repaired |

**Process note (recorded, not a skip).** The contract calls for the three seats to be
spawned in parallel. They were spawned in **two waves** — creative first, then
technical and QA together — so that each wave reviewed the repaired text rather than
the same defects three times. No seat was skipped, every seat read the document once
in full, and each seat's model was passed explicitly (creative/CD → GLM; technical/
QA/spot-check → DS). The consequence is that the technical and QA seats saw a text
already repaired from the creative wave, which is stricter, not looser: their
blockers are therefore *additional* defects, not re-reports.

## B. CD-GDD-ALIGN

### B.1 Pass 1 — CONCERNS

**B1 (blocker).** The pacing ledger booked **2 T3** while the gear layer required a
Warden behind the post-flip partition — SYS-02 receives a spawn budget and a placement
obligation that cannot both be satisfied.
**Repair.** The blocker was right, and checking it exposed a **deeper** defect the CD
had not seen: `design/gdd/room-world-structure.md` TR-RWS-002's layout fixture pins
**five spawns total** (0/2/2/0/1/0, max two per room) and TR-RWS-011 **re-arms the list
on every room entry**. The ledger was therefore wrong in *form* (a static 18-enemy
population), not just in count. Re-derived as a **rate**: `PACING_PASS_YIELD` = 30 per
pass (RM-02's two Husks + RM-03's pinned pair + RM-05's Warden), L2@1 / L3@2 / L4@3
passes, L5 at the fourth pass's boss. The Warden-tier part became a **placed `TAKE`
in the Cold Corridor wing beside M4** — no second Warden spawn (the two-per-room cap
forbids it) and no drop table (the anti-junk determinism D-1 asks for), with the
reasoning printed in TR-PRG-017 so a reader cannot mistake it for an omission.

**Recommendations (8) — all applied:** rider (a) extended to F-HD-14's pool clause;
rider (c) added for TR-HD-006's DEF-source clause; TR-PRG-004's boss-award source
corrected to SYS-07's `XP_BOSS`; the readout's ATK unit changed to the machine's own
units; G2's exclusion set gains "a broken promise"; SYS-05's row restated (the story
trigger, SYS-16 the sole grant writer); `MODULE_DAMAGE_HP_COST` derived; the module
rows aligned to the terminal's "chassis" vocabulary.

### B.2 Pass 2 — APPROVED

Zero blockers. **Recommendations (4) — all applied:** SYS-07's **OQ#18** joins the
closed table (the three-value readout); rider (a) names F-HD-14's frozen "up to L20
(214)" ceiling so SYS-07 cannot carry two VS attack ceilings; `PACING_PASSES_L5_MAX`
states its including-the-boss semantics; AC-PRG-08's fixture count aligned to its
seven outputs.

## C. Three-seat panel

### C.1 Creative seat (GLM-5.3-Flash) — NEEDS REVISION, 3 blockers

| # | Blocker | Disposition |
|---|---|---|
| 1 | The anchor claimed point 1 makes the T1 Husk die in one chain instead of two — **false** (the Husk is 6 HP and the identity chain is already 6; point 1 flips no kill anywhere in the roster). | **APPLIED.** The anchor re-written around what point 1 truly buys (the light hit's number, the chain 6→7) plus a printed ledger of the four points' real outcomes: **no flip / the Warden 4→3 / no flip / the boss 7→6**. TR-PRG-006 now states the uneven payoff as a law and forbids a preview that claims a flip it does not deliver. |
| 2 | The "a kill crosses two thresholds at once" example (boss 40 at 100 XP → 140) is **unreachable**: 100 XP is already L4 and 140 crosses exactly one threshold. | **APPLIED.** Replaced with the reachable instance — a boss award of 40 taken at 16–19 XP → 59, crossing 20 and 50 (the runner who reaches the boss early) — and the frozen gaps (30/40/50 vs a 40 maximum award) are printed as the reason a double crossing needs a sub-20 start. |
| 3 | The ATK readout did not say whether the pair folds `damage_bonus`; read literally it printed `ATK 2/4` while the hand dealt 3/5 — a gear-blind readout is the exact lie the success signature forbids. | **APPLIED.** TR-PRG-011 now prints the **effective** pair (`ATK 3/5` under the Coupler) with "the printed number must equal the number the hand deals" as the clause, and AC-PRG-11 gains the geared fixture. `ProgressionRead.atk_pair` is the publisher (TR-PRG-026), so SYS-24 never re-derives the ladder. |

**Recommendations (7) — all applied:** OQ-PRG-6 biases toward a post-boss spend;
`Governor-000` renamed **`Regulator-000`** so the two modules do not share a display
family; the frame's MVP auto-advise recorded (the argument is the drive's); the
dormant-socket anchor aligned to `DORMANT_DIM_AFTER_TEASE` (hidden first, dimmed on
the first press); the first cache visit's inertness (16 of 20 XP) folded into
TR-PRG-006; AC-PRG-32 now codes the Warden connection; the mid-fight equip's
legality and self-clamp stated.

### C.2 Technical seat (DS) — NEEDS REVISION, 10 blockers

| # | Blocker | Disposition |
|---|---|---|
| 1 | The boss award had two owners (SYS-07's `XP_BOSS` in one place, "SYS-14's registration" in another), and SYS-14 is unwritten. | **APPLIED.** SYS-07's `XP_BOSS` is the sole source in TR-PRG-004, AC-PRG-04, the dependency row and the inputs list; SYS-14's row now reads "None for the award". |
| 2 | **The guardrail silently replaced the upstream band.** F-HD-10 says a module build is "measured against the parity bands (V-HD-14)", and V-HD-14's binding MVP measurement is the 60 s integral ±10%; the Coupler's 779 vs 584 is +33.4% — a breach, and paying HP does not change sustained damage. | **REBUTTED WITH RIDER (d) — and the one item escalated.** The rebuttal: F-HD-10's sentence contrasts *rulers* (envelope vs bands), calls module damage "a situational source", and the ±10% ceiling belongs to TR-HD-034/F-HD-13 whose subject is the **weapon set** (one weapon at MVP). Read as a hard ceiling on gear, **D-1's gear layer cannot exist at all** — the integral must stay ≤ 642, i.e. chain ≤ 6.58, i.e. no damage lever — which contradicts the user's own D-1. So the lane records the reading (TR-PRG-013), requests rider (d), and **pre-authorises the fallback**: if the ceiling reading is upheld, `WINDOW_EXCEPTION_ENABLED` goes false, the drive payload is withdrawn, and the MVP gear layer is pool-only — a data switch, not a redesign. This is the lane's single hard decision item (§H). |
| 3 | The point's +8 had no transport, and the printed ATK pair had no publisher. | **APPLIED.** TR-PRG-026 names the ack chain (SYS-15's commit → SYS-16 writes the counter → SYS-07 reads `ProgressionRead` and applies one `StatRevision`) and `ProgressionRead` gains `atk_pair`. AC-PRG-06 asserts the chain. |
| 4 | `banked_points` was both a mirror and a derivation — two writers. | **APPLIED.** SYS-07's `training_points` is the writer; `banked_points` is a **read alias** with an equality assertion (TR-PRG-002, AC-PRG-02). |
| 5 | The namespace duplicated SYS-07's fields while AC-PRG-02 forbade SYS-16 writing them — both ACs could not pass. | **APPLIED.** The split is now explicit: SYS-07 is the **runtime** writer, SYS-16 is the **namespace** writer (one writer per family); TR-PRG-026 carries no `level`/`training_data` (not re-owned, not duplicated). |
| 6 | F-PRG-03's `attack > 132` law had no implementer. | **APPLIED.** Rider (f) names F-HD-02's branch 2 and SYS-07 as the implementer; unreachable at MVP (`attack ≤ 132`), so VS-gated. |
| 7 | F-PRG-06's `chain_nogear` used `step()`'s clamp and under-reported every L6+ chain. | **APPLIED.** `chain_nogear = dealt(ATK1) + dealt(ATK2)` from F-PRG-03. |
| 8 | The reducer's command set was not total (no module id, no slot, two exits from BUILT, no level-up command). | **APPLIED.** `SPEND_POINT(kind) · EQUIP(module_id) · UNEQUIP(slot) · ACQUIRE(module_id) · GRANT(g) · SYNC(health_read) · LOAD(namespace) · SNAPSHOT()`, with AC-PRG-29's command-totality fixture. |
| 9 | The carry joined SYS-05's restore window with no acknowledgment — a read race. | **APPLIED.** SYS-16's carry-complete acknowledgment is a named input to `load_complete` (TR-PRG-025, the SYS-05 row, AC-PRG-25's read-gate fixture). |
| 10 | The seven consumed constants are not in the registry, so AC-PRG-01's "empty diff" fails at landing. | **APPLIED.** TR-PRG-001 names the **pending registration** (seven constants, `atk_per_point` … `xp_boss`) and scopes the boot check to the named list until the sync lands; AC-PRG-01 matches. |

**Recommendations (10) — 9 applied, 1 rebutted.** Applied: the guardrail's (c) term
became the anti-stacking rule (it previously restated (a) as an absolute and never
bound); the catalogue's payloads now name their symbols; `owned_modules` → `owned`
everywhere; AC-PRG-03 asserts a **core-owned** allocation counter (a GDScript-wide
"allocates 0 times" is not measurable); rider (e) for TR-HD-010's writer clause;
AC-PRG-11 pins HP as current/max; TR-PRG-020 cites SYS-01's/SYS-05's pause gate;
AC-PRG-13 retagged `[GUT + LINT]`; TR-PRG-025 mirrors SYS-15's OQ-CSD-9 rider
including SYS-03's stale posture sentence. **Rebutted:** `MODULE_DAMAGE_HP_COST`
keeps its knob-table row — the row is labelled "derived, never edited", and removing
it would hide the derivation the closure depends on; the count stays 21.

### C.3 QA seat (DS) — NEEDS REVISION, 10 blockers

| # | Blocker | Disposition |
|---|---|---|
| 1 | AC-13 was `[LINT]` but carried executable assertions, and TR-PRG-013's fixtures had no AC — the DEF retirement had no runnable proof. | **APPLIED.** AC-13 is `[GUT + LINT]`: the LINT half is the printed law/refusal/fallback presence; the GUT half is the row percentages, **the DEF 1–24 × raw 1–4 sweep**, the two-cause audit and the pool-only fallback fixture. |
| 2 | Seven named fixtures had no AC (the preview ledger, the split-independence, the two-cause, the sign, the mid-fight swap, the read-gate, the command-totality). | **APPLIED.** Attached to AC-06, 10, 13, 15, 20, 25 and 29; AC-29's audit is now **fixture-level**, not TR-level. |
| 3 | Six edge bullets had no fixture, and the `POINT_BUDGET_CAP → 6` case **contradicted F-PRG-08** (a non-fixpoint the doc's own V-PRG law calls a boot failure). | **APPLIED.** The double-crossing and queue cases join AC-04; `VS_ATTACK_STEP = 0` and the live-edit seam rejection join AC-08; the guardrail's live-edit rejection joins AC-14. `POINT_BUDGET_CAP`'s safe range is now **4 (fixed at MVP)** and the cap-above-4 case is **rejected** (the level-up rule never grants a fifth point). |
| 4 | AC-32 was `[DEVICE]` with qualitative outcomes and no cohort, coding scheme or threshold — unfalsifiable, and the SYS-01 protocol does not apply to a device AC. | **APPLIED.** Moved to **MVP-lock** as a coded **G5 the-earn** with elicitor, inclusion/exclusion tokens and a qualifying floor; the partition becomes **29 + 2 + 5 + 0 = 36**. |
| 5 | AC-34 closed on a "broken promise **majority**" while TR-PRG-017 and the concept close on a **single** answer — the AC did not test its TR. | **APPLIED.** One rule: the concept's verbatim **single coded "broken promise" closes the window**; the reward bar (≥3/5) is the signal, the broken-promise answer is the gate. TR-PRG-017, AC-PRG-34 and OQ-PRG-2 aligned. |
| 6 | AC-23 asserted a three-row ladder table that TR-PRG-023 never authored. | **APPLIED.** TR-PRG-023 now authors the table (moment / slice / gate owner / placement home) for Dash, Wall Jump and Double Jump. |
| 7 | The playtest codes had tokens and a sample size but **no elicitors** — a coder has no statement to code. | **APPLIED.** The coding table gains a per-code elicitor column (the SYS-01 script cannot elicit a point spend, a module's cost or a dimmed socket) and the qualifying-subset floor (fewer than 4 of 5 invalidates the run). |
| 8 | F-PRG-07's example said "the governor's chain 8 vs 6" — Governor-207 is the *frame* and never moves the chain. | **APPLIED.** The example names **Regulator-000**, with the frame/drive distinction printed inline. |
| 9 | Rider (c) quoted only the DEF-source clause, leaving TR-HD-006's test "a module-produced DEF is legal at MVP" standing. | **APPLIED.** Rider (c) is now a two-clause rider naming the test. |
| 10 | The UI requirements (focus order, screen-reader labels, generated effect text) had no AC and no named obligation. | **APPLIED.** Folded into AC-PRG-30 (which cites TR-PRG-027) — focus order, the name+role announcement, and the "an edited payload changes the row's text with no string edit" assertion. |

**Recommendations (10) — all applied:** AC-02 → `[GUT + LINT]` with the legend
extended; AC-06 cites AC-CSD-04 instead of duplicating SYS-15's surface; AC-21 names
the `GrantPort` mock boundary; AC-31 names the save-machine debug log as the
observation surface; AC-29 counts all five quantities (TR / formulas / V / ACs / edge
bullets / OQs / knobs); the qualifying-subset floor on AC-33/34/35; the smoke row's
GUT/LINT split printed (24 + 4 dual + 1); the index correction now names SYS-16's
OQ-SAV-11 `v1→v2` clause as needing the `v2→v3` fix; the unequip-never-heals clause
joins AC-09; OQ-PRG-4's target moves to before the SYS-02/SYS-24 stories.

## D. Repair commits

| Commit | Scope |
|---|---|
| `667d922` | the authored GDD (28 TR / 10 F / 12 V / 36 AC) |
| `3516bd8` | the CD pass-1 blocker (the pacing rate + the placed part) and its 8 recs |
| *(CD pass-2 recs)* | OQ#18, the 214 ceiling, the pass semantics, AC-08's count |
| *(creative + technical repairs)* | the 3 creative blockers, the 9 applied technical blockers, 15 recommendations, riders (d)/(e)/(f) |
| *(QA repairs)* | the 10 QA blockers and 10 recommendations |

## E. Counts (re-verified after every repair)

28 TR-PRG (001–028, no gaps) · 10 formulas (F-PRG-01–10) · 12 V-PRG · 36 ACs
(01–36) · 44 edge bullets · 8 OQ rows · 21 knob rows · gate manifest
**29 + 2 + 5 + 0 = 36** (smoke 24 GUT + 4 dual + 1 LINT; device 2; lock 5; VS 0).

## F. qa-lead spot-check

**Round 1 — FAIL (3 blockers, 5 advisories).** Blocker 1: the four-point ledger did
not re-derive against the roster's boss (60 HP ÷ chains 6/7/8/9/10 = 10/9/8/7/6, so
"no flip" was false for points 1 and 3). Blocker 2: `PACING_PASS_YIELD_MIN`'s safe
range 24–40 admitted yields that fail both authored bars. Blocker 3: TR-PRG-014(c)
still read "the pool cap" while F-PRG-06(c) had become the anti-stacking rule.
Advisories: AC-03's recompute count omitted `UNEQUIP`; TR-008 said six fixtures vs
AC-08's seven; AC-30's UI obligations were absent from TR-027; TR-005/AC-05 attributed
the archetypes to SYS-13; the review log pre-recorded a PASS.

**Round 2 — FAIL (4 blockers, 4 advisories).** The three blockers were genuinely
fixed and the counts reproduced. The new blockers: (1) AC-PRG-05 still said "SYS-13's
tier assignment (RM-03's pinned pair)"; (2) TR-PRG-005's repair **inverted** the
ownership seam (making tiers SYS-02's in one clause and SYS-13's in the next);
(3) the review log pre-recorded this seat's verdict and cited a §G that did not exist;
(4) the IP-5 closure row still named "the pool cap". All four repaired: the archetypes
are SYS-02's room data and the tiers are SYS-13's per archetype (the sentence and the
AC aligned); the log's gate record is now honest (this section); the closure row reads
"the no-stacking rule". Advisories applied: the ledger table moved out of TR-PRG-006's
bullet into its own block (a list-terminating table rendered the following paragraph
and test outside the TR); `BOSS_HP` 60 joins the cross-system inputs; AC-PRG-06 cites
the table instead of restating its columns; TR-PRG-027's test names the systems index's
SYS-24 entry instead of "the index correction".

**Round 3 — FAIL (1 blocker, 3 advisories).** Every substantive row was
APPLIED-CORRECTLY and the counts reproduced; the blocker was the **review log itself**
— §A's gate row and this section pre-recorded a round-3 PASS before the seat ran (the
round-2 defect relocated one round forward), and the commit message's claim that the
record "stops pre-recording verdicts" was false against its own diff. The record is
now written only after a seat returns: this paragraph exists because the seat returned
it. Advisories applied: TR-PRG-006's prose carries the boss/Warden summary inline so a
TR-scoped read finds it; AC-PRG-06 names the boss column explicitly so an edited table
cannot pass silently; TR-PRG-005's placement parenthetical re-attached; a `BOSS_HP`
change now re-derives the ledger and is flagged.

**Round 4 — PASS.** The seat returned PASS with every worklist row APPLIED-CORRECTLY,
the counts reproducing (28 TR / 10 F / 12 V / 36 AC / 44 edge bullets / 8 OQ / 21
knobs; 29 + 2 + 5 + 0 = 36), the touched arithmetic re-deriving (the boss 10/9/8/7/6,
the Warden 4/4/3/3/3, 30 per pass, 120 + 40 = 160), and no collateral damage. Its five
advisories are applied: this section's gate rows now name only returned verdicts and
count rounds 1–3 as FAILs; AC-PRG-06 pins the Warden column as well as the boss's; the
boss/Warden summary is stated once (in TR-PRG-006) and the ledger block points at it;
and "met at seven, finished at six" is named as the **post-boss** build rather than a
same-fight claim (OQ-PRG-6 owns whether the fourth point is spendable).

## G. Final micro-check

**Round 1 — FAIL (1 blocker).** TR-PRG-006 still compressed the ledger into a
same-fight claim ("meets the boss at seven chains and finishes it at six") while the
ledger block had been qualified as the post-boss build and then deferred to TR-PRG-006
as the authority — the fact existed twice with two subjects. **Repaired:** the authority
states two builds with two subjects, the ledger block reduces to a pointer, and
AC-PRG-06's column order matches the table.

**Round 2 — PASS (zero blockers).** The blocker is resolved; the arithmetic re-derives
(boss 10/9/8/7/6, Warden 4/4/3/3/3, Husk 1×5, Spitter 2×5, `attack = 100 + 8·p`); the
counts are unmoved and still sum (28 / 10 / 12 / 36 / 44 / 8 / 21; 29 + 2 + 5 + 0 = 36,
with 24 GUT + 4 dual + 1 LINT); the cross-references resolve; no placeholder. **The
document is closed at this point** (the lane contract: "then stop; do not reopen").

**Deferred advisories (non-blocking, recorded not applied — the document is closed):**
(1) the prose "10/9/8/7/6" is the only boss-chain figure a `BOSS_HP` change would not
re-derive automatically (the clause covers the table); (2) two consecutive pointers to
the same fixture could be one; (3) AC-PRG-06 pins the Warden and boss columns but leaves
the Husk/Spitter to "cell for cell". All three are cosmetic or covered by the
re-derivation clause; none blocks a story.

## I. CodeRabbit (PR #81) — one pass, one batch, six threads, all resolved

| # | Class | Finding | Disposition |
|---|---|---|---|
| 1 | Major | The pool-only fallback would strand the Coupler-dependent ACs (the catalogue, the pair, the trade rubric) — it cannot pass the gates as a data-only change. | **APPLIED.** TR-PRG-013's fallback names its **conditional criteria** (one frame entry; AC-PRG-19 and AC-PRG-35 vacated with the Coupler; AC-PRG-14's table becomes the two frame states; AC-PRG-32's G5 still runs), and AC-PRG-18 carries the fallback clause. |
| 2 | Minor | A grant recorded while SYS-06 is absent never reaches a consumer that starts later — the latch blocks re-publication, not re-application. | **APPLIED.** TR-PRG-022 states the reader contract (a consumer reads the persisted set at init/restore and applies each grant without a new event); AC-PRG-22 gains the late-consumer fixture. |
| 3 | Major | Unequipping one slot cleared the other — BUILT had no defined partial exit. | **APPLIED.** The loadout table's EMPTY/BUILT transitions are corrected (BUILT → FRAMED on `UNEQUIP(drive)`, → DRIVEN on `UNEQUIP(frame)`), transition law 2 states it, AC-PRG-15 gains the unequip fixture. |
| 4 | Minor | The formulas use inline variables rather than the rule's variable tables. | **REBUTTED.** The requirement's substance (types, ranges, an Output clause, a worked example) is met in all ten; every APPROVED, merged GDD in this corpus uses the inline form (`health-damage.md`, `cache-stations-death.md`, `seam-borders.md`, `enemy-ai-telegraphs.md`), and a late ten-formula reformat carries arithmetic-drift risk. Recorded here, not silently skipped. |
| 5 | Major | **`hp_max_delta` summed only frame modules**, so the Coupler's `−8` never reached the aggregate and the exchange was unpayable. | **APPLIED — a real defect the three seats and both spot-checks missed.** F-PRG-05 now sums **both** slots (`Σ {m.hp_max : m equipped}`); AC-PRG-15 gains the aggregate fixture (Coupler `−8`, Coupler+Governor `−6`, Regulator+Governor `+2`), which matches the budget table's rows exactly. |
| 6 | Major | **The closed Regulator + a frame fails term (b)** (`Δhp −4` vs the required `−6`), so the closure's "zero exceptions" claim was false for that pair. | **APPLIED — and it followed from #5.** F-PRG-07's closure now states the **refusal**: the paid module alone passes; the paid module with a frame is refused at equip with the shortfall printed. The closure narrows the loadout rather than raising the derived `MODULE_DAMAGE_HP_COST` (which V-PRG-06 forbids). AC-PRG-17 asserts both arms. |

**Outcome:** 6 threads, **5 applied, 1 rebutted, 0 deferred, 0 unresolved**. All five CI
checks green at head `0501aa5`; CodeRabbit SUCCESS. **The merge is not taken by this
lane** — the contract merges only after the sync lands, and merge authority is the
orchestrator's.

## H. The one item for the orchestrator / user

**F-HD-10's module-build note — a reading, a rider request, and a pre-authorised
fallback** (technical seat blocker 2; TR-PRG-013; rider (d)).

- **The clause**: SYS-07's F-HD-10 says "a module build (a non-zero `damage_bonus`) is
  measured against the parity bands (V-HD-14), not this envelope — a module's damage is
  a situational source, not a TTK-ruler input."
- **This lane's reading**: the sentence names the *ruler* (the sustained-damage
  comparison, not the kill-count envelope) and calls module damage *situational*; the
  ±10% ceiling itself is TR-HD-034/F-HD-13's, whose subject is the **weapon set**.
- **Why it matters**: read as a hard ±10% ceiling on gear, **no damage lever can exist**
  at the 20-HP baseline (the integral must stay ≤ 642 → chain ≤ 6.58 → no integer
  damage step), which would make D-1's gear layer impossible — two user decisions
  (D-1 and D-7) in collision.
- **What the lane did**: recorded the reading in the GDD, requested rider (d), and
  **pre-authorised the pool-only fallback** as a data switch (no redesign): if the
  ceiling reading is upheld, `WINDOW_EXCEPTION_ENABLED` → false and the drive payload
  is withdrawn.
- **What is needed**: the orchestrator batches either (i) rider (d) at SYS-07's next
  doc touch (the reading stands; the gear layer ships as authored), or (ii) the ceiling
  reading upheld (the fallback executes). **No edit to SYS-07 is taken either way.**
