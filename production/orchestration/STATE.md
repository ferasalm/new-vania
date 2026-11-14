# Orchestration State — the single live state/log

> **Updated**: 2026-11-14 (setup chat)
> **Main**: `e8b194d` — SYS-11 Seam Borders squash-merged (PR #43)
> **Mode**: parallel GDD/pre-production lanes; nested topology; WIP-limited.
> **Source of truth**: `manifest.yaml`. **Paste source**: `prompts/NEXT.md`.
> **Operating manual**: `README.md`.

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
| ART-BIBLE | `docs/art-bible` | `../new-vania-art-bible` | AUTHORING | art-director + creative-director | `prompts/lanes/ART-BIBLE.md` v1.0.0 |
| SYS-03 | `docs/sys03-save-serialization` | `../new-vania-sys03-save-serialization` | AUTHORING | lead-programmer + systems-designer | `prompts/lanes/SYS-03.md` v1.0.0 |
| SYS-04 | `docs/sys04-audio-core` | `../new-vania-sys04-audio-core` | AUTHORING | sound-designer + audio-director | `prompts/lanes/SYS-04.md` v1.0.0 |

The hashes are in `manifest.yaml` (the lane prompts' headers must match). The
lane runners write their reports to `production/session-state/lane-<ID>-report.md`
inside their own worktree.

## 3. Review queue (WIP ledger)

- **Three-seat review**: 0 of 2 slots in use (the first three lanes are still
  authoring). Next review slot: the first lane to reach CD GATE.
- **CodeRabbit**: 0 of 1 in flight.
- **Shared-file writer**: **SYNC-LANE active** — SYS-03's request is queued
  (`review-queue.md` §5, order 1, IN PROGRESS).
- **Authored-queued**: 0 of 3.

## 4. Shared-file lock

`shared_file_lock: SYNC-LANE` — acquired **2026-11-14** by the sync lane for the
**SYS-03 Save & Serialization** request (`lane-SYS-03-report.md` §10). The two
shared files (`design/registry/entities.yaml`, `design/gdd/systems-index.md`) are
write-locked to the sync lane until the sync PR merges; the lock is released only
after the merge, in a separate release PR.

## 5. Blockers

None hard. Soft: the three active lanes are at AUTHORING; the first review slot
is open.

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
| 2026-11-14 | SYS-11 Seam Borders | `e8b194d` | #43 | verified this chat; lane state preserved |
| 2026-11-14 | SYS-10 World Mutation & Epochs | `5b2a1f9` | #42 | batch co-review pilot |
| 2026-11-14 | SYS-09 Dual-Reality State & Rendering | `778b35d` | #41 | APPROVED gated on S1-007 probe |
| 2026-11-14 | IP-19 MVP-Definition amendment | — | — | the pin flip |
| 2026-11-13 | SYS-13 Enemy AI & Telegraphs | — | — | APPROVED |

## 9. Next actions

1. **The user pastes `prompts/NEXT.md`** in a fresh fast-run chat. It is the
   orchestrator loop; it reads this file + the manifest and launches the next
   lane(s).
2. **ART-BIBLE lane** — resolve OQ-1 (the purple) as the first item; then the
   palette/grief pins; then the 9 sections; then the asset-spec handoff.
3. **SYS-03 lane** — author the save GDD; the real-file round-trip twin is the
   authoring gate.
4. **SYS-04 lane** — author the audio GDD; consume E1–E7 verbatim; pin the
   no-duck law.
5. **When a review slot frees** — start SYS-15 or SYS-28 (the next queued MVP
   GDDs). Do not start SYS-16/SYS-17 until SYS-07-REWORK lands.
6. **Batch the user decisions** — D-ORCH-01/02 (art bible) and D-ORCH-03
   (SYS-07 rework). Do not interrupt for soft blockers.

## 10. Handoff — what is running, queued, and decided

**Running**: ART-BIBLE, SYS-03, SYS-04 (authoring; each in its own worktree).
**Queued**: SYS-15, SYS-28, SYS-14, SYS-05, SYS-24, SYS-12, SYS-20, SYS-25,
SYS-07-REWORK; SYS-16/SYS-17 blocked on SYS-07-REWORK.
**Support**: ADR-DRAFT (standby, parallel), QA-PLAN (standby), SYNC-LANE
(standby, single writer).
**User must decide**: D-ORCH-01 (the purple / SYS-02 line 36), D-ORCH-02 (the
palette/grief pins), D-ORCH-03 (the SYS-07 rework package). The art-bible
direction approval is the one-click action that unblocks the most.
**Next orchestrator chat**: paste `NEXT.md`; read this file + `manifest.yaml`;
do not author; launch the next lane runner(s) within the WIP limits; update this
file at every lane boundary; batch decisions; stop only on a hard blocker.
