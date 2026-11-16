# PROTOTYPE - NOT FOR PRODUCTION
# A door in the edge of a room. It is shut and solid until she walks up to it,
# then it slides open and she walks off the screen through it. The boss door is
# bigger, opens slowly, shakes the room and its eye glows while it opens.
extends Node2D

var side := "right"
var boss := false
var to := ""              # the room behind it ("" = nowhere)
var locked := false       # a locked door never opens (the boss room, during the fight)
var open := 0.0           # 0 shut .. 1 fully open
var _slab: Texture2D
var _frame: Texture2D
var _shape: CollisionShape2D
var _was_opening := false
var _glow := 0.0


func setup(door_side: String, is_boss: bool, look: String, leads_to: String) -> void:
	side = door_side
	boss = is_boss
	to = leads_to
	_slab = G.tex("env/door_%s.png" % look)
	_frame = G.tex("env/doorframe_%s.png" % look)
	z_index = 3
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 48)
	_shape.shape = rect
	_shape.position = Vector2(8, -24)
	body.add_child(_shape)
	add_child(body)


func feet() -> Vector2:
	return global_position + Vector2(8, 0)


func _physics_process(delta: float) -> void:
	if G.main == null or G.main.player == null:
		return
	var p: Node2D = G.main.player
	var near: bool = absf(p.global_position.x - feet().x) < T.v("door_open_distance") \
		and absf(p.global_position.y - feet().y) < 40.0
	var want := 1.0 if (near and not locked and to != "") else 0.0
	var time := T.v("boss_door_time") if boss else T.v("door_time")
	var before := open
	open = move_toward(open, want, delta / maxf(0.05, time))
	var opening := open > before
	if opening and not _was_opening:
		Sfx.play("door")
	if opening and boss:
		G.main.shake(1.2, 0.1)        # the big door grinds
	_was_opening = opening
	_shape.disabled = open > 0.85
	_glow += delta
	queue_redraw()


func _draw() -> void:
	var w := float(_slab.get_width())
	var h := float(_slab.get_height())
	var x := 8.0 - w / 2.0
	# the dark way out behind the door
	draw_rect(Rect2(x, -h, w, h), Color(0, 0, 0, 1))
	if boss:
		var pulse := 0.25 + 0.2 * sin(_glow * 3.0) + 0.5 * open
		draw_rect(Rect2(x, -h, w, h), Color(0.75, 0.3, 1.0, 0.35 * pulse))
	# the slab slides up into the lintel; only the part still in the doorway is drawn
	var up := floorf(open * (h - 3.0))
	if h - up > 0.0:
		draw_texture_rect_region(_slab, Rect2(x, -h, w, h - up), Rect2(0, up, w, h - up))
	draw_texture(_frame, Vector2(8.0 - _frame.get_width() / 2.0, -float(_frame.get_height())))
	if boss:
		# the eye over the door brightens as you come near
		var a := 0.35 + 0.25 * sin(_glow * 4.0) + 0.4 * open
		draw_circle(Vector2(8, -h - 6.0), 5.0, Color(1.0, 0.82, 0.25, 0.25 * a))
		draw_circle(Vector2(8, -h - 6.0), 2.0, Color(1.0, 0.9, 0.5, a))
