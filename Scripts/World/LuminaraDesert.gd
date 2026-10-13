class_name LuminaraDesert
extends Node2D
## F2 region gurun: pasir desert_sand CC0 (Demetrius, OGA) + paver/batu
## hangat existing (roguelikeSheet via modulate) + reruntuhan + landmark
## Gerbang Terbenam + oasis. Pasif (spawn diurus Main via marker, pola B4).
## Sinyal keluar valley + checkpoint ditangani Main.travel_to()/
## reach_checkpoint(). Tanpa ambient gua (tak cocok gurun); BGM homestead
## via Main + MusicCatalog (BULK-001). Tanpa lore/quest kanon baru.

signal request_exit_to_valley
signal checkpoint_touched(region_id: String, pos: Vector2)

const REGION_ID: String = "luminara_desert"
const VALLEY_ID: String = "dawnroot_valley"
## BULK-001 puing gurun CC0 (ansimuz tiny-rpg-forest, public domain):
## kayu mati + batu sbg variasi dekor gurun. Tanpa collision.
const DEBRIS_TRUNK: String = "res://Assets/Environment/DesertDebris/trunk.png"
const DEBRIS_ROCK: String = "res://Assets/Environment/DesertDebris/rock.png"
const DEBRIS_TRUNK_POS: Array[Vector2] = [Vector2(400, 600), Vector2(1500, 800)]
const DEBRIS_ROCK_POS: Array[Vector2] = [Vector2(700, 950), Vector2(1200, 400)]


func _ready() -> void:
	add_to_group("region")
	_spawn_debris_decor()
	var exit: Area2D = $ExitPortal as Area2D
	if exit != null:
		exit.body_entered.connect(_on_exit_body)
	var cp: Area2D = $CheckpointZone as Area2D
	if cp != null:
		cp.body_entered.connect(_on_checkpoint_body)


## Dekor puing: kayu mati + batu gurun. Aman bila file hilang.
func _spawn_debris_decor() -> void:
	if ResourceLoader.exists(DEBRIS_TRUNK):
		var trunk: Texture2D = load(DEBRIS_TRUNK) as Texture2D
		if trunk != null:
			for i: int in DEBRIS_TRUNK_POS.size():
				var s := Sprite2D.new()
				s.name = "DesertTrunk%d" % (i + 1)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.scale = Vector2(2, 2)
				s.position = DEBRIS_TRUNK_POS[i]
				s.texture = trunk
				add_child(s)
	if ResourceLoader.exists(DEBRIS_ROCK):
		var rock: Texture2D = load(DEBRIS_ROCK) as Texture2D
		if rock != null:
			for j: int in DEBRIS_ROCK_POS.size():
				var r := Sprite2D.new()
				r.name = "DesertRock%d" % (j + 1)
				r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				r.scale = Vector2(2, 2)
				r.position = DEBRIS_ROCK_POS[j]
				r.texture = rock
				add_child(r)


func _on_exit_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		request_exit_to_valley.emit()


func _on_checkpoint_body(b: Node2D) -> void:
	if b.is_in_group("player"):
		checkpoint_touched.emit(REGION_ID, ($CheckpointZone as Area2D).global_position)
