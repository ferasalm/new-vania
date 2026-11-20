# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "T". Every feel number lives in tuning.json and in the part files
# under tuning.d/. A key lives in exactly one file; T merges them, remembers
# which file each key came from, and saves every key back to its own file.
# The F1 panel changes values live.
extends Node

const PATH := "res://tuning.json"
# the fixed part list (a fixed list works in an Android export, where listing a folder does not)
const PARTS := ["rpg", "world", "items", "ui", "machines", "pallbearer", "unmuzzled", "arnetria", "recall", "anim", "voice"]

var data := {}       # key -> {value, min, max, step, label, help}
var defaults := {}   # key -> value as loaded at start
var source := {}     # key -> part that owns it ("" = tuning.json)


func _ready() -> void:
	var parsed = _json(PATH)
	if not (parsed is Dictionary):
		push_error("tuning.json is missing or broken")
		return
	for k in parsed:
		_put(String(k), parsed[k], "")
	for part in PARTS:
		var path := "res://tuning.d/%s.json" % part
		if not FileAccess.file_exists(path):
			continue
		var extra = _json(path)
		if not (extra is Dictionary):
			push_error("tuning part is broken: " + path)
			continue
		for k in extra:
			_put(String(k), extra[k], part)
	for k in data:
		defaults[k] = float(data[k]["value"])


func _json(path: String):
	var txt := FileAccess.get_file_as_string(path)
	if txt == "":
		return null
	return JSON.parse_string(txt)


func _put(key: String, entry, part: String) -> void:
	# one key, one file: a key that appears twice is an error
	if data.has(key):
		push_error("tuning key appears twice: " + key)
		return
	data[key] = entry
	source[key] = part


func v(key: String) -> float:
	if not data.has(key):
		push_error("unknown tuning key " + key)
		return 0.0
	return float(data[key]["value"])


func set_v(key: String, value: float) -> void:
	if data.has(key):
		data[key]["value"] = value


func reset() -> void:
	for k in defaults:
		data[k]["value"] = defaults[k]


func save() -> bool:
	# every key goes back to the file it came from
	var files := {"": {}}
	for part in PARTS:
		files[part] = {}
	for k in data:
		var s := String(source.get(k, ""))
		if not files.has(s):
			files[s] = {}
		files[s][k] = data[k]
	var ok := true
	for s in files:
		if files[s].is_empty():
			continue
		var path := PATH if s == "" else "res://tuning.d/%s.json" % s
		var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
		if f == null:
			ok = false
			continue
		f.store_string(JSON.stringify(files[s], "  ", false) + "\n")
		f.close()
	if ok:
		for k in data:
			defaults[k] = float(data[k]["value"])
	return ok
