# PROTOTYPE - NOT FOR PRODUCTION
# F3 map builder: every room as a box on the map (data/rooms_meta.json, one page at a time).
#   drag a box = move it, drag its bottom-right corner = resize, right/middle drag or arrows = pan, wheel = zoom
#   Alt+arrows move the picked room, Shift+arrows resize it, Ctrl+Z undo, Ctrl+S saves
#   Enter = open the picked room in the room builder (F2), T = jump into the picked room and play
# Red = two rooms overlap, an exit that leads nowhere, or a door nobody answers on the other side.
# Only each room's four "cell" numbers are written (see meta_patch.gd); exits are shown, not edited.
extends CanvasLayer

signal closed

const RoomDoc := preload("res://editor/room_doc.gd")
const MetaPatch := preload("res://editor/meta_patch.gd")
const SHEETS := ["before", "after", "restored"]
const TOP := 16.0
const BOTTOM := 12.0

var sheet := "before"
var picked := ""                 # room id
var warnings: Array = []         # {id, text}
var data: Dictionary = {}        # the parsed rooms_meta.json (edited in place)

var _orig: Dictionary = {}       # the same, as loaded (to see what changed)
var _text := ""                  # the file text as loaded
var _view: Control = null
var _status: Label = null
var _theme: Theme = null
var _cam := Vector2.ZERO         # map cell at the top left of the view
var _zoom := 6.0                 # screen pixels (of 384x216) per map cell
var _drag := ""                  # "" | "move" | "size" | "pan"
var _drag_from := Vector2.ZERO
var _drag_cell := Vector2i.ZERO
var _drag_start: Array = []
var _cam_from := Vector2.ZERO
var _undo: Array = []            # [[sheet, id, cell], ...]
var _msg := ""
var _ui: Array = []


func _ready() -> void:
	layer = 101


func begin(info: Dictionary) -> void:
	_theme = _make_theme()
	_load()
	var room := String(info.get("room", ""))
	if info.has("sheet") and SHEETS.has(String(info["sheet"])):
		sheet = String(info["sheet"])
	elif W.sheet != "" and SHEETS.has(String(W.sheet)):
		sheet = String(W.sheet)
	if _rooms().has(room):
		picked = room
	_build_ui()
	_fit()
	_recheck()
	_say("F3 map: drag a room to move it, Enter opens it in F2, T jumps into it.")


# ---------- data ----------

func _meta_path() -> String:
	var pd: String = Dev.project_dir()
	if pd != "" and FileAccess.file_exists(pd.path_join("data/rooms_meta.json")):
		return pd.path_join("data/rooms_meta.json")
	return "res://data/rooms_meta.json"


func _load() -> void:
	_text = FileAccess.get_file_as_string(_meta_path())
	data = JSON.parse_string(_text)
	_orig = data.duplicate(true)


## id -> the room's dictionary, for the page shown. "restored" is its base page plus the rooms it adds.
func _rooms(which := "") -> Dictionary:
	if which == "":
		which = sheet
	var sheets: Dictionary = data.get("sheets", {})
	var page: Dictionary = sheets.get(which, {})
	if which != "restored":
		return page
	var out: Dictionary = {}
	var base: Dictionary = sheets.get(String(page.get("base", "before")), {})
	for k in base:
		out[k] = base[k]
	for k in page.get("add", {}):
		out[k] = page["add"][k]
	return out


## The page a room is stored on (the restored page keeps only the rooms it adds).
func _home(id: String) -> String:
	if sheet == "restored" and data["sheets"]["restored"].get("add", {}).has(id):
		return "restored"
	return "before" if sheet == "restored" else sheet


func _stored(home: String, id: String) -> Dictionary:
	if home == "restored":
		return data["sheets"]["restored"]["add"][id]
	return data["sheets"][home][id]


func _orig_cell(home: String, id: String) -> Array:
	if home == "restored":
		return _orig["sheets"]["restored"]["add"][id]["cell"]
	return _orig["sheets"][home][id]["cell"]


func _rect(id: String) -> Rect2:
	var c: Array = _rooms()[id]["cell"]
	return Rect2(float(c[0]), float(c[1]), float(c[2]), float(c[3]))


func is_dirty() -> bool:
	return not changed_rooms().is_empty()


## [[home page, id, cell], ...] of the rooms whose cell is not what the file says.
func changed_rooms() -> Array:
	var out: Array = []
	var sheets: Dictionary = data.get("sheets", {})
	for home in sheets:
		var rooms: Dictionary = sheets[home].get("add", {}) if home == "restored" else sheets[home]
		for id in rooms:
			if rooms[id] is Dictionary and rooms[id].has("cell") and rooms[id]["cell"] != _orig_cell(home, id):
				out.append([home, id, rooms[id]["cell"]])
	return out


func _recheck() -> void:
	warnings.clear()
	var rooms := _rooms()
	var ids: Array = rooms.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			if _rect(ids[i]).intersects(_rect(ids[j])):
				warnings.append({"id": ids[i], "text": "%s overlaps %s" % [ids[i], ids[j]]})
				warnings.append({"id": ids[j], "text": "%s overlaps %s" % [ids[j], ids[i]]})
	for id in ids:
		for ex in rooms[id].get("exits", []):
			var to := String(ex.get("to", ""))
			var kind := String(ex.get("kind", ""))
			if to == "":
				if kind != "bricked":
					warnings.append({"id": id, "text": "%s: an exit (%s) leads nowhere" % [id, kind]})
			elif not rooms.has(to):
				warnings.append({"id": id, "text": "%s: exit leads to '%s', which is not on this page" % [id, to]})
			elif kind == "door":
				var back := false
				for ex2 in rooms[to].get("exits", []):
					if String(ex2.get("to", "")) == id:
						back = true
				if not back:
					warnings.append({"id": id, "text": "%s: door to %s, but %s has no door back" % [id, to, to]})
	if _view != null:
		_view.queue_redraw()
	_update_status()


# ---------- editing (also used by the tests) ----------

func select(id: String) -> void:
	picked = id if _rooms().has(id) else ""
	_update_status()
	if _view != null:
		_view.queue_redraw()


func set_sheet(which: String) -> void:
	if not SHEETS.has(which) or not data["sheets"].has(which):
		return
	sheet = which
	if not _rooms().has(picked):
		picked = ""
	_fit()
	_recheck()


## Move the picked room by whole map cells.
func nudge(dx: int, dy: int) -> bool:
	return _edit(dx, dy, 0, 0)


## Grow or shrink the picked room by whole map cells (never below 1x1).
func resize_by(dw: int, dh: int) -> bool:
	return _edit(0, 0, dw, dh)


func _edit(dx: int, dy: int, dw: int, dh: int) -> bool:
	if picked == "":
		return false
	var home := _home(picked)
	if sheet == "restored" and home != "restored":
		_say("%s belongs to the BEFORE page: change it there." % picked)
		return false
	var cell: Array = _stored(home, picked)["cell"]
	var n := [maxi(0, int(cell[0]) + dx), maxi(0, int(cell[1]) + dy), maxi(1, int(cell[2]) + dw), maxi(1, int(cell[3]) + dh)]
	if n == cell:
		return false
	_undo.append([home, picked, cell.duplicate()])
	_stored(home, picked)["cell"] = n
	_recheck()
	return true


func undo() -> void:
	if _undo.is_empty():
		return
	var u: Array = _undo.pop_back()
	_stored(String(u[0]), String(u[1]))["cell"] = u[2]
	_recheck()


## Write the changed cells into rooms_meta.json (text patch). Returns true when it saved.
func save() -> bool:
	var ch := changed_rooms()
	if ch.is_empty():
		_say("Nothing changed.")
		return true
	var t := _text
	for c in ch:
		t = MetaPatch.set_cell(t, String(c[0]), String(c[1]), c[2])
		if t == "":
			_say("Could not find %s in the file: nothing saved." % c[1])
			return false
	var path := _meta_path()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_say("Could not write %s" % path)
		return false
	f.store_string(t)
	f.close()
	_text = t
	_orig = data.duplicate(true)
	# the running game reads the same table: keep it in step so the menu map and jumps agree
	var live: Dictionary = Db.table("rooms_meta")
	for c in ch:
		var rooms: Dictionary = live.get("sheets", {}).get(String(c[0]), {})
		if String(c[0]) == "restored":
			rooms = rooms.get("add", {})
		if rooms.has(String(c[1])):
			rooms[String(c[1])]["cell"] = (c[2] as Array).duplicate()
	_undo.clear()
	_say("Saved %d room(s) to %s" % [ch.size(), path.get_file()])
	_recheck()
	return true


## Open the picked room in the room builder (F2).
func open_in_room_builder() -> void:
	if picked == "":
		return
	var pd: String = Dev.project_dir()
	var text := ""
	var props := ""
	if pd != "" and FileAccess.file_exists(pd.path_join("rooms/%s.txt" % picked)):
		text = FileAccess.get_file_as_string(pd.path_join("rooms/%s.txt" % picked))
		if FileAccess.file_exists(pd.path_join("rooms/%s.props.json" % picked)):
			props = FileAccess.get_file_as_string(pd.path_join("rooms/%s.props.json" % picked))
	elif FileAccess.file_exists("res://rooms/%s.txt" % picked):
		text = FileAccess.get_file_as_string("res://rooms/%s.txt" % picked)
		if FileAccess.file_exists("res://rooms/%s.props.json" % picked):
			props = FileAccess.get_file_as_string("res://rooms/%s.props.json" % picked)
	else:
		_say("No room file for %s." % picked)
		return
	var doc: RefCounted = RoomDoc.parse(picked, text, props)
	closed.emit()
	Dev.open_tool.call_deferred("dev_room", {"doc": doc})


## Close the map and play in the picked room.
func teleport() -> void:
	if picked == "":
		return
	var id := picked
	var sh := sheet
	closed.emit()
	Dev.teleport.call_deferred(id, sh)


# ---------- ui ----------

func _make_theme() -> Theme:
	var t := Theme.new()
	for cls in ["Button", "Label"]:
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
	t.set_color("font_color", "Label", Color(0.9, 0.9, 0.95))
	return t


func _build_ui() -> void:
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.theme = _theme
	_view.draw.connect(_on_draw)
	_view.gui_input.connect(_on_view_input)
	add_child(_view)
	var bar := HBoxContainer.new()
	bar.theme = _theme
	bar.position = Vector2(2, 1)
	bar.add_theme_constant_override("separation", 2)
	add_child(bar)
	for s in SHEETS:
		_btn(bar, s.to_upper(), set_sheet.bind(s))
	_sep(bar)
	_btn(bar, "UNDO", undo)
	_btn(bar, "SAVE", save)
	_sep(bar)
	_btn(bar, "OPEN IN F2", open_in_room_builder)
	_btn(bar, "PLAY HERE", teleport)
	_btn(bar, "X", func(): closed.emit())
	_status = Label.new()
	_status.theme = _theme
	_status.position = Vector2(3, 216 - BOTTOM + 1)
	_status.size = Vector2(378, 11)
	_status.clip_text = true
	add_child(_status)
	var back := ColorRect.new()
	back.color = Color(0.06, 0.06, 0.1, 0.9)
	back.position = Vector2(0, 216 - BOTTOM)
	back.size = Vector2(384, BOTTOM)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	move_child(back, 1)


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
	if _status == null:
		return
	var s := "%s%s | " % [sheet.to_upper(), "*" if is_dirty() else ""]
	if picked != "":
		var c: Array = _rooms()[picked]["cell"]
		s += "%s (%s) at %d,%d size %dx%d | " % [picked, _rooms()[picked].get("title", ""), c[0], c[1], c[2], c[3]]
		for w in warnings:
			if w["id"] == picked:
				s += "RED: %s | " % w["text"]
				break
	if not warnings.is_empty():
		s += "%d red | " % warnings.size()
	_status.text = s + _msg


func _fit() -> void:
	var rooms := _rooms()
	if rooms.is_empty() or _view == null:
		return
	var box := Rect2(_rect(rooms.keys()[0]).position, Vector2.ZERO)
	for id in rooms:
		box = box.merge(_rect(id))
	var avail := Vector2(384.0 - 8.0, 216.0 - TOP - BOTTOM - 8.0)
	_zoom = clampf(minf(avail.x / maxf(1.0, box.size.x), avail.y / maxf(1.0, box.size.y)), 2.0, 24.0)
	_cam = box.get_center() - Vector2(192.0, TOP + (216.0 - TOP - BOTTOM) * 0.5) / _zoom


func _to_cell(p: Vector2) -> Vector2:
	return p / _zoom + _cam


func _to_screen(c: Vector2) -> Vector2:
	return (c - _cam) * _zoom


func _room_at(p: Vector2) -> String:
	var c := _to_cell(p)
	var hit := ""
	for id in _rooms():
		if _rect(id).has_point(c):
			hit = id            # the last one drawn is on top
	return hit


func _on_view_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var before := _to_cell(mb.position)
			_zoom = clampf(_zoom * (1.2 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2), 2.0, 40.0)
			_cam += before - _to_cell(mb.position)
			_view.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var id := _room_at(mb.position)
			picked = id
			_drag = ""
			if id != "":
				var r := _rect(id)
				var corner := _to_screen(r.end)
				_drag_from = mb.position
				_drag_cell = Vector2i(_to_cell(mb.position).floor())
				_drag_start = (_rooms()[id]["cell"] as Array).duplicate()
				_drag = "size" if mb.position.distance_to(corner) < maxf(4.0, _zoom * 0.45) else "move"
			_update_status()
			_view.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_drag = ""
		elif (mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE) and mb.pressed:
			_drag = "pan"
			_drag_from = mb.position
			_cam_from = _cam
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = ""
		return
	var mm := ev as InputEventMouseMotion
	if mm == null or _drag == "":
		return
	if _drag == "pan":
		_cam = _cam_from - (mm.position - _drag_from) / _zoom
		_view.queue_redraw()
		return
	var now := Vector2i(_to_cell(mm.position).floor())
	var home := _home(picked)
	if sheet == "restored" and home != "restored":
		_say("%s belongs to the BEFORE page: change it there." % picked)
		_drag = ""
		return
	var cell: Array = _stored(home, picked)["cell"]
	var n: Array = _drag_start.duplicate()
	if _drag == "move":
		n[0] = maxi(0, int(_drag_start[0]) + now.x - _drag_cell.x)
		n[1] = maxi(0, int(_drag_start[1]) + now.y - _drag_cell.y)
	else:
		n[2] = maxi(1, now.x - int(_drag_start[0]) + 1)
		n[3] = maxi(1, now.y - int(_drag_start[1]) + 1)
	if n != cell:
		# one undo step per drag: the first change of this drag records where it started
		if _undo.is_empty() or _undo.back()[1] != picked or _undo.back()[2] != _drag_start:
			_undo.append([home, picked, _drag_start.duplicate()])
		_stored(home, picked)["cell"] = n
		_recheck()


func _input(ev: InputEvent) -> void:
	var kev := ev as InputEventKey
	if kev == null or not kev.pressed or kev.echo:
		return
	var k: int = kev.physical_keycode
	if kev.ctrl_pressed:
		if k == KEY_S:
			save()
		elif k == KEY_Z:
			undo()
		return
	var d := Vector2i(int(k == KEY_RIGHT) - int(k == KEY_LEFT), int(k == KEY_DOWN) - int(k == KEY_UP))
	match k:
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			if kev.alt_pressed:
				nudge(d.x, d.y)
			elif kev.shift_pressed:
				resize_by(d.x, d.y)
			else:
				_cam += Vector2(d) * 4.0
				_view.queue_redraw()
		KEY_ENTER, KEY_KP_ENTER:
			open_in_room_builder()
		KEY_T:
			teleport()
		KEY_1:
			set_sheet("before")
		KEY_2:
			set_sheet("after")
		KEY_3:
			set_sheet("restored")
		KEY_DELETE:
			pass


# ---------- drawing ----------

func _on_draw() -> void:
	_view.draw_rect(Rect2(0, 0, 384, 216), Color(0.07, 0.07, 0.11))
	var font := ThemeDB.fallback_font
	if _zoom >= 8.0:
		var a := _cam.floor()
		for gx in range(int(a.x), int(a.x) + int(384.0 / _zoom) + 2):
			var sx := _to_screen(Vector2(gx, 0)).x
			_view.draw_line(Vector2(sx, TOP), Vector2(sx, 216 - BOTTOM), Color(1, 1, 1, 0.05))
		for gy in range(int(a.y), int(a.y) + int(216.0 / _zoom) + 2):
			var sy := _to_screen(Vector2(0, gy)).y
			_view.draw_line(Vector2(0, sy), Vector2(384, sy), Color(1, 1, 1, 0.05))
	var red := {}
	for w in warnings:
		red[w["id"]] = true
	var rooms := _rooms()
	var home_only := sheet == "restored"
	# the picked room's links first (so the boxes sit on top); the others would only be a tangle
	for id in rooms:
		if id != picked:
			continue
		for ex in rooms[id].get("exits", []):
			var to := String(ex.get("to", ""))
			if to != "" and rooms.has(to):
				_view.draw_line(_to_screen(_rect(id).get_center()), _to_screen(_rect(to).get_center()), Color(1.0, 0.9, 0.4, 0.55))
	for id in rooms:
		var r := _rect(id)
		var sr := Rect2(_to_screen(r.position), r.size * _zoom)
		var base := Color(0.25, 0.32, 0.55, 0.85)
		if bool(rooms[id].get("save", false)):
			base = Color(0.25, 0.5, 0.35, 0.85)
		if String(rooms[id].get("boss", "")) != "":
			base = Color(0.5, 0.3, 0.45, 0.85)
		if home_only and _home(id) != "restored":
			base = base.darkened(0.35)
		if red.has(id):
			base = Color(0.65, 0.15, 0.15, 0.9)
		_view.draw_rect(sr, base)
		var moved := _moved(id)
		_view.draw_rect(sr, Color(1.0, 0.9, 0.4) if id == picked else (Color(0.6, 1.0, 0.6) if moved else Color(0.8, 0.8, 0.9, 0.7)), false, 1.0)
		for ex in rooms[id].get("exits", []):
			_draw_exit(r, ex)
		if sr.size.x < 14.0:
			_view.draw_string(font, sr.position + Vector2(-1, -2), String(rooms[id].get("code", id)), HORIZONTAL_ALIGNMENT_LEFT, 20.0, 6, Color(0.85, 0.85, 0.95))
		else:
			var label := String(rooms[id].get("code", id)) if sr.size.x < 40.0 else "%s %s" % [rooms[id].get("code", ""), id]
			_view.draw_string(font, sr.position + Vector2(2, 8), label, HORIZONTAL_ALIGNMENT_LEFT, sr.size.x - 3.0, 7, Color(1, 1, 1))
	if picked != "" and rooms.has(picked):
		var pr := _rect(picked)
		_view.draw_rect(Rect2(_to_screen(pr.end) - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 0.9, 0.4))


func _moved(id: String) -> bool:
	for c in changed_rooms():
		if c[1] == id:
			return true
	return false


func _draw_exit(r: Rect2, ex: Dictionary) -> void:
	var at := float(ex.get("at", 0)) + 0.5
	var p := Vector2.ZERO
	var d := Vector2.ZERO
	match String(ex.get("side", "L")):
		"L":
			p = Vector2(r.position.x, r.position.y + at)
			d = Vector2(-1, 0)
		"R":
			p = Vector2(r.end.x, r.position.y + at)
			d = Vector2(1, 0)
		"U":
			p = Vector2(r.position.x + at, r.position.y)
			d = Vector2(0, -1)
		_:
			p = Vector2(r.position.x + at, r.end.y)
			d = Vector2(0, 1)
	var kind := String(ex.get("kind", "door"))
	var col := Color(1, 1, 1)
	if kind == "bricked" or kind == "sealed_x":
		col = Color(0.55, 0.55, 0.55)
	elif kind != "door" and kind != "open":
		col = Color(1.0, 0.85, 0.3)
	var s := _to_screen(p)
	_view.draw_line(s, s + d * 3.0, col, 1.5)


func _exit_tree() -> void:
	pass
