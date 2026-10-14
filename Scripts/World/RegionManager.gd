class_name RegionManager
extends Node
## B4 loader region sederhana: register via .tres, load/unload satu region
## aktif, transisi diminta via travel_to() Main dari Area2D.
## Sinyal B5: region_changed, region_discovered, checkpoint_reached.
## F-D: ambience per region + quality-aware ambience VFX.
# ponytail: tanpa streaming/chunk; upgrade path preload + background
# load bila region >aban atau butuh transisi mulus.

signal region_changed(region_id: String)
signal region_discovered(region_id: String)
signal checkpoint_reached(region_id: String, pos: Vector2)

var _defs: Dictionary = {} # region_id -> RegionDef
var current_region_id: String = ""
var current_node: Node2D = null
var discovered: Array[String] = []
var checkpoint_region: String = ""
var checkpoint_pos: Vector2 = Vector2.ZERO

## F-D: peta ambience VFX per region (data saja; audio diurus Main via
## AudioManager, VFX via grup "vfx" milik Main — bukan sistem kedua).
## ponytail: 1 sumber data; upgrade path padam otomatis saat region unload.
var _ambient_map: Dictionary = {
	"dawnroot_valley": "leaves",
	"dawnroot_crypt": "dust",
	"emberfall_highlands": "embers",
	"luminara_desert": "dust",
}


func setup(defs: Array[RegionDef]) -> void:
	_defs.clear()
	for d: RegionDef in defs:
		register_region(d)


func register_region(d: RegionDef) -> void:
	if d == null or d.region_id.is_empty():
		return
	_defs[d.region_id] = d


func get_def(region_id: String) -> RegionDef:
	return _defs.get(region_id) as RegionDef


func is_discovered(region_id: String) -> bool:
	return discovered.has(region_id)


## Muat scene region ke dalam root; region lama di-free. Kembalikan node baru.
func load_region(region_id: String, root: Node) -> Node2D:
	var d: RegionDef = get_def(region_id)
	if d == null:
		push_error("RegionManager: region tak dikenal: " + region_id)
		return null
	if d.scene_path.is_empty() or not ResourceLoader.exists(d.scene_path):
		push_error("RegionManager: scene hilang: " + d.scene_path)
		return null
	if is_instance_valid(current_node):
		current_node.queue_free()
		current_node = null
	var ps: PackedScene = load(d.scene_path) as PackedScene
	if ps == null:
		push_error("RegionManager: gagal load: " + d.scene_path)
		return null
	var n: Node2D = ps.instantiate() as Node2D
	root.add_child(n)
	current_node = n
	current_region_id = region_id
	if not discovered.has(region_id):
		discovered.append(region_id)
		region_discovered.emit(region_id)
	region_changed.emit(region_id)

	## F-D: teruskan ambience VFX region ke sistem VFX Main (grup "vfx").
	## Audio diurus Main._after_load_region; di sini hanya VFX + aman bila
	## VFX belum ada (tes headless tanpa Main).
	_apply_region_vfx(region_id)
	return n


## Nama ambience VFX untuk region ("" = tanpa ambience).
func ambience_vfx_for(region_id: String) -> String:
	return str(_ambient_map.get(region_id, ""))


## F-D: stop ambience lama + start ambience region via grup "vfx".
func _apply_region_vfx(region_id: String) -> void:
	if get_tree() == null:
		return
	var vfx: Node = get_tree().get_first_node_in_group("vfx")
	if vfx == null or not vfx.has_method("stop_ambience"):
		return
	vfx.call("stop_ambience")
	var vfx_name: String = ambience_vfx_for(region_id)
	if vfx_name.is_empty() or not vfx.has_method("start_ambience"):
		return
	vfx.call("start_ambience", vfx_name)


## Dipanggil saat player sentuh checkpoint (B5: hook autosave di Main).
func reach_checkpoint(region_id: String, pos: Vector2) -> void:
	checkpoint_region = region_id
	checkpoint_pos = pos
	checkpoint_reached.emit(region_id, pos)
