class_name VFX
extends Node2D
## F-C-001 combat feedback: spark hit per-jenis + poof mati per-tipe musuh
## (GPUParticles2D ringan, pooled) + slash prosedural + dodge puff +
## projectile trail + damage number capped + miss + loot/chest/quest.
## F-D world ambience: leaves/dust/embers (quality-aware, pooled).
## PERLUASAN sistem B5 (bukan sistem kedua): pool yang sama dipakai ulang,
## tanpa alokasi/frame setelah _ready (kecuali Tween sesekali, bounded).
## Quality: Low=partikel/shake/trail/ambience mati (gameplay tetap jalan),
## Balanced=setengah, High=penuh. Damage number/MISS tetap tampil di semua
## quality (murah + penting untuk keterbacaan).
## ponytail: template partikel kode (tanpa tekstur); upgrade path
## sprite Kenney bila butuh gaya pixel konsisten.
## Budget partikel (concurrent worst-case):
## Balanced: hit 6x8 + die 4x8 + puff 3x4 + trail 4x6 + ambience 2x20 = 156; High: 6x14 + 4x14 + 3x6 + 4x10 + ambience 2x40 = 258.

const HIT_POOL: int = 6
const DIE_POOL: int = 4
const PUFF_POOL: int = 3
const SLASH_POOL: int = 4
const TRAIL_POOL: int = 4
const NUM_POOL: int = 8
const MISS_POOL: int = 4
const SLASH_T: float = 0.18 # selaras jendela hitbox swing player 0-0.18s
const HEAVY_AT: float = 20.0

## F-D: ambience pools (leaves/dust/embers) — quality-aware
const LEAVES_POOL: int = 2
const DUST_POOL: int = 2
const EMBERS_POOL: int = 2
const AMBIENCE_AMOUNT_BALANCED: int = 20
const AMBIENCE_AMOUNT_HIGH: int = 40

var quality: String = "Balanced"

var _hit_pool: Array[GPUParticles2D] = []
var _die_pool: Array[GPUParticles2D] = []
var _puff_pool: Array[GPUParticles2D] = []
var _slash_pool: Array[Polygon2D] = []
var _slash_t: Array[float] = []
var _trail_pool: Array[GPUParticles2D] = []
var _trail_t: Array[float] = []
var _num_pool: Array[Label] = []
var _num_tw: Array = []
var _miss_pool: Array[Label] = []
var _miss_tw: Array = []
var _hi: int = 0
var _di: int = 0
var _pi: int = 0
var _si: int = 0
var _ti: int = 0
var _ni: int = 0
var _mi: int = 0

## F-D: ambience pools
var _leaves_pool: Array[GPUParticles2D] = []
var _dust_pool: Array[GPUParticles2D] = []
var _embers_pool: Array[GPUParticles2D] = []
var _leaves_idx: int = 0
var _dust_idx: int = 0
var _embers_idx: int = 0


func _ready() -> void:
	add_to_group("vfx")
	for i: int in HIT_POOL:
		_hit_pool.append(_make(false))
	for i: int in DIE_POOL:
		_die_pool.append(_make(true))
	for i: int in PUFF_POOL:
		_puff_pool.append(_make_puff())
	for i: int in SLASH_POOL:
		_slash_pool.append(_make_slash())
		_slash_t.append(0.0)
	for i: int in TRAIL_POOL:
		_trail_pool.append(_make_trail())
		_trail_t.append(0.0)
	for i: int in NUM_POOL:
		_num_pool.append(_make_number(20))
		_num_tw.append(null)
	for i: int in MISS_POOL:
		_miss_pool.append(_make_number(15))
		_miss_tw.append(null)

	## F-D: ambience pools
	for i: int in LEAVES_POOL:
		_leaves_pool.append(_make_leaves_ambience())
	for i: int in DUST_POOL:
		_dust_pool.append(_make_dust_ambience())
	for i: int in EMBERS_POOL:
		_embers_pool.append(_make_embers_ambience())


func _process(delta: float) -> void:
	for i: int in _slash_pool.size():
		if _slash_t[i] > 0.0:
			_slash_t[i] = maxf(0.0, _slash_t[i] - delta)
			var s: Polygon2D = _slash_pool[i]
			if _slash_t[i] <= 0.0:
				s.visible = false
			else:
				var k: float = _slash_t[i] / SLASH_T # 1->0
				var c: Color = s.color
				c.a = 0.85 * k
				s.color = c
	for i: int in _trail_pool.size():
		if _trail_t[i] > 0.0:
			_trail_t[i] = maxf(0.0, _trail_t[i] - delta)
			var p: GPUParticles2D = _trail_pool[i]
			if _trail_t[i] <= 0.0:
				p.emitting = false


func set_quality(q: String) -> void:
	if q == "Low" or q == "Balanced" or q == "High":
		quality = q
		## F-D: Low mematikan ambience yang sedang jalan (gameplay tetap).
		if quality == "Low":
			stop_ambience()


## Kind: melee (hangat), projectile (cyan), enemy (kemerahan, untuk player
## kena hit), skill/quest/gold. Kompatibel panggilan lama tanpa kind.
func hit_at(pos: Vector2, kind: String = "melee") -> void:
	if quality == "Low" or _hit_pool.is_empty():
		return
	var p: GPUParticles2D = _hit_pool[_hi % _hit_pool.size()]
	_hi += 1
	_tint(p, _hit_color(kind))
	_burst(p, pos)


## Kind: enemy_id (slime/skeleton/wisp/ember/elite) atau "" (default).
## Transform mati per-tipe tetap di EnemyBase F-B; ini hanya tint poof + tambahan ringan.
func death_at(pos: Vector2, kind: String = "") -> void:
	if quality == "Low" or _die_pool.is_empty():
		return
	var p: GPUParticles2D = _die_pool[_di % _die_pool.size()]
	_di += 1
	_tint(p, _die_color(kind))
	_burst(p, pos)
	# Tambahan ringan per tipe (pakai hit pool untuk variasi)
	if _hit_pool.is_empty():
		return
	var p2: GPUParticles2D = _hit_pool[_hi % _hit_pool.size()]
	_hi += 1
	match kind:
		"slime":
			_tint(p2, Color(0.55, 0.95, 0.5, 0.5))
			p2.amount = _amount_full() / 2
		"skeleton", "elite_dawnroot":
			_tint(p2, Color(0.9, 0.88, 0.8, 0.5))
			p2.amount = _amount_full() / 2
		"wisp", "aether_wisp":
			_tint(p2, Color(0.5, 0.95, 1.0, 0.5))
			p2.amount = _amount_full() / 2
		"ember_wisp":
			_tint(p2, Color(1.0, 0.6, 0.25, 0.5))
			p2.amount = _amount_full() / 2
		_:
			return
	_burst(p2, pos)


## Dodge puff halus di posisi awal dash; tak menutupi karakter.
func dodge_at(pos: Vector2, _dir: Vector2 = Vector2.ZERO) -> void:
	if quality == "Low" or _puff_pool.is_empty():
		return
	var p: GPUParticles2D = _puff_pool[_pi % _puff_pool.size()]
	_pi += 1
	_burst(p, pos)


## Projectile trail ringan (partikel kecil mengikuti proyektil).
## Dipanggil per-frame dari Projectile._physics_process saat quality != Low.
func trail_at(pos: Vector2, dir: Vector2) -> void:
	if quality == "Low" or _trail_pool.is_empty():
		return
	var p: GPUParticles2D = _trail_pool[_ti % _trail_pool.size()]
	var idx: int = _ti % _trail_pool.size()
	_ti += 1
	_trail_t[idx] = 0.15
	var m: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	if m != null:
		m.direction = Vector3(dir.x, dir.y, 0)
		m.spread = 30.0
	p.global_position = pos
	p.emitting = true
	p.amount = _amount_full() / 2


## Slash melee prosedural ringan (1 polygon), 0.18s selaras hitbox.
## Murah (tanpa partikel) sehingga tampil di semua quality.
func slash_at(pos: Vector2, dir: Vector2) -> void:
	if _slash_pool.is_empty():
		return
	var s: Polygon2D = _slash_pool[_si % _slash_pool.size()]
	var idx: int = _si % _slash_pool.size()
	_si += 1
	s.global_position = pos
	s.rotation = dir.angle() if dir.length() > 0.01 else 0.0
	var c := Color(1.0, 0.95, 0.85, 0.85)
	s.color = c
	s.visible = true
	_slash_t[idx] = SLASH_T


## Damage number TERBACA: font 20 + outline, capped 8 concurrent
## (round-robin reuse, tak penuhi layar). Heavy (>=20): lebih besar-oranye.
func damage_number(pos: Vector2, amount: float) -> void:
	if _num_pool.is_empty():
		return
	var l: Label = _num_pool[_ni % _num_pool.size()]
	var idx: int = _ni % _num_pool.size()
	_ni += 1
	var old = _num_tw[idx] as Tween
	if old != null and old.is_valid():
		old.kill()
	l.text = str(maxi(1, int(round(amount))))
	l.position = pos + Vector2(-14, -34)
	if amount >= HEAVY_AT:
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	else:
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color.WHITE)
	l.modulate = Color(1, 1, 1, 1)
	l.visible = true
	l.z_index = 50
	var tw: Tween = create_tween()
	_num_tw[idx] = tw
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 26.0, 0.55)
	tw.tween_property(l, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(_hide_label.bind(l))


## Miss/immune/dodge feedback: abu-abu kecil, capped 4.
func miss_at(pos: Vector2) -> void:
	if _miss_pool.is_empty():
		return
	var l: Label = _miss_pool[_mi % _miss_pool.size()]
	var idx: int = _mi % _miss_pool.size()
	_mi += 1
	var old = _miss_tw[idx] as Tween
	if old != null and old.is_valid():
		old.kill()
	l.text = "MISS"
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	l.position = pos + Vector2(-18, -30)
	l.modulate = Color(1, 1, 1, 1)
	l.visible = true
	l.z_index = 50
	var tw: Tween = create_tween()
	_miss_tw[idx] = tw
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 18.0, 0.45)
	tw.tween_property(l, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(_hide_label.bind(l))


## Loot/chest/quest/levelup: reuse hit pool dengan tint emas/hijau/cyan.
func loot_at(pos: Vector2) -> void:
	_gold_burst(pos, Color(1.0, 0.85, 0.35))


func chest_at(pos: Vector2) -> void:
	_gold_burst(pos + Vector2(0, -10), Color(1.0, 0.9, 0.5))


func quest_at(pos: Vector2) -> void:
	if quality == "Low" or _hit_pool.is_empty():
		return
	var p: GPUParticles2D = _hit_pool[_hi % _hit_pool.size()]
	_hi += 1
	_tint(p, Color(0.5, 1.0, 0.6))
	_burst(p, pos + Vector2(0, -20))


func levelup_at(pos: Vector2) -> void:
	_gold_burst(pos + Vector2(0, -20), Color(1.0, 0.95, 0.6))


## Helper headless: assert pool-bound + budget capped.
func get_budget() -> Dictionary:
	return {
		"hit": HIT_POOL, "die": DIE_POOL, "puff": PUFF_POOL,
		"slash": SLASH_POOL, "trail": TRAIL_POOL, "numbers": NUM_POOL, "miss": MISS_POOL,
		"per_hit": _amount_full(), "per_die": _amount_full(), "per_trail": _amount_full() / 2,
		"quality": quality,
	}


func _gold_burst(pos: Vector2, col: Color) -> void:
	if quality == "Low" or _hit_pool.is_empty():
		return
	var p: GPUParticles2D = _hit_pool[_hi % _hit_pool.size()]
	_hi += 1
	_tint(p, col)
	_burst(p, pos)


func _hide_label(l: Label) -> void:
	if is_instance_valid(l):
		l.visible = false


func _hit_color(kind: String) -> Color:
	match kind:
		"projectile":
			return Color(0.5, 0.95, 1.0)
		"enemy":
			return Color(1.0, 0.5, 0.45)
		"skill", "quest", "gold":
			return Color(1.0, 0.9, 0.45)
		_:
			return Color(1.0, 0.85, 0.4)


func _die_color(kind: String) -> Color:
	match kind:
		"slime":
			return Color(0.55, 0.95, 0.5)
		"skeleton":
			return Color(0.9, 0.88, 0.8)
		"wisp", "aether_wisp":
			return Color(0.5, 0.95, 1.0)
		"ember_wisp":
			return Color(1.0, 0.6, 0.25)
		"elite_dawnroot":
			return Color(1.0, 0.85, 0.35)
		_:
			return Color(0.7, 0.9, 1.0)


func _tint(p: GPUParticles2D, col: Color) -> void:
	var m: ParticleProcessMaterial = p.process_material as ParticleProcessMaterial
	if m != null:
		m.color = col


func _amount_full() -> int:
	match quality:
		"High":
			return 14
		"Balanced":
			return 8
	return 0


## F-D: ambience amount per quality
func _ambience_amount() -> int:
	match quality:
		"High":
			return AMBIENCE_AMOUNT_HIGH
		"Balanced":
			return AMBIENCE_AMOUNT_BALANCED
	return 0


func _make(big: bool) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 8
	p.lifetime = 0.4 if not big else 0.6
	p.one_shot = true
	p.explosiveness = 0.9
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.initial_velocity_min = 60.0
	m.initial_velocity_max = 160.0 if not big else 110.0
	m.gravity = Vector3(0, 220, 0)
	m.scale_min = 2.0
	m.scale_max = 4.0 if not big else 6.0
	m.color = Color(1.0, 0.85, 0.4) if not big else Color(0.7, 0.9, 1.0)
	p.process_material = m
	add_child(p)
	return p


func _make_puff() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 4
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 0.85
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 180.0
	m.initial_velocity_min = 40.0
	m.initial_velocity_max = 90.0
	m.gravity = Vector3.ZERO
	m.scale_min = 2.0
	m.scale_max = 3.0
	m.color = Color(0.85, 0.9, 0.95, 0.7)
	p.process_material = m
	add_child(p)
	return p


func _make_trail() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 6
	p.lifetime = 0.15
	p.one_shot = false
	p.explosiveness = 0.0
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, 0, 0)
	m.spread = 30.0
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 10.0
	m.gravity = Vector3.ZERO
	m.scale_min = 1.5
	m.scale_max = 2.5
	m.color = Color(0.5, 0.95, 1.0, 0.6)
	p.process_material = m
	p.emitting = false
	add_child(p)
	return p


## Busur slash: segitiga melengkung ringan, menghadap +X (di-rotate ke dir).
func _make_slash() -> Polygon2D:
	var s := Polygon2D.new()
	s.polygon = PackedVector2Array([
		Vector2(4, -16), Vector2(26, -6), Vector2(30, 0),
		Vector2(26, 6), Vector2(4, 16), Vector2(12, 0),
	])
	s.color = Color(1.0, 0.95, 0.85, 0.0)
	s.visible = false
	s.z_index = 20
	add_child(s)
	return s


func _make_number(fs: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_color_override("font_color", Color.WHITE)
	l.visible = false
	l.z_index = 50
	add_child(l)
	return l


func _burst(p: GPUParticles2D, pos: Vector2) -> void:
	p.amount = _amount_full()
	p.global_position = pos
	p.restart()


## F-D: Ambience VFX (quality-aware, pooled)
func start_ambience(vfx_name: String) -> void:
	if quality == "Low":
		return
	match vfx_name:
		"leaves":
			_start_leaves_ambience()
		"dust":
			_start_dust_ambience()
		"embers":
			_start_embers_ambience()
		_:
			return


func stop_ambience() -> void:
	_stop_leaves_ambience()
	_stop_dust_ambience()
	_stop_embers_ambience()


func _start_leaves_ambience() -> void:
	if _leaves_pool.is_empty() or quality == "Low":
		return
	var p: GPUParticles2D = _leaves_pool[_leaves_idx % _leaves_pool.size()]
	_leaves_idx += 1
	p.amount = _ambience_amount()
	p.global_position = Vector2.ZERO
	p.emitting = true


func _stop_leaves_ambience() -> void:
	for p in _leaves_pool:
		p.emitting = false


func _start_dust_ambience() -> void:
	if _dust_pool.is_empty() or quality == "Low":
		return
	var p: GPUParticles2D = _dust_pool[_dust_idx % _dust_pool.size()]
	_dust_idx += 1
	p.amount = _ambience_amount()
	p.global_position = Vector2.ZERO
	p.emitting = true


func _stop_dust_ambience() -> void:
	for p in _dust_pool:
		p.emitting = false


func _start_embers_ambience() -> void:
	if _embers_pool.is_empty() or quality == "Low":
		return
	var p: GPUParticles2D = _embers_pool[_embers_idx % _embers_pool.size()]
	_embers_idx += 1
	p.amount = _ambience_amount()
	p.global_position = Vector2.ZERO
	p.emitting = true


func _stop_embers_ambience() -> void:
	for p in _embers_pool:
		p.emitting = false


func _make_leaves_ambience() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 20
	p.lifetime = 15.0
	p.one_shot = false
	p.explosiveness = 0.0
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, 1, 0)
	m.spread = 90.0
	m.initial_velocity_min = 5.0
	m.initial_velocity_max = 20.0
	m.gravity = Vector3(0, 10, 0)
	m.scale_min = 1.0
	m.scale_max = 2.0
	m.color = Color(0.4, 0.7, 0.3, 0.4)
	var grad := Gradient.new()
	grad.set_colors(PackedColorArray([Color(0.4, 0.7, 0.3, 0.0), Color(0.4, 0.7, 0.3, 0.3), Color(0.4, 0.7, 0.3, 0.0)]))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	m.color_ramp = grad_tex
	p.process_material = m
	p.emitting = false
	return p


func _make_dust_ambience() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 15
	p.lifetime = 8.0
	p.one_shot = false
	p.explosiveness = 0.0
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, 0, 0)
	m.spread = 180.0
	m.initial_velocity_min = 2.0
	m.initial_velocity_max = 8.0
	m.gravity = Vector3.ZERO
	m.scale_min = 0.5
	m.scale_max = 1.5
	m.color = Color(0.6, 0.55, 0.5, 0.25)
	var grad := Gradient.new()
	grad.set_colors(PackedColorArray([Color(0.6, 0.55, 0.5, 0.0), Color(0.6, 0.55, 0.5, 0.2), Color(0.6, 0.55, 0.5, 0.0)]))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	m.color_ramp = grad_tex
	p.process_material = m
	p.emitting = false
	return p


func _make_embers_ambience() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 25
	p.lifetime = 3.0
	p.one_shot = false
	p.explosiveness = 0.3
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0, -1, 0)
	m.spread = 60.0
	m.initial_velocity_min = 10.0
	m.initial_velocity_max = 40.0
	m.gravity = Vector3(0, -30, 0)
	m.scale_min = 1.0
	m.scale_max = 2.5
	m.color = Color(1.0, 0.5, 0.2, 0.5)
	var grad := Gradient.new()
	grad.set_colors(PackedColorArray([Color(1.0, 0.5, 0.2, 0.0), Color(1.0, 0.5, 0.2, 0.6), Color(1.0, 0.3, 0.1, 0.0)]))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	m.color_ramp = grad_tex
	p.process_material = m
	p.emitting = false
	return p
