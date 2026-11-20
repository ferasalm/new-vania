# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "Db". Reads the data files under res://data/ once and keeps them.
# Every data file is read only through Db.table(name); a missing or broken
# file is an empty table and one error, never a crash.
extends Node

static var _cache := {}


static func table(table_name: String) -> Dictionary:
	# the parsed contents of res://data/<name>.json, cached after the first read
	var key := String(table_name).get_basename()
	if _cache.has(key):
		return _cache[key]
	var path := "res://data/%s.json" % key
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt) if txt != "" else null
	if parsed is Dictionary:
		_cache[key] = parsed
		return parsed
	push_error("data file missing or broken: " + path)
	_cache[key] = {}
	return _cache[key]


static func clear_cache() -> void:
	# forget every table (the tests and a reload of the data use this)
	_cache.clear()
