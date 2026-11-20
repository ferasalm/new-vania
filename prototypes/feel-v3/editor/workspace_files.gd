extends RefCounted


## Read a workspace override if it exists, otherwise read the bundled version.
static func read(path: String, fallback := "") -> String:
	var source := path if FileAccess.file_exists(path) else fallback
	return FileAccess.get_file_as_string(source) if source != "" else ""


## Stage every file before replacing any. An empty result indicates success.
## An expected value of null means the target did not exist when the draft opened.
static func commit(writes: Dictionary, expected := {}) -> String:
	var transaction := ".builder-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var staged: Array[Dictionary] = []
	for target in writes:
		var path := ProjectSettings.globalize_path(String(target)).simplify_path()
		var folder := path.get_base_dir()
		if DirAccess.dir_exists_absolute(path):
			_cleanup(staged)
			return "A folder occupies the save destination: %s" % path
		if not DirAccess.dir_exists_absolute(folder):
			if DirAccess.make_dir_recursive_absolute(folder) != OK:
				_cleanup(staged)
				return "Could not create the save folder: %s" % folder
		if expected.has(target) and not _matches(path, expected[target]):
			_cleanup(staged)
			return "Changed on disk since opening: %s. Your draft is still open." % path
		var entry := {"path": path, "temp": path + transaction + ".tmp",
			"backup": path + transaction + ".bak", "existed": FileAccess.file_exists(path)}
		if expected.has(target):
			entry["expected"] = expected[target]
		staged.append(entry)
		if not _write(String(entry["temp"]), String(writes[target])):
			_cleanup(staged)
			return "Could not write a temporary file for %s" % path
		if entry["existed"] and DirAccess.copy_absolute(path, entry["backup"]) != OK:
			_cleanup(staged)
			return "Could not back up %s" % path

	var published: Array[Dictionary] = []
	for entry in staged:
		var path: String = entry["path"]
		if not _original_matches(entry):
			return _fail(staged, published, "Changed during save: %s" % path)
		if DirAccess.rename_absolute(entry["temp"], path) != OK:
			return _fail(staged, published, "Could not replace %s" % path)
		published.append(entry)
	_cleanup(staged)
	return ""


static func _write(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok


static func _matches(path: String, version: Variant) -> bool:
	if version == null:
		return not FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and file.get_as_text() == version


static func _original_matches(entry: Dictionary) -> bool:
	var path: String = entry["path"]
	if entry.has("expected") and not _matches(path, entry["expected"]):
		return false
	if not entry["existed"]:
		return not FileAccess.file_exists(path)
	var original_hash := FileAccess.get_sha256(entry["backup"])
	return original_hash != "" and FileAccess.get_sha256(path) == original_hash


static func _fail(staged: Array[Dictionary], published: Array[Dictionary], reason: String) -> String:
	var recovery_paths := PackedStringArray()
	published.reverse()
	for entry in published:
		var path: String = entry["path"]
		if entry["existed"]:
			if DirAccess.rename_absolute(entry["backup"], path) != OK:
				recovery_paths.append(entry["backup"])
		elif DirAccess.remove_absolute(path) != OK:
			recovery_paths.append(path)
	_cleanup(staged, recovery_paths)
	if not recovery_paths.is_empty():
		return "%s. Automatic rollback needs attention at %s" % [reason, ", ".join(recovery_paths)]
	return reason


static func _cleanup(staged: Array[Dictionary], preserve := PackedStringArray()) -> void:
	for entry in staged:
		for key in ["temp", "backup"]:
			var path: String = entry[key]
			if not preserve.has(path) and FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
