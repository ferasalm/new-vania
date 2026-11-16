# Unapproved static proportion study — B03

Open `before_after.png`: OLD is the top row; NEW is the bottom row.
Left is front, right is side; floor and camera scale are shared.

The original-costume candidate is 8.43% taller, with legs 15.89% longer and a
slightly smaller head/hair mass. The original GLB is unchanged. This is NOT
natural-adult target approval, a finished sprite set, or runtime integration.

Independent GLM review: safe to show, with concerns. Arms were not lengthened;
face and ponytail remain heavily stylized. Cloth weights need repair, changed
bone lengths need motion/retarget testing. Do not integrate this static study.
Ask the user to judge the direction before doing more art work.

`settings.json` is a spike report, not a rig validation certificate:
- `heads_tall` is hair-inclusive, not an anatomical head/body ratio.
- `arm_bones` reports stale finger-bone names; fix reporting before reuse.
- `head_weighted_verts` actually counts arm-weighted vertices in the script.

`packed.blend` contains both original and modified meshes; they overlap in the
authoring scene. Use the PNGs to judge the comparison. Its identical local
`authoring.blend` duplicate is intentionally not committed.

`build_study.py` and `inspect.py` run ONLY in a separate headless Blender with
`--background --factory-startup --python <script>`; never in the user's live scene.
The build refuses existing output files. It renders the four individual tiles;
the labeled contact sheet was assembled separately. Paths are workstation-local.
