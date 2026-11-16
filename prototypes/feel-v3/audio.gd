# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "Sfx". Reads assets/audio/events.json and plays sounds and music.
# Each event has several options; the F1 panel switches between them by ear and
# saves the choice (the "file" field) and the volume back to events.json.
extends Node

const BASE := "res://assets/audio/"
const LABELS := {"footstep": "Footstep", "jump": "Jump", "land": "Landing", "swing": "Attack swing",
	"hit": "Hit connects", "hurt": "She gets hit", "enemy_die": "Enemy dies", "backdash": "Backdash",
	"door": "Door", "special": "Special attack", "pickup": "Orb pickup", "no_energy": "No energy",
	"music_room": "Music"}

var raw := {}      # events.json as loaded
var ev := {}       # name -> {group, options: [{file, gain_db, stream}], index, volume_db, pitch_random}
var missing: Array = []
var _pool: Array = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BASE + "events.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("assets/audio/events.json not found: the prototype runs silent")
		return
	raw = parsed
	for group in ["sfx", "music"]:
		for name in raw.get(group, {}):
			var e: Dictionary = raw[group][name]
			var opts: Array = e.get("options", [{"file": e["file"], "gain_db": 0.0}])
			var loaded: Array = []
			var index := 0
			for o in opts:
				var st := _load(String(o["file"]))
				if st == null:
					continue
				if group == "music" and st is AudioStreamOggVorbis:
					st.loop = true
				if String(o["file"]) == String(e["file"]):
					index = loaded.size()
				loaded.append({"file": String(o["file"]), "gain_db": float(o.get("gain_db", 0.0)), "stream": st})
			if loaded.is_empty():
				missing.append(name)
				continue
			ev[name] = {"group": group, "options": loaded, "index": index,
				"volume_db": float(e.get("volume_db", -8.0)), "pitch_random": float(e.get("pitch_random", 0.0))}


func _load(rel: String) -> AudioStream:
	var path := ProjectSettings.globalize_path(BASE + rel)
	if not FileAccess.file_exists(path):
		return null
	if rel.to_lower().ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	if rel.to_lower().ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	return null


func count(group: String) -> int:
	var n := 0
	for name in ev:
		if ev[name]["group"] == group:
			n += 1
	return n


func play(name: String, pitch: float = 1.0) -> void:
	if not ev.has(name) or ev[name]["group"] != "sfx":
		return
	var e: Dictionary = ev[name]
	var o: Dictionary = e["options"][e["index"]]
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = o["stream"]
	p.volume_db = float(e["volume_db"]) + float(o["gain_db"])
	p.pitch_scale = pitch * (1.0 + randf_range(-1.0, 1.0) * float(e["pitch_random"]))
	p.play()


func play_music(name: String, restart: bool = false) -> void:
	if not ev.has(name) or (name == _music_name and not restart):
		return
	_music_name = name
	var e: Dictionary = ev[name]
	var o: Dictionary = e["options"][e["index"]]
	_music.stream = o["stream"]
	_music.volume_db = float(e["volume_db"]) + float(o["gain_db"])
	_music.play()


# ---- used by the F1 panel ----

func pickable() -> Array:
	var out: Array = []
	for name in LABELS:
		if ev.has(name):
			out.append(name)
	return out


func option_text(name: String) -> String:
	var e: Dictionary = ev[name]
	var file := String(e["options"][e["index"]]["file"]).get_file().get_basename().replace("_", " ")
	return "%d/%d %s" % [int(e["index"]) + 1, e["options"].size(), file]


func cycle(name: String, step: int) -> void:
	var e: Dictionary = ev[name]
	e["index"] = posmod(int(e["index"]) + step, e["options"].size())
	preview(name)


func set_volume(name: String, db: float) -> void:
	ev[name]["volume_db"] = db
	if ev[name]["group"] == "music" and name == _music_name:
		_music.volume_db = db + float(ev[name]["options"][ev[name]["index"]]["gain_db"])


func preview(name: String) -> void:
	if ev[name]["group"] == "music":
		play_music(name, true)
	else:
		play(name)


func reset() -> void:
	# back to what is in events.json (the last saved choices)
	for name in ev:
		var e: Dictionary = ev[name]
		var saved: Dictionary = raw[e["group"]][name]
		e["volume_db"] = float(saved.get("volume_db", -8.0))
		for i in e["options"].size():
			if String(e["options"][i]["file"]) == String(saved["file"]):
				e["index"] = i
	if _music_name != "":
		play_music(_music_name, true)


func save() -> bool:
	for name in ev:
		var e: Dictionary = ev[name]
		var target: Dictionary = raw[e["group"]][name]
		target["file"] = e["options"][e["index"]]["file"]
		target["volume_db"] = e["volume_db"]
	var f := FileAccess.open(ProjectSettings.globalize_path(BASE + "events.json"), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(raw, "  ", false) + "\n")
	f.close()
	return true
