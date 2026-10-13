class_name EmberfallHighlands
extends Node2D
## E2 region vulkanik: basalt/caves-sheet + lava dekoratif (BUKAN tile lava
## khusus — tak ada di paket CC0; tile hangat + tint oranye + pulse ringan).
## Pasif (spawn diurus Main via marker). Sinyal keluar valley + checkpoint
## ditangani Main.travel_to()/reach_checkpoint() (pola B4 crypt).
# ponytail: lava Polygon2D pulse via _process; upgrade path shader bila perlu.

signal request_exit_to_valley
signal checkpoint_touched(region_id: String, pos: Vector2)

const REGION_ID: String = "emberfall_highlands"
const VALLEY_ID: String = "dawnroot_valley"
## F2 lava nyata CC0 (davesch, LPC): strip 720x16 = 45 frame 16x16.
## Uji tile F2: 17/45 frame seamless (avg L-R diff 42.4) -> GAGAL tile
## infinite (sesuai peringatan Charlie). Dipakai sebagai kolam berbingkai
## (framed pools, 2 titik) + crust static floor_is_lava (Kipperfalcon CC0).
## DEKOR SAJA: tanpa Hurtbox/damage (plan: jangan auto-damage).
# ponytail: SpriteFrames dirakit di kode (1 file, bukan 45 sub_resource tscn).
const LAVA_STRIP: String = "res://Assets/Environment/Emberfall/lava_spr_strip45.png"
const LAVA_CRUST: String = "res://Assets/Environment/Emberfall/floor_is_lava.png"
const LAVA_POOL_POS: Array[Vector2] = [Vector2(700, 430), Vector2(1400, 650)]
const LAVA_CRUST_CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 0)]

var _t: float = 0.0

@onready var _lava: Polygon2D = $LavaFissure
@onready var _pool: Polygon2D = $LavaPool


func _ready() -> void:
	add_to_group("region")
	_spawn_lava_decor()
	var exit: Area2D = $ExitPortal as Area2D
	if exit != null:
		exit.body_entered.connect(_on_exit_body)
	var cp: Area2D = $CheckpointZone as Area2D
	if cp != null:
		cp.body_entered.connect(_on_checkpoint_body)


func _process(delta: float) -> void:
	_t += delta
	var k: float = 0.5 + 0.12 * sin(_t * 2.0)
	if is_instance_valid(_lava):
		_lava.color = Color(0.9, 0.35 + 0.1 * k, 0.1, 0.85)
	if is_instance_valid(_pool):
		_pool.color = Color(0.95, 0.4 + 0.1 * k, 0.12, 0.9)


func _on_exit_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_exit_to_valley.emit()


func _on_checkpoint_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		checkpoint_touched.emit(REGION_ID, ($CheckpointZone as Area2D).global_position)


## Lava dekor: AnimatedSprite2D framed pools dari strip + crust static.
## Tanpa collision/damage. Aman bila file hilang (skip diam-diam).
func _spawn_lava_decor() -> void:
	if not ResourceLoader.exists(LAVA_STRIP) and not ResourceLoader.exists(LAVA_CRUST):
		return
	if ResourceLoader.exists(LAVA_STRIP):
		var strip: Texture2D = load(LAVA_STRIP) as Texture2D
		if strip != null:
			var frames := SpriteFrames.new()
			frames.set_animation_speed("default", 12.0)
			frames.set_animation_loop("default", true)
			for i: int in 45:
				var at := AtlasTexture.new()
				at.atlas = strip
				at.region = Rect2(i * 16, 0, 16, 16)
				frames.add_frame("default", at)
			for pi: int in LAVA_POOL_POS.size():
				var a := AnimatedSprite2D.new()
				a.name = "LavaAnimPool%d" % (pi + 1)
				a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				a.scale = Vector2(3, 3)
				a.position = LAVA_POOL_POS[pi]
				a.sprite_frames = frames
				add_child(a)
				a.play("default")
	if ResourceLoader.exists(LAVA_CRUST):
		var crust: Texture2D = load(LAVA_CRUST) as Texture2D
		if crust != null:
			var base := Vector2(940, 470)
			for i: int in LAVA_CRUST_CELLS.size():
				var cell: Vector2i = LAVA_CRUST_CELLS[i]
				var at2 := AtlasTexture.new()
				at2.atlas = crust
				at2.region = Rect2(cell.x * 16, cell.y * 16, 16, 16)
				var s := Sprite2D.new()
				s.name = "LavaCrust%d" % (i + 1)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.scale = Vector2(3, 3)
				s.position = base + Vector2(i * 48, 0)
				s.texture = at2
				add_child(s)
