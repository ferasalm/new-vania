# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "Dev": the in-game developer tools, desktop only.
#   F4  screenshot notes  (mark the picture, type a comment, saved for Claude to read)
#   F2  room builder      (added in a later slice)
#   F3  map builder       (added in a later slice)
# One tool is open at a time. The game pauses while a tool is open, and the
# pause menu cannot open on top of it.
extends Node

## Tools: input action -> [key, script path]. A tool script is a CanvasLayer with
## begin(info: Dictionary) and a `closed` signal.
const TOOLS := {
	"dev_notes": [KEY_F4, "res://editor/note_tool.gd"],
}

var god := false                 # invincible (room builder debug toggle)
var notes_dir_override := ""     # tests write notes somewhere else
var tool: Node = null            # the open tool, or null
var tool_action := ""

var _we_paused := false
var _touch_was_blocked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("mobile") or OS.has_feature("web"):
		set_process(false)      # desktop only
		return
	for action in TOOLS:
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = TOOLS[action][0]
		InputMap.action_add_event(action, ev)


func _process(_delta: float) -> void:
	for action in TOOLS:
		if Input.is_action_just_pressed(action):
			if tool != null:
				if tool_action == action:
					close_tool()          # the same key again closes it
			else:
				open_tool(action)
			return


## True while a dev tool owns the keyboard.
func busy() -> bool:
	return tool != null


## Open a tool by its action name. Returns the tool, or null when it cannot open
## (no game yet, the pause menu is open, or another tool is open).
func open_tool(action: String, info := {}) -> Node:
	if tool != null or G.main == null or get_tree().paused:
		return null
	if not TOOLS.has(action):
		return null
	var script: GDScript = load(TOOLS[action][1])
	var t: Node = script.new()
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	# the picture must be taken before the tool draws anything on top of it
	var info2: Dictionary = game_info()
	info2.merge(info, true)
	if action == "dev_notes" and not info2.has("image"):
		var img: Image = get_viewport().get_texture().get_image()
		if img == null or img.is_empty():
			# no renderer (a headless test run): a plain grey picture so the tool still works
			img = Image.create(768, 432, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.25, 0.25, 0.28))
		info2["image"] = img
	get_tree().root.add_child(t)
	tool = t
	tool_action = action
	_we_paused = true
	get_tree().paused = true
	var touch = G.main.touch
	if touch != null:
		_touch_was_blocked = touch.blocked
		touch.blocked = true        # Esc must not open the pause menu under the tool
	t.closed.connect(close_tool)
	t.begin(info2)
	return t


func close_tool() -> void:
	if tool == null:
		return
	var t := tool
	tool = null
	tool_action = ""
	if is_instance_valid(t):
		t.queue_free()
	if _we_paused:
		get_tree().paused = false
		_we_paused = false
	if G.main != null and G.main.touch != null:
		G.main.touch.blocked = _touch_was_blocked
	Engine.time_scale = 1.0


## What a note (or a bug report) should know about the moment: room, where she is, her state.
func game_info() -> Dictionary:
	var info := {"room": "?", "pos": Vector2.ZERO, "state": "?", "hp": 0.0, "facing": 1}
	var m = G.main
	if m == null:
		return info
	info["room"] = String(m.room_name)
	var p = m.player
	if p != null:
		info["pos"] = p.global_position
		info["state"] = String(p.state)
		info["hp"] = float(p.hp)
		info["facing"] = int(p.facing)
	return info


## The folder notes are written to. Next to the project's production/playtests when it can
## be found (also from an exported build run out of playable-history), else user://.
func notes_dir() -> String:
	if notes_dir_override != "":
		return notes_dir_override
	var starts: Array = [ProjectSettings.globalize_path("res://"), OS.get_executable_path().get_base_dir()]
	for s in starts:
		var a: String = String(s).simplify_path()
		for i in 8:
			for rel in ["production/playtests", "workspace/new-vania/production/playtests"]:
				if DirAccess.dir_exists_absolute(a.path_join(rel)):
					return a.path_join(rel).path_join("notes")
			var up := a.get_base_dir()
			if up == a:
				break
			a = up
	return ProjectSettings.globalize_path("user://notes")
