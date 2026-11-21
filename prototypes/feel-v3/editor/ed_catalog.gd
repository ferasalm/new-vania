# PROTOTYPE - NOT FOR PRODUCTION
# editor/ed_catalog.gd - read-only view of studio/catalog.json for the room builder library.
# Every entry is kept twice: once as the dictionary read from the file, and once as a
# lower-case haystack (name, category, sub, tags) so searching 24,000 entries stays fast.
extends RefCounted

## The placeable kinds a room can actually use.
const PLACEABLE := ["tiles", "props", "backdrops"]

## Entry dictionaries keyed by id.
static var _table: Dictionary = {}
## Lower-case search haystacks keyed by id.
static var _hay: Dictionary = {}
static var _whitespace := RegEx.create_from_string("(*UCP)\\s+")


## Replace the table with the valid entries of a catalog.json; return how many were kept.
## A missing, unreadable or invalid file returns 0 and leaves the table unchanged.
static func load_file(path: String) -> int:
	if path.is_empty() or not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var raw := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return 0
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return 0
	var listed: Variant = (parsed as Dictionary).get("entries", null)
	if not (listed is Array):
		return 0
	var table: Dictionary = {}
	var hay: Dictionary = {}
	for item: Variant in (listed as Array):
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item
		var id_value: Variant = entry.get("id", null)
		var name_value: Variant = entry.get("name", null)
		if not (id_value is String) or not (name_value is String):
			continue
		var id := String(id_value)
		table[id] = entry
		hay[id] = _haystack(entry)
	_table = table
	_hay = hay
	return table.size()


## Forget every entry.
static func clear() -> void:
	_table.clear()
	_hay.clear()


## How many entries the table holds.
static func entry_count() -> int:
	return _table.size()


## The entry for an id, or an empty dictionary when the id is unknown.
static func entry(id: String) -> Dictionary:
	if not _table.has(id):
		return {}
	return _table[id]


## Category ids computed from the entries (never from the file), sorted by id, with counts.
static func categories() -> Array:
	var counts: Dictionary = {}
	for id: Variant in _table:
		var category := String((_table[id] as Dictionary).get("category", ""))
		if category.is_empty():
			continue
		counts[category] = int(counts.get(category, 0)) + 1
	var ids: Array = counts.keys()
	ids.sort()
	var out: Array = []
	for id: Variant in ids:
		out.append({"id": String(id), "count": int(counts[id])})
	return out


## Entries matching every whitespace-separated word of text (name, category, sub, tags),
## optionally limited to one category, sorted by name then id. limit 0 means no limit.
static func search(text: String, category := "", limit := 0, facets: Dictionary = {}) -> Array:
	var words := _whitespace.sub(text.to_lower(), " ", true).split(" ", false)
	var out: Array = []
	for id: Variant in _table:
		var entry: Dictionary = _table[id]
		if not category.is_empty() and String(entry.get("category", "")) != category:
			continue
		if _matches_facets(entry, facets) and _contains_words(String(_hay.get(id, "")), words):
			out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var an := String(a.get("name", "")).to_lower()
		var bn := String(b.get("name", "")).to_lower()
		if an == bn:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return an < bn)
	if limit > 0 and out.size() > limit:
		out.resize(limit)
	return out


## Search a short ordered list of known IDs without sorting or scanning the entire catalog.
static func search_ids(text: String, ids: Array[String], facets: Dictionary = {}) -> Array:
	var words := _whitespace.sub(text.to_lower(), " ", true).split(" ", false)
	var found: Array = []
	for id in ids:
		if _table.has(id) and _matches_facets(_table[id], facets) and _contains_words(String(_hay[id]), words):
			found.append(_table[id])
	return found


## Distinct labels for a filter, sorted for its menu.
static func facet_values(key: String) -> Array:
	var values := {}
	for item: Dictionary in _table.values():
		values[_facet_value(item, key)] = true
	var labels := values.keys()
	labels.sort()
	return labels


static func _facet_value(item: Dictionary, key: String) -> String:
	var fallback := String(item.get("kind", "Unassigned")) if key == "type" else "Unassigned"
	return String(item.get(key, fallback))


static func _matches_facets(item: Dictionary, facets: Dictionary) -> bool:
	for key: String in facets:
		if facets[key] != "" and facets[key] != _facet_value(item, key):
			return false
	return true


static func _contains_words(hay: String, words: PackedStringArray) -> bool:
	for word in words:
		if not hay.contains(word):
			return false
	return true


## An empty string when the entry can be placed in a room, otherwise one plain sentence why not.
static func placeable_reason(entry: Dictionary) -> String:
	var placeable: Variant = entry.get("placeable", null)
	if placeable is String and (placeable as String) in PLACEABLE:
		if String(entry.get("path", "")).get_extension().to_lower() == "png":
			return ""
		return "Only PNG pictures can be placed in a room."
	match String(entry.get("type", "")):
		"original", "cleaned":
			return "Use a sprite made from this artwork to place it in a room."
		"document", "data", "import settings", "other file":
			return "Use Show file to inspect this asset."
	match String(entry.get("kind", "")):
		"audio":
			return "Sounds cannot be placed in a room."
		"3d":
			return "3D models are listed here but cannot be placed in a 2D room."
		"inbox":
			return "Inbox files are raw downloads; move one into the project first."
		"source":
			return "Source files are not pictures; use the exported PNG."
	return "This picture is not set up as a tile, prop or backdrop."


## One lower-case string holding every word a search may match for an entry.
static func _haystack(entry: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append(String(entry.get("name", "")))
	parts.append(String(entry.get("category", "")))
	for key: String in ["sub", "source", "derived_from", "room", "area", "type"]:
		parts.append(String(entry.get(key, "")))
	var tags: Variant = entry.get("tags", [])
	if tags is Array:
		for tag: Variant in (tags as Array):
			parts.append(String(tag))
	return " ".join(parts).to_lower()
