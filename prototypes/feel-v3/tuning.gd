# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "T". Every feel number lives in tuning.json; nothing is hardcoded.
# The F1 panel changes values live and saves them back to the file.
extends Node

const PATH := "res://tuning.json"

var data := {}       # key -> {value, min, max, step, label, help}
var defaults := {}   # key -> value as loaded at start


func _ready() -> void:
	var txt := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("tuning.json is missing or broken")
		return
	data = parsed
	for k in data:
		defaults[k] = float(data[k]["value"])


func v(key: String) -> float:
	if not data.has(key):
		push_error("unknown tuning key " + key)
		return 0.0
	return float(data[key]["value"])


func set_v(key: String, value: float) -> void:
	data[key]["value"] = value


func reset() -> void:
	for k in defaults:
		data[k]["value"] = defaults[k]


func save() -> bool:
	var f := FileAccess.open(ProjectSettings.globalize_path(PATH), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  ", false) + "\n")
	f.close()
	for k in data:
		defaults[k] = float(data[k]["value"])
	return true
