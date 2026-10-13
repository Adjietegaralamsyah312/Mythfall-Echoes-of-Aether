class_name EmberfallHighlands
extends Node2D
## E2 region vulkanik: basalt/caves-sheet + lava dekoratif (BUKAN tile lava
## khusus — tak ada di paket CC0; tile hangat + tint oranye + pulse ringan).
## Pasif (spawn diurus Main via marker). Sinyal keluar valley + checkpoint
## ditangani Main.travel_to()/reach_checkpoint() (pola B4 crypt).
# ponytail: lava Polygon2D pulse via _process; upgrade path shader bila perlu.

signal request_exit_to_valley
signal checkpoint_touched(region_id: String, pos: Vector2)

const REGION_ID: String = "emberfall_highlands"
const VALLEY_ID: String = "dawnroot_valley"

var _t: float = 0.0

@onready var _lava: Polygon2D = $LavaFissure
@onready var _pool: Polygon2D = $LavaPool


func _ready() -> void:
	add_to_group("region")
	var exit: Area2D = $ExitPortal as Area2D
	if exit != null:
		exit.body_entered.connect(_on_exit_body)
	var cp: Area2D = $CheckpointZone as Area2D
	if cp != null:
		cp.body_entered.connect(_on_checkpoint_body)


func _process(delta: float) -> void:
	_t += delta
	var k: float = 0.5 + 0.12 * sin(_t * 2.0)
	if is_instance_valid(_lava):
		_lava.color = Color(0.9, 0.35 + 0.1 * k, 0.1, 0.85)
	if is_instance_valid(_pool):
		_pool.color = Color(0.95, 0.4 + 0.1 * k, 0.12, 0.9)


func _on_exit_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_exit_to_valley.emit()


func _on_checkpoint_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		checkpoint_touched.emit(REGION_ID, ($CheckpointZone as Area2D).global_position)
