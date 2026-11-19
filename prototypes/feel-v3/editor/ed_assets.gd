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
					out.append({"glyph": g, "name": String(id)})
		"TILES", "PROPS", "BACKDROPS":
			var kind := tab.to_lower()
			for f in scan(kind):
				out.append({"png": "%s/%s" % [kind, f], "name": f.get_basename()})
			if tab == "BACKDROPS":
				out.append({"png": "", "name": "(no backdrop)"})
	return out


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
