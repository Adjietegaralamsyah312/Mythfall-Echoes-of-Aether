extends SceneTree
## B2 headless test: `godot --headless --path . -s Tests/B2_CombatTest.gd`
## Uji: damage->hurt->mati->xp+loot, tak double-hitung, inventory penuh
## menolak, proyektil wisp hanya lukai player.
## ponytail: satu file assert manual; upgrade path GUT bila suite membesar.

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


func _run() -> void:
	# --- 1. Health murni ---
	var h := Health.new()
	h.setup(30.0)
	_check(h.damage(12.0) == false and is_equal_approx(h.hp, 18.0), "health damage 30-12=18")
	h.heal(5.0)
	_check(is_equal_approx(h.hp, 23.0), "health heal 18+5=23")
	_check(h.damage(999.0) == true and h.is_dead(), "health mati saat hp 0")

	# --- 2. Progression murni ---
	var pr := Progression.new()
	pr.add_xp(250)
	_check(pr.level == 2 and pr.xp == 150, "progression 250xp -> lv2 sisa 150 (dapat lv%d sisa %d)" % [pr.level, pr.xp])
	pr.add_xp(50)
	_check(pr.level == 3 and pr.xp == 0, "progression +50 -> lv3 sisa 0 (dapat lv%d sisa %d)" % [pr.level, pr.xp])

	# --- 3. Data .tres ada & ID stabil ---
	var ids: Dictionary = {}
	for p: String in ["res://Data/Enemies/slime.tres", "res://Data/Enemies/skeleton.tres", "res://Data/Enemies/wisp.tres", "res://Data/Enemies/elite_dawnroot.tres"]:
		var st: EnemyStats = load(p) as EnemyStats
		ids[st.enemy_id] = st
	_check(ids.has("slime") and ids.has("skeleton") and ids.has("wisp") and ids.has("elite_dawnroot"), "4 EnemyStats ID stabil")
	_check((ids["elite_dawnroot"] as EnemyStats).max_hp >= 2.0 * (ids["skeleton"] as EnemyStats).max_hp - 1.0, "elite stat >=2x skeleton")
	for p: String in ["res://Data/Items/health_potion.tres", "res://Data/Items/rusty_sword.tres", "res://Data/Items/aether_shard.tres", "res://Data/Items/guard_helm.tres"]:
		_check(load(p) is ItemDef, "ItemDef ada: " + p)

	# --- 4. Main hidup + 3 musuh spawn ---
	var main_ps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = main_ps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	var player: PlayerUnit = main.get_node("Player") as PlayerUnit
	_check(get_nodes_in_group("enemy").size() == 3, "3 musuh uji spawn")
	var slime: EnemyBase = _enemy_by_id("slime")
	var skel: EnemyBase = _enemy_by_id("skeleton")
	var wisp: EnemyBase = _enemy_by_id("wisp")
	_check(slime != null and skel != null and wisp != null, "slime+skeleton+wisp ketemu per ID")
	_check(wisp.stats.is_ranged, "wisp is_ranged=true")

	# --- 5. Swing player: damage tepat 1 hit ---
	player.global_position = slime.global_position + Vector2(30, 0)
	player.facing = (slime.global_position - player.global_position).normalized()
	var hp0: float = slime.health.hp
	main._on_player_attacked()
	for i: int in 6:
		await physics_frame
	_check(slime.health.hp < hp0, "swing lukai slime (%.1f -> %.1f)" % [hp0, slime.health.hp])
	_check(is_equal_approx(slime.health.hp, hp0 - 12.0), "satu swing tepat 1 hit 12 dmg (tak double)")

	# --- 6. Mati -> XP ---
	var lv0: int = main.progression.level
	var xp0: int = main.progression.xp
	slime.apply_hit(999.0, slime.global_position + Vector2(10, 0), 0.0)
	for i: int in 3:
		await physics_frame
	_check(main.progression.xp > xp0 or main.progression.level > lv0, "mati -> xp naik (+12 slime)")

	# --- 7. Loot magnet + pickup ---
	main.inventory.clear()
	main._spawn_loot("health_potion", player.global_position + Vector2(10, 0), 1)
	for i: int in 30:
		await physics_frame
	_check(main.inventory.count("health_potion") >= 1, "loot potion ter-magnet & masuk inventory")

	# --- 8. Inventory penuh menolak ---
	main.inventory.clear()
	for i: int in 20:
		var d := ItemDef.new()
		d.item_id = "test_%02d" % i
		d.type = "currency"
		d.max_stack = 99
		main.inventory.add(d, 1)
	_check(main.inventory.is_full(), "inventory 20 slot penuh")
	var dn := ItemDef.new()
	dn.item_id = "test_baru"
	dn.type = "currency"
	dn.max_stack = 99
	_check(main.inventory.add(dn, 3) == 3, "penuh: item baru ditolak penuh (sisa 3)")
	main.inventory.clear()

	# --- 9. Proyektil team-check ---
	var ehp: float = skel.health.hp
	var proj := Projectile.new()
	main.add_child(proj)
	proj.global_position = skel.global_position
	proj.team = &"enemy"
	for i: int in 3:
		await physics_frame
	_check(is_equal_approx(skel.health.hp, ehp), "proyektil enemy tak lukai enemy")
	var php: float = player.hp
	proj.global_position = player.global_position
	for i: int in 3:
		await physics_frame
	_check(player.hp < php, "proyektil enemy lukai player (%.1f -> %.1f)" % [php, player.hp])

	print("B2 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
