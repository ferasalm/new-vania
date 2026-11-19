# PROTOTYPE - NOT FOR PRODUCTION
# Changes one room's "cell" inside data/rooms_meta.json by editing the text in place.
# The file is formatted by hand (short exits on one line), so it is never re-written whole:
# only the four numbers of the changed rooms move, and git shows exactly that.
extends RefCounted


## Returns the new file text, or "" when the sheet or room cannot be found.
## `sheet` is the top-level page the room is stored on: "before", "after" or "restored"
## (rooms added by the restored page live under its "add").
static func set_cell(text: String, sheet: String, id: String, cell: Array) -> String:
	var s := text.find("\"sheets\"")
	if s < 0:
		return ""
	var a := text.find("\"%s\": {" % sheet, s)
	if a < 0:
		return ""
	var b := text.find("\n    \"", a + 1)       # the next page starts at four spaces
	if b < 0:
		b = text.length()
	var r := text.find("\"%s\": {" % id, a)
	if r < 0 or r >= b:
		return ""
	var c := text.find("\"cell\": [", r)
	if c < 0 or c >= b:
		return ""
	var e := text.find("]", c)
	if e < 0:
		return ""
	return text.substr(0, c) + "\"cell\": [%d, %d, %d, %d]" % [int(cell[0]), int(cell[1]), int(cell[2]), int(cell[3])] + text.substr(e + 1)
