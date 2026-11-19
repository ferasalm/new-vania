# PROTOTYPE - NOT FOR PRODUCTION
# F2 room builder. Edits the room she is standing in, as a plan view (solid walls, enemies,
# traps and spots as coloured cells, PNG props drawn as they are). Tab plays the room as it
# is right now from the cell under the mouse; Tab again comes back. Ctrl+S saves into the
# project's rooms/ folder (git keeps the old version).
#
#   Palette (right)     TERRAIN / ENEMIES / HAZARDS / SPOTS / TILES / PROPS / BACKDROPS;
#                       PNGs dropped into assets/editor/{tiles,props,backdrops}/ appear here
#   Left click          place (hold to paint walls and floors)     Right click  erase
#   Wheel               zoom       Middle drag or Space+drag  pan     Arrow keys  pan
#   Ctrl+Z / Ctrl+Y     undo / redo     H flip a prop     1 2 3  prop layer back / with room / front
#   Tools               PLACE, MOVE (drag things), ZONE (drag an area, then SPREAD enemies over it)
#   Tab                 play from the mouse / back to editing      N (while playing) spawn the picked enemy
extends CanvasLayer

signal closed

const RoomDoc := preload("res://editor/room_doc.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const RoomScript := preload("res://room.gd")
const PropsLayer := preload("res://editor/props_layer.gd")
const TILE := 16
const VIEW_TOP := 16.0
const PANEL_W := 108.0

var doc: RefCounted = null
var tab := "TERRAIN"
var sel: Dictionary = {}
var tool := "PLACE"
var plane := "back"
var checks: Array = []          # {rect: Rect2 in room pixels, text: String}; filled by room_checks.gd

var _cam := Vector2.ZERO
var _zoom := 1.0
var _view: Control = null
var _list: ItemList = null
var _tabs: OptionButton = null
var _status: Label = null
var _count: SpinBox = null
var _entries: Array = []
var _hover := Vector2i(-1, -1)
var _mouse := Vector2.ZERO
var _painting := false
var _erasing := false
var _panning := false
var _pan_from := Vector2.ZERO
var _cam_from := Vector2.ZERO
var _zone := Rect2i()
var _zone_on := false
var _zone_drag := false
var _drag: Dictionary = {}
var _flip_next := false
var _playing := false
var _dirty := false
var _msg := ""
var _ui: Array = []
var _theme: Theme = null
var _enemy_glyphs: Array = []
var _hazard_glyphs: Array = []
var _spot_glyphs: Array = []
var _checks_script: GDScript = null


func _ready() -> void:
	layer = 35


## info: "room" is read from G.main. Tests may pass "doc" (a RoomDoc) to skip the file loading.
func begin(info: Dictionary) -> void:
	EdAssets.ensure_folders()
	doc = info.get("doc", null)
	if doc == null:
		doc = _load_doc()
	for e in EdAssets.entries("ENEMIES"):
		_enemy_glyphs.append(e["glyph"])
	for e in EdAssets.entries("HAZARDS"):
		_hazard_glyphs.append(e["glyph"])
	for e in EdAssets.entries("SPOTS"):
		_spot_glyphs.append(e["glyph"])
	if ResourceLoader.exists("res://editor/room_checks.gd"):
		_checks_script = load("res://editor/room_checks.gd")
	_build_ui()
	_fit()
	_set_tab("TERRAIN")
	_recheck()
	_say("F2 room builder: pick something on the right and click the room. Tab plays from the mouse.")


func _load_doc() -> RefCounted:
	var id := "church"
	var m = G.main
	if m != null and m.room != null:
		id = String(m.room.file_id)
	var text := ""
	var props := ""
	var pd: String = Dev.project_dir()
	if pd != "" and FileAccess.file_exists(pd.path_join("rooms/%s.txt" % id)):
		text = FileAccess.get_file_as_string(pd.path_join("rooms/%s.txt" % id))
		if FileAccess.file_exists(pd.path_join("rooms/%s.props.json" % id)):
			props = FileAccess.get_file_as_string(pd.path_join("rooms/%s.props.json" % id))
	else:
		text = FileAccess.get_file_as_string("res://rooms/%s.txt" % id)
		if FileAccess.file_exists("res://rooms/%s.props.json" % id):
			props = FileAccess.get_file_as_string("res://rooms/%s.props.json" % id)
	return RoomDoc.parse(id, text, props)


# ---------- ui ----------

func _make_theme() -> Theme:
	var t := Theme.new()
	for cls in ["Button", "OptionButton", "Label", "ItemList", "SpinBox", "LineEdit", "CheckButton"]:
		t.set_font_size("font_size", cls, 7)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": Color(0.16, 0.16, 0.24), "hover": Color(0.26, 0.26, 0.4), "pressed": Color(0.5, 0.3, 0.3),
			"focus": Color(0.16, 0.16, 0.24), "disabled": Color(0.1, 0.1, 0.14)}[st]
		sb.content_margin_left = 3.0
		sb.content_margin_right = 3.0
		sb.content_margin_top = 1.0
		sb.content_margin_bottom = 1.0
		t.set_stylebox(st, "Button", sb)
		t.set_stylebox(st, "OptionButton", sb)
	t.set_color("font_color", "Label", Color(0.9, 0.9, 0.95))
	t.set_constant("v_separation", "ItemList", 0)
	t.set_constant("line_separation", "ItemList", 0)
	t.set_constant("h_separation", "ItemList", 1)
	return t


func _build_ui() -> void:
	_theme = _make_theme()
	var vp := Vector2(384, 216)
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.focus_mode = Control.FOCUS_NONE
	_view.draw.connect(_on_draw)
	_view.gui_input.connect(_on_view_input)
	add_child(_view)
	# toolbar
	var bar := HBoxContainer.new()
	bar.theme = _theme
	bar.position = Vector2(1, 1)
	bar.add_theme_constant_override("separation", 1)
	add_child(bar)
	_ui.append(bar)
	for t in ["PLACE", "MOVE", "ZONE"]:
		var b := _btn(bar, t, func() -> void: _set_tool(t))
		b.tooltip_text = "tool"
	_sep(bar)
	_btn(bar, "UNDO", func() -> void: _undo())
	_btn(bar, "REDO", func() -> void: _redo())
	_btn(bar, "SAVE", func() -> void: save())
	_btn(bar, "PLAY", func() -> void: play())
	_btn(bar, "CHECK", func() -> void: run_full_check())
	_sep(bar)
	_btn(bar, "W+", func() -> void: _resize(1, 0))
	_btn(bar, "W-", func() -> void: _resize(-1, 0))
	_btn(bar, "H+", func() -> void: _resize(0, 1))
	_btn(bar, "H-", func() -> void: _resize(0, -1))
	_sep(bar)
	var hit := _btn(bar, "HIT", func() -> void: T.set_v("show_hitboxes", 0.0 if T.v("show_hitboxes") >= 0.5 else 1.0))
	hit.toggle_mode = true
	hit.button_pressed = T.v("show_hitboxes") >= 0.5
	var god := _btn(bar, "GOD", func() -> void: Dev.god = not Dev.god)
	god.toggle_mode = true
	god.button_pressed = Dev.god
	var slow := _btn(bar, "SLOW", func() -> void: Engine.time_scale = 0.5 if Engine.time_scale == 1.0 else 1.0)
	slow.toggle_mode = true
	slow.button_pressed = Engine.time_scale < 1.0
	# palette
	var panel := PanelContainer.new()
	panel.theme = _theme
	panel.position = Vector2(vp.x - PANEL_W, VIEW_TOP)
	panel.custom_minimum_size = Vector2(PANEL_W, vp.y - VIEW_TOP)
	panel.size = Vector2(PANEL_W, vp.y - VIEW_TOP)
	panel.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.96)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	_ui.append(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	panel.add_child(vb)
	_tabs = OptionButton.new()
	for t in EdAssets.TABS:
		_tabs.add_item(t)
	_tabs.item_selected.connect(func(i: int) -> void: _set_tab(EdAssets.TABS[i]))
	vb.add_child(_tabs)
	_list = ItemList.new()
	_list.select_mode = ItemList.SELECT_MULTI
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.fixed_icon_size = Vector2i(9, 9)
	_list.custom_minimum_size = Vector2(0, 30)
	_list.clip_contents = true
	_list.same_column_width = true
	_list.multi_selected.connect(_on_pick)
	vb.add_child(_list)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var lb := Label.new()
	lb.text = "COUNT"
	row.add_child(lb)
	_count = SpinBox.new()
	_count.min_value = 1
	_count.max_value = 40
	_count.value = 4
	_count.custom_minimum_size = Vector2(34, 0)
	row.add_child(_count)
	_btn(vb, "SPREAD OVER ZONE", func() -> void: spread_zone())
	_status = Label.new()
	_status.position = Vector2(2, vp.y - 11)
	_status.custom_minimum_size = Vector2(vp.x - PANEL_W - 4.0, 0.0)
	_status.size = Vector2(vp.x - PANEL_W - 4.0, 9.0)
	_status.clip_text = true
	_status.theme = _theme
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 3)
	add_child(_status)
	_ui.append(_status)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _sep(parent: Control) -> void:
	var l := Label.new()
	l.text = "|"
	parent.add_child(l)


func _say(text: String) -> void:
	_msg = text
	_update_status()


func _update_status() -> void:
	if _status == null or doc == null:
		return
	var cell := "-"
	if _hover.x >= 0:
		cell = "%d,%d '%s'" % [_hover.x, _hover.y, doc.get_cell(_hover.x, _hover.y)]
	var w: int = doc.width()
	var h: int = doc.height()
	var tip := ""
	if _in_view(_mouse):
		var mw := _to_world(_mouse)
		for ck in checks:
			if ck["rect"].has_point(mw):
				tip = String(ck["text"])
	_status.text = "%s%s %dx%d  cell %s  %s  layer %s%s  | %s" % [doc.file_id, "*" if _dirty else "", w, h, cell, tool, plane,
		"  flip" if _flip_next else "", ("RED: %s" % tip) if tip != "" else (("%d red | %s" % [checks.size(), _msg]) if not checks.is_empty() else _msg)]


func _set_ui_visible(v: bool) -> void:
	for n in _ui:
		n.visible = v
	if _view != null:
		_view.visible = v


func _fit() -> void:
	var rs: Vector2 = doc.pixel_size()
	_zoom = clampf(minf((384.0 - PANEL_W - 6.0) / maxf(rs.x, 1.0), (216.0 - VIEW_TOP - 14.0) / maxf(rs.y, 1.0)), 0.25, 4.0)
	_cam = Vector2(-3.0, -3.0) / _zoom


func _set_tool(t: String) -> void:
	tool = t
	_zone_on = tool == "ZONE" and _zone_on
	_update_status()
	_view.queue_redraw()


func _set_tab(t: String) -> void:
	tab = t
	var idx := EdAssets.TABS.find(t)
	if _tabs != null and idx >= 0 and _tabs.selected != idx:
		_tabs.select(idx)
	_entries = EdAssets.entries(t)
	_list.clear()
	for e in _entries:
		var label := String(e["name"])
		if e.has("glyph"):
			label = "%s  %s" % [e["glyph"], label]
		var tex: Texture2D = EdAssets.texture(String(e.get("png", ""))) if e.has("png") else null
		_list.add_item(label, tex)
	sel = {}
	if not _entries.is_empty():
		_list.select(0)
		sel = _entries[0]
	if t == "TILES":
		plane = "solid"
	elif t == "PROPS" and plane == "solid":
		plane = "back"
	_update_status()


func _on_pick(index: int, selected: bool) -> void:
	if selected and index >= 0 and index < _entries.size():
		sel = _entries[index]
		if tool == "MOVE":
			_set_tool("PLACE")
		_update_status()


# ---------- coordinates ----------

func _to_world(p: Vector2) -> Vector2:
	return _cam + (p - Vector2(0, VIEW_TOP)) / _zoom


func _to_screen(w: Vector2) -> Vector2:
	return (w - _cam) * _zoom + Vector2(0, VIEW_TOP)


func _cell_of(w: Vector2) -> Vector2i:
	return Vector2i(int(floorf(w.x / TILE)), int(floorf(w.y / TILE)))


func _zoom_at(p: Vector2, f: float) -> void:
	var before := _to_world(p)
	_zoom = clampf(_zoom * f, 0.25, 8.0)
	_cam += before - _to_world(p)
	_view.queue_redraw()


# ---------- editing ----------

func _changed() -> void:
	_dirty = true
	_recheck()
	_update_status()
	if _view != null:
		_view.queue_redraw()


func _recheck() -> void:
	# the quick checks run after every edit; the reach search runs on CHECK and on save
	checks = []
	if _checks_script != null and doc != null:
		checks = _checks_script.new().run(doc)


## The full check, with the can-she-get-there search (a second or two on a big room).
func run_full_check() -> void:
	if _checks_script == null or doc == null:
		return
	_say("checking...")
	checks = _checks_script.new().run(doc, true)
	if checks.is_empty():
		_say("no red warnings: every exit and item can be reached")
	else:
		_say("%d red warning(s): read the labels in the room" % checks.size())
	if _view != null:
		_view.queue_redraw()


func _undo() -> void:
	if doc.undo():
		_changed()
		_say("undo")


func _redo() -> void:
	if doc.redo():
		_changed()
		_say("redo")


func _resize(dw: int, dh: int) -> void:
	var cell_step := Input.is_key_pressed(KEY_SHIFT)      # Shift: a whole map cell (24 x 14 tiles)
	var w: int = doc.width() + dw * (24 if cell_step else 1)
	var h: int = doc.height() + dh * (14 if cell_step else 1)
	doc.push_undo()
	doc.resize(w, h)
	_changed()
	_say("room is now %dx%d tiles (the map cell size in F3 is not changed)" % [doc.width(), doc.height()])


func _paint(c: Vector2i) -> void:
	if not sel.has("glyph") or not doc.in_room(c.x, c.y):
		return
	var g := String(sel["glyph"])
	if g == "P":
		for y in doc.height():
			for x in doc.width():
				if doc.get_cell(x, y) == "P":
					doc.set_cell(x, y, ".")
	if doc.set_cell(c.x, c.y, g):
		_changed()


func _erase_at(w: Vector2) -> void:
	var i: int = doc.prop_at(w, Callable(EdAssets, "size_of"))
	if i >= 0:
		var p: Dictionary = doc.props[i]
		if bool(p.get("tile", false)) and String(p.get("layer", "")) == "solid":
			for c in _tile_cells(p):
				if doc.get_cell(c.x, c.y) == "#":
					doc.set_cell(c.x, c.y, ".")
		doc.props.remove_at(i)
		_changed()
		return
	var c := _cell_of(w)
	if doc.in_room(c.x, c.y) and doc.set_cell(c.x, c.y, "."):
		_changed()


func _tile_cells(p: Dictionary) -> Array:
	var s: Vector2 = EdAssets.size_of(String(p["png"]))
	var out: Array = []
	var c0 := Vector2i(int(p["x"]) / TILE, int(p["y"]) / TILE)
	for y in int(ceil(s.y / TILE)):
		for x in int(ceil(s.x / TILE)):
			out.append(Vector2i(c0.x + x, c0.y + y))
	return out


func _place_picture(w: Vector2) -> void:
	var rel := String(sel.get("png", ""))
	if tab == "BACKDROPS":
		doc.push_undo()
		if rel == "":
			doc.head.erase("backdrop")
			_say("backdrop removed (the theme's own wall is back)")
		else:
			doc.head["backdrop"] = rel.get_file()
			_say("backdrop is now %s (tiles at its real size)" % rel.get_file())
		_changed()
		return
	if rel == "":
		return
	var s: Vector2 = EdAssets.size_of(rel)
	doc.push_undo()
	if tab == "TILES":
		var c := _cell_of(w)
		var p: Dictionary = doc.add_prop(rel, c.x * TILE, c.y * TILE, plane, true, _flip_next)
		if plane == "solid":
			for q in _tile_cells(p):
				doc.set_cell(q.x, q.y, "#")
	else:
		var pos := ((w - s * 0.5) / 8.0).round() * 8.0
		doc.add_prop(rel, int(pos.x), int(pos.y), plane, false, _flip_next)
	_changed()


func _pick_for_move(w: Vector2) -> void:
	var i: int = doc.prop_at(w, Callable(EdAssets, "size_of"))
	doc.push_undo()
	if i >= 0:
		var p: Dictionary = doc.props[i]
		_drag = {"prop": i, "off": w - Vector2(p["x"], p["y"])}
		return
	var c := _cell_of(w)
	var g: String = doc.get_cell(c.x, c.y)
	if g != "." and g != "#" and g != "=" and g != "":
		_drag = {"glyph": g, "from": c}
	else:
		_drag = {}


func _drop_move(w: Vector2) -> void:
	if _drag.is_empty():
		return
	if _drag.has("glyph"):
		var c := _cell_of(w)
		if doc.in_room(c.x, c.y) and doc.get_cell(c.x, c.y) == "." and c != _drag["from"]:
			doc.set_cell(_drag["from"].x, _drag["from"].y, ".")
			doc.set_cell(c.x, c.y, String(_drag["glyph"]))
	_drag = {}
	_changed()


func spread_zone() -> void:
	if not _zone_on:
		_say("ZONE tool first: drag an area in the room")
		return
	var glyphs: Array = []
	if tab == "ENEMIES":
		for i in _list.get_selected_items():
			glyphs.append(String(_entries[i]["glyph"]))
	if glyphs.is_empty():
		_say("open the ENEMIES tab and pick the kinds (Ctrl+click for several)")
		return
	var want := int(_count.value)
	doc.push_undo()
	var placed: int = doc.spread(_zone, glyphs, want)
	_changed()
	if placed == want:
		_say("placed %d enemies" % placed)
	else:
		_say("placed %d of %d: not enough standing room in that zone" % [placed, want])


func save() -> bool:
	var pd: String = Dev.project_dir()
	if pd == "":
		_say("cannot find the project folder, nothing saved")
		return false
	var path := pd.path_join("rooms/%s.txt" % doc.file_id)
	if FileAccess.file_exists(path):
		# a copy of what is there, outside the project, before it is replaced
		var bdir := ProjectSettings.globalize_path("user://room_backups")
		DirAccess.make_dir_recursive_absolute(bdir)
		var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
		var old := FileAccess.get_file_as_string(path)
		var bf := FileAccess.open(bdir.path_join("%s_%s.txt" % [doc.file_id, stamp]), FileAccess.WRITE)
		if bf != null:
			bf.store_string(old)
			bf.close()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_say("could not write " + path)
		return false
	f.store_string(doc.to_text())
	f.close()
	var ppath := pd.path_join("rooms/%s.props.json" % doc.file_id)
	if not doc.props.is_empty() or FileAccess.file_exists(ppath):
		var pf := FileAccess.open(ppath, FileAccess.WRITE)
		if pf != null:
			pf.store_string(doc.props_text())
			pf.close()
	_dirty = false
	_update_status()
	run_full_check()
	_say("saved rooms/%s.txt (git keeps the old one); %d red warning(s)" % [doc.file_id, checks.size()])
	return true


# ---------- playing ----------

## Play the room as it is now, from the cell under the mouse (or where she stands).
func play() -> void:
	var m = G.main
	if m == null or m.player == null or _playing:
		return
	RoomScript.override[doc.file_id] = doc.to_text()
	PropsLayer.override[doc.file_id] = doc.props_text()
	var feet := Vector2.ZERO
	var use_cursor: bool = _hover.x >= 0 and doc.in_room(_hover.x, _hover.y)
	if use_cursor:
		feet = Vector2((_hover.x + 0.5) * TILE, (_hover.y + 1) * TILE - 0.5)
	var p = m.player
	var hp0: float = p.hp
	_playing = true
	_set_ui_visible(false)
	get_tree().paused = false
	await m.debug_enter(m.room_name, "left", G.shifted)
	for i in 3:
		await get_tree().physics_frame
	p = m.player
	if use_cursor and p != null:
		p.global_position = feet
		p.velocity = Vector2.ZERO
	if p != null:
		p.hp = clampf(maxf(hp0, 1.0), 1.0, R.max_hp())


func edit_again() -> void:
	if not _playing:
		return
	_playing = false
	get_tree().paused = true
	_set_ui_visible(true)
	_say("back in the builder")
	_view.queue_redraw()


func spawn_picked() -> void:
	var m = G.main
	if m == null or m.player == null or not sel.has("glyph") or tab != "ENEMIES":
		return
	var id := String(sel["name"])
	var at: Vector2 = m.player.global_position + Vector2(40.0 * m.player.facing, -4.0)
	var en = m.spawner.enemy(id, at)
	if en != null:
		m.world.add_child(en)


# ---------- input ----------

func _in_view(p: Vector2) -> bool:
	return p.x < 384.0 - PANEL_W and p.y > VIEW_TOP


func _input(ev: InputEvent) -> void:
	var kev := ev as InputEventKey
	if kev == null or not kev.pressed or kev.echo:
		return
	var k: int = kev.physical_keycode
	if k == KEY_TAB:
		get_viewport().set_input_as_handled()
		if _playing:
			edit_again()
		else:
			play()
		return
	if _playing:
		if k == KEY_N:
			spawn_picked()
		return
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	if kev.ctrl_pressed:
		if k == KEY_S:
			save()
		elif k == KEY_Z:
			if kev.shift_pressed:
				_redo()
			else:
				_undo()
		elif k == KEY_Y:
			_redo()
		return
	if typing:
		return
	match k:
		KEY_H:
			_flip_next = not _flip_next
			var i: int = doc.prop_at(_to_world(_mouse), Callable(EdAssets, "size_of")) if _in_view(_mouse) else -1
			if i >= 0:
				doc.push_undo()
				doc.props[i]["flip"] = not bool(doc.props[i].get("flip", false))
				_changed()
			_update_status()
		KEY_1:
			plane = "back"
			_update_status()
		KEY_2:
			plane = "solid"
			_update_status()
		KEY_3:
			plane = "front"
			_update_status()
		KEY_DELETE:
			if _in_view(_mouse):
				doc.push_undo()
				_erase_at(_to_world(_mouse))
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			var d := Vector2(float(k == KEY_RIGHT) - float(k == KEY_LEFT), float(k == KEY_DOWN) - float(k == KEY_UP))
			_cam += d * 48.0 / _zoom
			_view.queue_redraw()


func _on_view_input(ev: InputEvent) -> void:
	if doc == null or _playing:
		return
	if ev is InputEventMouseMotion:
		_mouse = ev.position
		var w := _to_world(_mouse)
		_hover = _cell_of(w) if doc.in_room(_cell_of(w).x, _cell_of(w).y) else Vector2i(-1, -1)
		if _panning:
			_cam = _cam_from - (ev.position - _pan_from) / _zoom
		elif _painting and tool == "PLACE" and sel.has("glyph") and _hover.x >= 0:
			_paint(_hover)
		elif _erasing:
			_erase_at(w)
		elif _zone_drag:
			_zone = _zone_from_cells(_zone_start, _cell_of(w))
		elif not _drag.is_empty():
			if _drag.has("prop"):
				var p: Dictionary = doc.props[_drag["prop"]]
				var np: Vector2 = ((w - _drag["off"]) / 8.0).round() * 8.0
				p["x"] = int(np.x)
				p["y"] = int(np.y)
		_update_status()
		_view.queue_redraw()
	elif ev is InputEventMouseButton:
		var w2 := _to_world(ev.position)
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_zoom_at(ev.position, 1.15)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_zoom_at(ev.position, 1.0 / 1.15)
		elif ev.button_index == MOUSE_BUTTON_MIDDLE or (ev.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE)):
			_panning = ev.pressed
			_pan_from = ev.position
			_cam_from = _cam
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				match tool:
					"PLACE":
						if sel.has("glyph"):
							doc.push_undo()
							_painting = true
							if _hover.x >= 0:
								_paint(_hover)
						else:
							_place_picture(w2)
					"MOVE":
						_pick_for_move(w2)
					"ZONE":
						_zone_start = _cell_of(w2)
						_zone = _zone_from_cells(_zone_start, _zone_start)
						_zone_drag = true
						_zone_on = true
			else:
				_painting = false
				if _zone_drag:
					_zone_drag = false
				if not _drag.is_empty():
					_drop_move(w2)
		elif ev.button_index == MOUSE_BUTTON_RIGHT:
			if ev.pressed:
				doc.push_undo()
				_erasing = true
				_erase_at(w2)
			else:
				_erasing = false
		_view.queue_redraw()


var _zone_start := Vector2i.ZERO


func _zone_from_cells(a: Vector2i, b: Vector2i) -> Rect2i:
	var lo := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var hi := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


# ---------- drawing ----------

func _glyph_color(ch: String) -> Color:
	if ch in _enemy_glyphs:
		return Color(0.85, 0.2, 0.2)
	if ch in _hazard_glyphs:
		return Color(0.95, 0.55, 0.1)
	match ch:
		"#":
			return Color(0.36, 0.36, 0.52)
		"=":
			return Color(0.55, 0.55, 0.8)
		"B":
			return Color(0.5, 0.3, 0.22)
		"|":
			return Color(0.5, 0.5, 0.5)
		"%":
			return Color(0.45, 0.4, 0.34)
		":":
			return Color(0.25, 0.6, 0.6)
		"^", "v", "<", ">":
			return Color(0.6, 0.3, 0.8)
		"D", "X":
			return Color(0.9, 0.8, 0.2)
		"P":
			return Color(0.2, 0.8, 0.3)
	if ch in _spot_glyphs:
		return Color(0.2, 0.7, 0.8)
	return Color(0.7, 0.7, 0.7)


func _on_draw() -> void:
	if doc == null:
		return
	var s := _view.size
	var font := ThemeDB.fallback_font
	_view.draw_rect(Rect2(Vector2.ZERO, s), Color(0.05, 0.05, 0.08))
	var rs: Vector2 = doc.pixel_size()
	var top_left := _to_screen(Vector2.ZERO)
	_view.draw_rect(Rect2(top_left, rs * _zoom), Color(0.1, 0.1, 0.16))
	# the backdrop, faint, at its real size from the left edge up from the floor
	var bd := String(doc.head.get("backdrop", ""))
	if bd != "":
		var bt := EdAssets.texture("backdrops/" + bd)
		if bt != null:
			var bs := bt.get_size()
			var x := 0.0
			while x < rs.x:
				_view.draw_texture_rect(bt, Rect2(_to_screen(Vector2(x, rs.y - bs.y)), bs * _zoom), false, Color(1, 1, 1, 0.35))
				x += bs.x
	var cw := TILE * _zoom
	var w: int = doc.width()
	var h: int = doc.height()
	var x0 := maxi(0, int(floorf(_cam.x / TILE)))
	var x1 := mini(w, int(ceilf((_cam.x + s.x / _zoom) / TILE)))
	var y0 := maxi(0, int(floorf(_cam.y / TILE)))
	var y1 := mini(h, int(ceilf((_cam.y + s.y / _zoom) / TILE)))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var ch: String = doc.get_cell(x, y)
			if ch == ".":
				continue
			var r := Rect2(_to_screen(Vector2(x * TILE, y * TILE)), Vector2(cw, cw))
			var c := _glyph_color(ch)
			if ch == "=":
				_view.draw_rect(Rect2(r.position, Vector2(cw, maxf(1.0, cw * 0.4))), c)
			elif ch == "#":
				_view.draw_rect(r, c)
			else:
				_view.draw_rect(r, Color(c.r, c.g, c.b, 0.85))
				if cw >= 7.0:
					_view.draw_string(font, r.position + Vector2(0, cw * 0.82), ch, HORIZONTAL_ALIGNMENT_CENTER, cw,
						maxi(5, int(cw * 0.75)), Color.WHITE)
	# PNG props and tiles as they are
	for p in doc.props:
		var tex := EdAssets.texture(String(p["png"]))
		var ps := Vector2(p["x"], p["y"])
		var rect := Rect2(_to_screen(ps), (tex.get_size() if tex != null else Vector2(TILE, TILE)) * _zoom)
		var tint := Color(1, 1, 1, 1.0 if String(p.get("layer", "back")) != "front" else 0.8)
		if tex != null:
			if bool(p.get("flip", false)):
				rect = Rect2(rect.position + Vector2(rect.size.x, 0), Vector2(-rect.size.x, rect.size.y))
			_view.draw_texture_rect(tex, rect, false, tint)
		else:
			_view.draw_rect(rect, Color(1, 0, 1, 0.5), false, 1.0)
		var lay := String(p.get("layer", "back"))
		_view.draw_rect(Rect2(_to_screen(ps), Vector2(2.0, 2.0)), {"back": Color(0.4, 0.6, 1), "solid": Color(1, 1, 0.3), "front": Color(1, 0.5, 0.5)}.get(lay, Color.WHITE))
	# grid
	if cw >= 5.0:
		var gc := Color(1, 1, 1, 0.07)
		for x in range(x0, x1 + 1):
			var a := _to_screen(Vector2(x * TILE, 0))
			_view.draw_line(a, Vector2(a.x, _to_screen(Vector2(0, h * TILE)).y), gc, 1.0)
		for y in range(y0, y1 + 1):
			var b := _to_screen(Vector2(0, y * TILE))
			_view.draw_line(b, Vector2(_to_screen(Vector2(w * TILE, 0)).x, b.y), gc, 1.0)
	_view.draw_rect(Rect2(top_left, rs * _zoom), Color(0.7, 0.7, 0.9, 0.6), false, 1.0)
	# red warnings (room_checks.gd)
	for ck in checks:
		var cr: Rect2 = ck["rect"]
		var sr := Rect2(_to_screen(cr.position), cr.size * _zoom)
		_view.draw_rect(sr, Color(1, 0.1, 0.1, 0.25), true)
		_view.draw_rect(sr, Color(1, 0.15, 0.15), false, 1.0)
		if _zoom >= 0.6:
			_view.draw_string(font, sr.position + Vector2(1, -1), String(ck["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 0.5, 0.5))
	# the zone
	if _zone_on:
		var zr := Rect2(_to_screen(Vector2(_zone.position) * TILE), Vector2(_zone.size) * cw)
		_view.draw_rect(zr, Color(0.3, 0.8, 1.0, 0.18), true)
		_view.draw_rect(zr, Color(0.3, 0.8, 1.0), false, 1.0)
	# the cell under the mouse, with what a click would put there
	if _hover.x >= 0 and tool == "PLACE" and _in_view(_mouse):
		var hr := Rect2(_to_screen(Vector2(_hover) * TILE), Vector2(cw, cw))
		_view.draw_rect(hr, Color(1, 1, 1, 0.9), false, 1.0)
		if sel.has("glyph") and cw >= 7.0:
			_view.draw_string(font, hr.position + Vector2(0, cw * 0.82), String(sel["glyph"]), HORIZONTAL_ALIGNMENT_CENTER, cw,
				maxi(5, int(cw * 0.75)), Color(1, 1, 1, 0.7))
		elif sel.has("png") and sel["png"] != "" and tab != "BACKDROPS":
			var tex2 := EdAssets.texture(String(sel["png"]))
			if tex2 != null:
				var sz := tex2.get_size() * _zoom
				var at := hr.position if tab == "TILES" else _to_screen(((_to_world(_mouse) - tex2.get_size() * 0.5) / 8.0).round() * 8.0)
				_view.draw_texture_rect(tex2, Rect2(at, sz), false, Color(1, 1, 1, 0.55))


func _exit_tree() -> void:
	# the unsaved copy must not outlive the builder
	if doc != null:
		RoomScript.override.erase(doc.file_id)
		PropsLayer.override.erase(doc.file_id)
	Engine.time_scale = 1.0
