class_name AudioManager
extends Node
## B5 bus Master/Music/SFX + SFX dari file .ogg NYATA Kenney RPG Audio.
## Musik: Preview.ogg BUKAN ambient loop (demo mashup) -> TANPA musik +
## catat kebutuhan (lihat AUDIO_MAP). Semua play aman bila file hilang.
## ponytail: pool 8 AudioStreamPlayer; upgrade path AudioStreamPlaylist
## bila butuh musik adaptif.
## Mapping jujur (file nyata di Assets/Audio/RPG/Audio/):
## swing=drawKnife1, hit=knifeSlice, hurt=cloth1(fallback),
## die=chop(fallback impact), pickup=handleCoins, quest=bookOpen(fallback),
## door=doorOpen_1/doorClose_1, ui=metalClick, chest=dropLeather.

signal volumes_applied(master: float, music: float, sfx: float)

const SFX_BASE: String = "res://Assets/Audio/RPG/Audio/"
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
# NOTE: musik ambient nyata BELUM tersedia; Preview.ogg hanya demo.
# Kebutuhan: loop ambient desa/hutan/dungeon (CC0) -> Docs.

var master_vol: float = 1.0
var music_vol: float = 0.8
var sfx_vol: float = 1.0

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _idx: int = 0


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for k: String in AUDIO_MAP.keys():
		var p: String = SFX_BASE + str(AUDIO_MAP[k])
		if ResourceLoader.exists(p):
			_streams[k] = load(p) as AudioStream
	for i: int in 8:
		var pl := AudioStreamPlayer.new()
		pl.bus = "SFX"
		add_child(pl)
		_pool.append(pl)
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
