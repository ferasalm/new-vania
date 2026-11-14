# SYS-04 Audio Core — review log

> The lane's running log. Authoring entries first; the CD gate, the three seats, the
> spot-check, and the micro-check append below in order.

## 2026-11-14 — lane start (authoring phase)

- **Prompt**: `production/orchestration/prompts/lanes/SYS-04.md` v1.0.0, hash
  `4e689924ac17` — **matches** the manifest SYS-04 row. Verified.
- **Worktree**: `../new-vania-sys04-audio-core`, branch `docs/sys04-audio-core`,
  clean at `e8b194d` (origin/Main, the SYS-11 landing).
- **Context read (once, in the lane's order)**:
  - `design/gdd/dual-reality-state.md` — TR-DR-004 (E1–E7 + G1–G7), TR-DR-011
    (the arena steel-hum expectation), TR-DR-012 (the liminal wing), the audio
    interaction row, AC-DR-27 (the zero-arena-bed-orders assertion), the
    no-flip-duck ruling in the Visual/Audio section.
  - `design/gdd/world-mutation-epochs.md` — TR-WME-004 (the compute-then-commit
    transaction and the abort), the SYS-04 interaction row (the abort case named),
    AC-WME-07 (the E3b-side assertion), the latched-resume rider (i).
  - `design/gdd/juice-feedback.md` — TR-JCE-027 (the closed edge list + the single
    duck request), TR-JCE-018 (no sting audio), TR-JCE-021 (the memory chime +
    the Leap-Stone grant), AC-JCE-31/32, OQ-J7, the `DEATH_DUCK_DB` knob row.
  - `design/gdd/seam-borders.md` — AR-SMB-01..04 (zero audio publications; the bed
    continues; the no-duck ruling; M4's chime), TR-SMB-006/011.
  - `design/gdd/combat.md` — TR-CMB-021/022/023 (the clash pair's two pulses, the
    hit-stop pairing, the freeze as a clock not a gate).
  - `design/gdd/health-damage.md` — TR-HD-013/015/035/036/038 (the
    `DamageNumber`/`HealEdge`/`DeathRecord`/`DefeatEvent` edges).
  - `design/gdd/systems-index.md` — the SYS-04 row (Foundation, MVP "Yes
    (minimal)", no dependencies, owner sound-designer) + the design-order row #16
    + the IP-7 rider note.
  - `docs/framework/technical-preferences.md`, `docs/engine-reference/godot/VERSION.md`
    (Godot 4.7.2, 60 fps, ~150 MB RAM ceiling, mobile-first), the QA plan §5.1
    (the Pixel 6a reference SKU).
- **Deliverable**: the context + feasibility brief, the E1–E7 consumption table,
  the receding-first law, the freeze brackets, the arena hum, the no-duck ruling,
  the closed edge list, the architecture/mix plan, and OQ-AUD-1..8 — delivered in
  `production/session-state/lane-SYS-04-report.md`.
- **Draft**: `design/gdd/audio-core.md` — the skeleton + sections A (Overview) and
  B (Player Fantasy), marked `Draft — skeleton`, awaiting user approval of the
  section plan.
- **Contract revisions requested**: none. Every input consumed as published.
- **Notes / decisions taken in-session (to be ratified at section authoring)**:
  1. E1's arm is **silent** (no pre-telegraph) — the contract's "the world still
     normal" at E1.
  2. The tear hook is the **licensed exception** to the bracket's no-new-one-shot
     rule: it is the flip's own voice, declared at τ0 by E1–E7; the bracket forbids
     *foreign* one-shots, loop restarts, and beat-reading snapshot changes.
  3. The recede is a **per-voice gain ramp**, never a `duck_request` — otherwise
     the "exactly one duck family" audit would find two.
  4. The score is **untouched** by the flip (no score duck, no stinger, no
     snapshot change) — the world's air turns over; the player's music does not.
     (Raises OQ-AUD-2: the MVP score's scope + the "beat-aligned" reading.)
  5. The arena bed is a **distinct epoch-invariant asset** so the `ambient_shift`
     target set is trivially assertable (OQ-AUD-5).
  6. Zero UI voices and zero stochastic ambience detail one-shots at MVP, so the
     closed-list audit stays exact (OQ-AUD-4).

## 2026-11-14 — authoring complete (sections A–K)

- **User approval (this session)**: the section plan A–K as proposed; the target
  counts (~35 TR / 7 F / 7 V / ~24 ACs / ~12 knobs / 8 OQs); OQ-AUD-1 = the
  provisional `PROV_AUD_*` roles; OQ-AUD-2 = one score loop, the beat = the 60 tps
  tick grid, the score untouched by the flip; OQ-AUD-3 = ratify −6 dB (OQ-J7).
- **Authored**: all eleven sections. Landed counts: **37 TR-AUD · 7 F-AUD ·
  7 V-AUD · 24 ACs (16 GUT · 3 LINT · 3 DEVICE · 2 PLAYTEST) · 13 knobs · 8 OQs
  (3 resolved, 5 open)**. Status set to `In Review`.
- **Resolved in-session**: OQ-AUD-1/2/3 (user). OQ-AUD-4..8 remain open with
  recommendations assumed for authoring; a change reopens §E/§G/§H.
- **Contract revisions requested**: none.
- **Next**: the CD gate.

## 2026-11-14 — CD gate (seat 1)

- **Seat**: `cd-gate` (glm-5.3-flash). **Verdict: APPROVED — zero blockers.**
- **Recommendations (8, all applied as one-line repairs)**: the G5 wing paraphrase;
  the asset arithmetic (25 one-shots / 29 files; the bands are runtime pitch
  shifts); the duck range unified at [−12, 0]; AC-AUD-11's unreachable P1 steal;
  the playtest cohort wording; TR-AUD-020's cache MEMORY CACHED trigger; the
  room-entry input path (SYS-02's room activation) + §C's opening; the
  audio-director countersign on the material/acoustic split.

## 2026-11-14 — three-seat panel

- **creative** (glm-5.3-flash): **NEEDS REVISION — 3 blockers** (no perceptual
  bed-contrast bar; the damage bands' absolute literals vs the D-7 low-stat
  rework; the closed list silent on the D-1/D-3 expansion beats), 8 recs.
- **technical** (deepseek): **NEEDS REVISION — 11 blockers** (the 420 ms → 26-tick
  ceil error; E3b's undefined payload; no clock column; the abort path's
  double-fired exit; RELEASED → IDLE at E7 vs `arrive_end`; §G.8 covering only
  E3b; no `is_heal` guard; the no-publication law vs the knobs/metadata
  surfaces; the damage file count; the pool literals vs the knobs; the seam
  no-op without an AC), 10 recs.
- **QA** (deepseek): **NEEDS REVISION — 9 blockers** (10 TRs without an AC; the
  order-record/edge-assertion contradiction; the tear arithmetic; no gate
  manifest; 7 edge cases without fixtures; the playtest protocol absent; the
  undefined records + stub-bed hash; 3 OQs already decided by the body; the
  variation law without a TR/AC), 10 recs.

## 2026-11-14 — repairs (all valid blockers applied; zero rebuttals)

1. **The clock law** (§D.1): every flip-scoped envelope on the wall clock; every
   start tick on the publisher's clock (the clash midpoint = logic).
2. **The trace split**: the **edge trace** (one observation per edge per run) vs
   the **order trace** (one `ambient_shift` record per run) — §C.2 G7, TR-AUD-001,
   AC-AUD-01, §G.8.
3. **The tear arithmetic**: 420 → **400 ms = 24 ticks** ≤ the 26-tick window
   (TR-AUD-010, AC-AUD-07, F-AUD-07, K.1).
4. **CR-AUD-01** (new): E3b's `to_epoch` payload is undefined in the published
   contract — the order record gains `to_epoch`; the MVP config constant
   `MVP_FLIP_TO_EPOCH = 1`; the request recorded for the batch, not blocking.
5. **E1 preloads the whole bed table** (all three beds) — the arriving bed is
   selected at τ0 by E3b's payload, never guessed at R.
6. **The abort precedence** (§D.1): the force-release wins → `DEGRADED`; the
   derived E6 is an event, never a `RELEASED` entry; `DEGRADED` → `IDLE` on the
   tail clear.
7. **`RELEASED` exits at `arrive_end` (134)**, not E7; the arrival fade is a voice
   envelope that outlives E7.
8. **The recede 300 → 240 ms** (15 ticks) — a 3-tick floor hold at the default
   freeze, so §B's held breath exists on the default path (F-AUD-02, AC-AUD-02,
   K.1).
9. **The arrival's start gain** pinned at `AMB_RECEDE_FLOOR_DB`, linear in gain;
   the recede likewise (TR-AUD-030, F-AUD-02, V-AUD-06).
10. **§G.8's failure table** gains E1/E2/E5/E6/E7 rows, the `AUD_*` record table,
    and the **gate failsafe** (`GATE_FAILSAFE_MS` 700; the only failure SYS-04
    contains itself).
11. **The `is_heal == false` guard** on `EV_DAMAGE_TICK` (TR-HD-035/029).
12. **The no-publication law scoped** to gameplay/state events; the two read-only
    surfaces (the tuning read, the event-metadata read) named as ports + the
    AC-AUD-19 allowlist.
13. **The pool arithmetic derived** from the knobs; `VOICE_CAP` floor 18; the
    boot failure when `VOICE_CAP < allocated`; the steal order **P3 → P2 → drop**.
14. **The damage bands from the arc symbols** (`ATK1_DAMAGE`/`ATK2_DAMAGE`), not
    literals; the band pitch offsets {0, +3, +6} st (the audible separation);
    the SYS-07-REWORK dependency row.
15. **The three named silences** (§C.3): the Stinger lunge, the demon grant, the
    Warden drop — each a decision with its TR-JCE-027 revision route.
16. **The bed-contrast law** (TR-AUD-039) + the DEVICE fixture (AC-AUD-31): the
    blind A/B nameability bar, the phone-speaker audibility, the arena-hum
    distinctness.
17. **The variation law** (TR-AUD-038) + the seeded fixture (AC-AUD-30).
18. **Eight new ACs** (AC-AUD-25..32) closing the TR coverage gaps; the **gate
    manifest** printed (26 smoke · 4 device · 2 MVP-lock · 0 VS = 32).
19. **The playtest protocol** (the AC-SMB-22 shape: the free-play log, the
    elicitor, the pass/fail token sets, 3-of-5, κ ≥ 0.7, top-up) + the Gate 1
    probe.
20. **OQ-AUD-5/8 closed as decided-in-body**; AC-AUD-21 marked PROVISIONAL on
    OQ-AUD-6; the record IDs + the stub-bed hash defined.
21. **TR-AUD-024 repurposed** to the seam's exemption from the room-entry path
    (it duplicated TR-AUD-014).
22. **Small recs applied**: the tear's body a shade under the air change (§H.2);
    the ducked-score loop-tolerance note to the sound bible (§H.3); the Gate 2
    arena-state script line; the OQ-AUD-4 Gate 2 probe; the SFX-pool rationale;
    the Ogg-gapless + stereo→mono ADR probes; the NOT-JOIN record; the
    duck-application-site wording; F-AUD-04's onset formula; the canonical
    encoding for empty records; edge case #14 restated as "dropped".

**Landed counts after repair**: 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs
(22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; 26 smoke · 4 device · 2 MVP-lock ·
0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 roles · 29 audio
files · 1 contract-revision request (CR-AUD-01).

**Next**: the mandatory qa-lead spot-check on the repair diff.

## 2026-11-14 — qa-lead spot-check

- **Seat**: `qa-spot-check` (deepseek). **Verdict: PASS.**
- **Worklist**: 31 rows (the CD gate's 8, creative 3, technical 11, QA 9) — **all
  APPLIED-CORRECTLY**; zero NOT-FOUND, zero MISAPPLIED.
- **Counts re-derived**: 39 TR · 7 F · 7 V · 32 ACs (22/4/4/2; the manifest
  26/4/2/0 = 32) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role
  rows · 29 files · 1 CR. Every TR is referenced by at least one AC.
- **Advisories (5, non-blocking, all applied as one-line fixes)**: F-AUD-04's
  example tick; the §D.6 countersign tense; AC-AUD-23's Gate 1 cohort; the
  counts line's "17 role rows"; "cross-system calls" wording.

## 2026-11-14 — final micro-check

- **Seat**: a fresh `general`/deepseek pass, diff-scoped to the six advisory
  fixes (`9d3d018..working tree`). **Verdict: PASS** — six hunks, six lines, no
  collateral change; the F-AUD-04 example reproduces the formula (unity at 5000,
  0.5012 at 5008, release 5600–5614, nominal 5615); all counts reproduce; no new
  placeholder.

## 2026-11-14 — lane PAUSED (model rerun)

- Per the user's hard rule, the audio division reruns on **GLM-5.3-flash**; DS is
  reserved for technical work. No further authoring on DS; no PR opened.
- **State at pause**: the full GDD, the review log, and the report are committed
  on `docs/sys04-audio-core`. Remaining for the GLM runner: re-verify the
  creative seat on GLM, the sync request, and the PR + one CodeRabbit pass.

## 2026-11-14 — GLM creative rerun: CD gate (re-run on GLM)

- Both creative seats re-spawned with the neutral briefs and the explicit model
  `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`; the prompt hash
  `4e689924ac17` re-verified against the manifest row before the rerun.
- **Seat**: `cd-gate` (glm-5.3-flash). **Verdict: APPROVED — zero blockers.**
  Pillar service, anti-pillars, player fantasy, scope, contract alignment, and
  tone all pass; the two reconciliations a reviewer might mistake for drift (the
  arena's epoch-invariant asset; the wing's material-not-acoustic split) are read
  as the named rulings they are.
- **Recommendations (7, all non-blocking) — dispositions**:
  1. the SYS-10 status label is stale (the frozen GDD's own header reads
     APPROVED 2026-11-14, S1-002b) — **APPLIED** (the header + §K.3 row);
  2. the SYS-04 index row's Dependencies column still reads "None" — **DEFERRED
     to the sync request** (the index is the sync lane's file; the dependency
     list rides the row completion);
  3. mark the jump-2 tick's 3 variant files VS-ready — **REBUTTED**: the closed
     list is frozen TR-JCE-027 (APPROVED 2026-11-13) and is consumed verbatim;
     the counts (13 voices / 29 files / AC-AUD-15/18) derive from the contract,
     not from reachability, and Double Jump's MVP reachability is the
     progression owners' question — a change is the contract's revision route,
     not this document's;
  4. make the §D.6 countersign condition explicit — **ALREADY COVERED** (the
     header's "audio-director countersign pending" + the DS spot-check's tense
     fix encode it; the approval record will carry it);
  5. F-AUD-03's dual-target scope — **APPLIED**: the received strikes 6/12/20
     and tiers 30/60/120 verified against TR-HD-003/006; one scope sentence, no
     formula or AC change;
  6. AC-AUD-23's Gate 1 probe needs the QA-plan owner's script amendment —
     **FLAGGED** in the lane report (a handoff, not a document edit);
  7. the Gate 2 gear-beat channel is pre-narrowed to "visual" — **APPLIED**: the
     concept's probe is "noticed and equipped" with no channel pinned.

## 2026-11-14 — GLM creative rerun: creative seat (re-run on GLM — authoritative)

- **Seat**: `creative` (glm-5.3-flash). **Verdict: APPROVED — zero blockers.**
  The GLM verdict is the authoritative creative pass per the user's hard rule
  and **supersedes the DS-era creative NEEDS REVISION (3)** — the three DS
  blockers were repaired in the DS run's 31-row pass (the bed-contrast law, the
  arc-anchored bands, the three named silences) and are re-verified by this
  seat's full read.
- **Prose re-authoring**: the rerun brief's conditional ("re-author the creative
  prose where the GLM seat flags it — Overview, Player Fantasy, the audio
  direction/feel, the no-duck framing") is **empty** — the seat flagged no prose
  in any of those regions (its notes endorse the composition assumption, the
  fantasy's structural guarantee, and the three-silence routing). **No settled
  text was reopened**; the DS-era prose stands, now verified by the GLM seat.
- **Recommendations (7, all non-blocking) — dispositions**:
  1. regroup Ambience under the Music slider so "mute combat noise" cannot mute
     the truth-change — **DEFERRED to the user**: it reopens the
     in-body-resolved OQ-AUD-8 (AC-AUD-22 + §H.4 test the current mapping);
     recorded in the lane report's decision batch;
  2. pre-commit the unnoticed-gear/grant response to the TR-JCE-027 revision
     route — **APPLIED** (§C.3's intro);
  3. check the held ducked segment does not sit on the loop's most repetitive
     bar — **APPLIED** (§H.3's carried note);
  4. ask the AC-SMB-22 owner for a neutral mid-bracket probe so designed
     stillness is not miscoded as breakage — **FLAGGED** in the lane report
     (the playtest protocol is the DS run's repaired fixture; not reopened
     here);
  5. a Gate 2 ear check on the +3 st band floor (the fix is the floor, never
     more voices) — **APPLIED** (F-AUD-03's carried note);
  6. stage one deliberate silent UI interaction early in the Gate 2 session —
     **APPLIED** (the OQ-AUD-4 probe wording);
  7. the memory chime's repeat-exposure tolerance across a session — **APPLIED**
     (§E.2's carried note; the one-variant law stands).

## 2026-11-14 — repair batch (8 one-line edits; zero technical-fact deltas)

- Eight edits to `design/gdd/audio-core.md`, all one-line, non-gating, none
  reopening the design: the SYS-10 status label (×2), §C.3's routing pre-commit,
  §C.3 item 3's probe-channel wording, F-AUD-03's scope sentence + the +3 st
  ear-check note, §H.3's held-segment bar check, §E.2's repeat-exposure note,
  and the OQ-AUD-4 staged-probe wording.
- **No formula, count, TR-ID, AC test, contract consumption, or tick value
  changed.** The counts stand at 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs (22
  GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; 26 smoke · 4 device · 2 MVP-lock ·
  0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role rows ·
  29 audio files · 1 contract-revision request (CR-AUD-01).
- **The technical seat (DS) is not re-run**: no creative repair changed a
  technical fact (the F-AUD-03 addition clarifies the variable's existing
  universal domain `amount ≥ 1`; it moves no threshold and no AC). The
  mandatory qa-lead spot-check on DS covers the diff as the tripwire.
- **Next**: the qa-lead spot-check on the repair diff (DS, `4c6bb7c..head`).

## 2026-11-14 — qa-lead spot-check (DS, on the GLM rerun's repair diff)

- **Seat**: `qa-spot-check` (deepseek-v4.1-flash). **Verdict: PASS.**
- **Diff**: `4c6bb7c..93be05d` (the 8 one-line edits + the log append).
- **Worklist**: 11 rows — **all APPLIED-CORRECTLY**; zero NOT-FOUND, zero
  MISAPPLIED. Verified against the frozen contracts: the SYS-10 status matches
  the frozen GDD's own header; 6/12/20 + 30/60/120 resolve to TR-HD-003/006;
  the gear-beat wording matches `game-concept.md`'s Gate 2 probe text; the
  counts re-derive (39 TR · 7 F · 7 V · 32 ACs · 14 knobs · 8 OQs · 13 voices ·
  17 role rows · 29 files · 1 CR); and the zero-technical-delta ground for not
  re-running the technical seat holds against the diff itself.
- **Advisories (5, non-blocking)**: the TR-HD citation split (**APPLIED** —
  `f8df947`); §C.3's mild redundancy (left — item 1's route statement predates
  the intro pre-commit); the F-AUD-03 scope line rides the PR body (done);
  CD-2's index Dependencies stays deferred to the sync lane (tracked in the
  report's sync request); §H.3's bar check gets a line in the palette brief
  when the sound bible is authored.

## 2026-11-14 — final micro-check (DS, on the advisory delta)

- **Seat**: a fresh deepseek pass, diff-scoped to `93be05d..f8df947` (one hunk:
  the TR-HD citation split). **Verdict: PASS — zero blockers.** The formula
  line, the thresholds, the examples, and AC-AUD-08 are byte-identical; both
  citations resolve in `health-damage.md`.
- **The GLM rerun's gate trail is complete.** The document stops here. The sync
  request, the PR, and the one CodeRabbit pass follow in the lane loop; the
  merge waits for the sync to land (the orchestrator + the sync lane).

## 2026-11-14 — PR #46 + the one CodeRabbit pass (triage + dispositions)

- **PR**: `#46` opened `--base Main` (the gate trail + the sync status in the
  body). The lane's **one CodeRabbit pass** ran (profile ASSERTIVE): **12
  actionable comments** (6 Major, 6 Minor) + a summarized review.
- **Dispositions** (every finding triaged; one fix commit; the threads resolved
  with these records):
  1. **Major — the epoch/bed source for room entry + the post-flip load** —
     **APPLIED (CR-AUD-02)**. Verified: SYS-02's room-activation surface
     (TR-RWS-010) carries no epoch/bed field, and a post-flip load replays no
     flip edges, so the derived state cannot cover it. Fix: §F.1's epoch-source
     rule (in-session = the derived consumed-event state; a load = the
     load-complete payload's `restored_epoch`, consumed as event data at the
     adapter — the CR-AUD-01 pattern); TR-AUD-002's publisher map gains
     SYS-03's load-complete; TR-AUD-022's test gains the load-complete fixture;
     §G.8 gains the failure row + `AUD_LOAD_MISSING`; §K.3 gains the SYS-03
     (upstream, soft) row; **CR-AUD-02** records the request to SYS-03's
     authoring (SYS-03 is Not Started — a design-order request, not a frozen
     edit). Counts: the CR line 1 → 2.
  2. **Major — the clash pair named a signature with 3 variants** —
     **APPLIED**. §E.2's law: the signatures are the six one-variant voices
     (heal, death, revive, level-up, memory, tear); the clash pair keeps its
     three variants and shares the zero-drift law as a named pair clause.
     TR-AUD-038 + AC-AUD-30 recount: "the eight signatures" → "the six
     signatures and the clash pair". Variant/file counts untouched.
  3. **Major — the E6-lost failsafe leaves the bed at the floor with the state
     stuck in HELD** — **APPLIED**. The HELD row gains the failsafe exit
     (`HELD` → `IDLE`, no `RELEASED` entry); §G.8's E6 row gains the recovery
     (the bed holds at the floor, zero new orders, the next room entry
     re-applies the room's bed at nominal); AC-AUD-13's E6 clause extends with
     the same assertions; K.2 gains edge case #15. No new AC, no count change.
  4. **Major — the formula template ("variable tables", a "prescribed
     opening")** — **REBUTTED**. The cited guideline ("always begin each
     formula with this exact structure") does not exist in the repo's framework
     docs (`docs/framework/coding-standards.md`, `docs/framework/templates/*`);
     the governing quality bar (the lane prompt's, mirroring the landed
     SYS-02/07/09/10/11 GDDs) is "variables with types + ranges, an Output
     clause, worked examples" — all seven F-AUD formulas comply inline, and the
     landed corpus is the template's precedent. No reformat.
  5. **Major — `VOICE_CAP` range [18, 24] vs the 20 hard cap** — **APPLIED**.
     K.1's range → [18, 20]; §G.3 gains the upper bound ("a config outside the
     span is a config-load rejection").
  6. **Major — AC-AUD-30's no-adjacent-repeat on single-variant voices** —
     **APPLIED**. The condition qualifies to the multi-variant voices in both
     AC-AUD-30 and TR-AUD-038's test.
  7. **Minor — §H.1's "the score under both" vs Music −6 > Ambience −9** —
     **APPLIED**. §H.1's ordering sentence corrected to match §G.1 (the score
     sits between them: under the one-shots, a shade over the beds).
  8. **Minor — the ±1 st variation vs the "≥ 3 st apart" claim** — **APPLIED**.
     F-AUD-03's Output clause qualifies the floor as nominal (the worst case
     with the within-band draw is 1 st; the printed amount carries the band's
     meaning).
  9. **Minor — AC-AUD-20's "within the bar" limiter threshold** — **APPLIED**.
     A numeric bar pinned in AC-AUD-20 and TR-AUD-035's test: the limiter's
     gain-reduction high-water ≤ 3 dB on the loudest fixture (provisional; the
     sound-bible pass may re-pin).
  10. **Minor — edge case #14's dropped room-entry bed + the arena at E6** —
      **APPLIED**. K.2 #14 states the drop policy (the mismatch persists to the
      next room entry), the E6 arrival serves the room the player occupies at
      the release boundary, and the arena gets no arrival; §D.3's gate bullet
      and §C.1's E6 obligation carry the same clause.
  11. **Major — F-AUD-06's absolute timestamps break the fresh/resume hash
      equality** — **APPLIED**. Both timestamps encode relative to the run's
      raise tick (`R` / `R′`); `recede_ms` is already relative.
  12. **Minor — the SYS-02/SYS-04 dependency direction (the report's line
      140)** — **APPLIED**. Verified: SYS-02's "explicit non-dependency" for
      SYS-04 (`room-world-structure.md:370`) is **direction-correct** — SYS-02
      consumes nothing from SYS-04 and authors no audio edges; SYS-04 is a
      downstream consumer of the room fixture + the room activation. The
      report's §1.1 row gains the direction note, and the sync request's
      systems-index updates gain the reciprocal downstream-consumer entry on
      SYS-02's side (SYS-02's own line-371 rule routes it to the index at
      completion — the frozen GDD itself is not edited).
- **Counts after the batch**: 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs (22 GUT ·
  4 LINT · 4 DEVICE · 2 PLAYTEST; 26 smoke · 4 device · 2 MVP-lock · 0 VS) ·
  14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role rows · 29 audio
  files · **2 contract-revision requests (CR-AUD-01, CR-AUD-02)**.
- **Confirm pass**: the batch is Major-class (findings 1/3/11), so the lane
  loop's confirm CodeRabbit pass runs after the fix commit.
- **Next**: the thread resolutions + the confirm pass.
