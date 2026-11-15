# Orchestration State — the single live state/log

> **Updated**: 2026-11-15 (orchestrator-launch chat)
> **Main**: `4c0a05f` — launch record SYS-15/SYS-28 (PR #56)
> **Mode**: parallel GDD/pre-production lanes; nested topology; WIP-limited.
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
| ART-BIBLE | `docs/art-bible` | `../new-vania-art-bible` | AUTHORING (GLM rerun complete `bda8d96`; D-ORCH-01/02 open) | art-director + creative-director | `prompts/lanes/ART-BIBLE.md` v1.0.0 |
| SYS-03 | `docs/sys03-save-serialization` | `../new-vania-sys03-save-serialization` | **MERGED** `66ae957` (PR #45); twin 34/34 | lead-programmer + systems-designer | `prompts/lanes/SYS-03.md` v1.0.0 |
| SYS-04 | `docs/sys04-audio-core` | `../new-vania-sys04-audio-core` | **MERGED** `ba07158` (PR #46); header still "In Review" (countersign pending) | sound-designer + audio-director | `prompts/lanes/SYS-04.md` v1.0.0 |
| SYS-15 | `docs/sys15-cache-stations-death` | `../new-vania-sys15-cache-stations-death` | **PR #59 open** — gates complete (CD APPROVED · seats 1+3+2 repaired · spot-check PASS · micro-check PASS); CodeRabbit pending | game-designer + systems-designer | `prompts/lanes/SYS-15.md` v1.0.0 |
| SYS-28 | `docs/sys28-narrative-presentation` | `../new-vania-sys28-narrative-presentation` | **PR #58 open** — gates complete (CD APPROVED · creative APPROVED · seats 3+1 repaired · spot-check PASS · micro-check PASS); CodeRabbit confirm re-running | narrative-director + writer | `prompts/lanes/SYS-28.md` v1.0.0 |

The hashes are in `manifest.yaml` (the lane prompts' headers must match). The
lane runners write their reports to `production/session-state/lane-<ID>-report.md`
inside their own worktree.

## 3. Review queue (WIP ledger)

- **Three-seat review**: 0 of 2 slots in use (both SYS lanes' gates are closed;
  ART-BIBLE is parked on D-ORCH-01/02).
- **CodeRabbit**: both lane passes ran concurrently (a serial-rule deviation by
  the autonomous runners — recorded): PR #59 triage in flight (8 threads,
  resumed runner) and PR #58 confirm re-running on the fix head (5 fixed + 1
  rebutted). NEW passes (the sync PRs) queue behind recorded dispositions.
- **Shared-file writer**: **SYS-15 sync in flight** — the lock is held (§4); the
  sync PR is open on `chore/sync-sys15` (base `Main`, from `4419a3b`) and the
  orchestrator merges after verifying the head. TWO requests were queued (§5 of
  `review-queue.md`): SYS-15 (order 1, in flight) and SYS-28 (order 2, waits
  serially — it starts only after the SYS-15 sync merges and the lock releases).
- **Authored-queued**: 0 of 3.

## 4. Shared-file lock

`shared_file_lock: SYNC-LANE` — **acquired 2026-11-15** for the serial queue's
order 1 (**SYS-15 Cache Stations & Death-as-Story**). Branch `chore/sync-sys15`,
cut from `origin/Main` at `4419a3b`. The lock is held until the SYS-15 sync PR
merges (order 2, SYS-28, follows serially); a separate release PR clears it
after the merge (the #49 pattern). **Prior release 2026-11-14**: both queued
syncs landed — SYS-03 at `50a9a93` (PR #47) and SYS-04 at `dd33658` (PR #48); the
two shared files (`design/registry/entities.yaml`,
`design/gdd/systems-index.md`) were free from that release until this
acquisition.

## 5. Blockers

None hard. Soft: SYS-15 and SYS-28 are AUTHORING (runners in flight on GLM);
ART-BIBLE is parked on D-ORCH-01/02; the first review slot is open.

## 6. Decisions (batched — see `decisions.md`)

- **D-ORCH-01** — SYS-11 OQ-1: the purple bridge's art-bible ratification vs the
  SYS-02 line-36 amendment. Owner: art-director + lead-programmer. The ART-BIBLE
  lane prepares the package; the user decides. **Blocks the art bible's first
  item, not the grey default.**
- **D-ORCH-02** — SYS-11 OQ-4: the `PROV_LIM_*` L gaps + the grief C/L/hue pins.
  Owner: art-director. The ART-BIBLE lane prepares the values; the user approves
  the direction.
- **D-ORCH-03** — SYS-07-REWORK: the IP-17 baseline contract revision. Owner:
  systems-designer + lead-programmer. The lane prepares the package; the user
  approves before any edit to the frozen SYS-07 GDD.

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
| 2026-11-15 | Launch record SYS-15/SYS-28 | `4c0a05f` | #56 | verified this chat; both lanes AUTHORING, runners on GLM |
| 2026-11-15 | Operator card + retry/fallback policy | `83989de` | #54 | verified this chat; OPERATOR.md + prompts v2.0.6 |
| 2026-11-15 | Tooling (modules, DCP, Superpowers, 350k policy) | `b99ed48` | #51 | verified this chat; guide + policy landed |
| 2026-11-14 | SYS-11 Seam Borders | `e8b194d` | #43 | verified this chat; lane state preserved |
| 2026-11-14 | SYS-10 World Mutation & Epochs | `5b2a1f9` | #42 | batch co-review pilot |
| 2026-11-14 | SYS-09 Dual-Reality State & Rendering | `778b35d` | #41 | APPROVED gated on S1-007 probe |
| 2026-11-14 | IP-19 MVP-Definition amendment | — | — | the pin flip |
| 2026-11-13 | SYS-13 Enemy AI & Telegraphs | — | — | APPROVED |

## 9. Next actions

1. **SYS-15 is at PR #59** — gates complete (CD APPROVED · three-seat 1+3+2
   repaired · spot-check PASS · micro-check PASS; §3.6 in-session fallback
   recorded). CodeRabbit posted (6m48s, 8 threads): the triage is in flight
   (resumed runner session `ses_e2318d2a8ffe1Ie7DIw934S1eg`). When the triage
   is clean AND the sync has landed: verify the head and squash-merge #59.
2. **SYS-28 is at PR #58** — gates complete (CD APPROVED · creative APPROVED ·
   technical 3 repaired · QA 1 repaired · spot-check PASS 6/6 · micro-check
   PASS; §3.6 fallback recorded, DS re-pass is a batched decision). CodeRabbit:
   6 threads (5 fixed + 1 rebutted); the confirm pass re-runs on the fix head —
   wait for it green. When the sync has landed: verify the head and
   squash-merge #58.
3. **Launch the sync lane** — both requests are queued in `review-queue.md` §5
   (SYS-15 order 1, SYS-28 order 2); one branch + PR per request, serial.
4. **ART-BIBLE lane** — D-ORCH-01 (the purple) and D-ORCH-02 (palette/grief pins)
   await the user; the lane resumes when they are decided.
5. **SYS-04 header** — the audio-director countersign; then flip the GDD header
   `In Review` → `APPROVED` (or downgrade the index row). A user decision.
6. **Keep SYS-16/SYS-17 BLOCKED** on SYS-07-REWORK (D-ORCH-03). Do not launch.
7. **Batch the user decisions** — D-ORCH-01/02 and D-ORCH-03 (see
   `decisions.md`). Do not interrupt for soft blockers.
8. At any lane boundary: refresh `NEXT.md`
   (`node tools/orchestration/render-prompts.mjs --next`).

## 10. Handoff — what is running, queued, and decided

**Running**: SYS-15 (PR #59, CodeRabbit triage) + SYS-28 (PR #58, CodeRabbit
confirm) + the sync lane (launching); ART-BIBLE parked; D-ORCH-01/02 pending.
**Landed**: SYS-03 `66ae957` (PR #45), SYS-04 `ba07158` (PR #46).
**Queued**: SYS-14, SYS-05, SYS-24, SYS-12, SYS-20, SYS-25, SYS-07-REWORK;
SYS-16/SYS-17 blocked on SYS-07-REWORK.
**Support**: ADR-DRAFT (standby, parallel), QA-PLAN (standby), SYNC-LANE
(standby, single writer).
**User must decide**: D-ORCH-01 (the purple / SYS-02 line 36), D-ORCH-02 (the
palette/grief pins), D-ORCH-03 (the SYS-07 rework package). The art-bible
direction approval is the one-click action that unblocks the most.
**Next orchestrator chat**: paste `NEXT.md` (v2.0.6, `6106fa2cd614`); read this
file + `manifest.yaml` + the lane reports; do not author; process the
SYS-15/SYS-28 results (sync → merge → receipts), keep launching within the WIP
limits; update this file at every lane boundary; batch decisions; stop only on a
hard blocker or the 350k hard trigger.

## 11. Sync receipt — SYS-03 Save & Serialization (in flight)

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

## 12. Sync receipt — SYS-04 Audio Core (in flight)

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
