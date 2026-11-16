# DEMO-TARGET — PROPOSED vertical-slice blueprint + worker briefs

> **Status: PROPOSAL.** Authored 2026-11-16, revised after Main's review. Authored by
> creative-director at the user's request; nothing is user-approved until the user says so.
> Every integration step sits behind the standing gates (art approval → wiring approval). I own
> only this file. I read: BRIEFS.md, OPENCODE-START.md, grief-boss-framework.md,
> proto-room-language.md. No prohibited file opened, no code or canonical docs touched.

## 0. Baseline (verified as of 2026-11-16; all tests re-run after any change)

- **CLIMB PASS** and **SMOKE 58/58** are the current passed baseline — not a permanent truth:
  every change to the slice re-runs SMOKE and CLIMB; the current numbers are only the starting
  point. B02 (user verdict on feel-v3) is still waiting on the human player.
- Hero art: original 4-pose preview is **NOT production-ready** (Fable reported cape weights
  stretch); 92-cutout `hero_v2` is **not approved / not wired**; traced `assets/hero/` is banned
  for new/published use. **No new asset is integrated in this session.**
- Hero frame contract, **fixed baseline**: **112×80, feet [56,76], faces right** — no alternative
  size is on the table for this slice.
- Touch-layout save/load: B07 is a **Fable-reported need-device-check** — the offline/touch fair-
  controls requirement below inherits a re-verification on device, not a passed claim.
- **B0 prerequisite (progression gate before the ascent):** the slice assumes a wall-climb relic
  exists or is added as authored state; the actual controller relic-gating mechanism must be
  verified first (T2.0). Nothing in R4/R5 proceeds on an assumed pickup.

## 1. The slice — "THE RELIQUARY CHIME" (10–15 min, one route; FUTURE PROPOSED)

Intro → enemy lesson → relic pickup → climb → return loop → boss climax → endpoint. It
demonstrates verified mechanics (run/jump/wall-jump, attack, telegraph reads, counter, deflect)
and one authored boss on the approved grief-boss frame (Denial pattern; slice-scaled values, a
proposal — never an override of SYS-14's authored numbers without a gate).

**Roster (minimum: 2 enemies + 1 boss; no miniboss), using ledger EXACT names — telegraphs below
are proposals to be fitted to the existing art, not claims about it:**

| Ledger model | Emotional function | Telegraph proposal (fitted at T3 to existing art) |
|---|---|---|
| **hound** | grief that lunges; wants contact | wide low lean = **denied family — step out**; ≥ 250 ms |
| **enemy_censer_moth** | grief that circles, will not land | coil + flash → **orb, deflectable** |
| **boss_mourning_bell** | denial that rings for the dead | sweep (denied), lift (counter), thrust (clashable power-2), punish jab — the four-strike grammar at slice values |

**Existing-art shape notes (per Main; telegraphs adapt to these, never contradict them):** the
boss is a **ribcage-bell with bell-fists** — **no halo**; the hound has **4 normal legs**; the
moth has **spread wings**. Hairline-crack stage cues that SYS-14 pins to the halo are re-mapped
as a proposal to the **chest-bell: potential weak point = the crack spreading across the
ribcage-bell** — explicitly a proposal, subject to the SYS-14 gate chain, not a contract change.

**Originality rule (binding):** emotional function → silhouette → telegraph; the hook is shape
and meaning, never a copied Castlevania frame. No traced/derived-from-Shanoa pose anywhere.

**Spatial beats (relative tiles; absolute scale pending T2 measurement):**

- **R1 — Waking Reliquary (intro).** ~24×11, flat. Walk right; one static chime-organ shard
  (not an enemy) teaches the attack; leads into R2, then the R3 pickup approach.
- **R2 — Hollow Corridor (enemy lesson).** ~30×11. One hound alone (step-out read); then
  hound + moth pair (deflect under closing pressure).
- **R3 — Bone Cache + relic pickup.** ~12×9. Shrine; **proposed wall-climb relic pickup here**,
  before any mandatory ascent (grant-then-need ordering).
- **R4 — Relic Shaft (climb test).** ~10×26 vertical. The ascent is the relic's first test using
  CLIMB-verified kinematics; top opens the route: boss door **SEALED → OPEN** via existing state
  only **if verified** (T2.0's output decides the mechanism; else re-plan this beat).
- **R5 — Return loop.** Down R4, re-cross R2: **one changed sentence** — moth repopulation only
  (1 changed : rest unchanged; bookend; no ambush in the first re-entered room).
- **R6 — Mourningbell Arena (climax).** Boss-door grammar (exhale arc). Drop-in basin feel; the
  lie: bar stalls at 1/3; 3 unanswered sweeps crack the **chest-bell**; then the fall is
  reachable; scripted goodbye beat (bell drops, she looks, she goes); endpoint at the east
  shrine. **No extended boss script or extra phases without user approval.**

**Non-goals for the slice:** no miniboss grammar, no dual-reality flip, no epoch mutation
machinery, no save expansion, no shop, no music decisions (B06 open). **NOT a non-goal: hero
replacement.** A distributable demo requires the full legal hero: finish the original hero
animation (cape fix) → human art approval → wire under B03's pattern → artifact audit, with
zero inspection/reuse of banned files. Until the banned legacy art is out of the runtime, this
is **not** a publishable demo; it is an internal slice.

## 2. Cross-cutting requirements

- **Art quality gates (per bead, before wiring):** silhouette reads at 32 px and grayscale;
  palette per user direction (black ceramic / ivory bone / cyan neural glow), value-first;
  telegraph = color-flash + shape lean, never opacity pulses; poses original per §1's rule;
  feet anchor documented; renders pass the same gates as concept.
- **Android + desktop, offline, fair controls:** offline always; touch uses the existing movable
  layout — **device re-check required** (B07 wording), no desktop-only precision.
- **Player verdict:** not done until the user plays and records the verdict in VERDICTS.md
  (B02 format). Player words outrank documents.
- **Completion bar:** Done = check passed AND nothing queued; waiting-on-user is never Done.

## 3. Sequenced POGR tasks (one worker each; stop after 2 failures; ≤120-word reports; no commits)

- **T1 — bead spec (design only).** DeepSeek `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017#low`. Inputs: §1, enemy-ai-telegraphs.md, grief-boss-framework.md TR-GBF-007.
  Output: `DEMO-BEADS.md` (strike rows, hp, cadence, shape families, slice values). Check: every
  telegraph ≥ 250 ms; sweep denied-family; no damage field in strike rows. Stop on SYS-13
  contradiction ×2.
- **T2 — room plan + controller-gating verification.** Same DeepSeek worker. Inputs: §1,
  proto-room-language.md, room-world-structure.md. **T2.0 first:** verify how the actual
  controller handles a relic pickup gating movement (state, flag, wiring) and whether boss-door
  SEALED→OPEN can use existing verified state; record evidence. Output: `DEMO-ROOMS.md` plus the
  gating verdict. Check: exactly one changed room in the loop; anchors named. Stop if gating
  cannot be shown with existing state.
- **T3 — asset render brief (existing assets first; NO regeneration by default).** GLM
  `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash#low`. **First action:** download the
   already-paid ledger assets (`hound`, `enemy_censer_moth`, `boss_mourning_bell` and available
   animation files) from the bank, inspect and render previews — free
  downloads/local Blender work, no price stalls. **No future paid generation without fresh user
  approval AND a known price.** Hero T3 gate is **separate from the enemy bank** (hero renders
  only from own source, its own approval). Never open banned files to inspect or reuse.
- **T4 — human art approval gates (user):** enemies/bank, then hero separately. Wiring only
  after both; hero wiring under B03's verified pattern + artifact audit.
- **T5 — implementation stories** after T4; checks: re-run SMOKE + CLIMB + screenshots
  (B03's pattern) against the changed build.
- **T6 — playtest verdict** (user plays; B02 format + slice questions).

**Concluding budget expectation (explicit):** this session's achievable output is **banked assets
(from already-paid jobs), the authored blueprint, and the re-verified baseline**. The whole
10–15-minute playable vertical slice is **NOT promised within Sol $4.50**. API cost is unknown;
the user subsequently reported about **10 credits and four more days of access**. Generation is
stopped; preserve those credits for targeted fixes, not more speculative assets.
A follow-up Cloudflare worker session can finish the slice incrementally under fresh approvals.
