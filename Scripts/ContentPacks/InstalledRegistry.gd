class_name InstalledRegistry
extends RefCounted
## D2 catatan paket terpasang: pack_id -> {version, bytes, installed_at}.
## File sendiri user://content_packs/installed.json (TIDAK menumpang
## mythfall_save.cfg; SaveManager hanya untuk save gameplay B5).
## Corrupt -> reset aman {} + last_error jujur (jangan crash).
# ponytail: JSON flat; upgrade path satukan ke SaveManager bila perlu.

signal changed

const DEFAULT_PATH: String = "user://content_packs/installed.json"

var path: String = DEFAULT_PATH
var last_error: String = ""
var _items: Dictionary = {}


func load() -> bool:
	_items.clear()
	last_error = ""
	if not FileAccess.file_exists(path):
		return true
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		last_error = "Tak bisa membaca registry terpasang."
		return false
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_items.clear()
		last_error = "Registry terpasang rusak — direset aman."
		_save()
		return false
	for k: String in (parsed as Dictionary).keys():
		var e: Variant = (parsed as Dictionary)[k]
		if e is Dictionary and (e as Dictionary).has("version"):
			_items[k] = dict(e as Dictionary)
		else:
			_items.clear()
			last_error = "Registry terpasang rusak — direset aman."
			_save()
			return false
	return true


func list_installed() -> Array[String]:
	var out: Array[String] = []
	for k: String in _items.keys():
		out.append(k)
	out.sort()
	return out


func is_installed(pid: String) -> bool:
	return _items.has(pid)


func get_entry(pid: String) -> Dictionary:
	var e: Variant = _items.get(pid, {})
	return dict(e as Dictionary) if e is Dictionary else {}


func mark_installed(pid: String, version: String, bytes: int) -> int:
	if pid.is_empty():
		last_error = "pack_id kosong."
		return ERR_INVALID_PARAMETER
	_items[pid] = {
		"version": version,
		"bytes": bytes,
		"installed_at": Time.get_unix_time_from_system(),
	}
	var err: int = _save()
	if err == OK:
		changed.emit()
	else:
		last_error = "Gagal menyimpan registry terpasang."
	return err


func remove(pid: String) -> int:
	_items.erase(pid)
	var err: int = _save()
	if err == OK:
		changed.emit()
	else:
		last_error = "Gagal menyimpan registry terpasang."
	return err


static func dict(d: Dictionary) -> Dictionary:
	return d.duplicate()


func _save() -> int:
	var dir: String = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		var mk: int = DirAccess.make_dir_recursive_absolute(dir)
		if mk != OK:
			return mk
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	f.store_string(JSON.stringify(_items))
	f.close()
	return OK
