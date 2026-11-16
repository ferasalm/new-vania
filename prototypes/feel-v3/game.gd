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
	"tuning": [KEY_F1],
	"restart": [KEY_R],
}
const PAD := {
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X], "attack2": [JOY_BUTTON_Y],
	"backdash": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER],
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


func frozen() -> bool:
	return hitstop > 0.0


func tex(rel: String) -> Texture2D:
	# Raw PNG loading (same trick as v2): runs from a cold clone with no import step.
	if _tex.has(rel):
		return _tex[rel]
	var path := ProjectSettings.globalize_path("res://assets/" + rel)
	var t: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null:
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
