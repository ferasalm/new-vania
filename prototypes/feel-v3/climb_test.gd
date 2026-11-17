# PROTOTYPE - NOT FOR PRODUCTION
# The lab wall climb, measured, with ONE wall latch per jump (wall_latches_per_air = 1).
# She can no longer go straight up the free-standing wall: the room has a thin ledge on
# each side of it now. The route, from either side: run at the wall, jump, latch near the
# top of the jump, wall-jump (the kick throws her back, up and away), land on the ledge,
# then jump at the wall from the ledge and over it. Human timing throughout: every press
# is held at least 6 frames, the run-up jump is a full press (a tap cannot reach the top
# of the jump, and the route latches there), the jump off the ledge is tried as a tap
# (12 frames) and a full press (20), and the wait between a latch and the next jump press
# comes from GAPS. Two more checks: without the relic she cannot reach either ledge from
# the floor, and a second latch is refused after the kick.
# Run: godot --headless --path prototypes/feel-v3 res://climb_test.tscn
# Options after "--":  <tuning_key>=<number> (tries other wall_* numbers without
# touching tuning.json),  verbose (prints every latch and kick).
# Add --fixed-fps 60 before --path to run it faster than real time (same physics steps;
# Engine.time_scale must NOT be used: it stretches the physics step itself).
extends Node

const TILE := 16.0
const GAPS := [10, 15, 20, 30]      # frames between "she latched" and the next jump press
const HOLDS := [12, 20]             # frames the jump off the ledge stays down: a tap and a full press
const PRESS := 20                   # frames for the run-up jump and the kick (a full human press)
const AWAY := 14                    # frames she leans away from the wall after the kick

var main: Node
var verbose := false
var wall_x0 := 0.0      # left face of the wall
var wall_x1 := 0.0      # right face
var wall_top := 0.0     # y of the top of the wall
var floor_y := 0.0
var ledges := {}        # "left"/"right" -> {row, x0, x1, y}
var rows: Array = []
var checks: Array = []
var reason := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "verbose":
			verbose = true
		elif a == "nocut":
			print("option nocut: no longer applies (a wall jump is never cut short)")
		elif a == "patched":
			print("option patched: no longer applies (the proposed player.gd lines are already in player.gd)")
		elif a.contains("=") and T.data.has(a.get_slice("=", 0)):
			T.set_v(a.get_slice("=", 0), float(a.get_slice("=", 1)))
			print("override  %s = %s" % [a.get_slice("=", 0), a.get_slice("=", 1)])
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(20)
	main.has_latch = true
	main.player.hp = 0.0
	main.enter("lab", "left")
	await _frames(20)
	if not _find_wall():
		print("CLIMB FAIL  (no tall wall found in rooms/lab.txt)")
		get_tree().quit(1)
		return
	if not _find_ledges():
		print("CLIMB FAIL  (no thin ledge beside the tall wall in rooms/lab.txt)")
		get_tree().quit(1)
		return
	print("wall: columns %d-%d, top y=%.0f, floor y=%.0f, height to climb %.0f px (%.0f tiles)" % [
		int(wall_x0 / TILE), int(wall_x1 / TILE) - 1, wall_top, floor_y, floor_y - wall_top, (floor_y - wall_top) / TILE])
	print("numbers: jump %.0f  gravity %.0f  jump_cut %.2f  wall_jump %.0f  push %.0f  lock %.2f  latch %.1f s  slide %.0f  latches per jump %.0f" % [
		T.v("jump_velocity"), T.v("gravity"), T.v("jump_cut"), T.v("wall_jump_velocity"), T.v("wall_jump_push"),
		T.v("wall_jump_lock"), T.v("wall_latch_time"), T.v("wall_slide_speed"), T.v("wall_latches_per_air")])
	print("ledges: left row %d cols %d-%d (y=%.0f, %.0f px up), right row %d cols %d-%d (y=%.0f, %.0f px up)" % [
		ledges["left"]["row"], ledges["left"]["x0"], ledges["left"]["x1"], ledges["left"]["y"], floor_y - ledges["left"]["y"],
		ledges["right"]["row"], ledges["right"]["x0"], ledges["right"]["x1"], ledges["right"]["y"], floor_y - ledges["right"]["y"]])
	for side in ["left", "right"]:
		for gap in GAPS:
			for hold in HOLDS:
				rows.append(await _climb(side, gap, hold))
	await _no_latch_check()
	await _platform_check()
	await _second_latch_check()
	_report()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _release_all() -> void:
	for a in ["left", "right", "jump", "down", "up"]:
		Input.action_release(a)


func _find_wall() -> bool:
	# the tall wall: the solid block that stands on the floor, away from the room edges,
	# with the most rows of open air on both sides
	var g: Array = main.room.grid
	var best := 0
	var bx0 := -1
	var bx1 := -1
	var floor_row := g.size() - 2
	var x := 2
	var w: int = g[floor_row - 1].length()
	while x < w - 2:
		if main.room.cell(x, floor_row - 1) != "#":
			x += 1
			continue
		var start := x
		while main.room.cell(x, floor_row - 1) == "#":
			x += 1
		var h := 0
		while main.room.cell(start, floor_row - 1 - h) == "#":
			h += 1
		if h > best:
			best = h
			bx0 = start
			bx1 = x
	if best < 4:
		return false
	wall_x0 = bx0 * TILE
	wall_x1 = bx1 * TILE
	floor_y = floor_row * TILE
	wall_top = floor_y - best * TILE
	return true


func _find_ledges() -> bool:
	# the thin ledge beside the wall, one to three tiles out, one on each side
	for side in ["left", "right"]:
		var face := int(wall_x0 / TILE) if side == "left" else int(wall_x1 / TILE)
		var found := {}
		for y in range(int(wall_top / TILE), int(floor_y / TILE)):
			for d in range(1, 4):
				var x := face - d if side == "left" else face + d - 1
				if main.room.cell(x, y) != "=":
					continue
				var x0 := x
				var x1 := x
				while main.room.cell(x0 - 1, y) == "=" and x0 - 1 > 1:
					x0 -= 1
				while main.room.cell(x1 + 1, y) == "=" and x1 + 1 < main.room.grid[y].length() - 1:
					x1 += 1
				found = {"row": y, "x0": x0, "x1": x1, "y": y * TILE}
				break
			if not found.is_empty():
				break
		if found.is_empty():
			return false
		ledges[side] = found
	return true


func _climb(side: String, gap: int, hold: int) -> Dictionary:
	# one run of the route, from the floor on one side to the far side of the wall
	var p: CharacterBody2D = main.player
	var toward := "right" if side == "left" else "left"
	var away := "left" if side == "left" else "right"
	var sgn := 1.0 if side == "left" else -1.0
	var face := wall_x0 if side == "left" else wall_x1
	var far := wall_x1 if side == "left" else wall_x0
	var ledge: Dictionary = ledges[side]
	var near_edge: float = (ledge["x1"] + 1) * TILE if side == "left" else ledge["x0"] * TILE
	_release_all()
	p.global_position = Vector2(face - sgn * 54.0, floor_y)
	p.velocity = Vector2.ZERO
	p.state = "move"
	await _frames(30)
	var frame := 0
	var latches := 0
	var kicks := 0
	var peak := floor_y
	var landed := false
	var crossed := false
	var why := ""
	# 1. run at the wall, jump near it with the button held like a person would
	Input.action_press(toward)
	await _frames(6)
	frame += 6
	while frame < 90:
		await get_tree().physics_frame
		frame += 1
		if p.is_on_floor() and absf(p.global_position.x - face) < 24.0:
			break
	Input.action_press("jump")
	var held := PRESS
	while held > 0:
		await get_tree().physics_frame
		frame += 1
		held -= 1
		if held == 0:
			Input.action_release("jump")
	# 2. latch near the top of the jump
	var guard := 0
	while guard < 90 and p.state != "wall":
		await get_tree().physics_frame
		frame += 1
		guard += 1
	if p.state != "wall":
		why = "never latched on the wall"
		_release_all()
		return _row(side, gap, hold, frame, false, 0, 0, 0.0, why)
	latches += 1
	if verbose:
		print("    %s gap %df: latch at %.0f px" % [side, gap, floor_y - p.global_position.y])
	# 3. wait the human gap, then kick: jump and lean away from the wall
	for i in gap:
		await get_tree().physics_frame
		frame += 1
	Input.action_release(toward)
	Input.action_press("jump")
	Input.action_press(away)
	kicks += 1
	peak = p.global_position.y
	var away_left := AWAY
	var jump_left := PRESS
	while away_left > 0 or jump_left > 0:
		await get_tree().physics_frame
		frame += 1
		peak = minf(peak, p.global_position.y)
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release("jump")
		if away_left > 0:
			away_left -= 1
			if away_left == 0:
				Input.action_release(away)
	# 4. fall onto the ledge (and count any second latch, which must never happen)
	var seen_wall := false
	guard = 0
	while guard < 180:
		await get_tree().physics_frame
		frame += 1
		guard += 1
		peak = minf(peak, p.global_position.y)
		if p.state == "wall" and not seen_wall:
			latches += 1
		seen_wall = p.state == "wall"
		if p.is_on_floor():
			if absf(p.global_position.y - float(ledge["y"])) < 1.0:
				landed = true
			else:
				why = "missed the ledge (landed at y=%.0f)" % p.global_position.y
			break
	if not landed:
		if why == "":
			why = "never landed on the ledge"
		_release_all()
		return _row(side, gap, hold, frame, false, latches, kicks, floor_y - peak, why)
	# 5. from the ledge: run at the wall, jump, and cross to the far side
	await _frames(4)
	frame += 4
	Input.action_press(toward)
	var run := 0
	while run < 20:
		await get_tree().physics_frame
		frame += 1
		run += 1
		if (near_edge - p.global_position.x) * sgn <= 12.0:
			break
	Input.action_press("jump")
	jump_left = hold
	guard = 0
	while guard < 180:
		await get_tree().physics_frame
		frame += 1
		guard += 1
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release("jump")
		if (p.global_position.x - far) * sgn > 8.0:
			crossed = true
			break
	if not crossed:
		why = "did not get past the far side of the wall"
	_release_all()
	if verbose:
		print("    %s gap %df hold %df: %s in %.2f s, latches %d, wall jumps %d, peak %.0f px" % [
			side, gap, hold, "over" if crossed else "stuck", frame / 60.0, latches, kicks, floor_y - peak])
	return _row(side, gap, hold, frame, crossed and landed and latches == 1 and kicks == 1, latches, kicks, floor_y - peak, why)


func _row(side: String, gap: int, hold: int, frame: int, ok: bool, latches: int, kicks: int, peak: float, why: String) -> Dictionary:
	if not ok and why == "":
		why = "latches=%d wall jumps=%d" % [latches, kicks]
	return {"side": side, "gap": gap, "hold": hold, "ok": ok, "time": frame / 60.0, "latches": latches,
		"kicks": kicks, "peak": peak, "why": why}


func _no_latch_check() -> void:
	# the wall is still a gate: with no relic she cannot reach either ledge from the floor
	main.has_latch = false
	var p: CharacterBody2D = main.player
	var best := 0.0
	var bad := ""
	for side in ["left", "right"]:
		var toward := "right" if side == "left" else "left"
		var sgn := 1.0 if side == "left" else -1.0
		var face := wall_x0 if side == "left" else wall_x1
		var far := wall_x1 if side == "left" else wall_x0
		for d in [8, 24, 40, 56, 72]:
			_release_all()
			p.global_position = Vector2(face - sgn * float(d), floor_y)
			p.velocity = Vector2.ZERO
			p.state = "move"
			await _frames(20)
			var top := p.global_position.y
			Input.action_press(toward)
			Input.action_press("jump")
			var held := PRESS
			for i in 240:
				await get_tree().physics_frame
				top = minf(top, p.global_position.y)
				if held > 0:
					held -= 1
					if held == 0:
						Input.action_release("jump")
				if p.is_on_floor() and (absf(p.global_position.y - float(ledges["left"]["y"])) < 1.0 or absf(p.global_position.y - float(ledges["right"]["y"])) < 1.0):
					bad += " %s d=%d stood on a ledge;" % [side, d]
				if (p.global_position.x - far) * sgn > 8.0:
					bad += " %s d=%d over the wall;" % [side, d]
			_release_all()
			best = maxf(best, floor_y - top)
			await _frames(10)
	main.has_latch = true
	var need := floor_y - float(ledges["left"]["y"])
	var text := "check a  no latch -> cannot reach the ledge: from the floor, 5 distances x 2 sides, highest %.0f px (the ledge is %.0f px up), reached a ledge or the far side: %s" % [
		best, need, "YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _platform_check() -> void:
	# the wall is a gate from EVERY nearby standing spot, not only the floor: with no relic,
	# start on each platform top within 14 tiles of a face, run at the wall and jump after
	# 0..30 frames of run-up (a full press). Landing on a ledge or getting over = a bypass.
	main.has_latch = false
	var p: CharacterBody2D = main.player
	var bad := ""
	var spots := 0
	for side in ["left", "right"]:
		var toward := "right" if side == "left" else "left"
		var sgn := 1.0 if side == "left" else -1.0
		var face := int(wall_x0 / TILE) if side == "left" else int(wall_x1 / TILE)
		var far := wall_x1 if side == "left" else wall_x0
		for d in range(1, 15):
			var x := face - d if side == "left" else face + d - 1
			for y in range(int(wall_top / TILE), int(floor_y / TILE)):
				var c: String = main.room.cell(x, y)
				if (c != "#" and c != "=") or main.room.cell(x, y - 1) != ".":
					continue
				if y == int(ledges[side]["row"]) and x >= int(ledges[side]["x0"]) and x <= int(ledges[side]["x1"]):
					continue
				spots += 1
				for delay in [0, 6, 12, 18, 24, 30]:
					_release_all()
					p.global_position = Vector2(x * TILE + TILE * 0.5, y * TILE)
					p.velocity = Vector2.ZERO
					p.state = "move"
					await _frames(8)
					Input.action_press(toward)
					var held := -1
					for i in 200:
						if i == delay:
							Input.action_press("jump")
							held = PRESS
						await get_tree().physics_frame
						if held > 0:
							held -= 1
							if held == 0:
								Input.action_release("jump")
						if p.is_on_floor() and (absf(p.global_position.y - float(ledges["left"]["y"])) < 1.0 or absf(p.global_position.y - float(ledges["right"]["y"])) < 1.0) \
								and absf(p.global_position.x - x * TILE) > TILE * 1.5:
							bad += " %s from col %d row %d (run %d f) stood on a ledge;" % [side, x, y, delay]
							break
						if (p.global_position.x - far) * sgn > 8.0:
							bad += " %s from col %d row %d (run %d f) got over;" % [side, x, y, delay]
							break
					_release_all()
	main.has_latch = true
	var text := "check c  no latch -> no platform near the wall leads to a ledge or over it: %d standing spots x 6 run-ups, bypass found: %s" % [
		spots, "YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _second_latch_check() -> void:
	# one latch per jump: after the kick, steering back into the wall must not latch again
	var bad := ""
	for side in ["left", "right"]:
		var p: CharacterBody2D = main.player
		var toward := "right" if side == "left" else "left"
		var sgn := 1.0 if side == "left" else -1.0
		var face := wall_x0 if side == "left" else wall_x1
		_release_all()
		p.global_position = Vector2(face - sgn * 54.0, floor_y)
		p.velocity = Vector2.ZERO
		p.state = "move"
		await _frames(30)
		Input.action_press(toward)
		await _frames(6)
		var frame := 0
		while frame < 90:
			await get_tree().physics_frame
			frame += 1
			if p.is_on_floor() and absf(p.global_position.x - face) < 24.0:
				break
		Input.action_press("jump")
		await _frames(PRESS)
		Input.action_release("jump")
		var guard := 0
		while guard < 90 and p.state != "wall":
			await get_tree().physics_frame
			guard += 1
		if p.state != "wall":
			bad += " %s: never latched;" % side
			_release_all()
			continue
		await _frames(15)             # the middle of GAPS: a human wait on the wall
		Input.action_press("jump")    # the kick; toward is still held, so she steers back at once
		await _frames(PRESS)
		Input.action_release("jump")
		var relatched := false
		var touched := false
		var was_wall := false
		var wait := 0
		while wait < 180:
			await get_tree().physics_frame
			wait += 1
			var on_wall: bool = p.state == "wall"
			if on_wall and not was_wall:
				relatched = true
			was_wall = on_wall
			if wait > 10 and p.is_on_wall():
				touched = true
			if p.is_on_floor():
				break
		_release_all()
		if relatched:
			bad += " %s: latched a second time;" % side
		elif not touched:
			bad += " %s: never got back to the wall;" % side
		await _frames(10)
	var text := "check b  second latch refused: after a latch and a wall jump, steering back into the wall before landing: latched again? %s" % [
		"YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _report() -> void:
	var need := floor_y - float(ledges["left"]["y"])
	print("")
	print("side   gap   ledge jump 12/20   over?  time    latches  wall jumps  peak / ledge")
	var fails := 0
	var bad_latch := 0
	for side in ["left", "right"]:
		for gap in GAPS:
			var line := ""
			var ok_all := true
			var times: Array = []
			var peak := 0.0
			var latches := 0
			var kicks := 0
			for r in rows:
				if r["side"] != side or r["gap"] != gap:
					continue
				line += "yes " if r["ok"] else "NO  "
				ok_all = ok_all and r["ok"]
				times.append(r["time"])
				peak = maxf(peak, r["peak"])
				latches = maxi(latches, r["latches"])
				kicks = maxi(kicks, r["kicks"])
			print("%-5s  %2df   %-16s  %-5s  %-6s  %-7d  %-10d  %3.0f / %.0f px" % [side, gap, line.strip_edges(),
				"yes" if ok_all else "NO", ("%.2f s" % times.max()) if ok_all else "-", latches, kicks, peak, need])
			if not ok_all:
				fails += 1
			if latches > 1 or kicks > 1:
				bad_latch += 1
	print("")
	print("gaps tried=%d  failed gaps=%d  gaps with more than one latch or kick=%d" % [GAPS.size() * 2, fails, bad_latch])
	print("checks:")
	for c in checks:
		print("  " + c["text"])
	var ok := fails == 0 and bad_latch == 0
	for c in checks:
		ok = ok and c["ok"]
	if not ok:
		reason = _first_reason()
	print("CLIMB %s" % ("PASS" if ok else "FAIL  (%s)" % reason))
	get_tree().quit(0 if ok else 1)


func _first_reason() -> String:
	for r in rows:
		if not r["ok"]:
			return "%s gap %df hold %df: %s" % [r["side"], r["gap"], r["hold"], r["why"]]
	for c in checks:
		if not c["ok"]:
			return c["text"]
	return "unknown"
