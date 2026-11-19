# PROTOTYPE - NOT FOR PRODUCTION
# The PNG props and tiles a room carries (rooms/<name>.props.json), drawn in the real game.
# room.gd adds one of these to every room it builds. "back" and "solid" pictures sit
# above the room's own tiles and behind everything that moves; "front" ones draw over her.
extends Node2D

const EdAssets := preload("res://editor/ed_assets.gd")

## The builder's live copy while she plays a room that has not been saved: file id -> json text.
static var override := {}


func setup(file_id: String) -> void:
	var text := ""
	if override.has(file_id):
		text = String(override[file_id])
	elif FileAccess.file_exists("res://rooms/%s.props.json" % file_id):
		text = FileAccess.get_file_as_string("res://rooms/%s.props.json" % file_id)
	elif Dev.project_dir() != "" and FileAccess.file_exists(Dev.project_dir().path_join("rooms/%s.props.json" % file_id)):
		text = FileAccess.get_file_as_string(Dev.project_dir().path_join("rooms/%s.props.json" % file_id))
	if text.strip_edges() == "":
		return
	var parsed = JSON.parse_string(text)
	if not (parsed is Array):
		return
	for p in parsed:
		if not (p is Dictionary):
			continue
		var tex: Texture2D = EdAssets.texture(String(p.get("png", "")))
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.flip_h = bool(p.get("flip", false))
		s.position = Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
		s.z_index = 8 if String(p.get("layer", "back")) == "front" else 0
		add_child(s)


## The picture for a header `backdrop=<file>` (a PNG in assets/editor/backdrops/); the theme's own wall when
## the file is missing.
static func backdrop_texture(file: String, fallback: Texture2D) -> Texture2D:
	var t: Texture2D = EdAssets.texture("backdrops/" + file)
	return t if t != null else fallback
