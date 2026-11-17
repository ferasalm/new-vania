# Pandora idle — appearance approval, NOT a completed animation set

## Current gate: image first

`pandora_idle_visual_concept.png` is the latest visual candidate requested by the
user. It is a **2048x2048 generated concept**, NOT a production 112x80 sprite.
Model: `openrouter/bytedance-seed/seedream-5-5`; job
`image_1e67442b30012QM6VL7Rgm1YKk`. One generation only, using the two user-supplied
JPG references in `../pandora_proportion_study/reference/`. Image fee not verified
by the LLM usage meter; do not describe the generation as free.

**Wait for the user's appearance approval.** Then prepare the real native 112x80
idle and inspect what survives at 1x before quoting/agreeing the entire sheet's
budget in this session. The user wants the full sheet before handoff, but it is
not funded by the current $2 additional base-test allowance. No runtime switch.

## Earlier coded drafts — separate from the generated concept

- `draw_hero_idle_sol.py` / `palette_sol.json`: Sol directly authored this separate
  native candidate after the user requested no more art delegation.
- `pandora_idle_base.png`, `_4x.png`, `proof_pandora_idle_base.png`, `layers_sol/`,
  `pandora_idle_base.aseprite`, `metadata.json`: outputs of that coded candidate,
  **not conversions of the newly generated concept**. Not user-approved.
- Reproduce that coded draft only with `python draw_hero_idle_sol.py` (Pillow).
- `draw_hero_idle.py`, `palette.json`, `layers/` are the helper's earlier work;
  its last cleanup script was saved but never executed. `first_draft/` preserves
  the initial helper output. Do not mistake these for the current source.

Independent binary checks verified the coded candidate's 112x80 RGBA, binary
alpha, 22 opaque colors, sole row 75 / pivot [56,76], exact nearest-neighbor 4x,
uncropped proof panels, and six Aseprite layers decompressing to the exact PNG.
**No native-app roundtrip claimed:** Aseprite runs in Docker; its MCP cannot use
the host `C:/...` path directly. Resolve the mount/container path for the next
native authoring/roundtrip step. A missing host executable is not missing Aseprite.

Lesson: establish the visual through an image before spending iterations on a
coded approximation. Palette candidates here are not canonical bible amendments.
