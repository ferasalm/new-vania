# Sol handoff — preview before implementation

## Now
- Worktree: `C:/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch`, branch `feat/proto-v3-patch`; no merge authorized.
- Goal: credible demo, not endless prototypes. This session banked sources and verified the baseline; it did NOT finish a demo or integrate new art.
- User REJECTED the 3D proportion study, the helper's coded idle, Sol's hand-coded idle, and the one generated concept. Approved design basis is `assets/hero_2d_base/pandora-base-sprite.png` (magenta turnaround, 5 views). All asset paths below relative to `prototypes/feel-v3/`.
- LATEST task: user said the hand-drawn sprites are bad and asked for a FREE online tool to generate them. Research done: PixelLab (40 free generations, ~$0.03/8 frames) and Retro Diffusion ($0.50 free, ~$0.14/animation). WAITING ON USER'S TOOL CHOICE; no key, no generation.
- Aseprite: MCP works with container paths (`/workspace/new-vania-proto-v3-patch/...`; Docker `/workspace` = host `C:\Users\AUC\opencode-workspace\workspace`). Native Windows Aseprite built from official source: `C:/Users/AUC/opencode-workspace/tools/aseprite-src/build/bin/aseprite.exe` (`1.x-eccf4ec-dev`), Desktop shortcut; free personal use, do not redistribute.
- Animation input ready: `assets/hero_2d_base/pandora_sheet/anim_input/pandora_base_112x80.png` (feet row 75, centre x=56), 64x64 variant, `pixellab_animate.py` (key from env only, compiles).
- Budget restriction lifted by user; still record actual spend, never invent $0. Full sprite sheet remains the session goal; agree its budget after the base is approved. Rodin STOPPED (~10 credits, four days; no spend without fresh approval).

## Verified
- `7cd4894` pushed: POGR runtime + Claude mirror + skill catalog/spec; fresh final `npm run ci` passed 5/5 (`C:/Users/AUC/AppData/Local/Temp/opencode/sol-final-ci.log`).
- Earlier fresh Godot runs: CLIMB PASS, SMOKE PASS passed=58 failed=0. No gameplay changes since. Logs: `C:/Users/AUC/AppData/Local/Temp/opencode/sol-climb.log` and `sol-smoke.log`.
- `prototypes/feel-v3/tools/models/rodin-bank.json`: 53 jobs = 51 new + 2 recovered. 30 local GLBs total 312883424 bytes, SHA256 manifest matches and valid glTF-v2 headers/lengths, each below 20MB; NOT visual/production approval.
- `tools/models/bank/DOWNLOADS.json` validates first 26; `HERO-DOWNLOADS.json` records four later Pandora downloads. Old pending list is stale for those four; derive remaining 23 by filename vs ledger, not that list alone.
- Pandora libraries `pandora_motion_library.glb` and `pandora_clean_motion_library.glb`: each 1 skin / 10 stock clips. `pandora_parts.glb`: 8 meshes / no skin. Clean raw model: no skin. Already paid: inspect locally, do NOT regenerate.
- `assets/hero_3d_preview/`: original four-pose spike, NOT production-ready (cape stretches). Packed `.blend`, PNGs, metadata; `tools/render_pandora_preview.py` reproduces it. `first-pass/` is a rejected cropped pass, not intended for commit.
- Runtime metadata: 77 frames, 15 animations, 112x80, pivot [56,76], faces right. Fable's 92 hero_v2 cutouts are a DIFFERENT unwired, unapproved set.
- Aseprite MCP round-trip verified: opened the custom 112x80 6-layer ASE, added a layer, re-read 7 layers. Native Aseprite `1.x-eccf4ec-dev` GUI launch tested; `build/bin/data` present.
- Animation input bbox 40,6,66,76 at 112x80; alpha binary; 64x64 variant bbox 22,5,43,61.

## Next steps
1. Get the user's tool choice and API key (PixelLab or Retro Diffusion). Generate ONE idle motion test from `anim_input/pandora_base_112x80.png`, review frames at 1x and enlarged, then expand only after approval. The hand-coded/generated drafts are rejected, not conversions. No Rodin/runtime switch.
2. After base approval, quote the complete 77-frame / 15-animation sheet and agree its budget in THIS session. Use a motion pilot before full expansion; native Aseprite cleanup allowed. Strips/GIFs at 1x, both directions, fixed pivot, anticipation/contact/recovery; no duplicated padding. 3D rig/cloth repair is OPTIONAL support, not a required detour for a 2D-first route.
3. Recover remaining 23 already-paid jobs from ledger using Hyper3D MCP result links; prefer packed `base_basic_pbr.glb` (rig clips are inside it). Validate glTF/header/hash; keep signed URLs out of repo. No need to hurry or pay again.
4. Review proposed `DEMO-TARGET.md` with user: intro → hound/moth lesson → relic BEFORE shaft → return loop → Mourning Bell climax. Two enemies, one boss; not all bank content. Validate existing progression gates before designing around them.
5. Only after design + art approvals, implement small test-first stories; fresh SMOKE + CLIMB + screenshots, then user playtest B02. No demo claim while prohibited legacy hero remains in runtime. APK has NOT been rebuilt after Fable's latest fixes.

## Open decisions / worker rules
- Status vocabulary: done / in progress / planned / not planned / waiting on user. A queued job, four poses, or passing unit tests is NOT a finished demo.
- Read `.agents/skills/pogr/SKILL.md`, this file, `PANDORA-QUALITY.md`, `DEMO-TARGET.md`, then only files needed for the next approved slice. Two failures: stop and report; do not loop or expand scope.
- LATEST USER ROUTING: ALL well-scoped subagents use `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017#max`. ONLY open-ended creative writing/ideation without supplied instructions uses `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` at default (no variant suffix). Main lead retains the independent visual gate. This overrides earlier low-variant/different-family-helper guidance; pin every helper.
- New references retain silver ponytail/black-cyan torso/cape and CHANGE the upper arms to exposed skin. Face needs construction/value changes, not just scale. Large ponytail remains intentional. Cape-free alternative is NOT approved. Base approval is not full-sheet/runtime approval.
- Study caveats: `heads_tall` uses hair-inclusive height, NOT anatomical heads. `head_weighted_verts` and `arm_bones` metadata have reporting defects; do not use as rig-correctness proof. Source SHA independently unchanged: `1b5361569c2212b17e1bf430f0b02b05ab0e4b10f3833bb29361d8e30b2e8c27`. Animation validation remains required.
- No merge, gameplay tuning, hero switch, new generation, API purchases or APK rebuild without approval. Verify publication rights before distribution.
- Never open/view traced `prototypes/feel-v3/assets/hero/*`, Shanoa sheet, `tools/build_pandora.py`, `bake_pandora.py`, `shanoa_cells.py`, `tools/pristine/`. Owned `pandora-001-sprite.jpg`, `pandora-001-concept.jpg` and generated GLBs are allowed. Do not run `play.cmd` blindly.

## Backups / execution gotchas
- Main sibling checkout has pre-existing modified `opencode.json` and sandbox `.gd.uid` files: NEVER stage/discard. We added only official OAuth Hyper3D MCP there; exact pre-add backup: `C:/Users/AUC/AppData/Local/Temp/opencode/opencode-pre-hyper3d-20261116.json`.
- Session stays in MAIN for MCP tools, all game writes use PATCH absolute paths/workdir. CLI API requires `$env:PWD=(Get-Location).Path` in the intended workdir.
- Blender `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`; run scripts headless `--factory-startup` so user's live scene stays intact. Live default scene preserved; our separate `Pandora_original_pose_preview` scene is unsaved. Telemetry off; addon protocol old, no upgrade attempted.
- Standalone Hyper3D works with OAuth. Native Blender generator reports disabled: don't retry it. Result URLs are signed; persist only UUIDs/permanent workspace links and hashes.
- Godot `C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe`; self-exiting tests run via shell, not MCP debug reader. CLIMB uses `--fixed-fps 60`.
- Blender may emit harmless deprecation text on stderr; capture `2>&1 | Out-File -Encoding utf8` and check `$LASTEXITCODE` plus PASS line. PowerShell's default redirect can make UTF16 logs look binary.

## Exact fresh-session start
From the PATCH worktree, run `git status --short`, then read this handoff and `.agents/skills/pogr/SKILL.md`. Determine whether the 2D base has a user verdict and whether the full-sheet budget was agreed; do not reopen the rejected 3D study. Future demo integration is separate from the current base-test allowance.

## Final checkpoint / preview verdict
- Final CI 5/5; all 30 source hashes verified. Bank `e7e76f4` and previews/handoff `429eedb` both PUSHED (remote confirmed after timeout retry), no merge. Rejected first-pass and identical authoring.blend duplicate deliberately retained untracked.
- Old 3D study and all hand-coded/generated 2D attempts rejected. Aseprite MCP + native Windows Aseprite fixed; animation input and PixelLab client ready. Waiting on user's tool choice; no full-sheet work started. Historical base-phase LLM increment ~$1.3404; image fee separate/unknown.
