# PROTOTYPE - NOT FOR PRODUCTION
# tests_quick/q7_shot.gd - proof for ledger N7 (handoff Q7).
# Shows that a real PNG in assets/items/<id>.png is drawn on the room pickup
# and on the pick-up card, and that when the file is gone the game falls back
# to the placeholder square (coloured by kind, first letter) with no error.
# It runs WINDOWED (not headless) so it can take real screenshots, saves them
# into shots/, and quits by itself:
#   godot --path . res://tests_quick/q7_shot.tscn
# Shots saved: shots/q7_with_image.png (room + card, suture.png exists),
# shots/q7_card_image.png (the card close-up) and shots/q7_placeholder.png
# (room, suture.png moved aside). The test PNG is made by this script and is
# left MOVED ASIDE as assets/items/_aside_suture.png at the end - it is a test
# leftover, not a real item picture, and must NOT be committed.
extends Node

const ItemIcons := preload("res://item_icons.gd")

const PNG := "res://assets/items/suture.png"
const ASIDE := "res://assets/items/_aside_suture.png"

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	if main.has_method("debug_enter"):
		await main.debug_enter("church", "left", false)
	await _frames(10)
	await _run()
	var ok := failed == 0 and passed > 0
	print("q7_shot %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	_clean_leftovers()
	_write_png()
	var tex := ItemIcons.texture("suture")
	_check("the test PNG suture.png loads through the shared lookup", tex != null, "tex=%s" % str(tex))
	# three pickups in the room: suture has a picture today, the other two do not
	var pk = _spawn("suture", Vector2(40.0, -6.0))
	var pk_c = _spawn("coupler_034", Vector2(-70.0, -6.0))
	var pk_l = _spawn("lexicon_core", Vector2(110.0, -6.0))
	await _frames(12)
	_check("the room pickup holds the real picture", pk != null and is_instance_valid(pk) and pk.get("_tex") != null, "tex=%s" % str(pk.get("_tex") if pk != null else null))
	await _shot("res://shots/q7_with_image.png")
	_check("saved shots/q7_with_image.png (room: suture with its picture, coupler and lexicon as placeholders)", true, "")
	# the card with the picture
	var card = main.get("card")
	_check("the pick-up card exists", card != null, "card=%s" % str(card))
	if card != null:
		card.call("present", "suture")
		var opened := await _wait_card(card, true, 4.0)
		_check("the card opened for the suture", opened, "")
		await _frames(40)
		var rect = card.get("_icon_rect")
		_check("the card's image area holds the real picture", rect != null and rect.get("texture") != null, "")
		await _shot("res://shots/q7_card_image.png")
		_check("saved shots/q7_card_image.png (card: suture with its picture)", true, "")
		card.debug_close("ok")
		await _frames(10)
		_check("the card closed again", not bool(card.get("active")), "active=%s" % str(card.get("active")))
	# move the PNG aside: the same room must now show the placeholder
	_move_aside()
	var tex2 := ItemIcons.texture("suture")
	_check("after moving suture.png aside the shared lookup answers none", tex2 == null, "tex2=%s" % str(tex2))
	if pk != null and is_instance_valid(pk):
		pk.queue_free()
	await _frames(5)
	var pk2 = _spawn("suture", Vector2(40.0, -6.0))
	await _frames(12)
	_check("the respawned pickup has no picture (placeholder mode)", pk2 != null and is_instance_valid(pk2) and pk2.get("_tex") == null, "tex=%s" % str(pk2.get("_tex") if pk2 != null else null))
	_check("the placeholder still knows the item's first letter", pk2 != null and is_instance_valid(pk2) and String(pk2.get("_letter")) == "S", "letter=%s" % str(pk2.get("_letter") if pk2 != null else "?"))
	await _shot("res://shots/q7_placeholder.png")
	_check("saved shots/q7_placeholder.png (room: the suture placeholder square 'S' next to the other placeholders)", true, "")
	print("the test PNG was MOVED ASIDE to assets/items/_aside_suture.png - do not commit it")


# a small transparent 32x32 PNG: a red disc with a white stitch cross
func _write_png() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(32):
		for y in range(32):
			var d := Vector2(x - 15.5, y - 15.5).length()
			if d <= 13.0:
				img.set_pixel(x, y, Color(0.55, 0.1, 0.15))
	for k in range(7, 25):
		img.set_pixel(k, 16, Color(0.95, 0.93, 0.9))
		img.set_pixel(16, k, Color(0.95, 0.93, 0.9))
	img.save_png(ProjectSettings.globalize_path(PNG))


func _move_aside() -> void:
	if FileAccess.file_exists(ASIDE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ASIDE))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(PNG), ProjectSettings.globalize_path(ASIDE))
	_check("the test PNG moved aside to _aside_suture.png",
		err == OK and not FileAccess.file_exists(PNG) and FileAccess.file_exists(ASIDE), "err=%d" % err)


func _clean_leftovers() -> void:
	for p in [PNG, ASIDE]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _wait_card(card, want_active: bool, max_s: float) -> bool:
	var t := 0.0
	while t < max_s:
		if bool(card.get("active")) == want_active and float(card.get("lock_left")) <= 0.0:
			return true
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	return bool(card.get("active")) == want_active


func _spawn(item_id: String, offset: Vector2):
	var lo = main.get("loot")
	if lo == null or not lo.has_method("spawn_pickup"):
		return null
	return lo.call("spawn_pickup", item_id, main.get("player").global_position + offset, {})


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
