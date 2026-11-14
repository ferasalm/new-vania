# SYS-03 Save & Serialization — review log

> **Document**: `design/gdd/save-serialization.md` · **Lane**: SYS-03 · **Branch**: `docs/sys03-save-serialization`
> **Opened**: 2026-11-14 · **Prompt**: `lanes/SYS-03.md` v1.0.0 / `8fbc08eec5c0` (matches manifest: yes)
> **Seat routing**: CD + creative → `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`; technical + QA + spot-check → `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`. **No fallback used** — the nested subagent tool was available for every seat.

## 1. The authoring gate — the real-file round-trip twin

| Run | Result | Notes |
|---|---|---|
| 1 (pre-repair) | **23/23 PASS** | the first run had 3 self-inflicted test bugs (a garbled expression, an off-by-one contiguity loop, a chain assertion) — fixed, not waived |
| 2 (pre-repair, hardened) | **24/24 PASS** | the hash moved to `{schema_version, payload}` (the version is hashed) and the `COR-downgrade` fixture was added |
| 3 (post-repair) | **29/29 PASS** | the number-normalization pass, the version-aware payload allowlist, the six-step write, the chain below the gate, `NORM-*`/`COR-cache-at-v1`/`WRITE-verify-temp` added |

**The split (recorded, not implied):** the twin proves the **format contract** on real files. The **engine half** (Godot `FileAccess`/`JSON`, the float-typed parse through the normalization pass, `user://`, the worker `Thread`) is a **story-gated obligation** at the first SYS-03 implementation story, under the same fixtures (OQ-SAV-1 option (a), user-approved 2026-11-14).

## 2. CD gate (CD-GDD-ALIGN)

**Verdict: APPROVED — zero blockers.** Recommendations (7), all one-line and non-gating; **all applied**:

| # | Recommendation | Disposition |
|---|---|---|
| 1 | Scope TR-SAV-013's post-τ0 claim to queued saves | APPLIED — the clause now reads "for a **queued** save", with the pre-window case named |
| 2 | Record the synchronous close-save as the ratified refinement of "never blocks the game thread" | APPLIED — TR-SAV-014 states the one legal blocking path; the lane report records it |
| 3 | State the refusal surface's scope relative to the two-slot model | APPLIED — §UI's scope clause |
| 4 | Make "the death counter persists at MVP" an explicit SYS-15 gate | APPLIED — the index correction (3) |
| 5 | Cross-check OQ-SAV-8 against SYS-01's Android backup item | APPLIED — OQ-SAV-8's status text |
| 6 | Reword F-SAV-03's coalescing example | APPLIED — "the later request's snapshot survives" |
| 7 | Name the platform classes behind "where the platform allows" | APPLIED — TR-SAV-011's row (and then superseded by the creative blocker's fix) |

## 3. Three-seat review — verdicts

| Seat | Verdict | Blockers |
|---|---|---|
| Creative | **NEEDS REVISION** | 1 |
| Technical | **NEEDS REVISION** | 8 |
| QA | **NEEDS REVISION** | 12 |

## 4. Repair worklist — every blocker, dispositioned

### Creative

| # | Blocker | Disposition |
|---|---|---|
| C1 | TR-SAV-011 gave iOS no save hook, so the routine background-kill path reloads one station behind — the exact inversion of Player Fantasy anchor 2, absorbed silently by the fantasy, the AC and the platform parenthetical | **APPLIED.** TR-SAV-011's `auto` trigger set now includes iOS `NOTIFICATION_APPLICATION_PAUSED` (an **event**, never a timer); the rationale is stated in TR-SAV-011 ("a station-only trigger would make anchor 2 platform-conditional"); AC-SAV-23 is tightened to require the background-kill survival. **Flagged for the user's nod** in OQ-SAV-4 — a refinement *inside* the "no timer" decision, not a reopening of it. |

Creative recommendations: (1) the SYS-15 bump as a named pre-MVP gate — **APPLIED** (index correction 3); (2) the autosave fate after `REFUSED_READ_ONLY` — **APPLIED** (the slot-state edges + AC-SAV-17's per-code state + §UI's scope clause); (3) the flip-completion moment as an event-autosave candidate — **DEFERRED** to SYS-15's authoring (it is a design decision, not a defect; recorded here); (4) the refusal copy bound to the language law — **APPLIED** (§UI); (5) a diegetic truth indicator, never an "epoch badge" — **APPLIED** (§UI); (6) the manual slot's near-null decision texture recorded as intentional — **APPLIED** (TR-SAV-011); (7) the re-fire beat's presentation owner named — **APPLIED** (§UI); (8) a diagnostics-export action for Full Vision — **DEFERRED** to the VS backlog (recorded).

### Technical

| # | Blocker | Disposition |
|---|---|---|
| T1 | F-SAV-04's hash step precedes the codes that name its unhashable inputs — a float or a non-int version leaves the order undefined and those codes unreachable | **APPLIED.** F-SAV-04 gains mechanical rows 0–2 **before** the hash (parse + envelope keys; `schema_version` integer; the normalization pass), and the range is restated. The twin's `NORM-*` and `COR-*` fixtures prove the reachable codes. |
| T2 | The v1 payload's shape was undetermined (`cache` "registered, empty" vs the envelope's `cache:{…}` vs the hash that reproduces only without it) | **APPLIED.** **`cache` is registered but ABSENT from v1**; TR-SAV-004 says so once; the envelope example drops the key; F-SAV-01's variable table says `{world}` at v1; the payload-key allowlist is **version-aware** (a v1 file with a `cache` key is `REFUSE_UNKNOWN_KEY`); the three cited hashes are unchanged and still reproduce. |
| T3 | "A rename is a `pop` + a `put` with the default" loses the value; and the `v0→v2` chain is a path the gate forbids | **APPLIED.** The rename is `put(new, pop(old))` — **the value moves**; only a genuinely new key takes the default. The chain is exercised **below the gate** by a synthetic `CURRENT = 3` harness (`v1→v3`); `v0` is a refusal fixture only. |
| T4 | `N_max` bounds only the base hold while the predicate includes the extension sources; and the bound re-derives the ms→tick conversion the note forbids | **APPLIED.** `N_max` is **consumed from SYS-09** (`worst_case_hold_ticks`: base + the two admitted extension spans); F-SAV-03 no longer computes it; the extension example is now "SYS-09's number, not SYS-03's". |
| T5 | The slot-state record is a linear chain with a dead `BAK_ONLY`; the read-only law is false on the `.bak`-recovery path | **APPLIED.** The edges are total (`EMPTY→OK`, `OK→BAK_ONLY`, `BAK_ONLY→OK`, `→REFUSED_READ_ONLY` only on both-fail); TR-SAV-020 scopes read-only to the terminal refusal, with the `.bak` recovery as the named exception; AC-SAV-17's per-code expected state matches. |
| T6 | The derived-target table omits `memories_collected` from the MetSys Dictionary's derivation, so "the stored object ids" has no home | **APPLIED.** The table row adds `memories_collected`; TR-SAV-003 names the registered **1:1 map** (memory id ≡ storable id; an unmapped id fails the boot lint; absent → empty). |
| T7 | `SAVE_BAK_DEPTH`'s legal value 2 is a silent no-op (no `.bak2` naming, rotation or sweep) | **APPLIED.** The knob is **removed**; the backup depth is fixed at one `.bak` and listed under "not knobs", with depth-2 recorded as a future change needing the naming/rotation/sweep. |
| T8 | Godot's `JSON` yields a float for every number, so a legitimate `truth_epoch: 0` re-parses as `0.0`, `canon` refuses it, and every legitimate save refuses at load — and the reference twin cannot catch it | **APPLIED.** **TR-SAV-026 — the number-normalization pass** (schema-driven; integral → coerce; non-integral → `REFUSE_FLOAT`), between parse and canon; V-SAV-09; AC-SAV-25; the twin's `NORM-float`/`NORM-identity`/`NORM-type`; the engine-reference obligation recorded; the engine fixture named as story-gated. |

Technical recommendations: (1) AC-04/07 tags — **APPLIED** (04 → GUT, 07 → GUT, the greps → the new AC-26 LINT); (2) F-SAV-04's "eleven codes" — **APPLIED** (nine + ACCEPT/MIGRATE); (3) the read-only vocabulary — **APPLIED** (the `SAVE_FAILED_*` table; one vocabulary per path); (4) the non-dependency range swallowing SYS-20/29 — **APPLIED** (the range is now explicit and SYS-20/29 are named consumers); (5) the REQUESTED loading-context refusal — **APPLIED** (a `REJECTED` state); (6) F-SAV-03's undefined unreadable case — **APPLIED** (`t_write = ⊥` → `SAVE_FAILED_FREEZE_UNAVAILABLE`); (7) the [E1, E2) gap — **APPLIED** (named, state (b)); (8) the twin's missing steps 3/6 — **APPLIED** (the six-step `atomicWrite` + `WRITE-verify-temp`); (9) registry rows for the sync request — **APPLIED** in the lane report's sync request; (10) SYS-16/17 — **APPLIED** (OQ-SAV-11 + the named exception + index correction 10).

### QA

| # | Blocker | Disposition |
|---|---|---|
| Q1 | F-SAV-04 row 3 refuses every migratable file (`MIGRATE` is not an output) | **APPLIED** (same repair as T1 — `MIGRATE` is an explicit output row). |
| Q2 | AC-SAV-16's `v0→v2` contradicts the gate law | **APPLIED** (same repair as T3 — the chain moves below the gate, `v1→v3`). |
| Q3 | AC-SAV-17 is false for `REFUSE_ABSENT`, has no fixture for four codes, and folds a LINT clause into a GUT AC | **APPLIED.** AC-SAV-17 now names a fixture for **every** code with a per-code expected slot state (`ABSENT` → `EMPTY`); the UI-call grep moves to AC-SAV-26 `[LINT]`. |
| Q4 | TR-SAV-013's loading-context refusal and the coalescing rule have no AC | **APPLIED.** AC-SAV-11 gains both clauses plus the `[E1, E2)` gap and the freeze-unavailable failure. |
| Q5 | "An unreadable freeze state is treated as frozen" has no exit, so the min is empty and the liveness proof fails | **APPLIED** (F-SAV-03's `⊥` + `SAVE_FAILED_FREEZE_UNAVAILABLE` + AC-SAV-11's clause). |
| Q6 | The read-only condition has two codes across two vocabularies, and half of AC-SAV-14 has no executable environment | **APPLIED.** One vocabulary per path (`SAVE_FAILED_*` vs `REFUSE_*`), a table for each; the read-only case moves to a GUT injected-IO fixture under AC-SAV-09; AC-SAV-14 keeps only the device-executable half. |
| Q7 | AC-SAV-12's "never stalls" has no threshold; "every telemetry record fires once" is asserted from a fixture that cannot fire 9 of them | **APPLIED.** The bar is "no gameplay frame > 16.6 ms attributable to the save; the close-save ≤ `SAVE_JOIN_TIMEOUT_MS`"; the telemetry assertion is split per path (save / load / boot) with the owning AC cited. |
| Q8 | AC-SAV-20's "behave per the table" is a rubric by reference; the (b) replay-hash equivalence is unasserted | **APPLIED.** The THEN is written out for (a)–(e), including "its replay hash equals the fresh flip's". |
| Q9 | F-SAV-01's worked example and the twin omit the registered `cache`, so the hash is unpinned | **APPLIED** (same repair as T2 — `cache` absent at v1; the hashes reproduce unchanged). |
| Q10 | AC-SAV-09/18 over-claim relative to their evidence | **APPLIED.** AC-SAV-09 names which steps the twin covers and which are GUT fixtures (and the twin now covers steps 3–6); AC-SAV-18 gains the both-corrupt case with the primary's reported code. |
| Q11 | AC-SAV-19 says "the four arrays" — there are three arrays and one dict | **APPLIED.** "The **three arrays** default to `[]`, `truth_flags` to `{}` with every flag unset, the absent epoch refuses." |
| Q12 | AC-SAV-24 cites no TR and treats the reference twin as the implementation | **APPLIED.** It cites TR-SAV-001/008/009/018/019/023/024, carries the **"reference twin only"** label, and the engine-path AC is recorded as scheduled at the first story. |

QA recommendations: (1) the V-SAV-04/TR-016 greps to a LINT AC — **APPLIED** (AC-26); (2) name AC-02's and AC-17's fixtures — **APPLIED**; (3) make the ms bars non-gating probes — **APPLIED**; (4) AC-04's absent-namespace default — **APPLIED**; (5) the rate-limit assertion in AC-12 — **APPLIED**; (6) the close-while-in-flight case in AC-23 — **APPLIED**; (7) "one load at a time globally" covered — **APPLIED** (AC-21); (8) cite `RT-hash-stable` in AC-22 — **APPLIED**; (9) print the counts in the header — **APPLIED**; (10) split AC-06 — **APPLIED**.

## 5. Counts

| | Before the repair | After the repair |
|---|---|---|
| TR-SAV | 25 | **26** (TR-SAV-026 added) |
| F-SAV | 4 | **4** |
| V-SAV | 8 | **9** (V-SAV-09 added) |
| AC-SAV | 24 | **26** (AC-SAV-25/26 added; 06 split in place) |
| Partition | 19 GUT + 3 LINT + 2 DEVICE + 0 PLAYTEST | **22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST** |
| Smoke | 22 | **24** |

The partition sums: 22 + 2 + 2 + 0 = 26; smoke 24 = the GUT + LINT sets; device 2 = AC-14, AC-23; no AC sits in two gates. The tag shift (+3 GUT, −1 LINT) is AC-04 and AC-07 moving from LINT to GUT (a boot test and a runtime port spy) plus AC-25 (GUT) and AC-26 (LINT) being added.

## 6. Spot-check and micro-check

**Spot-check #1: FAIL** — 6 blockers + 5 advisories, all bookkeeping left by the repair pass: the knobs intro ("three" vs the two remaining rows), TR-SAV-018's title ("eight steps" vs the nine enumerated), the load machine's VALIDATE cross-reference ("steps 2–3" after the normalization step was inserted), two stale "AC-SAV-17's audit clause" citations (the clause moved to AC-SAV-26), OQ-SAV-1's stale "24/24", and TR-SAV-023's test still saying "the four arrays". **All six repaired in-session.**

**Spot-check #2: PASS** — all 11 rows APPLIED-CORRECTLY; the arithmetic re-derived by enumeration (26 TR contiguous, 4 F-SAV, 9 V-SAV, 26 AC = 22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST, smoke 24, the twin's 29/29 re-run with all three hashes reproducing).

**Advisories closed (one clause each):** the load machine's RESTORE row now names the migrated-path post-migration validation (TR-SAV-018 step 7's reachability); TR-SAV-020's footnote states the `ABSENT`/`SCHEMA_AHEAD` exclusions explicitly.

**Final micro-check: PASS — zero blockers** (diff-scoped, fresh seat, on the last two-clause delta). The document is **not reopened**.

## 7. CodeRabbit (one pass + one confirm pass)

**Pass 1** (PR #45, 9m39s): 6 findings — **all valid, all applied in one fix commit `cfbe314`**, all 6 threads replied to with a disposition and resolved.

| # | Severity | Finding | Disposition |
|---|---|---|---|
| 1 | Major | The canonicalizer sorted **nested** arrays, so a cell coordinate `[1,0]` became `[0,1]` — one discovered cell silently turned into another; the round-trip passed because both sides were equally lossy | **APPLIED** — only the three outer family arrays are sets; a pair keeps its order. `CANON-pair` + `RT-content` added; the `post_flip` hash re-pinned to `05b1e48e…` (the hash change is the proof the loss was real) |
| 2 | Major | The `.bak` recovery left the corrupt primary at `.sav`, so the next write would rotate it over the good `.bak` and a failed commit would leave two bad files | **APPLIED** — the verified `.bak` is promoted to `.sav` before the slot returns to `OK`; AC-SAV-18 asserts it |
| 3 | Major | The absent-key defaults applied during normalization changed the hash input, turning a valid sparse file into `REFUSE_HASH_MISMATCH` | **APPLIED** — the absence is preserved through the hash; the defaults apply at restore (TR-SAV-026 step 4 + TR-SAV-023's note) |
| 4 | Minor | A close request during a flip freeze would have written a synchronous mid-choreography snapshot | **APPLIED** — the close-save is skipped while `flip_sources_active` is non-empty; the station autosave is the fallback (TR-SAV-014 + AC-SAV-23) |
| 5 | Minor | `flip_sources_active` typed `bool` but compared with `∅`; F-SAV-04's variables were a prose line | **APPLIED** — a source-id set (empty = writable); F-SAV-04 gains its variables table |
| 6 | Minor | An unregistered truth-flag name (`sanctum_log_consumed`) passed the validator | **APPLIED** — flag names are checked against the registered table → `REFUSE_UNKNOWN_KEY`; `COR-unregistered-flag` added |

**The twin after the batch: 32/32 PASS.** Counts unchanged (26 TR / 4 F / 9 V / 26 AC).

**Confirm pass** (on `cfbe314`, 6m58s; warranted — the batch contained three Major-class findings): **1 new Minor finding** — AC-SAV-23 conflated the suspension snapshot with the ack fallback (a successful close-save must restore the **suspension** state, including anything collected after the last ack; the ack state is the fallback only). **APPLIED in `e1e7a1f`**, thread replied + resolved. No new Major findings; the six pass-1 findings are confirmed fixed.

## 8. Gate trail (final)

| Gate | Verdict |
|---|---|
| The authoring gate (the real-file twin) | **32/32 PASS** (the format-contract half; the engine half is story-gated — OQ-SAV-1 (a)) |
| CD-GDD-ALIGN | **APPROVED** (0 blockers; 7 recommendations, all applied) |
| Creative seat | NEEDS REVISION (1) → repaired |
| Technical seat | NEEDS REVISION (8) → repaired |
| QA seat | NEEDS REVISION (12) → repaired |
| qa-lead spot-check #1 | **FAIL** (6) → repaired |
| qa-lead spot-check #2 | **PASS** |
| Final micro-check | **PASS** (zero blockers) |
| CodeRabbit pass 1 | 6 findings (3 Major) → all applied in `cfbe314`, 6/6 threads resolved |
| CodeRabbit confirm pass | pending at the time of writing |
| CI (5 checks) | **pass** on `04acd38` and `cfbe314` |
