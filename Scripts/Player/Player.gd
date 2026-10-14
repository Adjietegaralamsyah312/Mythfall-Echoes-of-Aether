class_name PlayerUnit
extends CharacterBody2D
## B1 Player: gerak 8-arah, dodge iframes, hp/stamina, scan interact.
## TANPA damage calc (itu B2). Sinyal attack/skill/interact untuk di-hook B2+.
## F-A-001: SATU tile statis (17,102,16,16) + prosedural Sprite2D.
## Sheet Kenney = PART rakitan, bukan frame berurutan -> JANGAN AnimatedSprite2D
## dari part acak (animasi palsu). Arah: gerak 8-arah, visual 1-tile + flip_h
## + tilt/bob (bukan 4/8 frame arah). Ukuran konsisten: semua scale di
## sekitar 1.0 dan selalu kembali ke (1,1,0).
## Timing selaras: attack visual 0.28s (peak ~0.14s di dalam hitbox 0-0.18s,
## mulai frame sama via sinyal; cooldown 0.45 > visual); dodge visual =
## stats.dodge_time 0.22 (stretch), iframes = stats.dodge_iframes 0.35.

signal health_changed(hp: float, max_hp: float)
signal stamina_changed(sp: float, max_sp: float)
signal died
signal attacked
signal skill_used
signal interacted(target: Node2D)
signal dodge

const ACCEL: float = 1200.0
const FRICTION: float = 1400.0
const FLASH_TIME: float = 0.12
# F-A-001 visual timing (prosedural, bukan frame). ATTACK_VIS_T > 0.18
# (hitbox Main) dan < 0.45 (cooldown) agar visual tak janji hit di luar hitbox.
const ATTACK_VIS_T: float = 0.28
const RESPAWN_VIS_T: float = 0.30
const IDLE_FREQ: float = 2.2
const IDLE_AMP: float = 0.02
# Camera shake (hanya heavy hit >= 20 dmg)
const SHAKE_DUR: float = 0.12
const SHAKE_AMP: float = 4.0

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
# F-A-001 visual state (tak sentuh gameplay selain guard attack saat hurt/dead).
var _anim_t: float = 0.0
var _step_phase: float = 0.0
var _attack_t: float = 0.0
var _attack_dir: Vector2 = Vector2.DOWN
var _die_t: float = 0.0
var _respawn_t: float = 0.0
# Camera shake state
var _shake_t: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _area: Area2D = $InteractArea
@onready var _body: CollisionShape2D = $CollisionShape2D
@onready var _camera: Camera2D = $Camera2D


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
		_tick(delta)
		_update_look()
		_update_anim(delta)
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
	# Camera shake offset (hanya visual, tak sentuh collision)
	if _shake_t > 0.0 and _camera != null:
		var k: float = _shake_t / SHAKE_DUR
		_shake_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_AMP * k
		_camera.offset = _shake_offset
	else:
		_camera.offset = Vector2.ZERO
	_update_look()
	_update_anim(delta)
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
	_attack_t = 0.0 # dodge batalkan visual attack agar tak tumpang tindih.
	velocity = dir * stats.speed * stats.dodge_multiplier
	_emit_bar(true)
	dodge.emit()
	return true


func take_damage(amount: float) -> void:
	if _dead or _inv_t > 0.0 or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	_flash_t = FLASH_TIME
	# Camera shake hanya untuk heavy hit (>= 20 dmg) dan quality != Low
	if amount >= 20.0:
		_shake_t = SHAKE_DUR
	_emit_bar(true)
	if hp <= 0.0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	_attack_t = 0.0
	_die_t = 0.0
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
	_attack_t = 0.0
	_die_t = 0.0
	_respawn_t = RESPAWN_VIS_T
	_shake_t = 0.0
	_shake_offset = Vector2.ZERO
	_body.disabled = false
	_sprite.modulate = Color.WHITE
	_sprite.scale = Vector2.ONE
	_sprite.rotation = 0.0
	_sprite.position = Vector2.ZERO
	# Snap camera langsung tanpa smoothing
	if _camera != null:
		_camera.position_smoothing_enabled = false
		_camera.global_position = global_position
		_camera.position_smoothing_enabled = true
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
	_attack_t = maxf(0.0, _attack_t - delta)
	_respawn_t = maxf(0.0, _respawn_t - delta)
	_shake_t = maxf(0.0, _shake_t - delta)
	_anim_t += delta
	stamina = minf(stats.max_stamina, stamina + stats.stamina_regen * delta)


func _steer(wish: Vector2, delta: float) -> void:
	if wish.length() > 0.1:
		velocity = velocity.move_toward(wish.normalized() * stats.speed, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func _poll_buttons() -> void:
	if Input.is_action_just_pressed("dodge"):
		try_dodge()
	# State-guard: dead/hurt tak boleh attack (gerak dead sudah dikunci di
	# _physics_process; hurt tetap boleh gerak agar feel tak berubah).
	if Input.is_action_just_pressed("attack"):
		if not _dead and _flash_t <= 0.0:
			_attack_t = ATTACK_VIS_T
			_attack_dir = facing
			attacked.emit()
	if Input.is_action_just_pressed("skill"):
		skill_used.emit()
	if Input.is_action_just_pressed("interact"):
		interact()


func _update_look() -> void:
	if _dead:
		return # modulate mati diatur _update_anim (fade), jangan timpa.
	if _flash_t > 0.0:
		_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif _inv_t > 0.0:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 0.55)
	else:
		_sprite.modulate = Color.WHITE


# F-A-001: animasi prosedural ringan (tanpa node/tekstur baru, tanpa alokasi
# per-frame). Prioritas: dead > dodge > attack > hurt > walk > idle.
# Pivot terkunci: selalu kembali ke scale (1,1), rotation 0, position (0,0).
func _update_anim(delta: float) -> void:
	if _sprite == null:
		return
	if _dead:
		_die_t += delta
		var k: float = minf(1.0, _die_t / 0.4)
		_sprite.scale = Vector2(1.0 + 0.1 * k, 1.0 - 0.35 * k)
		_sprite.rotation = lerp_angle(_sprite.rotation, 0.55, minf(1.0, delta * 8.0))
		var c: Color = _sprite.modulate
		c.a = 1.0 - 0.6 * k
		_sprite.modulate = c
		_sprite.position = Vector2.ZERO
		return
	if _respawn_t > 0.0:
		var rk: float = 1.0 - _respawn_t / RESPAWN_VIS_T # 0->1
		var s: float = 0.6 + 0.4 * rk
		_sprite.scale = Vector2(s, s)
		_sprite.rotation = 0.0
		_sprite.position = Vector2.ZERO
		var rc: Color = Color.WHITE
		rc.a = 0.2 + 0.8 * rk
		# hormati flash/inv bila bersamaan.
		if _flash_t > 0.0:
			rc = Color(1.0, 0.45, 0.45, rc.a)
		elif _inv_t > 0.0:
			rc.a *= 0.55
		_sprite.modulate = rc
		return
	if _dodge_t > 0.0:
		# Dash-stretch selama dodge_time saja (0.22s); arah ikut facing.
		var horiz: bool = absf(facing.x) >= absf(facing.y)
		if horiz:
			_sprite.scale = Vector2(1.18, 0.90)
		else:
			_sprite.scale = Vector2(0.90, 1.18)
		_sprite.rotation = clampf(facing.x * 0.12, -0.12, 0.12)
		_sprite.position = facing * 3.0
		return
	if _attack_t > 0.0:
		# Lunge mulai frame sama dengan spawn hitbox (sinyal langsung),
		# peak ~0.14s di dalam jendela hitbox 0-0.18s. JANGAN wind-up dulu.
		var el: float = ATTACK_VIS_T - _attack_t
		var ph: float = clampf(el / ATTACK_VIS_T, 0.0, 1.0) * PI
		var lunge: float = sin(ph) # 0->1->0, peak tengah (0.14s)
		_sprite.position = _attack_dir * (6.0 * lunge)
		var st: float = 1.0 + 0.08 * lunge
		_sprite.scale = Vector2(st, st)
		_sprite.rotation = clampf(_attack_dir.x * 0.10 * lunge, -0.10, 0.10)
		return
	if _flash_t > 0.0:
		# Hurt shake kecil + punch; knockback velocity tak diubah (gameplay tetap).
		var hk: float = _flash_t / FLASH_TIME # 1->0
		_sprite.position = Vector2(sin(_anim_t * 90.0) * 2.0 * hk, 0.0)
		var hs: float = 1.0 + 0.06 * hk
		_sprite.scale = Vector2(hs, hs)
		_sprite.rotation = 0.0
		return
	var spd: float = velocity.length()
	if spd > 10.0:
		# Jalan: bob speed-sync + tilt + flip_h (arah ikut velocity via facing).
		_step_phase += delta * (6.0 + 6.0 * clampf(spd / stats.speed, 0.0, 2.0))
		var b: float = sin(_step_phase)
		_sprite.scale = Vector2(1.0 - 0.02 * b, 1.0 + 0.03 * b)
		_sprite.position = Vector2(0.0, -absf(b) * 1.5)
		_sprite.rotation = clampf(velocity.x / maxf(1.0, stats.speed) * 0.08, -0.08, 0.08)
	else:
		# Idle: breath halus.
		var br: float = sin(_anim_t * IDLE_FREQ)
		_sprite.scale = Vector2(1.0 - IDLE_AMP * 0.5 * br, 1.0 + IDLE_AMP * br)
		_sprite.rotation = 0.0
		_sprite.position = Vector2.ZERO


# Helper headless (assert timing, tak dipakai gameplay).
func get_anim_state() -> String:
	if _dead:
		return "dead"
	if _dodge_t > 0.0:
		return "dodge"
	if _attack_t > 0.0:
		return "attack"
	if _flash_t > 0.0:
		return "hurt"
	if _respawn_t > 0.0:
		return "respawn"
	if velocity.length() > 10.0:
		return "walk"
	return "idle"


func is_attack_visual_active() -> bool:
	return _attack_t > 0.0


func is_dodge_visual_active() -> bool:
	return _dodge_t > 0.0


func get_attack_visual_duration() -> float:
	return ATTACK_VIS_T


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
