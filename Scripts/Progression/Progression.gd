class_name Progression
extends Node
## B2 XP + level curve sederhana (butuh 100*level). Sinyal leveled_up
## untuk hook stat (Main: heal + bonus attack via attack_bonus()).

signal xp_changed(xp: int, level: int)
signal leveled_up(new_level: int)

var level: int = 1
var xp: int = 0


func xp_needed(lvl: int) -> int:
	return 100 * maxi(1, lvl)


func add_xp(n: int) -> void:
	if n <= 0:
		return
	xp += n
	var leveled: bool = false
	while xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		leveled = true
	xp_changed.emit(xp, level)
	if leveled:
		leveled_up.emit(level)


func attack_bonus() -> int:
	return (level - 1) * 2
