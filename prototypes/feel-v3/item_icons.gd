# PROTOTYPE - NOT FOR PRODUCTION
# One small helper that every place an item is shown asks for the item's
# picture: the pickup in the room, the pick-up card, and menus later. The rule
# is simple: the game uses assets/items/<id>.png when that file exists, and
# otherwise the caller draws a placeholder - a square coloured by the item's
# kind, with the item's first letter. Adding a picture needs no code change
# anywhere: save a transparent 32x32 PNG named <id>.png into assets/items/
# and it is picked up on the next run (see assets/items/README.txt).
extends RefCounted

const DIR := "res://assets/items/"


# The picture for one item id, or null when there is none (never an error).
# icon_field is the "icon" line from the item's data (it already names
# res://assets/items/<id>.png today), checked first, then the plain name.
# A PNG that has not been imported yet still shows through the Image fallback.
static func texture(item_id: String, icon_field := "") -> Texture2D:
	for path in [icon_field, DIR + item_id + ".png"]:
		if path == "" or not FileAccess.file_exists(path):
			continue
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is Texture2D:
				return res
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


# The placeholder square colour, by the item's kind: the "type" line from
# items.json; gear counts as its own kind. Same palette as pickup.gd's glow.
static func kind_color(data: Dictionary, item_id: String, is_gear := false) -> Color:
	if is_gear:
		return Color(0.8, 0.6, 1.0)
	match String(data.get("type", "")):
		"orb":
			return Color(0.35, 0.7, 1.0)
		"material":
			return Color(0.95, 0.62, 0.25)
		"ability":
			return Color(0.5, 1.0, 1.0)
		"weapon":
			return Color(1.0, 0.85, 0.4)
		"consumable":
			return Color(0.9, 0.9, 0.8)
	return Color(0.9, 0.9, 0.8)


# The first letter on the placeholder square: the item's name's first letter
# when the data knows a name, otherwise the id's first letter, else "?".
static func letter(data: Dictionary, item_id: String) -> String:
	var nm := String(data.get("name", ""))
	if nm == "":
		nm = item_id
	if nm == "":
		return "?"
	return nm.left(1)
