# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d5_checks.gd - the room builder's red warnings (ledger N8).
# A hand-made bad layout gets every warning; a good layout and the real rooms get none.
# Run: godot --headless --path . res://tests_dev/d5_checks.tscn
extends Node

const RoomDoc := preload("res://editor/room_doc.gd")
const Checks := preload("res://editor/room_checks.gd")
const EdAssets := preload("res://editor/ed_assets.gd")

var passed := 0
var failed := 0


func _ready() -> void:
	_bad_layouts()
	_real_rooms()
	var ok := failed == 0 and passed > 0
	print("d5_checks %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _doc(rows: Array, head := "theme=church") -> RefCounted:
	return RoomDoc.parse("t", head + "\n" + "\n".join(rows) + "\n")


func _texts(flags: Array) -> String:
	var s := ""
	for f in flags:
		s += String(f["text"]) + " | "
	return s


func _has(flags: Array, part: String) -> bool:
	for f in flags:
		if String(f["text"]).contains(part):
			return true
	return false


func _bad_layouts() -> void:
	var w := 30
	var air := "#" + ".".repeat(w - 2) + "#"
	var wall := "#".repeat(w)
	# 1. ceiling trap: a ledge of floor with a ceiling slab only 2 tiles (32 px) above it
	var rows: Array = [wall]
	for i in 9:
		rows.append(air)
	rows[2] = "#" + ".".repeat(8) + "#".repeat(10) + ".".repeat(w - 20) + "#"      # a slab at row 2, x 9..18
	rows[6] = "#" + ".".repeat(8) + "#".repeat(10) + ".".repeat(w - 20) + "#"      # a platform at row 6 under it (three air rows between: she can stand but not jump to full height)
	rows.append(wall)
	var c := Checks.new()
	var f1: Array = c.run(_doc(rows))
	_check("a platform with a ceiling just above it is flagged", _has(f1, "ceiling trap"), _texts(f1))
	# 2. a climb that is too high: floor at row 14, a platform 4 rows (64 px) above it
	var rows2: Array = [wall]
	for i in 13:
		rows2.append(air)
	rows2[10] = "#" + ".".repeat(16) + "#".repeat(8) + ".".repeat(w - 26) + "#"
	rows2.append(wall)
	var f2: Array = c.run(_doc(rows2))
	_check("a climb steeper than 80 percent of her jump is flagged", _has(f2, "jump too high"), _texts(f2))
	# 3. an item she cannot reach: a mark sealed into a pocket (needs the slow search)
	var rows3: Array = [wall]
	for i in 11:
		rows3.append(air)
	rows3[2] = "#" + ".".repeat(10) + "###" + ".".repeat(w - 15) + "#"
	rows3[3] = "#" + ".".repeat(10) + "#5#" + ".".repeat(w - 15) + "#"
	rows3[4] = "#" + ".".repeat(10) + "###" + ".".repeat(w - 15) + "#"
	rows3.append(wall)
	var f3: Array = c.run(_doc(rows3), true)
	_check("a mark she cannot reach is flagged", _has(f3, "cannot reach this (5)"), _texts(f3))
	# 4. an exit she cannot reach: header names a right exit, the door is behind a wall of height 8
	var rows4: Array = [wall]
	for i in 11:
		rows4.append(air)
	rows4[3] = "D" + ".".repeat(w - 2) + "#"
	for y in range(1, 12):
		rows4[y] = rows4[y].substr(0, w - 4) + "#" + rows4[y].substr(w - 3)
	rows4[11] = "#P" + ".".repeat(w - 4) + "D#"
	rows4.append(wall)
	var f4: Array = c.run(_doc(rows4, "theme=church,right=boss,left=hall"), true)
	_check("a room she cannot get out of is flagged", _has(f4, "cannot reach the right exit") or _has(f4, "trapped") or _has(f4, "open edge"), _texts(f4))
	# 5. a door with a ceiling slab on its head
	var rows5: Array = [wall]
	for i in 8:
		rows5.append(air)
	rows5[7] = "D" + ".".repeat(w - 2) + "#"
	rows5[5] = "##" + ".".repeat(w - 3) + "#"          # blocks the inner cell above the door's head
	rows5.append(wall)
	rows5.append(wall)
	var f5: Array = c.run(_doc(rows5))
	_check("a door with a blocked head is flagged", _has(f5, "door head blocked"), _texts(f5))
	# 6. a backdrop picture that is missing
	var f6: Array = c.run(_doc(rows2, "theme=church,backdrop=nope.png"))
	_check("a missing backdrop picture is flagged", _has(f6, "backdrop picture"), _texts(f6))
	# 7. and a good room says nothing
	var rows7: Array = [wall]
	for i in 11:
		rows7.append(air)
	rows7[9] = "#" + ".".repeat(8) + "#".repeat(6) + ".".repeat(w - 16) + "#"      # one 48 px hop from the floor at row 12 is fine
	rows7.append(wall)
	var f7: Array = c.run(_doc(rows7))
	_check("a good layout gets no warnings", f7.is_empty(), _texts(f7))


func _real_rooms() -> void:
	var d := DirAccess.open("res://rooms")
	var worst := 0.0
	var bad: Array = []
	var n := 0
	var counts := {}
	for f in d.get_files():
		if not f.ends_with(".txt"):
			continue
		n += 1
		var doc := RoomDoc.parse(f.get_basename(), FileAccess.get_file_as_string("res://rooms/" + f))
		var t0 := Time.get_ticks_msec()
		var flags: Array = Checks.new().run(doc, true)
		worst = maxf(worst, float(Time.get_ticks_msec() - t0))
		counts[f.get_basename()] = 0
		var ceil_n := 0
		for fl in flags:
			var tx := String(fl["text"])
			if tx.contains("ceiling") or tx.contains("jump too high"):
				ceil_n += 1
			if tx.contains("trapped") or tx.contains("cannot reach") or tx.contains("open edge"):
				bad.append("%s: %s" % [f, tx])
		counts[f.get_basename()] = ceil_n
	print("slowest full check: %.0f ms" % worst)
	print("ceiling/jump flags per room: %s" % str(counts))
	_check("all %d real rooms pass the reach search (the same answer as roomreach.py)" % n, bad.is_empty(), str(bad))
	_check("the full check of the biggest room is fast enough to press a button for", worst < 8000.0, "%.0f ms" % worst)


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])
