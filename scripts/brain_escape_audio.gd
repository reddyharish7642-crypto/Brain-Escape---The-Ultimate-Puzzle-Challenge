extends Node

const BrowserBgmPlayer = preload("res://scripts/manus/browser_bgm_player.gd")
const MUSIC_SOURCE: AudioStreamMP3 = preload("res://assets/audio/brain_escape_theme.mp3")
const SUCCESS_SOURCE: AudioStreamMP3 = preload("res://assets/audio/puzzle_success.mp3")
const RETRY_SOURCE: AudioStreamMP3 = preload("res://assets/audio/puzzle_retry.mp3")
const MUSIC_BASE_DB := 9.5424
const SFX_BASE_DB := 6.0206

var music_enabled := true
var sfx_enabled := true
var music_level := 0.72
var sfx_level := 0.82
var _music: Node
var _success: AudioStreamPlayer
var _retry: AudioStreamPlayer
var _loop_stream: AudioStreamMP3
var _gesture_seen := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = BrowserBgmPlayer.new()
	_music.name = "BrainEscapeBackgroundMusic"
	_music.bus = &"Music"
	_music.volume_db = _music_db()
	_loop_stream = MUSIC_SOURCE.duplicate() as AudioStreamMP3
	_loop_stream.loop = true
	_music.stream = _loop_stream
	_music.buffer_key = "brain_escape_theme_v1"
	add_child(_music)
	_success = _make_sfx("PuzzleSuccess", SUCCESS_SOURCE)
	_retry = _make_sfx("PuzzleRetry", RETRY_SOURCE)
	_apply_levels()
	# Decode early for Web Audio; actual playback waits for a player gesture.
	_music.prepare()

func _make_sfx(player_name: String, source: AudioStreamMP3) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"SFX"
	player.stream = source
	player.volume_db = _sfx_db()
	player.max_polyphony = 2
	add_child(player)
	return player

func _music_db() -> float:
	return minf(0.0, linear_to_db(maxf(music_level, 0.0001)) - MUSIC_BASE_DB)

func _sfx_db() -> float:
	return minf(0.0, linear_to_db(maxf(sfx_level, 0.0001)) - SFX_BASE_DB)

func _apply_levels() -> void:
	if is_instance_valid(_music):
		_music.volume_db = _music_db()
	if is_instance_valid(_success):
		_success.volume_db = _sfx_db()
	if is_instance_valid(_retry):
		_retry.volume_db = _sfx_db()

func start_music_from_gesture() -> void:
	_gesture_seen = true
	if music_enabled and is_instance_valid(_music) and not _music.playing:
		_music.play()

func pause_music(paused: bool) -> void:
	if is_instance_valid(_music):
		_music.stream_paused = paused

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled and is_instance_valid(_music):
		_music.stop()
	elif enabled and _gesture_seen:
		start_music_from_gesture()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if not enabled:
		if is_instance_valid(_success): _success.stop()
		if is_instance_valid(_retry): _retry.stop()

func set_music_level(level: float) -> void:
	music_level = clampf(level, 0.0, 1.0)
	_apply_levels()

func set_sfx_level(level: float) -> void:
	sfx_level = clampf(level, 0.0, 1.0)
	_apply_levels()

func play_success() -> void:
	if sfx_enabled and is_instance_valid(_success):
		_success.play()

func play_retry() -> void:
	if sfx_enabled and is_instance_valid(_retry):
		_retry.play()

func _exit_tree() -> void:
	if is_instance_valid(_music):
		_music.stop()
		_music.stream = null
	if is_instance_valid(_success):
		_success.stop()
		_success.stream = null
	if is_instance_valid(_retry):
		_retry.stop()
		_retry.stream = null
	if _loop_stream != null:
		BrowserBgmPlayer.release_cached_stream(_loop_stream, "brain_escape_theme_v1")
	_loop_stream = null
