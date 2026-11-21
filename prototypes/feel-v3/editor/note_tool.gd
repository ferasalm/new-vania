# PROTOTYPE - NOT FOR PRODUCTION
# F4 screenshot notes. The game pauses on a picture of the moment. Drag to draw red
# boxes (right click removes the last), type what is wrong, press Enter. The picture
# (boxes burned in) goes to production/playtests/notes/ and one line goes into
# notes.md with the room, her position and your comment, for Claude to read next.
extends CanvasLayer

signal closed

var _img: Image = null
var _info := {}
var _boxes: Array = []          # Rect2 in 0..1 of the picture
var _drag := false
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _tex: ImageTexture = null
var _view: Control = null
var _edit: LineEdit = null
var _msg: Label = null
var _done := false

var saved_png := ""             # set after a save (tests read it)
var saved_md := ""


func _ready() -> void:
	layer = 40
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.draw.connect(_on_draw)
	_view.gui_input.connect(_on_input)
	add_child(_view)
	_msg = Label.new()
	_msg.position = Vector2(4, 178)
	_msg.add_theme_font_size_override("font_size", 8)
	_msg.add_theme_color_override("font_outline_color", Color.BLACK)
	_msg.add_theme_constant_override("outline_size", 3)
	_msg.text = "NOTE  drag = red box   right click = undo box   Enter = save   Esc or F4 = cancel"
	add_child(_msg)
	_edit = LineEdit.new()
	_edit.add_theme_font_size_override("font_size", 8)
	_edit.placeholder_text = "what is wrong here?"
	_edit.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_edit.offset_left = 4.0
	_edit.offset_right = -4.0
	_edit.offset_top = -22.0
	_edit.offset_bottom = -4.0
	_edit.text_submitted.connect(func(t: String) -> void: submit(t))
	_edit.gui_input.connect(_edit_input)
	add_child(_edit)
	_edit.grab_focus()


## info: "image" (the screenshot), "room", "pos", "state", "hp", "facing".
func begin(info: Dictionary) -> void:
	_info = info
	_img = info.get("image", null)
	if _img != null:
		_tex = ImageTexture.create_from_image(_img)
	if _view != null:
		_view.queue_redraw()


func _edit_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_ESCAPE:
		cancel()
		_edit.accept_event()


func cancel() -> void:
	if _done:
		return
	_done = true
	closed.emit()


## Add a box in 0..1 of the picture (the mouse does this; tests call it).
func add_box(r: Rect2) -> void:
	_boxes.append(r)
	if _view != null:
		_view.queue_redraw()


## Write the picture and the line, then close. Returns true when both were written.
func submit(comment: String) -> bool:
	if _done:
		return false
	var ok := _save(comment)
	if not ok:
		return false      # keep the note open so the comment is not lost
	_done = true
	closed.emit()
	return true


func _norm(p: Vector2) -> Vector2:
	var s := _view.size if _view != null and _view.size.x > 0.0 else Vector2(384, 216)
	return Vector2(clampf(p.x / s.x, 0.0, 1.0), clampf(p.y / s.y, 0.0, 1.0))


func _on_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_drag = true
				_from = _norm(ev.position)
				_to = _from
			elif _drag:
				_drag = false
				_to = _norm(ev.position)
				var r := Rect2(_from, _to - _from).abs()
				if r.size.x > 0.01 and r.size.y > 0.01:
					add_box(r)
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed and not _boxes.is_empty():
			_boxes.pop_back()
		_view.queue_redraw()
	elif ev is InputEventMouseMotion and _drag:
		_to = _norm(ev.position)
		_view.queue_redraw()


func _on_draw() -> void:
	var s := _view.size
	if _tex != null:
		_view.draw_texture_rect(_tex, Rect2(Vector2.ZERO, s), false)
	_view.draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.12), true)
	var red := Color(1.0, 0.1, 0.1)
	for b in _boxes:
		var r := Rect2(b.position * s, b.size * s)
		_view.draw_rect(r, Color(red.r, red.g, red.b, 0.15), true)
		_view.draw_rect(r, red, false, 1.0)
	if _drag:
		_view.draw_rect(Rect2(_from * s, (_to - _from) * s).abs(), red, false, 1.0)


func _save(comment: String) -> bool:
	if _img == null:
		return false
	var dir: String = Dev.notes_dir()
	if DirAccess.make_dir_recursive_absolute(dir) != OK and not DirAccess.dir_exists_absolute(dir):
		return false
	var human := Time.get_datetime_string_from_system(false, true)      # 2026-11-19 22:43:11
	var stamp := human.replace(":", "-").replace(" ", "_")
	var base := stamp
	var n := 2
	while FileAccess.file_exists(dir.path_join(base + ".png")):
		base = "%s_%d" % [stamp, n]
		n += 1
	var out := _img.duplicate() as Image
	_burn_boxes(out)
	if out.save_png(dir.path_join(base + ".png")) != OK:
		return false
	saved_png = dir.path_join(base + ".png")
	saved_md = dir.path_join("notes.md")
	var fresh := not FileAccess.file_exists(saved_md)
	var f := FileAccess.open(saved_md, FileAccess.WRITE if fresh else FileAccess.READ_WRITE)
	if f == null:
		return false
	if fresh:
		f.store_line("# Playtest notes (F4 in the game)")
		f.store_line("")
		f.store_line("One line per note: time | room | her position | her state | health | boxes drawn | comment | picture.")
		f.store_line("")
	else:
		f.seek_end()
	var pos: Vector2 = _info.get("pos", Vector2.ZERO)
	var clean := comment.strip_edges().replace("|", "/").replace("\n", " ")
	if clean == "":
		clean = "(no comment)"
	f.store_line("- %s | room %s | pos (%d, %d) | %s | hp %d | boxes %d | %s | ![](%s.png)" % [
		human, String(_info.get("room", "?")), int(pos.x), int(pos.y),
		String(_info.get("state", "?")), int(_info.get("hp", 0.0)), _boxes.size(), clean, base])
	f.close()
	return true


func _burn_boxes(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var th := maxi(2, w / 384)
	var red := Color(1.0, 0.1, 0.1)
	for b in _boxes:
		var x0 := int(b.position.x * w)
		var y0 := int(b.position.y * h)
		var x1 := mini(w - 1, int((b.position.x + b.size.x) * w))
		var y1 := mini(h - 1, int((b.position.y + b.size.y) * h))
		img.fill_rect(Rect2i(x0, y0, x1 - x0 + 1, th), red)
		img.fill_rect(Rect2i(x0, maxi(y0, y1 - th + 1), x1 - x0 + 1, th), red)
		img.fill_rect(Rect2i(x0, y0, th, y1 - y0 + 1), red)
		img.fill_rect(Rect2i(maxi(x0, x1 - th + 1), y0, th, y1 - y0 + 1), red)
