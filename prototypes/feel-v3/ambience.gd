# PROTOTYPE - NOT FOR PRODUCTION
# The ambience system: the drifting specks in a room and, after the shift, the
# whispers and chants. Moved out of main.gd unchanged; S1 adds the world cues.
extends Node

var whisper_t := 0.0       # seconds to the next voice after the shift


func motes(room: Node2D, world: Node2D) -> void:
	# slow drifting specks in the colour of the area: dust in the library, sparks in the lab
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
	# after the shift: now and then a whisper or a chant, at a random loudness and pitch
	if not G.shifted:
		return
	whisper_t -= delta
	if whisper_t > 0.0:
		return
	whisper_t = randf_range(T.v("shift_whisper_min"), T.v("shift_whisper_max"))
	var file := "sfx/shift/incant_%02d.wav" % randi_range(1, 6) if randf() < 0.5 else "sfx/shift/whisper_%02d.wav" % randi_range(1, 5)
	Sfx.play_file(file, randf_range(-16.0, -4.0), randf_range(0.85, 1.12))


func schedule_first() -> void:
	# the first whisper after the shift
	whisper_t = randf_range(T.v("shift_whisper_min"), T.v("shift_whisper_max"))
