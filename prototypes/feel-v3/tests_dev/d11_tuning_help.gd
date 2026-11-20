# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d11_tuning_help.gd - Studio slice S5 gate (ledger N24): a "?" on every row of the F1 tuning panel.
# Written from the spec only (production/briefs/2026-11-20/S5-deepseek.md); never from the code.
# Run: godot --headless --path . res://tests_dev/d11_tuning_help.tscn      (expect "d11_tuning_help PASS n/n")
#
# Contract under test (res://tuning_panel.gd, a CanvasLayer; add_child builds it; autoloads T and Sfx exist):
#   panel.help_key(key) -> String                 "tuning:" + key
#   panel.sound_help_key(name) -> String          "tuning:sound:" + name
#   panel.help_button(key) -> Button              the small "?" at the end of the row of that tuning key (the slider rows
#                                                 on every page and the weapon picker row); null for an unknown key.
#                                                 text "?", tooltip "Help: <label>", focus_mode NONE
#   panel.sound_help_button(name) -> Button       the "?" of one SOUNDS row (name from Sfx.pickable()); null if unknown
#   Pressing a "?" (a) rebuilds EdHelp.entries[<help key>] from the CURRENT data, then (b) calls EdHelp.show(<help key>).
#   It changes no value. Number text everywhere is the panel's own format: str(snappedf(x, 0.01)).
#   slider key  : title = label, what = help text, how = non-empty, limits =
#                 "Range: <min> to <max>, steps of <step>", "Saved value: <default>", "Now: <current value>"
#   picker key  : (a data entry with "options") limits = "Choices: <a, b, c>", "Saved choice: <option>", "Now: <option>"
#   sound row   : title = Sfx.LABELS[name]; limits = "Loudness: <-30.0> to <6.0> dB" and, for the "sfx" group only,
#                 "Pitch variety: <0.0> to <0.25>" (music has no pitch slider, so no such line)
#   Layout      : no page gets a horizontal scrollbar, and every "?" sits fully inside its page's rectangle.
extends Node

const EdHelp := preload("res://editor/ed_help.gd")
const TuningPanel := preload("res://tuning_panel.gd")

var passed := 0
var failed := 0
var panel: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await _run()
	var ok := failed == 0 and passed > 0
	print("d11_tuning_help %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _check(name: String, cond: bool, detail := "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", name, " | ", detail)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _fmt(x: float) -> String:
	return str(snappedf(x, 0.01))


func _buttons_named(node: Node, text: String, out: Array) -> void:
	for c in node.get_children():
		if c is Button and (c as Button).text == text:
			out.append(c)
		_buttons_named(c, text, out)


func _scroll_of(node: Node) -> ScrollContainer:
	var n := node
	while n != null:
		if n is ScrollContainer:
			return n
		n = n.get_parent()
	return null


func _press(b: Button) -> void:
	b.pressed.emit()


func _run() -> void:
	EdHelp.clear()
	panel = TuningPanel.new()
	add_child(panel)
	await _frames(3)
	panel._root.visible = true
	await _frames(2)
	var keys: Array = T.data.keys()
	_check("the real tuning data is loaded (at least 200 keys)", keys.size() >= 200, "n=%d" % keys.size())
	var names: Array = Sfx.pickable()
	_check("the real sound list is loaded (at least 5 pickable sounds)", names.size() >= 5, "n=%d" % names.size())
	var has_music := false
	var has_sfx := false
	for n in names:
		if String(Sfx.ev[n]["group"]) == "sfx":
			has_sfx = true
		else:
			has_music = true
	_check("the sounds include both an effect and a music row (so the pitch rule is tested both ways)", has_sfx and has_music, "sfx=%s music=%s" % [has_sfx, has_music])
	var api := true
	for m in ["help_key", "sound_help_key", "help_button", "sound_help_button"]:
		api = api and panel.has_method(m)
	_check("the panel has help_key, sound_help_key, help_button and sound_help_button", api, "")
	if not api:
		return

	# ---- keys and unknowns
	_check("help_key is tuning:<key>", panel.help_key("run_speed") == "tuning:run_speed", panel.help_key("run_speed"))
	_check("sound_help_key is tuning:sound:<name>", panel.sound_help_key(String(names[0])) == "tuning:sound:" + String(names[0]), "")
	_check("help_button of an unknown key is null", panel.help_button("no_such_key") == null, "")
	_check("sound_help_button of an unknown name is null", panel.sound_help_button("no_such_sound") == null, "")

	# ---- one "?" per row, none doubled, none missing
	var all_q: Array = []
	_buttons_named(panel, "?", all_q)
	_check("exactly one '?' per tuning row and per sound row", all_q.size() == keys.size() + names.size(), "found=%d want=%d" % [all_q.size(), keys.size() + names.size()])
	var seen := {}
	var distinct := true
	var every_key_has := true
	var first_missing := ""
	for k in keys:
		var b = panel.help_button(String(k))
		if not (b is Button):
			every_key_has = false
			if first_missing == "":
				first_missing = String(k)
			continue
		if seen.has(b):
			distinct = false
		seen[b] = true
	for n in names:
		var sb = panel.sound_help_button(String(n))
		if not (sb is Button):
			every_key_has = false
			if first_missing == "":
				first_missing = "sound " + String(n)
			continue
		if seen.has(sb):
			distinct = false
		seen[sb] = true
	_check("every tuning key and every sound has a '?' Button (first missing: %s)" % first_missing, every_key_has, first_missing)
	_check("no two rows share one '?' button", distinct, "")
	if not every_key_has:
		return

	# ---- button look, per page: text, tooltip, no focus, visible size, inside the page, no horizontal scrollbar
	var page_total: int = panel._pages.size()
	_check("the panel has at least 3 pages (FEEL, WEAPONS, SOUNDS)", page_total >= 3, "pages=%d" % page_total)
	var bad_text := 0
	var bad_tip := 0
	var bad_focus := 0
	var bad_size := 0
	var bad_inside := 0
	var hbars := 0
	var first_bad := ""
	for i in page_total:
		panel._page(i)
		await _frames(3)
		var page: ScrollContainer = panel._pages[i]
		if page.get_h_scroll_bar().visible:
			hbars += 1
			if first_bad == "":
				first_bad = "page %d has a horizontal scrollbar" % i
		var prect: Rect2 = page.get_global_rect()
		for k in keys:
			var b: Button = panel.help_button(String(k))
			if _scroll_of(b) != page:
				continue
			if b.text != "?":
				bad_text += 1
			if b.tooltip_text != "Help: " + String(T.data[k]["label"]):
				bad_tip += 1
				if first_bad == "":
					first_bad = "tooltip of " + String(k) + ": " + b.tooltip_text
			if b.focus_mode != Control.FOCUS_NONE:
				bad_focus += 1
			var r: Rect2 = b.get_global_rect()
			if r.size.x < 8.0 or r.size.y < 8.0:
				bad_size += 1
				if first_bad == "":
					first_bad = "size of " + String(k) + ": " + str(r.size)
			if r.position.x < prect.position.x - 0.5 or r.end.x > prect.end.x + 0.5:
				bad_inside += 1
				if first_bad == "":
					first_bad = "outside page %d: %s in %s" % [i, str(r), str(prect)]
		for n in names:
			var sb: Button = panel.sound_help_button(String(n))
			if _scroll_of(sb) != page:
				continue
			if sb.text != "?":
				bad_text += 1
			if not sb.tooltip_text.begins_with("Help: ") or not sb.tooltip_text.contains(String(Sfx.LABELS[n])):
				bad_tip += 1
			if sb.focus_mode != Control.FOCUS_NONE:
				bad_focus += 1
			var sr: Rect2 = sb.get_global_rect()
			if sr.size.x < 8.0 or sr.size.y < 8.0:
				bad_size += 1
			if sr.position.x < prect.position.x - 0.5 or sr.end.x > prect.end.x + 0.5:
				bad_inside += 1
				if first_bad == "":
					first_bad = "sound %s outside page %d: %s in %s" % [String(n), i, str(sr), str(prect)]
	_check("every '?' reads exactly ?", bad_text == 0, "bad=%d" % bad_text)
	_check("every tuning '?' tooltip is 'Help: <label>' and every sound one names the sound", bad_tip == 0, "bad=%d %s" % [bad_tip, first_bad])
	_check("no '?' takes keyboard focus", bad_focus == 0, "bad=%d" % bad_focus)
	_check("every '?' is at least 8 x 8 on screen", bad_size == 0, "bad=%d %s" % [bad_size, first_bad])
	_check("every '?' sits inside its page's rectangle", bad_inside == 0, "bad=%d %s" % [bad_inside, first_bad])
	_check("no page needs a horizontal scrollbar", hbars == 0, first_bad)
	panel._page(0)

	# ---- pressing every tuning '?': the popup opens for the right key and shows label, help, range or choices, saved, now
	var open_ok := 0
	var key_ok := 0
	var label_ok := 0
	var help_ok := 0
	var range_ok := 0
	var saved_ok := 0
	var now_ok := 0
	var untouched := 0
	var first_fail := ""
	var picker_count := 0
	for k in keys:
		var key := String(k)
		var d: Dictionary = T.data[key]
		var before: float = T.v(key)
		EdHelp.hide()
		_press(panel.help_button(key))
		if EdHelp.is_open():
			open_ok += 1
		if EdHelp.current_key() == panel.help_key(key):
			key_ok += 1
		var text: String = EdHelp.shown_text()
		if text.contains(String(d["label"])):
			label_ok += 1
		elif first_fail == "":
			first_fail = key + " lacks its label"
		if text.contains(String(d["help"])):
			help_ok += 1
		elif first_fail == "":
			first_fail = key + " lacks its help text"
		if d.has("options"):
			picker_count += 1
			var opts: Array = d["options"]
			var all := text.contains("Choices:")
			for o in opts:
				all = all and text.contains(String(o))
			var si := clampi(int(T.defaults[key]), 0, opts.size() - 1)
			var ni := clampi(int(T.v(key)), 0, opts.size() - 1)
			if all:
				range_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its choices"
			if text.contains("Saved choice: " + String(opts[si])):
				saved_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its saved choice"
			if text.contains("Now: " + String(opts[ni])):
				now_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its current choice"
		else:
			if text.contains("Range: %s to %s, steps of %s" % [_fmt(float(d["min"])), _fmt(float(d["max"])), _fmt(float(d["step"]))]):
				range_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its range"
			if text.contains("Saved value: " + _fmt(float(T.defaults[key]))):
				saved_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its saved value"
			if text.contains("Now: " + _fmt(T.v(key))):
				now_ok += 1
			elif first_fail == "":
				first_fail = key + " lacks its current value"
		if T.v(key) == before:
			untouched += 1
	EdHelp.hide()
	var total := keys.size()
	_check("pressing a '?' opens the popup, for every key", open_ok == total, "ok=%d of %d" % [open_ok, total])
	_check("the popup is for that row's help key, for every key", key_ok == total, "ok=%d of %d" % [key_ok, total])
	_check("the popup shows the label of every key", label_ok == total, "ok=%d of %d %s" % [label_ok, total, first_fail])
	_check("the popup contains the help text of every key", help_ok == total, "ok=%d of %d %s" % [help_ok, total, first_fail])
	_check("the popup shows the range (or the choices) of every key", range_ok == total, "ok=%d of %d %s" % [range_ok, total, first_fail])
	_check("the popup shows the saved value of every key", saved_ok == total, "ok=%d of %d %s" % [saved_ok, total, first_fail])
	_check("the popup shows the current value of every key", now_ok == total, "ok=%d of %d %s" % [now_ok, total, first_fail])
	_check("pressing a '?' changes no value", untouched == total, "ok=%d of %d" % [untouched, total])
	_check("the weapon picker is one of the choice rows", picker_count >= 1 and T.data["weapon"].has("options"), "pickers=%d" % picker_count)

	# ---- the text is rebuilt when pressed, not frozen when the panel was built
	var stale_ok := 0
	var stale_tried := 0
	for key in [String(keys[0]), String(keys[keys.size() / 2]), String(keys[keys.size() - 1]), "weapon"]:
		var d: Dictionary = T.data[key]
		var old: float = T.v(key)
		var changed: float = float(d["max"]) if old != float(d["max"]) else float(d["min"])
		if d.has("options"):
			changed = float((int(old) + 1) % (d["options"] as Array).size())
		T.set_v(key, changed)
		_press(panel.help_button(key))
		var text: String = EdHelp.shown_text()
		stale_tried += 1
		var want: String
		var saved: String
		if d.has("options"):
			var opts: Array = d["options"]
			want = "Now: " + String(opts[int(changed)])
			saved = "Saved choice: " + String(opts[int(T.defaults[key])])
		else:
			want = "Now: " + _fmt(changed)
			saved = "Saved value: " + _fmt(float(T.defaults[key]))
		if text.contains(want) and text.contains(saved):
			stale_ok += 1
		else:
			print("  stale ", key, " wanted '", want, "' and '", saved, "'")
		EdHelp.hide()
	T.reset()
	_check("after a value changes, the popup shows the new 'Now' and the unchanged saved value (4 keys)", stale_ok == stale_tried, "ok=%d of %d" % [stale_ok, stale_tried])
	T.reset()
	_press(panel.help_button("run_speed"))
	_check("after Reset, the popup shows the saved value as 'Now' again", EdHelp.shown_text().contains("Now: " + _fmt(float(T.defaults["run_speed"]))), "")
	EdHelp.hide()

	# ---- sound rows: label, loudness range, pitch variety only for effects, nothing changed
	var snd_open := 0
	var snd_title := 0
	var snd_loud := 0
	var snd_pitch := 0
	var snd_untouched := 0
	for n in names:
		var name := String(n)
		var vol_before: float = float(Sfx.ev[name]["volume_db"])
		var pit_before: float = float(Sfx.ev[name]["pitch_random"])
		EdHelp.hide()
		_press(panel.sound_help_button(name))
		var open: bool = EdHelp.is_open() and EdHelp.current_key() == panel.sound_help_key(name)
		if open:
			snd_open += 1
		var text: String = EdHelp.shown_text()
		if text.contains(String(Sfx.LABELS[name])):
			snd_title += 1
		if text.contains("Loudness: %s to %s dB" % [_fmt(-30.0), _fmt(6.0)]):
			snd_loud += 1
		var wants_pitch := String(Sfx.ev[name]["group"]) == "sfx"
		var has_pitch := text.contains("Pitch variety: %s to %s" % [_fmt(0.0), _fmt(0.25)])
		if wants_pitch == has_pitch and (wants_pitch or not text.contains("Pitch variety")):
			snd_pitch += 1
		if float(Sfx.ev[name]["volume_db"]) == vol_before and float(Sfx.ev[name]["pitch_random"]) == pit_before:
			snd_untouched += 1
	EdHelp.hide()
	var sn := names.size()
	_check("pressing a sound '?' opens its popup, for every sound", snd_open == sn, "ok=%d of %d" % [snd_open, sn])
	_check("the sound popup shows the sound's label", snd_title == sn, "ok=%d of %d" % [snd_title, sn])
	_check("the sound popup shows the loudness range", snd_loud == sn, "ok=%d of %d" % [snd_loud, sn])
	_check("pitch variety is listed for effects and left out for music", snd_pitch == sn, "ok=%d of %d" % [snd_pitch, sn])
	_check("pressing a sound '?' changes no sound setting", snd_untouched == sn, "ok=%d of %d" % [snd_untouched, sn])

	# ---- the popup closes on Escape and leaves the panel working
	_press(panel.help_button("run_speed"))
	_check("the popup is open before closing", EdHelp.is_open(), "")
	EdHelp.hide()
	_check("hide closes it", not EdHelp.is_open(), "")
	_check("the panel is still there and visible", is_instance_valid(panel) and panel._root.visible, "")
	panel.queue_free()
	EdHelp.clear()
