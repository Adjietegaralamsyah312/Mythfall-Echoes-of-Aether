class_name RegionDef
extends Resource
## B4 definisi region (kontrak B5/B6: region_id stabil, scene_path nyata).
## Satu Resource per region; region masa depan cukup tambah .tres tanpa
## scene kosong (scene dimuat dari scene_path saat dibuka).

@export var region_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var spawn_pos: Vector2 = Vector2.ZERO
@export var checkpoint_pos: Vector2 = Vector2.ZERO
## valley: dungeon_ref = id crypt; crypt: dungeon_ref = id valley induk.
@export var dungeon_ref: String = ""
@export var limit_left: int = 0
@export var limit_top: int = 0
@export var limit_right: int = 1280
@export var limit_bottom: int = 720
