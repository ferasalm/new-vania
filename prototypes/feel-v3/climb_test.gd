# PROTOTYPE - NOT FOR PRODUCTION
# The lab wall climb, measured. Plays the lab with the wall latch granted and tries to
# get over the tall wall (the two-column "##" block) from both sides with slow, human
# timing: every press held at least 6 frames, 10 to 30 frames between a latch and the
# next jump press. The direction toward the wall is simply held the whole time.
# Run: godot --headless --path prototypes/feel-v3 res://climb_test.tscn
# Options after "--":  <tuning_key>=<number> (tries other wall_* numbers without
# touching tuning.json),  verbose (prints every latch and kick),  nocut (acts as if
# player.gd did not cut a wall jump short when jump is let go: jump_cut is 1 from the
# kick until she lands),  patched (applies the proposed player.gd lines themselves, in
# memory only: the real thing, measured).
# Add --fixed-fps 60 before --path to run it faster than real time (same physics steps;
# Engine.time_scale must NOT be used: it stretches the physics step itself).
extends Node

const Patch := preload("res://climb_test_patch.gd")
const TILE := 16.0
const HOLDS := [6, 12, 20]          # frames the jump button stays down
const GAPS := [10, 15, 20, 30]      # frames between "she latched" and the next jump press
const LIMIT := 600                  # frames (10 s) before a try counts as failed
const MAX_KICKS := 4                # more wall jumps than this is not a comfortable climb

var main: Node
var verbose := false
var nocut := false
var cut0 := 0.4
var wall_x0 := 0.0      # left face of the wall
var wall_x1 := 0.0      # right face
var wall_top := 0.0     # y of the top of the wall
var floor_y := 0.0
var rows: Array = []
var gate: Array = []
var gate_broken := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "verbose":
			verbose = true
		elif a == "patched":
			# the real proposed player.gd lines, applied in memory (see climb_test_patch.gd)
			if not Patch.take_over("res://player.gd", Patch.PLAYER):
				print("CLIMB FAIL  (the proposed player.gd lines could not be applied)")
				get_tree().quit(1)
				return
		elif a == "nocut":
			nocut = true      # tries the proposed player.gd change: a wall jump is never cut short
			print("override  wall jumps are not cut by letting go of jump (proposed player.gd change)")
		elif a.contains("=") and T.data.has(a.get_slice("=", 0)):
			T.set_v(a.get_slice("=", 0), float(a.get_slice("=", 1)))
			print("override  %s = %s" % [a.get_slice("=", 0), a.get_slice("=", 1)])
	cut0 = T.v("jump_cut")
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
	print("wall: columns %d-%d, top y=%.0f, floor y=%.0f, height to climb %.0f px (%.0f tiles)" % [
		int(wall_x0 / TILE), int(wall_x1 / TILE) - 1, wall_top, floor_y, floor_y - wall_top, (floor_y - wall_top) / TILE])
	print("numbers: jump %.0f  gravity %.0f  jump_cut %.2f  wall_jump %.0f  push %.0f  lock %.2f  latch %.1f s  slide %.0f" % [
		T.v("jump_velocity"), T.v("gravity"), T.v("jump_cut"), T.v("wall_jump_velocity"), T.v("wall_jump_push"),
		T.v("wall_jump_lock"), T.v("wall_latch_time"), T.v("wall_slide_speed")])
	for side in ["left", "right"]:
		for hold in HOLDS:
			for gap in GAPS:
				rows.append(await _try(side, hold, gap))
	# the gate: without the relic the wall must NOT be passable
	main.has_latch = false
	for side in ["left", "right"]:
		var r: Dictionary = await _try(side, 30, 10, 240)
		gate.append("%-5s  from the floor, full jumps, no relic: over? %s   peak %.0f / %.0f px" % [side, "YES (BAD)" if r["ok"] else "no", r["peak"], floor_y - wall_top])
		gate_broken = gate_broken or r["ok"]
		await _gate_ledges(side)
	main.has_latch = true
	_report()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _gate_ledges(side: String) -> void:
	# every ledge or block near the wall that she could take a running jump from:
	# run to its end, jump at the edge with the button held, keep steering at the wall
	var p: CharacterBody2D = main.player
	var sgn := 1.0 if side == "left" else -1.0
	var face := wall_x0 if side == "left" else wall_x1
	var toward := "right" if side == "left" else "left"
	var col0 := int(wall_x0 / TILE) - 1 if side == "left" else int(wall_x1 / TILE)
	for y in range(int(wall_top / TILE) - 3, int(floor_y / TILE)):
		var x := col0
		var n := 0
		while n < 22 and x > 1 and x < main.room.grid[y].length() - 1:
			var ch: String = main.room.cell(x, y)
			var here: bool = (ch == "#" or ch == "=") and main.room.cell(x, y - 1) != "#" and main.room.cell(x, y - 2) != "#"
			if here:
				break
			x -= int(sgn)
			n += 1
		if n >= 22 or x <= 1 or x >= main.room.grid[y].length() - 1:
			continue
		# x is the cell of this row nearest the wall that she can stand on
		var edge := (x + 1) * TILE if side == "left" else x * TILE
		for a in ["left", "right", "jump", "down", "up"]:
			Input.action_release(a)
		p.global_position = Vector2(edge - sgn * 10.0, y * TILE)
		p.velocity = Vector2.ZERO
		p.state = "move"
		await _frames(30)
		var top_y := p.global_position.y
		var jumped := false
		var over := false
		Input.action_press(toward)
		for f in 200:
			if not jumped and (p.global_position.x - edge) * sgn > -3.0:
				jumped = true
				Input.action_press("jump")
			await get_tree().physics_frame
			top_y = minf(top_y, p.global_position.y)
			if (p.global_position.x - face) * sgn > 6.0:
				over = true
				break
			if jumped and p.is_on_floor() and f > 20:
				break
		for a in ["left", "right", "jump"]:
			Input.action_release(a)
		gate.append("%-5s  running jump off the ledge at column %d, %.0f px up, no relic: over? %s   peak %.0f / %.0f px, got to %.0f px from the wall" % [
			side, x, floor_y - y * TILE, "YES (BAD)" if over else "no", floor_y - top_y, floor_y - wall_top, maxf(0.0, (face - p.global_position.x) * sgn - 6.0)])
		gate_broken = gate_broken or over
		await _frames(30)


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


func _try(side: String, hold: int, gap: int, limit: int = LIMIT) -> Dictionary:
	var p: CharacterBody2D = main.player
	var toward := "right" if side == "left" else "left"
	var sgn := 1.0 if side == "left" else -1.0
	var face := wall_x0 if side == "left" else wall_x1
	for a in ["left", "right", "jump", "down", "up"]:
		Input.action_release(a)
	p.global_position = Vector2(face - sgn * 54.0, floor_y)
	p.velocity = Vector2.ZERO
	p.state = "move"
	await _frames(40)
	var top_y := p.global_position.y
	var kicks := 0
	var floor_jumps := 0
	var latches := 0
	var jump_left := 0          # frames the jump button still stays down
	var wait := -1              # frames until the next jump press (-1 = none planned)
	var was_wall := false
	var was_floor := true
	var done := -1
	var frame := 0
	Input.action_press(toward)
	await _frames(6)            # she starts running first, like a person would
	while frame < limit:
		var on_wall: bool = p.state == "wall"
		var on_floor: bool = p.is_on_floor()
		if nocut and on_floor:
			T.set_v("jump_cut", cut0)
		if on_wall and not was_wall:
			latches += 1
			wait = gap
			if verbose:
				print("    f%03d latch at height %.0f" % [frame, floor_y - p.global_position.y])
		if on_floor and not on_wall and jump_left == 0 and wait < 0 and absf(p.global_position.y - floor_y) < 1.0:
			# on the ground by the wall (the start, or she fell back): jump again when close
			if absf(p.global_position.x - face) < 24.0:
				wait = 0 if floor_jumps == 0 else gap
		if wait == 0 and jump_left == 0:
			if on_wall:
				kicks += 1
				if nocut:
					T.set_v("jump_cut", 1.0)
				if verbose:
					print("    f%03d kick %d from height %.0f" % [frame, kicks, floor_y - p.global_position.y])
			elif on_floor:
				floor_jumps += 1
			if on_wall or on_floor:
				Input.action_press("jump")
				jump_left = hold
			wait = -1
		elif wait > 0:
			wait -= 1
		was_wall = on_wall
		was_floor = on_floor
		await get_tree().physics_frame
		frame += 1
		if jump_left > 0:
			jump_left -= 1
			if jump_left == 0:
				Input.action_release("jump")
		top_y = minf(top_y, p.global_position.y)
		var over: bool = (p.global_position.x - face) * sgn > 6.0 and p.global_position.y <= wall_top + 1.0
		if over and p.is_on_floor():
			done = frame
			break
		if (p.global_position.x - (wall_x1 if side == "left" else wall_x0)) * sgn > 8.0:
			done = frame
			break
	for a in ["left", "right", "jump"]:
		Input.action_release(a)
	T.set_v("jump_cut", cut0)
	var row := {"side": side, "hold": hold, "gap": gap, "ok": done >= 0, "time": done / 60.0, "kicks": kicks,
		"floor_jumps": floor_jumps, "latches": latches, "peak": floor_y - top_y}
	if verbose:
		print("  %s" % str(row))
	return row


func _report() -> void:
	var need := floor_y - wall_top
	print("")
	print("side   hold  gap   over?  time    wall jumps  floor jumps  peak / needed")
	var fails := 0
	var hard := 0
	var worst := 0
	for r in rows:
		var kind := "slow" if r["gap"] <= 15 else "sloppy"
		print("%-5s  %2df   %2df   %-5s  %-6s  %-10s  %-11d  %3.0f / %.0f px   (%s)" % [r["side"], r["hold"], r["gap"],
			"yes" if r["ok"] else "NO", ("%.2f s" % r["time"]) if r["ok"] else "-", str(r["kicks"]), r["floor_jumps"],
			r["peak"], need, kind])
		if not r["ok"]:
			fails += 1
		else:
			worst = maxi(worst, r["kicks"])
			if r["kicks"] > MAX_KICKS:
				hard += 1
	print("")
	print("tries=%d  failed=%d  needed more than %d wall jumps=%d  most wall jumps in a success=%d" % [rows.size(), fails, MAX_KICKS, hard, worst])
	print("gate (the wall must stop her without the relic):")
	for g in gate:
		print("  " + g)
	var ok := fails == 0 and hard == 0 and not gate_broken
	print("CLIMB %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
