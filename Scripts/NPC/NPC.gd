class_name NPC
extends StaticBody2D
## B3 NPC desa statis: Area2D grup interactable agar InteractArea player
## (mask 4) menemukannya; hadap player saat diajak bicara.
## Dialogue idle Bahasa Indonesia per-scene; dialog quest di QuestDef.
# ponytail: StaticBody2D tanpa AI/jadwal; upgrade path CharacterBody2D +
# patrol bila B4 butuh NPC bergerak.

@export var npc_id: String = "villager"
@export var display_name: String = "Villager"
@export var idle_lines: Array[String] = ["Halo, pengelana."]

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("npc")
	add_to_group("interactable")


func face(pos: Vector2) -> void:
	if _sprite == null:
		return
	var dx: float = pos.x - global_position.x
	if dx < -0.5:
		_sprite.flip_h = true
	elif dx > 0.5:
		_sprite.flip_h = false


func lines() -> Array[String]:
	return idle_lines.duplicate()
