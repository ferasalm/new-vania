# PROTOTYPE - NOT FOR PRODUCTION
# The changes Helper 2 proposes for files it does not own (player.gd, smoke.gd), kept
# as data and applied IN MEMORY only, so they can be measured before the lead applies
# them. Nothing on disk is changed. Each entry: the file, the single line to find,
# "after" (insert the new lines after it) or "replace", and the new lines.
# Used by climb_test.gd (option "patched") and climb_test_smoke.gd.
extends RefCounted

const PLAYER := [
	["var _steer_lock := 0.0      # after a wall jump she cannot steer back at once", "after",
		["var _kicked := false        # rising from a wall jump: letting go of jump does not cut it short"]],
	["\t\t\t\t_steer_lock = T.v(\"wall_jump_lock\")", "after",
		["\t\t\t\t_kicked = true"]],
	["\t_coyote = T.v(\"coyote_time\") if on_floor else maxf(0.0, _coyote - delta)", "after",
		["\tif on_floor:", "\t\t_kicked = false"]],
	["\tif Input.is_action_just_released(\"jump\") and velocity.y < 0.0:", "replace",
		["\tif Input.is_action_just_released(\"jump\") and velocity.y < 0.0 and not _kicked:"]],
]

const SMOKE := [
	["\t_check(\"the latch gives out by itself\", p.state != \"wall\", \"state=%s\" % p.state)", "after", [
		"\t# the climb, both ways: a player who only taps jump (6 frames) and waits a quarter",
		"\t# of a second after each latch gets over the tall wall in a few wall jumps",
		"\t# (the full table comes from climb_test.tscn)",
		"\tfor way in [1, -1]:",
		"\t\tvar toward := \"right\" if way == 1 else \"left\"",
		"\t\tvar floor_y: float = main.room.size.y - 32.0",
		"\t\tawait _frames(30)",
		"\t\tp.global_position = Vector2((55 * 16 - 30.0) if way == 1 else (57 * 16 + 30.0), floor_y)",
		"\t\tp.velocity = Vector2.ZERO",
		"\t\tawait _frames(4)",
		"\t\tvar kicks := 0",
		"\t\tvar clung := 0",
		"\t\tvar held := 0",
		"\t\tvar took := -1",
		"\t\tInput.action_press(toward)",
		"\t\tfor i in 420:",
		"\t\t\tif held > 0:",
		"\t\t\t\theld -= 1",
		"\t\t\t\tif held == 0:",
		"\t\t\t\t\tInput.action_release(\"jump\")",
		"\t\t\telif p.state == \"wall\":",
		"\t\t\t\tclung += 1",
		"\t\t\t\tif clung >= 15:",
		"\t\t\t\t\tclung = 0",
		"\t\t\t\t\tkicks += 1",
		"\t\t\t\t\theld = 6",
		"\t\t\t\t\tInput.action_press(\"jump\")",
		"\t\t\telif p.is_on_floor() and p.global_position.y > floor_y - 1.0 and i >= 6:",
		"\t\t\t\theld = 6",
		"\t\t\t\tInput.action_press(\"jump\")",
		"\t\t\tif p.state != \"wall\":",
		"\t\t\t\tclung = 0",
		"\t\t\tawait get_tree().physics_frame",
		"\t\t\tvar on_top: bool = p.is_on_floor() and p.global_position.y < floor_y - 120.0",
		"\t\t\tif on_top or (p.global_position.x - 56 * 16) * way > 24.0:",
		"\t\t\t\ttook = i",
		"\t\t\t\tbreak",
		"\t\tInput.action_release(\"jump\")",
		"\t\tInput.action_release(toward)",
		"\t\t_check(\"tapping jump climbs the tall wall from the %s in at most 4 wall jumps\" % (\"left\" if way == 1 else \"right\"),",
		"\t\t\ttook >= 0 and kicks <= 4, \"wall jumps=%d frames=%d\" % [kicks, took])",
		"\t# and the wall is a real gate: without the relic she cannot cling to it",
		"\tmain.has_latch = false",
		"\tawait _frames(30)",
		"\tp.global_position = Vector2(55 * 16 - 30.0, main.room.size.y - 32.0)",
		"\tp.velocity = Vector2.ZERO",
		"\tvar gate_top: float = p.global_position.y",
		"\tvar gate_clung := false",
		"\tInput.action_press(\"right\")",
		"\tawait _frames(6)",
		"\tInput.action_press(\"jump\")",
		"\tfor i in 70:",
		"\t\tawait get_tree().physics_frame",
		"\t\tgate_top = minf(gate_top, p.global_position.y)",
		"\t\tgate_clung = gate_clung or p.state == \"wall\"",
		"\tInput.action_release(\"jump\")",
		"\tInput.action_release(\"right\")",
		"\tmain.has_latch = true",
		"\t_check(\"without the relic the tall wall stops her\", not gate_clung and gate_top > main.room.size.y - 32.0 - 128.0 + 30.0,",
		"\t\t\"clung=%s reached %.0f of 128 px\" % [str(gate_clung), main.room.size.y - 32.0 - gate_top])",
	]],
]


static func patched(path: String, edits: Array) -> String:
	# returns the text of the script at `path` with the edits applied, or "" if an anchor
	# line is missing or is there more than once (then the lead could not apply it either)
	var lines := FileAccess.get_file_as_string(path).replace("\r", "").split("\n")
	for e in edits:
		var at := -1
		var count := 0
		for i in lines.size():
			if lines[i] == e[0]:
				count += 1
				at = i
		if count != 1:
			print("PATCH FAIL  %s: the anchor line is there %d times: %s" % [path, count, e[0].strip_edges()])
			return ""
		if e[1] == "replace":
			lines.remove_at(at)
			at -= 1
		for j in e[2].size():
			lines.insert(at + 1 + j, e[2][j])
	return "\n".join(lines)


static func take_over(path: String, edits: Array) -> bool:
	# Swaps the source of the real script object (the one every later preload gets) for
	# the patched text, in memory. Call it before anything has made an instance of it.
	var text := patched(path, edits)
	if text == "":
		return false
	var gs: GDScript = load(path)
	gs.source_code = text
	var err := gs.reload()
	if err != OK:
		print("PATCH FAIL  %s does not compile with the edits (error %d)" % [path, err])
		return false
	print("patched in memory: %s (%d edits)" % [path, edits.size()])
	return true


static func script_from(path: String, edits: Array) -> GDScript:
	# a new script made from the patched text (for smoke.gd, which nothing preloads)
	var text := patched(path, edits)
	if text == "":
		return null
	var gs := GDScript.new()
	gs.source_code = text
	if gs.reload() != OK:
		print("PATCH FAIL  %s does not compile with the edits" % path)
		return null
	return gs
