class_name VFX
extends Node2D
## B5 spark hit + poof mati (GPUParticles2D ringan, pooled) + damage number.
## Quality: Low=matikan partikel, Balanced=setengah, High=penuh.
## ponytail: 2 template partikel kode (tanpa tekstur); upgrade path
## sprite Kenney bila butuh gaya pixel konsisten.

var quality: String = "Balanced"

var _hit_pool: Array[GPUParticles2D] = []
var _die_pool: Array[GPUParticles2D] = []
var _hi: int = 0
var _di: int = 0


func _ready() -> void:
	for i: int in 6:
		_hit_pool.append(_make(false))
	for i: int in 4:
		_die_pool.append(_make(true))


func set_quality(q: String) -> void:
	if q == "Low" or q == "Balanced" or q == "High":
		quality = q


func hit_at(pos: Vector2) -> void:
	if quality == "Low" or _hit_pool.is_empty():
		return
	_burst(_hit_pool[_hi % _hit_pool.size()], pos)
	_hi += 1


func death_at(pos: Vector2) -> void:
	if quality == "Low" or _die_pool.is_empty():
		return
	_burst(_die_pool[_di % _die_pool.size()], pos)
	_di += 1


func damage_number(pos: Vector2, amount: float) -> void:
	var l := Label.new()
	l.text = str(int(round(amount)))
	l.position = pos + Vector2(-12, -28)
	l.z_index = 50
	add_child(l)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 28.0, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(l.queue_free)


func _amount_full() -> int:
	match quality:
		"High":
			return 14
		"Balanced":
			return 8
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


func _burst(p: GPUParticles2D, pos: Vector2) -> void:
	p.amount = _amount_full()
	p.global_position = pos
	p.restart()
