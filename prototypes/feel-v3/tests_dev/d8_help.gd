# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d8_help.gd - Studio slice S2 gate (ledger N24): the "?" help system.
# Written from the spec only (production/briefs/2026-11-20/S2-deepseek.md); never from the code.
# Run: godot --headless --path . res://tests_dev/d8_help.tscn      (expect "d8_help PASS n/n")
#
# Contract under test:
#   const EdHelp := preload("res://editor/ed_help.gd")        (static functions, no instance needed)
#   EdHelp.load_file(path) -> int      merge entries from a JSON file {key: {title, what, how, limits[], keys[], thumb}};
#                                      returns how many valid entries it read; a missing, unreadable or invalid file returns 0
#                                      and leaves the table unchanged; a value that is not a dictionary is skipped
#   EdHelp.clear()                     empty the table and close any popup
#   EdHelp.has(key) -> bool            true only for a loaded, non-empty key
#   EdHelp.text_for(key) -> String     the plain text a reader sees: title, then labelled sections "What it is", "How to use",
#                                      "Limits" (one bullet per entry), "Keys" (one line per entry); empty sections are left out;
#                                      an unknown or empty key gives text containing "No help written yet" and the key
#   EdHelp.show(key)                   opens the ONE help popup (root node in group "ed_help_popup"); never crashes
#   EdHelp.hide()                      closes it (no popup node stays in the group)
#   EdHelp.is_open() -> bool, EdHelp.current_key() -> String, EdHelp.shown_text() -> String (what the open popup displays)
#   EdHelp.attach(control, key)        sets meta "help_key" on the control; a right mouse click on it opens help; a left click does not
#   Shell.button(parent, label, action, tooltip := "", help_key := "") -> Button   (Shell = res://editor/workspace_shell.gd)
#                                      returns the main button; with a help_key a small "?" Button follows it in the same parent
extends Node

const EdHelp := preload("res://editor/ed_help.gd")
const Shell := preload("res://editor/workspace_shell.gd")
const FIXTURE := "user://d8_help_fixture.json"
const BAD := "user://d8_help_bad.json"
const SEED := "res://studio/help/help.json"

var passed := 0
var failed := 0
var pressed_count := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	_run()
	var ok := failed == 0 and passed > 0
	print("d8_help %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _popups() -> int:
	return get_tree().get_nodes_in_group("ed_help_popup").size()


func _right_click(c: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	ev.position = Vector2(2, 2)
	c.gui_input.emit(ev)


func _left_click(c: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(2, 2)
	c.gui_input.emit(ev)


func _run() -> void:
	EdHelp.clear()
	_check("a fresh table knows no key", not EdHelp.has("alpha") and not EdHelp.has(""), "has alpha=%s" % str(EdHelp.has("alpha")))
	_check("nothing is open at the start", not EdHelp.is_open() and _popups() == 0, "popups=%d" % _popups())

	# ---- loading ----
	_write(FIXTURE, JSON.stringify({
		"alpha": {"title": "Alpha tool", "what": "Draws walls.", "how": "Drag on the grid.",
			"limits": ["Grid only", "Desktop only"], "keys": ["W: wall", "Shift+W: erase"]},
		"beta": {"title": "Beta tool", "what": "Places doors.", "how": "Click a wall edge."},
		"gamma": {"title": "Gamma tool", "what": "Shows a picture.", "how": "Open the palette.", "thumb": "no_such_asset_id"},
		"junk": "this is not a dictionary",
	}))
	var n := EdHelp.load_file(FIXTURE)
	_check("load_file returns the number of valid entries (3, the junk value is skipped)", n == 3, "n=%d" % n)
	_check("loaded keys are known, the skipped one is not", EdHelp.has("alpha") and EdHelp.has("beta") and EdHelp.has("gamma") and not EdHelp.has("junk"), "alpha=%s junk=%s" % [str(EdHelp.has("alpha")), str(EdHelp.has("junk"))])
	_check("an unknown key and an empty key are not known", not EdHelp.has("nope") and not EdHelp.has(""), "")

	_check("a missing file loads 0 entries", EdHelp.load_file("user://d8_does_not_exist.json") == 0, "")
	_write(BAD, "{ this is not json")
	_check("an invalid file loads 0 entries", EdHelp.load_file(BAD) == 0, "")
	_check("failed loads leave the table unchanged", EdHelp.has("alpha") and EdHelp.has("beta") and EdHelp.has("gamma"), "")

	# ---- the text a reader sees ----
	var t := EdHelp.text_for("alpha")
	for s in ["Alpha tool", "Draws walls.", "Drag on the grid.", "Grid only", "Desktop only", "W: wall", "Shift+W: erase"]:
		_check("text_for(alpha) contains '%s'" % s, t.contains(s), "text=%s" % t.left(120))
	for s in ["What it is", "How to use", "Limits", "Keys"]:
		_check("text_for(alpha) has the section label '%s'" % s, t.contains(s), "text=%s" % t.left(120))
	_check("each limit and key is on its own line", t.contains("Grid only") and t.contains("Desktop only") and t.find("Grid only") != t.find("Desktop only") and "\n" in t, "")
	var tb := EdHelp.text_for("beta")
	_check("text_for(beta) has its title, what and how", tb.contains("Beta tool") and tb.contains("Places doors.") and tb.contains("Click a wall edge."), "")
	_check("empty sections are left out (beta has no limits or keys)", not tb.contains("Limits") and not tb.contains("Keys"), "text=%s" % tb)
	var tm := EdHelp.text_for("not_written_key")
	_check("an unknown key reads 'No help written yet' and names the key", tm.contains("No help written yet") and tm.contains("not_written_key"), "text=%s" % tm)
	_check("an empty key also reads 'No help written yet'", EdHelp.text_for("").contains("No help written yet"), "")

	# ---- the popup ----
	EdHelp.show("alpha")
	_check("show opens the popup", EdHelp.is_open() and _popups() == 1, "open=%s popups=%d" % [str(EdHelp.is_open()), _popups()])
	_check("current_key is the key shown", EdHelp.current_key() == "alpha", "key=%s" % EdHelp.current_key())
	_check("the popup shows the same text as text_for", EdHelp.shown_text() == EdHelp.text_for("alpha"), "shown=%s" % EdHelp.shown_text().left(80))
	EdHelp.show("beta")
	_check("showing a second key reuses the one popup", _popups() == 1 and EdHelp.current_key() == "beta", "popups=%d key=%s" % [_popups(), EdHelp.current_key()])
	_check("the popup now shows the second entry", EdHelp.shown_text().contains("Beta tool") and not EdHelp.shown_text().contains("Alpha tool"), "")
	EdHelp.hide()
	_check("hide closes it and frees the popup node", not EdHelp.is_open() and _popups() == 0, "open=%s popups=%d" % [str(EdHelp.is_open()), _popups()])
	EdHelp.hide()
	_check("hide twice is harmless", not EdHelp.is_open() and _popups() == 0, "")
	EdHelp.show("never_written")
	_check("a missing key opens a popup that says 'No help written yet'", EdHelp.is_open() and EdHelp.shown_text().contains("No help written yet") and EdHelp.shown_text().contains("never_written"), "shown=%s" % EdHelp.shown_text().left(80))
	EdHelp.hide()
	EdHelp.show("")
	_check("an empty key opens a popup without crashing", EdHelp.is_open() and EdHelp.shown_text().contains("No help written yet"), "")
	EdHelp.hide()
	EdHelp.show("gamma")
	_check("an entry with an unknown thumbnail id still shows, without 'null' text", EdHelp.is_open() and EdHelp.shown_text().contains("Gamma tool") and not EdHelp.shown_text().contains("null"), "shown=%s" % EdHelp.shown_text().left(80))
	EdHelp.hide()

	# ---- attach: right click opens help ----
	var target := Button.new()
	add_child(target)
	EdHelp.attach(target, "beta")
	_check("attach stores the key on the control", String(target.get_meta("help_key", "")) == "beta", "meta=%s" % str(target.get_meta("help_key", "")))
	_left_click(target)
	_check("a left click does not open help", not EdHelp.is_open(), "")
	_right_click(target)
	_check("a right click opens help for the attached key", EdHelp.is_open() and EdHelp.current_key() == "beta", "open=%s key=%s" % [str(EdHelp.is_open()), EdHelp.current_key()])
	EdHelp.hide()
	target.queue_free()

	# ---- Shell.button ----
	var row := HBoxContainer.new()
	add_child(row)
	pressed_count = 0
	var plain := Shell.button(row, "Plain", func(): pressed_count += 1, "plain tip")
	_check("a button without help_key adds exactly one control", row.get_child_count() == 1, "children=%d" % row.get_child_count())
	_check("the button keeps its label and tooltip", plain.text == "Plain" and plain.tooltip_text == "plain tip", "text=%s tip=%s" % [plain.text, plain.tooltip_text])
	plain.pressed.emit()
	_check("the button action still fires", pressed_count == 1, "count=%d" % pressed_count)
	var row2 := HBoxContainer.new()
	add_child(row2)
	var helped := Shell.button(row2, "Walls", func(): pressed_count += 10, "wall tip", "alpha")
	_check("with a help_key a second control follows the button", row2.get_child_count() == 2 and row2.get_child(0) == helped, "children=%d" % row2.get_child_count())
	var q = row2.get_child(1) if row2.get_child_count() > 1 else null
	_check("the second control is a small Button labelled '?'", q is Button and q.text == "?", "node=%s" % str(q))
	_check("the '?' button's tooltip mentions help", q is Button and q.tooltip_text.to_lower().contains("help"), "tip=%s" % (q.tooltip_text if q is Button else "none"))
	helped.pressed.emit()
	_check("pressing the main button still runs its action and opens no help", pressed_count == 11 and not EdHelp.is_open(), "count=%d open=%s" % [pressed_count, str(EdHelp.is_open())])
	if q is Button:
		q.pressed.emit()
	_check("pressing '?' opens help for the key", EdHelp.is_open() and EdHelp.current_key() == "alpha", "open=%s key=%s" % [str(EdHelp.is_open()), EdHelp.current_key()])
	EdHelp.hide()
	row.queue_free()
	row2.queue_free()

	# ---- clear ----
	EdHelp.show("alpha")
	EdHelp.clear()
	_check("clear empties the table and closes the popup", not EdHelp.has("alpha") and not EdHelp.is_open() and _popups() == 0, "has=%s open=%s" % [str(EdHelp.has("alpha")), str(EdHelp.is_open())])

	# ---- the seed file the Studio ships ----
	var raw := FileAccess.get_file_as_string(SEED)
	var parsed = JSON.parse_string(raw)
	_check("the seed help.json exists and is a dictionary", parsed is Dictionary, "len=%d" % raw.length())
	if parsed is Dictionary:
		_check("the seed has at least 5 entries", parsed.size() >= 5, "n=%d" % parsed.size())
		var bad_entry := ""
		for k in parsed:
			var e = parsed[k]
			if not (e is Dictionary) or String(e.get("title", "")).strip_edges() == "" or String(e.get("what", "")).strip_edges() == "" or String(e.get("how", "")).strip_edges() == "":
				bad_entry = String(k)
				break
		_check("every seed entry has a title, a what and a how", bad_entry == "", "bad entry: %s" % bad_entry)
		var loaded := EdHelp.load_file(SEED)
		_check("EdHelp.load_file reads every seed entry", loaded == parsed.size(), "loaded=%d expected=%d" % [loaded, parsed.size()])
		var first := String(parsed.keys()[0])
		_check("a seed key is known and its text shows its title", EdHelp.has(first) and EdHelp.text_for(first).contains(String(parsed[first]["title"])), "key=%s" % first)
	EdHelp.clear()


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", name, " | ", detail)
