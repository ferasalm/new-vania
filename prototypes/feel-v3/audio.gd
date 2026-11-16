# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "Sfx". Reads assets/audio/events.json (event name -> file) and plays it.
extends Node

const BASE := "res://assets/audio/"

var sfx := {}      # name -> {stream, volume_db, pitch_random}
var music := {}    # name -> {stream, volume_db}
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
	for name in parsed.get("sfx", {}):
		var e: Dictionary = parsed["sfx"][name]
		var st := _load(String(e["file"]))
		if st == null:
			missing.append(name)
			continue
		sfx[name] = {"stream": st, "volume_db": float(e.get("volume_db", -8.0)),
			"pitch_random": float(e.get("pitch_random", 0.0))}
	for name in parsed.get("music", {}):
		var e: Dictionary = parsed["music"][name]
		var st := _load(String(e["file"]))
		if st == null:
			missing.append(name)
			continue
		if st is AudioStreamOggVorbis:
			st.loop = true
		music[name] = {"stream": st, "volume_db": float(e.get("volume_db", -12.0))}


func _load(rel: String) -> AudioStream:
	var path := ProjectSettings.globalize_path(BASE + rel)
	if not FileAccess.file_exists(path):
		return null
	if rel.to_lower().ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	if rel.to_lower().ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	return null


func play(name: String, pitch: float = 1.0) -> void:
	if not sfx.has(name):
		return
	var e: Dictionary = sfx[name]
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = e["stream"]
	p.volume_db = e["volume_db"]
	p.pitch_scale = pitch * (1.0 + randf_range(-1.0, 1.0) * float(e["pitch_random"]))
	p.play()


func play_music(name: String) -> void:
	if name == _music_name or not music.has(name):
		return
	_music_name = name
	_music.stream = music[name]["stream"]
	_music.volume_db = music[name]["volume_db"]
	_music.play()
