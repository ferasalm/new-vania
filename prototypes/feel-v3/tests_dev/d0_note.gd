# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d0_note.gd - proof for ledger N15 (the F4 screenshot-note tool).
# Opens the tool, draws a box, saves a note: a PNG with the red box burned in and one
# line in notes.md. A second note adds a second line. Cancel writes nothing. The game
# pauses while the tool is open and runs again after.
# Run: godot --headless --path . res://tests_dev/d0_note.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	await main.debug_enter("church", "left", false)
	await _frames(10)
	await _run()
	var ok := failed == 0 and passed > 0
	print("d0_note %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	var dir := ProjectSettings.globalize_path("user://d0_note_%d" % Time.get_ticks_msec())
	Dev.notes_dir_override = dir
	_check("the notes folder is the one the test set", Dev.notes_dir() == dir, Dev.notes_dir())
	# first note: one box and a comment with a pipe in it
	var t = Dev.open_tool("dev_notes")
	_check("F4 opens the note tool", t != null and Dev.busy(), "tool=%s" % str(t))
	if t == null:
		return
	_check("the game is paused while the tool is open", get_tree().paused, "")
	_check("a second tool cannot open on top", Dev.open_tool("dev_notes") == null, "")
	t.add_box(Rect2(0.25, 0.25, 0.25, 0.25))
	await _frames(3)
	var ok1: bool = t.submit("the moth | looks wrong")
	var png1: String = t.saved_png
	await _frames(3)
	_check("submit reports success", ok1, "")
	_check("the game runs again after saving", not get_tree().paused and not Dev.busy(), "paused=%s" % str(get_tree().paused))
	_check("the pause menu is allowed again", not main.touch.blocked, "blocked=%s" % str(main.touch.blocked))
	_check("the picture was saved", FileAccess.file_exists(png1), png1)
	var img := Image.load_from_file(png1)
	_check("the picture is the screen size", img != null and img.get_width() >= 384 and img.get_height() >= 216,
		"%s" % (str(img.get_size()) if img != null else "null"))
	if img != null:
		var x0 := int(0.25 * img.get_width())
		var y0 := int(0.25 * img.get_height())
		var c := img.get_pixel(x0 + 8, y0)
		_check("the red box is burned into the picture", c.r > 0.9 and c.g < 0.3 and c.b < 0.3, str(c))
	var lines := _note_lines(dir)
	_check("notes.md has one note line", lines.size() == 1, str(lines))
	if lines.size() == 1:
		_check("the line has the room, the comment (pipe replaced) and the picture",
			lines[0].contains("room church") and lines[0].contains("the moth / looks wrong")
			and lines[0].contains("boxes 1") and lines[0].contains(png1.get_file()), lines[0])
	# second note, no comment: appended, not overwritten
	var t2 = Dev.open_tool("dev_notes")
	t2.submit("")
	await _frames(3)
	lines = _note_lines(dir)
	_check("a second note adds a second line", lines.size() == 2 and lines[1].contains("(no comment)"), str(lines))
	# cancel writes nothing
	var t3 = Dev.open_tool("dev_notes")
	t3.cancel()
	await _frames(3)
	_check("cancel writes nothing and closes the tool", _note_lines(dir).size() == 2 and not Dev.busy() and not get_tree().paused, "")
	# F4 while the pause menu is open does nothing
	get_tree().paused = true
	_check("the tool does not open over a paused game", Dev.open_tool("dev_notes") == null, "")
	get_tree().paused = false


func _note_lines(dir: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(dir.path_join("notes.md"), FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("- "):
			out.append(l)
	return out


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
