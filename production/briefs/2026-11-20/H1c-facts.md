# Studio help facts — tuning and room data

Sources live in `prototypes/feel-v3/`.

| Control or data | Behavior and limits | Source |
| --- | --- | --- |
| **FEEL**, extra tuning tabs | FEEL shows the base tuning sliders outside WEAPONS. The extra tabs are named after loaded tuning parts. Dragging a slider changes the game at once. | `tuning_panel.gd:43`, `:100`, `:120`, `:332` |
| Slider **?** | Shows the setting description, min, max, step, saved value, and live value. | `tuning_panel.gd:250` |
| **WEAPONS**, **<**, **>**, picker **?** | Cycle weapon choices. The help lists choices and shows which are saved and live. Other weapon settings use sliders. | `tuning_panel.gd:129`, `:266`, `:320` |
| **SOUNDS**, **<**, **>**, sound **?** | The arrows choose and preview a sound. The loudness slider runs from −30 to +6 dB in steps of 1. Sound effects also have pitch variety from 0 to 0.25 in steps of 0.01. Music has no pitch slider. Help lists ranges. | `tuning_panel.gd:149`, `:288`, `:338` |
| **Save**, **Reset**, F1 | Save writes tuning and sound changes. Reset returns both to the saved values. F1 closes the panel. | `tuning_panel.gd:55`, `:64`, `:360` |
| Back, solid, front, backdrop | Front PNGs draw over the character. Back and solid PNGs draw below moving objects. A named backdrop replaces the default wall image when the picture exists. | `editor/props_layer.gd:2`, `:33`, `:49` |
| Room size and solid PNG collision | A room cell is 16 pixels. Resize adds empty cells and trims from the right or bottom, with a four-cell minimum on each axis. Solid PNG tiles can add collision to empty cells within their footprint. Existing glyphs keep their meaning. | `editor/room_doc.gd:11`, `:158`, `:175`, `:208` |
| Decorative picture transforms | Back and front decor may have optional angle and scale. Missing fields draw at the old size and angle. A picture turns around its top-left anchor. Free position can keep fractional pixels. Solid and tile pictures ignore angle and scale. | `editor/room_doc.gd:175`, `:192`, `:197`; `editor/props_layer.gd:33` |
