class_name Projectile
extends Area2D
## B2 proyektil minimal untuk Aether Wisp. Team-check via Hurtbox
## (team enemy: hanya lukai player). Umur pendek, despawn di dinding.
## ponytail: visual Polygon2D via kode (tanpa tekstur), tanpa pooling;
## upgrade path: pooling + trail bila jumlah proyektil padat.

var team: StringName = &"enemy"
var damage: float = 8.0
var speed: float = 260.0
var direction: Vector2 = Vector2.RIGHT
var knockback: float = 60.0
var _life: float = 1.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 9
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	cs.shape = circle
	add_child(cs)
	var dot := Polygon2D.new()
	var pts := PackedVector2Array()
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		pts.append(Vector2(cos(a), sin(a)) * 5.0)
	dot.polygon = pts
	dot.color = Color(0.5, 0.95, 1.0)
	add_child(dot)
	area_entered.connect(_on_area)
	body_entered.connect(_on_body)


func launch(dir: Vector2, dmg: float, spd: float) -> void:
	direction = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	damage = dmg
	speed = spd
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_area(a: Area2D) -> void:
	if a is Hurtbox:
		var h: Hurtbox = a as Hurtbox
		if h.team != team:
			if h.take_hit(damage, randi_range(1, 2147483647), global_position, knockback):
				queue_free()


func _on_body(b: Node2D) -> void:
	if b is PlayerUnit:
		return # damage lewat Hurtbox milik player
	queue_free()
