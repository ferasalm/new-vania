extends RefCounted

const RoomDoc := preload("res://editor/room_doc.gd")
const EdAssets := preload("res://editor/ed_assets.gd")

const AIR := Color("#202738")
const TERRAIN := Color("#8997ad")
const HAZARD := Color("#ec925d")
const ENEMY := Color("#e76e86")
const DOOR := Color("#79c9f5")
const MARKER := Color("#ead084")


## Draw one pixel per room cell, then scale with crisp edges. Empty rooms have no thumbnail.
static func room(source: Variant, scale := 1) -> Texture2D:
	var doc: RefCounted
	if source is String:
		doc = RoomDoc.parse("", source)
	elif source is RoomDoc:
		doc = source
	if doc == null or doc.width() == 0 or doc.height() == 0 or scale < 1:
		return null
	var colors: Dictionary = {}
	for item in EdAssets.TERRAIN:
		colors[item[0]] = TERRAIN
	for item in EdAssets.HAZARDS:
		colors[item[0]] = HAZARD
	for item in EdAssets.SPOTS:
		colors[item[0]] = MARKER
	for glyph in ["D", "X", "<", ">", "^", "v"]:
		colors[glyph] = DOOR
	for enemy: Dictionary in Db.table("enemies").values():
		colors[enemy.get("glyph", "")] = ENEMY
	colors["."] = AIR

	var preview := Image.create_empty(doc.width(), doc.height(), false, Image.FORMAT_RGBA8)
	preview.fill(AIR)
	for y in doc.height():
		var row: String = doc.rows[y]
		for x in row.length():
			preview.set_pixel(x, y, colors.get(row[x], AIR))
	if scale > 1:
		preview.resize(preview.get_width() * scale, preview.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(preview)

