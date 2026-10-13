extends SceneTree
## E3 headless: `godot --headless --path . -s Tests/E3_PackTest.gd`
## Uji: ID unik, contents ada, angka==du (±16384 toleransi .import/manifest),
## emberfall region+portal dua arah, registry kompatibel (initial valid, D2 tolak tetap).
# ponytail: assert manual; upgrade path GUT bila suite membesar.

const TOL: int = 16384
const EXP_INITIAL: int = 127584207
const EXP_EMBER: int = 329853
## F3: luminara terisi (v0.1.0); 3 paket lain tetap rencana.

var _fail: int = 0


func _initialize() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_fail += 1
		printerr("FAIL: ", label)


func _exists_res(p: String) -> bool:
	if ResourceLoader.exists(p):
		return true
	var disk: String = p.replace("res://", "./")
	return FileAccess.file_exists(disk) or DirAccess.dir_exists_absolute(disk)


func _run() -> void:
	var reg := PackRegistry.new()
	_check(reg.load_all() == 6, "registry 6 paket")
	var ids: Dictionary = {}
	for p: PackDef in reg.list_packs():
		_check(not ids.has(p.pack_id), "ID unik " + p.pack_id)
		ids[p.pack_id] = true
	for pid: String in PackRegistry.PACK_IDS:
		_check(ids.has(pid), "kontrak ID beku " + pid)
	# --- initial tetap valid (kompatibel D1/D2) ---
	var ini: PackDef = reg.get_pack("initial")
	_check(ini != null and ini.status == PackDef.Status.BUILT_IN, "initial BUILT_IN")
	_check(ini.file_bytes == 0, "initial file_bytes 0")
	_check(absi(ini.installed_bytes - EXP_INITIAL) <= TOL, "initial %d ~= du %d" % [ini.installed_bytes, EXP_INITIAL])
	_check(reg.installed_size("initial") == ini.installed_bytes, "installed_size initial konsisten")
	_check(not ini.contents.is_empty(), "initial contents tak kosong")
	for c: String in ini.contents:
		_check(_exists_res(c), "initial contents ada: " + c)
	# --- emberfall: lokal-terpasang, belum-bisa-diunduh ---
	var em: PackDef = reg.get_pack("emberfall")
	_check(em != null, "emberfall manifest ada")
	_check(em.status == PackDef.Status.UNAVAILABLE, "emberfall tetap UNAVAILABLE (unduh; lokal playable)")
	_check(em.download_url.strip_edges().is_empty(), "emberfall URL kosong (tanpa hosting)")
	_check(em.file_bytes == -1 and em.sha256.strip_edges().is_empty(), "emberfall file_bytes -1 + sha kosong")
	_check(em.version == "0.1.0", "emberfall v0.1.0")
	_check(absi(em.installed_bytes - EXP_EMBER) <= TOL, "emberfall %d ~= du %d" % [em.installed_bytes, EXP_EMBER])
	_check(em.contents.size() == 11, "emberfall 11 contents (dapat %d)" % em.contents.size())
	_check(em.region_ids.size() == 1 and em.region_ids.has("emberfall_highlands"), "emberfall region_ids tunggal")
	_check(em.license_note.contains("CC0"), "emberfall license CC0")
	for c2: String in em.contents:
		_check(_exists_res(c2), "emberfall contents ada: " + c2)
	# subset (tanpa double-count: tiap emberfall path di bawah dir initial)
	var ini_dirs: Array[String] = ["res://Assets", "res://Scenes", "res://Scripts", "res://Data"]
	for c3: String in em.contents:
		var sub: bool = false
		for d: String in ini_dirs:
			if c3 == d or c3.begins_with(d + "/"):
				sub = true
		_check(sub, "emberfall subset initial: " + c3)
	_check(em.installed_bytes < ini.installed_bytes, "emberfall < initial (subset, total=initial)")
	# --- luminara F3: lokal-terpasang, belum-bisa-diunduh (pola E3) ---
	var lu: PackDef = reg.get_pack("luminara")
	_check(lu != null and lu.status == PackDef.Status.UNAVAILABLE, "luminara UNAVAILABLE")
	_check(lu.file_bytes == -1 and lu.sha256.strip_edges().is_empty(), "luminara file_bytes -1 + sha kosong")
	_check(lu.version == "0.1.0", "luminara v0.1.0")
	_check(absi(lu.installed_bytes - 1672604) <= TOL, "luminara %d ~= du 1672604" % lu.installed_bytes)
	_check(lu.contents.size() == 7, "luminara 7 contents (dapat %d)" % lu.contents.size())
	_check(lu.region_ids.has("luminara_desert"), "luminara region luminara_desert")
	for c4: String in lu.contents:
		_check(_exists_res(c4), "luminara contents ada: " + c4)
	# --- 3 paket lain tetap rencana ---
	for pid2: String in ["veilwood", "azure", "aether_crown"]:
		var q: PackDef = reg.get_pack(pid2)
		_check(q != null and q.status == PackDef.Status.UNAVAILABLE, pid2 + " UNAVAILABLE")
		_check(q.file_bytes == -1 and q.installed_bytes == -1 and q.contents.is_empty(), pid2 + " -1 + kosong")
	_check(not reg.is_available("emberfall"), "registry: emberfall tak available (D2 tolak preserved)")
	# --- region + scene Emberfall ---
	var rdef: RegionDef = load("res://Data/Regions/emberfall_highlands.tres") as RegionDef
	_check(rdef != null and rdef.region_id == "emberfall_highlands", "region emberfall terbaca")
	_check(ResourceLoader.exists(rdef.scene_path), "scene_path nyata: " + rdef.scene_path)
	_check(rdef.spawn_pos.is_equal_approx(Vector2(960, 900)), "spawn/checkpoint (960,900)")
	var eps: PackedScene = load(rdef.scene_path) as PackedScene
	_check(eps != null, "EmberfallHighlands.tscn load")
	var en: Node2D = eps.instantiate() as Node2D
	root.add_child(en)
	await process_frame
	_check(en.get_node_or_null("ExitPortal") is Area2D, "ExitPortal Area2D ada")
	_check(en.get_node_or_null("CheckpointZone") is Area2D, "CheckpointZone ada")
	_check(en.get_node_or_null("EmberSpawn1") != null and en.get_node_or_null("EmberSpawn2") != null, "2 EmberSpawn")
	_check(en.get_node_or_null("SkeletonSpawn1") != null, "SkeletonSpawn ada")
	_check(en.get_node_or_null("EliteSpawn1") != null, "EliteSpawn ada")
	_check(en.get_node_or_null("EmberChest") != null, "EmberChest ada")
	en.queue_free()
	await process_frame
	# --- EmberWisp ---
	var wps: PackedScene = load("res://Scenes/Enemies/EmberWisp.tscn") as PackedScene
	_check(wps != null, "EmberWisp.tscn load")
	var w: Node = wps.instantiate()
	var wst: Resource = w.get("stats") as Resource
	_check(wst != null and str(wst.get("enemy_id")) == "ember_wisp", "ember_wisp stats ID")
	w.queue_free()
	# --- portal dua arah via Main ---
	var mps: PackedScene = load("res://Scenes/World/Main.tscn") as PackedScene
	var main: Node2D = mps.instantiate() as Node2D
	root.add_child(main)
	await physics_frame
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "boot valley")
	_check(main.region_manager.current_node.get_node_or_null("EmberPortal") is Area2D, "EmberPortal di valley")
	var player: Node2D = main.get_node("Player") as Node2D
	main._transition_cd = 0.0
	main.travel_to("emberfall_highlands")
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "emberfall_highlands", "valley -> emberfall")
	_check((player.global_position - Vector2(960, 900)).length() < 1.0, "player di checkpoint emberfall")
	_check(main.region_manager.is_discovered("emberfall_highlands"), "emberfall discovered")
	var cam: Camera2D = player.get_node("Camera2D") as Camera2D
	_check(cam.limit_right == 1920 and cam.limit_bottom == 1080, "kamera ikut emberfall 1920x1080")
	_check(main.region_manager.current_node.get_node_or_null("ExitPortal") is Area2D, "ExitPortal di emberfall aktif")
	main._transition_cd = 0.0
	main.travel_to("dawnroot_valley")
	await physics_frame
	await physics_frame
	_check(main.region_manager.current_region_id == "dawnroot_valley", "emberfall -> valley (dua arah)")
	_check((player.global_position - Vector2(640, 300)).length() < 1.0, "kembali di return pos valley")
	main.queue_free()
	print("E3 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
