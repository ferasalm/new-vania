# PROTOTYPE - NOT FOR PRODUCTION
# The floating damage numbers. 700 ms world-time lifetime, pooled at 32.
# Palette: enemy damage amber, player damage taken pale bone, heal cyan.
# Never sigil-red. (health-damage.md TR-HD-036)
extends Node2D

var entries: Array = []   # {pos, text, color, age, size}
var pool_used := 0


func spawn(world_pos: Vector2, text: String, color: Color, size: int = 15) -> void:
	if entries.size() >= K.DMG_NUM_POOL:
		entries.pop_front()
	entries.append({"pos": world_pos, "text": text, "color": color, "age": 0.0, "size": size})
	pool_used = max(pool_used, entries.size())


func step(world_delta_ms: float) -> void:
	for e in entries:
		e["age"] += world_delta_ms
		e["pos"].y -= 34.0 * (world_delta_ms / 1000.0)
	entries = entries.filter(func(e): return e["age"] < K.DAMAGE_NUMBER_MS)
	queue_redraw()


func _draw() -> void:
	for e in entries:
		var t: float = e["age"] / float(K.DAMAGE_NUMBER_MS)
		var a: float = 1.0 if t < 0.65 else 1.0 - (t - 0.65) / 0.35
		var c: Color = e["color"]
		c.a = clampf(a, 0.0, 1.0)
		var txt: String = e["text"]
		var w := ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, e["size"]).x
		draw_string(ThemeDB.fallback_font, e["pos"] - Vector2(w * 0.5, 0), txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, e["size"], c)
