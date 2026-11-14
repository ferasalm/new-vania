# Lane SYS-04 — report

- **Status**: `PR` — the GLM creative rerun is clean (both seats APPROVED, spot-check PASS, micro-check PASS); the PR opens now; CodeRabbit next
- **Branch / worktree / PR**: `docs/sys04-audio-core` / `../new-vania-sys04-audio-core` / (PR opened after this commit — see the GLM rerun note below)
- **Prompt**: v1.0.0 / `4e689924ac17` (matches manifest: **yes** — re-verified at the rerun's start)
- **Gate trail — DS phase (superseded creative verdicts; technical/QA repairs intact)**: CD APPROVED (0) · creative NEEDS REVISION (3 — superseded by the GLM rerun) · technical NEEDS REVISION (11 → all repaired) · QA NEEDS REVISION (9 → all repaired) · spot-check PASS (31/31) · micro-check PASS
- **Gate trail — GLM rerun (authoritative creative pass)**: CD **APPROVED** (0 blockers, 7 recs, dispositions logged) · creative **APPROVED** (0 blockers, 7 recs, dispositions logged) · technical **stands** (DS; zero technical-fact deltas — verified by the spot-check against the diff) · QA **stands** (DS; the DS-era repairs untouched) · spot-check **PASS** (DS; 11/11 rows on `4c6bb7c..93be05d`) · micro-check **PASS** (DS; 0 blockers on the advisory delta `93be05d..f8df947`)
- **Blockers (hard)**: none. `CR-AUD-01` (E3b's `to_epoch` payload — a contract-revision request against the now-APPROVED/frozen SYS-10 GDD; recorded for the batch, not blocking) + OQ-AUD-4/6/7 open (the body assumes the recommendations).
- **User decisions carried from the rerun (non-gating)**: (1) the Ambience/Music slider regrouping (the GLM creative seat's rec 1 — reopens the in-body-resolved OQ-AUD-8 and AC-AUD-22, so it is deferred, not applied); (2) the AC-AUD-23 mid-bracket probe + the Gate 1 probe amendment → the QA-plan owner; (3) OQ-AUD-4/6/7 stand open as recorded in §K.4.
- **Sync request**: prepared — see "Sync request" below; not sent (the orchestrator queues it).
- **CodeRabbit**: one pass runs on the PR; dispositions recorded after.
- **Landing receipt**: not merged (the merge waits for the sync to land).
- **Next action**: the orchestrator queues the sync request below; the lane runs the one CodeRabbit pass + triage on the PR; merge after the sync lands and the checks are green.

> **GLM rerun note (2026-11-14)**: per the user's hard rule, the audio division's creative divisions re-ran on **GLM-5.3-flash** (`cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`) in this worktree; DS is reserved for technical work. The DS checkpoint (`4c6bb7c`) was the rerun's input. The rerun re-ran the **CD gate** and the **creative seat** on GLM with the neutral briefs — both returned **APPROVED, zero blockers**. The GLM creative verdict **supersedes** the DS-era creative NEEDS REVISION (3) as the authoritative creative pass (the three DS blockers were repaired in the DS run's 31-row pass and are re-verified by the GLM seat's full read). The rerun brief's conditional prose re-authoring (Overview / Player Fantasy / audio direction / no-duck framing) was **empty** — the GLM seat flagged no prose there — so no settled text was reopened. The **technical** and **QA** seat verdicts remain DS's (correct per the hard rule); no creative repair changed a technical fact, so no DS technical re-run was needed — the spot-check verified that ground against the diff itself. The **qa-lead spot-check** re-ran on DS on the repair diff: PASS. Repair commits: `93be05d` (the 8-line batch), `f8df947` (the citation-split advisory).

---

## GLM rerun — repair summary

**Applied (8 one-line edits in `93be05d` + 1 in `f8df947`)**: the SYS-10 status label ×2 (the frozen GDD is APPROVED 2026-11-14, S1-002b); §C.3's unnoticed-beat routing pre-commit; §C.3 item 3's gear-beat channel un-pinned (the concept's probe is "noticed and equipped", no channel); F-AUD-03's dual-target scope sentence (strikes 6/12/20 TR-HD-003 · tiers 30/60/120 TR-HD-006) + the +3 st Gate 2 ear-check note; §H.3's held-segment bar check; §E.2's memory-chime repeat-exposure note; the OQ-AUD-4 staged-probe wording; the TR-HD citation split.

**Rebutted (logged, never silently skipped)**: the jump-2 VS-ready mark (CD rec 3) — the closed list is frozen TR-JCE-027 and the counts derive from it; reachability is the progression owners' question.

**Deferred to the user / other owners**: the Ambience↔Music slider regrouping (user; reopens OQ-AUD-8); the AC-AUD-23 mid-bracket probe + the Gate 1 script amendment (QA-plan owner); the SYS-04 index Dependencies column (the sync lane — see below).

**Counts (unchanged by the rerun)**: 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs (22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; 26 smoke · 4 device · 2 MVP-lock · 0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role rows · 29 audio files · 1 contract-revision request (CR-AUD-01).

---

## Sync request (prepared; the orchestrator queues it; the sync lane applies)

**To `design/registry/entities.yaml`** — three new SYS-04-owned entries + one SYS-29-sourced entry whose ratification completes with this landing + one `referenced_by` append:

```yaml
  - name: audio_bus_contract
    status: active
    source: design/gdd/audio-core.md
    referenced_by:
      - design/gdd/audio-core.md
    kind: published_contract
    published_by: SYS-04 Audio Core
    consumed_by: SYS-24 HUD (the settings surface renders the knobs: MONO + three
      sliders, the Ambience and UI buses riding the SFX slider's group)
    values: "Master 0 dB (limiter only) · Music −6 dB · Ambience −9 dB · SFX −3 dB ·
      UI −6 dB (reserved, zero voices at MVP) · one mix snapshot SNAP_GAMEPLAY ·
      SFX pool 12 + 1 reserved flip slot · AMB pool 4 · VOICE_CAP 20 hard cap
      (allocated 18) · steal P3 → P2 → drop, never P0, never a signature"
    notes: "The duck's only target is Music; zero snapshot changes across [E1, E7]
      (V-AUD-05); the core is a leaf consumer — no gameplay/state event publishes."
    added: 2026-11-14
    revised: ""

  - name: ambient_bed_contract
    status: active
    source: design/gdd/audio-core.md
    referenced_by:
      - design/gdd/audio-core.md
      - design/gdd/dual-reality-state.md
      - design/gdd/world-mutation-epochs.md
      - design/gdd/seam-borders.md
    kind: published_contract
    published_by: SYS-04 Audio Core
    consumed_by: SYS-09 (AC-DR-27's zero-arena-bed-orders assertion audits these bed
      IDs) · SYS-10 (E3b's receding-first target set is carried in the order record)
      · SYS-11 (the seam's acoustic no-op — the wing resolves to RM-03's bed)
    values: "Three beds: AMB_A_HOUSE / AMB_B_HOUSE / AMB_ARENA_STEEL_HUM ·
      RM-01..RM-05 map A→B, RM-06 is epoch-invariant (the steel hum, never ordered)
      · the wing has no bed of its own (RM-03's) · AMB_RECEDE_MS 240 ·
      AMB_ARRIVE_MS 240 · AMB_RECEDE_FLOOR_DB −60 · receding-first: the recede
      begins at τ0 (a per-voice ramp, never a duck), the arriving bed's first
      audible sample ≥ the release boundary · the abort leaves the bed put"
    notes: "The score (MUS_HOUSE_LOOP) is global and untouched by the flip. Zero
      stochastic ambience one-shots at MVP (the closed-list audit)."
    added: 2026-11-14
    revised: ""

  - name: audio_edge_list
    status: active
    source: design/gdd/audio-core.md
    referenced_by:
      - design/gdd/audio-core.md
      - design/gdd/juice-feedback.md
      - design/gdd/seam-borders.md
    kind: published_contract
    published_by: SYS-04 Audio Core (the voice realization of SYS-29's closed list)
    consumed_by: SYS-29 (AC-JCE-31/32's audits must find exactly these emissions)
    values: "Ten SYS-29 edges → eleven one-shot voices (the clash pair carries two)
      + two flip tear voices (EV_FLIP_TEAR success / EV_FLIP_TEAR_ABORT) = 13
      one-shot voices · 29 audio files (25 one-shots + 3 beds + 1 score) · zero UI
      voices · zero stochastic ambience one-shots · no per-press popups, no
      ORDER RECEIVED voice · variation: round-robin no-immediate-repeat, ±1 st
      within a band, zero drift on the eight signatures"
    notes: "TR-JCE-027 remains the upstream closed list (frozen 2026-11-13); adding
      an edge or a voice is a TR-JCE-027 revision. The three named silences (the
      Stinger lunge, the demon grant, the Warden drop) are decisions with that
      revision route, not omissions."
    added: 2026-11-14
    revised: ""

  - name: duck_request_contract
    status: active
    source: design/gdd/juice-feedback.md
    referenced_by:
      - design/gdd/juice-feedback.md
      - design/gdd/audio-core.md
      - design/gdd/seam-borders.md
    kind: published_contract
    published_by: SYS-29 Juice & Feedback (the schema; TR-JCE-027)
    consumed_by: SYS-04 (the single application site in src/audio/; the ratified
      value) · SYS-15 (the offline screen's lifetime backs the release)
    values: "duck_request {bus, dB, hold} — exactly three fields: bus ∈ {MUSIC},
      dB ∈ [−12, 0], hold ∈ {UNTIL_OFFLINE_EXIT} · DEATH_DUCK_DB −6 (RATIFIED —
      OQ-J7) · attack 120 ms · release 240 ms · released on both exits
      (reconstruct and revive) · exactly one request per death, one family in
      the game"
    notes: "The no-duck law: no hit-stop/flip/seam/reveal-hold/pause duck
      (AR-SMB-03, SYS-09's sweep-not-beat ruling); V-AUD-01's static audit finds
      exactly one application site."
    added: 2026-11-14
    revised: "2026-11-14 (SYS-04's mix ratifies −6 dB — OQ-J7 resolved; no longer
      provisional)"
```

**Append to `flip_trigger_contract`'s `referenced_by`** (the entry exists; do not duplicate):
```yaml
      - design/gdd/audio-core.md
```
with the revised comment: `2026-11-14 (SYS-04 composes against it verbatim — the audio obligations at E1–E7; audio-core.md joins referenced_by)`.

**To `design/gdd/systems-index.md`**:

1. The SYS-04 row (line 156) is replaced by the landed row:
```markdown
| SYS-04 | Audio Core | MVP | **APPROVED (2026-11-14 — the GLM creative rerun's trail): CD APPROVED (GLM, 0) · creative APPROVED (GLM, 0 — the authoritative creative pass, superseding the DS-era NEEDS REVISION (3)) · technical+QA NEEDS REVISION (DS: 11 + 9 → all 31 blockers repaired) · qa-lead spot-check PASS (31/31; re-PASS on the GLM rerun's repair diff) · final micro-check PASS ×2; 39 TR-AUD / 7 F-AUD / 7 V-AUD / 32 ACs (gate 26 smoke + 4 device + 2 MVP-lock + 0 VS) / 14 knobs / 8 OQs (5 resolved); the E1–E7 Flip-Trigger Contract consumed verbatim (TR-DR-004 — the audio obligation column, no edge added/removed/re-timed); the receding-first `ambient_shift` (AR-AUD-01: the target set RM-01..RM-05 exactly, zero arena-bed orders, the recede at τ0, the arrival ≥ the release boundary, the abort leaves the bed put); the freeze brackets (AR-AUD-02: drop-never-queue, no loop restart, no snapshot change, the freeze is not a duck); the arena's epoch-invariant steel hum (TR-AUD-013); the wing's acoustic no-op (the material/acoustic split — a named ruling, audio-director countersign at approval); the no-duck law (exactly one duck family: the death beat −6 dB, OQ-J7 ratified); the closed list (13 voices / 29 files, TR-AUD-038's variation law); CR-AUD-01 recorded (E3b's `to_epoch` payload — the contract-revision request, not blocking); review record `design/gdd/reviews/sys04-audio-core-review-log.md`; **Dependencies (correcting the stale "None"): SYS-09, SYS-10, SYS-29, SYS-11, SYS-07, SYS-08, SYS-02 upstream; SYS-15, SYS-20, SYS-24 downstream; ADR-DRAFT + the sound bible support** | design/gdd/audio-core.md |
```
2. The design-order row #16 is marked: `16. SYS-04 Audio Core *(APPROVED)*`.
3. The dependency-map bullet for SYS-04 (added after the SYS-11 bullet, line 65's neighbourhood):
```markdown
- SYS-04 Audio Core → depends on SYS-09, SYS-10, SYS-29, SYS-11, SYS-07, SYS-08, SYS-02 (the Flip-Trigger Contract's composition surface; E3b's receding-first emission; the closed edge list + the death duck; the seam's zero-audio rulings; the damage/heal/death/defeat payloads; the clash pair's publication; the six-room bed map); feeds SYS-15 (the duck's release backstop), SYS-20 (the memory-pickup trigger), SYS-24 (the settings knobs + the group map). **GDD `design/gdd/audio-core.md` — APPROVED (2026-11-14):** 39 TR-AUD / 7 F-AUD / 7 V-AUD / 32 ACs (26 smoke · 4 device · 2 MVP-lock) / 14 knobs / 8 OQs; E1–E7 consumed verbatim; the receding-first turnover; the freeze brackets; the arena steel hum; the no-duck law; the closed list; CR-AUD-01 recorded; review record `design/gdd/reviews/sys04-audio-core-review-log.md`.
```

---


## 0 · Verification

| Check | Result |
|---|---|
| Lane prompt header hash vs manifest SYS-04 | `4e689924ac17` == `4e689924ac17` — **match** |
| Worktree exists, clean | yes; `git status --short` empty before writes |
| `git log --oneline -1` | `e8b194d docs(sys11): the Seam Borders GDD lands (SYS-11) (#43)` — the manifest base |
| STATE.md marks the lane BLOCKED | no (AUTHORING) |
| Shared-file lock | free; no shared file read-locked or written |

Files created (uncommitted at authoring time; checkpoint commit follows):

- `design/gdd/audio-core.md` — the GDD skeleton + sections A (Overview) and B (Player Fantasy), status `Draft — skeleton`.
- `design/gdd/reviews/sys04-audio-core-review-log.md` — the running review log (authoring entries).
- `production/session-state/lane-SYS-04-report.md` — this report.

---

## 1 · Context + feasibility brief

### 1.1 Consumed-contract summary

| Contract | What it publishes | What SYS-04 consumes | State |
|---|---|---|---|
| **SYS-09** `dual-reality-state.md` TR-DR-004 | The Flip-Trigger Contract: E1–E7 + G1–G7, the canonical tick table, the tear hook at τ0, the freeze brackets, `ambient_shift` pinned to `epoch_swap`'s tick | The **composition surface**, consumed verbatim. The audio obligation at each edge (§1.2). No edge added, removed, or re-timed | APPROVED gated on S1-007 |
| SYS-09 TR-DR-011 | The arena's pristine lie; **the audio expectation: the arena's ambient bed remains the steel hum post-flip** | The arena bed is epoch-invariant; RM-06 is never in an `ambient_shift` order | same |
| SYS-09 TR-DR-012 | The liminal wing: epoch-invariant `PROV_LIM_*`, the wing receives the tear like the rest of the world | The wing gets **no audio treatment** — RM-03's bed continues; no crossfade/filter/layer/sting | same |
| SYS-09 AC-DR-27 | The zero-arena-bed-orders assertion; `ambient_shift`'s target set = the non-arena rooms exactly | The exact assertion SYS-04 must satisfy and telemetrize | same |
| SYS-09 Visual/Audio note | "No duck request exists for the flip (a 300 ms duck is a sweep, not a beat)" | The flip-duck ban, verbatim rationale | same |
| **SYS-10** `world-mutation-epochs.md` | E3b `ambient_shift` is **SYS-10's emission**, pinned to `epoch_swap`'s tick, receding-first; **the abort case named**: `freeze_open` fires, E3/E3b/E4 never do, the bed stays put; the latched-resume rider (i) | The publisher identity; the abort path's zero-order law; the re-run's identical trace | In Design 2026-11-14 |
| SYS-10 AC-WME-07 | `ambient_shift` fires exactly at τ0; zero arena-bed orders; **no E3b on the abort path** | The SYS-10-side twin of AC-DR-27 | same |
| **SYS-29** `juice-feedback.md` TR-JCE-027 | The **closed audio edge list** (ten edges) + the **single duck request** `{bus, dB, hold}`, `DEATH_DUCK_DB` −6 provisional (OQ-J7), held to the offline exit; "the hit-stop never ducks" | The vocabulary, the one duck family, the audit (`AC-JCE-31/32`) | APPROVED 2026-11-13 |
| SYS-29 TR-JCE-018 / 021 | The death sting publishes **no audio edge**; the memory chime is **audio-led**; the Leap-Stone grant reuses the chime; the jump-2 edge | The death power-down is the death's only audio; the chime is a signature voice | same |
| **SYS-11** `seam-borders.md` AR-SMB-01..04 | **Zero audio publications**; **the bed continues** (no crossfade/filter/layer/restart/sting); **the no-duck ruling**; **M4's chime is not the seam's** | The seam is a no-op on the audio graph; M4's chime is TR-JCE-021's edge by consequence | APPROVED 2026-11-14 |
| **SYS-07** `health-damage.md` | `DamageNumber`, `HealEdge`, `DeathEdge`+`DeathRecord`, `DefeatEvent` | The damage/heal/death/defeat edge payloads (the amount, the heal, the death latch, the defeat) | APPROVED 2026-11-12 |
| **SYS-08** `combat.md` TR-CMB-021/022/023 | The clash pair (contact + midpoint at +21 logic ticks); hit-stop 70/90/40 ms; the freeze is a clock, not a gate | The clash pair's co-timing (consume SYS-29's publication, never derive); the no-hit-stop-duck law | APPROVED 2026-11-12 |
| **SYS-02** `room-world-structure.md` | The six-room fixture RM-01..RM-06; RM-06 = the pinned arena | The bed table's room set: the target set is RM-01..RM-05 (5 rooms), the excluded set is RM-06 | APPROVED 2026-11-13 |
| **ADR-0001** §3, §5 | The freeze as a `request_freeze` source; the tick-boundary pipeline | The bracket's clock semantics; the ms→tick ceil law | Accepted 2026-11-12 |

**Contract revisions requested: none.** Every input is consumed as published. Two conditional cases are named in §1.11: OQ-AUD-4 (UI voices) would need a TR-JCE-027 revision if the user wants menu sound; OQ-AUD-2 (no score at MVP) would leave the death duck with nothing to duck and would need a TR-JCE-027 revision on the duck's target.

### 1.2 The E1–E7 consumption table (defaults: N = 18, R = 100 → τ0 = 101, E6 boundary 118→119, E7 = 119)

| # | Edge | Fired at | Publisher | **Audio obligation (SYS-04)** | Audible result |
|---|---|---|---|---|---|
| E1 | `flip_begin` | R = 100 | SYS-09 | **Arm silently**: validate + preload the arriving bed, the tear layer, and the bed table; build the order record. **No pre-telegraph cue** — the contract's "the world still normal" is an audio law too. | none |
| E2 | `freeze_open` | τ0 = 101 boundary | SYS-29 (`active_sources` gains `truth_flip`) | **Open the stillness bracket**: close the gameplay one-shot gate (**drop, never queue**); no loop restart; no mix-snapshot change; **no duck**. Already-sounding voices ring out, never truncated. | the bracket opens |
| E3 | `epoch_swap` | 101 | SYS-10 | **No direct obligation.** The audio core never reads `truth_epoch`; it consumes E3b and nothing else (epoch-blindness). | none |
| E3b | `ambient_shift` | 101 (pinned to E3's tick) | SYS-10 | **The receding-first order** (§1.3): target set = RM-01..RM-05 exactly; excluded = RM-06; begin the sounding bed's recede at τ0; the arriving bed's first audible sample **≥ the release boundary**; **zero arena-bed orders**. | the old air draws in |
| E4 | `rematerial_done` | R+1 frame = 101 | SYS-09 | **Sync point only.** No sound is keyed to E4; the tear is already sounding. No second tear hit. | none |
| E5 | `glitch_window` | [101, 127) = τ0 + N + 8 ticks | SYS-29 | **The tear layer**: the beat-aligned transient at τ0 + the body through the window + the 120 ms decay tail. The flip's **only** one-shot; the reserved voice. **Abort path**: the degenerate form (no transient, no success beats), the tail runs. | the tear |
| E6 | `freeze_close` | 118→119 boundary | SYS-29 | **The release boundary**: the gate lifts; the arriving bed **may** begin (never before); the arrival fades in. | the new air arrives |
| E7 | `flip_complete` | 119 | SYS-09 | **Resume**: the arrival completes; gameplay one-shots resume; **no fanfare, no completion sting**. | the world is other |

**The guarantees as consumed:** G2 (single-shot per landed flip) → the tear latches once per run; the latched-resume re-run replays the same order trace from R′. G3 (deferred upstream of E1) → the audio sees no partial sequence; the arm happens once, at R. G5 (pin/reveal) → the arena bed and the wing's bed are untouched. G6 (photosensitivity) → the audio carries no flash, no strobe; `REDUCED_FLASH` changes no audio edge and no timing. G7 (totality/order/fire-once) → the audio's order trace asserts exactly one order per edge per run.

### 1.3 The receding-first `ambient_shift` law (proposed AR-AUD-01)

The law, in seven clauses:

1. **Pinned.** The order's tick equals E3's tick (τ0 = 101 at the fixture). A one-tick drift is a failure, not a tolerance.
2. **Target set = the non-arena rooms exactly.** `target_rooms = {RM-01, RM-02, RM-03, RM-04, RM-05}`; `excluded = {RM-06}`. The set is carried in the order record, so the assertion holds even when only one bed is sounding.
3. **Zero arena-bed orders across [E1, E7].** `AMB_ARENA_STEEL_HUM` appears in no order, ever. (AC-DR-27 / AC-WME-07 consumed.)
4. **Recede at τ0, never before.** The first audio-graph motion is the sounding bed's gain ramp, starting at τ0 (not at R). The recede is a **per-voice gain ramp**, never a `duck_request` — a duck here would break the one-duck audit.
5. **Recede completes at the release boundary.** `AMB_RECEDE_MS` = 300 (= the default bracket); on an admitted extension the ramp still completes at 300 ms and the bed **holds at the floor** until E6 — the extended freeze lengthens the held breath, never the recede. (The breath is the inhale; the extension is the pause at the top of it.)
6. **Arrival no earlier than the release boundary.** The arriving bed's first audible sample is at tick ≥ R+N+1 (119 at the fixture); no pre-roll, no crossfade tail before it. Fade-in `AMB_ARRIVE_MS` = 240 (15 ticks, 250.0 ms effective).
7. **The abort case: the bed stays put.** E3b absent → zero orders, zero recede, zero arrival; the bracket opens at E2 and closes at the force-release-derived `freeze_close`; the tear's degenerate layer runs; the world stays truth A and the ear agrees.

*Fixture (AC-DR-04's timeline):* arm at 100 · bracket + recede + tear at 101 · recede ends at the 118→119 boundary · arrival 119→134 · full B bed at 134 · no arena order anywhere in [100, 134].

### 1.4 The freeze brackets (proposed AR-AUD-02)

- **Bracket** = `[E2, E6)` = 18 ticks = 300.0 ms at defaults; moved only by an admitted extension.
- **The gate**: gameplay one-shots **drop, never queue** (a queue replays stale sounds at release = a burst; a drop is honest). Counter + telemetry.
- **The one licensed exception**: the flip's own tear at τ0. The bracket forbids *foreign* one-shots, not the event itself. This is stated explicitly because E5's τ0 sits inside the bracket — the reconciliation is named, not implied.
- **Loops**: no restart, no loop-point jump. The only loop-graph motion is the sounding bed's recede.
- **No snapshot change that reads as a beat**: **zero mix-snapshot changes across [E1, E7]**; the score is untouched (no stinger, no score duck, no transition).
- **The freeze is not a duck**: zero duck requests in the window; the recede is a voice gain, not bus surgery.
- **Already-sounding voices ring out** — never truncated (a cut is a click and reads as a bug).
- **Abort**: the same rules; the bracket closes at the force-release-derived `freeze_close`; zero bed orders.

### 1.5 The arena steel hum (proposed AR-AUD-03)

- RM-06's bed is `AMB_ARENA_STEEL_HUM`: **one asset, epoch-invariant**, the same file at epoch 0 and 1. TR-DR-011's expectation is consumed as an asset law, not a per-epoch pick.
- It is a **distinct asset** from the A house bed (OQ-AUD-5) — that is what makes "zero arena-bed orders" trivially assertable: the arena's bed ID simply never appears in any order.
- If the player stands in the arena during the flip (the long-deferral chain), the steel hum continues untouched; the tear layer is global and plays (the world tears around the untouched room — the seam is the point). Zero bed orders either way.
- The arena's steel hum is **not** the score; the score continues everywhere, including the arena.

### 1.6 The no-duck ruling (proposed AR-AUD-04)

- **Exactly one duck request family exists in the game**: `duck_request {bus: MUSIC, dB: DEATH_DUCK_DB, hold: UNTIL_OFFLINE_EXIT}`, `DEATH_DUCK_DB = −6` (provisional, OQ-J7; range [−12, 0]), published **once per death**, released on the offline exit (reconstruct **or** revive).
- **Forbidden and audited**: hit-stop duck (70–90 ms = a click artifact), flip duck (300 ms = a sweep, not a beat — SYS-09's ruling), seam duck (AR-SMB-03), reveal-hold duck (SYS-32's lease), pause duck (the map/pause screen changes no bus gain), freeze duck, low-HP duck.
- The **static audit** finds exactly one call site of the duck symbol; the runtime counter equals 1 per death.
- Every other gain move in the game is a **per-voice ramp** (the beds' recede/arrival), which is not bus surgery and is not a duck.

### 1.7 The closed edge list (proposed AR-AUD-05)

**Ten SYS-29 edges → eleven one-shot voices** (the clash pair carries contact + midpoint), plus **two flip tear voices** (success / abort) = **13 one-shot voices**. Zero UI voices; zero stochastic ambience one-shots; zero per-press popups.

| Edge (source) | Trigger | Bus | Class | Max conc. | Retrigger floor | Variants | Duration class |
|---|---|---|---|---|---|---|---|
| damage tick (SYS-07 `DamageNumber`) | the damage edge; **pitched by amount band, never a per-hit voice** | SFX | P2 | 2 | 1 tick | 4 × 3 bands, ±1 st | 90 ms |
| clash — contact (SYS-29/SYS-08) | the clash tick | SFX | P2 | 1 | 21 ticks | 3 | 120 ms |
| clash — midpoint (SYS-29/SYS-08) | +21 **logic** ticks (the spark's midpoint) | SFX | P2 | 1 | 21 ticks | 3 | 120 ms |
| deflect tick (SYS-08) | the deflect resolution | SFX | P2 | 2 | 3 ticks | 2 | 100 ms |
| heal chime (SYS-07 `HealEdge`) | the heal edge | SFX | P3 | 1 | 6 ticks | 1 (signature) | 350 ms |
| death power-down (SYS-07 `DeathEdge`) | the player's death latch | SFX | P1 | 1 | latch | 1 (signature) | 700 ms |
| revive boot (SYS-07 revive) | the restore-module draw | SFX | P1 | 1 | 30 ticks | 1 | 500 ms |
| level-up print (SYS-07/SYS-29) | the level-up print edge | SFX | P3 | 1 | 30 ticks | 1 | 400 ms |
| memory chime (SYS-29 TR-JCE-021) | the pickup/grant edge, once per pickup | SFX | P1 | 1 | latch per pickup | 1 (signature) | 1200 ms |
| jump-2 tick (SYS-29) | the double-jump takeoff | SFX | P3 | 2 | 2 ticks | 3, ±1 st | 120 ms |
| defeat tick (SYS-29) | an enemy defeat | SFX | P2 | 2 | 2 ticks | 3, ±1 st | 200 ms |
| **flip tear — success** (E5) | τ0, the flip's own voice | SFX (reserved voice) | P0 | 1 | latch per run | 1 (signature) | 420 ms (inside the 433 ms window) |
| **flip tear — abort** (E5 degenerate) | τ0 on the abort path; no transient, no beats | SFX (reserved voice) | P0 | 1 | latch per run | 1 | the tail |

**Amount bands** (F-AUD-03): `band = 1 + (amount ≥ 10) + (amount ≥ 20)` — the arc table's 8/10/20 falls into B1/B2/B3; the counters 15/30 into B2/B3. Three bands, derived from existing damage values, not invented.

**Asset arithmetic**: 26 one-shot files (4+6+2+1+1+1+1+1+3+3+2 = 26 across the 13 voices) + 3 beds + 1 score = **30 audio files** at MVP.

### 1.8 The audio architecture plan

| Element | Plan | Rationale |
|---|---|---|
| **Buses** | Master → **Music · Ambience · SFX · UI** (4 children; UI is zero-voice at MVP, reserved) | The minimum that keeps the duck target isolated and the mix controllable on mobile |
| **Nominal volumes** | Music −6 dB · Ambience −9 dB · SFX −3 dB · UI −6 dB · Master 0 dB (limiter only) | The beds sit ≥ 6 dB under the one-shots; the score under both. The audio-director ratifies the master at the sound-bible pass |
| **Snapshots** | **Exactly one mix snapshot** at MVP (`SNAP_GAMEPLAY`). Zero snapshot changes across [E1, E7]. The offline state is the duck request, not a snapshot | "No snapshot change that reads as a beat" is easiest to prove with one snapshot |
| **Voice pools** | SFX 12 · Ambience 4 · Music 1 · Flip 1 (reserved, never stolen) · UI 0 → **18 of a 20 hard cap** | The turnover needs 2 beds simultaneously (recede + arrive); the cap leaves slack |
| **Steal** | Lowest class first (P3 → P2 → P1 → P0), within a class the oldest; never P0; never a signature | The tear and the signatures are the player's memory of the beat |
| **Loop points** | Beds seamless at bar boundaries; the arrival starts a bed's **first** start, never a restart of a sounding loop | The bracket's loop-restart ban |
| **Import** | Beds: Ogg Vorbis mono 44.1 kHz, loop on, q0.5–0.6 · Score: Ogg Vorbis stereo 44.1 kHz, loop on, q0.6–0.7 · One-shots: WAV 16-bit mono 44.1 kHz, trimmed, −3 dBFS peak, no loop | Mono beds halve memory; WAV one-shots avoid decode latency on the hit frame |
| **Budget** | Disk ≤ 10 MB · runtime ≤ 16 MB · 20 voices · the **Pixel 6a** reference SKU (QA plan §5.1) · the audio core's logic tick ≤ 0.10 ms p99.9 / 0.30 max (proposal for the technical-director) | ≤ 16 MB ≈ 10% of the 150 MB RAM ceiling; the mixing runs on the audio thread, the core only routes events |
| **Duck schema** | `duck_request {bus, dB, hold}` — exactly three fields, consumed verbatim. `bus ∈ {MUSIC}` · `dB ∈ [−24, 0]` · `hold ∈ {UNTIL_OFFLINE_EXIT}`. Attack 120 ms, release 240 ms | A schema change is a contract revision; the three fields suffice at MVP |
| **Telemetry** | The **order-trace record** (hashable): `{tick, target_rooms, excluded, recede_ms, arrive_not_before_tick}` · the duck counter (1/death) · the steal counter · the gate-drop counter · the missing-input counter · a bounded 256-record ring | The order trace is the replay hash's audio half (AC-DR-08's "identical to the fresh flip") |
| **Failure paths** | E3b missing → the bed stays put + one rate-limited record + a dev assert; **no self-shift** · the tear asset missing → the flip is silent, the choreography proceeds (audio never blocks) · the duck's bus missing → drop + error (never a silent Master duck) · the release edge lost → the offline screen's tree-exit is the backstop · a one-shot inside the bracket → drop + counter | Each mirrors the house pattern: named owner, no silent default |
| **Core shape** | `AudioCore` is a pure `RefCounted` over ports (`AudioPort`, `ClockPort`, `TelemetryPort`, `TuningPort`); edges arrive at the node adapter. No `Input`, `Time`, `SceneTree`, `RenderingServer`; **no read of `truth_epoch`** | The ADR §15 seam pattern, as `RealityCore`/`WorldCore`/`CameraCore` |

### 1.9 The mix plan

- **The death-duck ratification (OQ-J7)**: −6 dB on the Music bus, held to the offline exit, released on both exits. The rationale: −6 is audible as a step-back but leaves the score present (the death is not a silence); −12 would read as the music dying (the world's job, not the score's); 0 would make the beat invisible. **Proposed: ratify −6.**
- **Priority/steal**: P0 reserved (tear) → P1 signature (death/revive/memory) → P2 combat (damage/clash/deflect/defeat) → P3 feedback (heal/level-up/jump-2). Steal lowest, then oldest.
- **Masking**: the beds are low-mid-weighted and sit −6 dB under the one-shots; the one-shots occupy the transient band; the static EQ carve of the beds around the one-shots' fundamentals is the **audio-director's palette pass** (not mine).
- **Accessibility**: a `MONO` toggle on Master (one effect, engine mechanism deferred to the ADR); **three volume sliders** — Master, Music, SFX — with the Ambience and UI buses assigned to the SFX slider's group (3 sliders, 4 buses, one documented group mapping); SYS-24 renders the surface. Captions for non-speech cues: **out of scope at MVP**, but the audio core publishes an event-metadata hook (event ID + tick) so captions can be added without re-authoring (OQ-AUD-7).
- **The "text+shape" law**: audio carries no unique meaning — every meaning completes visually (SYS-29's gain-toggle law); the mix is redundancy, never information.

### 1.10 Feasibility and risks

**Feasible now.** All seven contract inputs are landed on `origin/Main` at `e8b194d`, with testable assertions on both sides (AC-DR-27, AC-WME-07, AC-JCE-31/32). The authoring needs no contract revision. The GDD can be authored to its definition of done with one placeholder pattern: the palette.

**Gaps / risks**

1. **No sound bible / sonic palette exists in the repo** (no `design/audio/`, no sound-bible doc). The palette — timbres, instrument vocabulary, the "machine air" vs "candlelit air" character — is the **audio-director's** decision, not mine. Mitigation: the GDD carries `PROV_AUD_*` provisional role names (function + register + envelope class, no instrument pins) with `status: PLACEHOLDER`, exactly the `PROV_*` pattern the art pipeline uses; the sound-bible pass upgrades them in place. This is OQ-AUD-1 and it is the one decision that shapes the text.
2. **The MVP score's scope is unstated.** The music bus and the death duck imply a score exists; if there is no score at MVP, the duck has nothing to duck (TR-JCE-027 breaks). Also, "the tear hook is beat-aligned at τ0" needs a reading: τ0 is event-driven (the Reading's close), so true musical alignment cannot be guaranteed without a score phase-sync surface. Recommended reading: the "beat" is the game's tick grid (60 tps) and the tear is a meter-agnostic transient; the score is untouched by the flip. OQ-AUD-2.
3. **No audio ADR and no Godot audio API reference.** `docs/engine-reference/godot/` holds only `VERSION.md`; Godot 4.4–4.7 audio specifics are post-cutoff for the model. The GDD states **what, never how** (the house style), and the mechanism choices (bus effects, snapshot implementation, voice pool, Ogg/WAV import flags) belong to an ADR — the `ADR-DRAFT` standby lane already covers SYS-03/SYS-04/SYS-05 per the manifest. Risk contained, but the ADR must not be skipped before the first story.
4. **The one-duck audit is fragile.** A well-meaning "duck the music for the offline screen's fade" or "duck under the freeze" would silently break AC-JCE-31. Mitigation: V-AUD-01 + a LINT AC + the single call site + the runtime counter.
5. **The order-trace determinism** is a real architecture requirement (AC-DR-08's "replay hash identical to the fresh flip" includes the audio orders). If the audio core timestamps from wall time or iterates an unordered set, the hash breaks. Mitigation: the trace is tick-stamped, ordered, and hashed by F-AUD-06; the ADR pins the structure.
6. **The reference SKU** is the Pixel 6a (QA plan §5.1); the audio budget numbers are proposals until the technical-director's ceiling is set (OQ-AUD-6).

### 1.11 Open questions for the user (batched as OQ-AUD-1..8)

| # | Question | Options | Recommendation | Blocks |
|---|---|---|---|---|
| **OQ-AUD-1** | Where does the sonic palette live? No sound bible exists. | (a) The GDD carries `PROV_AUD_*` provisional role names (function/register/envelope, no instrument pins), upgraded by the sound-bible pass; (b) block SYS-04 until the sound bible is authored | **(a)** — mirrors the art pipeline's `PROV_*` pattern; keeps SYS-04's contract deliverable unblocked | The palette sections (E/F/H). **The one decision that shapes the text** |
| **OQ-AUD-2** | The MVP score's scope and the "beat-aligned" reading | (a) One score loop; "beat" = the 60 tps tick grid; the score is untouched by the flip; (b) no score at MVP → the death duck needs a TR-JCE-027 revision (duck the Ambience bus instead); (c) true musical alignment → needs a score tempo + phase-sync surface | **(a)** — keeps TR-JCE-027 intact, the τ0 pin exact, and the flip free of score surgery | The flip composition + the duck |
| **OQ-AUD-3** | OQ-J7 ratification: `DEATH_DUCK_DB` | −6 dB on the Music bus, held to the offline exit, released on reconstruct **and** revive | **Ratify −6** (the [−12, 0] range stands) | The mix section |
| **OQ-AUD-4** | UI voices at MVP | (a) zero menu/UI voices (the closed list stays exact); (b) add menu clicks → a TR-JCE-027 revision | **(a)** | The closed-list audit |
| **OQ-AUD-5** | The arena bed's identity | (a) a distinct epoch-invariant asset `AMB_ARENA_STEEL_HUM`; (b) the A bed with an epoch-pin flag | **(a)** — the zero-arena-bed-orders assertion becomes trivial | The bed table |
| **OQ-AUD-6** | The mobile audio budget | ≤ 10 MB disk / ≤ 16 MB runtime / 20 voices on the Pixel 6a | **Confirm, or defer to the technical-director** | The architecture section's numbers |
| **OQ-AUD-7** | Captions for non-speech cues | (a) out of scope at MVP, with the event-metadata hook reserved; (b) in scope | **(a)** | The accessibility section |
| **OQ-AUD-8** | The accessibility surface's ownership | 3 sliders (Master/Music/SFX; Ambience+UI ride the SFX group) + MONO, rendered by SYS-24 | **Confirm** | The mix section's a11y subsection |

### 1.12 Section plan (A–K)

| § | Section | Contents | Est. counts |
|---|---|---|---|
| **A** | Overview | Drafted (see `design/gdd/audio-core.md`) | — |
| **B** | Player Fantasy | Drafted (see the file) | — |
| **C** | Contracts Consumed | The E1–E7 table verbatim + the audio obligation column; G1–G7 as consumed; the closed list's arithmetic; the arena/wing expectations; the abort and latched-resume cases; the no-duck rulings | TR-AUD-001..008 |
| **D** | The Flip's Sound | AR-AUD-01 (receding-first) · AR-AUD-02 (brackets) · AR-AUD-03 (arena) · the tear layer · the in-arena edge case | TR-AUD-009..014 |
| **E** | The Closed Edge List | 13 one-shot spec sheets (trigger, bus, class, concurrency, retrigger, variants, duration); the amount-band law; the variation plan | TR-AUD-015..019 |
| **F** | Ambience Design | The 3 beds and their layers; the room→bed table; the wing's no-op; the arena's invariance; the transition law; the stochastic-detail ban | TR-AUD-020..023 |
| **G** | Audio Architecture | Buses · the one snapshot · voice pools/cap · loop points · import · budget · the duck schema · telemetry/order trace · the failure paths · the core shape | TR-AUD-024..031 |
| **H** | The Mix | Nominal volumes · priority/steal · masking · the OQ-J7 ratification · accessibility | TR-AUD-032..035 |
| **I** | Formulas | F-AUD-01..07 | 7 formulas |
| **J** | V-Invariants & ACs | V-AUD-01..07 + ~24 ACs ([GUT] ~16 · [LINT] 3 · [DEVICE] 3 · [PLAYTEST] 2) | 7 V + 24 ACs |
| **K** | Knobs · Edge Cases · Dependencies · OQs | The knob table with ranges/rationale; the edge ledger; the dependency matrix; OQ-AUD-1..8 | ~12 knobs |

**Target totals** (to reproduce at landing): ~35 TR-AUD · 7 F-AUD · 7 V-AUD · ~24 ACs · ~12 knobs · 8 OQs.

---

## 2 · Draft

- **File**: `design/gdd/audio-core.md` — status `Draft — skeleton`.
- **Authored now**: the header (contracts, pillar), **§A Overview** (~430 words), **§B Player Fantasy** (~400 words), both marked `Draft` in the document's status line.
- **Skeleton**: §C–§K carry their one-line intent and `to be authored (pending approval)`; no final section is written.
- **Review log**: `design/gdd/reviews/sys04-audio-core-review-log.md` — the authoring entries, the six in-session decisions to ratify at section authoring, and the "no contract revision requested" record.

---

## 3 · Lane report

- **Status**: `AUTHORING`
- **Gate trail**: CD — · creative — · technical — · QA — · spot-check — · micro-check — (none run; the authoring loop has not reached the gates)
- **Blockers (hard)**: none. Batched decisions OQ-AUD-1..8; only OQ-AUD-1 shapes the text and it has a recommended unblocking pattern.
- **Sync request**: none yet. Planned entries: `audio_bus_contract` (the bus layout + volumes), `ambient_bed_contract` (the bed table + the arena invariance), `duck_request_contract` (the schema + the single family), `audio_edge_contract` (the closed list + the 13 voices) + the SYS-04 row completion (GDD path, counts, the E1–E7 consumption record) + the design-order row #16 mark. Exact YAML to be prepared at landing.
- **CodeRabbit**: not run.
- **Landing receipt**: not merged.
- **Next action**: user approval of the section plan (§1.12), then author sections A–K with `/design-system` discipline (Question → Options → Decision → Draft → Approval), starting with §C (Contracts Consumed) because it is pure consumption and fixes the vocabulary the rest of the document uses.
