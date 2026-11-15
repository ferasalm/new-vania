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
