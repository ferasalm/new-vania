# SYS-24 HUD — review log

> **Document**: `design/gdd/hud.md` · **Lane**: SYS-24 (branch `docs/sys24-hud`, worktree `../new-vania-sys24-hud`)
> **Prompt**: `prompts/lanes/SYS-24.md` v1.0.0 / hash `491dcc7c2b7a` (matches manifest: **yes** — verified against `manifest.yaml` SYS-24 row at launch)
> **Base**: `origin/Main` `016bbbe02db6d09d9d35c3701091a7f8774b6c0c` (ancestry verified: `merge-base --is-ancestor` → 0)
> **Launch**: 2026-11-15 · **Model**: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` (GLM — creative lane routing; DS never runs a creative seat)
> **Brief approval**: the feasibility brief + section plan approved as **D-ORCH-17** (2026-11-15); the eight authoring decisions recorded there are binding for this lane.

## A · Consumed contracts (read once each, in the lane's read order)

`design/gdd/systems-index.md` (SYS-24 rows: line 38, the dependency bullet 84, the tracker 176, design order 18) · `design/gdd/camera-framing.md` (TR-CAM-015, TR-CAM-012, the SYS-24 interaction rows, the envelope) · `design/gdd/health-damage.md` (TR-HD-008/015/023/035, F-HD-07, the bar/chip/boss-bar laws, the SYS-24 row) · `design/gdd/combat.md` (the commitment state's HUD boundary) · `design/gdd/input-control-mapping.md` (TR-INP-008/024/059/067/068/069/070/077/036/037/047, EX-9, AC-03/07/09/34/37/47/60/66/69/76, the Recalibration lists, the safe floors) · `design/gdd/juice-feedback.md` (TR-JCE-016/020/021/022/023/026/027/029/030/031, the four-entry settings list, the print slot, the reboot assignment) · `design/art/concepts/REVIEW.md` (the red rule, finding 5; the key-art recolor) · `design/gdd/progression.md` (TR-PRG-003/011/020/022/023/025/026/027/028, OQ-PRG-4/7, AC-PRG-06/11/30) · `design/gdd/save-serialization.md` (TR-SAV-017/020/021/022, §UI, OQ-SAV-7, the slot-list metadata) · `design/gdd/grief-boss-framework.md` (TR-GBF-012/015/018, the SYS-24 row — the boss bar's contract is LANDED) · `design/gdd/audio-core.md` (§H.4, TR-AUD-037, the tuning-read allowlist) · `design/gdd/cache-stations-death.md` (TR-CSD-001/004/009/011/014/015, OQ-CSD-2, the SYS-24 row) · `design/gdd/narrative-presentation.md` (TR-NAR-013's 17-line mapping) · `design/gdd/room-world-structure.md` (TR-RWS-015/018/025 — the memory counter's source) · `design/gdd/game-concept.md` (the MVP definition, the pillars/anti-pillars) · `design/art/art-bible.md` (§4 palette pins, §7 HUD look + the nine-item proposal, the D1 text split, the no-new-hue law) · `docs/framework/technical-preferences.md` · `docs/engine-reference/godot/VERSION.md` · `design/registry/entities.yaml` (READ-ONLY: `camera_publication_contract`, `progression_read`, `grant_event`, `progression_namespace`, `boss_hp_pool`, `player_max_hp` — schema + relevant rows).

**Feasibility decisions (D-ORCH-17's eight)**: the caps law (`player_screen_px + shake_offset_px`; `authority` ignored), the settings-persistence split (`controls.cfg` vs the `settings` namespace + the OQ-PRG-5 renumber rider), the chip geometry (240, 44) + the R-9-analog reach exemption pending the promotion audit, the bible-list accept/decline set, the envelope join (0.10/0.30 → 2.55/6.85), the per-script label caps, the truth-temperature accent, `TEXT_SCALE`.

## B · Gate trail

### B.1 CD gate (CD-GDD-ALIGN)

- Model: GLM (`cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`), brief `seat-briefs/cd-gate.md`.
- Verdict: **APPROVED — 0 blockers** (2026-11-15). 6 recommendations: 5 applied as one-line non-gating fixes (AC-15's geared-state form; F-HUD-01 example 1's arithmetic; §13's directional-weights note; OQ-HUD-1's gate-manifest clause-flip recording; the `LOW_HP_PULSE_PERIOD_MS` floor 900 → 1000), 1 rebutted (§D.1 — the designation-row claim contradicts SYS-15's landed TR-CSD-015).

### B.2 Three-seat panel

- creative (GLM): **PENDING**
- technical (DS `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`): **PENDING**
- QA (DS): **PENDING**

### B.3 Repairs

**PENDING** (the worklist appends below as repairs land).

### B.4 qa-lead spot-check

- **PENDING**

### B.5 Final micro-check

- **PENDING**

## C · Worklist (the repairs ledger)

| # | Source seat | Blocker / recommendation | Disposition | Owner |
|---|---|---|---|---|
| CD-1 | CD gate | AC-15's bundled fixture mixes the bare `HP 12/20` with the geared `ATK 3/5` as one state | APPLIED — the AC now names the bare state (`HP 12/20`, `ATK 2/4`) and SYS-16's own geared example (`HP 12/12` · `ATK 3/5`) separately | lane |
| CD-2 | CD gate | F-HUD-01 example 1's center/rect arithmetic (202/176–228) mismatches the 24-px-feet premise | APPLIED — recomputed: feet y 246, center y 224, rect [198, 250]; the Attack visual (y ≥ 180) intersects | lane |
| CD-3 | CD gate | §13's SYS-32 weight (hard) vs the camera's own Soft cell | APPLIED — the HUD-side hard + the camera-side Soft named as directional weights; the reconciliation rides the sync request | lane |
| CD-4 | CD gate | OQ-HUD-1 should name the gate-manifest clause flips the promotion forces | APPLIED — OQ-HUD-1 now lists the SYS-01 chip-clause gate flips (VS → MVP) as part of the recorded promotion | lane |
| CD-5 | CD gate | TR-HUD-010's revive-path Gameplay designation row "beyond SYS-15's three named print forms" | REBUTTED — §D.1 | lane |
| CD-6 | CD gate | `LOW_HP_PULSE_PERIOD_MS` floor 900 ms ≈ 1.11 Hz contradicts the ≤ 1 Hz claim | APPLIED — the floor is 1000 ms | lane |

## D · Rebuttals (a blocker judged invalid gets its line here, never a silent skip)

1. **CD-5 (the revive path's Gameplay designation row)** — the seat read SYS-15's print forms as three (terminal readout, post-reconstruction print, stamp twin). SYS-15's **TR-CSD-015** states verbatim: "**The revive's exit prints the new designation row in Gameplay** — `DESIGNATION 005` — the machine's acknowledgment of the remade body, driven by SYS-15's own increment event **in the same print-slot family as MEMORY CACHED** (the reconstruct path sees the number at the terminal; the revive path sees it in the field — the scar is witnessed on both paths)." The row is SYS-15's own fourth named form; TR-HUD-010 consumes it, it does not extend SYS-15's contract. No change.

## E · Sync request

Prepared in `production/session-state/lane-SYS-24-report.md` (the registry entries + the index corrections + the diff summary). `entities.yaml` and `systems-index.md` were never edited by this lane.
