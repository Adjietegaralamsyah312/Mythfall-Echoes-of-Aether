extends Node
## Boot: loading cepat lalu pindah ke MainMenu. Tanpa splash panjang.
## Phase A: tidak ada autoload, tidak ada loading berat.

const MAIN_MENU_SCENE: String = "res://Scenes/MainMenu/MainMenu.tscn"


func _ready() -> void:
	# ponytail: self-check satu baris, gagal jujur (error + return) bukan fake loading.
	assert(ResourceLoader.exists(MAIN_MENU_SCENE), "MainMenu scene hilang.")
	if not ResourceLoader.exists(MAIN_MENU_SCENE):
		push_error("Boot gagal: %s tidak ditemukan." % MAIN_MENU_SCENE)
		return
	get_tree().call_deferred("change_scene_to_file", MAIN_MENU_SCENE)
