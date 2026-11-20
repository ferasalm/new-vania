extends RefCounted

# Token offsets let us patch a specific JSON member without changing the hand-formatted
# exits, indentation, or line endings elsewhere in the map file.
const JSON_TOKEN := "\"(?:\\\\.|[^\"\\\\])*\"|[{}\\[\\]:,]|[^\\s\"{}\\[\\]:,]+"


## Return the new map text, or "" if the requested cell cannot be located.
static func set_cell(text: String, sheet: String, id: String, cell: Array) -> String:
	return set_cells(text, [[sheet, id, cell]])


## Patch a list of [sheet, room ID, cell] entries in a single pass.
static func set_cells(text: String, changes: Array) -> String:
	var tokens := RegEx.create_from_string(JSON_TOKEN).search_all(text)
	var sheets := _member(tokens, 0, "sheets")
	if sheets < 0:
		return ""
	var replacements: Array = []
	for change in changes:
		var era := String(change[0])
		var page := _member(tokens, sheets, era)
		if era == "restored":
			page = _member(tokens, page, "add")
		var room := _member(tokens, page, String(change[1]))
		var start := _member(tokens, room, "cell")
		if start < 0 or tokens[start].get_string() != "[":
			return ""
		var end := _value_end(tokens, start)
		var cell: Array = change[2]
		if end < 0 or cell.size() != 4:
			return ""
		var replacement := "[%d, %d, %d, %d]" % [int(cell[0]), int(cell[1]), int(cell[2]), int(cell[3])]
		replacements.append([tokens[start].get_start(), tokens[end].get_end(), replacement])
	replacements.sort_custom(func(a, b): return a[0] > b[0])
	var out := text
	var boundary := text.length()
	for replacement in replacements:
		if replacement[1] > boundary:
			return ""
		out = out.substr(0, replacement[0]) + replacement[2] + out.substr(replacement[1])
		boundary = replacement[0]
	return out


## Find a direct member of the object at the given token index.
static func _member(tokens: Array[RegExMatch], object: int, key: String) -> int:
	if object < 0 or object >= tokens.size() or tokens[object].get_string() != "{":
		return -1
	var i := object + 1
	while i + 2 < tokens.size() and tokens[i + 1].get_string() == ":":
		var member := tokens[i].get_string()
		if member.begins_with("\"") and JSON.parse_string(member) == key:
			return i + 2
		var end := _value_end(tokens, i + 2)
		if end < 0 or end + 1 >= tokens.size() or tokens[end + 1].get_string() != ",":
			break
		i = end + 2
	return -1


static func _value_end(tokens: Array[RegExMatch], start: int) -> int:
	var first := tokens[start].get_string()
	if first != "[" and first != "{":
		return start
	var depth := 0
	for i in range(start, tokens.size()):
		match tokens[i].get_string():
			"[", "{": depth += 1
			"]", "}":
				depth -= 1
				if depth == 0:
					return i
	return -1
