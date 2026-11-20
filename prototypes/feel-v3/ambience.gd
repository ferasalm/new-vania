# PROTOTYPE - NOT FOR PRODUCTION
# The ambience system: the drifting specks in a room, the voices after the shift,
# and world sound/visual cues that replace hand-holding text (chain run + distant boom,
# door refuse, candle light, rattle, cold air, dust).
extends Node

var whisper_t := 0.0


func motes(room: Node2D, world: Node2D) -> void:
	var m := CPUParticles2D.new()
	m.position = room.size / 2.0
	m.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	m.emission_rect_extents = room.size / 2.0
	m.amount = clampi(int(room.size.x * room.size.y / 2600.0), 16, 140)
	m.lifetime = 6.0
	m.preprocess = 6.0
	m.direction = Vector2(0.3, -1)
	m.spread = 40.0
	m.gravity = Vector2.ZERO
	m.initial_velocity_min = 2.0
	m.initial_velocity_max = 9.0
	m.color = room.theme["dust"]
	m.z_index = 1
	world.add_child(m)


func voices(delta: float) -> void:
	if not G.shifted:
		return
	whisper_t -= delta
	if whisper_t > 0.0:
		return
	whisper_t = randf_range(T.v("shift_whisper_min") if T.data.has("shift_whisper_min") else 4.0,
		T.v("shift_whisper_max") if T.data.has("shift_whisper_max") else 12.0)
	var file := "sfx/shift/incant_%02d.wav" % randi_range(1, 6) if randf() < 0.5 else "sfx/shift/whisper_%02d.wav" % randi_range(1, 5)
	Sfx.play_file(file, randf_range(-16.0, -4.0), randf_range(0.85, 1.12))


func schedule_first() -> void:
	whisper_t = randf_range(T.v("shift_whisper_min") if T.data.has("shift_whisper_min") else 4.0,
		T.v("shift_whisper_max") if T.data.has("shift_whisper_max") else 12.0)


func cue(name: String, at := Vector2.ZERO) -> void:
	match name:
		"chain_boom":
			Sfx.play("chain_run")
			Sfx.play("boom")
			if G.main != null:
				G.main.shake(1.8, 0.4)
				if at != Vector2.ZERO:
					G.main.dust(at, 8)
		"door_refuse":
			Sfx.play("door_refuse")
		"door_lamp":
			Sfx.play("door_lamp")
		"dust":
			Sfx.play("dust")
			if G.main != null and at != Vector2.ZERO:
				G.main.dust(at, 6)
		"cold_air":
			Sfx.play("cold_air")
		"candle":
			Sfx.play("candle")
			if G.main != null and at != Vector2.ZERO:
				G.main.fx("spark", at)
		"rattle":
			Sfx.play("rattle")
		"winch":
			Sfx.play("winch")
			if G.main != null:
				G.main.shake(1.2, 0.25)
		_:
			Sfx.play(name)
