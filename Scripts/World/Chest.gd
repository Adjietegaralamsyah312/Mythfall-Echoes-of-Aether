class_name Chest
extends Area2D
## B4 peti sekali-ambil: grup interactable+chest agar InteractArea player
## (mask 4) menemukannya. Dibuka via Main._on_interacted -> open() ->
## loot nyata di-spawn sebagai LootPickup. Buka kedua = [] (jujur kosong).
# ponytail: visual Polygon2D tanpa tekstur; upgrade path sprite Kenney
# bila tile peti terverifikasi di sheet.

signal opened(chest: Chest)

## Loot [{item_id, qty}] diisi per-instance di scene valley/crypt.
@export var loot_items: Array[Dictionary] = []

var _opened: bool = false

@onready var _base: Polygon2D = $Base
@onready var _lid: Polygon2D = $Lid


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("chest")
	collision_layer = 4
	collision_mask = 0
	_update_visual()


func is_opened() -> bool:
	return _opened


## Kembalikan loot lalu kunci; bila sudah dibuka kembalikan [].
func open() -> Array[Dictionary]:
	if _opened:
		return []
	_opened = true
	_update_visual()
	opened.emit(self)
	var out: Array[Dictionary] = []
	for e: Dictionary in loot_items:
		out.append((e as Dictionary).duplicate())
	return out


## Dipakai Main saat restore state lintas transisi (tanpa sinyal).
func set_opened_silent() -> void:
	_opened = true
	if is_node_ready():
		_update_visual()


func _update_visual() -> void:
	if not is_node_ready():
		return
	if _opened:
		_base.color = Color(0.32, 0.24, 0.16)
		_lid.color = Color(0.45, 0.45, 0.48)
		_lid.position = Vector2(0, -7)
	else:
		_base.color = Color(0.5, 0.35, 0.2)
		_lid.color = Color(0.85, 0.65, 0.25)
		_lid.position = Vector2.ZERO
