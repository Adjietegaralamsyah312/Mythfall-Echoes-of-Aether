class_name PackRegistry
extends RefCounted
## D1 registry baca-manifest (TANPA unduh — itu D2/download manager).
## API untuk D2: load_all/get_pack/list_packs/is_available/is_built_in/installed_size.
# ponytail: tanpa cache ke user://; upgrade path simpan status unduhan D2 bila ada.

signal pack_list_changed

const MANIFEST_DIR: String = "res://Data/Packs"
## Kontrak pack ID beku untuk D2.
const PACK_IDS: Array[String] = ["initial", "emberfall", "luminara", "veilwood", "azure", "aether_crown"]

var _packs: Dictionary = {}


func load_all() -> int:
	_packs.clear()
	for pid: String in PACK_IDS:
		var p: PackDef = load(MANIFEST_DIR + "/" + pid + ".tres") as PackDef
		if p != null and p.pack_id == pid:
			_packs[pid] = p
		else:
			push_error("PackRegistry: manifest rusak/hilang: " + pid)
	pack_list_changed.emit()
	return _packs.size()


func get_pack(pid: String) -> PackDef:
	return _packs.get(pid) as PackDef


func list_packs() -> Array[PackDef]:
	var out: Array[PackDef] = []
	for pid: String in PACK_IDS:
		var p: PackDef = get_pack(pid)
		if p != null:
			out.append(p)
	return out


func is_available(pid: String) -> bool:
	var p: PackDef = get_pack(pid)
	return p != null and p.status != PackDef.Status.UNAVAILABLE


func is_built_in(pid: String) -> bool:
	var p: PackDef = get_pack(pid)
	return p != null and p.status == PackDef.Status.BUILT_IN


## Byte terpasang; -1 bila belum diketahui (D2: cek ruang sebelum unduh).
func installed_size(pid: String) -> int:
	var p: PackDef = get_pack(pid)
	if p == null:
		return -1
	return p.installed_bytes
