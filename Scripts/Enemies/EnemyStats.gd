class_name EnemyStats
extends Resource
## B2 definisi data musuh (kontrak B3/B4: enemy_id stabil, loot_table
## [{item_id, chance}]). Perilaku beda tipe via data (windup, speed,
## is_ranged), bukan via script duplikat.

@export var enemy_id: String = "slime"
@export var display_name: String = "Slime"
@export var max_hp: float = 30.0
@export var damage: float = 6.0
@export var speed: float = 55.0
@export var aggro_radius: float = 180.0
@export var attack_range: float = 26.0
@export var attack_cooldown: float = 1.4
@export var attack_windup: float = 0.4
@export var xp_reward: int = 12
@export var is_ranged: bool = false
@export var projectile_speed: float = 260.0
@export var keeps_distance: bool = false
@export var loot_table: Array[Dictionary] = []
