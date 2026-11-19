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
	"backdash_left": [KEY_Q, KEY_U],
	"backdash_right": [KEY_L, KEY_O],
	"swap": [KEY_E, KEY_TAB],
	"tuning": [KEY_F1],
	"restart": [KEY_R],
	"pause": [KEY_ESCAPE, KEY_P],
	"quick": [KEY_H],
	"repair": [KEY_G],
	"map": [KEY_M],
	"room1": [KEY_1], "room2": [KEY_2], "room3": [KEY_3], "room4": [KEY_4], "room5": [KEY_5], "room6": [KEY_6],
	"room7": [KEY_7], "room8": [KEY_8], "room9": [KEY_9], "room10": [KEY_0],
}
const PAD := {
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
	"jump": [JOY_BUTTON_A], "attack": [JOY_BUTTON_X], "attack2": [JOY_BUTTON_Y],
	"backdash_left": [JOY_BUTTON_LEFT_SHOULDER], "backdash_right": [JOY_BUTTON_RIGHT_SHOULDER],
	"swap": [JOY_BUTTON_B],
	"pause": [JOY_BUTTON_START],
	"quick": [JOY_BUTTON_BACK],
	"repair": [JOY_BUTTON_Y],
}

var hitstop := 0.0
var main: Node = null
var peace := false      # the self-test turns enemy aggression off
var shifted := false    # the reality shift has happened: the world is mirrored and recoloured
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
	# A double-detail version (assets/2x/<rel>, twice the pixels) wins when it exists.
	# It keeps its world size: the wrapper reports half its pixel size and draws all of
	# its pixels into that space, so the screen shows the extra detail.
	if not rel.begins_with("2x/") and (ResourceLoader.exists("res://assets/2x/" + rel) or FileAccess.file_exists("res://assets/2x/" + rel)):
		var hi := tex("2x/" + rel)
		if hi != null:
			var half := HalfTexture.new()
			half.inner = hi
			_tex[rel] = half
			return half
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


func sprite(set_name: String, fps: Dictionary, no_loop: Array = [], dir_override: String = "") -> AnimatedSprite2D:
	# Builds an animated sprite from assets/<set_name>/<anim>_NN.png.
	# dir_override reads the same frames from another folder (Pandora's skin B: pandora_b).
	var s := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = frames[set_name]["anims"]
	# "dir" lets a set live in another folder (the hero set is chosen by tools/use_hero_set.py)
	var dir: String = dir_override if dir_override != "" else frames[set_name].get("dir", set_name)
	for anim in anims:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(fps.get(anim, 10.0)))
		sf.set_animation_loop(anim, not no_loop.has(anim))
		for i in int(anims[anim]):
			sf.add_frame(anim, tex("%s/%s_%02d.png" % [dir, anim, i]))
	s.sprite_frames = sf
	s.centered = false
	return s


# A double-detail picture drawn at its world size: it reports half of its pixel size,
# and every draw call maps the requested area onto all of its pixels.
class HalfTexture extends Texture2D:
	var inner: Texture2D

	func _get_width() -> int:
		return inner.get_width() / 2

	func _get_height() -> int:
		return inner.get_height() / 2

	func _has_alpha() -> bool:
		return true

	func _is_pixel_opaque(x: int, y: int) -> bool:
		return true

	func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, Rect2(pos, get_size()), inner.get_rid(), false, modulate, transpose)

	func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, rect, inner.get_rid(), tile, modulate, transpose)

	func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
		RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, rect, inner.get_rid(),
			Rect2(src_rect.position * 2.0, src_rect.size * 2.0), modulate, transpose, clip_uv)
