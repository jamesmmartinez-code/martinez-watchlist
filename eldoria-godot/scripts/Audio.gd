extends Node
## Audio.gd — global music + SFX + ambient autoload.
##
## Usage:
##   Audio.play_music("village_theme")
##   Audio.stop_music(2.0)
##   Audio.play_sfx("sword_swing")
##   Audio.play_ambient("crickets_night")
##   Audio.play_footstep("grass")

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const AMBIENT_DIR := "res://assets/audio/ambient/"
const FOOTSTEP_DIR := "res://assets/audio/footsteps/"

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const AMBIENT_BUS := &"Ambient"

const MUSIC_VOLUME_DB := -6.0
const SFX_VOLUME_DB := -3.0
const AMBIENT_VOLUME_DB := -10.0
const DEFAULT_MUSIC_FADE := 1.5

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_music_name: String = ""
var _current_ambient_name: String = ""
var _stream_cache: Dictionary = {}

func _ready() -> void:
	_music_a = _make_player(MUSIC_BUS, MUSIC_VOLUME_DB)
	_music_b = _make_player(MUSIC_BUS, MUSIC_VOLUME_DB)
	_music_a.name = "MusicA"
	_music_b.name = "MusicB"
	add_child(_music_a)
	add_child(_music_b)
	_music_active = _music_a
	_ambient = _make_player(AMBIENT_BUS, AMBIENT_VOLUME_DB)
	_ambient.name = "Ambient"
	add_child(_ambient)
	for i in 8:
		var p := _make_player(SFX_BUS, SFX_VOLUME_DB)
		p.name = "SFX_%d" % i
		add_child(p)
		_sfx_pool.append(p)

func play_music(track: String, fade_seconds: float = DEFAULT_MUSIC_FADE) -> void:
	if track == _current_music_name and _music_active.playing:
		return
	var stream := _load_stream(MUSIC_DIR + track + ".ogg")
	if stream == null:
		push_warning("[Audio] Missing music track: %s" % track)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_current_music_name = track
	var next := _music_b if _music_active == _music_a else _music_a
	next.stream = stream
	next.volume_db = -80.0
	next.play()
	_fade_player(next, MUSIC_VOLUME_DB, fade_seconds)
	if _music_active.playing:
		_fade_player(_music_active, -80.0, fade_seconds, true)
	_music_active = next

func stop_music(fade_seconds: float = DEFAULT_MUSIC_FADE) -> void:
	_current_music_name = ""
	if _music_active.playing:
		_fade_player(_music_active, -80.0, fade_seconds, true)

func play_ambient(track: String, fade_seconds: float = 1.0) -> void:
	if track == _current_ambient_name and _ambient.playing:
		return
	var stream := _load_stream(AMBIENT_DIR + track + ".ogg")
	if stream == null:
		push_warning("[Audio] Missing ambient track: %s" % track)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_current_ambient_name = track
	_ambient.stream = stream
	_ambient.volume_db = -80.0
	_ambient.play()
	_fade_player(_ambient, AMBIENT_VOLUME_DB, fade_seconds)

func stop_ambient(fade_seconds: float = 1.0) -> void:
	_current_ambient_name = ""
	if _ambient.playing:
		_fade_player(_ambient, -80.0, fade_seconds, true)

func play_sfx(sfx_name: String, pitch_variation: float = 0.05) -> void:
	var stream := _pick_variant(SFX_DIR, sfx_name)
	if stream == null:
		push_warning("[Audio] Missing SFX: %s" % sfx_name)
		return
	var player := _next_sfx_voice()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = SFX_VOLUME_DB
	player.play()

func play_footstep(surface: String) -> void:
	var stream := _pick_variant(FOOTSTEP_DIR, surface)
	if stream == null:
		stream = _pick_variant(FOOTSTEP_DIR, "grass")
	if stream == null:
		return
	var player := _next_sfx_voice()
	player.stream = stream
	player.pitch_scale = randf_range(0.92, 1.08)
	player.volume_db = SFX_VOLUME_DB - 4.0
	player.play()

func _make_player(bus: StringName, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) != -1 else &"Master"
	p.volume_db = volume_db
	return p

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_stream_cache[path] = s
	return s

func _pick_variant(dir: String, base: String) -> AudioStream:
	var variants: Array[String] = [base]
	for i in range(2, 6):
		variants.append("%s_%d" % [base, i])
	variants.shuffle()
	for v in variants:
		var s := _load_stream(dir + v + ".ogg")
		if s != null:
			return s
	return null

func _next_sfx_voice() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	return _sfx_pool[0]

func _fade_player(player: AudioStreamPlayer, target_db: float, seconds: float, stop_at_end: bool = false) -> void:
	var tw := create_tween()
	tw.tween_property(player, "volume_db", target_db, max(seconds, 0.01))
	if stop_at_end:
		tw.tween_callback(player.stop)
