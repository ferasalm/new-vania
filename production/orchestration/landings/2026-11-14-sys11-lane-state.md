# Active Session State — SYS-11 Seam Borders lane

## Current task

**SYS-11 Seam Borders GDD authoring** (`design/gdd/seam-borders.md`), design order #10.
Branch `docs/sys11-seam-borders` from origin/Main `5b2a1f9`. Worktree:
`C:\Users\AUC\opencode-workspace\workspace\new-vania-sys11-seam-borders`.

## Progress

- [x] Step 0: worktree + branch + session move + `npm install` (hooks)
- [x] Kickoff copy written (`sys11-kickoff-prompt.md`)
- [x] Context read: concept, index, registry entries, SYS-02/09/10/32 contracts, ADR-0001 §3/§5/§15
- [x] Context summary + feasibility brief approved
- [x] Skeleton created
- [x] Sections A–E authored (Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases)
- [x] Sections F–K authored (Dependencies, Tuning Knobs, Visual/Audio, UI, ACs, OQs)
- [x] CD-GDD-ALIGN (full): CONCERNS → R1/R2 + advisories applied in-session
- [x] Fresh-seat review loop: 3 seats NEEDS REVISION (3+8+8) → all valid blockers repaired; qa-lead spot-check #1 FAIL → repaired; #2 FAIL → repaired; final micro-check PASS
- [x] Registry + index syncs (seam_border_contract, seam_admission_test; SYS-11 row APPROVED; material-only correction)
- [x] Commit/push, PR #43, CodeRabbit (single pass + 2 confirm passes, all threads resolved), **squash-merged as `e8b194d`**

## Landing state

**MERGED: PR #43 squash-merged as `e8b194d` on Main (2026-11-14).** The GDD is
APPROVED; the registry (`seam_border_contract`, `seam_admission_test`) and the
systems index (SYS-11 row APPROVED; the material-only correction; design order
#10 marked) are on Main. The remote branch is deleted.

Review trail: CD-GDD-ALIGN CONCERNS → REVISED; three-seat review NEEDS REVISION
(3+8+8) → all valid blockers repaired; qa-lead spot-check #1 FAIL → repaired;
#2 FAIL → repaired; final micro-check PASS. CodeRabbit: 10 single-pass threads +
4 confirm-pass + 5 confirm-pass + 1 predicate_version = all VALID, applied in
`9d26719`, `3a43ae4`, `407ed67`, `d1f59db`, resolved manually with dispositions
(PR comments #6882614807, #6882663143). All checks green.

**Handoff / next touches:** OQ-1 (the purple's art-bible ratification + SYS-02's
line-36 conflict) · OQ-2 (SYS-09's key/pixel countersign) · OQ-3 (the band's
PR-DR-05 capture + the admission harness) · OQ-4 (the ramp L gaps + grief C/L/hue
pins) · OQ-5 (the side offset/band step at playtest) · OQ-6 (the fixture set +
south termination) · OQ-7 (the fill's row sampling rider). The local worktree
`C:\Users\AUC\opencode-workspace\workspace\new-vania-sys11-seam-borders` remains
on the merged branch for the orchestrator's cleanup (the lane state lives here;
remove with `git worktree remove` after moving out).

## Key decisions in force

- Purple bridge = **gated proposal**: pure `PROV_LIM_*` grey ramp ships; purple only
  if SYS-09's TR-DR-012 admission test + art-bible ratification pass. No art bible
  exists yet → grey is the default; the purple stays an OQ.
- No MVP prompt/VFX/audio on any seam (SYS-02's pivot). No tell channel (SYS-10's
  delta namespace is tell-free for the wing/M4). SYS-11 issues zero camera commands
  and does not act on `active_hold` (SYS-32's row).
- Consumed verbatim: SYS-02's placement (wing `Rect2(1312,176,160,96)`, partition
  row, `reveal_cistern` framing zone); SYS-09's `PROV_LIM_*` ramp + TR-DR-012;
  SYS-10's epoch store; SYS-32's 9-field publication (read-only).
- Index row's "Yes (one + VFX)" is stale vs. the pivot → correct to "one (material
  only — no prompt/VFX/audio)" at the systems-index sync.
- Formula set: F-SMB-01 depth/step; F-SMB-02 band clip; F-SMB-03 visibility;
  F-SMB-04 contract acceptance (four content hashes); F-SMB-05 admission P1–P5+G;
  F-SMB-06 tint alpha (floor-quantized, per-step colors); F-SMB-07 feasibility.
- The purple's admitted form is a **static depth tint on the wing frame's W/E
  columns** — never the threshold band (outside the wing), never the north row,
  never the fill/fixtures/M4. Per-step tint colors; alpha floor-quantized.
- `visible_at_epoch_gte` is derived at boot (min epoch where both predicates true);
  the admission record hashes ramp/grief/placement/constants.
- No CameraPort, no `active_hold` read; SYS-32 is an acceptance fixture only.

## Open items

- Art-bible ratification of the purple bridge (OQ-RWS-7 / SYS-11's OQ-1).
- Purple hue/hex pins at the art bible; `PROV_LIM_*` hexes are PLACEHOLDER.
- The `PROV_LIM_*` ramp is SYS-09's; SYS-11 assigns only the frame's step mapping.

## Next

Present context summary + feasibility brief; ask framing questions; create skeleton.
