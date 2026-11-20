# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d9_palette.gd - Studio slice S3 gate (ledger N22, N23, N24): the asset library inside the room builder.
# Written from the spec only (production/briefs/2026-11-20/S3-deepseek.md); never from the code.
# Run: godot --headless --path . res://tests_dev/d9_palette.tscn      (expect "d9_palette PASS n/n")
#
# Contract under test (all static functions unless noted):
#   EdCatalog  (res://editor/ed_catalog.gd, extends RefCounted)
#     load_file(path) -> int       REPLACES the table with the entries of a catalog.json ({version, generated, categories, entries});
#                                  entries without a String id or name are skipped; a missing, unreadable or invalid file returns 0
#                                  and leaves the table unchanged
#     clear(), entry_count() -> int, entry(id) -> Dictionary ({} when unknown)
#     categories() -> Array        [{"id", "count"}] COMPUTED from the entries (never trusted from the file), sorted by id
#     search(text, category := "", limit := 0) -> Array
#                                  entries whose name, category, sub or any tag contains EVERY whitespace-separated word of text
#                                  (case-insensitive); category "" means all, otherwise an exact match; sorted by name then id;
#                                  limit 0 means no limit
#     placeable_reason(entry) -> String   "" when entry.placeable is "tiles", "props" or "backdrops"; otherwise one plain sentence:
#                                  kind audio mentions "sound", 3d mentions "3D", inbox mentions "inbox", source mentions "source",
#                                  any other (a picture with placeable null) mentions "picture"
#   EdAssets   (res://editor/ed_assets.gd)  new:
#     static var library_override := "" ; library_root() -> String (the override, else <project dir>/studio/library)
#     adopt(entry) -> String       copy a placeable .png from library_root()/entry.path into editor_root()/<placeable>/<file name>
#                                  and return "<placeable>/<file name>"; same bytes already there -> reuse; different bytes with the same
#                                  name -> "<stem>_<last 6 characters of id>.png" and the old file is untouched; anything not placeable,
#                                  not a .png, missing in the library, or whose path leaves the library folder -> "" and nothing is written
#   EdPalette  (res://editor/ed_palette.gd, extends Control; EdPalette.new() then add_child)
#     public: search_box: LineEdit, category_box: OptionButton (first item "All", then one per category id), help_button: Button,
#             use_button: Button; signals entry_picked(entry), entry_used(entry)
#     search_text(text), set_category(id), refresh(), result_count(), result_entry(i), truncated(), const MAX_RESULTS = 300,
#     pick(i), selected_id(), help_key() ("asset:<id>" or ""), info_text(), use_selected() -> bool, result_icon(i) -> Texture2D,
#     static var thumb_loads: int (pictures read from disk since the last clear_thumbs(); cache hits and missing files do not count),
#     static func clear_thumbs(). A thumbnail keeps its size when the picture is 48 px or smaller on both sides; a bigger one is scaled
#     down to fit 48 x 48 keeping its shape. Non-picture entries and pictures missing from the library have no thumbnail (null).
#   RoomBuilder (the F2 builder, Dev.open_tool("dev_room")) new: library_button: Button ("Library", in the palette panel),
#     library_palette (null unless open), open_library() (when already open it keeps the same palette), close_library(),
#     use_library_entry(entry) -> bool (adopt, switch to the tab named by entry.placeable upper-cased, select the copied picture, arm
#     the PLACE tool; false and no change for a non-placeable entry). A picture used from the overlay's own entry_used closes the overlay.
extends Node

const EdCatalog := preload("res://editor/ed_catalog.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const EdPalette := preload("res://editor/ed_palette.gd")
const EdHelp := preload("res://editor/ed_help.gd")
const WorkspaceFiles := preload("res://editor/workspace_files.gd")

var passed := 0
var failed := 0
var main: Node = null
var base := ""
var libdir := ""
var edir := ""
var catalog_path := ""
var used: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# unique per run: the milliseconds since start alone can repeat between runs and find an old room file
	base = ProjectSettings.globalize_path("user://d9_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	libdir = base.path_join("library")
	edir = base.path_join("editor")
	catalog_path = base.path_join("catalog.json")
	EdAssets.library_override = libdir
	EdAssets.root_override = edir
	_make_fixture()
	await get_tree().process_frame
	_units()
	await _palette()
	await _builder()
	EdHelp.hide()
	EdAssets.library_override = ""
	EdAssets.root_override = ""
	var ok := failed == 0 and passed > 0
	print("d9_palette %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _png(rel: String, w: int, h: int, c: Color) -> void:
	var path := libdir.path_join(rel)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	img.save_png(path)


func _e(id: String, nm: String, cat: String, sub: String, kind: String, path: String, w: Variant, h: Variant, tags: Array, placeable: Variant) -> Dictionary:
	return {"id": id, "name": nm, "category": cat, "sub": sub, "kind": kind, "path": path, "source": "src/" + nm, "w": w, "h": h,
		"bytes": 100, "tags": tags, "placeable": placeable, "help_key": "asset:" + id}


func _fixture_entries() -> Array:
	return [
		_e("env_lamp_aaaaaa", "lamp.png", "environment", "1x", "image", "environment/1x/lamp.png", 16, 24, ["environment", "1x", "lamp", "glow"], "props"),
		_e("env_brick_bbbbbb", "brick_tile.png", "environment", "1x", "image", "environment/1x/brick_tile.png", 16, 16, ["environment", "brick", "tile"], "tiles"),
		_e("env_sky_cccccc", "sky.png", "environment", "1x", "image", "environment/1x/sky.png", 120, 60, ["environment", "sky"], "backdrops"),
		_e("chr_pandora_dddddd", "pandora_idle.png", "characters", "pandora", "image", "characters/pandora/pandora_idle.png", 90, 90, ["characters", "pandora"], null),
		_e("aud_toll_eeeeee", "toll.ogg", "audio", "sfx", "audio", "audio/sfx/toll.ogg", null, null, ["audio", "toll"], null),
		_e("inb_raw_ffffff", "raw.png", "inbox", "", "inbox", "", null, null, ["inbox"], null),
		_e("mdl_fig_aaaaab", "fig.glb", "models", "", "3d", "", null, null, ["models", "fig"], null),
		_e("src_ase_aaaaac", "model.aseprite", "source", "", "source", "source/model.aseprite", null, null, ["source"], null),
	]


func _make_fixture() -> void:
	_png("environment/1x/lamp.png", 16, 24, Color(0.9, 0.8, 0.1))
	_png("environment/1x/brick_tile.png", 16, 16, Color(0.5, 0.2, 0.2))
	_png("environment/1x/sky.png", 120, 60, Color(0.1, 0.1, 0.4))
	_png("environment/2x/lamp.png", 32, 48, Color(0.1, 0.9, 0.1))
	_png("characters/pandora/pandora_idle.png", 90, 90, Color(0.8, 0.3, 0.6))
	var jimg := Image.create(8, 8, false, Image.FORMAT_RGB8)
	jimg.fill(Color(0.3, 0.3, 0.3))
	jimg.save_jpg(libdir.path_join("environment/1x/pic.jpg"))
	var f := FileAccess.open(catalog_path, FileAccess.WRITE)
	var entries := _fixture_entries()
	entries.append({"name": "an entry without an id"})
	entries.append("not a dictionary")
	f.store_string(JSON.stringify({"version": 1, "generated": "2026-11-21T00:00:00Z",
		"categories": [{"id": "environment", "count": 99}], "entries": entries}))
	f.close()


func _units() -> void:
	EdCatalog.clear()
	_check("an empty catalog has no entries", EdCatalog.entry_count() == 0 and EdCatalog.search("").is_empty(), "")
	var n := EdCatalog.load_file(catalog_path)
	_check("load_file returns the valid entries (8, the two junk values are skipped)", n == 8 and EdCatalog.entry_count() == 8, "n=%d" % n)
	_check("a missing file loads 0 and changes nothing", EdCatalog.load_file(base.path_join("nope.json")) == 0 and EdCatalog.entry_count() == 8, "")
	var bad := base.path_join("bad.json")
	var f := FileAccess.open(bad, FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	_check("an invalid file loads 0 and changes nothing", EdCatalog.load_file(bad) == 0 and EdCatalog.entry_count() == 8, "")

	_check("entry(id) finds an entry", String(EdCatalog.entry("env_lamp_aaaaaa").get("name", "")) == "lamp.png", "")
	_check("entry(unknown id) is empty", EdCatalog.entry("nope").is_empty(), "")

	var cats := EdCatalog.categories()
	var ids: Array = []
	var counts: Array = []
	for c in cats:
		ids.append(c["id"])
		counts.append(c["count"])
	_check("categories are computed from the entries, sorted by id", ids == ["audio", "characters", "environment", "inbox", "models", "source"], "ids=%s" % str(ids))
	_check("category counts come from the entries (the file said 99)", counts == [1, 1, 3, 1, 1, 1], "counts=%s" % str(counts))

	var names := func(arr: Array) -> Array:
		var out: Array = []
		for e in arr:
			out.append(e["name"])
		return out
	_check("search with no text returns everything sorted by name", names.call(EdCatalog.search("")) == ["brick_tile.png", "fig.glb", "lamp.png", "model.aseprite", "pandora_idle.png", "raw.png", "sky.png", "toll.ogg"], "got=%s" % str(names.call(EdCatalog.search(""))))
	_check("search matches a name", names.call(EdCatalog.search("lamp")) == ["lamp.png"], "")
	_check("search ignores case", EdCatalog.search("LAMP").size() == 1, "")
	_check("search matches a category word", EdCatalog.search("environment").size() == 3, "n=%d" % EdCatalog.search("environment").size())
	_check("search matches a tag that is not in the name", names.call(EdCatalog.search("glow")) == ["lamp.png"], "")
	_check("search needs every word to match", names.call(EdCatalog.search("1x lamp")) == ["lamp.png"] and EdCatalog.search("lamp brick").is_empty(), "")
	_check("search with a category filter", EdCatalog.search("", "environment").size() == 3 and EdCatalog.search("lamp", "characters").is_empty() and EdCatalog.search("lamp", "environment").size() == 1, "")
	_check("search matches a sub folder word", EdCatalog.search("1x").size() == 3, "n=%d" % EdCatalog.search("1x").size())
	var two := EdCatalog.search("", "", 2)
	_check("search honours a limit", two.size() == 2 and two[0]["name"] == "brick_tile.png", "n=%d" % two.size())

	_check("a props entry is placeable (no reason)", EdCatalog.placeable_reason(EdCatalog.entry("env_lamp_aaaaaa")) == "", "")
	_check("a tiles entry is placeable", EdCatalog.placeable_reason(EdCatalog.entry("env_brick_bbbbbb")) == "", "")
	_check("a backdrops entry is placeable", EdCatalog.placeable_reason(EdCatalog.entry("env_sky_cccccc")) == "", "")
	_check("a character picture says why not (mentions picture)", EdCatalog.placeable_reason(EdCatalog.entry("chr_pandora_dddddd")).to_lower().contains("picture"), EdCatalog.placeable_reason(EdCatalog.entry("chr_pandora_dddddd")))
	_check("a sound says why not (mentions sound)", EdCatalog.placeable_reason(EdCatalog.entry("aud_toll_eeeeee")).to_lower().contains("sound"), "")
	_check("an inbox file says why not (mentions inbox)", EdCatalog.placeable_reason(EdCatalog.entry("inb_raw_ffffff")).to_lower().contains("inbox"), "")
	_check("a 3D model says why not (mentions 3D)", EdCatalog.placeable_reason(EdCatalog.entry("mdl_fig_aaaaab")).contains("3D"), "")
	_check("a source file says why not (mentions source)", EdCatalog.placeable_reason(EdCatalog.entry("src_ase_aaaaac")).to_lower().contains("source"), "")

	# ---- adopt: copy into the builder's own folders so the game can load it ----
	EdAssets.ensure_folders()
	var lamp := EdCatalog.entry("env_lamp_aaaaaa")
	var rel := EdAssets.adopt(lamp)
	_check("adopt returns props/lamp.png", rel == "props/lamp.png", "rel=%s" % rel)
	var src_bytes := FileAccess.get_file_as_bytes(libdir.path_join("environment/1x/lamp.png"))
	_check("the adopted file has the same bytes as the library file", FileAccess.file_exists(edir.path_join("props/lamp.png")) and FileAccess.get_file_as_bytes(edir.path_join("props/lamp.png")) == src_bytes, "")
	_check("adopting again returns the same path", EdAssets.adopt(lamp) == "props/lamp.png", "")
	_check("a tiles entry goes to tiles/", EdAssets.adopt(EdCatalog.entry("env_brick_bbbbbb")) == "tiles/brick_tile.png" and FileAccess.file_exists(edir.path_join("tiles/brick_tile.png")), "")
	_check("a backdrops entry goes to backdrops/", EdAssets.adopt(EdCatalog.entry("env_sky_cccccc")) == "backdrops/sky.png" and FileAccess.file_exists(edir.path_join("backdrops/sky.png")), "")
	var clash := _e("env_lamp_zzzzzz", "lamp.png", "environment", "2x", "image", "environment/2x/lamp.png", 32, 48, ["lamp"], "props")
	var rel2 := EdAssets.adopt(clash)
	_check("a different file with the same name gets the id's last 6 characters", rel2 == "props/lamp_zzzzzz.png" and FileAccess.file_exists(edir.path_join("props/lamp_zzzzzz.png")), "rel=%s" % rel2)
	_check("the first file is untouched by the clash", FileAccess.get_file_as_bytes(edir.path_join("props/lamp.png")) == src_bytes, "")
	_check("adopting the clash again reuses its file", EdAssets.adopt(clash) == rel2, "")
	var before := _count_files(edir)
	_check("a character picture is not adopted", EdAssets.adopt(EdCatalog.entry("chr_pandora_dddddd")) == "", "")
	_check("a sound is not adopted", EdAssets.adopt(EdCatalog.entry("aud_toll_eeeeee")) == "", "")
	_check("an inbox entry is not adopted", EdAssets.adopt(EdCatalog.entry("inb_raw_ffffff")) == "", "")
	var missing := _e("env_gone_111111", "gone.png", "environment", "1x", "image", "environment/1x/gone.png", 8, 8, [], "props")
	_check("a placeable entry whose library file is missing is not adopted", EdAssets.adopt(missing) == "", "")
	var jpg := _e("env_pic_222222", "pic.jpg", "environment", "1x", "image", "environment/1x/pic.jpg", 8, 8, [], "props")
	_check("a .jpg is not adopted", EdAssets.adopt(jpg) == "", "")
	var evil := _e("env_evil_333333", "evil.png", "environment", "1x", "image", "../editor/props/lamp.png", 8, 8, [], "tiles")
	_check("a path that leaves the library folder is not adopted", EdAssets.adopt(evil) == "", "")
	var odd := _e("env_odd_444444", "odd.png", "environment", "1x", "image", "environment/1x/lamp.png", 16, 24, [], "weird")
	_check("an entry with an unknown placeable kind is not adopted", EdAssets.adopt(odd) == "" and not DirAccess.dir_exists_absolute(edir.path_join("weird")), "")
	_check("refused entries wrote nothing", _count_files(edir) == before, "before=%d after=%d" % [before, _count_files(edir)])


func _count_files(dir: String) -> int:
	var n := 0
	for sub in ["tiles", "props", "backdrops"]:
		var d := DirAccess.open(dir.path_join(sub))
		if d != null:
			n += d.get_files().size()
	return n


func _index_of(p: Control, nm: String) -> int:
	for i in p.result_count():
		if p.result_entry(i)["name"] == nm:
			return i
	return -1


func _palette() -> void:
	EdCatalog.clear()
	EdCatalog.load_file(catalog_path)
	EdPalette.clear_thumbs()
	var p = EdPalette.new()
	p.size = Vector2(900, 520)
	add_child(p)
	await get_tree().process_frame
	await get_tree().process_frame
	_check("the palette lists everything at first", p.result_count() == 8 and not p.truncated(), "n=%d" % p.result_count())
	_check("the category box has All plus one item per category", p.category_box.item_count == 7 and p.category_box.get_item_text(0) == "All", "n=%d" % p.category_box.item_count)
	p.search_text("lamp")
	_check("search_text filters the list and shows the text", p.result_count() == 1 and p.search_box.text == "lamp", "n=%d" % p.result_count())
	p.search_box.text_changed.emit("brick")
	_check("typing in the search box filters the list", p.result_count() == 1 and p.result_entry(0)["name"] == "brick_tile.png", "n=%d" % p.result_count())
	p.search_text("")
	p.set_category("environment")
	_check("set_category filters the list", p.result_count() == 3, "n=%d" % p.result_count())
	p.search_text("lamp")
	_check("category and text combine", p.result_count() == 1, "")
	p.search_text("")
	p.set_category("")
	_check("clearing both shows everything again", p.result_count() == 8, "")

	# thumbnails (the character picture is removed from the library first, so it counts as a picture whose file is missing)
	DirAccess.remove_absolute(libdir.path_join("characters/pandora/pandora_idle.png"))
	var lamp_i := _index_of(p, "lamp.png")
	var sky_i := _index_of(p, "sky.png")
	EdPalette.clear_thumbs()
	var icon = p.result_icon(lamp_i)
	var sky_icon = p.result_icon(sky_i)
	p.result_icon(lamp_i)
	p.result_icon(lamp_i)
	_check("a thumbnail is read from disk once and then cached", EdPalette.thumb_loads == 2, "loads=%d (lamp and sky, each once)" % EdPalette.thumb_loads)
	_check("an image entry has a thumbnail", icon is Texture2D, "icon=%s" % str(icon))
	_check("a small picture keeps its size (16 x 24)", icon is Texture2D and icon.get_width() == 16 and icon.get_height() == 24, "size=%s" % (str(icon.get_size()) if icon is Texture2D else "none"))
	_check("a bigger picture is scaled down to fit 48 x 48 (120 x 60 becomes 48 x 24)", sky_icon is Texture2D and sky_icon.get_width() == 48 and sky_icon.get_height() == 24, "size=%s" % (str(sky_icon.get_size()) if sky_icon is Texture2D else "none"))
	_check("a sound has no thumbnail", p.result_icon(_index_of(p, "toll.ogg")) == null, "")
	_check("a picture missing from the library has no thumbnail", p.result_icon(_index_of(p, "pandora_idle.png")) == null, "")
	_check("misses and non-pictures did not count as disk reads", EdPalette.thumb_loads == 2, "loads=%d" % EdPalette.thumb_loads)
	EdPalette.clear_thumbs()
	_check("clear_thumbs resets the cache and the counter", EdPalette.thumb_loads == 0, "")

	# nothing picked yet
	_check("nothing picked: no help key, no use", p.help_key() == "" and p.selected_id() == "" and not p.use_selected(), "")

	# pick a placeable entry
	used.clear()
	p.entry_used.connect(func(e: Dictionary) -> void: used.append(e))
	p.pick(lamp_i)
	_check("pick selects the entry", p.selected_id() == "env_lamp_aaaaaa", "id=%s" % p.selected_id())
	_check("help_key is asset:<id>", p.help_key() == "asset:env_lamp_aaaaaa", "key=%s" % p.help_key())
	var info := p.info_text()
	for s in ["lamp.png", "environment", "16x24", "environment/1x/lamp.png", "props"]:
		_check("the info pane shows '%s'" % s, info.contains(s), "info=%s" % info.left(160))
	_check("the pick registered help for the asset", EdHelp.has("asset:env_lamp_aaaaaa") and EdHelp.text_for("asset:env_lamp_aaaaaa").contains("lamp.png"), "")
	_check("the use button is on for a placeable entry", not p.use_button.disabled, "")
	p.help_button.pressed.emit()
	_check("the ? button opens help for the asset", EdHelp.is_open() and EdHelp.current_key() == "asset:env_lamp_aaaaaa", "open=%s key=%s" % [str(EdHelp.is_open()), EdHelp.current_key()])
	EdHelp.hide()
	_check("use_selected returns true and emits entry_used once", p.use_selected() and used.size() == 1 and used[0]["id"] == "env_lamp_aaaaaa", "used=%d" % used.size())
	p.use_button.pressed.emit()
	_check("the use button emits too", used.size() == 2, "used=%d" % used.size())

	# pick a non-placeable entry
	used.clear()
	p.pick(_index_of(p, "toll.ogg"))
	_check("a sound shows its reason in the info pane", p.info_text().to_lower().contains("sound") and p.info_text().contains("toll.ogg"), "info=%s" % p.info_text().left(120))
	_check("the use button is off for a sound", p.use_button.disabled, "")
	_check("use_selected refuses a sound and emits nothing", not p.use_selected() and used.is_empty(), "")
	_check("a sound still has a help key and help text", p.help_key() == "asset:aud_toll_eeeeee" and EdHelp.has("asset:aud_toll_eeeeee"), "")

	# a big catalog is capped
	var bulk: Array = []
	for i in 350:
		bulk.append(_e("bulk_%03d_abcdef" % i, "item_%03d.png" % i, "bulk", "", "image", "bulk/item_%03d.png" % i, 8, 8, ["bulk"], null))
	var bp := base.path_join("bulk.json")
	var f := FileAccess.open(bp, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "generated": "x", "categories": [], "entries": bulk}))
	f.close()
	EdCatalog.load_file(bp)
	_check("loading a new catalog replaces the old table (350, not 358)", EdCatalog.entry_count() == 350, "n=%d" % EdCatalog.entry_count())
	p.search_text("")
	p.set_category("")
	_check("a big catalog is capped at MAX_RESULTS and says so", p.result_count() == 300 and p.truncated() and EdPalette.MAX_RESULTS == 300, "n=%d" % p.result_count())
	p.search_text("item_34")
	_check("a narrower search is not capped", p.result_count() == 10 and not p.truncated(), "n=%d" % p.result_count())
	p.queue_free()
	await get_tree().process_frame
	EdCatalog.clear()
	EdCatalog.load_file(catalog_path)


func _builder() -> void:
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	await main.debug_enter("church", "left", false)
	await _frames(10)
	var proj := base.path_join("project")
	var initial := FileAccess.get_file_as_string("res://rooms/church.txt")
	var target := proj.path_join("rooms/church.txt")
	var commit_err: String = WorkspaceFiles.commit({target: initial}, {target: null})
	_check("create a private room fixture", commit_err == "", "err=%s target=%s" % [commit_err, target])
	Dev.project_dir_override = proj
	EdAssets.ensure_folders()
	var b = Dev.open_tool("dev_room")
	_check("F2 opens the room builder", b != null and Dev.busy(), "tool=%s" % str(b))
	if b == null:
		return
	await _frames(3)
	_check("the builder keeps its seven palette tabs", b._tabs.item_count == 7, "tabs=%d" % b._tabs.item_count)
	_check("the palette panel has a Library button", b.library_button is Button and b.library_button.text == "Library", "btn=%s" % str(b.library_button))
	_check("the Library button has a help button next to it", b.library_button.get_parent().get_child_count() > 1 and b.library_button.get_parent().get_child(b.library_button.get_index() + 1) is Button and b.library_button.get_parent().get_child(b.library_button.get_index() + 1).text == "?", "")
	_check("no Library overlay is open at first", b.library_palette == null, "")
	b.open_library()
	await _frames(2)
	_check("open_library opens the search overlay", b.library_palette != null and is_instance_valid(b.library_palette) and b.library_palette.is_inside_tree() and b.library_palette.result_count() == 8, "pal=%s" % str(b.library_palette))
	var first = b.library_palette
	b.open_library()
	await _frames(1)
	_check("opening it twice keeps the same overlay", b.library_palette != null and b.library_palette == first, "")
	var edir_before := _count_files(edir)
	var props_entry := EdCatalog.entry("env_lamp_aaaaaa")
	var ok1: bool = b.use_library_entry(props_entry)
	_check("using a props picture succeeds", ok1, "")
	_check("it switches to the PNG Props tab", b.tab == "PROPS", "tab=%s" % b.tab)
	_check("it selects the copied picture and arms placing", String(b.sel.get("png", "")) == "props/lamp.png" and b.tool == "PLACE", "sel=%s tool=%s" % [str(b.sel), str(b.tool)])
	_check("the picture was copied into the builder's folder", FileAccess.file_exists(edir.path_join("props/lamp.png")), "")
	_check("it is selected in the palette list", b._list.get_selected_items().size() == 1, "selected=%d" % b._list.get_selected_items().size())
	var ok2: bool = b.use_library_entry(EdCatalog.entry("env_brick_bbbbbb"))
	_check("using a tiles picture switches to the PNG Tiles tab", ok2 and b.tab == "TILES" and String(b.sel.get("png", "")) == "tiles/brick_tile.png", "tab=%s sel=%s" % [b.tab, str(b.sel)])
	_check("a tiles picture is placed solid", b.plane == "solid", "plane=%s" % str(b.plane))
	var ok3: bool = b.use_library_entry(EdCatalog.entry("env_sky_cccccc"))
	_check("using a backdrop switches to the Backdrop tab", ok3 and b.tab == "BACKDROPS" and String(b.sel.get("png", "")) == "backdrops/sky.png", "tab=%s sel=%s" % [b.tab, str(b.sel)])
	var tab_before: String = b.tab
	var files_before := _count_files(edir)
	var ok4: bool = b.use_library_entry(EdCatalog.entry("chr_pandora_dddddd"))
	_check("a character picture is refused, the tab stays, nothing is copied", not ok4 and b.tab == tab_before and _count_files(edir) == files_before, "ok=%s tab=%s" % [str(ok4), b.tab])
	_check("the first copy happened only when a picture was used", edir_before <= files_before, "")
	b.close_library()
	_check("close_library drops the reference at once (null, not a stale object)", typeof(b.library_palette) == TYPE_NIL, "type=%d" % typeof(b.library_palette))
	await _frames(2)
	_check("close_library closes the overlay", b.library_palette == null, "")
	b.open_library()
	await _frames(2)
	var pal = b.library_palette
	pal.pick(_index_of(pal, "lamp.png"))
	used.clear()
	pal.use_selected()
	await _frames(2)
	_check("using a picture from the overlay selects it and closes the overlay", typeof(b.library_palette) == TYPE_NIL and b.tab == "PROPS" and String(b.sel.get("png", "")) == "props/lamp.png", "pal=%s tab=%s" % [str(b.library_palette), b.tab])
	Dev.request_close()
	await _frames(3)


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", nm, " | ", detail)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
