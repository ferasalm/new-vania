# PROTOTYPE - NOT FOR PRODUCTION
# The pause menu. Esc, P or Start opens it (the corner button on a phone does
# the same), and the world stops while it is up. Five tabs sit across the top:
#   MAP       the current sheet's rooms and Pandora's location
#   CHARACTER her level, her stat points, and what each stat does right now
#   ITEMS     what she carries; things that can be used show USE
#   EQUIPMENT what she wears: hand, core, two torso straps, two drive slots,
#             and a live stat line that always matches the sheet
#   SYSTEM    the tuning panel, the touch layout editor, a rebuild, tuning
#             reset, resume and quit
# The rows are real buttons, so a finger works; on keys the arrows move the
# pick, left and right change the tab, jump confirms and Esc or swap goes back.
# The list scrolls when a tab has more rows than fit, and the picked row always
# scrolls into view. For menu_swallow seconds after the menu closes (tuned in
# tuning.d/ui.json) she does not run her own physics, so the press that closed
# the menu does not also swing her blade or make her jump; the world keeps
# moving and a short grace keeps anything from hitting her while she stands
# still. The locked test drives all of this with debug_rows, debug_tap and
# debug_press, so those three never move.
extends CanvasLayer

const VIEW := Vector2(384, 216)
const ROW_W := 358.0
const ROW_H := 15.0
const PauseMap := preload("res://pause_map.gd")

var TABS: Array = ["MAP", "CHARACTER", "ITEMS", "EQUIPMENT", "SYSTEM"]
var is_open := false
var tab := "CHARACTER"
var _sel := 0
var _rows: Array = []          # the current tab's rows: {text, cb}
var _row_btns: Array = []      # the row buttons, same order
var _tab_btns: Array = []
var _scroll: ScrollContainer
var _list: VBoxContainer
var _map_view: PauseMap
var _map_dev := false
var _gear_scroll: ScrollContainer
var _gear_list: VBoxContainer
var _swallow := 0.0            # seconds left of the after-close hold
var _holding := false          # the hold is on her right now
var _had_invuln := false       # she was already untouchable when the hold began
var _was := {}                 # action -> pressed a moment ago (own edge check)
const NAV := ["up", "down", "left", "right", "ui_up", "ui_down", "ui_left", "ui_right",
	"jump", "attack", "swap", "ui_accept", "ui_cancel"]


func _ready() -> void:
	layer = 45      # above the touch rig and the offline screen
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	dim.size = VIEW
	add_child(dim)
	var head := HBoxContainer.new()
	head.position = Vector2(4, 2)
	head.add_theme_constant_override("separation", 2)
	add_child(head)
	for t in TABS:
		var b := Button.new()
		b.text = String(t)
		b.custom_minimum_size = Vector2(73, 14)
		b.add_theme_font_size_override("font_size", 8)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_open_tab.bind(String(t)))
		head.add_child(b)
		_tab_btns.append(b)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(4, 18)
	_scroll.size = Vector2(376, 184)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	_map_view = PauseMap.new()
	_map_view.name = "map_view"
	_map_view.position = Vector2(4, 18)
	_map_view.size = Vector2(376, 109)
	_map_view.room_selected.connect(_select_map_room)
	add_child(_map_view)
	_gear_scroll = ScrollContainer.new()
	_gear_scroll.position = Vector2(202, 18)
	_gear_scroll.size = Vector2(178, 184)
	_gear_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_gear_scroll)
	_gear_list = VBoxContainer.new()
	_gear_scroll.add_child(_gear_list)
	var foot := Label.new()
	foot.text = "ARROWS: PICK   LEFT/RIGHT: TAB   JUMP: OK   ESC: BACK"
	foot.position = Vector2(6, 204)
	foot.add_theme_font_size_override("font_size", 6)
	foot.add_theme_color_override("font_outline_color", Color.BLACK)
	foot.add_theme_constant_override("outline_size", 2)
	foot.modulate = Color(1, 1, 1, 0.6)
	add_child(foot)


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open(tab_name: String = "") -> void:
	# open the menu (or switch its tab); the world stops while it is up
	var m = G.main
	if m != null and bool(m._busy):
		return
	if tab_name != "" and TABS.has(tab_name):
		tab = tab_name
	is_open = true
	_map_dev = false
	visible = true
	if _holding:
		_hold_end()
	_swallow = 0.0      # reopening cancels the after-close hold
	get_tree().paused = true
	Sfx.pause_music(true)
	if m != null and m.touch != null:
		m.touch._release_all()
		m.touch.paused = true
		m.touch._overlay.visible = false
	_sel = 0
	for a in NAV:
		_was[a] = true      # a key already held needs a fresh press
	_refresh()


func close() -> void:
	is_open = false
	visible = false
	Sfx.pause_music(false)
	get_tree().paused = false
	if T.data.has("menu_swallow"):
		_swallow = T.v("menu_swallow")      # the after-close hold (see _physics_process)
	if G.main != null and G.main.touch != null:
		G.main.touch.paused = false


func _physics_process(delta: float) -> void:
	# the after-close hold: for menu_swallow seconds she does not run her own
	# physics, so an attack or jump press made while the menu was closing is
	# never read, and the key that closed the menu does not also swing her
	# blade or make her jump. The world itself keeps moving; a short grace
	# keeps anything from hitting her while she stands still.
	var m = G.main
	if m == null:
		return
	if _holding:
		_swallow = maxf(0.0, _swallow - delta)
		if _swallow <= 0.0:
			_hold_end()
	elif _swallow > 0.0 and not is_open:
		_hold_start()


func _hold_start() -> void:
	var m = G.main
	if m == null:
		_swallow = 0.0
		return
	var p = m.player
	if p == null or not is_instance_valid(p):
		_swallow = 0.0
		return
	_holding = true
	p.process_mode = Node.PROCESS_MODE_DISABLED
	_had_invuln = float(p.get("invuln")) > 0.0
	if not _had_invuln:
		p.set("invuln", _swallow + 0.1)


func _hold_end() -> void:
	_holding = false
	var m = G.main
	if m == null:
		return
	var p = m.player
	if p != null and is_instance_valid(p):
		p.process_mode = Node.PROCESS_MODE_INHERIT
		if not _had_invuln:
			p.set("invuln", 0.0)


func offer_points() -> void:
	# the level-up offer: the menu opens straight on CHARACTER to spend them
	open("CHARACTER")


func debug_rows() -> Array:
	# the test hook: the row texts of the tab on screen
	var out: Array = []
	for r in _rows_for(tab):
		out.append(String(r["text"]))
	return out


func debug_tap(i: int) -> void:
	# the test hook: act like a finger on row i
	_sel = clampi(i, 0, maxi(0, _rows.size() - 1))
	_activate(_sel)


func debug_press(a: String) -> void:
	# the test hook: act like one press of a menu key
	match a:
		"tab_next":
			_tab_shift(1)
		"tab_prev":
			_tab_shift(-1)
		"up":
			_move(-1)
		"down":
			_move(1)
		"ok":
			_activate(_sel)
		"back":
			close()


func _process(delta: float) -> void:
	if not is_open:
		return
	var m = G.main
	if m != null and m.touch != null and bool(m.touch.editing):
		return      # Pause > CONTROLS owns the fingers for a while
	# own edge check (like the offline screen): a press made during a physics
	# step can fall between two drawn frames and be missed by just_pressed
	var e := {}
	for a in NAV:
		var now := Input.is_action_pressed(a)
		e[a] = now and not bool(_was.get(a, false))
		_was[a] = now
	if e["up"] or e["ui_up"]:
		_move(-1)
	if e["down"] or e["ui_down"]:
		_move(1)
	if e["left"] or e["ui_left"]:
		_tab_shift(-1)
	if e["right"] or e["ui_right"]:
		_tab_shift(1)
	if e["jump"] or e["ui_accept"] or e["attack"]:
		_activate(_sel)
	if e["swap"] or e["ui_cancel"]:
		close()


func _move(d: int) -> void:
	if _rows.is_empty():
		return
	_sel = wrapi(_sel + d, 0, _rows.size())
	_show_sel()
	Sfx.play("no_energy", 1.4)


func _tab_shift(d: int) -> void:
	tab = String(TABS[wrapi(TABS.find(tab) + d, 0, TABS.size())])
	_sel = 0
	_refresh()
	Sfx.play("no_energy", 1.4)


func _open_tab(tab_name: String) -> void:
	# a tab button was tapped or picked
	tab = tab_name
	_sel = 0
	_refresh()


func _on_row(i: int) -> void:
	_sel = i
	if _rows[i].has("slot") or _rows[i].get("cb") == null:
		_show_sel()
		return
	_activate(i)


func _activate(i: int) -> void:
	if i < 0 or i >= _rows.size():
		return
	var cb = _rows[i].get("cb")
	if cb != null and cb is Callable and (cb as Callable).is_valid():
		(cb as Callable).call()
		_refresh()
		Sfx.play("pickup", 0.8)


func _refresh() -> void:
	_rows = _rows_for(tab)
	_map_view.visible = tab == "MAP"
	_gear_scroll.visible = tab == "EQUIPMENT"
	_scroll.position.y = 130 if _map_view.visible else 18
	_scroll.size = Vector2(196 if _gear_scroll.visible else 376, 202 - _scroll.position.y)
	if _map_view.visible:
		var current := String(G.main.room_name) if G.main != null else ""
		_map_view.show_rooms(_map_ids(), current)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_row_btns = []
	for i in _rows.size():
		var b := Button.new()
		b.text = " " + String(_rows[i]["text"])
		b.custom_minimum_size = Vector2(180.0 if _gear_scroll.visible else ROW_W, ROW_H)
		b.add_theme_font_size_override("font_size", 8)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if _rows[i].get("cb") != null or _rows[i].has("slot") or _rows[i].has("room"):
			b.pressed.connect(_on_row.bind(i))
		_list.add_child(b)
		_row_btns.append(b)
	_sel = clampi(_sel, 0, maxi(0, _rows.size() - 1))
	for j in _tab_btns.size():
		_tab_btns[j].modulate = Color(1, 1, 1) if String(TABS[j]) == tab else Color(0.62, 0.62, 0.62, 0.9)
	_show_sel()


func _show_sel() -> void:
	for i in _row_btns.size():
		_row_btns[i].modulate = Color(1, 1, 1) if i == _sel else Color(0.68, 0.68, 0.68, 0.92)
	if _sel >= 0 and _sel < _row_btns.size():
		_scroll.ensure_control_visible(_row_btns[_sel])
		if tab == "MAP":
			_map_view.select_room(String(_rows[_sel].get("room", "")))
	if tab == "EQUIPMENT":
		_refresh_gear_choices()


# ---- what each tab shows ----

func _rows_for(which: String) -> Array:
	match which:
		"MAP":
			return _map_rows()
		"CHARACTER":
			return _character_rows()
		"ITEMS":
			return _item_rows()
		"EQUIPMENT":
			return _equipment_rows()
		"SYSTEM":
			return _system_rows()
	return []


func _map_rows() -> Array:
	var out: Array = []
	for room in _map_ids():
		var id := String(room)
		var title := W.title(id)
		out.append({"text": id.to_upper() + ("  " + title if title != "" else "") +
			("   [JUMP HERE]" if _map_dev else ""), "room": id,
			"cb": _teleport.bind(id) if _map_dev else null})
	if out.is_empty():
		out.append({"text": "(NO MAP YET)", "cb": null})
	if OS.is_debug_build():
		out.append({"text": "DEV   RETURN TO VISITED ROOMS" if _map_dev else "DEV   SHOW ROOMS FOR PLAYTEST",
			"cb": _toggle_map_dev})
	return out


func _map_ids() -> Array:
	var seen: Dictionary = W.visited.get(W.sheet, {})
	return W.room_list(W.sheet) if _map_dev else seen.keys()


func _toggle_map_dev() -> void:
	_map_dev = not _map_dev
	_sel = 0


func _select_map_room(id: String) -> void:
	for i in _rows.size():
		if _rows[i].get("room") == id:
			_sel = i
			_show_sel()
			return


func _teleport(id: String) -> void:
	if not OS.is_debug_build() or not _map_dev or G.main == null:
		return
	close()
	_swallow = 0.0
	Dev.teleport(id, W.sheet)


func _character_rows() -> Array:
	var out: Array = []
	out.append({"text": "LV %d   XP %d   PTS %d" % [R.level, R.xp, R.points], "cb": null})
	var shown := {"vigor": "MAX HP %d", "power": "ATK %d%%", "guard": "DEF %d%%",
		"stamina": "MAX EN %d", "magic": "MAX MP %d"}
	var live := {"vigor": int(R.max_hp()), "power": int(R.atk()), "guard": int(R.def()),
		"stamina": int(R.max_en()), "magic": int(R.max_mp())}
	for s in R.STATS:
		out.append({"text": "%s %d   %s" % [String(s).to_upper(), int(R.alloc.get(s, 0)), String(shown[s]) % int(live[s])],
			"cb": _spend.bind(String(s))})
	out.append({"text": "AUTO   SPEND ALL %d PTS" % R.points, "cb": _auto})
	return out


func _spend(stat: String) -> void:
	# one point on one stat; the sheet refuses when she has none
	R.spend(stat)


func _auto() -> void:
	R.auto_allocate()


func _item_rows() -> Array:
	# what she carries; gear lives on EQUIPMENT, so it is not listed twice
	var out: Array = []
	var gear: Dictionary = Db.table("gear")
	var items: Dictionary = Db.table("items")
	for id in R.items:
		var n := R.count(String(id))
		if n <= 0 or gear.has(String(id)):
			continue
		var d: Dictionary = items.get(String(id), {})
		var nm := String(d.get("name", String(id).to_upper()))
		var use: Dictionary = d.get("use", {})
		if use.has("heal_hp_key") or use.has("heal_mp_key"):
			out.append({"text": "%s x%d   USE" % [nm, n], "cb": _use.bind(String(id))})
		else:
			out.append({"text": "%s x%d" % [nm, n], "cb": null})
	if out.is_empty():
		out.append({"text": "(NOTHING CARRIED)", "cb": null})
	return out


func _use(id: String) -> void:
	# a Suture and friends; the sheet refuses at full health or with none left
	if not R.use_item(id):
		Sfx.play("no_energy")


func _equipment_rows() -> Array:
	# hand and core on top, then the two torso straps and the two drive slots,
	# then the stat line the way the sheet computes it right now
	var out: Array = []
	var wpn := "DIRGE-042"
	var m = G.main
	if m != null and m.player != null and m.player.has_method("weapon_name"):
		wpn = String(m.player.weapon_name())
	out.append({"text": "%-7s %s" % ["HAND", wpn], "cb": null})
	out.append({"text": "%-7s %s" % ["CORE", "RESTORE MODULE" if R.has("restore_module") else "-"], "cb": null})
	for slot in ["harness1", "harness2", "module1", "module2"]:
		var tag := "TORSO-1" if slot == "harness1" else ("TORSO-2" if slot == "harness2" \
			else ("DRIVE-1" if slot == "module1" else "DRIVE-2"))
		out.append({"text": "%-7s %s" % [tag, _slot_text(slot)], "slot": slot, "cb": _cycle_slot.bind(slot)})
	out.append({"text": "ATK %d%%  DEF %d%%  HP %d  EN %d  MP %d" % [int(R.atk()), int(R.def()),
		int(R.max_hp()), int(R.max_en()), int(R.max_mp())], "cb": null})
	return out


func _slot_text(slot: String) -> String:
	var id := String(R.equip.get(slot, ""))
	if id == "":
		return "-"
	var d: Dictionary = Db.table("gear").get(id, {})
	return String(d.get("name", id))


func _cycle_slot(slot: String) -> void:
	# tap an empty slot to fit the first piece she owns, tap again for the next
	# one, and round to empty: one tap is one step, the stat line follows
	var cands := _gear_choices(slot)
	if cands.size() <= 1:
		return      # nothing she owns fits here
	var cur := String(R.equip.get(slot, ""))
	var i := cands.find(cur)
	if i < 0:
		i = 0
	R.equip_gear(slot, String(cands[wrapi(i + 1, 0, cands.size())]))


func _gear_choices(slot: String) -> Array[String]:
	var kind := "harness" if slot.begins_with("harness") else "module"
	var choices: Array[String] = [""]
	var gear: Dictionary = Db.table("gear")
	for owned in R.owned_gear:
		var id := String(owned)
		if String(gear.get(id, {}).get("slot", "")) != kind:
			continue
		var blocked := false
		for other_slot in R.SLOTS:
			if other_slot == slot:
				continue
			var other := String(R.equip.get(other_slot, ""))
			if other == id or (R.DRIVE.has(id) and R.DRIVE.has(other)):
				blocked = true
				break
		if not blocked:
			choices.append(id)
	return choices


func _refresh_gear_choices() -> void:
	for child in _gear_list.get_children():
		_gear_list.remove_child(child)
		child.queue_free()
	var slot := String(_rows[_sel].get("slot", "")) if _sel < _rows.size() else ""
	var hint := Label.new()
	hint.text = "SELECT A TORSO OR DRIVE SLOT" if slot.is_empty() else "GEAR FOR THIS SLOT"
	hint.add_theme_font_size_override("font_size", 8)
	_gear_list.add_child(hint)
	if slot.is_empty():
		return
	for id in _gear_choices(slot):
		var button := Button.new()
		var name_text := "(EMPTY)" if id.is_empty() else String(Db.table("gear")[id].get("name", id))
		button.text = name_text + ("  [ON]" if R.equip.get(slot, "") == id else "")
		button.custom_minimum_size = Vector2(160, ROW_H)
		button.add_theme_font_size_override("font_size", 8)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose_gear.bind(slot, id))
		_gear_list.add_child(button)


func _choose_gear(slot: String, id: String) -> void:
	if R.equip_gear(slot, id):
		_refresh()


func _system_rows() -> Array:
	return [
		{"text": "TUNING PANEL   (F1)", "cb": _toggle_panel},
		{"text": "CONTROLS   (TOUCH LAYOUT)", "cb": _controls},
		{"text": "RECONSTRUCT", "cb": _rebuild},
		{"text": "RESET TUNING", "cb": T.reset},
		{"text": "RESUME", "cb": close},
		{"text": "QUIT", "cb": _quit},
	]


func _toggle_panel() -> void:
	var m = G.main
	if m != null and m.panel != null:
		m.panel._root.visible = not m.panel._root.visible


func _controls() -> void:
	# Pause > CONTROLS: the touch rig's own editor takes the screen; the menu
	# waits hidden and the world stays stopped until DONE
	var m = G.main
	if m == null or m.touch == null:
		return
	visible = false
	m.touch._edit_start()


func _rebuild() -> void:
	# a new Pandora at the last cache, same as the old pause screen's button
	var m = G.main
	if m == null or m._busy:
		return
	close()
	_swallow = 0.0
	m.reconstruct()


func _quit() -> void:
	get_tree().quit()
