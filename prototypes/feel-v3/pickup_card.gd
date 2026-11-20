# PROTOTYPE - NOT FOR PRODUCTION
# The pickup card and the special show (S2). The game pauses, the screen dims to
# 70%, the item flies to her, and the card fades in at 0.15 s. Gear cards offer
# EQUIP NOW (J) and LATER (K). The card asks item_icons.gd for the picture:
# assets/items/<id>.png when the file exists, otherwise a placeholder square
# coloured by the item's kind with its first letter - never an error.
extends CanvasLayer

signal card_closed(choice: String)

const TAG_ITEM := "ITEM"
const TAG_ABILITY := "ABILITY"
const TAG_WEAPON := "WEAPON"
const TAG_HARNESS := "HARNESS"
const TAG_MODULE := "MODULE"

const ItemIcons := preload("res://item_icons.gd")


class Rays extends Node2D:
	var phase := 0.0
	var col := Color(0.5, 1.0, 1.0)

	func set_phase(u: float, c: Color) -> void:
		phase = u
		col = c
		queue_redraw()

	func _draw() -> void:
		var a := clampf(1.0 - absf(phase - 0.5) * 2.0, 0.0, 1.0)
		for i in 12:
			var ang := TAU * float(i) / 12.0 + phase * 0.7
			var r0 := 12.0 + phase * 12.0
			var r1 := 34.0 + phase * 26.0
			draw_line(Vector2(cos(ang), sin(ang)) * r0, Vector2(cos(ang), sin(ang)) * r1,
				Color(col.r, col.g, col.b, a * 0.5), 1.0)
		draw_arc(Vector2.ZERO, 10.0 + phase * 30.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, a * 0.6), 1.0)
		draw_circle(Vector2.ZERO, 3.0 + phase * 3.0, Color(col.r, col.g, col.b, a * 0.4))


var active := false
var lock_left := 0.0
var swallow_left := 0.0

var _item_id := ""
var _tag := TAG_ITEM
var _name := ""
var _desc := ""
var _effect := ""
var _icon := ""
var _data := {}
var _gear_slot := ""
var _is_gear := false
var _special := false
var _show_total := 0.0
var _show_left := 0.0
var _lock_total := 0.0
var _auto_close := -1.0
var _age := 0.0
var _choice := "ok"
var _finished := true
var _gen := 0
var _shown := {}
var _paused_by_us := false
var _locked_player := false
var _swallow_locked := false
var _word_text := ""

var _root: Control
var _dim: ColorRect
var _flash: ColorRect
var _word: Label
var _show_layer = null
var _show_item: ColorRect
var _show_icon: TextureRect
var _card: Control
var _border: ColorRect
var _bg: ColorRect
var _icon_rect: TextureRect
var _icon_placeholder: ColorRect
var _icon_letter: Label
var _tag_label: Label
var _name_label: Label
var _desc_label: Label
var _effect_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build()
	W.room_entered.connect(_on_room_entered)


func present(item_id: String) -> String:
	if not _finished:
		_finish("ok", false)
	_gen += 1
	var my := _gen
	_finished = false
	_choice = "ok"
	_item_id = item_id
	_age = 0.0
	_show_left = 0.0
	_auto_close = -1.0
	_read_data(item_id)
	var first := not _shown.has(item_id)
	_shown[item_id] = true
	_root.visible = true
	_dim.visible = true
	_card.visible = false
	_show_layer.visible = false
	_show_item.visible = false
	_show_icon.visible = false
	_word.visible = false
	_flash.color = Color(1, 1, 1, 0)
	Sfx.play("pickup_chime")
	var tex := ItemIcons.texture(_item_id, _icon)
	_show_icon.texture = tex
	if _special:
		_show_total = maxf(0.1, T.v("special_pickup_time"))
		_show_left = _show_total
		_lock_total = maxf(0.0, T.v("pickup_lock") - _show_total)
		_word_text = _word_for(_tag)
		_word.text = _word_text
		_word.add_theme_color_override("font_color", _tag_color())
		_show_layer.visible = true
		_show_icon.visible = tex != null
		_show_item.visible = tex == null
		_show_item.color = _tag_color()
		_word.visible = true
		_word.modulate.a = 0.0
		_lock_player("special")
		_pause()
		Sfx.play("pickup_show")
	else:
		_lock_total = T.v("pickup_lock") if first else minf(T.v("pickup_lock"), 0.2)
		if not first:
			_auto_close = _lock_total
		_open_card()
	await card_closed
	if my != _gen:
		return "ok"
	return _choice


func debug_close(choice := "ok") -> void:
	if not active:
		return
	if lock_left > 0.0:
		return
	_finish(choice, false)


func _read_data(item_id: String) -> void:
	var items: Dictionary = Db.table("items")
	var gear: Dictionary = Db.table("gear")
	_is_gear = gear.has(item_id)
	var data = {}
	if _is_gear:
		data = gear[item_id]
	else:
		data = items.get(item_id, {})
	_data = data
	_name = String(data.get("name", item_id.to_upper()))
	_desc = String(data.get("desc", ""))
	_icon = String(data.get("icon", ""))
	_gear_slot = String(data.get("slot", ""))
	if _is_gear:
		_tag = TAG_HARNESS if _gear_slot == "harness" else TAG_MODULE
		_special = not bool(data.get("rare", false))
		_effect = _gear_effect_line(item_id, data)
	else:
		_tag = String(data.get("tag", TAG_ITEM))
		_special = bool(data.get("special_show", false)) or _tag == TAG_ABILITY or _tag == TAG_WEAPON
		_effect = _replace_keys(String(data.get("effect", "")))


func _open_card() -> void:
	_show_left = 0.0
	_show_layer.visible = false
	_show_item.visible = false
	_show_icon.visible = false
	_word.visible = false
	_flash.color = Color(1, 1, 1, 0)
	if not _locked_player:
		_lock_player("special" if _special else "")
	active = true
	_age = 0.0
	lock_left = _lock_total
	_card.visible = true
	_card.modulate.a = 0.0
	_populate()
	_dim.visible = true
	_pause()


func _populate() -> void:
	var c := _tag_color()
	_border.color = c
	_tag_label.text = _tag
	_tag_label.add_theme_color_override("font_color", c)
	_name_label.text = _name
	_desc_label.text = _desc
	_effect_label.text = _effect
	_icon_letter.text = ItemIcons.letter(_data, _item_id)
	var tex := ItemIcons.texture(_item_id, _icon)
	_icon_rect.texture = tex
	_icon_rect.visible = tex != null
	_icon_placeholder.visible = tex == null
	_icon_letter.visible = tex == null
	# no picture yet: the placeholder square is coloured by the item's kind with
	# its first letter (assets/items/README.txt)
	var kc := ItemIcons.kind_color(_data, _item_id, _is_gear)
	_icon_placeholder.color = Color(kc.r * 0.35, kc.g * 0.35, kc.b * 0.35, 1.0)
	_icon_letter.add_theme_color_override("font_color", kc)


func _tag_color() -> Color:
	match _tag:
		TAG_WEAPON:
			return Color(1.0, 0.85, 0.4)
		TAG_ABILITY:
			return Color(0.5, 1.0, 1.0)
		TAG_HARNESS:
			return Color(0.8, 0.6, 1.0)
		TAG_MODULE:
			return Color(0.4, 1.0, 0.8)
	return Color(0.9, 0.9, 0.8)


func _word_for(tag: String) -> String:
	match tag:
		TAG_WEAPON:
			return "BOUND"
		TAG_ABILITY:
			return "PATCH"
		TAG_HARNESS:
			return "FITTED"
		TAG_MODULE:
			return "SEATED"
	return "TAKEN"


func _gear_effect_line(item_id: String, data: Dictionary) -> String:
	if item_id == "restore_module":
		return "One more stand where she falls."
	var fx = data.get("effects", {})
	var parts: Array = []
	for eff in fx:
		var key := String(fx[eff])
		if key == "" or not T.data.has(key):
			continue
		var v := T.v(key)
		match String(eff):
			"atk_add_key":
				parts.append("Damage +%s." % _num(v))
			"def_add_key":
				parts.append("Defence +%s." % _num(v))
			"hp_max_add_key":
				parts.append("Max HP +%s." % _num(v))
			"en_max_add_key":
				parts.append("Max EN +%s." % _num(v))
			"mp_max_add_key":
				parts.append("Max MP +%s." % _num(v))
			"mag_add_key":
				parts.append("Magic +%s." % _num(v))
			"orb_reach_add_key":
				parts.append("Soul orbs give %sx MP." % _num(v))
			"scrap_gain_mult_key":
				parts.append("Scrap gauge +%s." % _num(v))
	return " ".join(parts)


func _replace_keys(text: String) -> String:
	var out := text
	var re := RegEx.new()
	re.compile("\\{([a-z0-9_]+)\\}")
	for m in re.search_all(text):
		var key := m.get_string(1)
		if T.data.has(key):
			out = out.replace("{%s}" % key, _num(T.v(key)))
	return out


func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return str(int(roundf(v)))
	return "%.1f" % v


func _process(delta: float) -> void:
	if swallow_left > 0.0:
		swallow_left = maxf(0.0, swallow_left - delta)
		if swallow_left <= 0.0 and _swallow_locked:
			_swallow_locked = false
			if not active and _show_left <= 0.0 and _player_valid() and _player_locked():
				G.main.player.unlock()
	if _show_left > 0.0:
		_show_left -= delta
		var u := 1.0 - _show_left / maxf(0.001, _show_total)
		_show_layer.set_phase(u, _tag_color())
		var rise := 92.0 - 18.0 * sin(u * PI)
		_show_item.position = Vector2(188, rise)
		_show_icon.position = Vector2(184, rise - 4.0)
		_word.modulate.a = clampf((u - 0.6) / 0.15, 0.0, 1.0) * clampf((1.0 - u) / 0.1, 0.0, 1.0)
		_flash.color = Color(1, 1, 1, clampf((u - 0.7) / 0.1, 0.0, 1.0) * clampf((0.9 - u) / 0.1, 0.0, 1.0) * 0.7)
		if _show_left <= 0.0:
			_open_card()
		return
	if not active:
		return
	_age += delta
	lock_left = maxf(0.0, lock_left - delta)
	_card.modulate.a = clampf((_age - 0.15) / 0.15, 0.0, 1.0)
	if _auto_close > 0.0 and _age >= _auto_close:
		_finish("later" if _is_gear else "ok", false)
		return
	if lock_left > 0.0:
		return
	if Input.is_action_just_pressed("attack"):
		_finish("equip_now" if _is_gear else "ok", true)
	elif Input.is_action_just_pressed("jump"):
		_finish("later" if _is_gear else "ok", true)
	elif Input.is_action_just_pressed("up"):
		_finish("ok", true)
	elif InputMap.has_action("ui_accept") and Input.is_action_just_pressed("ui_accept"):
		_finish("ok", true)


func _input(event: InputEvent) -> void:
	if not active or lock_left > 0.0:
		return
	var tapped := false
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			tapped = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped = true
	if tapped:
		_finish("ok", true)
		get_viewport().set_input_as_handled()


func _finish(choice: String, from_input: bool) -> void:
	if _finished:
		return
	_finished = true
	_choice = choice
	active = false
	_show_left = 0.0
	lock_left = 0.0
	_root.visible = false
	_dim.visible = false
	_card.visible = false
	_show_layer.visible = false
	_show_item.visible = false
	_show_icon.visible = false
	_word.visible = false
	_flash.color = Color(1, 1, 1, 0)
	_unpause()
	if _locked_player and _player_valid():
		G.main.player.unlock()
	_locked_player = false
	if choice == "equip_now":
		_equip_now()
	if from_input and _player_valid():
		swallow_left = T.v("input_swallow")
		if swallow_left > 0.0 and G.main.player.has_method("lock"):
			G.main.player.lock("")
			_swallow_locked = true
	card_closed.emit(choice)


func _equip_now() -> void:
	if not _is_gear or _gear_slot == "":
		return
	var slots: Array = []
	if _gear_slot == "harness":
		slots = ["harness1", "harness2"]
	elif _gear_slot == "module":
		slots = ["module1", "module2"]
	for slot in slots:
		if String(R.equip.get(slot, "")) == "":
			if R.equip_gear(String(slot), _item_id):
				Sfx.play("pickup_equip")
				return


func _on_room_entered(_file_id: String) -> void:
	if not _finished:
		_finish("ok", false)


func _pause() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_us = true


func _unpause() -> void:
	if _paused_by_us:
		get_tree().paused = false
		_paused_by_us = false


func _lock_player(anim := "") -> void:
	if _player_valid() and G.main.player.has_method("lock"):
		G.main.player.lock(anim)
		_locked_player = true


func _player_valid() -> bool:
	return G.main != null and G.main.player != null and is_instance_valid(G.main.player)


func _player_locked() -> bool:
	return _player_valid() and G.main.player.has_method("is_locked") and G.main.player.is_locked()


func _build() -> void:
	_root = Control.new()
	_root.size = Vector2(384, 216)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.7)
	_dim.size = Vector2(384, 216)
	_root.add_child(_dim)

	_show_layer = Rays.new()
	_show_layer.position = Vector2(192, 108)
	_show_layer.visible = false
	_root.add_child(_show_layer)

	_show_item = ColorRect.new()
	_show_item.size = Vector2(8, 8)
	_show_item.position = Vector2(188, 92)
	_show_item.visible = false
	_root.add_child(_show_item)

	_show_icon = TextureRect.new()
	_show_icon.size = Vector2(16, 16)
	_show_icon.position = Vector2(184, 88)
	_show_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_show_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_show_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_show_icon.visible = false
	_root.add_child(_show_icon)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.size = Vector2(384, 216)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_word = Label.new()
	_word.position = Vector2(0, 138)
	_word.size = Vector2(384, 14)
	_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word.add_theme_font_size_override("font_size", 9)
	_word.add_theme_color_override("font_outline_color", Color.BLACK)
	_word.add_theme_constant_override("outline_size", 2)
	_word.visible = false
	_root.add_child(_word)

	_card = Control.new()
	_card.position = Vector2(76, 52)
	_card.size = Vector2(232, 112)
	_card.visible = false
	_root.add_child(_card)

	_border = ColorRect.new()
	_border.size = Vector2(232, 112)
	_card.add_child(_border)

	_bg = ColorRect.new()
	_bg.position = Vector2(2, 2)
	_bg.size = Vector2(228, 108)
	_bg.color = Color(0.04, 0.05, 0.07, 0.97)
	_card.add_child(_bg)

	_icon_placeholder = ColorRect.new()
	_icon_placeholder.position = Vector2(8, 8)
	_icon_placeholder.size = Vector2(64, 64)
	_icon_placeholder.color = Color(0.1, 0.12, 0.16)
	_card.add_child(_icon_placeholder)

	_icon_letter = Label.new()
	_icon_letter.position = Vector2(8, 8)
	_icon_letter.size = Vector2(64, 64)
	_icon_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_icon_letter.add_theme_font_size_override("font_size", 20)
	_icon_letter.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_card.add_child(_icon_letter)

	_icon_rect = TextureRect.new()
	_icon_rect.position = Vector2(8, 8)
	_icon_rect.size = Vector2(64, 64)
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon_rect.visible = false
	_card.add_child(_icon_rect)

	_tag_label = Label.new()
	_tag_label.position = Vector2(80, 8)
	_tag_label.size = Vector2(144, 10)
	_tag_label.add_theme_font_size_override("font_size", 7)
	_card.add_child(_tag_label)

	_name_label = Label.new()
	_name_label.position = Vector2(80, 20)
	_name_label.size = Vector2(144, 11)
	_name_label.add_theme_font_size_override("font_size", 9)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	_card.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.position = Vector2(80, 34)
	_desc_label.size = Vector2(144, 46)
	_desc_label.add_theme_font_size_override("font_size", 7)
	_desc_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_desc_label)

	_effect_label = Label.new()
	_effect_label.position = Vector2(80, 84)
	_effect_label.size = Vector2(144, 22)
	_effect_label.add_theme_font_size_override("font_size", 7)
	_effect_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_effect_label)
