# SYS-05 — Game Flow & Session Structure · review log

> Lane: SYS-05 (linear stub) · Branch `docs/sys05-game-flow-session` · Worktree
> `../new-vania-sys05-game-flow-session` · Model GLM-5.3-Flash · Prompt v1.0.0 /
> `ae2a122951f7` (matches the manifest row).
> Document: `design/gdd/game-flow-session.md` (the path SYS-28's contracts name).

---

## §0 · Context + feasibility brief (pre-authored, 2026-11-15)

### 0.1 Preconditions — validated

- Head `016bbbe` = origin/Main base `016bbbe02db6d09d9d35c3701091a7f8774b6c0c`;
  `git merge-base --is-ancestor` confirmed.
- Lane prompt header (Lane/Branch/Worktree/Version/Model/Hash) matches the
  manifest SYS-05 row verbatim (`ae2a122951f7`, QUEUED, deps `[SYS-03]` — SYS-03
  MERGED `66ae957`, PR #45). STATE.md marks no SYS-05 blocker.
- Worktree state: only the orchestrator's staged prompt + its manifest hash
  fill-in (the lane's own in-flight files — the preconditions' sanctioned
  exception). `node_modules` was absent; `npm install` run for the hooks.

### 0.2 Consumed contracts (each read once) — the load-bearing clauses

| Source | The clauses SYS-05 consumes |
|---|---|
| SYS-03 `save-serialization.md` (APPROVED) | `restore_complete` strictly before SYS-05's `load_complete` (TR-SAV-024.3); SYS-05 owns the refusal flow, SYS-24 renders (TR-SAV-022); `load_result ∈ {restored, refused(code), absent}`; a save request during the **loading context** is refused at the request — SYS-05's gate (TR-SAV-013); the slot model (`auto`/`manual_1`) + the close-save; `REFUSE_ABSENT` = the first boot, not a failure; the no-save-present → `new_game` path is SYS-05's; the load machine's RECONCILE state closes on `load_complete`. |
| SYS-09 `dual-reality-state.md` (landed) | E1–E7; **E1 eligibility = request-presence ∧ no operation in flight ∧ context is GAMEPLAY** (rider iii — the load path's request is observed at the first post-load GAMEPLAY tick); the Reading re-open during the flip window is blocked by the context manager; the freeze-scoped discard rider (TR-DR-014) — touches in the window are discarded, Reading/pause are context-blocked. |
| SYS-10 `world-mutation-epochs.md` (APPROVED) | The reconcile chain `[SYS-03 restore] → [SYS-10 reconcile → publish the request] → [SYS-05 load-complete] → [first post-load GAMEPLAY tick: RAISED] → [τ0: the store]`; the request publishes **strictly before** the gate; F-WME-01 `pending_flip = s.flags[T] ∧ (s.epoch < E_to)`; the same-logical-flip doctrine. |
| SYS-02 `room-world-structure.md` (APPROVED) | **The room transition is not a gate** (TR-RWS-010/§6 ruling); true gates = Reading, pause, death, the TRANSITION fallback (TR-MOV-029 consumed); the ack-sourced door row (ADR §6 — no new row); the Reading contexts ride the **non-ack row** (queued; next gate-entry phase); one context at a time — the RM-04 terminal+log queue edge; the TRANSITION context = the non-resident-load fallback (overflow of `TRANSITION_BUDGET_MS` 50), **never entered at MVP**; the linear stub's boundary = RM-01's hub door Class B `LOCKED`. |
| SYS-01 `input-control-mapping.md` (UNFROZEN #10) | TR-INP-045: single active context (stackable: Paused may hold Menu-focus); **SYS-05 owns context state; input owns gate enforcement**; TR-INP-046: the ratified 7-context gating table; TR-INP-047: buffers clear at gate entry, atomic transitions, gate-request terminality (B4), no auto-timeout, **app blur = forced pause → restore to Paused**, Platform Back; the non-ack queue rule (NB-J); `pause` = Tier 2, "verb ours, menu content theirs"; the pause-menu a11y actions synthesize ordinary input at the first Gameplay tick after the transition frame (EX-14). |
| SYS-15 `cache-stations-death.md` (APPROVED) | The station ack's three steps (activation → save request → non-ack context request); the System Offline screen (`OFFLINE_HOLD_MS` 400; the three options verbatim); **TR-CSD-012: the carry write lands inside the restore window (between `restore_complete` and `load_complete`) and completes with the carry-complete acknowledgment — `load_complete`'s named gate input**; the increment on the first logic tick after `load_complete`, strictly before control returns, inside Death/respawn; TR-CSD-014: the reconstruct serialization + `REFUSE_ABSENT` → the pre-cache fallback; **law 3: a refused reconstruct load → SYS-05's refusal flow owns the session (two actions: new game / quit)**; law 4: death during the terminal context → the one-context law closes the terminal first; RESOLVED(quit) → SYS-05's session flow. |
| SYS-16 `progression.md` (APPROVED) | TR-PRG-025: the `progression` namespace v2→v3; the carry law + **SYS-16's carry-complete acknowledgment = the second named `load_complete` input**; TR-PRG-021/022/023: `GrantEvent {DASH, WALL_JUMP, DOUBLE_JUMP, STINGER}` — the Stinger is **off-ladder, SYS-05's story moment authors the trigger**, once-latched, persisted, recorded in SYS-16's grant set; zero MVP traversal grants; the dormant Dash socket. |
| SYS-28 `narrative-presentation.md` (APPROVED) | TR-NAR-007: **the Reading's close ≡ completion ratified verbatim** — no dismiss affordance; instant print; no new verb; one context at a time; TR-NAR-012: the VS briefing/report are **SYS-05's flow surfaces**, the copy registered-but-absent at MVP, the copy landing at SYS-05's authoring gate (this GDD names the gates; the copy is SYS-28's); TR-NAR-013: the refusal display mapping (17 rows + recovery); the irony rubric rides SYS-05's playtest set at VS. |
| ADR-0001 (Accepted) | §6's gate-source table (5 rows: ack-sourced door; non-ack death / cutscene / pause+blur / log-reading-cache); the pipeline phase order (phase 3 GATE-ENTRY applies queued non-ack requests; phase 5 ACKS); §3's freeze law (the flip freeze is a `request_freeze` source — **the freeze is not a gate**); §5's tick-boundary pipeline. |
| ADR-0002 (Proposed) | SYS-05 consumes the `restore_complete`→`load_complete` ordering; the ADR does not wait on SYS-05; the refusal flow's ownership confirmed. |
| ADR-0003 §12 + O-AUD-1 | **`load_complete` is SYS-05's** and **must carry `restored_epoch`** (derived from the store after `restore_complete`); O-AUD-1: present and non-default asserted after a post-flip load; CR-AUD-04 (the one-clause SYS-04 correction) rides `decisions.md` — pending the user; SYS-05 authors on the ADR's resolution (SYS-05 owns the seam). |
| SYS-04 `audio-core.md` (APPROVED) | The load-complete's missing-input path (`AUD_LOAD_MISSING`; the derived state stands); the death duck released at every offline exit; the no-duck law. |
| `game-concept.md` (frozen) | The Session Loop (briefing → dive → grief boss → report → contract → spend → pick next errand); MVP = the linear stub (no hub; the LOCKED hub door); VS = one complete errand loop; D-3: the Stinger grant's story moment is SYS-05's. |
| Tech prefs / VERSION.md | Godot 4.7.2, GDScript, GUT, 60 fps / 16.6 ms. |

### 0.3 Open items carried into authoring (with recommendations)

1. **OQ-DR-1 (close ≡ completion)** — RATIFY verbatim (SYS-02's close law +
   SYS-28's + SYS-09's input all align; no amendment). The ratification clause
   lives in the GDD's Consumed-Contracts table.
2. **CR-AUD-04** (SYS-04's TR-AUD-002 publisher row says SYS-03 publishes the
   load-complete; ADR-0003 §12 + the design direction name SYS-05) — pending the
   user in `decisions.md`. SYS-05 authors `load_complete` as its own publication
   and records the correction request in the sync handoff. No SYS-04 text is
   edited here.
3. **O-AUD-1** — accepted: the `load_complete` payload carries
   `restored_epoch`; the dev assert (present, in-range; non-default after a
   post-flip load) is a V-invariant.
4. **The Stinger grant beat (D-3)** — recommendation: the trigger is the **first
   cache activation** (the faucet's fire event, TR-CSD-017): the `GrantEvent`
   publishes at the first Gameplay tick after the terminal context exits; the
   cue is SYS-16's (one chime edge + one Gameplay print row — TR-JCE-021's
   treatment), so SYS-15's frozen five-row terminal surface is untouched. The
   grant is once-latched + persisted in SYS-16's namespace, so a reconstruct
   never re-fires it and a death never loses it. The gesture-reservation
   amendment to SYS-01 stays SYS-12's authoring obligation (recorded, not
   edited here).
5. **The Loading context** — codified as SYS-05's eighth context (a full gate,
   never player-requested): SYS-03's TR-SAV-013 already names "the loading
   context" as SYS-05's gate. The TR-INP-046 table gains a Loading row via the
   recorded one-clause SYS-01 rider (the OQ-M1 pattern — rides the next SYS-01
   doc touch; listed in the sync request).
6. **Boot / slot law** — boot loads `auto`; `REFUSE_ABSENT` → the new-game path
   (the session boot anchor; the designation seeds 001's absence — the stamp
   appears only after the first death). A refused slot (non-ABSENT) → the
   refusal flow (new game or quit; the slot stays read-only for the session —
   SYS-03's terminal-refusal law; `manual_1` remains writable at the terminal).
7. **The spawn anchor on every load** — `active_cache`'s terminal anchor (the
   composed record's last activation), else the session boot anchor (RM-01's
   entry anchor). Generalizes SYS-15's TR-CSD-014 rule to plain relaunches
   (the save carries no position — the store-sources law makes this forced).
   Recorded as a ratification of SYS-15's rule, not an amendment.
8. **The pause menu's MVP content (SYS-05 owns it)** — four rows: `RESUME` ·
   `MAP` (SYS-25's pause room-grid, MVP-promoted by D-4; the row + its data
   contract named here, SYS-25 owns the policy/presentation) · `RECALIBRATION`
   (SYS-01's; the a11y surface) · `QUIT` (the session teardown). No submenu at
   MVP beyond Recalibration's own surface (SYS-01's).
9. **Quit semantics** — the pause-menu QUIT, the offline screen's QUIT, and the
   app-close event all route to one session-teardown path: the close-save
   attempt (SYS-03's synchronous close path; skipped inside the flip window —
   TR-SAV-014's law consumed), then the session ends. The offline QUIT saves
   nothing (SYS-15's law consumed: the death stays unsaved). The explicit
   new-game/title affordance is recorded as VS scope (an OQ).

### 0.4 Section plan (the authored document's skeleton)

| § | Section | Serves |
|---|---|---|
| Header | Status/Author/Contracts | — |
| Overview | owns / does-not-own / one-line contract / MVP posture | the lane's mission |
| Player Fantasy | "The House Never Announces Itself" + contract terms + anchors | — |
| Detailed Design | C1 the context machine (contexts, gates, the no-double-gate law, pause≠freeze≠gate) · C2 the session loop (the linear stub; the VS/full loop's named gates; the grant beat) · C3 the save/load flow (boot; the loading context; the load-complete gate; the refusal flow; the save queue's flow law; the reconstruct serialization) · C4 the death/revive flow (offline entry/exit; the three paths; the return edge) · C5 the Reading context (close ≡ completion ratified; the budget consumed) · C6 the transition law (not-a-gate; the TRANSITION fallback) · C7 the quit/teardown flow | obligations 1–6 |
| States and Transitions | the context machine's table + transition laws | — |
| Interactions | the boundary table + missing-input failure paths | the contract's bar |
| Consumed-Contracts Ratification | OQ-DR-1, SYS-15's, SYS-16's, SYS-03's, SYS-28's rows | the ratify-at-authoring obligations |
| Formulas | F-GFS-01 gate_priority · F-GFS-02 load_complete_ready · F-GFS-03 session_anchor | every formula: variables/ranges/Output/examples |
| Edge Cases | the If→outcome register | — |
| Dependencies | upstream/downstream + explicit non-dependencies + the sync corrections | — |
| Tuning Knobs | the flow's knob posture (identity values, no feel knobs) | — |
| Visual/Audio + UI Requirements | none rendered; the pause-menu content contract; the UX flag note | — |
| Acceptance Criteria | the counts + gate partition | must reproduce |

Counts skeleton (the ceiling the AC ledger must match): **TR-GFS 24 · F-GFS 3 ·
V-GFS 7 · ACs 30 (gate 24 smoke = 18 GUT + 4 LINT + 2 DEVICE + 0 PLAYTEST · 2
MVP-lock · 0 VS)** — re-derived exactly at authoring.

### 0.5 Hard constraints restated (the lane prompt's)

SYS-03 owns the save; SYS-09/10 own the flip; SYS-02 owns the room data; SYS-05
owns the context machine. The pause is not a freeze; the freeze is not a gate.
No new input verb. `entities.yaml` + `systems-index.md` untouched (the sync
request carries the diffs). No frozen GDD edited; every ratification is a
clause in SYS-05's own document.

### 0.6 Gate trail (filled as gates run)

- Authoring: COMPLETE (2026-11-15) — `design/gdd/game-flow-session.md` written in full; counts verified 24 TR / 3 F / 7 V / 30 ACs (25 smoke = 20 GUT + 3 LINT + 2 PLAYTEST · 3 DEVICE · 2 lock · 0 VS) / 5 OQs; two broken self-references (V-GFS-08 → AC-GFS-22) and the interrupted-close rider repaired pre-commit.
- CD gate: round 1 CONCERNS (3 blockers) → repaired → round 2 CONCERNS (2 blockers) → repaired → round 3 CONCERNS (1 blocker: the carried OQ-PRG-6 disposition) → repaired → **round 4 APPROVED (2026-11-15, zero blockers)**. Post-approval: 6 one-line recommendations applied (the grant build-gate; the teardown-during-Loading edge; the re-open's first-line clause; the phase-3 mapping pointer; the authored-order mark; the pooled-cohort script clause); 1 declined with rebuttal: *deferring the Cutscene row's registration to the VS pass* — the nine-row set is the authored shape and the row's registration is table data; deferring would churn AC-GFS-01's fixture and the set law for a cosmetic MVP delta the approved round-4 document already hedges (the retire path).
- Creative seat: NEEDS REVISION (1 blocker: the gear loadout's pause-surface absence) · Technical seat: NEEDS REVISION (5 blockers: the Loading exit's three incompatible statements; the ack set's domain including SYS-02; the restored_epoch input path; the REFUSE_ABSENT carve-out; the clock law vs the wall-clock holds) · QA seat: NEEDS REVISION (8 blockers: the AC-01 count; the TR-024 coverage; the untested initialization forms; the TR-001 test arms; the AC-10 dual disposition; the playtest thresholds; the four missing-input arms; the two fixture-less edge rows; the PROVISIONAL convention)
- qa-lead spot-check: —
- Final micro-check: —
- CodeRabbit: —
