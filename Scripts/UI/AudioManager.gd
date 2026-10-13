class_name AudioManager
extends Node
## B5 bus Master/Music/SFX + SFX dari file .ogg NYATA Kenney RPG Audio.
## Musik: 16 trek CC0 di MusicLibrary (katalog MusicCatalog, play via
## play_music anti-overlap). Preview.ogg demo TAK dipakai.
## ponytail: pool 8 AudioStreamPlayer; upgrade path AudioStreamPlaylist
## bila butuh musik adaptif.
## Mapping jujur (file nyata di Assets/Audio/RPG/Audio/):
## swing=drawKnife1, hit=knifeSlice, hurt=cloth1(fallback),
## die=chop(fallback impact), pickup=handleCoins, quest=bookOpen(fallback),
## door=doorOpen_1/doorClose_1, ui=metalClick, chest=dropLeather.

signal volumes_applied(master: float, music: float, sfx: float)

const SFX_BASE: String = "res://Assets/Audio/RPG/Audio/"
const IMPACT_BASE: String = "res://Assets/Audio/Impacts/"
## F2 ambient CC0 (JaggedStone, OGA): loopable dungeon/cave ambient 94.3 dtk
## (wind + water drips) -> cocok Emberfall vulkanik + crypt. Tanpa tag LOOP
## embedded -> loop via flag AudioStreamOggVorbis di bawah.
## BULK-001: Luminara + valley + menu pakai BGM MusicCatalog (bukan ambient).
const AMBIENT_BASE: String = "res://Assets/Audio/Ambience/"
const AMBIENT_MAP: Dictionary = {
	"ambient_ember": "dungeon_ambient_1.ogg",
}
const IMPACT_MAP: Dictionary = {
	"footstep_ember": "footstep_concrete_000.ogg",
	"hit_metal": "impactMetal_heavy_000.ogg",
	"mine": "impactMining_000.ogg",
	"punch": "impactPunch_heavy_000.ogg",
}
const AUDIO_MAP: Dictionary = {
	"swing": "drawKnife1.ogg",
	"hit": "knifeSlice.ogg",
	"hurt": "cloth1.ogg",
	"die": "chop.ogg",
	"pickup": "handleCoins.ogg",
	"quest": "bookOpen.ogg",
	"door_open": "doorOpen_1.ogg",
	"door_close": "doorClose_1.ogg",
	"ui": "metalClick.ogg",
	"chest": "dropLeather.ogg",
	"levelup": "handleCoins2.ogg",
}
# NOTE: BGM nyata via MusicCatalog (16 trek CC0) + play_music; Preview.ogg demo tak dipakai.

var master_vol: float = 1.0
var music_vol: float = 0.8
var sfx_vol: float = 1.0

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _idx: int = 0
var _ambient: AudioStreamPlayer = null
## BULK-001 musik BGM (lazy-load via MusicCatalog, 1 player bus Music).
## Anti-overlap: play_music hentikan ambient; play_ambient hentikan musik.
var _music: AudioStreamPlayer = null
var _music_id: String = ""


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for k: String in AUDIO_MAP.keys():
		var p: String = SFX_BASE + str(AUDIO_MAP[k])
		if ResourceLoader.exists(p):
			_streams[k] = load(p) as AudioStream
	for k2: String in IMPACT_MAP.keys():
		var p2: String = IMPACT_BASE + str(IMPACT_MAP[k2])
		if ResourceLoader.exists(p2):
			_streams[k2] = load(p2) as AudioStream
	for ka: String in AMBIENT_MAP.keys():
		var pa: String = AMBIENT_BASE + str(AMBIENT_MAP[ka])
		if ResourceLoader.exists(pa):
			var raw: AudioStream = load(pa) as AudioStream
			if raw is AudioStreamOggVorbis:
				var looped: AudioStreamOggVorbis = (raw as AudioStreamOggVorbis).duplicate()
				looped.loop = true
				_streams[ka] = looped
			else:
				_streams[ka] = raw
	for i: int in 8:
		var pl := AudioStreamPlayer.new()
		pl.bus = "SFX"
		add_child(pl)
		_pool.append(pl)
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = "Music"
	add_child(_ambient)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	apply_volumes(master_vol, music_vol, sfx_vol)


func apply_volumes(master: float, music: float, sfx: float) -> void:
	master_vol = clampf(master, 0.0, 1.0)
	music_vol = clampf(music, 0.0, 1.0)
	sfx_vol = clampf(sfx, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, _to_db(master_vol))
	AudioServer.set_bus_volume_db(_bus_idx("Music"), _to_db(music_vol))
	AudioServer.set_bus_volume_db(_bus_idx("SFX"), _to_db(sfx_vol))
	volumes_applied.emit(master_vol, music_vol, sfx_vol)


func play(name: String) -> void:
	var s: AudioStream = _streams.get(name) as AudioStream
	if s == null or _pool.is_empty():
		return
	var pl: AudioStreamPlayer = _pool[_idx % _pool.size()]
	_idx += 1
	pl.stream = s
	pl.play()


## Ambient loop di bus Music (volume via apply_volumes). Aman bila hilang.
## Hentikan musik dulu (anti-overlap satu sumber Music).
func play_ambient(name: String) -> void:
	stop_music()
	if _ambient == null:
		return
	var s: AudioStream = _streams.get(name) as AudioStream
	if s == null:
		return
	if _ambient.stream == s and _ambient.playing:
		return
	_ambient.stream = s
	_ambient.play()


## BULK-001 BGM dari MusicCatalog (lazy-load, loop). Aman bila hilang.
## Hentikan ambient dulu (anti-overlap). Sama = no-op.
func play_music(track_id: String) -> void:
	if _music == null or track_id.is_empty():
		return
	if _music_id == track_id and _music.playing:
		return
	stop_ambient()
	var path: String = MusicCatalog.file_for(track_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var raw: AudioStream = load(path) as AudioStream
	if raw == null:
		return
	var s: AudioStream = raw.duplicate() as AudioStream
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	_music.stream = s
	_music_id = track_id
	_music.play()


func stop_music() -> void:
	_music_id = ""
	if _music != null and _music.playing:
		_music.stop()


func is_music_playing() -> bool:
	return _music != null and _music.playing


func current_music_id() -> String:
	return _music_id


func stop_ambient() -> void:
	if _ambient != null and _ambient.playing:
		_ambient.stop()


func is_ambient_playing() -> bool:
	return _ambient != null and _ambient.playing


func _to_db(v: float) -> float:
	if v <= 0.001:
		return -60.0
	return 20.0 * log(v) / log(10.0)


func _bus_idx(name: String) -> int:
	var i: int = AudioServer.bus_count - 1
	while i >= 0:
		if AudioServer.get_bus_name(i) == name:
			return i
		i -= 1
	return 0


func _ensure_bus(name: String) -> void:
	for i: int in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == name:
			return
	AudioServer.add_bus(AudioServer.bus_count)
	AudioServer.set_bus_name(AudioServer.bus_count - 1, name)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
