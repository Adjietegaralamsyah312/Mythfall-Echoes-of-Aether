class_name LootPickup
extends Area2D
## B2 loot jatuh: magnet ringan ke player, expire 60 dtk, grup "loot".
## Diambil via Inventory grup "inventory" (penuh = tetap di tanah, jujur).
## ponytail: visual Polygon2D warna-per-type (tanpa tekstur);
## upgrade path: sprite Kenney bila tile consumable terverifikasi.

signal picked(item_id: String, gained: int)

@export var item: ItemDef
@export var qty: int = 1

const MAGNET_RADIUS: float = 96.0
const PICK_RADIUS: float = 22.0
const EXPIRE: float = 60.0

var _age: float = 0.0
var _cool: float = 0.0
var _t0: float = 0.0

@onready var _gem: Polygon2D = $Gem


func _ready() -> void:
	add_to_group("loot")
	collision_layer = 16
	collision_mask = 1
	_t0 = randf() * TAU
	if item != null:
		match item.type:
			"consumable":
				_gem.color = Color(0.95, 0.35, 0.35)
			"weapon":
				_gem.color = Color(0.8, 0.8, 0.85)
			"armor":
				_gem.color = Color(0.95, 0.8, 0.3)
			_:
				_gem.color = Color(0.5, 0.95, 1.0)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	_age += delta
	_cool = maxf(0.0, _cool - delta)
	if _age >= EXPIRE:
		queue_free()
		return
	_gem.position.y = sin(Time.get_ticks_msec() / 400.0 + _t0) * 3.0
	var p: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var d: float = global_position.distance_to(p.global_position)
	if d <= MAGNET_RADIUS and d > PICK_RADIUS:
		global_position = global_position.move_toward(p.global_position, 220.0 * delta)
	elif d <= PICK_RADIUS and _cool <= 0.0:
		_try_pickup()


func _on_body(b: Node2D) -> void:
	if b is PlayerUnit:
		_try_pickup()


func _try_pickup() -> void:
	if item == null or qty <= 0:
		return
	var inv: Inventory = get_tree().get_first_node_in_group("inventory") as Inventory
	if inv == null:
		return
	var leftover: int = inv.add(item, qty)
	var gained: int = qty - leftover
	if gained > 0:
		picked.emit(item.item_id, gained)
		if leftover <= 0:
			queue_free()
		else:
			qty = leftover
			_cool = 0.6
