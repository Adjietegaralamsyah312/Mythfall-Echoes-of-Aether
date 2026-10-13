class_name RegionManager
extends Node
## B4 loader region sederhana: register via .tres, load/unload satu region
## aktif, transisi diminta via travel_to() Main dari Area2D.
## Sinyal B5: region_changed, region_discovered, checkpoint_reached.
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
	return n


## Dipanggil saat player sentuh checkpoint (B5: hook autosave di Main).
func reach_checkpoint(region_id: String, pos: Vector2) -> void:
	checkpoint_region = region_id
	checkpoint_pos = pos
	checkpoint_reached.emit(region_id, pos)
