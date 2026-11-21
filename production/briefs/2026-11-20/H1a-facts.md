# Studio help facts — room builder

Sources live in `prototypes/feel-v3/editor/`.

| Control or key | Behavior and limits | Source |
| --- | --- | --- |
| **Map**, **Save**, **Playtest**, **Close** | Switch to F3, save the room and picture placements (Ctrl+S), play the current draft (Tab), or close through the draft prompt. | `room_builder.gd:175`, `:1108`, `:1150` |
| **Select**, **Place**, **Move**, **Erase** | Pick an object (V), place a palette item (B), drag an object (M), or remove a glyph or picture (E). | `room_builder.gd:189`, `:824`, `:871`, `:1017`, `:1183` |
| **Spread**, **Count**, **Apply Spread** | Draw a zone (S), choose enemy or trap types, and apply up to 40 placements. A type needs legal support and room to fit. Existing glyphs are preserved. | `room_builder.gd:193`, `:249`, `:1073`; `room_doc.gd:360` |
| **Play from here**, **Playtest Options** | Pick the playtest start (P). Options toggle Show hitboxes, Invincible, and Half speed. | `room_builder.gd:194`, `:347`, `:1137` |
| **Undo**, **Redo**, **Grid**, **Collision** | Undo and redo room edits (Ctrl+Z, Ctrl+Shift+Z or Ctrl+Y). Grid draws cell outlines and Collision shows collision on the canvas. | `room_builder.gd:196`, `:743`, `:1183` |
| **Library**, palette tabs, **Asset Folder**, **Refresh** | Search and preview project assets with Library. Tabs offer terrain, enemies, traps, markers, tiles, props, and backdrops. Asset Folder opens the picture folder and Refresh rescans it. | `room_builder.gd:217`, `:449`, `:483`; `ed_assets.gd:29` |
| **Behind**, **Solid**, **In Front** | Choose the picture layer. Solid PNG tiles add collision where their footprint covers empty room cells. Backdrops set the room background. | `room_builder.gd:243`, `:792`; `room_doc.gd:175` |
| **−**, **+**, **Fit** | Zoom out, zoom in, or frame the whole room (F). Wheel zooms around the pointer. Arrows or Space+drag can pan. | `room_builder.gd:258`, `:618`, `:1183`, `:1285` |
| **Move**, **Delete**, **Flip** | Inspector actions apply to the selection. Flip mirrors a picture. Delete removes the selected object. | `room_builder.gd:300`, `:833`, `:888` |
| **Room Size · Tiles**, **Apply**, **Check Reachability** | Set room dimensions in 16 px tiles and apply. Shrinking trims the right and bottom. Check Reachability runs the full room check. | `room_builder.gd:325`, `:684`, `:757`; `room_doc.gd:158` |
| **Copy**, **Cut**, **Paste**, **Duplicate**, **Delete** | Shift+drag selects a box of cells and pictures by their top-left anchors. Drag the box or nudge it with arrows. Ctrl+C copies, Ctrl+X cuts, Ctrl+V pastes at the pointed tile, and Ctrl+D duplicates. Delete clears the box. A move that would lose contents is refused. A paste may clip at the room edge and leaves a message. | `room_builder.gd:888`, `:912`, `:932`, `:1183`, `:1285` |
| **Rotate**, **− Size**, **+ Size**, **Free** | Rotate (R) turns a selected decorative picture 15°. [ and ] size it in steps of 0.25×, from 0.25× to 4×. Free lets decorative pictures move or be placed between snap points. Solid and tile pictures stay on the room grid. | `room_builder.gd:300`, `:987`, `:999`; `room_doc.gd:192` |
