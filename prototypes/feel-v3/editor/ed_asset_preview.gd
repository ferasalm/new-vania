# Reads thumbnails and previews from the Studio library without importing them.
extends RefCounted

const Assets := preload("res://editor/ed_assets.gd")
const IMAGE_FORMATS := ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg"]
const TEXT_FORMATS := ["md", "txt", "json", "csv", "xml", "import", "rtf"]
const MAX_TEXT_BYTES := 1500
static var _badges: Dictionary = {}


## The copied file, or the existing project source for catalog-only rows.
static func file_path(entry: Dictionary) -> String:
	var root := Assets.library_root()
	var relative := String(entry.get("path", ""))
	if relative.is_empty() and not root.is_empty():
		root = root.path_join("../../../..").simplify_path()
		relative = String(entry.get("source", ""))
	return _existing_path(root, relative)


## Decode the generated preview or a natively supported image.
static func picture(entry: Dictionary) -> Image:
	var target := _existing_path(Assets.library_root(), String(entry.get("preview", "")))
	if target.is_empty() and String(entry.get("kind", "")) == "image":
		target = file_path(entry)
	if target.get_extension().to_lower() in IMAGE_FORMATS:
		return Image.load_from_file(target)
	return null


## Return a small type icon when a row has no visual preview.
static func badge(entry: Dictionary) -> Texture2D:
	var type := String(entry.get("type", ""))
	if type.is_empty():
		return null
	if _badges.has(type):
		return _badges[type]
	var pixels := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	pixels.fill(Color.TRANSPARENT)
	var tile := Color("#273446")
	var ink := Color("#9fbcce")
	match type:
		"audio":
			tile = Color("#44344d")
			ink = Color("#d5aedc")
		"source", "3d":
			tile = Color("#3b354c")
			ink = Color("#bab0ed")
		"original", "cleaned", "sprite", "image":
			tile = Color("#263f3b")
			ink = Color("#a9d4b5")
	pixels.fill_rect(Rect2i(4, 4, 40, 40), tile)
	match type:
		"audio":
			for i in 7:
				var height: int = [8, 14, 22, 26, 17, 12, 6][i]
				pixels.fill_rect(Rect2i(10 + 4 * i, 24 - height / 2, 2, height), ink)
		"source", "3d":
			for i in 3:
				pixels.fill_rect(Rect2i(11 + 4 * i, 14 + 6 * i, 18, 3), ink)
		"original", "cleaned", "sprite", "image":
			pixels.fill_rect(Rect2i(11, 13, 26, 21), ink)
			pixels.fill_rect(Rect2i(13, 15, 22, 17), tile)
			pixels.fill_rect(Rect2i(16, 24, 17, 5), ink)
			pixels.fill_rect(Rect2i(25, 18, 4, 4), ink)
		_:
			pixels.fill_rect(Rect2i(15, 11, 18, 26), ink)
			pixels.fill_rect(Rect2i(17, 13, 14, 22), tile)
			for i in 3:
				pixels.fill_rect(Rect2i(19, 17 + 6 * i, 10, 2), ink)
	var icon := ImageTexture.create_from_image(pixels)
	_badges[type] = icon
	return icon


## A brief textual preview for supported documents and metadata.
static func excerpt(path: String) -> String:
	if path.get_extension().to_lower() not in TEXT_FORMATS:
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_buffer(MAX_TEXT_BYTES).get_string_from_utf8().strip_edges()


## Open a local audio file for listening in Studio.
static func audio(path: String) -> AudioStream:
	match path.get_extension().to_lower():
		"wav":
			return AudioStreamWAV.load_from_file(path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
	return null


static func _existing_path(root: String, relative: String) -> String:
	if root.is_empty() or relative.is_empty() or relative.is_absolute_path():
		return ""
	var clean := relative.replace("\\", "/")
	if ".." in clean.split("/"):
		return ""
	var target := root.path_join(clean).simplify_path()
	return target if FileAccess.file_exists(target) else ""
