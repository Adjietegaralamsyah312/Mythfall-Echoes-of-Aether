class_name Inventory
extends Node
## B2 kantong item TANPA UI (UI di B5). Kapasitas 20 slot, satu tumpuk per
## item_id. Penuh = tolak jujur (kembalikan sisa). Grup "inventory".
## ponytail: satu tumpuk per item_id; upgrade path multi-slot per item.

signal changed

const CAPACITY: int = 20
const TYPES: Array[String] = ["weapon", "armor", "consumable", "currency"]

var _slots: Dictionary = {} # item_id -> {"item": ItemDef, "qty": int}


func _ready() -> void:
	add_to_group("inventory")


func slots_used() -> int:
	return _slots.size()


func is_full() -> bool:
	return _slots.size() >= CAPACITY


func count(item_id: String) -> int:
	var e: Dictionary = _slots.get(item_id, {})
	return int(e.get("qty", 0))


func get_item(item_id: String) -> ItemDef:
	var e: Dictionary = _slots.get(item_id, {})
	return e.get("item") as ItemDef


## Kembalikan sisa yang TIDAK masuk (0 = semua masuk).
func add(item: ItemDef, qty: int) -> int:
	if item == null or qty <= 0 or item.item_id.is_empty():
		return qty
	if not TYPES.has(item.type):
		push_warning("Inventory.add: type tak dikenal: " + item.type)
		return qty
	var e: Dictionary = _slots.get(item.item_id, {})
	if e.is_empty():
		if is_full():
			return qty
		var take: int = mini(qty, maxi(1, item.max_stack))
		_slots[item.item_id] = {"item": item, "qty": take}
		changed.emit()
		return qty - take
	var space: int = maxi(1, (e["item"] as ItemDef).max_stack) - int(e["qty"])
	var take2: int = mini(qty, maxi(0, space))
	if take2 > 0:
		e["qty"] = int(e["qty"]) + take2
		changed.emit()
	return qty - take2


func remove(item_id: String, qty: int) -> bool:
	if qty <= 0:
		return false
	var e: Dictionary = _slots.get(item_id, {})
	if e.is_empty() or int(e["qty"]) < qty:
		return false
	e["qty"] = int(e["qty"]) - qty
	if int(e["qty"]) <= 0:
		_slots.erase(item_id)
	changed.emit()
	return true


func clear() -> void:
	if _slots.is_empty():
		return
	_slots.clear()
	changed.emit()
