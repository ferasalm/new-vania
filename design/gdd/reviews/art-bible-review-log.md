# Art Bible — review log (lane ART-BIBLE)

> **Document**: `design/art/art-bible.md` (+ `design/art/palette.json`, `design/art/style-anchor-prompt.md`)
> **Lane**: ART-BIBLE · branch `docs/art-bible` · worktree `../new-vania-art-bible` · model GLM-5.3-flash
> **Started**: 2026-11-14 (the prior lane sessions) · **Resumed + completed**: 2026-11-15

## A. Authoring record

### A.1 Prior lane sessions (2026-11-14, summarized; the full detail is in the prior lane report, git history)

- The lane produced three deliverables: the D-ORCH-01 decision package (SYS-11 OQ-1), the D-ORCH-02 palette/grief pin package (SYS-11 OQ-4), and the Visual Identity Statement + the 9-section plan — all marked DRAFT/proposed pending user decision.
- A premature SYS-02 line-36 edit (`a81ef52`) was reverted (`8fbc13e`) — the recorded lesson: no frozen-contract edit before the decision record.
- A GLM rerun re-authored the creative deliverables on GLM and re-verified the color math (the DS-era draft is preserved at `218cdee`).

### A.2 This session (2026-11-15) — the decisions applied, the bible completed

1. **Preconditions re-verified**: prompt header `1.0.0` / `fe36c9a4acd2` = manifest row ✓; branch `docs/art-bible` at `20ddd95` (a merge of `origin/Main` through `ce46fac`); `git merge-base --is-ancestor origin/Main HEAD` → **ANCESTRY OK**; working tree clean; STATE.md does not mark the lane BLOCKED; the shared-file lock is free; review mode `production/review-mode.txt` = full.
2. **D-ORCH-01 applied** (decisions.md: APPROVED — B, 2026-11-15): SYS-02 `design/gdd/room-world-structure.md` line 36 amended — *"a purple bridge holding it together"* → *"a bridge of neither truth holding it together"* (the recorded proposal text from the approved package; the decisions row offered "the grey bridge / the bridge of neither truth" — the executing edit takes the package's proposed wording). Exactly one line changed; the commit (`5cc1377`) names D-ORCH-01. The SYS-11 index-row qualification is recorded as a **sync rider** in the lane report (the OQ-M1 pattern; not this lane's file to edit).
3. **D-ORCH-02 applied** (decisions.md: approved as proposed, 2026-11-15): the four `PROV_LIM_*` L values + the grief C/L + the hue band [330, 20] are recorded as approved pins in §4; entries upgraded PLACEHOLDER → **PINNED** with the decision as source. OQ-4's conditional is recorded as **not exercised**: quantized gaps 0.098 / 0.110 / 0.109 ≥ 0.09 — the D-gap clause does not relax, the tint does not close on gap grounds.
4. **The bible completed** (`design/art/art-bible.md`): §1 finalized (the D-ORCH-01 ruling paragraph is final); §2, §2B, §3, §4 (full color system), §4B, §4C, §4D, §5, §6, §7, §8, §8B, §9 authored; §10 = the `/asset-spec` handoff list. Exports: `design/art/palette.json` (JSON only — the recorded default; no CSS consumer), `design/art/style-anchor-prompt.md`. Phase 4.5 web reference search skipped (the recorded default — the concept corpus is the catalog).

### A.3 Independent color-math verification (this session, before any pin was written)

A from-scratch OKLCH implementation (standard Ottosson matrices, D65, sRGB gamma; the a-row coefficient corrected to 0.4505937090 — the achromatic-sum property was the check) verified every load-bearing hex:

| Entry | Hex | OKLCH (verified) | Contract check |
|---|---|---|---|
| `PROV_LIM_DEEP` | `#484848` | L 0.4017 · C 0.0000 | VR-SMB-01 ladder ✓ |
| `PROV_LIM_MID` | `#636363` | L 0.4997 · C 0.0000 | ✓ |
| `PROV_LIM_PALE` | `#838383` | L 0.6100 · C 0.0000 | ✓ |
| `PROV_LIM_LIGHT` | `#A4A4A4` | L 0.7187 · C 0.0000 | ✓ |
| quantized gaps | — | **0.0980 / 0.1103 / 0.1087** | ≥ 0.09 ✓ (margins +0.008/+0.020/+0.019) |
| `PROV_GRIEF_TINT` | `#CD6CA6` | L 0.6602 · C 0.1402 · h 344.8° | VR-SMB-07 (C 0.12–0.18, L 0.55–0.68) ✓; band [330,20] ✓; forward-map round-trip byte-exact |
| alternative grief | `#D36A96` | L 0.6595 · C 0.1404 · h 355.2° | recorded alternative ✓ |
| `PROV_GLITCH_ACCENT` | `#00CFE8` | L 0.7830 · C 0.1354 · h 210.1° | matches the prior annotation (L 0.78 · C 0.14 · h 210) ✓ |
| A-ratification tint family | `#42465A/#5D6277/#7D8298/#9EA3BA` | L 0.3986/0.4996/0.6101/0.7190 · C 0.034 · h ~275 | the razor window (source C 0.0333–0.0349) ✓; ΔL vs ramp ≤ 0.004 ✓ |
| contrast ratios | — | DEEP→MID 1.52 · MID→PALE 1.58 · PALE→LIGHT 1.52 · DEEP→LIGHT 3.67 | even ladder ✓ |

### A.4 Recorded refinements (deviations from the prior draft, with reasons)

1. **The hue-set extraction threshold: C ≥ 0.05** (the prior draft recorded 0.02 provisionally). Reason: the A/B slate members sit at C 0.013–0.049 — inside quantization noise, hues drifting ±30° under the pack normalization audit; a hue interval must not depend on them. With C ≥ 0.05 the extraction yields A = {206.6, 210.3}, B = {14.1, 33.2, 74.6, 74.9, 78.5} → the feasible interval **[255, 304.8]** (open arcs), and the recorded candidate h 275 stays feasible. This is an art-bible-side data definition for F-SMB-07's inputs, not a SYS-11 formula change; rides SYS-11's data sheet at its next touch.
2. **The line-36 wording**: the decisions row offers two alternatives; the executing edit takes the approved package's proposal ("a bridge of neither truth holding it together"). The one-word alternative ("a grey bridge") is recorded here for completeness; the meaning is identical.
3. **A/B slot placeholder hexes**: the packs are not yet promoted (`assets/source` is empty; the normalization audit has not run; the Aseprite reference tool cannot reach the concept corpus in this environment), so §4.5's hexes are derived from the locked concept masters' documented dialect bands (PROMPT-PACK shots 1A/1B; the game concept's color philosophy) with their OKLCH values computed and recorded. They carry status PLACEHOLDER with source "concept master dialect band; pending pack promotion + normalization audit" — the pack audit changes hexes, never the structure.

### A.5 Hard-constraint compliance check (the lane brief's list)

| Constraint | Where enforced |
|---|---|
| one geometry, two palettes | §3/§6 (the isomorphism law, the pack audit); §4.5's paired tables |
| the liminal ramp is epoch-invariant | §4.1's ramp laws; §8B #1/#6/#7 |
| the arena's pristine lie keeps `epoch_pin: 0` | §2 state 4; §6 room kit; §8B (no per-room exception *except* the arena's licensed cleanliness, which is the lie's design) |
| the greys read quiet, not corrupted | §2's "quiet, not corrupted" bar (TR-DR-012 verbatim); §4.1 |
| the purple is never on the threshold band, the north row, the fill, fixtures, or M4 | §1's final ruling (the admitted-placement bounds are permanent even for a future re-open); the purple is declined at MVP entirely |
| no new MVP prompt/VFX/audio authorized by the bible | §2B's scope law (a constraint pass; the owning GDDs win) |

## B. Gate trail

### B.1 CD gate (CD-GDD-ALIGN) — run 1 — **CONCERNS** (2026-11-15, GLM-5.3-flash, nested subagent `ses_e22ce06f3ffeuQNvbhAQYsmLpJ`)

**Blockers (2, both accepted as valid):**

1. §5's Acceptance row ("the crown gone or dissolved") contradicted §3's crown invariant and REVIEW L132's adopted lock → **repaired**: Acceptance now carries the crown "healed smooth" (unadorned, halo-free vs Denial; the body's openness carries the stage; the invariant holds in all five).
2. OQ-RWS-7's climbable-surface pin was unaddressed (SYS-02 L507/L127/L400 assign the wall-tag visual language to this bible; RM-05 ships the tagged shaft at MVP) → verified against `room-world-structure.md` (TR-RWS-024; the provisional lifetimes; OQ-RWS-7's row) → **repaired**: §6 gains "The climbable-surface language" (grip-rhythm treatment: A maintenance rungs / B masonry handhold courses, same spacing; shape rhythm, never a pointing device) + §10 handoff item 10.

**Recommendations (7/7 accepted — all one-line, non-gating):** R1 §8B #7 qualified to the seam's standing presentation (the wing receives the tear during the flip window); R2 the grief-wash channel separated from the wing-placement law (§4 semantic table); R3 the MVP telegraph-flash source named — the owning truth's GLOW family, the HAZARD slots stay dormant (§2B); R4 the §4 preamble's dormancy note aligned (B_SEAL/B_HAZARD per OQ-DR-8; A_SEAL zero-occurrence per AC-DR-02); R5 §9's locked-masters list expanded to the full REVIEW-adopted set + the selection rule stated; R6 §4.1's DEEP note cites the frame step array [DEEP, MID, MID, PALE, PALE]; R7 §6's dither default pinned (prohibition by default; per-asset-spec grant recorded, never silent).

**Notes accepted for the record:** the arithmetic contracts reproduce (alpha array, gap check, feasible interval, P1–P5+G on the recorded A-path data); D-ORCH-01/02 applied faithfully; the corpus numbering collision (SYS-11's OQ-1 cites "(OQ-RWS-7)" for the purple while SYS-02 assigns OQ-RWS-7 to the wall-tag language) is recorded here — the purple side is closed by D-ORCH-01; the wall-tag side is now pinned (blocker 2's repair). The SYS-11 index row's "Cold Corridor purple = bridge material" wording remains pending the recorded sync rider (not a bible contradiction).

### B.2 Three-seat panel — run 1 — **NEEDS REVISION (3 creative + 6 technical + 8 QA)** (2026-11-15; creative GLM `ses_e22c95edfffe7JtFledeaX0Sbo`, technical DS `ses_e22c95edcffem5QRHj0oMSLdWI`, QA DS `ses_e22c95e90ffeQ7P3c57RnrFhLY` — parallel nested subagents)

**Blockers triaged — all 17 accepted as valid (0 rebuttals), with overlaps merged into 14 repairs:**

1. *(C1/T5)* **§2B telegraph grammar** contradicted SYS-13's TR-ENM-013 (the flash = the power band; hexes pin at the art bible per OQ-ENM-3) → **repaired**: band 1 = `PROV_A_HAZARD` `#7DF0FF`, band 2 = the derived deep amber `#C78B28` (L 0.68 · C 0.13 · h 75), ΔL 0.213 ≥ 0.20 + ≈ 7 ramp-index positions (both metric forms pass), band 3 VS-recorded, truth-independent, never sigil-red, never color-alone; §4's semantic vocabulary gains the flash-pair row; §10 answers OQ-ENM-3.
2. *(C2/T2)* **§4.5 value zoning** asserted arithmetic that fails the ≥ 0.20 L bar (A_WALL ΔL 0.102; B_WALL 0.109) → **repaired honestly**: the body does not clear the darkest backdrops by fill value; the read is **rim-carried** (the contour is the audit's measurement surface for rim-lit near-black bodies), SYS-29's countersign recorded, the re-derivation path named; **§4.6 added — the canonical value ramp** (the ordered index table pinning TR-JCE-016's "PROV_PALETTE ordering until the art-bible pin" and reconciling the two metric forms).
3. *(C3/Q4)* **The grief wash** was carried as a live MVP channel with no owning GDD (and a no-spill collision) → **repaired**: the wash is **VS-recorded direction, not an MVP channel** (the concept graft's landing terms: owning GDD + bounded alpha + discriminator re-run + the seam exclusion at VS); at MVP the grief tint's presence is M4's anchor only; the semantic table's rose row corrected.
4. *(T1)* **§7's "SYS-24's 9-field publication"** misattributed SYS-32's TR-CAM-015 → **repaired**: TR-CAM-015 named as SYS-24's input; the nine-item look list marked a bible-side proposal pending SYS-24's authoring.
5. *(T3/CR2-rec)* **A_HAZARD's dormancy** was misstated (OQ-DR-8 dormants only the B side) → **repaired**: A_HAZARD is a live A member whose MVP consumer is the band-1 telegraph flash; B_HAZARD/B_SEAL stay dormant.
6. *(T4)* **OQ-DR-6 never consumed** → **repaired**: the tear's GPU budget ≤ 1.5 ms/frame p95 adopted (PR-DR-03/06 the tripwire) + the resolution half answered by §6's 480×270/16 px + ADR-0001's D1; §8's budget list gains the line; §10 records the answer.
7. *(T5)* **The spark pair** was made truth-keyed against TR-JCE-016's designer-fixed pair → **repaired verbatim**: contact = amber = `PROV_B_GLOW`, midpoint = cyan = `PROV_A_GLOW` (OQ-J3's hex pin); plus the damage-number glyph palette (amber/pale-bone/cyan = `PROV_B_GLOW`/`PROV_B_FRAME`/`PROV_A_GLOW`), the sting magnitudes (LOW base/MID ×1.5/HIGH ×2.2), and the grant-cue VFX family — OQ-J3 answered comprehensively.
8. *(T6/QA-R1/CR-R1)* **§7's map pulse vs §8B #24** self-blocked → **repaired**: #24 scoped to the world layer; the map's once-per-open pulse named an explicit bounded screen-space exception.
9. *(Q1/QA-R1)* **§1's 2-second bar** unfalsifiable + collided with the seam's "neither" read → **repaired**: scoped to truth-rendered frames (the wing excluded — VR-SMB-09 owns it), AC-DR-24's instrument adopted verbatim, n ≥ 5 / ≥ 4/5 / 0 failure reads, owner + evidence path + gate named.
10. *(Q2)* **§3's 32 px grief test** unfalsifiable + 4 of 5 states absent at MVP → **repaired**: the coded instrument (n ≥ 5, the closed five-stage list + "cannot tell", ≥ 4/5 modal-correct per state, the Denial↔Acceptance confusable pair), evidence = the 06 strip at 32 px, per-state gating (Denial's row at MVP).
11. *(Q3)* **The upgrade path** named no owner/gate; "content-ship gate"/"court pass" undefined → **repaired**: the entry-class → evidence → owner → gate → evidence-path table in the repo's gate vocabulary (the pack promotion audit, the MVP device gates, the court dressing pass, the SYS-11 admission harness).
12. *(Q5/TR-R2)* **The 0.05 extraction rule** changes F-SMB-07's output with no countersign → **repaired**: both intervals printed ([284, 304.8] at 0.02; [255, 304.8] at 0.05), the countersigners named (SYS-09's + SYS-11's owners, the OQ-2/OQ-3 pattern), the gate = before the first SYS-11 story, `ADM_HUE_BAND` cited, the P1 margin note added.
13. *(Q6/TR-R7)* **The grip cadence** dangled (no contract defines it) → **repaired numerically**: 2-tile pitch (32 px), ½-tile relief footprint inside the 2-value cap, 4-tile minimum run; the read test (tagged vs untagged capture, n ≥ 5, ≥ 4/5 + 0 on the control); owner + gate named; the seam's no-carvings rule explicitly not implicated.
14. *(Q7)* **§3's pixel-perfect overlay** untestable as written → **repaired**: the mechanism cited (TR-DR-009/AC-DR-03's packed-data byte hash) + the visual-twin test defined (epoch-0/epoch-1 XOR diff = exactly the designed palette deltas); owner + evidence + gate named; added to §10 (item 12).
15. *(Q8)* **The D-ORCH-01 propagation** incomplete (SYS-02's TR-RWS-015/TR-RWS-022 + the index row still route the purple) → **repaired**: the ruling paragraph now names the four rider sites (the index row → the sync lane now; TR-RWS-015/022 + AC-RWS-21's clause → SYS-02's next doc touch, the OQ-M1 pattern) with owner + verification gate. (This lane edits none of them.)
16. *(QA-R7/CR-R5/TR-R8)* **§4C** → the named-tiers clarification, the D1 surface split (art-res world text vs native-res UI text), the light-ink fallback for mid-value steel, the owned per-surface contrast check.
17. *(TR-R6)* **§8's import wording** corrected to Godot 4.7.2's real settings (the project canvas-texture filter, no per-import 2D filter flag) with the post-cutoff verification rule.

**Recommendations applied (one-line, non-gating):** CR-R3 (the cache pool as the interactable's local treatment + RM-04's tell family) · CR-R6 (§8B #3's court-canonical clause) · CR-R7 (the DEEP-remedy clause bound to §8B #25) · CR-R8 (the altar + impossible-flame pair pinned under the isomorphism law) · CR-R9 (the richness budget — where the SotN texture lives) · CR-R10 + QA-R2 (the ramp a11y + deuteranopia claims restated honestly) · TR-R1 (the wine-family distances printed: B_SEAL 29.3°, B_HAZARD 48.4°) · TR-R3 (the P1 margin note) · TR-R4 (RESERVED recorded as a schema-extension rider) · TR-R5/QA-R5 (16 slots / 15 hexes) · QA-R3 (the court pass must prove the sigil red's ≥ 2-step value separation or declare shape-only) · QA-R4 (the L-column target note) · QA-R6 (AC-DR-25 cited with the eligibility rule; the wing rides AC-SMB-21's failure catch) · QA-R8 (the band-edge worst case printed: h 330 → 55°; h 355 → 80°) · QA-R9 (the arena licence = AC-DR-14's two authored exceptions). *(B.1's R3 — "the HAZARD slots stay dormant" — is **superseded by B.2's blocker 5**: OQ-DR-8 dormants only the B side; A_HAZARD is live with the band-1 consumer.)*

**Recommendations folded into blockers:** QA-R1/TR-R10 (the 2-second instrument), QA-R10 (§10's overlay twin), TR-R2 (the countersign), CR-R2's A_HAZARD note (blocker 5), CR-R4 (blocker 7). **No recommendation rejected; no rebuttals.** *(Bookkeeping note: the 17 numbered rows are the three seats' blocker filings as triaged — 17 seat findings across 15 distinct defect sites (the creative/technical seats overlap on the zoning defect, rows 2; the creative/QA seats overlap on the wash, rows 3; T5 is tagged on two distinct findings — row 1 the flash-band contradiction and row 7 the spark pair's truth-keying); "14 repairs" counts the rows that changed art-bible text.)*

### B.3 qa-lead spot-check — run 1 — **PASS** (2026-11-15, DS, nested subagent `ses_e22bf8f70ffeDURjar1mCxqi3k`)

Diff-scoped on `ef470d2..db48b9e`: **17/17 rows APPLIED-CORRECTLY** (plus the recommendations list and the CD blockers); every touched number re-derived (the band-2 flash's OKLCH recomputed 0.6804/0.1303/74.7°; ΔL 0.2126 ≥ 0.20; all 21 §4.6 indices re-derive ascending; the feasible intervals re-derive at both thresholds; P1's 0.035 margin confirmed); every touched citation resolves (TR-ENM-013, AC-ENM-32, OQ-ENM-3, TR-JCE-016/024, OQ-J3, OQ-DR-6, AC-DR-24/25/14, TR-DR-009/AC-DR-03, TR-CAM-015's field order, OQ-DR-8's B-side scope, TR-RWS-015/022/AC-RWS-21 verbatim, OQ-RWS-7, VR-SMB-09/AC-SMB-21). 5 advisories (non-blocking) — **all 5 applied** in the follow-up commit: the band-2 "no bright member" qualification, §8B #21's flash-pair exception clause, the 1.5:1 ratio correction, §4.6's derived-shade conservative reading, and this log's B.1-R3 supersession + the bookkeeping note.

### B.4 Final micro-check

**Run 1 — FAIL (2 blockers)** (2026-11-15, DS, nested subagent `ses_e22b8c078ffeEiaoHe7irxH8dg`, delta `db48b9e..b10cbd8`):
1. The advisory-(a) fix was applied additively — the falsified clause "no table member sits ≥ 0.20 below a bright flash" survived verbatim in the band-2 bullet while the qualified form landed in the separation bullet → **repaired**: the band-2 bullet's clause replaced (the derivation reason now points to the separation bullet); the qualified form (+ "e.g." for the dimmer-members list, adding `PROV_GRIEF_TINT` 0.660) lives in the separation bullet only.
2. The bookkeeping note misderived ("15 blocker-bearing rows"; "T5 rows 1 and 5") → **repaired**: restated to re-derive — 17 seat findings across the distinct defect sites (creative/technical overlap on the zoning; creative/QA overlap on the wash; T5 tagged on rows 1 and 7), "14 repairs" = the rows that changed art-bible text.

Advisories (3) applied: "e.g." in the dimmer-members list; the §4.6 table footnote aligned ("a derived shade reads at its own L within its source's hue neighborhood"); §8B #21's exception reworded to its operative content ("the flash pair's truth-independence is the recorded exception").

**Run 2**: *(appended after the re-run)*
