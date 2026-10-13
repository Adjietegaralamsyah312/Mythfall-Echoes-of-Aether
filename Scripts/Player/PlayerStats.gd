class_name PlayerStats
extends Resource
## B1: data angka player, terpisah dari logika PlayerUnit.
## ponytail: Resource flat di-inspect editor; upgrade path: load dari
## Data/Players/*.tres bila varian kelas dibutuhkan.

@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var speed: float = 180.0
@export var dodge_multiplier: float = 2.2
@export var dodge_time: float = 0.22
@export var dodge_iframes: float = 0.35
@export var dodge_cost: float = 20.0
@export var stamina_regen: float = 15.0
# B2: angka serangan dibaca Main untuk spawn Hitbox swing.
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 0.45
@export var attack_range: float = 48.0
