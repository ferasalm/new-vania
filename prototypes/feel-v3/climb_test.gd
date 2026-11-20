# PROTOTYPE - NOT FOR PRODUCTION
# The well's wall climb, measured, with ONE wall latch per jump (wall_latches_per_air = 1).
# map.md gives the wall climb to THE MARROW WELL (SH, rooms/shaft.txt): a 5-tile shaft whose right
# wall is the climbable one, with 2-tile ledges jutting from the left wall every 96 px, a corridor
# along the bottom that runs east to the door, and an opening at the top into the vault.
# The route a human would use, from the floor: run at the right wall, jump, latch near the top of
# the jump, wall-jump (the kick throws her back, up and away) onto the next ledge; from that ledge
# walk to its free end (at least 6 frames of running), jump at the wall again, latch, kick, and so
# on; from the top ledge jump straight up out into the vault.
# Human timing throughout: every press is held at least 6 frames, the run-up jump from the floor
# is a full press (PRESS), the jumps from the ledges are tried as a tap (12 frames) and a full
# press (20), the wait between a latch and the next jump press comes from GAPS, and after the
# kick she leans away from the wall for AWAY frames. One route row = one climb in one go: she
# starts on the floor and the next hop starts wherever the last one landed her.
# Her body is rebuilt on every room entry (main.gd), so every trial starts with main.enter
# ("shaft", "right") and re-reads main.player; nothing holds a player across a room change.
# Table column "peak / ledge" = the weakest hop of the route: the highest point the kick reached
# above the spot it started from, against the 96 px between ledges.
# Three checks: a) with no wall jump she cannot reach the first ledge from the floor (5 standing
# spots), b) a second latch is refused after the kick, c) with no wall jump no standing spot
# (floor or ledge below the top one) reaches a higher ledge or the top after any run-up. A jump
# that ends at the east door is not a bypass; the trial ends when she lands.
# Run: godot --headless --path prototypes/feel-v3 res://climb_test.tscn
# Options after "--":  <tuning_key>=<number> (tries other wall_* numbers without
# touching tuning.json),  away=<frames> (tries a longer lean after the kick; the verdict
# uses the default AWAY),  verbose (prints every latch, kick and landing).
# Add --fixed-fps 60 before --path to run it faster than real time (same physics steps;
# Engine.time_scale must NOT be used: it stretches the physics step itself).
extends Node

const TILE := 16.0
const HALF := 6.0                   # half her body width (player.gd BODY.x / 2)
const GAPS := [10, 15, 20, 30]      # frames between "she latched" and the next jump press
const HOLDS := [12, 20]             # frames the jump from a ledge stays down: a tap and a full press
const PRESS := 20                   # frames for the run-up jump and the kick (a full human press)
const AWAY := 14                    # frames she leans away from the wall after the kick

var main: Node
var verbose := false
var away := AWAY
var wall_x0 := 0.0      # left face of the wall (the corridor's right side)
var wall_x1 := 0.0      # right edge of the wall
var wall_top := 0.0     # y of the top of the wall
var floor_y := 0.0
var ledges := {}        # "left" -> {row, x0, x1, y}: the lowest ledge of the ladder
var ledge_ys: Array = []  # every ledge of the ladder, lowest first
var ledge_edge := 0.0   # x of the free end of the ledges (where they stop jutting into the shaft)
var ledge_mid := 0.0    # x in the middle of a ledge
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
		elif a.begins_with("away="):
			away = int(a.get_slice("=", 1))
			print("override  away = %d frames (the verdict uses %d)" % [away, AWAY])
		elif a.contains("=") and T.data.has(a.get_slice("=", 0)):
			T.set_v(a.get_slice("=", 0), float(a.get_slice("=", 1)))
			print("override  %s = %s" % [a.get_slice("=", 0), a.get_slice("=", 1)])
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(20)
	main.has_latch = true
	main.player.hp = 0.0
	main.enter("shaft", "right")
	await _frames(20)
	if not _find_wall():
		print("CLIMB FAIL  (no climbable wall found in rooms/shaft.txt)")
		get_tree().quit(1)
		return
	if not _find_ledges():
		print("CLIMB FAIL  (no ledges found beside the well wall in rooms/shaft.txt)")
		get_tree().quit(1)
		return
	print("wall: columns %d-%d, top y=%.0f, floor y=%.0f, height to climb %.0f px (%.0f tiles)" % [
		int(wall_x0 / TILE), int(wall_x1 / TILE) - 1, wall_top, floor_y, floor_y - wall_top, (floor_y - wall_top) / TILE])
	print("numbers: jump %.0f  gravity %.0f  jump_cut %.2f  wall_jump %.0f  push %.0f  lock %.2f  latch %.1f s  slide %.0f  latches per jump %.0f" % [
		T.v("jump_velocity"), T.v("gravity"), T.v("jump_cut"), T.v("wall_jump_velocity"), T.v("wall_jump_push"),
		T.v("wall_jump_lock"), T.v("wall_latch_time"), T.v("wall_slide_speed"), T.v("wall_latches_per_air")])
	print("ledges: %d ledges, lowest row %d cols %d-%d (y=%.0f, %.0f px up), ladder %s; free end x=%.0f, wall face x=%.0f (%.0f px apart, her box is %.0f wide)" % [
		ledge_ys.size(), ledges["left"]["row"], ledges["left"]["x0"], ledges["left"]["x1"], ledges["left"]["y"],
		floor_y - ledges["left"]["y"], str(ledge_ys), ledge_edge, wall_x0, wall_x0 - ledge_edge, HALF * 2.0])
	for gap in GAPS:
		for hold in HOLDS:
			rows.append(await _climb("left", gap, hold))
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


func _into_well(x: float, y: float) -> CharacterBody2D:
	# a fresh trial: back into the well with a brand-new body (main.enter rebuilds her), put down
	# at (x, y) and left to settle for 20 frames. Always use the body this returns, never an old one.
	_release_all()
	while main._busy:             # a door fade from an earlier trial must finish first
		await get_tree().physics_frame
	main.enter("shaft", "right")
	var p: CharacterBody2D = main.player
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	p.state = "move"
	await _frames(20)
	return main.player


func _find_wall() -> bool:
	# the well's climbable wall: the solid right side of the shaft, from the floor
	# up to the top opening (map.md: climb the well, SH, WALL JUMP)
	var g: Array = main.room.grid
	if main.room.up_span.x < 0.0:
		return false
	var face := int(main.room.up_span.y / TILE)
	if face <= 0 or face >= g[0].length() - 1:
		return false
	# the floor: the first solid row under the well's open bottom
	var floor_row := 1
	while floor_row < g.size() and main.room.cell(face - 1, floor_row) != "#":
		floor_row += 1
	if floor_row >= g.size():
		return false
	# the wall starts above the corridor that runs in from the door, and climbs to the top opening
	var r := floor_row - 1
	while r > 0 and main.room.cell(face, r) == ".":
		r -= 1
	var h := 0
	while r - h >= 0 and main.room.cell(face, r - h) == "#":
		h += 1
	if h < 8:
		return false
	wall_x0 = face * TILE
	wall_x1 = g[0].length() * TILE
	wall_top = (r - h + 1) * TILE
	floor_y = floor_row * TILE
	return true


func _find_ledges() -> bool:
	# the ledges: the 2-tile shelves where the shaft's left wall juts in, each with open air above
	# it; the lowest one is the first step of the climb. The shaft is the columns of the top opening.
	# A ledge may end in a one-way plank lip ("=", user decision 2026-11-19): she jumps up through
	# it from below and lands on it from above, so the lip counts as part of the ledge's top.
	var found: Array = []
	var floor_row := int(floor_y / TILE)
	var lc := int(main.room.up_span.x / TILE)         # the shaft's left column
	for y in range(1, floor_row):
		var lip: bool = main.room.cell(lc + 2, y) == "=" and main.room.cell(lc + 3, y) == "."
		if main.room.cell(lc, y) == "#" and main.room.cell(lc + 1, y) == "#" and (main.room.cell(lc + 2, y) == "." or lip) and main.room.cell(lc, y - 1) == ".":
			found.append(y)
	if found.size() < 2:
		return false
	var y := int(found[found.size() - 1])
	var x0 := lc + 2
	var x1 := lc + 1
	for x in range(0, lc + 3):
		if (main.room.cell(x, y) == "#" or main.room.cell(x, y) == "=") and main.room.cell(x, y - 1) == ".":
			x0 = mini(x0, x)
			x1 = maxi(x1, x)
	ledges["left"] = {"row": y, "x0": x0, "x1": x1, "y": y * TILE}
	ledge_edge = (x1 + 1) * TILE
	ledge_mid = (x0 + x1 + 1) * TILE / 2.0
	ledge_ys.clear()
	for i in range(found.size() - 1, -1, -1):
		ledge_ys.append(found[i] * TILE)
	return true


func _climb(side: String, gap: int, hold: int) -> Dictionary:
	# one run of the route: floor -> lowest ledge -> ... -> the top ledge -> out through the opening,
	# one latch per jump; each hop starts where the last one landed her
	var p: CharacterBody2D = await _into_well(wall_x0 - 44.0, floor_y)
	var frame := 20
	var latches := 0
	var kicks := 0
	var weakest := 9999.0       # the lowest kick peak above its starting spot
	var why := ""
	for k in ledge_ys.size():
		var target: float = float(ledge_ys[k])
		var from_y: float = floor_y if k == 0 else float(ledge_ys[k - 1])
		if k > 0:
			await _frames(20)       # she catches her breath on the ledge
			frame += 20
			p = main.player
		# run at the wall and jump: a full press from the floor, the tested hold from a ledge
		var start_x := p.global_position.x
		Input.action_press("right")
		await _frames(6)
		frame += 6
		var walk := 0
		while k > 0 and p.global_position.x < ledge_edge - 4.0 and walk < 60:
			await get_tree().physics_frame      # from a ledge she walks to its free end before she jumps
			frame += 1
			walk += 1
		Input.action_press("jump")
		var held := PRESS if k == 0 else hold
		var latched_at := -1
		var t := 0
		while t < 90:
			await get_tree().physics_frame
			frame += 1
			t += 1
			if held > 0:
				held -= 1
				if held == 0:
					Input.action_release("jump")
			if latched_at < 0 and p.state == "wall":
				latched_at = t
				latches += 1
				if verbose:
					print("    gap %df hold %df hop %d: run-up from x=%.0f, latch at (%.0f, %.0f) = %.0f px up, frame %d of the jump" % [
						gap, hold, k + 1, start_x, p.global_position.x, p.global_position.y, from_y - p.global_position.y, t])
			if latched_at >= 0 and held == 0 and t - latched_at >= gap:
				break           # latched, the jump press is over and the human wait is done
			if latched_at < 0 and held == 0 and t > 4 and p.is_on_floor():
				break           # came down without a latch
		if latched_at < 0 or p.state != "wall":
			why = "never latched on the wall at ledge %d" % (k + 1) if latched_at < 0 else "lost the wall before the kick at ledge %d" % (k + 1)
			_release_all()
			return _row(side, gap, hold, frame, false, latches, kicks, weakest, why)
		# the kick: jump and lean away from the wall
		var kick_x := p.global_position.x
		var kick_y := p.global_position.y
		Input.action_release("right")
		Input.action_press("jump")
		Input.action_press("left")
		kicks += 1
		var hop_top := kick_y
		var jump_left := PRESS
		var away_left := away
		var seen_wall := true       # she is still on the wall as the kick starts: not a second latch
		var landed := false
		var short := NAN        # how far her box ended up from the ledge, at the ledge's height
		var guard := 0
		while guard < 240:
			await get_tree().physics_frame
			frame += 1
			guard += 1
			hop_top = minf(hop_top, p.global_position.y)
			if jump_left > 0:
				jump_left -= 1
				if jump_left == 0:
					Input.action_release("jump")
			if away_left > 0:
				away_left -= 1
				if away_left == 0:
					Input.action_release("left")
			var on_wall: bool = p.state == "wall"
			if on_wall and not seen_wall:
				latches += 1        # a second latch in one jump: never allowed
			seen_wall = on_wall
			if is_nan(short) and hop_top < target and p.velocity.y > 0.0 and p.global_position.y >= target - 2.0:
				short = (p.global_position.x - HALF) - ledge_edge
			if guard > 2 and p.is_on_floor():
				if absf(p.global_position.y - target) < 1.0:
					landed = true
				else:
					if is_nan(short):
						why = "missed ledge %d (landed at y=%.0f; too low: the hop topped out %.0f px above where it began, the ledge is %.0f px up)" % [
							k + 1, p.global_position.y, from_y - hop_top, from_y - target]
					else:
						why = "missed ledge %d (landed at y=%.0f; at the ledge's height her box was %.0f px %s its free end; the hop topped out %.0f px up, the ledge is %.0f)" % [
							k + 1, p.global_position.y, absf(short), "beyond" if short > 0.0 else "inside", from_y - hop_top, from_y - target]
				break
		weakest = minf(weakest, from_y - hop_top)
		if verbose:
			print("    gap %df hold %df hop %d: kick at (%.0f, %.0f), rose %.0f px (ledge %.0f up), box %.0f px %s the ledge's free end at its height, %s" % [
				gap, hold, k + 1, kick_x, kick_y, kick_y - hop_top, from_y - target, absf(short) if not is_nan(short) else 0.0,
				"beyond" if short > 0.0 else "inside", "landed x=%.0f y=%.0f" % [p.global_position.x, p.global_position.y] if landed else "did not land on it"])
		if not landed:
			if why == "":
				why = "never landed on ledge %d" % (k + 1)
			_release_all()
			return _row(side, gap, hold, frame, false, latches, kicks, weakest, why)
	# from the top ledge, jump straight up through the opening into the vault
	await _frames(20)
	frame += 20
	Input.action_press("jump")
	var out := 0
	while out < 120 and main.room_name == "shaft":
		await get_tree().physics_frame
		frame += 1
		out += 1
	Input.action_release("jump")
	var out_ok: bool = main.room_name == "vault"
	if not out_ok:
		why = "did not leave through the top"
	_release_all()
	if verbose:
		print("    gap %df hold %df: %s in %.2f s, latches %d, wall jumps %d, weakest hop %.0f px" % [
			gap, hold, "out" if out_ok else "stuck", frame / 60.0, latches, kicks, weakest])
	return _row(side, gap, hold, frame, out_ok and latches == ledge_ys.size() and kicks == ledge_ys.size(), latches, kicks, weakest, why)


func _row(side: String, gap: int, hold: int, frame: int, ok: bool, latches: int, kicks: int, peak: float, why: String) -> Dictionary:
	if not ok and why == "":
		why = "latches=%d wall jumps=%d" % [latches, kicks]
	return {"side": side, "gap": gap, "hold": hold, "ok": ok, "time": frame / 60.0, "latches": latches,
		"kicks": kicks, "peak": peak, "why": why}


func _no_latch_check() -> void:
	# the well is still a gate: with no wall jump she cannot reach the first ledge from the floor
	main.has_latch = false
	var best := 0.0
	var bad := ""
	for d in [8, 24, 40, 56, 72]:
		var p: CharacterBody2D = await _into_well(wall_x0 - float(d), floor_y)
		var top := p.global_position.y
		Input.action_press("right")
		Input.action_press("jump")
		var held := PRESS
		var airborne := false
		for i in 240:
			await get_tree().physics_frame
			if main.room_name != "shaft":
				if main.room_name == "vault":
					bad += " d=%d left through the top;" % d
				break
			p = main.player
			top = minf(top, p.global_position.y)
			if held > 0:
				held -= 1
				if held == 0:
					Input.action_release("jump")
			if not p.is_on_floor():
				airborne = true
			elif airborne or p.global_position.y < floor_y - 1.0:
				if p.global_position.y < floor_y - 1.0:
					bad += " d=%d stood on a ledge at y=%.0f;" % [d, p.global_position.y]
				break           # she is down again: the jump is over
		_release_all()
		best = maxf(best, floor_y - top)
	main.has_latch = true
	var need := floor_y - float(ledge_ys[0])
	var text := "check a  no latch -> cannot reach the ledge: from the floor, 5 distances, highest %.0f px (the ledge is %.0f px up), reached a ledge or the top: %s" % [
		best, need, "YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _platform_check() -> void:
	# the well is a gate from every standing spot near the wall, not only the floor: with no
	# wall jump, start on the floor and on every ledge below the top one (the top ledge's own way
	# out is the end of the climb), run at the wall and jump after 0..30 frames of run-up
	# (a full press). A higher ledge or the top = a bypass.
	main.has_latch = false
	var bad := ""
	var starts: Array = []
	for i in ledge_ys.size() - 1:
		starts.append(Vector2(ledge_mid, float(ledge_ys[i])))
	for d in [8, 24, 40, 56, 72]:
		starts.append(Vector2(wall_x0 - float(d), floor_y))
	for st in starts:
		for delay in [0, 6, 12, 18, 24, 30]:
			var p: CharacterBody2D = await _into_well(st.x, st.y)
			var start_y: float = st.y
			Input.action_press("right")
			var held := -1
			for i in 200:
				if i == delay:
					Input.action_press("jump")
					held = PRESS
				await get_tree().physics_frame
				if main.room_name != "shaft":
					if main.room_name == "vault":
						bad += " from (%.0f,%.0f) run %d f left through the top;" % [st.x, st.y, delay]
					break           # any other room is the east door: not a bypass
				p = main.player
				if held > 0:
					held -= 1
					if held == 0:
						Input.action_release("jump")
				if p.is_on_floor():
					if p.global_position.y < start_y - 1.0:
						bad += " from (%.0f,%.0f) run %d f stood higher at y=%.0f;" % [st.x, st.y, delay, p.global_position.y]
						break
					if i >= delay + PRESS:
						break       # the jump is over and she stands no higher
			_release_all()
	main.has_latch = true
	var text := "check c  no latch -> no standing spot near the wall reaches a higher ledge or the top: %d spots x 6 run-ups, bypass found: %s" % [
		starts.size(), "YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _second_latch_check() -> void:
	# one latch per jump: after the kick, steering back into the wall must not latch again.
	# She first does what hop 1 of the route does (run at the wall from the floor, full jump), so
	# she really does latch; then the kick with right still held, and she steers back at once.
	var bad := ""
	var p: CharacterBody2D = await _into_well(wall_x0 - 44.0, floor_y)
	Input.action_press("right")
	await _frames(6)
	Input.action_press("jump")
	var held := PRESS
	var guard := 0
	while guard < 90:
		await get_tree().physics_frame
		guard += 1
		if held > 0:
			held -= 1
			if held == 0:
				Input.action_release("jump")
		if held == 0 and p.state == "wall":
			break
		if held == 0 and guard > 4 and p.is_on_floor():
			break
	if p.state != "wall":
		bad += " never latched;"
	else:
		await _frames(15)             # the middle of GAPS: a human wait on the wall
		Input.action_press("jump")    # the kick; right is still held, so she steers back at once
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
		if relatched:
			bad += " latched a second time;"
		elif not touched:
			bad += " never got back to the wall;"
	_release_all()
	var text := "check b  second latch refused: after a latch and a wall jump, steering back into the wall before landing: latched again? %s" % [
		"YES (BAD)" if bad != "" else "no"]
	checks.append({"ok": bad == "", "text": text + ("" if bad == "" else "  " + bad)})


func _report() -> void:
	var need := floor_y - float(ledge_ys[0])
	var hops := ledge_ys.size()
	print("")
	print("side   gap   ledge jump 12/20   top?   time    latches  wall jumps  peak / ledge")
	var fails := 0
	var bad_latch := 0
	for gap in GAPS:
		var line := ""
		var ok_all := true
		var times: Array = []
		var peak := 9999.0
		var latches := 0
		var kicks := 0
		for r in rows:
			if r["gap"] != gap:
				continue
			line += "yes " if r["ok"] else "NO  "
			ok_all = ok_all and r["ok"]
			times.append(r["time"])
			peak = minf(peak, r["peak"])
			latches = maxi(latches, r["latches"])
			kicks = maxi(kicks, r["kicks"])
		print("%-5s  %2df   %-16s  %-5s  %-6s  %-7d  %-10d  %3.0f / %.0f px" % ["left", gap, line.strip_edges(),
			"yes" if ok_all else "NO", ("%.2f s" % times.max()) if ok_all else "-", latches, kicks, minf(peak, 9999.0), need])
		if not ok_all:
			fails += 1
		if latches != hops or kicks != hops:
			bad_latch += 1
	print("")
	for r in rows:
		if not r["ok"]:
			print("  gap %df hold %df: %s" % [r["gap"], r["hold"], r["why"]])
	print("gaps tried=%d  failed gaps=%d  gaps with more than one latch or kick=%d" % [GAPS.size(), fails, bad_latch])
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
			return "gap %df hold %df: %s" % [r["gap"], r["hold"], r["why"]]
	for c in checks:
		if not c["ok"]:
			return c["text"]
	return "unknown"
