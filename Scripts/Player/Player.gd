class_name PlayerUnit
extends CharacterBody2D
## B1 Player: gerak 8-arah, dodge iframes, hp/stamina, scan interact.
## TANPA damage calc (itu B2). Sinyal attack/skill/interact untuk di-hook B2+.
## ponytail: 1 sprite statis AtlasTexture + flip_h; upgrade path
## AnimatedSprite2D bila frame jalan/idle berurutan tersedia (jangan
## gabung part spritesheet acak jadi animasi palsu).

signal health_changed(hp: float, max_hp: float)
signal stamina_changed(sp: float, max_sp: float)
signal died
signal attacked
signal skill_used
signal interacted(target: Node2D)

const ACCEL: float = 1200.0
const FRICTION: float = 1400.0
const FLASH_TIME: float = 0.12

@export var stats: PlayerStats

var hp: float = 100.0
var stamina: float = 100.0
var facing: Vector2 = Vector2.DOWN

var _dodge_t: float = 0.0
var _inv_t: float = 0.0
var _flash_t: float = 0.0
var _dead: bool = false
var _targets: Array[Node2D] = []
var _last_hp: float = -1.0
var _last_sp: float = -1.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _area: Area2D = $InteractArea
@onready var _body: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new()
	hp = stats.max_hp
	stamina = stats.max_stamina
	_area.area_entered.connect(_on_area_entered)
	_area.area_exited.connect(_on_area_exited)
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_emit_bar(true)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_tick(delta)
	_poll_buttons()
	var wish: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if wish.length() > 0.1:
		facing = wish.normalized()
		_sprite.flip_h = facing.x < -0.1
	if _dodge_t <= 0.0:
		_steer(wish, delta)
	move_and_slide()
	_update_look()
	_emit_bar(false)


func try_dodge() -> bool:
	if _dead or _dodge_t > 0.0 or stamina < stats.dodge_cost:
		return false
	var dir: Vector2 = facing
	var wish: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if wish.length() > 0.1:
		dir = wish.normalized()
		facing = dir
	stamina -= stats.dodge_cost
	_dodge_t = stats.dodge_time
	_inv_t = stats.dodge_iframes
	velocity = dir * stats.speed * stats.dodge_multiplier
	_emit_bar(true)
	return true


func take_damage(amount: float) -> void:
	if _dead or _inv_t > 0.0 or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash_t = FLASH_TIME
	_emit_bar(true)
	if hp <= 0.0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	_body.set_deferred("disabled", true)
	died.emit()


func respawn(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	hp = stats.max_hp
	stamina = stats.max_stamina
	_dead = false
	_dodge_t = 0.0
	_inv_t = 0.0
	_flash_t = 0.0
	_body.disabled = false
	_sprite.modulate = Color.WHITE
	_emit_bar(true)


func is_dead() -> bool:
	return _dead


func is_invincible() -> bool:
	return _inv_t > 0.0 or _dodge_t > 0.0


func has_interact_target() -> bool:
	_prune_targets()
	return not _targets.is_empty()


func interact() -> void:
	_prune_targets()
	if _targets.is_empty():
		return
	var best: Node2D = _targets[0]
	for t: Node2D in _targets:
		if global_position.distance_squared_to(t.global_position) < global_position.distance_squared_to(best.global_position):
			best = t
	interacted.emit(best)


func _tick(delta: float) -> void:
	_dodge_t = maxf(0.0, _dodge_t - delta)
	_inv_t = maxf(0.0, _inv_t - delta)
	_flash_t = maxf(0.0, _flash_t - delta)
	stamina = minf(stats.max_stamina, stamina + stats.stamina_regen * delta)


func _steer(wish: Vector2, delta: float) -> void:
	if wish.length() > 0.1:
		velocity = velocity.move_toward(wish.normalized() * stats.speed, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func _poll_buttons() -> void:
	if Input.is_action_just_pressed("dodge"):
		try_dodge()
	if Input.is_action_just_pressed("attack"):
		attacked.emit()
	if Input.is_action_just_pressed("skill"):
		skill_used.emit()
	if Input.is_action_just_pressed("interact"):
		interact()


func _update_look() -> void:
	if _flash_t > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif _inv_t > 0.0:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 0.55)
	else:
		_sprite.modulate = Color.WHITE


func _emit_bar(force: bool) -> void:
	if force or not is_equal_approx(hp, _last_hp):
		_last_hp = hp
		health_changed.emit(hp, stats.max_hp)
	if force or not is_equal_approx(stamina, _last_sp):
		_last_sp = stamina
		stamina_changed.emit(stamina, stats.max_stamina)


func _prune_targets() -> void:
	_targets = _targets.filter(func(t: Node2D) -> bool: return is_instance_valid(t))


func _on_area_entered(a: Area2D) -> void:
	if a.is_in_group("interactable"):
		_targets.append(a)


func _on_area_exited(a: Area2D) -> void:
	_targets.erase(a)


func _on_body_entered(b: Node2D) -> void:
	if b != self and b.is_in_group("interactable"):
		_targets.append(b)


func _on_body_exited(b: Node2D) -> void:
	_targets.erase(b)
