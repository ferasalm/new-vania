# PROTOTYPE - NOT FOR PRODUCTION
# The PNG props and tiles a room carries (rooms/<name>.props.json), drawn in the real game.
# room.gd adds one of these to every room it builds. "back" and "solid" pictures sit
# above the room's own tiles and behind everything that moves; "front" ones draw over her.
extends Node2D

const EdAssets := preload("res://editor/ed_assets.gd")
const RoomDoc := preload("res://editor/room_doc.gd")

## The builder's live copy while she plays a room that has not been saved: file id -> json text.
static var override := {}


static func read_layout(file_id: String) -> Array:
	var rel := "rooms/%s.props.json" % file_id
	var text: String
	if override.has(file_id):
		text = String(override[file_id])
	else:
		var linked: String = Dev.project_dir()
		var path := linked.path_join(rel) if linked != "" else ""
		text = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else FileAccess.get_file_as_string("res://" + rel)
	if text.strip_edges() == "":
		return []
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Array else []


func setup(file_id: String) -> void:
	setup_props(read_layout(file_id))


func setup_props(layout: Array) -> void:
	for p in layout:
		if not (p is Dictionary):
			continue
		var tex: Texture2D = EdAssets.texture(String(p.get("png", "")))
		if tex == null:
			continue
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.flip_h = bool(p.get("flip", false))
		s.transform = RoomDoc.prop_transform(p)
		s.z_index = 8 if String(p.get("layer", "back")) == "front" else 0
		add_child(s)


## The picture for a header `backdrop=<file>` (a PNG in assets/editor/backdrops/); the theme's own wall when
## the file is missing.
static func backdrop_texture(file: String, fallback: Texture2D) -> Texture2D:
	var t: Texture2D = EdAssets.texture("backdrops/" + file)
	return t if t != null else fallback
