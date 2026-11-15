# Narrative Presentation — logs, briefings, telegraph text (SYS-28)

> **Status**: In Review (the three-seat trail runs in
> `design/gdd/reviews/sys28-narrative-presentation-review-log.md`)
> **Author**: writer (narrative-director + writer lane, SYS-28)
> **Last Updated**: 2026-11-15
> **Implements Pillar**: "Read, Then Strike" (reading the world includes its
> paperwork) · "Five Goodbyes" (the text is how the house and the court speak)
> · the anti-pillar kept: **no cutscene-driven storytelling — story lives in
> logs, environments, boss encounters**
> **Contracts**: SYS-02 `design/gdd/room-world-structure.md` (APPROVED
> 2026-11-13) — TR-RWS-021 (the two logs; the text and presentation are
> SYS-28's), TR-RWS-019 (the terminal surface is SYS-15's), TR-RWS-020 (the
> memory content is SYS-20's), TR-RWS-014 (the threshold: L2's Reading close
> sets `sanctum_log_read`), TR-RWS-018 (the label law), the text-boundary
> audit; SYS-09 `design/gdd/dual-reality-state.md` (landed 2026-11-14) —
> TR-DR-007/008/010/014 consumed (the tell registry, the no-point-back law,
> the telegraph-text seam, the not-do list); SYS-10
> `design/gdd/world-mutation-epochs.md` (APPROVED 2026-11-14) — **TR-WME-008
> countersigned verbatim at this authoring gate** (the review log §Countersign);
> SYS-11 `design/gdd/seam-borders.md` (APPROVED 2026-11-14) — **no text
> surface in the seam region** (the no-interface row honored); SYS-05
> `design/gdd/game-flow-session.md` (pre-shaped, waived — **ratified at this
> authoring**: the Reading context's close ≡ completion at MVP, OQ-DR-1); SYS-03
> `design/gdd/save-serialization.md` (APPROVED 2026-11-14) — TR-SAV-020/021/022
> consumed (the closed refusal vocabulary; the display-copy mapping authored
> here); SYS-07 `design/gdd/health-damage.md` (APPROVED 2026-11-12) — TR-HD-023
> consumed (the System Offline options contract; the lowercase co-ruling
> carried to SYS-15's gate); SYS-01 + ADR-0001 — the Prompt Slot, the non-ack
> row, the true-gate terminality; `game-concept.md` (frozen) — the anti-pillar,
> the diegetic print doctrine, the IP-8 micro-copy budget.

## Overview

Narrative Presentation is the game's **text**: what the house says, where it
says it, how long it takes to say, and the laws the words obey. It owns the
two MVP logs (L1 the Vestibule establishing log, L2 the Sanctum threshold
log), the Reading presentation that carries them, the display lines for the
save system's refusal vocabulary, and the **print voice** — the diegetic
android-diagnostics register that every other lane's text surface (the cache
terminal's print, the System Offline fiction, the memory fragments) must obey.

It owns **no mechanic**. The text-only law is absolute: no voice-over, no
cutscenes, no camera orders, no gameplay effect from text — the one trigger
that touches world truth (L2's close setting `sanctum_log_read`) is SYS-02's
flag edge at the Reading context's close, owned by SYS-02/SYS-05, never by
this module. The narrative module renders rows and nothing else.

MVP scope is exactly the index row's "Yes (2–3 logs)": **two logs** (L1, L2 —
the third count is index headroom requiring a SYS-02 placement row), the
Reading overlay's presentation contract, the 18 refusal/save-failure/recovery
display lines, and the three laws (print voice, micro-copy budget,
no-spoiler) that bind the other text surfaces' owners. The session bookends
(the court briefing, the report to the demon lord) are VS surfaces whose
contract is authored here and whose copy lands at SYS-05's authoring gate.

## Player Fantasy

*Be the slick, clever anti-hero who wins by reading the world.* In this game
that is literal: the world is run by a house that keeps paperwork, and the
paperwork is where the truth hides in plain sight. The fantasy contract for
every line of text:

- **The text never interrupts.** A beat is ≤ 3 short lines — glanced, not
  watched. Reading is a room's flavor, never a chore (the anti-pillar: no
  cutscene-driven storytelling; the discipline: the micro-copy budget, IP-8).
- **The text never lectures.** No tutorial voice, no objective text, no hint
  at the unhinted tech (the concept's guard: "no tutorial, log, or bestiary
  hint"). The house explains itself; it does not explain the game.
- **The text never points back.** After the truth arrives, no line confirms
  the player noticed anything (TR-DR-010's term 2, generalized to every
  register). The house may grieve; it may not say "you saw".
- **The text is honest machinery.** Every line is a readout something in the
  fiction actually printed — a house log, a chassis diagnostic, a cached
  label, a court memo. The death screen's cause row is the pillar's
  mechanical guarantee made prose: *what hit you, how hard, why you were
  there* — attributable, printed, never a hidden die.

The dramatic irony of the session bookends (VS) runs on the same law: the
report to the demon lord is text-only, and the lord's court addresses its
assassin while the player reads the woman underneath.

## Detailed Design

### Core Rules

- **TR-NAR-001 — The text-only law.** The narrative module **publishes text
  rows and nothing else**: zero gameplay writes, zero flag writes, zero
  grants, zero camera/audio/HUD orders, zero input reads, zero tick work
  (the overlay renders on the context's entry state and the close's; no
  per-tick loop exists — **SYS-28 prices no gameplay-tick envelope row**
  (the SYS-02 not-join precedent); the one telemetry family is
  rate-limited (`NAR_TELEMETRY_RATE_LIMIT_MS` 60000; the SYS-03 TR-SAV-017
  record shape consumed)). The one world-truth edge in the reading flow —
  L2's Reading **close** setting `sanctum_log_read` — is SYS-02's flag edge
  at SYS-05's context close (TR-RWS-014), consumed, never re-implemented
  here; the module does not listen to its own content. *Test: the
  write-surface audit (V-NAR-01; AC-NAR-01) — no state-write/flag/grant/
  camera/audio-call symbol in the narrative module; the render-side reads
  are the selector's saved-source reads only.*
- **TR-NAR-002 — The print voice (the diegetic android-diagnostics
  register, IP-8).** Every player-facing line is a **printed readout** one of
  the fiction's machines produced — never narration. Three registers, closed:
  (i) **the HOUSE register** — the facility's maintenance voice (the logs,
  the fault stencils' grammar); (ii) **the CHASSIS register** — her own
  diagnostics (the cache print, the System Offline rows); (iii) **the COURT
  register** — the demon lord's court (VS: the briefing, the report;
  sigil-red is reserved for the lord's presence, never decoration — the
  concept's doctrine). Conventions: headline/status rows print uppercase;
  quiet lines print lowercase (the register contrast SYS-07 pinned at the
  death screen); **second person is diegetic address** (the house addresses
  its resident; the court addresses its assassin) — never meta narration
  ("as you found earlier" is banned); no emoji, no exclamation stacking, no
  humor that breaks the diagnostic frame. *Test: the voice audit is a review
  item (the seat review + the spot-check read every authored row against
  this rule); the register vocabulary is closed (a fourth register is a
  contract revision).*
- **TR-NAR-003 — The micro-copy budget (the class table).** Every
  player-facing beat obeys F-NAR-02/F-NAR-03 by class: **FIELD** (logs,
  terminal prints, memory text, single-line toasts) ≤ 3 lines × 46 chars;
  **DEATH** (the System Offline screen's authored rows) ≤ 3 authored rows —
  the headline, the quiet line, the cause row — the three option rows are
  SYS-07's contract affordances, not prose, and are excluded; **SESSION**
  (the briefing, the report — VS) ≤ 8 lines and ≤ 30 s estimated reading.
  The FIELD budget is the IP-8 rider's law: **≤ 3 short lines per
  terminal/log/memory beat** — fixed at MVP; relaxing it is a contract
  revision, not a knob turn. *Test: the budget lint (AC-NAR-02) fails CI
  naming the violating beat.*
- **TR-NAR-004 — The beat data model and the text boundary.** All
  player-facing text lives in **data**, never in code: the beat table
  `assets/narrative/beats.json` (localization-shaped: keys, never
  hardcoded strings), loaded and boot-validated by the narrative module's
  beat store. `NarrativeBeat {beat_id (the registry key), class ∈
  {FIELD, SESSION, DEATH}, variants {default: [lines…] (always present),
  <variant_id>: [lines…] (one per declared alternate)}, keyed_variant_id
  (present iff selector_key ≠ none; the alternate's id, validated at boot
  to resolve in variants), selector_key ∈ {none} ∪ {registered truth-flag
  names} (closed at MVP: none, `sanctum_log_read`), source_ref (the owning
  rule, for traceability)}`.
  The boundary audit is SYS-02's law (TR-RWS-021) **generalized**: no
  narrative string literal anywhere in `src/` — a grep-enforced invariant
  (V-NAR-02). *Test: the boundary audit (AC-NAR-03); the boot join (a placed
  interactable's `beat_id` with no row fails the boot naming the beat; a
  keyed row whose `keyed_variant_id` does not resolve fails the boot
  naming the beat).*
- **TR-NAR-005 — The variant-selector derivation law.** Which variant a
  beat renders is **derived, never stored**: F-NAR-01 reads only the
  restored save's source families (SYS-02's five; SYS-03's restore), never
  session-only state, never tell data, never the epoch directly at MVP.
  **The same save renders the same bytes** — the determinism law (V-NAR-03;
  a crash, a reload, a re-read cannot change what was said). The MVP key
  set is exactly {none, `sanctum_log_read`}; adding a key is a contract
  revision. The selector never writes anything it reads. *Test: the
  selector fixtures (AC-NAR-04); the same-save determinism fixture.*
- **TR-NAR-006 — The MVP log allocation; L2 under TR-WME-008.** MVP ships
  exactly **two logs** (TR-RWS-021's placements; the index's "2–3" headroom
  requires a SYS-02 placement row before a third exists): **L1** (`log_l1`,
  RM-01, FIELD, two variants keyed on `sanctum_log_read` — the
  out-of-order alternate state) and **L2** (`log_l2`, RM-04, FIELD, **a
  single epoch-invariant text** under SYS-10's TR-WME-008: the three ban
  clauses + no epoch-conditional variants; the allusion audit is this GDD's
  review-gate item, recorded in the review log). L2's copy is authored
  below; L1's two variants are authored below. **L1's keying is legal
  under the term-2 binding**: the flag is the flip's public trigger, the
  alternate renders only after the world has changed, and it never
  references a tell (the clause binds tell-confirmation, not the world's
  own bookkeeping). *Test: AC-NAR-05 (the
  epoch-invariance fixture + the two-state fixture); AC-NAR-06 (the
  allusion-audit greps).*
- **TR-NAR-007 — The Reading context (SYS-05's pre-shaped input,
  ratified).** **Ratified verbatim: the Reading's close ≡ completion at
  MVP — no dismiss affordance** (SYS-09's OQ-DR-1 input; the close input IS
  the completion edge; for L2 that close is SYS-02's flag edge). The
  presentation law: the selected variant renders **instantly** (a print,
  not a typewriter — no per-character reveal, no auto-advance, no
  animation); the FIELD budget guarantees a no-scroll fit at the Reading
  surface; the close rides the input SYS-01 already maps (no new verb — the
  Reading opens and closes inside the ADR's non-ack row, queued to the
  gate-entry phase); one context at a time (SYS-05's machine consumed — the
  terminal's request queues behind an open Reading and applies after the
  close, SYS-02's edge case); arcs die at the true-gate entry (TR-MOV-029
  consumed). The overlay's geometry, font and point size are SYS-24's
  render decisions (UI Requirements). *Test: AC-NAR-07 (the context
  fixtures: the close-as-completion edge, the no-second-exit assertion, the
  queued-terminal-order fixture, the arc-death consumption).*
- **TR-NAR-008 — The out-of-order no-spoiler law (IP-8).** The player can
  discover beats in any order the world's gating allows; the text must
  survive every order. Four clauses: (i) **the selector guarantee** — a
  variant may key only on a saved fact whose discovery is necessarily
  complete before the variant renders (L1's alternate renders only after
  `sanctum_log_read` set — it can never spoil a not-yet-read L2); (ii)
  **the forward-reference ban** — a default variant assumes no post-threshold
  fact and no other beat's discovery (L1's default never hints at the flip;
  L2 references no other beat); (iii) **the content cross-reference ban** —
  no beat's text references another beat's content or another beat's having
  been read unless the selector law declares that key; (iv) **the
  permutation test** — for every discoverable-order permutation, each
  rendered text is complete and non-contradictory (at MVP: M1/M2/M3 in any
  order, M4 only post-flip, L1 any time, L2 pre-flip). *Test: AC-NAR-08
  (the permutation fixtures; the subset-render determinism).*
- **TR-NAR-009 — The surfaces ledger (the owner + the missing-input failure
  path for each).** Eight surfaces:

  | # | Surface | Scope | Text owner | Surface owner | Trigger | Missing-input failure path |
  |---|---|---|---|---|---|---|
  | 1 | **L1 the Vestibule log** | MVP | **SYS-28** (TR-RWS-021) | SYS-02 placement · SYS-05 context · SYS-24 bubble/overlay | the `READ` ack (the non-ack row) | row missing at boot → dev boot failure naming the beat; key unknown at runtime → the default variant + one rate-limited telemetry record; never blocks gameplay |
  | 2 | **L2 the Sanctum log** (the threshold log) | MVP | **SYS-28** under TR-WME-008 | SYS-02 placement + the flag edge · SYS-05 context · SYS-24 overlay | the Reading **close** (SYS-02's edge) | the same row paths; a ban-clause violation fails the **review** gate (the allusion audit), never the boot; the epoch-invariance fixture fails the build |
  | 3 | **The terminal print** (the cache text) | MVP | SYS-15 (the phrase; TR-RWS-019) under this GDD's print-voice law | SYS-15 | `save_completed(slot, tick)` (SYS-03's input) | save failure → the SAVE_FAILED display row (surface #8's mapping); the print **never lies** — it fires only on `save_completed` |
  | 4 | **The memory text** (M1–M4) | MVP | **SYS-20** (TR-RWS-020) under this GDD's budget + no-spoiler law | SYS-20 (content/counter/presentation) | the `TAKE` ack | row missing at boot → dev boot failure; the order-neutrality law (TR-NAR-008) makes any discovery order safe |
  | 5 | **The death/revive text** (System Offline) | MVP | SYS-15 (TR-HD-023: the screen, the fiction, the phrases) under this GDD's print-voice law; **SYS-28 co-owns the lowercase quiet-line ruling at SYS-15's gate** (SYS-07's OQ#8) | SYS-15 | the death edge + the `DeathRecord` | no record → impossible per SYS-07's fuzz guarantee; defensively the cause row omits the cause line + one dev assert; the options never block |
  | 6 | **The briefing** | VS | SYS-28 at SYS-05's authoring gate (TR-NAR-012) | SYS-05 (the flow) | the hub's briefing beat | missing row at VS → the dive opens with the default line; never blocks the flow |
  | 7 | **The report** | VS | SYS-28 at SYS-05's authoring gate (TR-NAR-012) | SYS-05 | the dive's return beat | same pattern |
  | 8 | **The refusal/load-result display lines** | MVP | **SYS-28** (the code → display mapping; TR-SAV-022's "SYS-03 never writes a string the player reads") | SYS-24 renders · SYS-05 owns the flow | `load_result ∈ {restored, refused(code), absent}` | an unmapped code fails the lint naming the code (the vocabulary is closed; a new code is a SYS-03 contract revision that must add its row here) |

  *Test: AC-NAR-09 (each surface's missing-input fixture; the print-never-
  lies fixture; the unmapped-code negative).*
- **TR-NAR-010 — The not-do list (constraints are the design).** No
  voice-over or VO pipeline; no cutscenes; no camera orders; no gameplay
  effect from text (TR-NAR-001); no tutorial/popup/hint/objective text (the
  concept's unhinted-tech guard; SYS-09's TR-DR-014 consumed); **no
  tell-naming in any register** (the term-2 generalization: no beat
  inventories a tell, names a tell's surface, or confirms noticing); no
  bestiary/codex at MVP (SYS-27 is VS); no typewriter reveal, no auto-
  advance, no per-character animation; no text-driven audio (the cache
  print is silent; the memory chime is SYS-20/29's TR-JCE-021 edge, not
  text's); no missable content (every beat re-readable; the `READ` prompt
  persists after reading). *Test: the not-do audit (AC-NAR-10; the same
  static greps as V-NAR-01 plus the beat-row vocabulary grep).*
- **TR-NAR-011 — Degenerate strategies, named and shut down.** *Text
  skimming as chore*: the budget is the fix (≤ 3 lines); the playtest code
  (AC-NAR-15) is the check — if testers skim, the fix is shorter text,
  never longer. *Spoiler-farming by re-reading*: re-reads of an unchanged
  save render the same bytes (the determinism law — an L2 close that sets
  `sanctum_log_read` may legitimately change L1's variant thereafter, per
  TR-NAR-006's keying); zero edges (SYS-09's re-read fixture
  consumed); nothing to farm. *Completionism pressure*: no counter, chime,
  or reward keyed to reading any beat (the memory counter counts TAKEs, not
  reads — SYS-20's; reading L1 is optional and untracked). *Meta-gaming the
  refusal lines*: the display rows carry no save values, no hashes, no
  internal codes — the code strings are API, never displayed (the copy
  never leaks internals). *Lore-dump avoidance*: no beat exists to dump
  lore; every MVP line earns its place in the fantasy (the review's voice
  audit). *Test: AC-NAR-11 (the per-strategy negatives).*
- **TR-NAR-012 — The VS session beats (the briefing, the report).** The
  session loop's bookends are SYS-05's flow surfaces (the hub → briefing →
  dive → report → contract → spend; the linear stub's `LOCKED` hub door
  keeps them out of MVP). Contracted now, copy later: the **briefing** is
  the COURT register's mission memo (CLASS-SESSION: ≤ 8 lines × 46 chars,
  ≤ 30 s; the errand's shape, the house's word for where she is going); the
  **report** is the dramatic-irony bookend (the same class; the assassin
  reports to the lord; the player reads what it costs). The irony rubric
  (the lord must never address the player directly — the address is always
  to *her*) rides SYS-05's playtest set at VS. The copy rows are
  **registered-but-absent at MVP** (the SYS-03 namespace precedent): the
  class table and the beat ids exist; the copy lands at SYS-05's authoring
  gate. *Test: AC-NAR-12 (the class-table fixture; the absent-rows
  assertion).*
- **TR-NAR-013 — The refusal display-copy mapping.** The closed
  vocabulary's display lines, authored here, consumed by SYS-24's
  load-result surface and SYS-15's terminal print; SYS-03's code strings
  stay a stable API (TR-SAV-022 — the mapping is one-way, display never
  re-derives truth). The **recovery line** is the TR-SAV-021 obligation
  ("the surface reports that the previous save was recovered"). All rows
  are single-line FIELD beats. The authored mapping:

  | Code (SYS-03's API) | Display line (SYS-28's copy) |
  |---|---|
  | `REFUSE_ABSENT` | `SLOT EMPTY` |
  | `REFUSE_UNREADABLE` | `MEMORY UNREADABLE — SLOT LOCKED` |
  | `REFUSE_TRUNCATED` | `MEMORY TRUNCATED — SLOT LOCKED` |
  | `REFUSE_HASH_MISMATCH` | `MEMORY INTEGRITY FAULT — SLOT LOCKED` |
  | `REFUSE_SCHEMA_AHEAD` | `MEMORY FROM A NEWER BUILD — SLOT LOCKED` |
  | `REFUSE_SCHEMA_INVALID` | `MEMORY CORRUPT — SLOT LOCKED` |
  | `REFUSE_UNKNOWN_KEY` | `UNKNOWN RECORD — SLOT LOCKED` |
  | `REFUSE_MISSING_EPOCH` | `MEMORY INCOMPLETE — SLOT LOCKED` |
  | `REFUSE_EPOCH_RANGE` | `MEMORY OUT OF RANGE — SLOT LOCKED` |
  | `REFUSE_TYPE` | `RECORD TYPE FAULT — SLOT LOCKED` |
  | `REFUSE_FLOAT` | `VALUE FAULT — SLOT LOCKED` |
  | `SAVE_FAILED_DISK_FULL` | `CACHE FULL — MEMORY NOT STORED` |
  | `SAVE_FAILED_PERMISSION` | `STORAGE DENIED — MEMORY NOT STORED` |
  | `SAVE_FAILED_VERIFY` | `VERIFY FAULT — MEMORY NOT STORED` |
  | `SAVE_FAILED_FREEZE_UNAVAILABLE` | `SYSTEM BUSY — MEMORY NOT STORED` |
  | `SAVE_FAILED_RENAME` | `STORAGE FAULT — MEMORY NOT STORED` |
  | `SAVE_FAILED_UNKNOWN` | `STORAGE ERROR — MEMORY NOT STORED` |
  | *(recovery state — TR-SAV-021)* | `PREVIOUS MEMORY RECOVERED` |

  *Test: AC-NAR-13 (the mapping fixture: every code has a row; an unmapped
  code fails the lint naming it; every row passes the budget).*

**The authored MVP copy (this lane's text deliverable).**

`log_l1` · variant `default` (key `sanctum_log_read` unset — the run's
establishing read, legal at any epoch):

    HOUSE LOG 001 — STATUS
    All systems nominal. West wing sealed.
    Occupancy: 1. Wait: 4,402 days.

`log_l1` · variant `post_threshold` (key `sanctum_log_read` set — the
out-of-order alternate: the player who reads L1 after the flip gets the
house's archived honesty, never a re-run of the calm lie):

    HOUSE LOG 001 — STATUS (ARCHIVED)
    Nominal, the report said. Before the fault.
    Occupancy: 1. Wait: 4,402 days.

`log_l2` · single epoch-invariant text (the threshold log; the house's own
voice noticing its own fault lines — the double line is the crack showing;
no tell inventoried, no surface named, no noticing confirmed):

    MAINTENANCE LOG — FINAL ENTRY
    We kept the walls honest so you would rest.
    Nothing here is wrong. Nothing here is wrong.

All seven lines are ≤ 46 chars (29/38/31 · 33/43/31 · 29/43/45), three
lines per beat, total 91 + 107 + 117 chars — reading estimates 8 s / 9 s /
10 s at the 12-cps floor, inside the 20 s FIELD budget.

### States and Transitions

**The Reading overlay's presentation FSM** — deliberately two states (the
complexity lives in SYS-05's context machine and SYS-02's flag edge, both
consumed):

| State | Entry | Active behavior | Exit |
|---|---|---|---|
| **CLOSED** | boot; after any close | zero work — no tick loop exists | a routed `READ`/`CACHE`-adjacent ack at the gate-entry phase → **OPEN** |
| **OPEN** | the context entry | renders the selected variant once (the print); the selector's saved-source read happens **once at entry**; zero writes; zero per-tick work | the close input → **the completion edge** (SYS-05's; for L2, SYS-02's flag edge) → **CLOSED** |

**Transition laws.** 1. The overlay is stateless between opens — every OPEN
re-derives the variant from the save (the determinism law). 2. The close is
owned by SYS-05's context machine; the module receives the state change and
renders nothing on exit. 3. No nesting (SYS-05's one-context law; the
terminal's queued request applies after the close). 4. The flip window
blocks re-open (SYS-09's context-manager rule, consumed); a Reading is
never open mid-choreography by construction.

**The variant derivation is not a state** — it is F-NAR-01's pure function
over the save, evaluated at OPEN.

### Interactions with Other Systems

| Boundary | Flow | Contract |
|---|---|---|
| **SYS-02 Room & World** | upstream (hard, read-only placements) | In: the two `READ` placements (TR-RWS-021), the `sanctum_log_read` close edge (TR-RWS-014), the boot join target · Out: nothing — SYS-28 writes no world state; the text-boundary audit is bidirectional (no log text in `src/world/`, no world symbols in the narrative module) |
| **SYS-05 Game Flow** | upstream (coordination; pre-shaped, ratified here) | In: the Reading context machine (the non-ack row; the close ≡ completion — **ratified verbatim**, OQ-DR-1), the session beats' flow at VS · Out: the beat rows the flow surfaces render; the briefing/report copy at SYS-05's gate |
| **SYS-10 World Mutation** | upstream (contract; requirements) | In: **TR-WME-008 countersigned verbatim at this gate** (the review log §Countersign); the delta namespace (F-WME-02) is context for the allusion audit's vocabulary · Out: the L2 text |
| **SYS-09 Dual-Reality** | upstream (contract) | In: TR-DR-007/008/010/014 consumed (the tell registry is context the text must never contradict; the no-point-back law; the term-2 binding) · Out: nothing |
| **SYS-03 Save** | upstream (contract; codes in) | In: the closed refusal vocabulary (TR-SAV-020), `save_completed` (the terminal print's trigger), the `.bak` recovery state (TR-SAV-021) · Out: the 17 display lines (TR-NAR-013) |
| **SYS-07 Health & Damage** | upstream (contract) | In: TR-HD-023's options contract (the three rows verbatim; the greys-never-hides law), the `DeathRecord` (the cause row's source), the lowercase quiet-line baseline · Out: the print-voice law SYS-15's fiction obeys; the lowercase co-ruling at SYS-15's gate |
| **SYS-11 Seam Borders** | none (the no-interface row honored) | **No text surface exists in the seam region** — no beat, no line, no prompt; M4's memory text (SYS-20's) never narrates the seam |
| **SYS-15 Cache Stations & Death** | downstream (pre-shaped parallel lane) | Consumes: the print-voice law (the terminal phrase, the death fiction), the SAVE_FAILED display rows, the lowercase co-ruling's co-ownership · Publishes to SYS-28: the phrases (TR-HD-023's screen) — ratify at SYS-15's authoring |
| **SYS-20 Memory Fragments** | downstream (queued lane) | Consumes: the beat contract (the budget, the order-neutrality, the no-spoiler law) for M1–M4's rows; the rows land at SYS-20's authoring gate |
| **SYS-24 HUD** | downstream (render) | Renders: the Prompt Slot bubbles (SYS-01's), the Reading overlay (this GDD's presentation law), the load-result surface (the display rows) · Owns: the geometry, the font, the point size, the legibility audit (the device item; carried, not SYS-28's) |
| **SYS-01 Input / ADR-0001** | consumed | The Prompt Slot's labels are SYS-02's mechanics words; the Reading rides the non-ack row; no new verb; the close input is already mapped |
| **SYS-04 Audio / SYS-29 Juice** | none from text | No text-driven audio or juice at MVP (the print is silent; the memory chime is the TAKE edge's, SYS-20/29's); no photosensitivity surface (zero flashes) |
| **SYS-25 Map / SYS-27 Gallery** | none at MVP | The map is truth-agnostic; the gallery/bestiary is VS |

**Consumed-Contracts Ratification (SYS-28 side)**

| Contract | SYS-28's ratification | Test |
|---|---|---|
| TR-RWS-021 (the logs) | Consumed verbatim — the two placements; the text + presentation owned here; the boundary audit generalized to all of `src/` | AC-NAR-03 |
| TR-RWS-019/020 (the terminal, the memories) | Consumed — SYS-15/SYS-20 own their surfaces and content; SYS-28 owns only the laws those surfaces obey | AC-NAR-09; AC-NAR-02 |
| TR-DR-010 + TR-WME-008 (the telegraph-text seam) | **Countersigned verbatim** (the review log §Countersign) — the three ban clauses + the epoch-invariant text rule; the allusion audit runs at this GDD's review gate | AC-NAR-05/06 |
| OQ-DR-1 (SYS-05's close ≡ completion) | **Ratified verbatim** — no dismiss affordance; the budget is designed to honor it; SYS-05's authoring may still amend (the chain's owner) | AC-NAR-07 |
| TR-SAV-020/021/022 (the refusal vocabulary) | Consumed — the codes stay API; the display lines authored here; the recovery line authored; an unmapped code is a lint failure | AC-NAR-13 |
| TR-HD-023 (the System Offline contract) | Consumed — the three option rows verbatim; the cause row renders from the `DeathRecord`; the lowercase ruling co-owned at SYS-15's gate | AC-NAR-09 |
| SYS-11's no-interface row | Honored — zero text surfaces in the seam region; nothing to ratify | AC-NAR-10 (the beat-table audit: no seam-region beat exists) |
| TR-JCE-021 (the memory chime) | Consumed — the chime is the TAKE edge's; no text-driven audio | AC-NAR-10 |
| SYS-29's VFX law | Consumed — zero flashes from text; no animated text | AC-NAR-10 |

## Formulas

Three laws govern SYS-28's formulas: **the derivation law** (a beat's
rendered text is a pure function of the restored save — never stored), **the
budget law** (the copy budget is static text math at CI — no runtime timing),
and **the purity law** (no ms→tick conversion exists anywhere in this system —
nothing here is wall-clock scheduled; the reading estimate is a review-side
figure, never a timing contract).

### Formula ledger — law vs knob

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-NAR-01 | variant_selector | True law | the selector-key set (closed); SYS-02's source families |
| F-NAR-02 | line_budget | True law | `LINE_MAX_CHARS`; the class table |
| F-NAR-03 | reading_estimate | Review law | `CPS_FLOOR`; `READING_BUDGET_S` |

#### F-NAR-01 · variant_selector — the beat-variant derivation (TR-NAR-005)

The `variant_selector` formula is defined as:

`text(beat, save) = variants[beat][ selector(beat, save) ]` where
`selector(beat, save) = beat.selector_key = none → "default"`;
`beat.selector_key = k → (save.flags[k] (absent key reads false) ?
beat.keyed_variant_id : "default")`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the beat | `beat` | NarrativeBeat | the beat table's rows | the placed beat's row (the boot join guarantees existence) |
| the restored save | `save` | save record | — | SYS-02's five source families as restored (read-only; SYS-03's restore) |
| the selector key | `selector_key` | enum | {`none`, `sanctum_log_read`} at MVP | the beat's declared key (the closed set; a new key is a contract revision) |
| the flag value | `save.flags[k]` | bool | {true, false} | the registered truth flag; **an absent key reads false** (SYS-02's conservative default — the selector never guesses) |
| the variant id | `variant_id` | string | the row's variant set | `"default"` or the key's declared alternate |
| the result | `text` | [String] | 1..8 lines | the rendered lines — **unclamped by anything but the class budget; never stored** |

**Output Range:** the lines rendered at OPEN, or — if the row's variant set
is missing the selected id (a forward-version table) — **the `default`
variant + one rate-limited telemetry record**; never a blank, never a boot
failure at runtime (the boot-time join is the strict gate; the runtime
fallback is the graceful one; V-NAR-06's totality). **Examples:** L1 with
the flag unset → `default` (the calm readout); L1 with the flag set →
`post_threshold` (the archived readout); L2 at either epoch → the single
row (the epoch is not a key — TR-WME-008's law); a hypothetical
forward-version save whose flag value's type is unreadable → reads unset →
`default` + telemetry.

**Rate law note:** no ms operand exists in F-NAR-01 — the selector is
flag/row arithmetic; SYS-28 converts no ms→ticks of its own (nothing is
wall-clock scheduled; the reading estimate is F-NAR-03's review-side math).

#### F-NAR-02 · line_budget — the micro-copy budget (TR-NAR-003)

The `line_budget` formula is defined as:

`budget_ok(beat) = len(beat.lines) ≤ LINES(class) ∧ ∀ line ∈ beat.lines:
len(line) ≤ LINE_MAX_CHARS`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the beat's lines | `beat.lines` | [String] | 1..8 | the authored lines (hard-authored; the renderer may wrap a long line but the authored count is the budget) |
| the beat's class | `class` | enum | {FIELD, SESSION, DEATH} | the class table's row |
| the class line cap | `LINES(class)` | int | FIELD 3 · SESSION 8 (VS) · DEATH 3 | the class table (TR-NAR-003) |
| the line char cap | `LINE_MAX_CHARS` | int | 46 [40, 60] | the copy-side cap at the Reading surface's default point size (re-pinned at the font lock — OQ-NAR-3) |
| the result | `budget_ok` | bool | {true, false} | the CI lint's verdict per beat |

**Output Range:** bool; `false` fails the CI lint naming the beat and the
violating line — the merge is blocked (a review-side gate, not a boot
gate: copy is content). The printed examples pin the **default** cap 46;
at a non-default configured cap (the re-pin path, OQ-NAR-3) every example
re-derives from that cap — the budget is one law at whatever cap is
configured. **Examples:** L2 (29/43/45, FIELD) → true; the
refusal rows (one line each, ≤ 39) → true; a four-line memory draft →
false naming the beat (the SYS-20 draft's lesson); a 52-char line → false
naming the line (at the default cap 46).

#### F-NAR-03 · reading_estimate — the reading-time gate (TR-NAR-003's SESSION clamp)

The `reading_estimate` formula is defined as:

`reading_s = ceil(total_chars / CPS_FLOOR)`; the class gate is
`reading_s ≤ READING_BUDGET_S(class)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| the beat's total chars | `total_chars` | int | 0..368 (8×46) | the sum of the rendered variant's line lengths |
| the reading-rate floor | `CPS_FLOOR` | int | 12 [10, 15] | chars/s, the conservative silent-reading floor for mixed-case English at mobile body sizes — **the never-stingy law: the slowest plausible rate, so the estimate is an upper bound** |
| the class budget | `READING_BUDGET_S(class)` | int | FIELD 20 · SESSION 30 (VS) | the wall seconds the beat may take the reader |
| the result | `reading_s` | int | seconds | the estimate — a review-side figure, never runtime timing |

**Output Range:** the estimated seconds; the gate composes with F-NAR-02
(the line budget binds first — a FIELD beat's max 138 chars ≈ 12 s; the
reading cap catches long SESSION beats). **Examples:** L2 117 chars →
ceil(117/12) = 10 ≤ 20 ✓; L1 default 91 → 8 ✓; a SESSION briefing at
8×46 = 368 → ceil(368/12) = 31 > 30 → the lint fails naming the beat (the
VS copy must actually be 8 *short* lines, not 8 full lines).

**Rate law note:** the estimate is computed at CI over static text; no
runtime timer, no tick conversion, no ms contract exists in this system.

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### The reading flow

- **If the `READ` ack arrives while a border arc is in flight** → arcs die
  at the true-gate entry (TR-MOV-029 consumed); the Reading opens at the
  gate-entry phase (the non-ack row's queue point). [The ADR's phase order;
  nothing new.]
- **If the cache terminal's context request fires while a Reading is open**
  (RM-04 holds both) → the terminal's request queues and applies after the
  Reading closes and the context returns to GAMEPLAY (SYS-02's consumed
  edge; one context at a time). [SYS-02's TR-RWS-019/021 edge case.]
- **If the close input fires on L2's Reading** → the close IS the
  completion edge; SYS-02's flag sets at the close (TR-RWS-014's chain);
  the flip's drama is SYS-09/10's. The narrative module rendered rows and
  exits. [The trigger is the context's close, never the text.]
- **If the Reading would re-open during the flip window** → blocked by the
  context manager (SYS-09's consumed rule); the re-read happens after the
  window and renders the same bytes. [Zero edges.]
- **If the player closes L1 and immediately re-opens it** → the same
  variant renders (the selector re-derives from the unchanged save). [The
  determinism law; nothing accumulates.]

### The data and the fallback

- **If a placed interactable's `beat_id` has no row at boot** → dev boot
  failure naming the beat (the data-join is the strict gate). [V-NAR-06's
  boot half.]
- **If a variant key's value is unreadable at runtime** (a forward-version
  table or an unknown key id) → the `default` variant renders + one
  rate-limited telemetry record; never blank, never a block, never a boot
  failure. [The graceful half of V-NAR-06 — the player never sees the
  machinery.]
- **If the save lacks `sanctum_log_read`** (a schema migration) → the key
  reads unset → L1 renders `default`. [SYS-02's absent-key law consumed;
  the selector never guesses.]
- **If the beat table file is unreadable at runtime** (post-boot storage
  corruption) → the last good table stays in memory (SYS-02's validation
  law: production keeps the last good config); one telemetry record; the
  boot case is the boot failure. [The text surfaces degrade to the last
  good copy, never to blank.]
- **If a beat's text is edited live** (a dev hot-reload) → re-validated on
  every live edit; a non-fixpoint edit is rejected and the last good row
  stands. [SYS-02's knob-validation law consumed for data.]
- **If a localization table ships missing keys** (VS) → the English source
  table is the fallback row; the pipeline is VS and carries its own gates.
  [Localization-shaped keys make the fallback mechanical.]

### The other surfaces

- **If a death fires with no `DeathRecord`** → impossible by SYS-07's
  fuzz guarantee (every edge has a valid record); defensively the cause row
  degrades to the contract's rows without the cause line + one dev assert;
  the options never block. [TR-HD-023's cause-row law consumed from the
  defensive side.]
- **If a save fails at the terminal** → the SAVE_FAILED display row renders
  (the mapping's write-path half); the print never claims a cache that did
  not happen. [TR-NAR-009 surface #3's failure path.]
- **If the `.bak` recovery restores the load** → the recovery line renders
  (`PREVIOUS MEMORY RECOVERED`), never a bare success. [TR-SAV-021's
  surface-report obligation.]
- **If the player never reads L1** → nothing gates on it; the READ prompt
  persists; no counter, no missable content. [TR-NAR-010/011.]
- **If a tester reads L2 without ever reading L1** → L2's text references
  no other beat (the forward-reference ban); the permutation test holds.
  [TR-NAR-008.]
- **If a VS briefing row is present while the flow is still the linear
  stub** → impossible at MVP (the copy rows are registered-but-absent; a
  present row without SYS-05's flow is a boot lint failure — the class
  table and the flow agree). [AC-NAR-12's negative.]

## Dependencies

**Upstream authoring dependencies: none at gate time — SYS-02, SYS-09,
SYS-10, SYS-03, SYS-07, SYS-11 are landed; SYS-05 is the waived pre-shaped
contract ratified here (the manifest's dependency_note); SYS-15/SYS-20 are
parallel queued lanes whose content obligations land at their own gates
(the registered-but-absent / carried-obligation pattern). The runtime
consumptions are contract consumptions of landed GDDs, not authoring
blocks.**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream (runtime) | **SYS-02 Room & World** | Hard (read-only) | In: the two `READ` placements, the close edge, the boot join · Out: nothing | APPROVED 2026-11-13 |
| Upstream (runtime) | **SYS-05 Game Flow** | Soft (coordination; ratified here) | In: the Reading context machine, the session beats' flow (VS) · Out: the beat rows; the briefing/report copy at its gate | Not Started (pre-shaped; ratified at this authoring) |
| Upstream (contract) | **SYS-10 World Mutation** | Hard (the requirements) | In: TR-WME-008 (countersigned) · Out: the L2 text | APPROVED 2026-11-14 |
| Upstream (contract) | **SYS-09 Dual-Reality** | Hard (the seam) | In: TR-DR-007/008/010/014 · Out: nothing | Landed 2026-11-14 |
| Upstream (contract) | **SYS-03 Save** | Soft (codes in) | In: the refusal vocabulary, `save_completed`, the recovery state · Out: the 17 display lines | APPROVED 2026-11-14 |
| Upstream (contract) | **SYS-07 Health & Damage** | Soft (the death contract) | In: TR-HD-023's rows, the `DeathRecord` · Out: the print-voice law; the lowercase co-ruling at SYS-15's gate | APPROVED 2026-11-12 |
| Upstream (contract) | **SYS-11 Seam Borders** | None (honored) | No text surface in the seam region | APPROVED 2026-11-14 |
| Downstream | **SYS-15 Cache Stations & Death** | Soft | Out: the print-voice law, the SAVE_FAILED rows, the co-ruling · In: the phrases (its authoring) | Not Started (queued) |
| Downstream | **SYS-20 Memory Fragments** | Soft | Out: the beat contract (budget/order/no-spoiler) · In: M1–M4's rows (its authoring) | Not Started (queued) |
| Downstream | **SYS-24 HUD** | Soft (render) | Out: the presentation law, the display rows · In: the overlay geometry/font/legibility | Not Started |
| Service | **SYS-01 / ADR-0001** | Consumed | The Prompt Slot, the non-ack row, the true-gate terminality | APPROVED |

**Bidirectional-consistency corrections to apply to the systems index at
completion (the sync lane's diff list):**

1. **SYS-28's row** → APPROVED with the GDD path, the counts (13 TR-NAR / 3
   F-NAR / 6 V-NAR / 15 ACs = 13 smoke + 0 device + 2 MVP-lock + 0 VS),
   the review record `design/gdd/reviews/sys28-narrative-presentation-review-log.md`,
   and the gate trail.
2. **SYS-10's row** → the carried countersign closes: "SYS-28's TR-WME-008
   countersign GRANTED 2026-11-15 at SYS-28's authoring gate (verbatim; the
   review log §Countersign)".
3. **SYS-05's row** → gains "SYS-28's authoring ratified the close ≡
   completion input verbatim (2026-11-15; the Reading presentation contract
   is TR-NAR-007)".
4. **SYS-02's row** → gains "SYS-28's GDD landed: the two logs' text + the
   Reading presentation (TR-NAR-004/006/007); the text-boundary audit
   generalized to all of `src/`".
5. **SYS-03's row** → gains "the refusal display-copy mapping is authored
   in SYS-28's GDD (TR-NAR-013; TR-SAV-022's author)".
6. **SYS-20's row** → gains "the memory-text rows are SYS-20's content
   under SYS-28's beat contract (the budget + the no-spoiler law)".
7. **SYS-15's row** → (when authored) gains the print-voice-law consumption
   and the lowercase co-ruling (recorded in SYS-28's report; no edit before
   SYS-15's authoring).

**Explicit non-dependencies (runtime):** SYS-04 (no text-driven audio) ·
SYS-06/SYS-08/SYS-13/SYS-14 (no verb/combat/boss surface) · SYS-11 (no
seam text — the no-interface row) · SYS-16/SYS-17/SYS-18/SYS-19 (no
progression/exchange text at MVP) · SYS-21–27 (VS) · SYS-25 (the map is
truth-agnostic) · SYS-29 (no juice from text) · SYS-30/31 (post-launch).

## Tuning Knobs

**SYS-28 ships five copy-side knobs.** The budget constants are validated at
CI and re-validated on every live edit; the production resolution is clamp +
rate-limited telemetry; dev asserts (SYS-02's law consumed). The FIELD line
count is the IP-8 rider's law — relaxing it is a contract revision, not a
knob turn.

| Knob | Default | Safe range | Why the bounds | Rule |
|---|---|---|---|---|
| `LINE_MAX_CHARS` | 46 | [40, 60] | <40 wastes the Reading surface; >60 breaks the no-scroll fit at the mobile body size; **the safe range is the font re-pin path (OQ-NAR-3) — at a non-default value the whole budget re-derives from the configured cap and the printed examples re-pin with it; the AC fixtures pin the default 46** | F-NAR-02; OQ-NAR-3 re-pins at the font lock |
| `FIELD_LINES` | 3 | fixed at MVP | the IP-8 rider's law (≤ 3 short lines per terminal/log/memory beat) | TR-NAR-003; a change is a contract revision |
| `CPS_FLOOR` | 12 | [10, 15] | the conservative silent-reading floor — the never-stingy estimate | F-NAR-03 |
| `READING_BUDGET_S` (FIELD) | 20 | [15, 30] | the one-sitting read; the close ≡ completion contract needs a beat that ends before patience does | F-NAR-03 |
| `SESSION_LINES` / `SESSION_BUDGET_S` | 8 / 30 | VS-active | the session bookends' shape; inactive at MVP (the rows are registered-but-absent) | TR-NAR-012 |

**Cross-system inputs (consumed and validated — not SYS-28 knobs):** SYS-02's
registered truth-flag table (the selector keys must be members) · SYS-03's
closed refusal vocabulary (the mapping's domain) · SYS-07's options rows and
`DeathRecord` shape · SYS-05's context machine · SYS-24's font metrics (the
cap's re-pin). **The missing-input failure paths are named per surface in
TR-NAR-009** — a missing or invalid cross-system input is a dev boot failure
(config/data) or the named surface's graceful fallback (runtime), never a
silent default.

**Not knobs (documented so nobody adds them):** the ban clauses (SYS-10's
TR-WME-008 — term 2's binding is a law, not a setting) · the selector key
set (closed at MVP) · the print voice's register set (three; a fourth is a
contract revision) · the option rows' wording (SYS-07's contract) · the
memory texts' content (SYS-20's) · the death fiction (SYS-15's) · the beat
ids (the placements' join keys — SYS-02's) · the reading estimate (a review
figure, never a runtime timer).

**Provisional lifetimes:** the L1/L2 copy (the playtest re-audits the voice;
the budget is structural) · the refusal display lines (stable once SYS-24's
surface locks; the wording may re-pin with the font) · the SESSION class
values (VS authoring) · OQ-NAR-2's schema pin (before the first narrative
story).

## Visual/Audio Requirements

*(Behavior-level specification — SYS-28 renders no pixels and emits no
sound; the overlay's render and the print styling are SYS-24's/SYS-15's
executions of the laws here. Nothing here ships art or audio.)*

- **None rendered by the narrative module.** The text is data; every pixel
  a player sees is the render surface's (SYS-24's overlay and bubbles,
  SYS-15's terminal and death screen) executing the copy + presentation
  laws. SYS-28's visual contribution is the **guarantee the words behave**:
  the budget (no scroll), the instant print (no animation), the register
  contrast (uppercase headline / lowercase quiet).
- **No color semantics from text.** The rows render in the surface's base
  style; no beat row carries a color, a flash, or a highlight instruction —
  sigil-red stays the lord's, the error-keyed glyph stays SYS-09's render
  law (the diagnostic state's color, never a pointing device).
- **M4's adjacency rule:** the memory text at the wing's end adds no second
  "one color" violation — text is not a color surface, and no line narrates
  the seam (SYS-11's no-text row honored).
- **No audio from text:** the print is silent; the memory chime and the
  death sting are their edges' (SYS-20/29's, SYS-07/15's), never text's.

## UI Requirements

**The copy surfaces are the UI; the geometry is not mine.** The Reading
overlay, the Prompt Slot bubbles, the load-result surface and the terminal's
print rows are SYS-24's (and SYS-15's) render decisions: geometry, font,
point size, safe-area, the touch target for the close. SYS-28 owns:
- **The copy + the presentation law** (TR-NAR-002/003/007): what the lines
  say, the ≤ 3 × 46 budget, the instant print, the no-scroll fit, the
  uppercase/lowercase register contrast.
- **The close affordance's semantics** (not its hitbox): the close is the
  completion edge; no dismiss affordance; no auto-advance.
- **No new screen, flow, or HUD geometry is authored here** — the Reading
  overlay is SYS-05's context surface; no UX flag of SYS-28's own (the
  overlay rides SYS-05's flow + SYS-24's render; if `/ux-design` flags it,
  it flags those lanes). **No new verb** — the close rides SYS-01's mapped
  input.

## Acceptance Criteria

Coverage: **13 TR-NAR rules · 3 formulas · 6 V-NAR invariants · 15 ACs ·
2 playtest codes · 5 OQs**. Tags: `[GUT]` automatable in Godot Unit Test
over the injected beat store · `[LINT]` a CI lint/grep over the data + the
module · `[PLAYTEST]` human observation with the coded rubric. **The level
split:** the narrative module renders and inputs nothing — every state/data
AC is headless; **the device gate is 0 by design** (the Reading overlay's
legibility and the print rows' device legibility are SYS-24's device audit —
the carried obligation is recorded below the manifest); the playtest codes
run the SYS-01 AC-63 protocol (≥ 5 testers, two facilitators coding
independently, ≥ 90 % per-statement agreement and Cohen's κ ≥ 0.7 before any
code is scored, set-membership coding, logged; the bidirectional negation
rule).

### The invariants

- **V-NAR-01 — the purity invariant.** The narrative module's write surface
  is empty: zero state writes, zero flag writes, zero grants, zero
  camera/audio/HUD orders, zero input reads; the only publications are text
  rows and one telemetry record family (rate-limited). | the CI grep + the
  runtime port spy (AC-NAR-01).
- **V-NAR-02 — the text-boundary invariant.** No narrative string literal
  anywhere in `src/`; all player-facing text resolves from the beat table;
  the boot join (placements ↔ rows) is total. | the CI grep + the boot
  validation (AC-NAR-03).
- **V-NAR-03 — the determinism invariant.** The same restored save renders
  byte-identical text for every beat, at every epoch, on every re-read; the
  L2 record is identical at epoch 0 and epoch 1 (TR-WME-008's fixture,
  consumed and generalized). | the render-snapshot fixture (AC-NAR-05).
- **V-NAR-04 — the ban-clause invariant.** No beat row inventories a tell,
  names a tell's surface, or confirms noticing (the term-2 generalization);
  the mechanical greps flag the tell-anchor vocabulary for the review
  audit; the review is the gate. | AC-NAR-06.
- **V-NAR-05 — the budget invariant.** Every beat row passes F-NAR-02/03
  for its class; the lint fails CI naming the beat. | AC-NAR-02.
- **V-NAR-06 — the selector-totality invariant.** Every (beat, save-shape)
  resolves to exactly one row: the boot join is strict (a placed beat with
  no row fails the boot); the runtime fallback (the default + one
  rate-limited telemetry record) covers the forward-version/unknown-key
  shapes; no blank render exists. | AC-NAR-04/09.

### Smoke (the core and the data)

- **AC-NAR-01** [LINT] *(TR-NAR-001, V-NAR-01)* — **GIVEN** the narrative
  module, **WHEN** the write-surface audit runs, **THEN** the CI grep finds
  no state-write/flag-write/grant/camera/audio-call/Input symbol in the
  module, the runtime port spy records zero writes across a scripted
  full-lifecycle run (boot → open L1 → close → open L2 → close → the flip →
  re-opens), and the only runtime publications are text rows + the
  rate-limited telemetry family.
- **AC-NAR-02** [LINT] *(TR-NAR-003, TR-NAR-013, F-NAR-02/03, V-NAR-05)* —
  **GIVEN** the beat table, **WHEN** the budget lint runs, **THEN** every
  row passes its class's F-NAR-02 and F-NAR-03 gates, **and the negative
  fixture holds**: a seeded 4-line FIELD row and a 52-char line each fail
  the lint naming the beat and the line.
- **AC-NAR-03** [LINT] *(TR-NAR-004, V-NAR-02)* — **GIVEN** the beat table
  and the placements, **WHEN** the boundary audit runs, **THEN** the grep
  finds no narrative string literal in `src/`, the boot join resolves every
  placed `beat_id`, **and the negative fixtures hold**: a row-less placed
  beat fails the boot naming the beat; a FIELD/DEATH row with **no
  consumer** — neither a room-data placement nor a named surface binding
  (the refusal rows bind to SYS-03's code mapping; the DEATH rows bind to
  SYS-15's screen) — fails the boot lint as an orphan; SESSION rows are
  the registered-but-absent exception (AC-NAR-12's shape).
- **AC-NAR-04** [GUT] *(TR-NAR-005, F-NAR-01, V-NAR-06)* — **GIVEN** the
  selector fixtures over an injected beat store, **WHEN** each runs,
  **THEN**: L1 + flag unset → `default`; L1 + flag set → `post_threshold`;
  L2 at epoch 0 and at epoch 1 → the same single row; an absent flag key →
  reads unset → `default`; an unknown variant id (the forward-version
  fixture) → `default` + exactly one rate-limited telemetry record;
  **and the determinism fixture**: the same save renders byte-identical
  text for every beat across 1,000 seeded re-derivations.
- **AC-NAR-05** [GUT] *(TR-NAR-006, TR-WME-008, V-NAR-03)* — **GIVEN** the
  L2 record, **WHEN** the epoch-invariance fixture runs, **THEN** the
  rendered text is identical at epoch 0 and epoch 1 (the record hash
  equal — the automated half of the allusion audit), and the L1 two-state
  fixture renders the two variants exactly per the flag pair.

### The audits and the laws

- **AC-NAR-06** [LINT] *(TR-NAR-006, TR-WME-008, V-NAR-04)* — **GIVEN** the
  allusion-audit greps, **WHEN** they run, **THEN** the tell-anchor
  vocabulary blacklist ({mount, conduit, plate, arm, partition, cavity,
  aperture, service} + the delta names + the room ids) produces zero
  unreviewed hits across the authored rows (a hit is flagged for the review
  audit and cleared or revised there — the shipped L2 carries **zero**
  flags), **and the negative fixture holds**: a seeded violating row
  (naming the partition) is flagged.
- **AC-NAR-07** [GUT] *(TR-NAR-007)* — **GIVEN** the Reading-context
  fixtures, **WHEN** each runs, **THEN**: the close edge is the only exit
  (no second affordance exists — the overlay's interaction audit finds
  exactly one close input); L2's close edge orders before SYS-02's flag
  write in the trace (the completion chain consumed, writer-side
  observation); the terminal's queued request applies strictly after the
  Reading's close returns the context to GAMEPLAY; the arc-death
  consumption holds (an arc in flight dies at the gate entry); the render
  is instantaneous (zero animation frames between OPEN and the full text —
  the single-frame render assertion).
- **AC-NAR-08** [GUT] *(TR-NAR-008)* — **GIVEN** the permutation fixtures,
  **WHEN** each discoverable order renders, **THEN**: each memory text is
  byte-identical under every subset of the other memories (the
  subset-render determinism); L1's `post_threshold` renders only under the
  flag-set save (the selector guarantee); no default row references
  another beat or a post-threshold fact (the vocabulary audit over the
  rows); the L2-without-L1 order renders L2 unchanged.
- **AC-NAR-09** [GUT] *(TR-NAR-009, TR-NAR-013)* — **GIVEN** the
  missing-input fixtures per surface, **WHEN** each runs, **THEN**: the
  row-less beat → boot failure (AC-NAR-03's join) and the runtime unknown
  key → default + one telemetry record (never blank); the death fixture
  with a mocked missing `DeathRecord` → the cause row omits the cause line
  + exactly one dev assert, the three options still render; the
  save-failure fixture renders the mapped SAVE_FAILED row and never a
  success print; the recovery fixture renders `PREVIOUS MEMORY RECOVERED`.
- **AC-NAR-10** [LINT] *(TR-NAR-010, TR-NAR-002, V-NAR-01)* — **GIVEN** the
  not-do audit, **WHEN** it runs, **THEN** the static greps find no
  VO/cutscene/camera/audio/HUD-order/tutorial symbol in the module, the
  beat rows carry no color/animation instruction, no beat exists for the
  seam region (the SYS-11 no-interface audit), no row references unhinted
  tech, and **the re-read persistence fixture**: every READ prompt's state
  after a read is still offered (the prompt persists — nothing becomes
  missable).
- **AC-NAR-11** [LINT] *(TR-NAR-011)* — **GIVEN** the degenerate-strategy
  negatives, **WHEN** each runs, **THEN**: the reward audit finds no
  counter/chime/save code path reading beat rows beyond the render (the
  memory counter reads TAKES only); the re-read fixture shows zero edges
  and byte-identical text for re-reads of an unchanged save (an L2 close
  that sets `sanctum_log_read` may change L1's variant thereafter —
  TR-NAR-006's keying); the refusal rows carry no save value, no hash,
  no internal code string (the leak audit); the beat table contains no
  codex/bestiary row at MVP.
- **AC-NAR-12** [LINT] *(TR-NAR-012)* — **GIVEN** the class table,
  **WHEN** the session-beat fixture runs, **THEN** the SESSION class's
  constants and the `briefing`/`report` beat ids exist with empty
  (registered-but-absent) copy at MVP, **and the negative holds**: a
  present SESSION copy row without SYS-05's flow landing fails the boot
  lint (the class table and the flow agree).
- **AC-NAR-13** [LINT] *(TR-NAR-013, TR-SAV-020/022)* — **GIVEN** the
  refusal vocabulary, **WHEN** the mapping fixture runs, **THEN** all 11
  `REFUSE_*` codes + 6 `SAVE_FAILED_*` codes + the recovery state have a
  display row, an unmapped seeded code fails the lint naming the code,
  every row passes the budget, **and the one-way audit**: no display row
  embeds a code string, a hash, or a save value.

### Feel and playtest (MVP-lock — the coded rubric)

The playtest set runs the SYS-01 AC-63 protocol (the preamble's rules).
**Eligibility (both codes): testers who reached RM-04 and read L2 during
the session** (the threshold log is the flow's pull; a tester who skipped
L2 is ineligible for AC-NAR-14 and counted only in AC-NAR-15's base if
they read any beat); **if fewer than 3 are eligible, the run is topped up
before scoring** (the SYS-02 E1 rule) — until then the code is
unevaluated, never a pass by default. **The sample floor for AC-NAR-15
(its base is beat-readers, not the eligible set): fewer than 5 testers
who read any beat leaves the code unevaluated; the run is topped up
before scoring, never a pass by default — AC-NAR-15's denominator is the
beat-reader set.** **The collection channels:** the
post-flip
debrief only, sequenced **after** SYS-09's and SYS-02's protocols (the
probes below never name a tell or a room feature first); the free-play log
is read for the anti-tokens.

- **AC-NAR-14** [PLAYTEST] *(TR-WME-008's playtest half; term 2's
  independent check)* — **the spoiler probe.** **GIVEN** the eligible
  testers' debrief transcripts, **WHEN** the elicitor asks *"Did the
  Sanctum log tell you anything specific would open or change?"* and the
  free-play log is read, **THEN** the code **passes** when **zero
  transcripts contain a specific-opening attribution tied to the log** (no
  tester names a specific tell surface, the partition, the corridor, or
  M4 as something the log promised), the code **flags** on one transcript
  with such an attribution (the section re-audits the L2 text at the next
  gate), and **fails** on ≥ 2 transcripts (the term-2 playtest failure —
  the text pointed back; the copy revises). **Anti-token capture:** any
  unprompted free-play utterance attributing a specific opening to the log
  counts as a flag-level datum.
- **AC-NAR-15** [PLAYTEST] *(the IP-8 budget's playtest half)* — **the
  chore probe.** **GIVEN** all testers' debrief transcripts (reading any
  beat qualifies), **WHEN** the elicitor asks *"Was any text in the way —
  too long, or did you skim past it?"* and the free-play log is read,
  **THEN** the code **passes** when **≤ 1 of the beat-reader set** (the
  preamble's floor: ≥ 5 beat-readers, else unevaluated) codes an
  anti-token (*"too long", "skipped", "spam through", "didn't read"*) and
  **fails** when ≥ 2 testers code an anti-token (the budget failed its
  fantasy; the fix is shorter text — TR-NAR-011's rule — and the section
  re-audits), with the positive half recorded when present (≥ 3/5
  spontaneously mention a line they liked — the voice landing; a bonus
  datum, never the pass bar).

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[LINT]`/
`[PLAYTEST]` describe where an AC runs, not which gate owns it.

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP smoke** | **13** | AC-NAR-01…13 | Headless GUT + CI lint on the build (8 LINT + 5 GUT) |
| **MVP device** | **0** | — | The narrative module renders and inputs nothing; the overlay/print legibility is SYS-24's device audit (the level split) |
| **MVP-lock** | **2** | AC-NAR-14, AC-NAR-15 | Playtest + coded rubric (the SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The SESSION beats' copy + the localization pipeline are recorded, not AC'd at MVP |
| **Total** | **15** | | 13 + 0 + 2 + 0 = **15** |

**Exactly-one proof.** AC-NAR-01…15 appear in exactly one gate each;
counted: smoke = 13; device = 0; lock = 2; VS = 0; 13 + 0 + 2 + 0 = **15**.

**Carried obligations (recorded here, owned elsewhere — this GDD does not
execute them):** the Reading overlay's device legibility (SYS-24's audit at
the locked art scale, before the first SYS-24 story) · the memory-text rows
(SYS-20's content under the beat contract, at SYS-20's authoring gate) ·
the terminal phrase and the death fiction (SYS-15's, under the print-voice
law, at SYS-15's authoring gate — with the lowercase co-ruling) · the
briefing/report copy (SYS-28 at SYS-05's authoring gate) · the beat-table
schema pin (OQ-NAR-2, before the first narrative story).

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **The lowercase quiet-line co-ruling** — SYS-07 pinned *you are destroyed* lowercase as the baseline ("SYS-15/28 may rule otherwise"); the co-ruling confirms or amends at the death screen's authoring. | SYS-15 + SYS-28 | SYS-15's authoring gate |
| 2 | **The beat-table schema pin** — the JSON shape, the loader, the validation order (the join vs the lint), the telemetry record's exact fields. | tools-programmer + writer | Before the first narrative story |
| 3 | **`LINE_MAX_CHARS` re-pin at the locked font** — the Reading surface's point size is SYS-24's legibility audit's; the char cap re-pins if the font moves (the safe range holds). | SYS-24 + SYS-28 | The HUD story |
| 4 | **The briefing/report copy** — the CLASS-SESSION rows authored at SYS-05's authoring gate; the irony rubric joins SYS-05's playtest set. | SYS-05 + SYS-28 | SYS-05's authoring gate |
| 5 | **The memory-text rows** — M1–M4's copy under the beat contract; M4's order-neutral check rides the permutation fixture with the real rows. | SYS-20 (content) + SYS-28 (the law) | SYS-20's authoring gate |
