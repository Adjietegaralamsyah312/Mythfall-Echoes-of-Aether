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
# F-B-001: visual prosedural (tanpa node/tekstur/frame baru). Sheet Kenney =
# part library, bukan frame -> JANGAN SpriteFrames palsu. Timing telegraph
# memakai _windup gameplay yang sama (selaras stat attack_windup).
const STRIKE_VIS_T: float = 0.18
const IDLE_FREQ: float = 2.2
const HOVER_FREQ: float = 3.0
const HOVER_AMP: float = 3.0

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
# F-B-001 visual state (tak sentuh gameplay; hanya transform Sprite2D).
var _anim_t: float = 0.0
var _strike_vis_t: float = 0.0
var _die_t: float = 0.0
var _base_mod: Color = Color.WHITE

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
	_base_mod = _sprite.modulate # simpan tint scene (EmberWisp oranye) agar tak tertimpa


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
		_die_t += delta
		_fade_t -= delta
		if _fade_t <= 0.0:
			queue_free()
		else:
			_sprite.modulate = Color(_base_mod.r, _base_mod.g, _base_mod.b, clampf(_fade_t / FADE_TIME, 0.0, 1.0))
			_update_anim_dead(delta)
		return
	_anim_t += delta
	_cool = maxf(0.0, _cool - delta)
	_state_t -= delta
	_flash_t = maxf(0.0, _flash_t - delta)
	_strike_vis_t = maxf(0.0, _strike_vis_t - delta)
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
	_update_anim(delta)


func _enter(s: int) -> void:
	if _state == S.DEAD:
		return # mati tak bisa idle/attack lagi (guard FSM)
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
		_strike_vis_t = STRIKE_VIS_T # visual lunge/cast nurses hit 0-0.15s, tak ubah cooldown
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
	_die_t = 0.0
	_strike_vis_t = 0.0
	velocity = Vector2.ZERO
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)
	_hurtbox.set_deferred("monitoring", false)
	_hurtbox.set_deferred("monitorable", false)
	_hitbox.set_deferred("monitoring", false)
	died.emit(self)


func _update_look() -> void:
	if _state == S.DEAD:
		return # modulate mati diatur branch DEAD (fade + base hue), jangan timpa
	var face_x: float = velocity.x
	if is_instance_valid(_player) and absf(velocity.x) < 5.0:
		face_x = _player.global_position.x - global_position.x
	if face_x < -0.5:
		_sprite.flip_h = true
	elif face_x > 0.5:
		_sprite.flip_h = false
	var a: float = 1.0
	if _flash_t > 0.0:
		# Hurt flash: campur base ke merah (putih->merah pas; oranye Ember tetap oranye-kemerahan).
		_sprite.modulate = Color(1.0, _base_mod.g * 0.45, _base_mod.b * 0.45, a)
		return
	if _state == S.ATTACK and _windup > 0.0:
		# Telegraph: tint hangat sebanding windup, hue dasar dipertahankan.
		var w: float = 1.0 - clampf(_windup / maxf(0.01, stats.attack_windup), 0.0, 1.0)
		if _is_wisp_like():
			_sprite.modulate = Color(minf(1.0, _base_mod.r + 0.25 * w), minf(1.0, _base_mod.g + 0.20 * w), _base_mod.b, a)
		else:
			_sprite.modulate = Color(_base_mod.r, _base_mod.g * (1.0 - 0.25 * w), _base_mod.b * (1.0 - 0.35 * w), a)
		return
	_sprite.modulate = Color(_base_mod.r, _base_mod.g, _base_mod.b, a)


# F-B-001: animasi prosedural ringan (tanpa node/tekstur/frame baru, tanpa
# alokasi per-frame). Prioritas: dead > hurt > attack-windup > strike >
# chase/patrol-gerak > idle/hover. Pivot terkunci: tiap cabang assign
# scale/rotation/position eksplisit, idle kembali ke (1,1,0,0).
func _update_anim(_delta: float) -> void:
	if _sprite == null or _state == S.DEAD:
		return
	if _flash_t > 0.0:
		# Hurt shake kecil + punch; knockback velocity tak diubah (gameplay tetap).
		var hk: float = _flash_t / FLASH_TIME # 1->0
		_sprite.position = Vector2(sin(_anim_t * 90.0) * 2.0 * hk, _hover_base())
		var hs: float = 1.0 + 0.06 * hk
		_sprite.scale = Vector2(hs, hs)
		_sprite.rotation = 0.0
		return
	if _state == S.ATTACK and _windup > 0.0:
		# Wind-up TERBACA, durasi = _windup gameplay yang sama (selaras stat).
		var w: float = 1.0 - clampf(_windup / maxf(0.01, stats.attack_windup), 0.0, 1.0) # 0->1
		var fx: float = -1.0 if _sprite.flip_h else 1.0
		if _is_wisp_like():
			# Cast charge: mengembang + terangkat, denyut ringan.
			var cw: float = 1.0 + 0.15 * w + 0.03 * sin(_anim_t * 40.0) * w
			_sprite.scale = Vector2(cw, cw)
			_sprite.position = Vector2(0.0, _hover_base() - 2.0 * w)
			_sprite.rotation = 0.0
		elif _is_slime():
			# Slime: jongkok squash RINGAN + mundur sedikit.
			_sprite.scale = Vector2(1.0 + 0.15 * w, 1.0 - 0.15 * w)
			_sprite.position = Vector2(-fx * 3.0 * w, 0.0)
			_sprite.rotation = 0.0
		else:
			# Skeleton/elite: telegraph jelas — jongkok + mundur + getar naik.
			var shk: float = sin(_anim_t * 60.0) * 1.5 * w * w
			_sprite.scale = Vector2(1.0 + 0.12 * w, 1.0 - 0.12 * w)
			_sprite.position = Vector2(-fx * 4.0 * w + shk, 0.0)
			_sprite.rotation = 0.0
		return
	if _strike_vis_t > 0.0:
		# Lunge/cast snap pasca-strike (di dalam jendela hit 0-0.15s / spawn proyektil).
		var k: float = _strike_vis_t / STRIKE_VIS_T # 1->0
		var fx2: float = -1.0 if _sprite.flip_h else 1.0
		if _is_wisp_like():
			var cs: float = 1.0 + 0.12 * k
			_sprite.scale = Vector2(cs, cs)
			_sprite.position = Vector2(fx2 * 2.0 * k, _hover_base())
		else:
			_sprite.position = Vector2(fx2 * 6.0 * k, 0.0)
			var st: float = 1.0 + 0.08 * k
			_sprite.scale = Vector2(st, st)
		_sprite.rotation = clampf(fx2 * 0.08 * k, -0.08, 0.08)
		return
	var spd: float = velocity.length()
	if (_state == S.CHASE or _state == S.PATROL) and spd > 10.0:
		if _is_wisp_like():
			# Hover cepat: melayang + miring ikut velocity.
			var spd_r: float = clampf(spd / maxf(1.0, stats.speed), 0.0, 2.0)
			_sprite.position = Vector2(0.0, sin(_anim_t * 6.0) * (HOVER_AMP + spd_r))
			_sprite.scale = Vector2.ONE
			_sprite.rotation = clampf(velocity.x / maxf(1.0, stats.speed) * 0.10, -0.10, 0.10)
		elif _is_slime():
			# Slime chase: squash-and-stretch RINGAN speed-sync.
			var b: float = sin(_anim_t * 9.0)
			_sprite.scale = Vector2(1.0 + 0.05 * b, 1.0 - 0.05 * b)
			_sprite.position = Vector2(0.0, -absf(b) * 1.5)
			_sprite.rotation = clampf(velocity.x / maxf(1.0, stats.speed) * 0.08, -0.08, 0.08)
		else:
			# Skeleton/elite chase: bob + lean (elite ikut, root-scale 1.35 tak tersentuh).
			var b2: float = sin(_anim_t * 10.0)
			_sprite.scale = Vector2(1.0 - 0.02 * b2, 1.0 + 0.03 * b2)
			_sprite.position = Vector2(0.0, -absf(b2) * 1.5)
			_sprite.rotation = clampf(velocity.x / maxf(1.0, stats.speed) * 0.08, -0.08, 0.08)
		return
	# Idle/patrol-diam: breath halus; wisp/ember hover terus.
	if _is_wisp_like():
		_sprite.position = Vector2(0.0, sin(_anim_t * HOVER_FREQ) * HOVER_AMP)
		var brw: float = sin(_anim_t * IDLE_FREQ)
		_sprite.scale = Vector2(1.0 - 0.01 * brw, 1.0 + 0.015 * brw)
		_sprite.rotation = 0.0
	else:
		var br: float = sin(_anim_t * IDLE_FREQ)
		if _is_slime():
			_sprite.scale = Vector2(1.0 + 0.03 * br, 1.0 - 0.03 * br)
		else:
			_sprite.scale = Vector2(1.0 - 0.01 * br, 1.0 + 0.02 * br)
		_sprite.rotation = 0.0
		_sprite.position = Vector2.ZERO


# Death beda per tipe (transform saja; disable hit + loot via _die/died tetap).
func _update_anim_dead(delta: float) -> void:
	if _sprite == null:
		return
	var k: float = clampf(_die_t / FADE_TIME, 0.0, 1.0) # 0->1
	var eid: String = ""
	if stats != null:
		eid = stats.enemy_id
	if eid == "slime":
		# Slime: kempis pipih + fade.
		_sprite.scale = Vector2(1.0 + 0.25 * k, 1.0 - 0.50 * k)
		_sprite.rotation = 0.0
		_sprite.position = Vector2.ZERO
	elif eid == "skeleton" or eid == "elite_dawnroot":
		# Skeleton/elite: roboh + fade (elite lebih jauh).
		var target: float = 0.9 if eid == "elite_dawnroot" else 0.65
		_sprite.scale = Vector2(1.0 + 0.10 * k, 1.0 - 0.20 * k)
		_sprite.rotation = lerp_angle(_sprite.rotation, target, minf(1.0, delta * 8.0))
		_sprite.position = Vector2.ZERO
	else:
		# Wisp/ember: menyusut + naik + fade.
		var s: float = 1.0 - 0.60 * k
		_sprite.scale = Vector2(s, s)
		_sprite.rotation = 0.0
		_sprite.position = Vector2(0.0, -6.0 * k)


func _hover_base() -> float:
	if _is_wisp_like():
		return sin(_anim_t * HOVER_FREQ) * HOVER_AMP
	return 0.0


func _is_wisp_like() -> bool:
	if stats != null and stats.is_ranged:
		return true
	if stats != null and "wisp" in stats.enemy_id:
		return true
	return false


func _is_slime() -> bool:
	return stats != null and stats.enemy_id == "slime"


# Helper headless (assert timing/visual, tak dipakai gameplay).
func get_anim_state() -> String:
	if _state == S.DEAD:
		return "dead"
	if _flash_t > 0.0:
		return "hurt"
	if _state == S.ATTACK and _windup > 0.0:
		return "attack_windup"
	if _strike_vis_t > 0.0:
		return "attack_strike"
	if _state == S.ATTACK:
		return "attack"
	if _state == S.CHASE:
		return "chase"
	if _state == S.PATROL:
		return "patrol"
	return "idle"


func is_telegraph_active() -> bool:
	return _state == S.ATTACK and _windup > 0.0 and _flash_t <= 0.0


func get_windup_ratio() -> float:
	if stats == null or stats.attack_windup <= 0.0:
		return 0.0
	return 1.0 - clampf(_windup / stats.attack_windup, 0.0, 1.0)


func get_windup_total() -> float:
	if stats == null:
		return 0.0
	return stats.attack_windup


func is_strike_visual_active() -> bool:
	return _strike_vis_t > 0.0


func get_strike_visual_duration() -> float:
	return STRIKE_VIS_T
