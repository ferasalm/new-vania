# PROPOSED — Pandora Hero Sprite Quality Matrix + Next-Worker Brief

> **Status: PROPOSED — not canonical, not production-complete.** Owned by this handoff only.
> Owner file: `production/handoff/PANDORA-QUALITY.md` (PATCH). No asset-manifest changes are
> made here. Nothing in this file approves frame-count increases or wires art.

## 1. Grounding (verified 2026-11-16)

- **Art bible** `design/art/art-bible.md` — read. Binding clauses for the hero: §3 committed
  poses (SotN weight, no neutral A-poses), rim-light rule (1-px glow-family rim on the
  key-facing side; Pandora's near-black chassis needs it), §4.5 value-zoning measurement
  rule (rim-lit near-black bodies are audited on the **contour**, not the fill), §2B evidence
  standard (**frame strips** anticipation→strike→recovery ≥3 frames; single-frame GIFs are
  not reviewable), §8 asset standards/naming.
- **Technical preferences** `docs/framework/technical-preferences.md` — read: Godot 4.7.2,
  GDScript, mobile-first 60 fps, 480×270 art res, telegraphs = color-flash + shape,
  snake_case naming, GUT tests.
- **Pandora narrative profile: not found by the scout.** Use the existing art bible and
  owned `pandora-001-sprite.jpg` / `pandora-001-concept.jpg`, without inventing new lore.
  `86c636c1-9042-4efa-b23f-f8bd3aa3f952` is a generated cape-free CANDIDATE, not an approved reference.
- **Runtime state enumeration** (grep of `player.gd`, `game.gd`, `smoke.gd` — TEXT only):
  idle, run, jump, crouch, land, attack, attack2, crouchatk, crouchatk2, airatk(2),
  cast, backdash, hurt, dead. `frames.json` confirms the counts.
- **Separate wall animation names are absent** from the current hero metadata; this does
  not mean the tested wall-jump mechanic is absent. Wall cling / slide / kick pose support
  belongs to B04: prepare and review art, but do not invent new gameplay states to fit it.

## 2. Metadata contract — DISAGREEMENT FLAGGED

`prototypes/feel-v3/assets/frames.json` hero block: **77 frames total** (lead independently summed JSON)
(6+16+4+1+5+5+5+5+5+5+5+4+2+5+4), size [112,80], feet [56,76], faces right.
Fable reported "92 cutouts hero v2" for a separate, unwired set. It is NOT the 77-frame runtime contract.
**frames.json is the runtime contract; the 92-set is neither wired nor approved.**
Any final set must reconcile against frames.json, not against memory.

## 3. PROPOSED acceptance matrix (per animation)

Applies to every animation in frames.json's hero list. A row passes only when **all** cells pass.

| Gate | Bar |
|---|---|
| Frame count | Matches frames.json (proposed land/hurt/cast/death increases need a runtime + art-bible review; NOT approved here — do not pre-author) |
| Dimensions | Native 112×80; shared logical pivot [56,76]; planted contacts drift at most 1 px. Airborne or lifted feet may move naturally without changing the logical pivot |
| Palette | Stable global palette, no per-frame palette drift, no added blur/anti-alias outside the style contract |
| Edges | High-contrast alpha edges, no halo, no semi-transparent mush at the contour |
| Volume | Body/chassis volume consistent across frames; no limb-stretch to fake cloth — cloth (hair, cape if the user approves it) moves on its own weights |
| Motion quality | Contact/anticipation/active/recovery distinguishable; no duplicate-frame padding presented as animation |
| Rim | 1-px rim in the glow family on the key-facing side (art bible §3) |
| Evidence | Sheet 1×N per anim + GIF **both directions** + in-Godot screenshot + fresh SMOKE 58/58 and CLIMB PASS |
| Provenance | No tracing or derivation from Shanoa frames or prohibited previous art. Rodin stock motions (rig f08e54b8…, library 109ca55a…) are blocking inputs, not authored-sprite proof; confirm publication rights before distribution |
| Approval | Human approval per set; old hero set rollback retained until approval |

**Coverage additions (B04-facing, conditional):** wall_cling / wall_slide / wall_kick —
spec only at this stage; author only when mechanics exist or B04 requires them.

## 4. First practical task (worker)

1. **The proportion study is REJECTED. Create ONE actual 2D idle base first.**
   New direction: the two JPGs in `assets/pandora_proportion_study/reference/`:
   exposed skin upper arms, a more defined mature face, flowing silver ponytail.
   Keep the ponytail intentionally large; do not substitute more leg stretching.
   Output `assets/hero_2d_base/`, native 112x80, shared pivot [56,76], faces right,
   transparent, also shown enlarged. Human approval BEFORE any sheet expansion.
   All four Pandora jobs
   (cape-free `86c636c1…`, core rig `f08e54b8…`, original core library `109ca55a…`,
   parts `ad6a0c64…`) are now downloaded under `tools/models/bank/`; hashes are in
   `HERO-DOWNLOADS.json`. Inspect local files; do not pay to regenerate them.
   These are optional pose/volume aids, not approved final sprites or compulsory
   3D repair work. The 2D look is the deliverable, not the model's close-up fidelity.
2. **After base approval, quote and agree the full-sheet budget in THIS session.**
   User wants the full sheet before handoff, but approved only a $2 additional base
   test allowance so far. Do not claim a full sheet is funded or approved.
   Then **4-action polished pilot: idle, run, jump, wall** — wall from B04 handling only
   (pose support; runtime wiring is not this task). Do **not** extrapolate the full
   matrix from the pilot; the full set is a separate pass.
3. Base-sprite approval is **not** full-animation-set approval. Complete the
   full quality matrix and obtain implementation approval before a runtime switch.
   Cape-free costume: **human-approved before it becomes anything canonical** —
   a silent costume change from the cape reference is forbidden.
4. Pipeline: native Aseprite, layers body/hair/cape(conditional)/weapon/VFX-guide;
   tags + durations locked. **Latest user routing overrides the previous pairing:**
   all well-scoped helper work uses Cloudflare DeepSeek V4.1 Flash 1017 **max**;
   GLM 5.3 Flash **default** only for open-ended creative writing/ideation without
   instructions. Main lead provides independent visual review. Record exact model
   IDs per run; 2 failures → stop; honest statuses only.

## 5. Explicit prohibitions

- No partial-set wiring into the runtime.
- No distributable-demo claim while the currently wired prohibited legacy hero art remains. The separate `hero_v2` cutouts are unwired and unapproved; do not conflate the two sets.
- No approval of new land/hurt/cast/death frame counts here.
- Never view prohibited previous art to "compare".

*POGR statuses: done / in progress / planned / not planned / waiting on user. A finished pilot is not a finished sprite set.*
