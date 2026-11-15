# SYS-15 Cache Stations & Death-as-Story — review log

> **Document**: `design/gdd/cache-stations-death.md` · **Lane**: SYS-15 · **Branch**: `docs/sys15-cache-stations-death`
> **Opened**: 2026-11-15 · **Prompt**: `lanes/SYS-15.md` v1.0.0 / `85701ea84621` (matches manifest: yes)
> **Base SHA**: `9e20653ec52a0d459efe6b38ac80dac6876413f7` (ancestry verified: `git merge-base --is-ancestor` → OK)
> **Seat routing**: CD + creative → `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`; technical + QA + spot-check → `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`. The lane itself runs on the manifest model (GLM — a creative lane on GLM, as required).

## 1. Context + feasibility brief (the authoring gate's input)

**Consumed contracts** (the named set; each read once):

| Contract | Status | What SYS-15 consumes |
|---|---|---|
| SYS-07 `health-damage.md` | APPROVED 2026-11-12 | TR-HD-023 (no auto-respawn; the three-option contract — RECONSTRUCT AT THE NEURAL TERMINAL / DRAW THE RESTORE MODULE / QUIT; the screen, the cause row and the counter are SYS-15's), TR-HD-024 (the reconstruct reset; no respawn i-frames at MVP), TR-HD-025 (the module: first-cache grant, cap 1, 50 % + `REVIVE_IFRAME_MS` 1000, the record archived), TR-HD-032 (the cache restore; the save stores no HP), TR-HD-015 (the `DeathRecord` — the cause row's input), TR-HD-035 (the read contract), **OQ#8 — the System Offline screen: SYS-15's obligation at this authoring** (SYS-28 co-owner for the copy), OQ#16 (VS — in-place respawn grants) |
| SYS-03 `save-serialization.md` | APPROVED 2026-11-14 | TR-SAV-004 + **OQ-SAV-10 — the `cache` namespace's shape is SYS-15's to fill; the key appears at the v1→v2 bump**, TR-SAV-011 (slots `auto` on the station ack + the suspension/close events; `manual_1` on the explicit action; no timer — **OQ-SAV-4: SYS-15 ratifies the station trigger at its authoring**), `save_completed(slot, tick, bytes, hash)` = the MEMORY CACHED print's input (SYS-03 owns the record, never the words), the language law (SYS-15 never speaks of "slots" to the player), the absent-namespace default (counter 0, no cache active), SYS-03's review-deferred decision: the flip-completion moment as an event-autosave candidate |
| SYS-05 `game-flow-session.md` | **NOT landed** — consumed as pre-shaped via the systems-index row + the recorded contract inputs | The context machine (Gameplay / Paused / Reading / Cache-terminal / Death-respawn / Loading; the TRANSITION context never entered at MVP); the one-context-at-a-time law; SYS-05 owns the refusal flow's navigation (OQ-SAV-7), the load flow and quit; `restore_complete` strictly before `load_complete` |
| SYS-02 `room-world-structure.md` | APPROVED 2026-11-13 | RM-04 The Sanctum holds the one MVP terminal (`CACHE`, Class A ≤ 6 — SYS-02 places and prompts, **SYS-15 owns the terminal's surface**; the Reading context is SYS-05's; the request is the ADR's non-ack row); TR-RWS-011 (the reconstruct boundary — **SYS-15 increments the designation counter, never SYS-02**); TR-RWS-025 (the counter + the cache activation are SYS-15's save sources); the terminal anchor in room data; **OQ-RWS-4's release gate — `last_grounded_safe_pos` (room-scoped, updated every grounded tick outside hazards, re-initialized to the exit anchor on every swap) must be ratified by SYS-07/SYS-15 before the pit and the module revive co-ship** |
| SYS-29 `juice-feedback.md` | APPROVED 2026-11-13 | TR-JCE-027 (the death power-down + the revive boot edges; **the single duck request −6 dB held `UNTIL_OFFLINE_EXIT`, released on the offline exits; OQ-J7 ratified by SYS-04** — no longer provisional), the death-beat glitch component into SYS-15's screen, the shared print row (one slot, newest replaces), the world-time law (**the offline screen's presentation is context-time, never world time**), the shake law (a request raised outside Gameplay is dropped — no world to shake on the offline surface) |
| SYS-04 `audio-core.md` | APPROVED 2026-11-14 | The no-duck law (exactly one duck family — the death beat); the death power-down / revive boot sounds designed against SYS-29's edges; **SYS-15's offline screen lifetime backs the duck's release** |
| SYS-01 `input-control-mapping.md` | APPROVED | The ratified gate-source rows: **Cache-terminal** (buffers cleared at entry; controls owner = the SYS-15 terminal menu; exit = leave control → Gameplay) and **Death/respawn** (buffers cleared at death entry; controls owner = the SYS-07/SYS-15 respawn flow; exit = respawn complete → Gameplay); the Prompt Slot law (TR-INP-030 — Interact means the lit bubble; no walk-by saves; TR-INP-075 custody; TR-INP-029 body availability); the a11y baseline (the label is the accessible name; ≥ 48 dp targets; wall-clock UI-feel timers per TR-INP-061) |
| `game-concept.md` | the game's own doc | Pillar **"Remade Every Death"** — death is story: cache stations, body reconstruction, the incrementing name counter; the design test (a plain "YOU DIED" screen → redesign it); SotN's save-sanctuary texture; the diegetic serial numbers (the counter stamped on her chassis; MEMORY CACHED as printed output); the concept OQ — does the demon lord ever address the death-counter number as a story hook |
| Benchmark audit **IP-6** | recorded rider | "Write the cache-adjacency doctrine into SYS-15 (terminals at epoch-shift thresholds + boss gates as the map scales); open the fast-travel question as a Full-Vision OQ (unowned today — the hub may make it moot)" |

**The lane's five obligations** (the lane brief): ① MEMORY CACHED — the interaction, the checkpoint semantics, the respawn point, the designation increment, the save trigger. ② Death-as-story — the death loop's fiction, the reconstruction beat, the System Offline contract to SYS-07, the training-point surface, the no-punishment law. ③ The cache-adjacency doctrine (IP-6). ④ The fast-travel OQ — Full-Vision only; record the decision, do not build it. ⑤ The save/flow contract — cache → SYS-03, cache → SYS-05, the death → offline → revive handshake, the missing-input failure paths.

**Rulings this lane makes at authoring** (each named in the GDD):

| # | Ruling | Consumes |
|---|---|---|
| R1 | The `cache` namespace = `{designations: int ≥ 0, activated_caches: [id…] (ordered, append-only)}`; `active_cache` is **derived** (the list's last entry — store sources, derive targets); the v1→v2 bump `M_1` adds the key with the conservative default `{0, []}` | OQ-SAV-10 |
| R2 | The station trigger ratified as-is: the event set `{station ack, desktop quit, Android onStop, iOS application-paused}`; **no fifth event** — the flip-completion autosave candidate is **DECLINED at MVP** (the close/suspension events already preserve the post-flip state on every normal exit; a fifth event is a code change with a migration review per TR-SAV-011; the terminal stays the only in-session diegetic save surface); VS candidate beside the station multiplication | OQ-SAV-4 + SYS-03's deferred decision |
| R3 | The revive placement (OQ-RWS-4 **ratified**): `revive_placement = last_grounded_safe_pos` iff `cause_kind = ENVIRONMENT`; otherwise the death spot (TR-HD-025's "on the spot" stands for attack deaths); the void has no spot — an on-the-spot pit revive would re-fall through i-frames (TR-HD-018's bypass). The release gate is satisfied by this GDD + the implementation story | OQ-RWS-4, TR-HD-018/025 |
| R4 | The designation counter counts **reconstructions and revives** (exactly one increment per resolved death, at the named tick per path: revive = the revive tick; reconstruct = the first logic tick after `load_complete`, before control returns — the restore must never erase the increment); never decrements; resets only on an explicit new game; persists across quit/reload through the v2 namespace (the named gate) | OQ#8, TR-HD-023/025, TR-RWS-011 |
| R5 | The module faucet is **per-station first-activation**: fires iff `station ∉ activated_caches ∧ restore_modules < cap`; the station joins `activated_caches` on every activation regardless of the grant; at MVP's single station the two readings of SYS-07's "first cache activation" are identical; revisiting never re-fires (the farm shutdown holds) | TR-HD-025/032 |
| R6 | The pre-cache reconstruct (no save present): routes through SYS-05's new-game initialization; the post-resume increment still applies — the stamp reads 001 after each such reconstruct; the count becomes permanent from the first station activation (the first save) onward | TR-HD-023, TR-SAV-020 (`REFUSE_ABSENT`) |
| R7 | The offline screen's options unlock after `OFFLINE_HOLD_MS` 400 [250, 800] (wall-clock UI-feel per TR-INP-061); the DEATH state itself is never time-limited (TR-HD-023's "stays DEAD indefinitely" consumed) | TR-JCE-026/027, TR-INP-061 |
| R8 | The cause row prints from the `DeathRecord` in diegetic diagnostics voice (the strike's `display_name`, the kind, the tick); an unreadable record prints the generic fault row + one telemetry record — the options still function (never a crash, never a silent skip) | TR-HD-015, TR-CMB-028's `display_name` |
| R9 | `save_failed(code)` prints the terminal's fault row — **never MEMORY CACHED** (the first lie would be the print); the session continues unsaved; the player may re-ack (a new request with a new snapshot) | TR-SAV-010/017 |
| R10 | The adjacency doctrine: "a terminal stands where the truth turns, and at the gate you cannot pass" — every epoch-shift threshold room and every boss-gate staging threshold carries a terminal as the map scales; the MVP instance is RM-04 (the threshold room itself — the doctrine's seed); the walk-back is the only cost of death and it must cross at most one threshold-scale segment | IP-6 |
| R11 | Fast travel: the Full-Vision OQ opened, unowned, **not built at MVP** — no knob, no AC, no design surface (IP-6 verbatim; the hub may make it moot) | IP-6 |
| R12 | The duck's release fires on **every** offline-screen exit — reconstruct, revive, and quit (the hold's registered value `UNTIL_OFFLINE_EXIT` already covers it; the registry note's "both exits" names the two Gameplay-returning exits; the sync request adds the quit-exit rider to the note) | `duck_request_contract`, TR-JCE-027 |

**Feasibility**: no hard blockers. Every dependency is landed (SYS-01/02/03/04/07/29) or explicitly pre-shaped/waived (SYS-05 — ratified at authoring per the manifest's `dependency_note`). No frozen contract requires revision; SYS-28 (the copy's co-owner) is not landed, so the copy is authored at contract level and the co-ownership is recorded for SYS-28's authoring.

## 2. Section plan (as drafted)

1. Header + Overview — the terminal where the machine caches you; the death that is a sentence you can finish.
2. Player Fantasy — the named fantasy ("You Are a Copy, and the Copy Counts"); the anchors (The Print, The Remake, The Second Life); the language law (never "slots", never "checkpoint"; the cache voice).
3. Detailed Design — four rule groups, 20 TR-CSD:
   - §1 The station and its surfaces (TR-CSD-001…007)
   - §2 Death-as-story (TR-CSD-008…015)
   - §3 The save contract (TR-CSD-016…018)
   - §4 The doctrine and the OQ (TR-CSD-019…020)
4. States and transitions — the offline screen's options machine + the terminal surface's states.
5. Interactions + consumed-contracts ratification.
6. Formulas — F-CSD-01…04 (designation_next, revive_placement, module_faucet, cache_defaults).
7. Edge cases.
8. Validation invariants — V-CSD-01…07.
9. Tuning knobs — `OFFLINE_HOLD_MS`, `DESIGNATION_PRINT_DIGITS`.
10. Visual/Audio + UI requirements.
11. Acceptance criteria — 26 ACs; gate partition smoke 21 (19 GUT + 2 LINT) · device 3 · lock 2 · VS 0.
12. Open questions.

*(The gate trail follows in §3+. Section drafts were written to file as authored; the transcript presents the brief and the section summaries.)*

## 3. Gate trail

### 3.1 CD gate (CD-GDD-ALIGN)

**Fallback recorded (contract §3.6):** this harness session has no nested-subagent tool; every seat ran as a separate in-session pass with the seat's neutral brief, reading the document once in full from disk. The per-seat model routing (GLM/DS) could not be honored — all passes ran on the lane's GLM model. No seat was skipped.

**Run 1 — verdict: CONCERNS (1 blocker, 2 one-line defects).**

| # | Finding | Class | Disposition |
|---|---|---|---|
| CD-1 | Anchor 1 (The Print) wrote "The world's noise ducks under a held −6 dB of terminal hush" — a **station duck**, contradicting the no-duck law the same document consumes (exactly one duck family: the death beat, `duck_request_contract`'s "one family in the game") and contradicting the anchor's own parenthetical | Blocker (contract conflict + internal contradiction) | **APPLIED** — the anchor rewritten: no duck at the station; the hush is the threshold room's ambient bed (SYS-04's design), never a duck request; the no-duck clause made explicit |
| CD-2 | The adjacency doctrine attributed "~10–14 stations" to "the audit's scale" — the audit's IP-6 names no count; the figure is the doctrine's own extrapolation | One-line precision defect | **APPLIED** — reworded to "the doctrine's extrapolation at the audit's scope, tunable per zone pass" |
| CD-3 | The pre-cache fallback: the reconstruct option's words name "the neural terminal" but the fallback wakes at the boot anchor — a words-vs-place gap the document left implicit | One-line clarification | **APPLIED** — TR-CSD-014 names the fallback's placement (the boot anchor, the machine's raw print), keeps SYS-07's verbatim words, and states the fiction's hold-by-omission |

**Run 2 (post-repair) — verdict: APPROVED (zero blockers).** Pillar service ✓ (MEMORY CACHED → SotN's save-sanctuary texture + Remade Every Death's beat; the doctrine → One World, Two Truths). Anti-pillars ✓ (no timers — the hold is presentation, explicitly framed; no stat-spreadsheet — two diegetic spend rows; no helpless horror; no twitch gauntlets). Player fantasy ✓ ("You Are a Copy, and the Copy Counts" — the concept's diegetic serial-number doctrine). Scope ✓ (one MVP station; the doctrine is doctrine; fast travel opened-not-built; VS items in OQs). Contract alignment ✓ (the five rulings are ratifications the consumed contracts assigned to SYS-15; no frozen contract edited; SYS-05's pre-shaped contract ratified at authoring per the manifest's `dependency_note`). Tone/voice ✓ (the print voice; the lowercase ruling stands; the language law bans the banned nouns).

### 3.2 Three-seat panel

**Fallback (§3.6) applies to all three seats** (no nested-subagent tool; separate in-session passes; the model routing unrecorded per seat — all GLM).

| Seat | Verdict | Blockers |
|---|---|---|
| Creative | **NEEDS REVISION** | 1 |
| Technical | **NEEDS REVISION** | 3 |
| QA | **NEEDS REVISION** | 2 |

### 3.3 Repair worklist — every blocker, dispositioned

#### Creative

| # | Blocker | Disposition |
|---|---|---|
| C1 | The designation increment is invisible on the revive path: the reconstruct path prints the new number at the terminal (TR-CSD-014), but the revive path returns to Gameplay on the spot with no acknowledgment — the pillar's scar goes unwitnessed on one of the two death paths, and D-CSD-2's inclusion token "the number" is unreachable for revive-only testers | **APPLIED.** TR-CSD-015 gains the exit print: the revive's exit prints the new designation row in Gameplay (the machine's acknowledgment — the same print-slot family as MEMORY CACHED, driven by SYS-15's own increment event); AC-CSD-15's THEN gains the print clause. One line, non-gating, uses the existing surface. |

Creative recommendations: (1) the options' focus order (reconstruct → revive → quit) already puts the common choice first — **noted, no change**; (2) RE-CACHE's near-null texture — **already recorded as intentional** (TR-CSD-005); (3) the success signature's "nobody describes the death screen as a game over" — **kept** (it is the D-CSD-2 exclusion set's positive form).

#### Technical

| # | Blocker | Disposition |
|---|---|---|
| T1 | The ack's stated order — save request (a) **then** context (b), with the activation at the gate-entry phase — lets the first-activation snapshot execute at the request tick **before** the faucet appends the station: the first save captures `activated_caches: []`; a crash + reload re-fires the faucet (a module farm) and the first save is a lie about the activation | **APPLIED.** TR-CSD-002's ack order is now three steps: (a) **the activation applies at the ack's resolution tick** (the faucet evaluates, the record appends — the namespace write precedes the snapshot), (b) the save request raises (the snapshot captures the post-activation state), (c) the context request raises (non-ack queued). TR-CSD-007 splits the timing: the faucet + the record at the ack's resolution, the body restore at the gate-entry phase. AC-CSD-01's THEN asserts the ordering. |
| T2 | V-CSD-02 read "exactly one increment per resolved death … never neither" while the same row's parenthetical excepts quit (which increments nothing) — the invariant contradicts its own exception | **APPLIED.** The invariant now reads: exactly one increment per death resolved by reconstruct or revive — never both, never neither on those paths; a quit-resolved death increments nothing (the exception is the law). |
| T3 | The document is silent on its envelope position — the house not-join pattern (SYS-02's "envelope not-join", SYS-03's "does not join the gameplay-tick envelope") is missing, leaving an implementable ambiguity about per-tick work | **APPLIED.** The Detailed Design intro gains the not-join: SYS-15 prices event budgets, not a tick budget — the screens are context-time presentation with no gameplay-tick work; the counter's write is one integer write at two named events; the namespace's snapshot cost is SYS-03's bounded-constant budget (TR-SAV-012 consumed). |

Technical recommendations: (1) F-CSD-03's set-union notation on an ordered list → **APPLIED** (append-if-absent wording); (2) the SYS-03 bump rider (CURRENT=2 / MIGRATIONS[1] registration is SYS-03's schema fact; the frozen GDD's "zero migrations at MVP" posture line goes stale at the bump's landing) → **APPLIED as the OQ-M1-pattern rider** (TR-CSD-016 + OQ-CSD-9; the sync request carries the SYS-03 doc-touch note); (3) AC-CSD-18's v0 clause overlaps SYS-03's AC-SAV-17 — **kept** (it is the bump's boundary arm, not a duplicate fixture).

#### QA

| # | Blocker | Disposition |
|---|---|---|
| Q1 | The Core Rules intro promises "PROVISIONAL marks" but no TR carries the mark — a phantom convention (the no-placeholder bar) | **APPLIED.** The intro reworded: no MVP TR is provisional; the not-yet-landed consumers (SYS-05, SYS-24, SYS-28) are named as pre-shaped in the Interactions table, which is where their status lives. |
| Q2 | AC-CSD-25 has no denominator: a tester who never dies in 30 minutes cannot feed a "≥ 3/5" bar honestly | **APPLIED.** The AC gains the denominator: the testers who experienced ≥ 1 death **and** ≥ 1 station visit; a tester with neither is recorded, not counted. |

QA recommendations: (1) the OQ table gains OQ-CSD-9 (the SYS-03 bump rider) — **APPLIED** (header count 8 → 9 OQ rows, everywhere reproduced); (2) AC-CSD-16's "third arm" phrasing — **kept** (it is the AC's named third GIVEN arm); (3) AC-CSD-24's v2 dependency — **kept and named** (the namespace ships with SYS-15's implementation stories; the AC runs at the device gate).

**Repair commit**: `c0d967a` — `docs(sys15): repair the three-seat blockers (SYS-15, cache-stations-death)`. The repair diff (`24d9c33..c0d967a`) covers the CD-gate repairs (CD-1/2/3) and the panel repairs (C1, T1–T3, Q1, Q2 + the two applied recommendations).

### 3.4 Mandatory qa-lead spot-check (on the repair diff)

**Verdict: PASS (11/11 rows APPLIED-CORRECTLY; zero blockers).**

| Row | Verdict | Note |
|---|---|---|
| CD-1 (the station duck) | APPLIED-CORRECTLY | the anchor's no-duck clause is explicit; the ambient-bed framing stays inside SYS-04's design space |
| CD-2 (the attribution) | APPLIED-CORRECTLY | the figure is now the doctrine's own extrapolation |
| CD-3 (the fallback's placement) | APPLIED-CORRECTLY | the boot anchor named; SYS-07's verbatim words preserved |
| C1 (the revive-path print) | APPLIED-CORRECTLY | TR-CSD-015's exit print + AC-CSD-15's clause; the print-slot family named |
| T1 (the ack's three-step order) | APPLIED-CORRECTLY | TR-CSD-002 + TR-CSD-007 + AC-CSD-01 + the body-busy edge row (the T1 ripple, in scope) all consistent; the snapshot can never precede the activation append |
| T2 (V-CSD-02) | APPLIED-CORRECTLY | the invariant and its quit exception no longer contradict |
| T3 (the not-join) | APPLIED-CORRECTLY | the intro's envelope clause; no tick-budget claim exists anywhere |
| Q1 (the phantom PROVISIONAL) | APPLIED-CORRECTLY | the intro reworded; the pre-shaped status lives in Interactions |
| Q2 (the denominator) | APPLIED-CORRECTLY | AC-CSD-25's denominator clause; the died-but-never-stationed tester codes D-CSD-2 only |
| TR-a (F-CSD-03's notation) | APPLIED-CORRECTLY | append-if-absent wording |
| TR-b + OQ-9 (the bump rider) | APPLIED-CORRECTLY | TR-CSD-016's rider + OQ-CSD-9 + the header count |

**No collateral damage**: the diff touches only the intended regions; the counts reproduce (20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0); every touched cross-reference resolves; no new placeholder; the gate record matches the diff. **Arithmetic**: the header's 9 OQ rows = the table's 9 rows.

### 3.5 Final micro-check (diff-scoped, blockers only)

**Verdict: PASS — zero blockers.** A fresh pass over the last repair delta found no blocker-class defect in the changed regions. Two non-blocking advisories recorded (no change applied — the document is closed):

1. TR-CSD-004's "The print fires only on SYS-03's `save_completed` record" is scoped by its own TR title (the MEMORY CACHED print); TR-CSD-015's designation print is a separate row in the same print-slot family — a strict reader may want the "only" scoped by name at SYS-24's authoring (advisory, non-gating).
2. The sync request must carry two riders: the `duck_request_contract` note's quit-exit addition and the SYS-03 doc-touch note (OQ-CSD-9) — both are in the lane report.

**The gate trail is complete: CD CONCERNS→repaired→APPROVED · creative NEEDS REVISION(1)→repaired · technical NEEDS REVISION(3)→repaired · QA NEEDS REVISION(2)→repaired · spot-check PASS · micro-check PASS.**

## 4. CodeRabbit pass — PR #59 (1 pass, 8 threads; all applied; fix commit `e5cea0d`)

The pass ran on the PR head `0798862` (6m48s; check PASS). 8 inline threads, **3 Major + 5 Minor. Triage: 8 applied, 0 rebutted** — every finding verified against the current document before the fix; none required reopening a closed design decision (two superseded this lane's own authoring-time rulings — R6's pre-cache stamp behavior and the ledger's unscoped baseline — both toward stricter internal consistency; recorded here, the rulings' original text stands as history in §1).

| # | ID | Severity | Finding (verified) | Disposition |
|---|---|---|---|---|
| CR-1 | 4576675790 | Minor | The reconstruct during an in-flight first station write reads `REFUSE_ABSENT` → the fallback wipes the activation (contradicts the ledger's "never, within a run") | **APPLIED.** TR-CSD-014: the reconstruct's load **queues behind any in-flight same-slot write** (SYS-03's transition law 1 consumed) and reads the committed post-activation state — an activated run's reconstruct can never observe `REFUSE_ABSENT` because of its own in-flight save; the load's target named (the `auto` slot); the edge-case row added; AC-CSD-16's fourth arm is the fixture. Also covered: a *failed* first write (never committed) → the fallback **carries the namespace** (with CR-2's fix), so the activation survives there too — no farm window |
| CR-2 | 4576675796 | **Major** | The restore erases *accumulated* unsaved increments (saved 3, live 4 after an unsaved revive, reconstruct → restore 3 +1 = 4 — two deaths, +1; the live count transiently drops, violating V-CSD-01) — and the pre-cache fallback reset the stamp to 001 each time, contradicting "resets only on an explicit new game" | **APPLIED.** **The carry law:** the reconstruct captures the live `designations` at the choice, re-applies it after the restore (the store never lowers the live count), then increments — the saved value seeds only a fresh session load. F-CSD-01 rewritten (`L`/`S` variables; example 3 is the accumulated case → 5). TR-CSD-011's laws + AC-CSD-10's fixture (both values stated; the spy asserts the store never reads below the captured live value) + AC-CSD-16's fallback arm (the stamp accumulates across pre-cache reconstructs). **Supersedes the authoring-time ruling R6** (recorded; the carry is stricter and now consistent with TR-CSD-011/014/V-CSD-01) |
| CR-3 | 4576675803 | **Major** | The ledger's "survives death" lacked the restore baseline: world truth and progress accumulated after the last save revert *with the restore* (the reconstruct is a load of the last save); AC-CSD-11's "unchanged" had no named baseline | **APPLIED.** TR-CSD-013 gains the **two-baseline law**: store-carried state restores from the last station save (post-save progress reverts with the restore — the record is what the reboot prints from); store-absent state (the body) restores from the live session (the load never touches it). The table's rows carry their baselines; TR-CSD-014 names the baseline; AC-CSD-11 asserts "equal to the loaded save's values" + the carry for the counter. Consistent with SYS-02's TR-RWS-011 (truth persists *through* loads — it is restored, never wiped) and SYS-07's quit edge (the cache is the checkpoint of record) |
| CR-4 | 4576675805 | Minor | `active_cache` = the first-activation list's last entry ≠ "the last cache": a revisit to an earlier station left the respawn at the *newer* station | **APPLIED.** The respawn rule is **most-recent-activation**: `activated_caches` is ordered by most recent activation (a revisit **moves** the id to the end; ids are never removed); the faucet's membership test is unaffected; `active_cache` = the list's last entry = the most recently activated station. TR-CSD-016's list law, TR-CSD-017 + F-CSD-03's record wording (append/move), TR-CSD-014's derivation, the revisit edge-case row, AC-CSD-13's move clause, F-CSD-03's variable table + examples |
| CR-5 | 4576675807 | Minor | F-CSD-04 lacked a Variables table / Output Range (the house formula template) | **APPLIED.** F-CSD-04 gains the Variables table (the two fields + the result) and an Output Range clause; its "(b) new-game initialization" case is scoped to an **explicit** new game (consistent with CR-2's fallback carry) |
| CR-6 | 4576675812 | Minor | AC-CSD-05 bound the faucet evaluation to the gate-entry phase, contradicting TR-CSD-002(a)/TR-CSD-007's ack-resolution-tick placement — the fixture would not check the snapshot-critical timing | **APPLIED.** AC-CSD-05's WHEN splits the two timings per the review's suggestion: the faucet at the ack's resolution tick (before the save request raises), the body restore at gate entry — both before the menu is interactive |
| CR-7 | 4576675818 | **Major** | AC-CSD-19's closed four-cause set contradicted AC-CSD-03's `cause = player` (an implementation passing one fails the other) | **APPLIED.** AC-CSD-19 is scoped to the **automatic** save requests' causes (the closed four-event set), states the manual request's cause is exactly `player` (TR-CSD-005 cited alongside TR-CSD-002), and the no-fifth-event condition names automatic events |
| CR-8 | 4576675825 | Minor | AC-CSD-25 had two conflicting denominator rules (both-events eligibility vs the died-only D-CSD-2 carve-out) | **APPLIED.** One denominator per code, stated separately: D-CSD-1's bar is over the testers with ≥ 1 station visit; D-CSD-2's bar is over the testers with ≥ 1 death; a tester with neither counts for neither |

**Counts after the batch: unchanged** — 20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0 (the new fixtures fold into AC-CSD-16's arms; no AC added or removed). The mechanical audit re-run: every cited AC/TR/F/V/OQ resolves; zero stale "stamp reads 001"/"append-only" references remain.

## 5. The confirm pass (the fresh CodeRabbit run on `e5cea0d`/`57b1e18`) — 4 new findings + 1 follow-up; 4 applied, 1 rebutted

The fresh pass (6m8s, all checks green) posted 3 new Major findings, 1 Minor, and 1 follow-up on an existing thread; it also **resolved its own ledger thread** (4576696392) — "I overstated the rollback: body progress is currently session-only" — confirming CR-3's fix was correct as applied. Per the contract's confirm-pass rule (a Major-class fix batch), this batch runs once more.

| # | ID | Severity | Finding (verified) | Disposition |
|---|---|---|---|---|
| CR-9 | 4576710019 + the 4576695897 follow-up | **Major** | The specified sequence (swap to the saved value, then re-apply the live value) exposes an intermediate store state (4 → 3 → 4), contradicting AC-CSD-10's "never reads below 4" | **APPLIED.** The carry is now **atomic with the restore**: the live namespace state composes into SYS-03's staging namespace **before the single atomic swap** (SYS-03's staging-swap architecture consumed) — there is no tick where the store reads the bare restored value. TR-CSD-012's branch a, F-CSD-01's branch a + the `L`/`S` variable rows + the worked examples rewritten (the compose wording), AC-CSD-10's fixture asserts zero intermediate reads |
| CR-10 | 4576710024 | **Major** | The namespace's record reverts with the restore: station A saved, station B activated (module granted), B's save failed → the reconstruct loads A's older record → B is lost while the module survives → a later B activation re-grants | **APPLIED.** The carry is **namespace-wide**: the whole live `cache` namespace (both keys, with the record's most-recent-activation ordering) composes across the restore — the live record is a superset of any saved record, so no activation can be lost and the faucet can never re-fire. TR-CSD-013's law upgraded from two-baseline to **three-baseline** (world truth stays save-bounded — the designed checkpoint rollback; the namespace is live-carried — the monotone laws make a rollback a data loss + a farm vector; the body stays live-carried); TR-CSD-014's baseline sentence; AC-CSD-11 asserts the carried-live namespace |
| CR-11 | 4576710028 | **Major** | A suspension save can commit before the first activation: the reconstruct's load succeeds with `activated_caches` empty — no terminal anchor exists and the `REFUSE_ABSENT` fallback does not apply | **APPLIED.** TR-CSD-014 gains the **empty-record spawn rule**: a successfully loaded save with an empty record spawns the body at the session's boot anchor (the machine's raw print — the fallback's placement rule without the initialization; the world loads as saved); AC-CSD-16's fifth arm is the fixture |
| CR-12 | 4576713320 | Minor | The duck released only after `load_complete`: a stalled or refused reconstruct load holds the duck through loading — TR-CSD-009 requires the release at the screen exit | **APPLIED.** TR-CSD-014's beat sequence now releases the duck **at the offline screen's exit** (the exit's event, never later — TR-CSD-009's all-exits law consumed); the state machine's RESOLVED(reconstruct) row carries the same clause; a stall or refusal cannot hold the duck |
| CR-13 | 4576695622 (the follow-up on CR-5's thread) | Minor | The four formulas "still omit the required opening, `The [formula_name] formula is defined as:`" (the design-system skill's template learning) | **REBUTTED.** The house standard is the **landed corpus**, not the skill snippet: no APPROVED GDD uses the opener — SYS-03's F-SAV-01..04 and SYS-07's F-HD-01..15 (both reviewed by this same machinery and approved) open with the named expression directly under the `#### F-XXX · name — tagline (TR)` heading, then Variables / Output Range / worked examples — exactly this document's structure. Adopting the opener here would make SYS-15 the corpus's only deviant and would need a corpus-wide template decision (a design-system skill alignment question for the framework's owner, not a single-document edit). The finding's substance (the missing variable table + output range) was applied in `e5cea0d` |

**Counts after the confirm batch: unchanged** — 20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0. The mechanical audit re-run clean (all IDs resolve; zero stale phrasings).

## 6. The confirm pass's findings (the run on `9db1ae7`) — 2 new findings; 2 applied

The confirm pass itself surfaced two more valid findings (the CodeRabbit cadence's confirm budget is now exhausted — both were small, well-defined repairs; the verification of record is this fix commit's own checks plus the thread dispositions; no further CodeRabbit pass is run).

| # | ID | Severity | Finding (verified) | Disposition |
|---|---|---|---|---|
| CR-14 | 4576728934 | **Major** | SYS-03's restore sequence has no pre-swap hook for owner-supplied carry values — the "compose into the staging namespace" carry had no implementable path without editing the frozen SYS-03 GDD (whose only alternatives would reopen CR-9 or CR-10) | **APPLIED — the carry restated as a restore-window write, read-gated.** No SYS-03 edit is made or needed (SYS-03's sequence is consumed verbatim: the atomic swap installs the restored staging dict unchanged). SYS-15's carry write lands **inside the restore window — between SYS-03's `restore_complete` and SYS-05's `load_complete`** (SYS-15's named-writer right over its own namespace sources — TR-RWS-025), and the **read-gating law** holds: the `cache` namespace has no consumers in the loading context (the terminal row, the designation prints and the HUD readout all gate on `load_complete` or later), so the transient restored value is unobservable — **the atomicity bar is observability, not swap composition**. TR-CSD-012's branch a, F-CSD-01 (branch a, the `L`/`S` rows, the examples), TR-CSD-013's namespace row, TR-CSD-014's baseline sentence, and AC-CSD-10's fixture (the spy asserts zero consumer reads inside the window) all restated |
| CR-15 | 4576728939 | Minor | The world-truth baseline said "the last station save", but the reconstruct loads the `auto` slot — which may be a **newer suspension/close save** postdating the last station ack | **APPLIED.** The world-truth baseline is now **the loaded `auto` save** (the newest committed `auto` state — a suspension save postdating the last station ack is the baseline it provides); the rollback is described relative to the loaded record; the fiction's "checkpoint of record" is the loaded record. TR-CSD-013's law + row + closing prose, TR-CSD-014's baseline sentence |

**Counts: unchanged** — 20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0.

## 7. The second confirm batch (the sync landed at `1e9e524`; the merge's required-resolution gate surfaced 5 unresolved threads) — 3 applied, 1 verified-already-fixed, 1 verified-rebuttal

| # | ID | Severity | Finding (verified) | Disposition |
|---|---|---|---|---|
| CR-16 | 4576745965 | **Major** | The pre-cache fallback's carry window was undefined: the `new_game` path's publications are not established in the corpus, so "the restore window" had no footing on the fallback path — a reset counter could become readable or persistable (both violate V-CSD-01's never-lowers law) | **APPLIED — the fallback's own named carry step (the comment's option (ii); option (i) was rejected as an invented SYS-05 contract claim).** TR-CSD-014's fallback now names the step: it lands immediately after the initialization and **completes before the initialized state is readable by any consumer or saveable by any event** (the read-gating law's fallback form: no consumer exists in the initialization context — the Death/respawn context owns the display; the first saveable event is a trigger-set event, which can only fire after control returns, strictly after the carry and the increment). F-CSD-01's worked example (1) restated; AC-CSD-16's fallback arm names the step. **No SYS-05 contract text invented** — the step is SYS-15's own write under its named-writer right |
| CR-17 | 4576745960 | Minor | Nothing in the consumed contracts made `load_complete` wait for the carry write — SYS-05 could publish before the carry, letting gated consumers read the restored counter (an AC-CSD-10 violation) | **APPLIED.** TR-CSD-012's branch a now completes the carry with **SYS-15's carry-complete acknowledgment — SYS-05's `load_complete`'s named gate input** (recorded in the SYS-05 Interactions row and the ratification row as SYS-05's contract input; SYS-05's authoring consumes it — SYS-05 is not edited here). AC-CSD-10's fixture asserts the acknowledgment's gate ordering. The read-gating law is now **structural, not advisory** |
| CR-18 | 4576728943 | Minor | The empty-record spawn rule and the carry could disagree: a suspension save with an empty record + a station activation whose write failed + a death → the carried `[A]` selects A's anchor but the empty-record rule selected the boot anchor | **APPLIED.** TR-CSD-014's empty-record rule now derives the spawn from the **composed (carried) record**: a non-empty composed record spawns at its most recently activated station's anchor (**the carried activation wins over the loaded save's empty record**); the boot anchor only when the composed record remains empty. AC-CSD-16's fifth arm restated |
| CR-19 | 4576728934 | **Major** | "SYS-03's restore contract has no pre-swap hook for the live cache namespace" (posted against `9db1ae7`'s compose wording) | **VERIFIED ALREADY FIXED** in `f7b9d25` — the thread's own option (b), taken: the carry is a **read-gated restore-window write**; SYS-03's load sequence is consumed verbatim ("no pre-swap hook exists or is required" — the current text), no frozen GDD edited; AC-CSD-10/11 restated to match. This batch's CR-17 strengthens it (the acknowledgment gates `load_complete`) |
| CR-20 | 4576675807 | Minor | The formula-template opener (the design-system skill's learning) | **VERIFIED: the rebuttal + the substance-fix both stand** — the reply (4576718811) records the corpus precedent (no landed GDD uses the opener; SYS-03's F-SAV-01..04 and SYS-07's F-HD-01..15 are the house standard), and the finding's substance (F-CSD-04's variable table + output range) landed in `e5cea0d`. Resolved on the recorded rebuttal |

**Counts: unchanged** — 20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0. The mechanical audit re-run clean.

## 8. The tick fix (the run on `5d2b489` — one Minor) — applied

| # | ID | Severity | Finding (verified) | Disposition |
|---|---|---|---|---|
| CR-21 | 4576778428 | Minor | The fallback arm said "the post-resume increment applies" without naming the tick — the load path ties its increment to `load_complete`, but the fallback loads no file, so a reader cannot identify the increment point from the fallback arm alone | **APPLIED** in `29e3556` — the fallback arm names the increment point in the load path's tick language: **the first logic tick after the carry step, before control returns** (the carry step standing in for the `load_complete` gate the fallback path does not have; no new event introduced; the ordering before any saveable event preserved). The same wording completed in the three sibling passages: F-CSD-01's branch a (the fallback clause), the pre-cache edge-case row, AC-CSD-16's fallback arm, and F-CSD-01's worked example (1) |

**Counts: unchanged** — 20 TR / 4 F / 7 V / 26 ACs / 9 OQs / gate 21+3+2+0. The thread resolved after the reply; the run on `29e3556` was CodeRabbit **skipping** (the docs-only diff — zero new findings); **all 18 review threads resolved, 0 unresolved** — the required-resolution merge gate is clear.
