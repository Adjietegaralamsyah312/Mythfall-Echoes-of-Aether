class_name LuminaraDesert
extends Node2D
## F2 region gurun: pasir desert_sand CC0 (Demetrius, OGA) + paver/batu
## hangat existing (roguelikeSheet via modulate) + reruntuhan + landmark
## Gerbang Terbenam + oasis. Pasif (spawn diurus Main via marker, pola B4).
## Sinyal keluar valley + checkpoint ditangani Main.travel_to()/
## reach_checkpoint(). Tanpa ambient (gua-ambient tak cocok gurun; TERBUKA).
## Tanpa lore/quest kanon baru.

signal request_exit_to_valley
signal checkpoint_touched(region_id: String, pos: Vector2)

const REGION_ID: String = "luminara_desert"
const VALLEY_ID: String = "dawnroot_valley"


func _ready() -> void:
	add_to_group("region")
	var exit: Area2D = $ExitPortal as Area2D
	if exit != null:
		exit.body_entered.connect(_on_exit_body)
	var cp: Area2D = $CheckpointZone as Area2D
	if cp != null:
		cp.body_entered.connect(_on_checkpoint_body)


func _on_exit_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_exit_to_valley.emit()


func _on_checkpoint_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		checkpoint_touched.emit(REGION_ID, ($CheckpointZone as Area2D).global_position)
