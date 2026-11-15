# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16
# THE ASSET MANIFEST. Every sprite the suite draws is named here once, so the
# scenes never touch a path. Files live in res://assets/ (self-contained: the
# inbox/ library is a BUILD-time source only — see tools/build_assets.py and
# assets/MANIFEST.txt for each file's origin).
extends RefCounted

# frame counts, straight from the manifest
const PANDORA := {"idle": 12, "dash": 8, "jump": 5}
const WARDEN := {"idle": 5, "run": 6}
const CHOIR := {"idle": 8, "attack": 3}
const HUSK := {"idle": 4, "walk": 6}
const SPITTER := 5
const FX := {"burst": 8, "shatter": 10, "spark": 8, "slash": 3}

# the canvas the player's frames share (feet at the bottom centre)
const PLAYER_CANVAS := Vector2(128, 200)

static var _cache := {}


static func frames(prefix: String, n: int, start: int = 0) -> Array:
	var out: Array = []
	for i in range(start, start + n):
		var p := "res://assets/%s_%02d.png" % [prefix, i]
		var t := tex(p)
		if t != null:
			out.append(t)
	return out


static func tex(path: String) -> Texture2D:
	# Raw-file loading on purpose: a cold clone has no .godot/imported cache, and
	# this prototype must run from the exe with zero build steps. Reading the PNG
	# through Image skips the editor's import pass entirely.
	if _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		push_warning("missing texture " + path)
		_cache[path] = null
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		push_warning("unreadable texture " + path)
		_cache[path] = null
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[path] = t
	return t


static func sheet(anims: Dictionary) -> AnimatedSprite2D:
	# anims: name -> {prefix, n, fps, start, loop}
	var s := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	var first := true
	for key in anims:
		var a: Dictionary = anims[key]
		if first:
			sf.remove_animation("default")
			first = false
		sf.add_animation(key)
		sf.set_animation_speed(key, float(a.get("fps", 10.0)))
		sf.set_animation_loop(key, bool(a.get("loop", true)))
		for t in frames(String(a["prefix"]), int(a["n"]), int(a.get("start", 0))):
			sf.add_frame(key, t)
	s.sprite_frames = sf
	s.centered = false
	s.offset = Vector2(-PLAYER_CANVAS.x * 0.5, -PLAYER_CANVAS.y)
	return s


static func strip(prefix: String, n: int, fps: float, start: int = 0) -> AnimatedSprite2D:
	var s := sheet({"run": {"prefix": prefix, "n": n, "fps": fps, "start": start}})
	s.play("run")
	return s


static func one(path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(path)
	s.centered = false
	return s


static func fx_burst(at: Node2D, pos: Vector2, prefix: String, n: int, scale: float = 1.0) -> void:
	# a one-shot effect that frees itself: the enemy death, the mirror's shatter
	var s := strip(prefix, n, 22.0, 1)
	s.position = pos
	s.scale = Vector2(scale, scale)
	s.offset = Vector2(-16, -16)
	s.z_index = 30
	at.add_child(s)
	var t := at.create_tween()
	t.tween_interval(float(n) / 22.0)
	t.tween_callback(s.queue_free)
