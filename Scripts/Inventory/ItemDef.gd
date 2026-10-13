class_name ItemDef
extends Resource
## B2 definisi item (kontrak B3/B4: item_id stabil).
## type: weapon/armor/consumable/currency (divalidasi di Inventory.add).

@export var item_id: String = "health_potion"
@export var display_name: String = "Health Potion"
@export var type: String = "consumable"
@export var heal_amount: float = 0.0
@export var damage_bonus: float = 0.0
@export var description: String = ""
@export var max_stack: int = 10
