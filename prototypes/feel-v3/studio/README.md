# Studio asset library

This folder is the one place that holds a copy of every image, sound and
source file in the project, plus `catalog.json`, which describes each one.

## Library layout

    library/
      characters/pandora/...      Pandora and hero sprites (1x and 2x)
      enemies/<name>/1x|2x/...    enemy art
      bosses/...                  boss art
      environment/1x|2x/...       tiles, props and backdrops
      fx/  weapon/  items/  palettes/
      audio/music/...             music
      audio/sfx/<group>/...       sound effects
      source/<name>/...           references and 3D previews
      root-assets/<name>/...      the shared assets/ folders
      concepts/...                design/art/concepts
      other/...                   anything that fits no rule

`catalog.json` holds `version`, `generated`, `categories` and `entries`.
Each entry says where the file came from, its kind, size, PNG dimensions,
search tags and a stable id (`help_key` is `asset:<id>`).

## Copied vs catalogued only

Images, sounds and source files from `prototypes/feel-v3/assets`,
`assets/` and `design/art/concepts/` are copied into `library/`.

The 3D model bank (`tools/models/bank/`) and the `inbox/` are listed in
`catalog.json` but never copied. They are large or raw, and the Studio
only needs to know they exist.

## Regenerating

From the repo root:

    node tools/asset_library.mjs

It is safe to run again: unchanged files are left alone. `--dry-run`
prints the catalog without writing anything. `library/` and `catalog.json` are generated
and are not committed (the catalog lists every file on this machine and changes on each run).

`.gdignore` is here so Godot does not import or export the copies.
Without it the game export would grow by the size of the whole archive.

The builder code stays in `prototypes/feel-v3/editor/` because Godot
needs it inside the project.


## Open Studio on Windows

Double-click `open-studio.cmd` in this folder, then click **Studio** in
the top right of the game. The launcher uses the milestone 3 Windows build
when it exists. Otherwise it uses the workspace's Godot installation or
the executable set in `GODOT_EXE`.

The launcher builds the library with Node.js if the catalog or library folder is missing.
Turn on **Recent** beside the Library category menu to find pictures you used in this session.

Studio shows the full library path. Search for an activity such as
`map resize`, select the result, and press **Open selected help**.
Use F2 for the room builder, F3 for the map, and F1 for tuning. Press
a **?** button or right-click a builder control to read its help.
