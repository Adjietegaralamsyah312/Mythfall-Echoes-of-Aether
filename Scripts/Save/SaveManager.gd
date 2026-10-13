class_name SaveManager
extends Node
## B5 save manual + autosave checkpoint ke user://mythfall_save.cfg.
## Validasi saat load + corrupt fallback aman (kembalikan {} + alasan).
## ponytail: ConfigFile flat; upgrade path JSON bila slot/Cloud dibutuhkan.

signal saved
signal save_failed(reason: String)
signal loaded(data: Dictionary)
signal load_failed(reason: String)

const PATH: String = "user://mythfall_save.cfg"
const SAVE_VERSION: int = 1

var last_error: String = ""


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func clear() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


## data: {player_pos, level, xp, hp, inventory{item_id:qty}, quest, region...,
## settings}. Kembalikan OK atau error; gagal jujur via save_failed.
func save_game(data: Dictionary) -> int:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("meta", "saved_at", Time.get_unix_time_from_system())
	for section: String in ["player", "quest", "region", "settings"]:
		var sub: Dictionary = data.get(section, {}) as Dictionary
		for k: String in sub.keys():
			cfg.set_value(section, k, sub[k])
	var err: int = cfg.save(PATH)
	if err != OK:
		last_error = "Gagal menyimpan (err %d)." % err
		save_failed.emit(last_error)
		return err
	saved.emit()
	return OK


## Kembalikan {} bila tak ada/rusak; alasan via load_failed (jujur).
func load_game() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var cfg := ConfigFile.new()
	var err: int = cfg.load(PATH)
	if err != OK:
		last_error = "File save rusak (err %d). Mulai baru aman." % err
		load_failed.emit(last_error)
		return {}
	var data: Dictionary = {
		"player": _section(cfg, "player"),
		"quest": _section(cfg, "quest"),
		"region": _section(cfg, "region"),
		"settings": _section(cfg, "settings"),
		"meta": _section(cfg, "meta"),
	}
	if not validate(data):
		last_error = "Data save tidak valid. Mulai baru aman."
		load_failed.emit(last_error)
		return {}
	loaded.emit(data)
	return data


## Validasi ringan: versi cocok + field kunci bertipe benar.
func validate(data: Dictionary) -> bool:
	var meta: Dictionary = data.get("meta", {}) as Dictionary
	if int(meta.get("version", 0)) != SAVE_VERSION:
		return false
	var p: Dictionary = data.get("player", {}) as Dictionary
	if p.is_empty():
		return false
	if not (p.get("pos") is Vector2 or p.get("pos") is Array):
		return false
	if int(p.get("level", 0)) < 1:
		return false
	if int(p.get("xp", -1)) < 0:
		return false
	var q: Dictionary = data.get("quest", {}) as Dictionary
	if q.has("status") and not (q["status"] is Dictionary):
		return false
	if q.has("progress") and not (q["progress"] is Dictionary):
		return false
	return true


func _section(cfg: ConfigFile, name: String) -> Dictionary:
	var out: Dictionary = {}
	if not cfg.has_section(name):
		return out
	for k: String in cfg.get_section_keys(name):
		out[k] = cfg.get_value(name, k)
	return out


## Baca/tulis section settings saja (dipakai MainMenu sebelum save ada).
func load_settings() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return {}
	return _section(cfg, "settings")


func store_settings(s: Dictionary) -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(PATH):
		cfg.load(PATH)
	if not cfg.has_section("meta"):
		cfg.set_value("meta", "version", SAVE_VERSION)
		cfg.set_value("meta", "saved_at", Time.get_unix_time_from_system())
	for k: String in s.keys():
		cfg.set_value("settings", k, s[k])
	if cfg.save(PATH) != OK:
		last_error = "Gagal menyimpan pengaturan."
		save_failed.emit(last_error)
