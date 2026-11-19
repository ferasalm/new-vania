This folder holds one picture per item she can pick up or equip.

- One transparent PNG per item, named <id>.png - for example suture.png,
  coupler_034.png. The id is the key in data/items.json (items) or
  data/gear.json (gear).
- Size 32x32. Transparent background. Pixel art, nearest-neighbour scaling.
- Used in the menus, and drawn in the room over the glow and on the pick-up
  card when she takes the item.
- Optional: <id>_world.png for how the same item looks lying in the room
  (the fallback is the plain <id>.png, so start with that one).
- The game looks the name up by id (item_icons.gd). Dropping a correctly named
  PNG in here is enough - no code change. Until a PNG exists the game draws a
  placeholder: a square coloured by the item's kind with the item's first
  letter.
- Files named _aside_<id>.png are test leftovers moved out of the way on
  purpose; they are not real item pictures and should not be committed.
