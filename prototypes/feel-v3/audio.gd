# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "Sfx". Reads assets/audio/events.json and plays sounds and music.
# Each event has several options; the F1 panel switches between them by ear and
# saves the choice (the "file" field) and the volume back to events.json.
extends Node

const BASE := "res://assets/audio/"
# the same fixed part list as tuning.gd: a fixed list works in an Android export
const PARTS := ["rpg", "world", "items", "ui", "machines", "pallbearer", "unmuzzled", "arnetria", "recall", "anim", "voice"]
const LABELS := {"footstep": "Footstep", "jump": "Jump", "land": "Landing", "swing": "Attack swing",
	"swing_heavy": "Heavy swing", "hit": "Hit connects", "hurt": "She gets hit", "enemy_die": "Enemy dies",
	"backdash": "Backdash", "door": "Door", "special": "Special attack", "pickup": "Orb pickup",
	"no_energy": "No energy", "music_church": "Music: church", "music_library": "Music: library",
	"music_lab": "Music: lab", "music_save": "Music: save room", "music_boss": "Music: boss"}

var raw := {}      # events.json as loaded (plus the part files)
var ev := {}       # name -> {group, options: [{file, gain_db, stream}], index, volume_db, pitch_random}
var missing: Array = []
var _pool: Array = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""
var _music_held := false
var _part_names := {}   # event name -> the part file it came from (never saved back to events.json)
var _warned := {}       # unknown names already warned about


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BASE + "events.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		raw = parsed
	else:
		push_warning("assets/audio/events.json not found: the prototype runs silent")
	for part in PARTS:
		var path: String = BASE + "events.d/" + String(part) + ".json"
		if not FileAccess.file_exists(path):
			continue
		var extra = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(extra) != TYPE_DICTIONARY:
			push_error("sound part is broken: " + path)
			continue
		for group in ["sfx", "music"]:
			if not (extra.has(group) and extra[group] is Dictionary):
				continue
			if not raw.has(group):
				raw[group] = {}
			for name in extra[group]:
				if raw[group].has(name):
					push_error("sound event appears twice: " + String(name))
					continue
				raw[group][name] = extra[group][name]
				_part_names[name] = part
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
	# imported projects and exported builds: use the imported stream
	var path := BASE + rel
	var st: AudioStream = null
	if ResourceLoader.exists(path):
		st = load(path) as AudioStream
	# cold clone with no import step: read the raw file through FileAccess
	if st == null:
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			return null
		if rel.to_lower().ends_with(".ogg"):
			st = AudioStreamOggVorbis.load_from_buffer(bytes)
		elif rel.to_lower().ends_with(".wav"):
			st = AudioStreamWAV.load_from_buffer(bytes)
	return st


func count(group: String) -> int:
	var n := 0
	for name in ev:
		if ev[name]["group"] == group:
			n += 1
	return n


func play(name: String, pitch: float = 1.0) -> void:
	if not ev.has(name) or ev[name]["group"] != "sfx":
		if not _warned.has(name):
			_warned[name] = true
			push_warning("unknown sound: " + name)
		return
	var e: Dictionary = ev[name]
	var o: Dictionary = e["options"][e["index"]]
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = o["stream"]
	p.volume_db = float(e["volume_db"]) + float(o["gain_db"])
	p.pitch_scale = pitch * (1.0 + randf_range(-1.0, 1.0) * float(e["pitch_random"]))
	p.play()


var _files := {}          # rel path -> AudioStream (sounds played by file, not by event)
var _loop: AudioStreamPlayer


func play_file(rel: String, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	# A sound played straight from its file under assets/audio/ (e.g. "sfx/world/lever.wav").
	# Used by the new rooms, hazards, enemies and the reality shift. Missing files stay silent.
	if not _files.has(rel):
		_files[rel] = _load(rel)
	var st: AudioStream = _files[rel]
	if st == null:
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = st
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_loop(rel: String, volume_db: float = -10.0) -> void:
	# One looping ambience (the drone after the shift). "" stops it.
	if _loop == null:
		_loop = AudioStreamPlayer.new()
		add_child(_loop)
	if rel == "":
		_loop.stop()
		return
	var st := _load(rel)
	if st == null:
		return
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
	elif st is AudioStreamOggVorbis:
		st.loop = true
	_loop.stream = st
	_loop.volume_db = volume_db
	_loop.play()


func play_music(name: String, restart: bool = false) -> void:
	if not ev.has(name) or (name == _music_name and not restart):
		return
	_music_name = name
	var e: Dictionary = ev[name]
	var o: Dictionary = e["options"][e["index"]]
	_music.stream = o["stream"]
	_music.volume_db = float(e["volume_db"]) + float(o["gain_db"])
	_music.play()
	_music.stream_paused = _music_held


func stop_music() -> void:
	# after the reality shift there is no music, only the drone
	_music.stop()
	_music_name = ""


func pause_music(on: bool) -> void:
	# the pause menu and the SYSTEM OFFLINE screen hold the music; it picks up where it stopped
	_music_held = on
	_music.stream_paused = on


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


func set_pitch(name: String, amount: float) -> void:
	ev[name]["pitch_random"] = amount


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
		e["pitch_random"] = float(saved.get("pitch_random", 0.0))
		for i in e["options"].size():
			if String(e["options"][i]["file"]) == String(saved["file"]):
				e["index"] = i
	if _music_name != "":
		play_music(_music_name, true)


func save() -> bool:
	# the saved baseline is backed up first: if the file cannot be written, Reset
	# must still go back to the last saved choices, not to these unsaved ones
	var backup: Dictionary = raw.duplicate(true)
	for name in ev:
		var e: Dictionary = ev[name]
		if _part_names.has(name):
			continue      # a part event is saved back to its own file, never to events.json
		var target: Dictionary = raw[e["group"]][name]
		target["file"] = e["options"][e["index"]]["file"]
		target["volume_db"] = e["volume_db"]
		target["pitch_random"] = e["pitch_random"]
	var f := FileAccess.open(ProjectSettings.globalize_path(BASE + "events.json"), FileAccess.WRITE)
	if f == null:
		raw = backup
		return false
	f.store_string(JSON.stringify(raw, "  ", false) + "\n")
	f.close()
	return true
