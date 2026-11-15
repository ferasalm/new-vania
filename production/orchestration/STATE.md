# Orchestration State — the single live state/log

> **Updated**: 2026-11-16 (the era-closing receipt)
> **Main**: `5026612` — `feat(proto): the sandbox suite v2 - real art, one button, Arnetria's stored lie (#93)` (at this receipt's branch point)
> **Mode**: **the prototype era (D-ORCH-15)** — the GDD queue is PAUSED until the playtest verdicts.
> **Source of truth**: `manifest.yaml`. **Paste source**: `prompts/NEXT.md`.
> **Operating manual**: `README.md`. **Tooling**: `TOOLING.md`.
> **Context budget**: `CONTEXT-POLICY.md` (soft 250k / hard 350k).

## 1. Landing receipt — SYS-11 Seam Borders (verified 2026-11-14)

- **Main**: `e8b194d` — `docs(sys11): the Seam Borders GDD lands (SYS-11) (#43)`.
- **Ancestors**: `5b2a1f9` (SYS-10) and `778b35d` (SYS-09) are ancestors.
- **PR #43**: **MERGED**; remote branch deleted. Do not re-merge; do not run the
  admin fallback for it.
- **Artifacts verified on `origin/Main`**:
  - `design/gdd/seam-borders.md` — present (APPROVED; 12 TR-SMB / 7 F-SMB /
    7 V-SMB / 32 ACs / 7 OQs).
  - `design/registry/entities.yaml` — `seam_border_contract` and
    `seam_admission_test` present, `status: active`, source
    `design/gdd/seam-borders.md`.
  - `design/gdd/systems-index.md` — SYS-11 row APPROVED; design order #10
    marked; the material-only correction present.
- **Review trail**: CD-GDD-ALIGN CONCERNS → REVISED; three-seat review NEEDS
  REVISION (3+8+8) → all valid blockers repaired; qa-lead spot-check #1 FAIL →
  repaired; #2 FAIL → repaired; final micro-check PASS; 16 threads (10
  single-pass + 5 confirm + 1 final) all resolved; CodeRabbit passed in 4m44s;
  all CI green.
- **Preserved lane state**: `landings/2026-11-14-sys11-lane-state.md` (verbatim
  copy of the worktree's `production/session-state/active.md`).
- **Local worktree**: `new-vania-sys11-seam-borders` still on the merged branch;
  preserved then removable (`git worktree remove`; `git branch -D
  docs/sys11-seam-borders`). The SYS-10 worktree is also merged; leave it alone
  unless housekeeping is requested.

## 2. Active lanes

| ID | Branch | Worktree | Phase | Owner | Prompt |
|---|---|---|---|---|---|
| SYS-16 | `docs/sys16-progression` | `../new-vania-sys16-progression` | **MERGED `6db8c38` (PR #81)**; sync `fac409f` (#84); D-ORCH-13 recorded | game-designer + systems-designer | `prompts/lanes/SYS-16.md` v1.0.0 |
| SYS-14 | `docs/sys14-grief-boss-framework` | `../new-vania-sys14-grief-boss-framework` | **MERGED `016bbbe` (PR #82)**; sync `27aa989` (#85) | game-designer + narrative-director | `prompts/lanes/SYS-14.md` v1.0.0 |
| SYS-05 | `docs/sys05-game-flow-session` | `../new-vania-sys05-game-flow-session` | **MERGED `2164181` (PR #87)**; sync `9365b56` (#92) | lead-programmer + game-designer | `prompts/lanes/SYS-05.md` v1.0.0 |
| SYS-24 | `docs/sys24-hud` | `../new-vania-sys24-hud` | **MERGED `40aaf78` (PR #86)**; sync `bdc8380` (#89) | ui-programmer + ux-designer | `prompts/lanes/SYS-24.md` v1.0.0 |
| ADR-DRAFT | `docs/adr-draft` | `../new-vania-adr-draft` | **Pass 2 MERGED `81d836c` (PR #90)**; ADR-0004 → **ACCEPTED (D-ORCH-23)**; ADR-0002/0003 → **ACCEPTED (D-ORCH-06)**; next pass: **ADR-0005** (the tick director) | lead-programmer + technical-director | `prompts/lanes/ADR-DRAFT.md` v1.0.0 |
| PROTO-SANDBOX | `feat/proto-sandbox-suite` | `../new-vania-proto-sandbox-suite` | **v2 MERGED `5026612` (PR #93)** — awaits the user's playtest; the SFX package `2bff2df` (#95), the Aseprite canonical pass `a6697cd` (#96), and the room-language spec `8d5a7cb` (#94) stand ready for v3 | prototyper + technical-artist + sound-designer + level-designer | — |

The hashes are in `manifest.yaml` (the lane prompts' headers must match). The
lane runners write their reports to `production/session-state/lane-<ID>-report.md`
inside their own worktree.

**The GDD queue is PAUSED (D-ORCH-15, the hybrid-prototyping pivot)**: the queued
lanes (SYS-17, SYS-12, SYS-20, SYS-25 + the ADR-0005 pass) resume on the user's
playtest verdicts. The prototype track is this era's primary lane.

## 3. Review queue (WIP ledger)

- **Three-seat review**: 0 of 2 slots in use — the GDD queue is paused
  (D-ORCH-15).
- **CodeRabbit**: 0 of 1 in flight — the prototype-era PRs (#93–#96) are all
  triaged and merged.
- **Shared-file writer**: idle; the lock is free (see §4).
- **Authored-queued**: 0 of 3.

## 4. Shared-file lock

`shared_file_lock: none` — **released 2026-11-16 by this receipt**: the SYS-05
sync — the last queued request — landed as **PR #92, squash-merged `9365b56`**
(registry 122 → 130 entries; the index's 17 corrections), and its GDD followed
per review-queue §7 rule 4 as **PR #87, `2164181`**. Both shared files
(`design/registry/entities.yaml` and `design/gdd/systems-index.md`) are free.
The next lane to reach `SYNC` queues its request in `review-queue.md` §5 and
re-acquires the lock here before any edit.

**Landed receipt 2026-11-15 (order 1, the SYS-16 sync)** — **PR #84**
(`chore/sync-sys16` → `Main`), squash-merged as **`fac409f`**:
`fa91299` (the lock) + `e71183a` (the sync) + `7590599` (the CodeRabbit batch).
Registry **88 → 113** entries (+18 constants, +5 published contracts, +2
`kind: formula`; `damage_ladder_mvp`'s note revised, value unchanged). Index: the
SYS-16 APPROVED row, design order 23, the dependency bullet, 9 row corrections,
the six riders recorded. Validation: YAML parses · no duplicate names · no
missing `source`/`referenced_by` path (`design/gdd/progression.md` was the one
pending path — it landed with PR #81 at `6db8c38`, after the sync by
review-queue §7 rule 4) · the counts reproduce · no entry deleted. CodeRabbit:
**5 threads, 5 applied, 0 rebutted, 0 deferred, all resolved**. Its lock release
rides the transfer above.

**Receipt (landed 2026-11-15)** — **PR #85** (`chore/sync-sys14` → `Main`),
squash-merged as **`27aa989`**:
`fedde76` (the lock transfer) + `b4862a8` (the sync) + `c40a8d1` (the CodeRabbit
batch). Registry **113 → 119** entries (+5 published contracts, +1 `contract`;
`boss_hp_pool` 60; the request's `boss_kill_award` **folded onto `xp_boss`** —
one fact, one entry). Index: the SYS-14 APPROVED row, design order 14, the
dependency cell + bullet (the stale **300 HP → 60**, the D-ORCH-03 number), the
6 neighbor notes, the A12 rider recorded. Validation: YAML parses · no duplicate
names · no missing `source`/`referenced_by` path (`design/gdd/grief-boss-framework.md`
is the one pending path — it lands with **PR #82**, which merges **after** this
sync by review-queue §7 rule 4) · the counts reproduce (24 + 2 + 4 + 0 = 30) ·
no entry deleted. CodeRabbit: **4 threads, 3 applied, 1 rebutted, 0 deferred,
all resolved** (the `arena_hold` two-term predicate; the landed SYS-16 row
removed from the active queue; the release decoupled from PR #82; **rebutted**:
the tracker's status cell stays the house `**APPROVED (date — trail)**` form —
14 of 31 rows carry it and no consumer parses the cell). **The lock stayed
`SYNC-LANE` at that merge; its release to `none` rides the SYS-24 sync's receipt.**
Landing order: **that sync first, then PR #82** (both landed).

**Receipt (landed 2026-11-16)** — **PR #89** (`chore/sync-sys24` → `Main`),
squash-merged as **`bdc8380`**:
the lock transfer + the sync + the CodeRabbit batch. Registry
**119 → 122** entries (+3 published contracts: `hud_caps_contract`,
`settings_namespace`, `hud_registration_contract`; `camera_publication_contract`'s
`consumed_by` gains the caps' rendered-center clause; 8 `referenced_by` appends;
the envelope `2.45/6.55 → 2.55/6.85`, eight-system). Index: the SYS-24 APPROVED
row, the dependency bullet, the SYS-15/16/03/32 row notes; design order 18
unchanged. Validation: YAML parses · no duplicate names (122) · no missing
`source`/`referenced_by` path (`design/gdd/hud.md` is the one pending path — it
lands with **PR #86**, which merges **after** this sync by review-queue §7 rule 4)
· the counts reproduce (25 TR / 7 F / 8 V / 37 ACs = 30 smoke + 5 device + 2 lock
+ 0 VS) · no entry deleted. CodeRabbit: **2 threads, 2 applied, 0 rebutted, 0
deferred, all resolved** (the SYS-24 dependency list gains SYS-16 + SYS-04 — the
GDD's own dependency table marks SYS-16 **hard** and SYS-04 soft; then SYS-06's
read-only boot-constant edge, which the enumeration row already carried — the
enumeration and the bullet are now the same set). **The lock stayed
`SYNC-LANE` at that merge; the release to `none` rides the SYS-05 sync's
receipt.** Landing order: **that sync first, then PR #86** (both landed).

**Prior release 2026-11-15 (the riders mini sync)**: PR #80 at `fe38c4c` —
`spitter_orb_damage` 8 → 2, `enemy_strike_contract`'s payload `power_band`
1 → 2, the index's SYS-07 Suture 25 → 5.

**Prior release 2026-11-15 (SYS-07-REWORK sync)**: landed — PR #76 merged at
`6dd4651`; 4 CodeRabbit threads, all applied + resolved.

**Prior release 2026-11-15**: after the ART-BIBLE sync landed — PR #72 merged at
`bc8c6be` (head `8eb621d`; 0 CodeRabbit threads). Registry notes updated on
`dual_reality_palette_tables` (the D-ORCH-02 pins) and `seam_admission_test`
(D-ORCH-01: the purple declined); the index gained the SYS-11 qualification, the
SYS-02 line-36 note (naming D-ORCH-01 + `5cc1377`), the OQ rider notes and the
OQ-M1 rider list.

**Prior release 2026-11-15 (SYS-28)**: PR #69 merged at `a5a1f81` (head
`eb85da4`; 4 CodeRabbit threads, all applied + resolved). Registry 77 → 80
entries (`narrative_beat_contract`, `beat_variant_selector`,
`micro_copy_budget`); the index gained the SYS-28 APPROVED row, design order 21
and the 10 request diffs.

**Prior release 2026-11-15**: after the SYS-15 sync landed — PR #63 merged at
`1e9e524` (head `5f67ee0`; 1 CodeRabbit thread applied — the
`designation_counter` wording narrowed to the GDD's own law; 1 rebuttal — the
fifth-save-event suggestion closed by AC-CSD-19/OQ-SAV-4). Registry 70 → 77
entries; the index gained the SYS-15 bullet, the APPROVED MVP row and design
order 12. **Prior release 2026-11-14**: SYS-03 at `50a9a93` (PR #47) and
SYS-04 at `dd33658` (PR #48).

## 5. Blockers

None. The GDD queue is PAUSED by user decision (D-ORCH-15) until the v2 playtest
verdicts; the prototype era carries no blockers — v2 (`5026612`) is ready for
the user's cold playtest.

## 6. Decisions (batched — see `decisions.md`)

- **D-ORCH-01/02/05** — RESOLVED and executed (the SYS-02 line-36 amendment, the
  palette pins, the SYS-04 countersign).
- **D-ORCH-03** — RESOLVED: option A applied (PR #75/#76) + the riders (#78/#80).
- **D-ORCH-06** — RESOLVED: ADR-0002/0003 ACCEPTED; the flips execute in this
  receipt.
- **D-ORCH-07/08/09** — RESOLVED: CR-SAV-01/CR-AUD-03/CR-AUD-04 approved as
  riders to SYS-03/SYS-04's next doc touches.
- **D-ORCH-10/11/12** — RESOLVED: (i) re-author; the deflect accepted; keep 500.
- **D-ORCH-13/14** — decided autonomously under the away-directive (the ruler
  reading; the SYS-14 brief A); revisit-on-return noted.
- **D-ORCH-15..22** — RESOLVED (2026-11-16): the hybrid-prototyping pivot; the
  SYS-05/24 briefs; one-button combat (D-ORCH-18 — the frozen SYS-01/SYS-08
  contract revision executes at the resume); **Arnetria the Mirror Queen**
  (D-ORCH-19 — the stored-damage mirror fight replaces SYS-14's crack route);
  no fall damage (D-ORCH-20); the longer multi-part scope + the Twine tree
  (D-ORCH-21); the asset authorization (D-ORCH-22 — amended: the Ansimuz
  recall, **all assets usable, no exception**).
- **D-ORCH-23** — RESOLVED: the TD-ADR verdict on ADR-0004 — ACCEPT WITH
  CONDITIONS; C1–C3 applied and the status flipped in this receipt.
- **Open for the user**: the O-HD-9 recommendation (resolution (i) — the body is
  session-only at MVP), the CR-HD-01/02 ratification nod, the license-text
  capture for the 7 user-recalled packs (at promotion time), and the playtest
  verdicts themselves.

## 7. SYS-11 OQ handoff (OQ-1..7)

| OQ | Item | Owner | When |
|---|---|---|---|
| OQ-1 | Purple bridge art-bible ratification + SYS-02 Player Fantasy line 36 conflict (ratify the purple, or amend the line + qualify the index row; the grey default ships either way) | art-director + lead-programmer | ART-BIBLE lane, first item |
| OQ-2 | The AC-DR-15 key-level vs pixel-level reading; SYS-09's owner countersigns; if pixel-level, the tint is false and the grey ships | SYS-09's owner + technical-artist | Before the first SYS-11 story |
| OQ-3 | The band's inclusion in SYS-09's PR-DR-05/AC-DR-15 capture + the admission harness (OKLCH conversion, desaturate/saturate stress) | technical-artist + SYS-09's owner + tools-programmer | Before the first SYS-11 story |
| OQ-4 | The ramp's L gaps (`gap_R ≥ 0.09`) and the grief tint's C/L/hue pin [330, 20]; if gaps < 0.09, the D-gap clause relaxes to ≥ 0.01 or the tint closes | art-director | ART-BIBLE lane |
| OQ-5 | The frame's side offset (`SEAM_SIDE_OFFSET` ∈ {−1, 0}) and the band step at playtest (`SEAM_BAND_STEP` stays {MID}) | game-designer + QA | Gate 2 |
| OQ-6 | The fixture set (the wing's fixtures are `[]` at MVP) and the south termination's visual note | level-designer + technical-artist | Next room-data / SYS-09 touch |
| OQ-7 | The fill's row sampling — SYS-09's TR-DR-003 keys per zone, not per row; the proposed rider | SYS-09's owner + technical-artist | Before the first SYS-11 story |

The ART-BIBLE lane prompt is seeded with OQ-1 and OQ-4. OQ-2/OQ-3/OQ-7 are
SYS-09-owner items, not art-bible items; they are recorded here so they do not
fall between lanes. OQ-5/OQ-6 are gate-2 / room-data items.

## 8. Last five landings

| Date | System | Main | PR | Notes |
|---|---|---|---|---|
| 2026-11-16 | Prototype v2 — real art, one button, Arnetria's stored lie | `5026612` | #93 | the user playtests; 71-check smoke ALL GREEN; CodeRabbit caught the 150 px mirror-height fight-breaker |
| 2026-11-16 | The Aseprite canonical pass (Pandora, Arnetria, the shards) | `a6697cd` | #96 | 184 files in `assets/processed/`; the `.aseprite` sources are the MVP art base; the 37k green-pinhole inpaint verified |
| 2026-11-16 | The prototype SFX package | `2bff2df` | #95 | 21 files, 17/17 events wired; the bus/gain map per ADR-0003; 5 CR threads all applied |
| 2026-11-16 | The room-language spec | `8d5a7cb` | #94 | the boss-door grammar, the mini-boss rules, the changed-place pattern; the SYS-11 OQ-6 fixtures |
| 2026-11-16 | The license verification sweep | `953edb2` | #91 | 35 rows, per-pack LICENSEs, CREDITS.md; the 7 user-recalled rows re-attributed in this receipt (D-ORCH-22) |
| 2026-11-16 | ADR-0004 Health & Damage (pass 2) | `81d836c` | #90 | landed Proposed; **ACCEPTED via D-ORCH-23 in this receipt** (C1–C3 applied) |
| 2026-11-16 | SYS-05 Game Flow & Session Structure | `2164181` | #87 | sync PR #92 `9365b56`; the nine-context machine; OQ-DR-1/OQ-SAV-7 ratified |
| 2026-11-16 | SYS-05 sync (registry 122→130) | `9365b56` | #92 | the last queued sync; the lock released in this receipt |
| 2026-11-16 | SYS-24 HUD | `40aaf78` | #86 | sync PR #89 `bdc8380`; OQ-CSD-2 answered; the envelope is eight systems |
| 2026-11-16 | SYS-24 sync (registry 119→122) | `bdc8380` | #89 | hud_caps/settings/registration contracts; the CR-1/CR-2 dependency fixes |
| 2026-11-15 | ADR-0002 + ADR-0003 (the ADR-DRAFT lane) | `b991714` | #79 | verified this chat; both `Proposed`; 29 CR threads resolved; the TD-ADR verdict batched (D-ORCH-06) |
| 2026-11-15 | The D-ORCH-03 riders mini sync | `fe38c4c` | #80 | verified this chat; the orb 8→2, `power_band` 1→2, the Suture 5; 0 threads |
| 2026-11-15 | The D-ORCH-03 riders (SYS-13 + four mechanical) | `b4ec55b` | #78 | verified this chat; the deflect-weight + stagger-floor questions recorded (D-ORCH-11/12) |
| 2026-11-15 | SYS-07 baseline rework (D-ORCH-03 applied) | `3fcedc6` | #75 | verified this chat; SYS-07 + SYS-08 revised; 24 CR threads all resolved; riders PR in flight |
| 2026-11-15 | SYS-07-REWORK sync | `6dd4651` | #76 | verified this chat; registry 81→88 (`damage_event` + the baseline constants); the orb HELD |
| 2026-11-15 | ART-BIBLE — the Art Bible lands | `ee08e63` | #67 | verified this chat; gates + sync (PR #72, `bc8c6be`); nested seats verified |
| 2026-11-15 | SYS-28 Narrative Presentation | `2ff3096` | #58 | verified this chat; GDD + sync (PR #69, `a5a1f81`); counts 13/3/6/15 |
| 2026-11-15 | SYS-15 Cache Stations & Death-as-Story | `24efd09` | #59 | verified this chat; GDD + sync (PR #63, `1e9e524`); counts 20/4/7/26 |
| 2026-11-15 | ART-BIBLE gates closed (PR #67; sync queued) | `4629bb8` | #68 | verified this chat; D-ORCH-01 executed (`5cc1377`), D-ORCH-02 pinned |
| 2026-11-15 | The decision batch (D-ORCH-01/02/05, D-ORCH-03 round 2) | `ce46fac` | #65 | verified this chat; D-ORCH-03 = revise again |
| 2026-11-15 | SYS-04 header countersign + flip | `01a9442` | #66 | verified this chat; D-ORCH-05 executed |
| 2026-11-15 | Launch record SYS-15/SYS-28 | `4c0a05f` | #56 | verified this chat; both lanes AUTHORING, runners on GLM |
| 2026-11-15 | Operator card + retry/fallback policy | `83989de` | #54 | verified this chat; OPERATOR.md + prompts v2.0.6 |
| 2026-11-15 | Tooling (modules, DCP, Superpowers, 350k policy) | `b99ed48` | #51 | verified this chat; guide + policy landed |
| 2026-11-14 | SYS-11 Seam Borders | `e8b194d` | #43 | verified this chat; lane state preserved |
| 2026-11-14 | SYS-10 World Mutation & Epochs | `5b2a1f9` | #42 | batch co-review pilot |
| 2026-11-14 | SYS-09 Dual-Reality State & Rendering | `778b35d` | #41 | APPROVED gated on S1-007 probe |
| 2026-11-14 | IP-19 MVP-Definition amendment | — | — | the pin flip |
| 2026-11-13 | SYS-13 Enemy AI & Telegraphs | — | — | APPROVED |

## 9. Next actions

1. **The user playtests prototype v2** — cmd/bash: `"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --path prototypes/sandbox`;
   PowerShell: `& "C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --path prototypes/sandbox`.
   Cold start. The verdicts feed v3: the canonical `.aseprite` sources
   (`assets/processed/`), the SFX package (`assets/audio/selected/` + WIRING.md),
   and the room-language spec wire in on the next prototype pass.
2. **The queued agents (spawn on the verdicts)**: analytics-engineer (telemetry
   before v3), performance-analyst (the sandbox vs the 2.55/6.85 envelope),
   accessibility-specialist + economy-designer (at the GDD resume), world-builder
   (the mirror-world change rules + the Twine structure), tools-programmer (the
   OKLCH harness + Twine tooling).
3. **On the GDD resume (the user's word)**: the queue (SYS-17, SYS-12, SYS-20,
   SYS-25), the **ADR-0005 lane** (the composition root / tick director —
   candidate #1, it gates the first SYS-07 integration story), the
   **D-ORCH-18/19/20 contract revisions** into the frozen GDDs (one-button
   combat, Arnetria's stored-damage fight, the fall-damage removal), the
   CR-SAV-01/CR-AUD-03/04 + O-HD-1..11 riders, and the TD-ADR story gates
   (probes #6/#4/#5 first, O-HD-12..17, `tr-registry.yaml` via
   `/architecture-review`).
4. At any lane boundary: refresh `NEXT.md`
   (`node tools/orchestration/render-prompts.mjs --next`).

## 10. Handoff — what is running, queued, and decided

**Running**: nothing — all streams landed (the last: prototype v2 `5026612`,
PR #93). **The user playtests next.**
**Landed this era**: SYS-16 `6db8c38` (#81) + sync `fac409f` (#84) · SYS-14
`016bbbe` (#82) + sync `27aa989` (#85) · SYS-24 `40aaf78` (#86) + sync
`bdc8380` (#89) · ADR pass 2 `81d836c` (#90) · the license sweep `953edb2`
(#91) · SYS-05 sync `9365b56` (#92) · SYS-05 `2164181` (#87) · prototype v2
`5026612` (#93) · the room language `8d5a7cb` (#94) · the SFX package
`2bff2df` (#95) · the Aseprite canonical pass `a6697cd` (#96).
**Decided**: D-ORCH-01..23 (see §6 + `decisions.md`); the GDD queue is PAUSED
(D-ORCH-15) until the playtest verdicts.
**Open for the user**: the O-HD-9 recommendation (resolution (i)); the
CR-HD-01/02 nod; the playtest verdicts themselves.
**Next orchestrator chat**: paste `NEXT.md`; read this file + `manifest.yaml` +
`production/session-state/active.md` (the handover); **the prototype loop is the
primary lane — do not launch GDD lanes until the user's verdicts**; batch the
open decisions; stop only on a hard blocker or the 350k hard trigger.

## 11. Sync receipt — SYS-03 Save & Serialization (landed 2026-11-14 — PR #47, `50a9a93`)

- **Lane**: SYS-03 Save & Serialization. **Request**: `lane-SYS-03-report.md` §10
  (2 `entities.yaml` entries + the `systems-index.md` row/design-order/bullet +
  the 10 bidirectional-consistency corrections).
- **Lock**: `shared_file_lock: SYNC-LANE` (held from `a8cb13f`; released only
  after the sync PR merges).
- **Branch / PR**: `chore/sync-shared-files` / **PR #47** (base `Main`, branched
  from `32940c8`).
- **Files**: `design/registry/entities.yaml` (+`save_contract`,
  `save_roundtrip_twin`), `design/gdd/systems-index.md` (SYS-03 row → APPROVED,
  design order #11, the Foundation bullet, the 10 corrections),
  `production/orchestration/{STATE,review-queue}.md`.
- **Validation**: YAML parse OK · duplicate-name scan OK (66 entries) · every
  `source`/`referenced_by` path exists · counts reproduce (26 TR-SAV / 4 F-SAV /
  9 V-SAV / 26 ACs = 22 GUT + 2 LINT + 2 DEVICE + 0 PLAYTEST; smoke 24) · design
  order unique · table integrity OK · 10/10 corrections present.
- **Two corrections to the request** (both toward the authoritative GDD, both
  re-verified by running the twin): the twin is **32/32 PASS** (the request's
  §10 says 29/29 — stale since the CodeRabbit batch added three checks) and the
  `post_flip` hash prefix is **05b1e48e** (the request says b3283603).
- **Landing hash**: **`50a9a93`** — `docs(sync): land the SYS-03 save contract + index row (#47)`,
  squash-merged 2026-11-14 with the head pinned at `07f9b27`. 3 CodeRabbit
  threads: 2 applied in `07f9b27` (SYS-24's dependency edges; the manifest lane
  status → `SYNC`), 1 rebutted (the parenthetical status cell is the file-wide
  convention — 10 of 10 approved rows; the exact-string `Approved` restyle is an
  adopt-migration item, not a single-row edit). All 6 checks green; 0 unresolved.

## 12. Sync receipt — SYS-04 Audio Core (landed 2026-11-14 — PR #48, `dd33658`)

- **Lane**: SYS-04 Audio Core. **Request**: `lane-SYS-04-report.md` "Sync
  request" (4 `entities.yaml` entries + the `flip_trigger_contract` append + the
  `systems-index.md` row/design-order/bullet/SYS-02 reciprocal).
- **Lock**: held (re-acquired at SYS-03's release; see §4).
- **Branch / PR**: `chore/sync-sys04` / the sync PR (base `Main`, branched from
  `50a9a93`).
- **Files**: `design/registry/entities.yaml` (+`audio_bus_contract`,
  `ambient_bed_contract`, `audio_edge_list`, `duck_request_contract`;
  `flip_trigger_contract` gains `audio-core.md` in `referenced_by` and a second
  dated `revised` note — the SYS-10 ratification is preserved),
  `design/gdd/systems-index.md` (SYS-04 row → APPROVED, design order #16, the
  Foundation bullet, the SYS-02 reciprocal, the enumeration Dependencies column).
- **Validation**: YAML parse OK · duplicates 0 (70 entries) · every
  source/referenced_by path exists · counts reproduce (39 TR-AUD / 7 F-AUD /
  7 V-AUD / 32 ACs = 26 smoke + 4 device + 2 MVP-lock + 0 VS; 14 knobs; 8 OQs) ·
  design order unique · table integrity OK · the SYS-03 rows/corrections
  unregressed.
- **One recorded condition**: the SYS-04 GDD header's `Status` line still reads
  `In Review` (the audio-director countersign pending — the review log's §D.6
  condition). The index row says APPROVED **and names the condition**; the lane
  flips the header at PR #46's merge.
- **Two mechanical fixes to the request's YAML**: `audio_bus_contract`'s
  `consumed_by` is quoted (its `knobs: MONO` colon-space is a YAML mapping
  error unquoted); the `flip_trigger_contract` `revised` note is appended, not
  overwritten (the registry's own rule — never lose the prior revision record).
- **Landing hash**: **`dd33658`** — `docs(sync): land the SYS-04 audio contracts + index row (#48)`,
  squash-merged 2026-11-14 with the head pinned at `6392f84` (**admin merge
  used once**: the required review was the only blocker — all 6 checks green,
  0 unresolved threads; recorded as a bypass). 3 CodeRabbit threads: 2 applied
  in `6392f84` (the bullet's "no dependencies" opening; the stale lane phases in
  STATE/review-queue), 1 rebutted (the `audio-core.md` path is absent until
  PR #46 lands — the protocol's sync-before-GDD order, the SYS-03 precedent).

## 13. Tooling landing — modules, plugins, context policy (2026-11-15)

- **Landed**: **`b99ed48`** — `chore(tooling): audit modules, install DCP +
  Superpowers, adopt the 350k policy (#51)`, squash-merged 2026-11-15 with the
  head pinned at `c5b902d`. All 6 checks green; CodeRabbit passed; 3 threads
  (2 initial + 1 confirm) all applied and resolved; **no admin merge needed**.
- **Modules audited, not reinstalled**: 22 installed @ 0.6.0 for OpenCode. The five
  non-Godot engine modules (`engine-unity`, `engine-unreal`, `engine-sfml3`,
  `engine-raylib`, `engine-bevy`) are installed but unused; **kept** (13 inert
  agent files, no MCP/hooks) with a one-click removal path in `TOOLING.md` §1.1.
  No removal decision has been made.
- **DCP** `@tarquinen/opencode-dcp` **3.2.0**, installed with
  `opencode plugin add @tarquinen/opencode-dcp@latest` → global
  `~/.config/opencode/opencode.json`. Project config `.opencode/dcp.jsonc`:
  `minContextLimit 250000`, `maxContextLimit 350000`. `/dcp` and
  `/dcp-compress [focus]` verified present; the context-limit nudge fires
  in-session.
- **Superpowers** `superpowers@git+https://github.com/obra/superpowers.git` at
  commit **`22f0b46`**, in project `opencode.json` → `plugins`. The git-backed
  Windows install worked; no npm fallback needed. 15 skills load via the native
  `skill` tool.
- **Combined load verified**: `opencode plugin list` shows 5 plugins (3 OCGS local
  + DCP 3.2.0 + Superpowers `22f0b46`); a standalone run logs all five loading.
- **Guide**: `TOOLING.md` — inventory, commands, when-to-use table, the
  OCGS↔Superpowers division of labour, model routing, a 10-minute walkthrough and
  three exercises.
- **Context policy**: `CONTEXT-POLICY.md` — soft 250k / hard 350k, three handoff
  modes, the measured harness thresholds (OpenCode auto-compaction at ~898,576
  tokens via `compaction.buffer: 150000`).
- **Prompts**: `orchestrator-loop.md` rewritten to v2.0.0 as the mode-agnostic
  handoff prompt; `prompts/handoff.md` added as the template; `NEXT.md`
  re-rendered (hash `555c18812b03`); `SYS-15.md` and `SYS-28.md` rendered
  (`85701ea84621`, `e2e9a0f20532`).

## 14. Operator card + retry/fallback landing (2026-11-15)

- **Landed**: **`83989de`** — `chore(orchestration): add the operator card and
  pin the fallback policy (#54)`, squash-merged 2026-11-15 with the head pinned
  at `ecc1df6`. 5 CI checks green on every round; 10 CodeRabbit threads across
  5 review rounds, all valid, all applied, all resolved; **no admin merge
  needed** (final `mergeStateStatus: CLEAN`).
- **`OPERATOR.md`**: the one-page TL;DR card for the human operator — the
  paste/approve/decide loop, the file map, the `ID: choice` pre-answer format,
  the unattended-run authorization block, WIP/context/model quick facts, and
  the three rules. Linked from the manual header and the file map.
- **Retry/fallback policy (user decision, recorded in `decisions.md`)**: up to
  **4 spawn attempts** on server-side errors (`ProviderModelNotFoundError`,
  `AiError: Capacity temporarily exceeded`, 5xx/rate limits). Then: **DS→GLM**
  is an authorized autonomous fallback; **GLM→DS never autonomously** — only an
  explicit user decision can authorize it (creativity is not to be
  compromised). Pinned in the routing rule (§3), the launch procedure (§5),
  and `TOOLING.md` §5.
- **Fallback mechanics (CodeRabbit-honed)**: a fallback first updates the
  lane's manifest `model`, re-renders + validates the lane prompt (the header
  embeds the model), lands `model` + `status` on `origin/Main` through the §6
  path (branch + PR, or the sync lane), keeps `AUTHORING` conditional on a
  successful spawn (a failed launch stays `PAUSED`), and defines the
  `PAUSED → QUEUED` relaunch with a clean lane worktree.
- **Prompts**: `NEXT.md` re-rendered at **v2.0.6** (`6106fa2cd614`); the
  manifest `next.version` bumped 2.0.1 → 2.0.6 through the review rounds.

## 15. Sync receipt — SYS-07-REWORK (landed 2026-11-15 — PR #76, `6dd4651`)

- **Lane**: SYS-07-REWORK (D-ORCH-03, the IP-17 low-stat baseline rework; baseline
  PR #75, head `270b9ad`). **Request**: the "Sync request" section of
  `../new-vania-sys07-baseline-rework/production/session-state/lane-SYS-07-REWORK-report.md`
  (+ the package's § 10, `design/reviews/sys07-baseline-rework-package.md`).
- **Lock**: `shared_file_lock: SYNC-LANE` (held from `2d0a821`; released only after
  this sync PR merges).
- **Branch / PR**: `chore/sync-sys07` / **PR #76** (base `Main`, branched from
  `ac6c623`; head `2d0a821` at open).
- **Files**: `design/registry/entities.yaml` (11 value/note updates + 7 new entries:
  `damage_event`, `player_max_hp`, `hp_per_point`, `training_data_l2..l5`,
  `damage_ladder_mvp`; 81 → 88), `design/gdd/systems-index.md` (the SYS-07
  bullet/row, design order 22, the SYS-16/17 unblock), `design/gdd/game-concept.md`
  (the 5th Gate-2 probe — the one GDD touch, routed by the lane's CD gate so the
  probe list stays single-sourced), `production/orchestration/{STATE,review-queue}.md`,
  `production/orchestration/manifest.yaml` (the lane row → `SYNC`).
- **Held**: `spitter_orb_damage` stays **8** until the coordinated SYS-13 rider lands
  (`enemy-ai-telegraphs.md`); the hold is in the entry's history, not a silent skip.
- **Validation**: YAML parse OK (entities + manifest) · duplicate-name scan OK
  (88 entries: 30 entities / 0 items / 6 formulas / 52 constants) · every
  `source`/`referenced_by` path exists · all 12 value/note checks + the 7 new entries
  reproduce the request · design-order numbers 1–25 unique · `git diff --stat` shows
  only the intended 6 files (+185/−47).
- **Landing hash**: pending (the orchestrator merges after verifying the head).
- **Head at verification**: `036ae9c` (3 commits: the sync, the two CodeRabbit
  batches) — **5/5 CI green at that revision**. The receipt commit that carries this
  line moves the head, so this is a snapshot, not a claim about the current head: the
  orchestrator re-verifies the head and its checks immediately before merging and binds
  the merge with `--match-head-commit`.
- **CodeRabbit**: 3 threads across 2 passes, **all resolved** — 3 applied
  (`d6eab95`: the `arc = ABILITY` dispatch stated in `damage_event` +
  `damage_ladder_mvp`, and the merge order corrected to sync-first per
  review-queue § 7 rule 4; `036ae9c`: SYS-17 keeps its own SYS-16 dependency — the
  sync removes only the SYS-07-REWORK blocker). 0 rebutted, 0 deferred.
- **Merge order**: the sync PR first, then PR #75 (review-queue § 7 rule 4).

## 16. The 2026-11-16 receipt — the era closes (D-ORCH-15..23)

- **This receipt lands**: the decisions ledger (D-ORCH-06..23) · the TD-ADR
  acceptance flips — ADR-0002/0003 per D-ORCH-06 and **ADR-0004 per D-ORCH-23
  with C1–C3 + the editorial batch applied** (the producer's door §4d, the heal
  admission/drain split §8b, the director-owned freeze assert; the §10 verdict
  record in the review log) · the `technical-preferences.md` rows · the
  license-ledger re-attribution (D-ORCH-22's amendment: the Ansimuz recall,
  all assets usable, no exception) · the manifest receipt sweep (the MERGED
  rows, the PAUSED queue notes, the ADR-DRAFT next pass) · this STATE rewrite ·
  the `NEXT.md` re-render (v2.0.7 — the orchestrator loop's §1 rewritten for
  the prototype era).
- **The GDD machine's in-flight tail is complete**: every lane that was running
  or queued for this era has landed or is PAUSED by user decision. The
  shared-file lock is free; the review queue is empty.
- **The prototype era is live**: v2 `5026612` awaits the user's cold playtest;
  the canonical art sources (`assets/processed/`), the SFX package
  (`assets/audio/selected/` + `WIRING.md`), and the room-language spec
  (`design/level/proto-room-language.md`) stand ready for v3.
- **The fresh session** starts by pasting `NEXT.md` and reading
  `production/session-state/active.md` (the handover).

