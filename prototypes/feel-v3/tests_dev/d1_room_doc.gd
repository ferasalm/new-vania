# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d1_room_doc.gd - proof for ledger N8 (the room builder's data).
#  d1  a room saved then loaded gives back the same room (all real rooms, and a real file)
#  d2  the palette picks up a PNG dropped into a temporary folder
#  d3  spreading places the right number of enemies on ground she can stand on
# Run: godot --headless --path . res://tests_dev/d1_room_doc.tscn
extends Node

const RoomDoc := preload("res://editor/room_doc.gd")
const EdAssets := preload("res://editor/ed_assets.gd")

var passed := 0
var failed := 0


func _ready() -> void:
	_d1()
	_d2()
	_d3()
	var ok := failed == 0 and passed > 0
	print("d1_room_doc %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _norm(t: String) -> String:
	# what room.gd reads: no carriage returns, right-trimmed rows, no empty lines
	var lines := t.replace("\r", "").split("\n", false)
	var out := ""
	for i in lines.size():
		out += (lines[i] if i == 0 else lines[i].strip_edges(false, true)) + "\n"
	return out


func _d1() -> void:
	var d := DirAccess.open("res://rooms")
	var bad: Array = []
	var n := 0
	for f in d.get_files():
		if not f.ends_with(".txt"):
			continue
		n += 1
		var text := FileAccess.get_file_as_string("res://rooms/" + f)
		var doc := RoomDoc.parse(f.get_basename(), text)
		if doc.to_text() != _norm(text):
			bad.append(f)
	_check("d1: all %d real rooms load and save back identical" % n, n >= 20 and bad.is_empty(), str(bad))
	# a real file written and read back, with an edit in between
	var text2 := FileAccess.get_file_as_string("res://rooms/church.txt")
	var doc2 := RoomDoc.parse("church", text2)
	var w: int = doc2.width()
	var h: int = doc2.height()
	doc2.push_undo()
	doc2.set_cell(5, 5, "H")
	doc2.add_prop("props/x.png", 32, 48, "front", false, true)
	var path := ProjectSettings.globalize_path("user://d1_room.txt")
	var ppath := ProjectSettings.globalize_path("user://d1_room.props.json")
	var f1 := FileAccess.open(path, FileAccess.WRITE)
	f1.store_string(doc2.to_text())
	f1.close()
	var f2 := FileAccess.open(ppath, FileAccess.WRITE)
	f2.store_string(doc2.props_text())
	f2.close()
	var back := RoomDoc.parse("church", FileAccess.get_file_as_string(path), FileAccess.get_file_as_string(ppath))
	_check("d1: a saved edit loads back as the same room", back.to_text() == doc2.to_text() and back.get_cell(5, 5) == "H",
		"cell=%s" % back.get_cell(5, 5))
	_check("d1: props survive the save", back.props.size() == 1 and back.props[0]["png"] == "props/x.png"
		and back.props[0]["layer"] == "front" and back.props[0]["flip"] == true and int(back.props[0]["x"]) == 32, str(back.props))
	_check("d1: size is kept", back.width() == w and back.height() == h, "%dx%d" % [back.width(), back.height()])
	# undo and redo
	doc2.undo()
	_check("d1: undo takes the edit back", doc2.get_cell(5, 5) != "H" and doc2.props.is_empty(), "cell=%s" % doc2.get_cell(5, 5))
	doc2.redo()
	_check("d1: redo puts it again", doc2.get_cell(5, 5) == "H" and doc2.props.size() == 1, "")
	# resize
	doc2.resize(w + 3, h + 2)
	_check("d1: resize grows with empty air", doc2.width() == w + 3 and doc2.height() == h + 2 and doc2.get_cell(w + 1, 1) == ".", "")
	doc2.resize(10, 6)
	_check("d1: resize shrinks", doc2.width() == 10 and doc2.height() == 6, "")


func _d2() -> void:
	var dir := ProjectSettings.globalize_path("user://d2_editor_%d" % Time.get_ticks_msec())
	EdAssets.root_override = dir
	EdAssets.ensure_folders()
	_check("d2: the three folders and the README are made", DirAccess.dir_exists_absolute(dir.path_join("tiles"))
		and DirAccess.dir_exists_absolute(dir.path_join("props")) and DirAccess.dir_exists_absolute(dir.path_join("backdrops"))
		and FileAccess.file_exists(dir.path_join("README.txt")), dir)
	_check("d2: an empty folder gives an empty palette tab", EdAssets.entries("PROPS").is_empty(), "")
	var img := Image.create(24, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.9, 0.2, 0.2))
	img.save_png(dir.path_join("props/candle_big.png"))
	img.save_png(dir.path_join("tiles/floor_a.png"))
	var pe := EdAssets.entries("PROPS")
	_check("d2: a PNG dropped into props appears in the palette", pe.size() == 1 and pe[0]["png"] == "props/candle_big.png"
		and pe[0]["name"] == "candle_big", str(pe))
	_check("d2: a PNG dropped into tiles appears in the tiles tab", EdAssets.entries("TILES").size() == 1, "")
	var tex := EdAssets.texture("props/candle_big.png")
	_check("d2: the picture loads (even though Godot never imported it)", tex != null and tex.get_size() == Vector2(24, 40),
		str(tex.get_size()) if tex != null else "null")
	_check("d2: the built-in tabs still have their characters", EdAssets.entries("TERRAIN").size() >= 10
		and EdAssets.entries("ENEMIES").size() >= 5 and EdAssets.entries("HAZARDS").size() == 4, "")
	EdAssets.root_override = ""
	EdAssets.clear_cache()


func _d3() -> void:
	# a wide hall: floor row, 6 rows of air above it, walls around
	var rows: Array = []
	rows.append("#".repeat(40))
	for i in 7:
		rows.append("#" + ".".repeat(38) + "#")
	rows.append("#".repeat(40))
	var doc := RoomDoc.parse("test", "theme=church\n" + "\n".join(rows) + "\n")
	var area := Rect2i(1, 1, 38, 7)
	var placed: int = doc.spread(area, ["H"], 6)
	var cells := _glyph_cells(doc, "H")
	_check("d3: spread places the number asked for", placed == 6 and cells.size() == 6, "placed=%d found=%d" % [placed, cells.size()])
	var all_ok := true
	for c in cells:
		all_ok = all_ok and doc.get_cell(c.x, c.y + 1) == "#" and doc.get_cell(c.x, c.y - 1) == "." and doc.get_cell(c.x, c.y - 2) == "."
	_check("d3: every ground enemy stands on floor with room above", all_ok, str(cells))
	var xs: Array = []
	for c in cells:
		xs.append(c.x)
	xs.sort()
	var gaps_ok := true
	for i in range(1, xs.size()):
		gaps_ok = gaps_ok and xs[i] - xs[i - 1] >= 3
	_check("d3: they are spread out, not stacked", gaps_ok, str(xs))
	# mixed kinds and a flyer
	var doc2 := RoomDoc.parse("test", "theme=church\n" + "\n".join(rows) + "\n")
	var p2: int = doc2.spread(area, ["H", "m", "c"], 6)
	var fl := _glyph_cells(doc2, "m")
	var fly_ok := not fl.is_empty()
	for c in fl:
		fly_ok = fly_ok and doc2.get_cell(c.x, c.y + 1) == "." and c.y >= 2
	_check("d3: kinds are used in turn and flyers hang in open air", p2 == 6 and _glyph_cells(doc2, "H").size() == 2 and fly_ok,
		"placed=%d H=%d m=%d c=%d" % [p2, _glyph_cells(doc2, "H").size(), fl.size(), _glyph_cells(doc2, "c").size()])
	# too little room: only what fits
	var doc3 := RoomDoc.parse("test", "theme=church\n" + "\n".join(rows) + "\n")
	var p3: int = doc3.spread(Rect2i(1, 7, 3, 1), ["H"], 5)
	_check("d3: with too little ground it places fewer and says so", p3 >= 1 and p3 < 5, "placed=%d" % p3)
	# a zone with no floor at all
	var p4: int = doc3.spread(Rect2i(1, 1, 38, 3), ["H"], 4)
	_check("d3: no standing room, no enemies", p4 == 0, "placed=%d" % p4)


func _glyph_cells(doc, g: String) -> Array:
	var out: Array = []
	for y in doc.height():
		for x in doc.width():
			if doc.get_cell(x, y) == g:
				out.append(Vector2i(x, y))
	return out


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])
