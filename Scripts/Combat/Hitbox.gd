class_name Hitbox
extends Area2D
## B2 penyerang: damage/team/knockback + swing_id unik per serangan.
## Dipakai musuh (node scene) dan swing player (dibuat via kode di Main).

signal struck(hurtbox: Hurtbox)

@export var team: StringName = &"enemy"

var damage: float = 5.0
var knockback: float = 120.0
var swing_id: int = 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	monitorable = false
	area_entered.connect(_on_area)


func _on_area(a: Area2D) -> void:
	try_hit(a)


func try_hit(a: Area2D) -> void:
	if a is Hurtbox:
		var h: Hurtbox = a as Hurtbox
		if h.team != team and h.take_hit(damage, swing_id, global_position, knockback):
			struck.emit(h)
