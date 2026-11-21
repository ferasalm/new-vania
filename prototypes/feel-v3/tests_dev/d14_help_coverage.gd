extends Node

const Help := preload("res://editor/ed_help.gd")
const Assets := preload("res://editor/ed_assets.gd")
const RoomDoc := preload("res://editor/room_doc.gd")
const CATALOG_CATEGORIES := ["3d", "audio", "bosses", "characters", "concepts", "enemies",
	"environment", "fx", "inbox", "items", "other", "palettes", "root-assets", "source", "weapon"]

var _checks := 0
var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var room = load("res://editor/room_builder.gd").new()
	add_child(room)
	room.begin({"room": "church", "doc": RoomDoc.parse("church", "theme=lab\n....\n.P..\n....\n####\n")})
	_check_controls(room, "F2")
	room.open_library()
	_check_controls(room.library_palette, "Library")
	room.close_library()
	room.queue_free()
	await get_tree().process_frame

	var map = load("res://editor/map_builder.gd").new()
	add_child(map)
	map.begin({"room": "church"})
	_check_controls(map, "F3")
	map.queue_free()
	await get_tree().process_frame

	var tuning = load("res://tuning_panel.gd").new()
	add_child(tuning)
	_check_controls(tuning, "F1")
	for sound: String in Sfx.pickable():
		var key: String = tuning.sound_help_key(sound)
		tuning.sound_help_button(sound).pressed.emit()
		var wording := Help.text_for(key)
		_check("saved and current sound values: " + sound,
			"Saved loudness:" in wording and "Current loudness:" in wording
			and "Saved sound:" in wording and "Current sound:" in wording)
		if Sfx.ev[sound]["group"] == "sfx":
			_check("sound effect saved and current pitch: " + sound,
				"Saved pitch variety:" in wording and "Current pitch variety:" in wording)
	Help.hide()
	for category: String in CATALOG_CATEGORIES:
		_check("catalog category " + category, _complete("catalog." + category))
	for tab: String in Assets.TABS:
		_check("room palette tab " + tab, _complete("palette." + tab.to_lower()))
	for group: Array in [Assets.TERRAIN, Assets.HAZARDS, Assets.SPOTS]:
		for glyph: Array in group:
			_check("room symbol " + glyph[0], _complete("glyph." + glyph[0]))
	_check("Studio entry can show the linked library path",
		Dev.has_method("studio_library_path") and str(Dev.call("studio_library_path")).ends_with("/studio/library"))
	var matches: Array = []
	var help_script: Script = Help
	for method in help_script.get_script_method_list():
		if method["name"] == "search":
			matches = Callable(help_script, "search").call("map resize")
			break
	_check("help search finds an activity described in the map", "map.width" in matches)
	print("d14_help_coverage %s %d/%d" % ["PASS" if _failures == 0 else "FAIL", _checks - _failures, _checks])
	get_tree().quit(0 if _failures == 0 else 1)


func _check_controls(node: Node, page: String) -> void:
	if node is BaseButton or node is Range or node is LineEdit or node is ItemList:
		var control := node as Control
		var key := str(control.get_meta("help_key", ""))
		var label := str(control.get("text")) if control is BaseButton else control.get_class()
		_check("%s %s (%s)" % [page, label, key], _complete(key))
	for child in node.get_children():
		_check_controls(child, page)


func _complete(key: String) -> bool:
	var entry: Dictionary = Help.entries.get(key, {})
	return not str(entry.get("what", "")).strip_edges().is_empty() and not str(entry.get("how", "")).strip_edges().is_empty()


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		printerr("FAIL: " + label)
