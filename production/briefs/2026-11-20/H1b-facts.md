# Studio help facts — map, builder switcher, and playtest notes

Sources live in `prototypes/feel-v3/editor/`. Keep button labels and key names when writing help.

| Control | Behavior and limits | Source |
| --- | --- | --- |
| **Map**, **Edit Room**, **Play Here** | Map marks the active tool. Edit Room opens the selected room in F2 (Enter). Play Here starts a playtest in the selected room (T). | `map_builder.gd:350`, `:389`, `:940` |
| **Undo**, **Redo**, **Save Map**, **Close** | Undo or redo map edits (Ctrl+Z, Ctrl+Shift+Z or Ctrl+Y). Save Map writes map positions and sizes (Ctrl+S). Close goes through the shared draft prompt. | `map_builder.gd:190`, `:331`, `:396`, `:930` |
| **Search name or code**, room list | Filters the rooms in the active era by display name, code, or room ID. Click a thumbnail to select its room. The map centers the room if it is outside the view. | `map_builder.gd:415`, `:520` |
| **Before**, **After**, **Restored** | Show the three era sheets (1, 2, 3). A room may be visible on another sheet. Edit its placement on its own sheet. | `map_builder.gd:11`, `:260`, `:289`, `:446`, `:942` |
| **−**, **+**, **Fit**, **Center** | Zoom out or in from the center, fit all rooms in view, or center the selected room. The wheel zooms around the pointer. Arrows pan, as do middle drag, right drag, and Space+left drag. | `map_builder.gd:451`, `:677`, `:793`, `:950` |
| **Map X**, **Map Y**, **Width (cells)**, **Height (cells)** | Set the selected room's map position and map footprint. Positions start at 0, sizes at 1. Drag the room or Alt+arrow to move it. Drag its handle or Shift+arrow to resize it. | `map_builder.gd:294`, `:470`, `:812`, `:950` |
| **Issues**, overlap list, **Cancel** | Click an issue to focus it and read its details. Click an overlap to choose a room when the selected room cannot be dragged there. Cancel closes that list. Esc cancels the current gesture, closes the overlap list, or asks to close the builders. | `map_builder.gd:626`, `:660`, `:812`, `:879`, `:943` |
| **Builders**, F2, F3, F4 | Builders opens the map. F2 opens the room editor, F3 the map, F4 screenshot notes. The shared close prompt offers Save all, Keep editing, and Discard when drafts are dirty. | `dev_hub.gd:6`, `:60`, `:203` |
| **Stop Playtest    Tab** | Tab returns to the builder. Escape, F2, and F3 also stop the playtest. N spawns the chosen pick during a room playtest. | `dev_hub.gd:73`, `:339` |
| **what is wrong here?** | Type a note about the frozen frame. Left drag draws a red box, right click removes the last, and Enter saves. Esc or F4 cancels. Save needs a captured image and writes a PNG plus a line in notes.md. | `note_tool.gd:37`, `:66`, `:107`, `:137` |
