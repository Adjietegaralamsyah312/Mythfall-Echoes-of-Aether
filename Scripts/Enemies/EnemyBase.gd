class_name EnemyBase
extends CharacterBody2D
## B2 FSM musuh: IDLE/PATROL, aggro, CHASE, ATTACK, HURT, DEAD.
## Dikonfigurasi via EnemyStats. XP/loot diurus Main lewat sinyal died.
## ponytail: tanpa separation & pathfinding (arena uji terbuka);
## upgrade path: NavigationAgent2D bila arena butuh halangan kompleks.

signal died(enemy: EnemyBase)

enum S { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

const HURT_TIME: float = 0.22
const FADE_TIME: float = 0.5
const PATROL_RADIUS: float = 96.0
const DEAGGRO_MULT: float = 1.4
const FLASH_TIME: float = 0.12

@export var stats: EnemyStats

var health: Health
var _state: int = S.IDLE
var _state_t: float = 1.0
var _cool: float = 0.0
var _windup: float = -1.0
var _struck: bool = false
var _hit_off: float = -1.0
var _home: Vector2
var _patrol_target: Vector2
var _player: Node2D
var _requery_t: float = 0.0
var _flash_t: float = 0.0
var _fade_t: float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _hitbox: Hitbox = $Hitbox


func _ready() -> void:
	if stats == null:
		push_error("EnemyBase tanpa stats")
		stats = EnemyStats.new()
	add_to_group("enemy")
	_home = global_position
	_patrol_target = _home
	health = Health.new()
	health.setup(stats.max_hp)
	health.died.connect(_die)
	add_child(health)
	_hitbox.team = &"enemy"
	_hitbox.damage = stats.damage
	_hitbox.monitoring = false


func apply_hit(damage: float, from_pos: Vector2, knockback: float) -> void:
	if _state == S.DEAD:
		return
	var dir: Vector2 = Vector2.ZERO
	var off: Vector2 = global_position - from_pos
	if off.length() > 0.01:
		dir = off.normalized()
	health.damage(damage)
	_flash_t = FLASH_TIME
	if health.is_dead():
		return # _die() lewat sinyal Health.died
	velocity = dir * knockback
	_enter(S.HURT)
	_state_t = HURT_TIME


func _physics_process(delta: float) -> void:
	if _state == S.DEAD:
		_fade_t -= delta
		if _fade_t <= 0.0:
			queue_free()
		else:
			_sprite.modulate.a = clampf(_fade_t / FADE_TIME, 0.0, 1.0)
		return
	_cool = maxf(0.0, _cool - delta)
	_state_t -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	if _hit_off > 0.0:
		_hit_off -= delta
		if _hit_off <= 0.0:
			_hitbox.monitoring = false
	_refresh_player(delta)
	match _state:
		S.IDLE, S.PATROL:
			_tick_calm(delta)
		S.CHASE:
			_tick_chase(delta)
		S.ATTACK:
			_tick_attack(delta)
		S.HURT:
			_tick_hurt(delta)
	move_and_slide()
	_update_look()


func _enter(s: int) -> void:
	_state = s


func _refresh_player(delta: float) -> void:
	if is_instance_valid(_player):
		return
	_requery_t -= delta
	if _requery_t <= 0.0:
		_requery_t = 0.5
		_player = get_tree().get_first_node_in_group("player") as Node2D


func _dist_player() -> float:
	if not is_instance_valid(_player):
		return -1.0
	return global_position.distance_to(_player.global_position)


func _tick_calm(_delta: float) -> void:
	var d: float = _dist_player()
	if d >= 0.0 and d <= stats.aggro_radius:
		_enter(S.CHASE)
		return
	if _state == S.IDLE:
		if _state_t <= 0.0:
			_patrol_target = _home + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(24.0, PATROL_RADIUS)
			_enter(S.PATROL)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * _delta)
	else:
		if global_position.distance_to(_patrol_target) < 8.0:
			_enter(S.IDLE)
			_state_t = randf_range(0.8, 2.2)
		else:
			var dir: Vector2 = (_patrol_target - global_position).normalized()
			velocity = velocity.move_toward(dir * stats.speed * 0.4, 400.0 * _delta)


func _tick_chase(delta: float) -> void:
	var d: float = _dist_player()
	if d < 0.0 or d > stats.aggro_radius * DEAGGRO_MULT:
		_enter(S.IDLE)
		_state_t = 1.0
		return
	if stats.is_ranged and stats.keeps_distance and d < stats.attack_range * 0.55:
		var away: Vector2 = (global_position - _player.global_position).normalized()
		velocity = velocity.move_toward(away * stats.speed, 600.0 * delta)
		return
	if d <= stats.attack_range and _cool <= 0.0:
		_enter(S.ATTACK)
		_windup = stats.attack_windup
		_struck = false
		velocity = Vector2.ZERO
		if not stats.is_ranged:
			_hitbox.swing_id = randi_range(1, 2147483647)
			_hitbox.monitoring = true
		return
	if d > stats.attack_range:
		var toward: Vector2 = (_player.global_position - global_position).normalized()
		velocity = velocity.move_toward(toward * stats.speed, 600.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)


func _tick_attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
	_windup -= delta
	if _windup <= 0.0 and not _struck:
		_struck = true
		_strike()
		_hit_off = 0.15
		_cool = stats.attack_cooldown
		_enter(S.CHASE)


func _tick_hurt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if _state_t <= 0.0:
		_enter(S.CHASE)


func _strike() -> void:
	if stats.is_ranged:
		_shoot()
	else:
		for a: Area2D in _hitbox.get_overlapping_areas():
			_hitbox.try_hit(a)


func _shoot() -> void:
	if not is_instance_valid(_player):
		return
	var dir: Vector2 = (_player.global_position - global_position).normalized()
	var p := Projectile.new()
	get_parent().add_child(p)
	p.global_position = global_position + dir * 14.0
	p.team = &"enemy"
	p.launch(dir, stats.damage, stats.projectile_speed)


func _die() -> void:
	if _state == S.DEAD:
		return
	_enter(S.DEAD)
	_fade_t = FADE_TIME
	velocity = Vector2.ZERO
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)
	_hurtbox.set_deferred("monitoring", false)
	_hurtbox.set_deferred("monitorable", false)
	_hitbox.set_deferred("monitoring", false)
	died.emit(self)


func _update_look() -> void:
	if _flash_t > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, _sprite.modulate.a)
		return
	_sprite.modulate = Color(1.0, 1.0, 1.0, _sprite.modulate.a)
	var face_x: float = velocity.x
	if is_instance_valid(_player) and absf(velocity.x) < 5.0:
		face_x = _player.global_position.x - global_position.x
	if face_x < -0.5:
		_sprite.flip_h = true
	elif face_x > 0.5:
		_sprite.flip_h = false
