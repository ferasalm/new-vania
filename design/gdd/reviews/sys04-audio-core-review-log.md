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
