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

*(appended as the gates run)*
