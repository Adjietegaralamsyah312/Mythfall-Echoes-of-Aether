class_name Health
extends Node
## B2 komponen HP reusable untuk musuh (player tetap pakai sistem B1-nya
## sendiri agar tidak regresi; satu file, tanpa scene tambahan).
## ponytail: Node polos, tanpa visual; upgrade path: hubungkan ke HUD B5.

signal damaged(amount: float, current: float)
signal healed(amount: float, current: float)
signal died

var max_hp: float = 10.0
var hp: float = 10.0


func setup(m: float) -> void:
	max_hp = maxf(1.0, m)
	hp = max_hp


func is_dead() -> bool:
	return hp <= 0.0


func ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)


func damage(a: float) -> bool:
	if a <= 0.0 or is_dead():
		return is_dead()
	hp = maxf(0.0, hp - a)
	damaged.emit(a, hp)
	if hp <= 0.0:
		died.emit()
	return is_dead()


func heal(a: float) -> void:
	if a <= 0.0 or is_dead():
		return
	hp = minf(max_hp, hp + a)
	healed.emit(a, hp)
