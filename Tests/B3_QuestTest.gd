extends SceneTree
## B3 headless test: `godot --headless --path . -s Tests/B3_QuestTest.gd`
## Uji: chain intro->wilds->dungeon, relevansi target (skeleton/item salah
## tak maju), enter + kill_elite dungeon, to_dict/from_dict, hook Main
## (NPC spawn, interacted, kill/collect nyata, reward).
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


func _defs() -> Array[QuestDef]:
	var out: Array[QuestDef] = []
	for p: String in ["res://Data/Quests/dawnroot_intro.tres", "res://Data/Quests/dawnroot_wilds.tres", "res://Data/Quests/dawnroot_sealed_dungeon.tres"]:
		out.append(load(p) as QuestDef)
	return out


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


func _run() -> void:
	# --- 1. Kontrak .tres: ID stabil + chain ---
	var defs: Array[QuestDef] = _defs()
	_check(defs.size() == 3 and defs[0] != null and defs[1] != null and defs[2] != null, "3 QuestDef .tres terbaca")
	var by_id: Dictionary = {}
	for d: QuestDef in defs:
		by_id[d.quest_id] = d
	_check(by_id.has("dawnroot_intro") and by_id.has("dawnroot_wilds") and by_id.has("dawnroot_sealed_dungeon"), "quest_id stabil sesuai kontrak")
	_check((by_id["dawnroot_wilds"] as QuestDef).prereq_ids == ["dawnroot_intro"], "wilds prereq intro")
	_check((by_id["dawnroot_sealed_dungeon"] as QuestDef).prereq_ids == ["dawnroot_wilds"], "dungeon prereq wilds")
	_check((by_id["dawnroot_wilds"] as QuestDef).giver_npc_id == "elder_maren", "giver elder_maren")
	_check(not (by_id["dawnroot_intro"] as QuestDef).accept_lines.is_empty(), "dialogue Indonesia inline ada")

	# --- 2. Chain murni: intro -> wilds available ---
	var qm := QuestManager.new()
	root.add_child(qm)
	qm.setup(defs)
	_check(qm.status_of("dawnroot_intro") == "available", "intro available awal")
	_check(qm.status_of("dawnroot_wilds") == "locked", "wilds locked sebelum prereq")
	_check(qm.accept("dawnroot_intro"), "accept intro")
	qm.notify_talk("elder_maren")
	_check(qm.status_of("dawnroot_intro") == "completed", "talk Maren -> intro completed")
	_check(qm.status_of("dawnroot_wilds") == "available", "intro done -> wilds available")

	# --- 3. Relevansi: kill/collect salah tak maju ---
	_check(qm.accept("dawnroot_wilds"), "accept wilds")
	qm.notify_kill("skeleton")
	_check(qm.progress_of("dawnroot_wilds") == [0, 0], "kill skeleton TAK tambah slime")
	qm.notify_collect("health_potion", 2)
	_check(qm.progress_of("dawnroot_wilds") == [0, 0], "collect potion TAK tambah shard")
	qm.notify_kill("slime")
	qm.notify_kill("slime")
	qm.notify_kill("slime")
	qm.notify_collect("aether_shard", 2)
	_check(qm.status_of("dawnroot_wilds") == "completed", "3 slime + 2 shard -> wilds completed")
	_check(qm.status_of("dawnroot_sealed_dungeon") == "available", "wilds done -> dungeon available")

	# --- 4. Dungeon: enter salah + kill biasa tak maju ---
	_check(qm.accept("dawnroot_sealed_dungeon"), "accept dungeon")
	qm.notify_enter("emberfall_crypt")
	qm.notify_kill("elite_dawnroot")
	_check(qm.progress_of("dawnroot_sealed_dungeon") == [0, 0], "enter salah + kill biasa TAK maju elite")
	qm.notify_enter("dawnroot_crypt")
	qm.notify_kill_elite("elite_dawnroot")
	_check(qm.status_of("dawnroot_sealed_dungeon") == "completed", "enter crypt + elite -> dungeon completed")
	qm.queue_free()

	# --- 5. Roundtrip save B5 ---
	var qm2 := QuestManager.new()
	root.add_child(qm2)
	qm2.setup(defs)
	qm2.accept("dawnroot_intro")
	qm2.notify_talk("elder_maren")
	qm2.accept("dawnroot_wilds")
	qm2.notify_kill("slime")
	var snap: Dictionary = qm2.to_dict()
	var qm3 := QuestManager.new()
	root.add_child(qm3)
	qm3.setup(defs)
	qm3.from_dict(snap)
	_check(qm3.status_of("dawnroot_intro") == "completed", "roundtrip: intro tetap completed")
	_check(qm3.progress_of("dawnroot_wilds") == [1, 0], "roundtrip: wilds progress [1,0]")
	qm3.from_dict({"status": {"dawnroot_intro": "nonsense"}, "progress": {}})
	_check(qm3.status_of("dawnroot_intro") == "completed", "from_dict tolak status liar")
	qm2.queue_free()
	qm3.queue_free()

	# --- 6. Hook Main: NPC + interact + kill/collect nyata ---
	var main_ps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = main_ps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	_check(main.quest_manager != null, "Main punya QuestManager")
	_check(get_nodes_in_group("npc").size() >= 3, "Elder + 2 villager spawn (dapat %d)" % get_nodes_in_group("npc").size())
	var elder: NPC = _npc_by_id("elder_maren")
	_check(elder != null, "Elder Maren ketemu per npc_id")
	_check(elder.get_node_or_null("InteractArea").is_in_group("interactable"), "NPC InteractArea grup interactable")
	var player: PlayerUnit = main.get_node("Player") as PlayerUnit
	player.global_position = Vector2(100, 100) # jauh: loot drop acak tak ke-magnet
	main._on_interacted(elder)
	await physics_frame
	_check(main.quest_manager.status_of("dawnroot_intro") == "completed", "bicara Maren -> intro complete")
	_check(main.quest_manager.status_of("dawnroot_wilds") == "available", "intro -> wilds available")
	_check(main._dialog_label.visible, "panel dialogue sementara tampil")
	main._on_interacted(elder)
	_check(main.quest_manager.status_of("dawnroot_wilds") == "active", "bicara ke-2 -> wilds active")
	var skel: EnemyBase = _enemy_by_id("skeleton")
	skel.apply_hit(999.0, skel.global_position + Vector2(10, 0), 0.0)
	for i: int in 3:
		await physics_frame
	_check(main.quest_manager.progress_of("dawnroot_wilds") == [0, 0], "skeleton nyata mati -> slime tetap [0,0]")
	main._spawn_loot("health_potion", player.global_position + Vector2(10, 0), 1)
	for i: int in 30:
		await physics_frame
	_check(main.inventory.count("health_potion") >= 1, "loot potion nyata masuk inventory")
	_check(main.quest_manager.progress_of("dawnroot_wilds") == [0, 0], "potion nyata -> shard tetap [0,0]")
	var slime: EnemyBase = _enemy_by_id("slime")
	slime.apply_hit(999.0, slime.global_position + Vector2(10, 0), 0.0)
	for i: int in 3:
		await physics_frame
	_check(main.quest_manager.progress_of("dawnroot_wilds")[0] == 1, "slime nyata mati -> slime 1/3")
	main.quest_manager.notify_kill("slime")
	main.quest_manager.notify_kill("slime")
	main._spawn_loot("aether_shard", player.global_position + Vector2(10, 0), 2)
	for i: int in 30:
		await physics_frame
	_check(main.quest_manager.status_of("dawnroot_wilds") == "completed", "shard nyata pickup -> wilds completed")
	_check(main.quest_manager.status_of("dawnroot_sealed_dungeon") == "available", "wilds -> dungeon available")
	_check(main.inventory.count("rusty_sword") >= 1, "reward wilds rusty_sword masuk inventory")

	print("B3 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
