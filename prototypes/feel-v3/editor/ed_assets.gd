# PROTOTYPE - NOT FOR PRODUCTION
# The builder's palette and picture loading.
#   assets/editor/tiles/      PNGs that are placed on the 16 px grid (a solid tile also makes the cell solid)
#   assets/editor/props/      PNGs placed anywhere (8 px snap), behind, with the room, or in front
#   assets/editor/backdrops/  PNGs for the wall behind the room; they tile at their real size, never stretched
# Drop a PNG into a folder and it shows up in the palette the next time the builder opens.
extends RefCounted

const KINDS := ["tiles", "props", "backdrops"]

static var root_override := ""      # tests point the palette at a temporary folder
static var _cache := {}

## Built-in grid characters: [character, plain name]. Group names are the palette tabs.
const TERRAIN := [
	["#", "solid wall"], ["=", "thin ledge"], ["B", "bricked arch"], ["|", "iron bars"], ["%", "cracked wall"],
	[":", "shutter"], [".", "empty (erase)"], ["^", "opening up"], ["v", "opening down"],
	["<", "open edge left"], [">", "open edge right"],
]
const HAZARDS := [["p", "pendulum"], ["u", "crusher"], ["f", "flame vent"], ["i", "spikes"]]
const SPOTS := [
	["P", "player start"], ["D", "door"], ["X", "boss door"], ["M", "save terminal"], ["K", "capsule"],
	["A", "relic"], ["O", "boss spawn"], ["T", "time machine"], ["L", "library lever"], ["Y", "lever behind bars"],
	["1", "mark 1"], ["2", "mark 2"], ["3", "mark 3"], ["4", "mark 4"], ["5", "mark 5"],
	["6", "mark 6"], ["7", "mark 7"], ["8", "mark 8"], ["9", "mark 9"],
]

## Tabs, in order.
const TABS := ["TERRAIN", "ENEMIES", "HAZARDS", "SPOTS", "TILES", "PROPS", "BACKDROPS"]
const CATEGORY_LABELS := ["Terrain", "Enemies", "Traps", "Room Markers", "PNG Tiles", "PNG Props", "Backdrop"]


static func editor_root() -> String:
	if root_override != "":
		return root_override
	var pd: String = Dev.project_dir()
	return pd.path_join("assets/editor") if pd != "" else ""


## Make the three folders (with a short README) when they are missing.
static func ensure_folders() -> void:
	var root := editor_root()
	if root == "":
		return
	for k in KINDS:
		DirAccess.make_dir_recursive_absolute(root.path_join(k))
	var readme := root.path_join("README.txt")
	if not FileAccess.file_exists(readme):
		var f := FileAccess.open(readme, FileAccess.WRITE)
		if f != null:
			f.store_string("Drop PNG files into these folders; they appear in the room builder (F2) palette.\n"
				+ "  tiles/      placed on the 16 px grid; a solid tile also makes its cells solid\n"
				+ "  props/      placed anywhere, behind, with the room or in front\n"
				+ "  backdrops/  the wall behind the room; tiles across at its real size, never stretched\n")
			f.close()


## PNG file names in one folder, sorted.
static func scan(kind: String) -> Array:
	var out: Array = []
	var root := editor_root()
	if root == "":
		return out
	var d := DirAccess.open(root.path_join(kind))
	if d == null:
		return out
	for f in d.get_files():
		if f.to_lower().ends_with(".png"):
			out.append(f)
	out.sort()
	return out


## Every palette entry for a tab: {name, glyph} for grid characters, {name, png} for pictures.
static func entries(tab: String) -> Array:
	var out: Array = []
	match tab:
		"TERRAIN":
			for t in TERRAIN:
				out.append({"glyph": t[0], "name": t[1]})
		"HAZARDS":
			for t in HAZARDS:
				out.append({"glyph": t[0], "name": t[1]})
		"SPOTS":
			for t in SPOTS:
				out.append({"glyph": t[0], "name": t[1]})
		"ENEMIES":
			var defs: Dictionary = Db.table("enemies")
			for id in defs:
				var g := String(defs[id].get("glyph", ""))
				if g != "":
					out.append({"glyph": g, "name": String(id), "label": String(defs[id].get("name", id)).capitalize()})
		"TILES", "PROPS", "BACKDROPS":
			var kind := tab.to_lower()
			for f in scan(kind):
				out.append({"png": "%s/%s" % [kind, f], "name": f.get_basename()})
			if tab == "BACKDROPS":
				out.append({"png": "", "name": "(no backdrop)"})
	return out


## Palette thumbnails use actual room/game art where there is a matching sprite.
static func thumbnail(entry: Dictionary, category: String, theme_tiles: String) -> Texture2D:
	if entry.has("png"):
		return texture(String(entry["png"]))
	var glyph := String(entry.get("glyph", ""))
	if category == "ENEMIES":
		var anim := "hang" if glyph == "l" else "fly" if glyph == "m" else "idle"
		var path := "%s/%s_00.png" % [entry["name"], anim]
		if ResourceLoader.exists("res://assets/" + path) or FileAccess.file_exists("res://assets/" + path):
			return G.tex(path)
	if glyph in ["#", "="]:
		var atlas := AtlasTexture.new()
		atlas.atlas = G.tex("env/%s_%s.png" % [theme_tiles, "ledge" if glyph == "=" else "tiles"])
		atlas.region = Rect2(0, 0, 16, 8 if glyph == "=" else 16)
		return atlas
	if glyph in ["D", "X"]:
		return G.tex("env/door_%s.png" % ("boss" if glyph == "X" else "church"))
	return _marker_icon(glyph, category)


static func _marker_icon(glyph: String, category: String) -> Texture2D:
	var key := "marker|" + category + "|" + glyph
	if _cache.has(key):
		return _cache[key]
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	var ink := Color("#f3ac6f") if category == "HAZARDS" else Color("#b7a9f0")
	if glyph == "i":
		for base in [3, 9, 15]:
			for n in 5:
				img.fill_rect(Rect2i(base + floori(n * 0.5), 17 - n, 5 - n, 1), ink)
	elif glyph == "f":
		img.fill_rect(Rect2i(5, 17, 14, 3), ink)
		for x in [7, 11, 15]:
			img.fill_rect(Rect2i(x, 7 + x % 3, 2, 8), ink)
	elif glyph == "u":
		img.fill_rect(Rect2i(11, 3, 2, 9), ink)
		img.fill_rect(Rect2i(5, 12, 14, 7), ink)
	elif glyph == "p":
		img.fill_rect(Rect2i(11, 3, 2, 11), ink)
		img.fill_rect(Rect2i(7, 14, 10, 5), ink)
	else:
		img.fill_rect(Rect2i(5, 5, 14, 14), ink.darkened(0.52))
		img.fill_rect(Rect2i(9, 9, 6, 6), ink)
	var result := ImageTexture.create_from_image(img)
	_cache[key] = result
	return result


## A palette picture, or null. `rel` is "props/x.png". Works for a PNG that Godot has not imported.
static func texture(rel: String) -> Texture2D:
	if rel == "":
		return null
	var root := editor_root()
	var key := root + "|" + rel
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	if root != "":
		var path := root.path_join(rel)
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	if tex == null and ResourceLoader.exists("res://assets/editor/" + rel):
		tex = load("res://assets/editor/" + rel)
	_cache[key] = tex
	return tex


static func size_of(rel: String) -> Vector2:
	var t := texture(rel)
	return t.get_size() if t != null else Vector2(TILE_FALLBACK, TILE_FALLBACK)


const TILE_FALLBACK := 16.0


static func clear_cache() -> void:
	_cache.clear()
