class_name DawnrootCrypt
extends Node2D
## B4 root Crypt: ruang elite + reward chest + checkpoint + pintu keluar.
## Pasif (spawn diurus Main). notify_enter + checkpoint diurus Main saat
## region_changed; CheckpointZone memicu ulang hook B5 bila player kembali.

signal request_exit_to_valley
signal checkpoint_touched(region_id: String, pos: Vector2)

const REGION_ID: String = "dawnroot_crypt"
const VALLEY_ID: String = "dawnroot_valley"


func _ready() -> void:
	add_to_group("region")
	add_to_group("dungeon")
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
