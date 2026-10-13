extends SceneTree
## B4 headless test: `godot --headless --path . -s Tests/B4_RegionTest.gd`
## Uji: RegionDef .tres, boot valley (spawn/kamera/NPC/musuh/chest/entrance),
## chest sekali-ambil + loot nyata, entrance Area2D -> crypt (quest enter),
## elite + 2 skeleton, checkpoint, reward chest, kill elite -> dungeon done,
## exit -> valley + chest tetap terbuka.
# ponytail: satu file assert manual; upgrade path GUT bila suite membesar.

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


func _npc_by_id(id: String) -> NPC:
	for n: Node in get_nodes_in_group("npc"):
		var c: NPC = n as NPC
		if c != null and c.npc_id == id:
			return c
	return null


func _chest_by_name(nm: String) -> Chest:
	for n: Node in get_nodes_in_group("chest"):
		var c: Chest = n as Chest
		if c != null and c.name == nm:
			return c
	return null


func _run() -> void:
	# --- 1. Kontrak RegionDef .tres ---
	var valley_def: RegionDef = load("res://Data/Regions/dawnroot_valley.tres") as RegionDef
	var crypt_def: RegionDef = load("res://Data/Regions/dawnroot_crypt.tres") as RegionDef
	_check(valley_def != null and crypt_def != null, "2 RegionDef .tres terbaca")
	_check(valley_def.region_id == "dawnroot_valley", "valley region_id stabil")
	_check(valley_def.dungeon_ref == "dawnroot_crypt", "valley dungeon_ref dawnroot_crypt")
	_check(valley_def.spawn_pos.is_equal_approx(Vector2(640, 1150)), "valley spawn (640,1150)")
	_check(ResourceLoader.exists(valley_def.scene_path), "valley scene_path nyata: " + valley_def.scene_path)
	_check(ResourceLoader.exists(crypt_def.scene_path), "crypt scene_path nyata: " + crypt_def.scene_path)
	_check(crypt_def.checkpoint_pos.is_equal_approx(Vector2(640, 560)), "crypt checkpoint (640,560)")

	# --- 2. Boot Main -> valley ---
	var main_ps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = main_ps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "boot region = valley")
	var player: PlayerUnit = main.get_node("Player") as PlayerUnit
	_check(player.global_position.is_equal_approx(Vector2(640, 1150)), "player di spawn valley (dapat %s)" % str(player.global_position))
	var cam: Camera2D = player.get_node("Camera2D") as Camera2D
	_check(cam.limit_right == 2560 and cam.limit_bottom == 1440, "kamera limit ikut valley 2560x1440")
	_check(get_nodes_in_group("npc").size() >= 3, "Elder + 2 villager di valley (dapat %d)" % get_nodes_in_group("npc").size())
	_check(_npc_by_id("elder_maren") != null, "Elder Maren di valley")
	_check(_npc_by_id("villager_bram") != null and _npc_by_id("villager_sari") != null, "Bram + Sari di valley")
	_check(get_nodes_in_group("enemy").size() == 3, "3 encounter valley (dapat %d)" % get_nodes_in_group("enemy").size())
	_check(_enemy_by_id("slime") != null and _enemy_by_id("skeleton") != null and _enemy_by_id("wisp") != null, "slime+skeleton+wisp per ID")
	var vchest: Chest = _chest_by_name("ValleyChest")
	_check(vchest != null and not vchest.is_opened(), "ValleyChest ada & belum dibuka")
	_check(main.region_manager.current_node.get_node_or_null("DungeonEntrance") != null, "DungeonEntrance ada di valley")
	_check(main.region_manager.is_discovered("dawnroot_valley"), "valley discovered tercatat")

	# --- 3. Chest sekali-ambil + loot nyata ---
	player.global_position = vchest.global_position + Vector2(30, 0)
	main._transition_cd = 0.0
	main._on_interacted(vchest)
	var loot_n0: int = get_nodes_in_group("loot").size()
	_check(loot_n0 >= 2, "buka chest -> loot shard+potion jatuh (dapat %d)" % loot_n0)
	for i: int in 40:
		await physics_frame
	_check(main.inventory.count("aether_shard") >= 2, "shard chest masuk inventory (%d)" % main.inventory.count("aether_shard"))
	_check(main.inventory.count("health_potion") >= 1, "potion chest masuk inventory")
	_check(main.quest_manager.status_of("dawnroot_wilds") != "completed", "wilds tak completed sebelum active (relevansi)")
	main._on_interacted(vchest)
	for i: int in 3:
		await physics_frame
	_check(get_nodes_in_group("loot").size() <= loot_n0, "buka kedua -> tak ada loot baru (sekali-ambil)")

	# --- 4. Chain quest sampai dungeon active ---
	var elder: NPC = _npc_by_id("elder_maren")
	main._on_interacted(elder) # intro completed
	main._on_interacted(elder) # wilds active
	_check(main.quest_manager.status_of("dawnroot_wilds") == "active", "wilds active via Maren")
	main.quest_manager.notify_kill("slime")
	main.quest_manager.notify_kill("slime")
	main.quest_manager.notify_kill("slime")
	main._spawn_loot("aether_shard", player.global_position + Vector2(10, 0), 2)
	for i: int in 30:
		await physics_frame
	_check(main.quest_manager.status_of("dawnroot_wilds") == "completed", "wilds completed (3 slime + 2 shard)")
	main._on_interacted(elder) # dungeon available -> active
	_check(main.quest_manager.status_of("dawnroot_sealed_dungeon") == "active", "dungeon active via Maren")

	# --- 5. Entrance nyata Area2D -> crypt + quest enter + checkpoint ---
	main._transition_cd = 0.0
	player.global_position = Vector2(640, 150)
	for i: int in 8:
		await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_crypt", "entrance -> region crypt")
	_check(player.global_position.is_equal_approx(Vector2(640, 560)), "player di checkpoint crypt (dapat %s)" % str(player.global_position))
	_check(cam.limit_right == 1280 and cam.limit_bottom == 720, "kamera limit ikut crypt 1280x720")
	_check(main.quest_manager.progress_of("dawnroot_sealed_dungeon") == [1, 0], "notify_enter crypt tercatat [1,0]")
	_check(main.region_manager.checkpoint_region == "dawnroot_crypt", "checkpoint region = crypt (B5 hook)")
	_check(main.region_manager.is_discovered("dawnroot_crypt"), "crypt discovered tercatat")
	for i: int in 4:
		await physics_frame
	_check(get_nodes_in_group("enemy").size() == 3, "crypt: elite + 2 skeleton (dapat %d)" % get_nodes_in_group("enemy").size())
	var elite: EnemyBase = _enemy_by_id("elite_dawnroot")
	_check(elite != null, "elite_dawnroot spawn di crypt")
	var rchest: Chest = _chest_by_name("CryptRewardChest")
	_check(rchest != null and not rchest.is_opened(), "reward chest ada & belum dibuka")
	_check(main.region_manager.current_node.get_node_or_null("ExitPortal") != null, "ExitPortal ada di crypt")

	# --- 6. Bunuh elite -> dungeon completed + reward helm ---
	elite.apply_hit(999.0, elite.global_position + Vector2(10, 0), 0.0)
	for i: int in 4:
		await physics_frame
	_check(main.quest_manager.status_of("dawnroot_sealed_dungeon") == "completed", "kill elite -> dungeon completed")
	_check(main.inventory.count("guard_helm") >= 1, "reward guard_helm masuk inventory")

	# --- 7. Reward chest -> rusty_sword nyata ---
	player.global_position = rchest.global_position + Vector2(30, 0)
	main._on_interacted(rchest)
	for i: int in 40:
		await physics_frame
	_check(main.inventory.count("rusty_sword") >= 1, "rusty_sword chest masuk inventory")

	# --- 8. Exit nyata -> valley, chest tetap terbuka ---
	main._transition_cd = 0.0
	player.global_position = Vector2(640, 670)
	for i: int in 8:
		await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "exit -> kembali valley")
	_check(player.global_position.is_equal_approx(Vector2(640, 300)), "player di return pos valley (dapat %s)" % str(player.global_position))
	for i: int in 4:
		await physics_frame
	var vchest2: Chest = _chest_by_name("ValleyChest")
	_check(vchest2 != null and vchest2.is_opened(), "ValleyChest tetap terbuka lintas transisi")

	print("B4 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
