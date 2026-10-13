class_name DawnrootValley
extends Node2D
## B4 root Valley: desa + hutan + encounter marker + chest + entrance crypt.
## Pasif (tanpa spawn musuh; spawn diurus Main agar tes B2/B3 stabil).
## Sinyal keluar dungeon ditangani Main.travel_to().

signal request_enter_dungeon(dungeon_id: String)

const REGION_ID: String = "dawnroot_valley"
const DUNGEON_ID: String = "dawnroot_crypt"
const EMBER_ID: String = "emberfall_highlands"


func _ready() -> void:
	add_to_group("region")
	var entrance: Area2D = $DungeonEntrance as Area2D
	if entrance != null:
		entrance.body_entered.connect(_on_entrance_body)
	var ember: Area2D = get_node_or_null("EmberPortal") as Area2D
	if ember != null:
		ember.body_entered.connect(_on_ember_body)


func _on_entrance_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_enter_dungeon.emit(DUNGEON_ID)


func _on_ember_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_enter_dungeon.emit(EMBER_ID)
