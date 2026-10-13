extends SceneTree
## B5 headless test: `godot --headless --path . -s Tests/B5_SaveTest.gd`
## Uji: SaveManager valid/invalid/corrupt, settings, Main save->mutate->
## restore roundtrip, error jujur. ponytail: assert manual.

var _fail: int = 0


func _initialize() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_fail += 1
		printerr("FAIL: ", label)


func _run() -> void:
	# --- 1. SaveManager murni ---
	var sm := SaveManager.new()
	root.add_child(sm)
	sm.clear()
	_check(not sm.has_save(), "tanpa save awal")
	_check(sm.load_game().is_empty(), "load tanpa file -> {}")
	var good: Dictionary = {
		"player": {"pos": Vector2(100, 200), "level": 3, "xp": 40, "hp": 80.0, "inventory": {"health_potion": 2}},
		"quest": {"status": {"dawnroot_intro": "completed"}, "progress": {"dawnroot_intro": [1]}},
		"region": {"current": "dawnroot_valley", "discovered": ["dawnroot_valley"], "checkpoint_region": "dawnroot_valley", "checkpoint_pos": Vector2(640, 1150), "opened": {}},
		"settings": {"master": 0.8, "music": 0.5, "sfx": 1.0, "sensitivity": 1.0, "quality": "Low", "ui_scale": 1.0},
	}
	_check(sm.save_game(good) == OK, "save valid OK")
	_check(sm.has_save(), "has_save true")
	var back: Dictionary = sm.load_game()
	_check(not back.is_empty() and int((back["player"] as Dictionary).get("level", 0)) == 3, "load kembali level 3")
	_check(sm.validate(back), "validate true untuk data baik")
	var bad: Dictionary = {"player": {}, "meta": {"version": 999}}
	_check(not sm.validate(bad), "validate tolak versi liar")
	sm.store_settings({"master": 0.5, "quality": "High"})
	_check(str(sm.load_settings().get("quality", "")) == "High", "settings roundtrip High")
	# --- 2. Corrupt fallback aman ---
	var f := FileAccess.open("user://mythfall_save.cfg", FileAccess.WRITE)
	f.store_string("{{{ini bukan config valid???")
	f.close()
	var corrupt: Dictionary = sm.load_game()
	_check(corrupt.is_empty(), "corrupt -> {} aman + load_failed")
	sm.clear()

	# --- 3. Main roundtrip: save -> mutate -> restore ---
	var main_ps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = main_ps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(main.get("ui") != null, "Main punya GameUI")
	_check(main.get("audio") != null, "Main punya AudioManager")
	_check(main.get("vfx") != null, "Main punya VFX")
	_check(main.get("_dialog_label") != null, "kompat _dialog_label ada")
	main.save_now()
	_check(sm.has_save() or FileAccess.file_exists("user://mythfall_save.cfg"), "save_now tulis file")
	var snap: Dictionary = main.collect_save_data()
	_check((snap["player"] as Dictionary).has("pos"), "collect ada pos")
	_check((snap["region"] as Dictionary).has("discovered"), "collect ada discovered")
	var orig_pos: Vector2 = main.get_node("Player").global_position
	(main.get_node("Player") as PlayerUnit).global_position = Vector2(10, 10)
	main.inventory.clear()
	main._apply_save_data(snap)
	_check((main.get_node("Player") as PlayerUnit).global_position.is_equal_approx(orig_pos), "restore posisi kembali")
	# quest tracker + dialogue panel nyata
	main._on_interacted(main.get_node("Player"))
	if main.get("ui") != null:
		(main.get("ui") as GameUI).show_dialogue(["Halo, uji."], "Uji")
		_check((main.get("ui") as GameUI).is_dialogue_open(), "dialogue panel terbuka")
		(main.get("ui") as GameUI).close_dialog()
		_check(not (main.get("ui") as GameUI).is_dialogue_open(), "dialogue panel tertutup")
		(main.get("ui") as GameUI).show_error("Uji error jujur.")
	# pause benar (pohon paused + resume)
	(main.get("ui") as GameUI).toggle_pause()
	_check(paused, "pause hentikan pohon")
	(main.get("ui") as GameUI).toggle_pause()
	_check(not paused, "resume jalan lagi")
	sm.clear()
	sm.queue_free()

	print("B5 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
