extends SceneTree
## F2 headless: `godot --headless --path . -s Tests/F2_LuminaraTest.gd`
## Uji: aset runtime nyata (lava strip/static, ambient ogg, desert sheet);
## Emberfall lava anim jalan + DEKOR tanpa damage; ambient play di
## emberfall/crypt + stop di valley/desert; portal Valley<->Luminara dua arah;
## discovery + 4 encounter komposisi beda + chest loot nyata + checkpoint
## (autosave) + kembali; minimap/save otomatis via sistem.
# ponytail: assert manual; upgrade path GUT bila suite membesar.

var _fail: int = 0


func _initialize() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_fail += 1
		printerr("FAIL: ", label)


func _enemy_by_id(id: String) -> EnemyBase:
	for n: Node in get_nodes_in_group("enemy"):
		var e: EnemyBase = n as EnemyBase
		if e != null and e.stats != null and e.stats.enemy_id == id:
			return e
	return null


func _chest_by_name(nm: String) -> Chest:
	for n: Node in get_nodes_in_group("chest"):
		var c: Chest = n as Chest
		if c != null and c.name == nm:
			return c
	return null


func _run() -> void:
	# --- 1. Aset runtime nyata ---
	_check(ResourceLoader.exists("res://Assets/Environment/Emberfall/lava_spr_strip45.png"), "lava strip nyata")
	_check(ResourceLoader.exists("res://Assets/Environment/Emberfall/floor_is_lava.png"), "lava static nyata")
	_check(ResourceLoader.exists("res://Assets/Audio/Ambience/dungeon_ambient_1.ogg"), "ambient ogg nyata")
	_check(ResourceLoader.exists("res://Assets/Environment/Luminara/desert_sand.png"), "desert sheet nyata")
	var strip: Texture2D = load("res://Assets/Environment/Emberfall/lava_spr_strip45.png") as Texture2D
	_check(strip != null and strip.get_size().is_equal_approx(Vector2(720, 16)), "strip 720x16 = 45 frame")
	var amb: AudioStream = load("res://Assets/Audio/Ambience/dungeon_ambient_1.ogg") as AudioStream
	_check(amb != null and amb.get_length() > 90.0, "ambient durasi >90 dtk (dapat %.1f)" % amb.get_length())

	# --- 2. RegionDef luminara ---
	var ldef: RegionDef = load("res://Data/Regions/luminara_desert.tres") as RegionDef
	_check(ldef != null and ldef.region_id == "luminara_desert", "luminara_desert tres ID beku")
	_check(ResourceLoader.exists(ldef.scene_path), "luminara scene_path nyata")
	_check(ldef.limit_right == 1920 and ldef.limit_bottom == 1080, "luminara limits 1920x1080")

	# --- 3. Boot Main -> valley + portal Luminara ada ---
	var mps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = mps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "boot valley")
	_check(main.region_manager.current_node.get_node_or_null("LuminaraPortal") is Area2D, "LuminaraPortal di valley")
	_check(not main.audio.is_ambient_playing(), "valley tanpa ambient (jujur)")

	# --- 4. Emberfall: lava anim + ambient + tanpa damage ---
	var player: PlayerUnit = main.get_node("Player") as PlayerUnit
	main._transition_cd = 0.0
	main.travel_to("emberfall_highlands")
	await physics_frame
	await physics_frame
	await physics_frame
	var lava_anims: int = 0
	for n: Node in main.region_manager.current_node.find_children("LavaAnimPool*", "AnimatedSprite2D", true, false):
		var a: AnimatedSprite2D = n as AnimatedSprite2D
		if a != null and a.is_playing() and a.sprite_frames.get_frame_count("default") == 45:
			lava_anims += 1
	_check(lava_anims == 2, "2 lava pool anim 45f jalan (dapat %d)" % lava_anims)
	_check(main.region_manager.current_node.find_children("LavaCrust*", "Sprite2D", true, false).size() == 3, "3 crust static fallback")
	var hp0: float = player.hp
	player.global_position = Vector2(700, 430)
	for i: int in 20:
		await physics_frame
	_check(player.hp >= hp0, "lava DEKOR tanpa damage (hp %.0f->%.0f)" % [hp0, player.hp])
	_check(main.audio.is_ambient_playing(), "ambient play di emberfall")

	# --- 5. Valley -> Luminara: discovery + spawn + kamera + encounter ---
	main._transition_cd = 0.0
	main.travel_to("luminara_desert")
	await physics_frame
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "luminara_desert", "valley -> luminara")
	_check(main.region_manager.is_discovered("luminara_desert"), "luminara discovered tercatat")
	_check(player.global_position.is_equal_approx(Vector2(960, 900)), "spawn luminara (960,900)")
	var cam: Camera2D = player.get_node("Camera2D") as Camera2D
	_check(cam.limit_right == 1920 and cam.limit_bottom == 1080, "kamera ikut luminara")
	_check(get_nodes_in_group("enemy").size() == 4, "4 encounter luminara (dapat %d)" % get_nodes_in_group("enemy").size())
	_check(_enemy_by_id("skeleton") != null, "skeleton area reruntuhan utara")
	_check(_enemy_by_id("wisp") != null and _enemy_by_id("ember_wisp") != null, "wisp+ember area dune selatan (komposisi beda)")
	_check(main.region_manager.current_node.get_node_or_null("SunkenGate") != null, "landmark Gerbang Terbenam")
	_check(main.region_manager.current_node.get_node_or_null("ExitPortal") is Area2D, "ExitPortal luminara ada")
	_check(not main.audio.is_ambient_playing(), "desert tanpa musik (TERBUKA, jujur)")

	# --- 6. Chest loot nyata sekali-ambil ---
	var lchest: Chest = _chest_by_name("LuminaraChest")
	_check(lchest != null and not lchest.is_opened(), "LuminaraChest ada & belum dibuka")
	player.global_position = lchest.global_position + Vector2(30, 0)
	main._transition_cd = 0.0
	main._on_interacted(lchest)
	for i: int in 40:
		await physics_frame
	_check(main.inventory.count("aether_shard") >= 2, "shard chest luminara masuk inventory")
	_check(main.inventory.count("guard_helm") >= 1, "guard_helm chest luminara masuk inventory")

	# --- 7. Checkpoint (autosave hook) + kembali valley ---
	player.global_position = Vector2(960, 900)
	for i: int in 8:
		await physics_frame
	_check(main.region_manager.checkpoint_region == "luminara_desert", "checkpoint luminara tercatat (autosave)")
	main._transition_cd = 0.0
	player.global_position = Vector2(960, 1000)
	for i: int in 8:
		await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "luminara -> valley (dua arah)")
	_check(player.global_position.is_equal_approx(Vector2(640, 300)), "kembali di return pos valley")
	var lchest2: Chest = _chest_by_name("LuminaraChest")
	_check(lchest2 == null, "chest luminara ter-unload lintas transisi (restore via _opened)")
	main._transition_cd = 0.0
	main.travel_to("luminara_desert")
	await physics_frame
	await physics_frame
	_check(_chest_by_name("LuminaraChest") != null and _chest_by_name("LuminaraChest").is_opened(), "chest tetap terbuka (save/restore)")
	main.queue_free()

	print("F2 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
