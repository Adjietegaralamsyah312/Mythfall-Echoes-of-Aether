class_name Hurtbox
extends Area2D
## B2 penerima serangan. Cek team + dedup per-swing + immunity singkat
## agar satu serangan tak hit berkali-kali.
## ponytail: swing unik via randi_range per serangan (tanpa counter global);
## upgrade path: ID terpusat bila perlu combat-log/replay.

@export var team: StringName = &"enemy"

const IMMUNITY: float = 0.35

var last_swing: int = 0
var _immune: float = 0.0


func _ready() -> void:
	monitoring = false
	monitorable = true


func _physics_process(delta: float) -> void:
	_immune = maxf(0.0, _immune - delta)


func take_hit(damage: float, swing_id: int, from_pos: Vector2, knockback: float) -> bool:
	if damage <= 0.0 or _immune > 0.0 or swing_id == last_swing:
		return false
	last_swing = swing_id
	_immune = IMMUNITY
	var p: Node = get_parent()
	if p != null and p.has_method("apply_hit"):
		p.apply_hit(damage, from_pos, knockback)
	elif p is PlayerUnit:
		(p as PlayerUnit).take_damage(damage)
	return true
