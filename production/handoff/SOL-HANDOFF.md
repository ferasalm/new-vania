# Sol handoff — preview before implementation

## Now
- Worktree: `C:/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch`, branch `feat/proto-v3-patch`; no merge authorized.
- Goal: credible demo, not endless prototypes. This session banked sources and verified the baseline; it did NOT finish a demo or integrate new art.
- User explicitly requires: LOOK at Pandora's adult-proportion preview first; only if they approve, proceed toward implementation. Full polished animation set remains a separate gate.
- Study: `prototypes/feel-v3/assets/pandora_proportion_study/`; rendered/viewed, original costume, zero Rodin credits. TOP row old, BOTTOM new, same camera scale. Height +8.43%, legs +15.89%; arms unchanged, still stylized. NOT approved or integrated.
- Total LLM ceiling $4.50. Study window overran its $0.30 cap: measured ~$0.574 since approval including checkpoint/handoff work; user told, art iterations stopped. Last measured aggregate ~$3.77; costs accrue after that reading. Do not mistake main-only cost for aggregate.
- Rodin generation STOPPED. Latest user report: ~10 credits, four more days of access; preserve for targeted fixes under fresh approval.

## Verified
- `7cd4894` pushed: POGR runtime + Claude mirror + skill catalog/spec; fresh final `npm run ci` passed 5/5 (`C:/Users/AUC/AppData/Local/Temp/opencode/sol-final-ci.log`).
- Earlier fresh Godot runs: CLIMB PASS, SMOKE PASS passed=58 failed=0. No gameplay changes since. Logs: `C:/Users/AUC/AppData/Local/Temp/opencode/sol-climb.log` and `sol-smoke.log`.
- `prototypes/feel-v3/tools/models/rodin-bank.json`: 53 jobs = 51 new + 2 recovered. 30 local GLBs total 312883424 bytes, SHA256 manifest matches and valid glTF-v2 headers/lengths, each below 20MB; NOT visual/production approval.
- `tools/models/bank/DOWNLOADS.json` validates first 26; `HERO-DOWNLOADS.json` records four later Pandora downloads. Old pending list is stale for those four; derive remaining 23 by filename vs ledger, not that list alone.
- Pandora libraries `pandora_motion_library.glb` and `pandora_clean_motion_library.glb`: each 1 skin / 10 stock clips. `pandora_parts.glb`: 8 meshes / no skin. Clean raw model: no skin. Already paid: inspect locally, do NOT regenerate.
- `assets/hero_3d_preview/`: original four-pose spike, NOT production-ready (cape stretches). Packed `.blend`, PNGs, metadata; `tools/render_pandora_preview.py` reproduces it. `first-pass/` is a rejected cropped pass, not intended for commit.
- Runtime metadata: 77 frames, 15 animations, 112x80, pivot [56,76], faces right. Fable's 92 hero_v2 cutouts are a DIFFERENT unwired, unapproved set.

## Next steps
1. Show `pandora_proportion_study/before_after.png`; obtain an explicit user verdict. Study approval does NOT mean finished sprite-set approval. No runtime art switch without the full legal set and implementation approval.
2. Follow `PANDORA-QUALITY.md`: resolve cloth weights, retest the changed rig under motion, author a four-action polished pilot, then ALL runtime animations. Native Aseprite cleanup allowed. Strips/GIFs at 1x, both directions, fixed pivot, anticipation/contact/recovery; no duplicated padding, no stock-clip-as-final claim.
3. Recover remaining 23 already-paid jobs from ledger using Hyper3D MCP result links; prefer packed `base_basic_pbr.glb` (rig clips are inside it). Validate glTF/header/hash; keep signed URLs out of repo. No need to hurry or pay again.
4. Review proposed `DEMO-TARGET.md` with user: intro → hound/moth lesson → relic BEFORE shaft → return loop → Mourning Bell climax. Two enemies, one boss; not all bank content. Validate existing progression gates before designing around them.
5. Only after design + art approvals, implement small test-first stories; fresh SMOKE + CLIMB + screenshots, then user playtest B02. No demo claim while prohibited legacy hero remains in runtime. APK has NOT been rebuilt after Fable's latest fixes.

## Open decisions / worker rules
- Status vocabulary: done / in progress / planned / not planned / waiting on user. A queued job, four poses, or passing unit tests is NOT a finished demo.
- Read `.agents/skills/pogr/SKILL.md`, this file, `PANDORA-QUALITY.md`, `DEMO-TARGET.md`, then only files needed for the next approved slice. Two failures: stop and report; do not loop or expand scope.
- Builder: `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017#low`; independent review: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash#low`. Pin every helper. Do not silently inherit an expensive model.
- Preserve identity/silver ponytail/black-cyan costume. Cape-free alternative is NOT approved canonical art. Proportion study is not a general vertical stretch; face redesign and cloth repair are not automatically complete.
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
From the PATCH worktree, first run `git status --short`, then read this handoff and `.agents/skills/pogr/SKILL.md`. Ask for the pending visual verdict, not for permission already given to make the study. Do NOT implement before that verdict.

## Final checkpoint / preview verdict
- Final CI 5/5; all 30 source hashes verified. Bank commit `e7e76f4`. Initial push timed out at 120s; checkpoint retry must confirm remote. Use `git log -3 --oneline` and `git status --short --branch` for final checkpoint IDs/sync; never infer a push from a local commit.
- Independent GLM gate: SAFE TO SHOW, CONCERNS; not natural-adult/full-sprite quality. Read the study README for metadata/authoring-scene limitations. The user has not approved the revision.
