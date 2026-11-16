# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "G". Shared state: the hit pause, the input map, sprite loading.
extends Node

# Keys copied from the user's melonDS layout (WASD = d-pad, K = B, J = Y, I = X, L = A, Q = L).
const KEYS := {
	"left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP],
	"down": [KEY_S, KEY_DOWN],
	"jump": [KEY_K, KEY_SPACE],
	"attack": [KEY_J],
	"attack2": [KEY_I],
	"backdash": [KEY_L, KEY_Q, KEY_SHIFT],
	"swap": [KEY_E, KEY_TAB],
	"tuning": [KEY_F1],
	"restart": [KEY_R],
	"pause": [KEY_ESCAPE, KEY_P],
	"room1": [KEY_1], "room2": [KEY_2], "room3": [KEY_3], "room4": [KEY_4], "room5": [KEY_5], "room6": [KEY_6],
}
const PAD := {
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X], "attack2": [JOY_BUTTON_Y],
	"backdash": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER],
	"swap": [JOY_BUTTON_RIGHT_SHOULDER],
	"pause": [JOY_BUTTON_START],
}

var hitstop := 0.0
var main: Node = null
var peace := false      # the self-test turns enemy aggression off
var frames := {}        # assets/frames.json
var _tex := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in KEYS:
		InputMap.add_action(action)
		for code in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
		for b in PAD.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/frames.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		frames = parsed
	else:
		push_error("assets/frames.json is missing: run tools/build_assets.py")


func _process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop = maxf(0.0, hitstop - delta)
	# Esc / P / Start: the pause menu (it also holds the music)
	if Input.is_action_just_pressed("pause") and main != null and main.touch != null:
		main.touch.toggle_pause()


func frozen() -> bool:
	return hitstop > 0.0


func tex(rel: String) -> Texture2D:
	# imported projects and exported builds use the imported texture; a cold clone
	# with no import step falls back to the raw PNG.
	if _tex.has(rel):
		return _tex[rel]
	# imported projects and exported builds: use the imported texture
	var res_path := "res://assets/" + rel
	var t: Texture2D = null
	if ResourceLoader.exists(res_path):
		t = load(res_path) as Texture2D
	# cold clone with no import step: read the raw PNG through FileAccess
	if t == null:
		var bytes := FileAccess.get_file_as_bytes(res_path)
		if not bytes.is_empty():
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				t = ImageTexture.create_from_image(img)
	if t == null:
		push_error("missing texture " + rel)
	_tex[rel] = t
	return t


func sprite(set_name: String, fps: Dictionary, no_loop: Array = []) -> AnimatedSprite2D:
	# Builds an animated sprite from assets/<set_name>/<anim>_NN.png.
	var s := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = frames[set_name]["anims"]
	for anim in anims:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(fps.get(anim, 10.0)))
		sf.set_animation_loop(anim, not no_loop.has(anim))
		for i in int(anims[anim]):
			sf.add_frame(anim, tex("%s/%s_%02d.png" % [set_name, anim, i]))
	s.sprite_frames = sf
	s.centered = false
	return s
