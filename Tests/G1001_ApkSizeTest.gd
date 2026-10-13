extends SceneTree
## G1-001 headless: `godot --headless --path . -s Tests/G1001_ApkSizeTest.gd`
## Uji ringan (tanpa preload 242 audio): katalog musik 30 + SFX 242 + mapping
## konteks + lazy play 1 SFX/1 musik + manifest 27 + size gate + tak-yatim.
# ponytail: assert manual; upgrade path GUT bila suite membesar.

const TARGET: int = 100_000_000
const EXP_INITIAL: int = 298001776
const EXP_EMBER: int = 1337985
const EXP_LUMINARA: int = 1672604
const TOL: int = 65536

var _fail: int = 0


func _initialize() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_fail += 1
		printerr("FAIL: ", label)


func _exists_disk(p: String) -> bool:
	var disk: String = p.replace("res://", "./")
	return FileAccess.file_exists(disk) or DirAccess.dir_exists_absolute(disk)


func _run() -> void:
	# --- musik: 30 trek, ID unik, file nyata, CC0 ---
	_check(MusicCatalog.TRACKS.size() == 30, "musik 30 trek (dapat %d)" % MusicCatalog.TRACKS.size())
	var mids: Dictionary = {}
	var mfiles: Dictionary = {}
	for t: Dictionary in MusicCatalog.TRACKS:
		var tid: String = str(t.get("id", ""))
		_check(not tid.is_empty() and not mids.has(tid), "musik ID unik: " + tid)
		mids[tid] = true
		var fp: String = MusicCatalog.file_for(tid)
		_check(not fp.is_empty() and _exists_disk(fp), "musik file nyata: " + tid)
		mfiles[fp] = true
		_check(str(t.get("license", "")) == "CC0", "musik CC0: " + tid)
	_check(MusicCatalog.auto_bgm("menu") == "wandering_woodlands", "auto menu tetap")
	_check(MusicCatalog.auto_bgm("dawnroot_valley") == "back_to_nature", "auto valley tetap")
	_check(MusicCatalog.auto_bgm("luminara_desert") == "homestead", "auto luminara tetap")
	_check(MusicCatalog.auto_bgm("emberfall_highlands").is_empty(), "ember tetap ambient")
	for nid: String in ["glizzy_forest", "grizzly_battle", "grizzly_victory", "magic_mush", "fantasy_orchestral", "future_ambient_1", "chillstep_1", "hiphop_noir"]:
		_check(mids.has(nid), "musik G1 ada: " + nid)
	_check(MusicCatalog.tracks_for_use("combat").size() >= 5, "combat >= 5")
	_check(MusicCatalog.tracks_for_use("optional").size() >= 8, "optional >= 8")
	_check(MusicCatalog.tracks_for_use("loot").size() >= 3, "loot >= 3")
	# --- SFX: 242 entri, ID unik, file nyata ---
	_check(SfxCatalog.ENTRIES.size() == 242, "sfx 242 entri (dapat %d)" % SfxCatalog.ENTRIES.size())
	var sids: Dictionary = {}
	var sfiles: Dictionary = {}
	for e: Dictionary in SfxCatalog.ENTRIES:
		var sid: String = str(e.get("id", ""))
		_check(not sid.is_empty() and not sids.has(sid), "sfx ID unik: " + sid)
		sids[sid] = true
		var sp2: String = SfxCatalog.path_for(sid)
		_check(not sp2.is_empty() and _exists_disk(sp2), "sfx file nyata: " + sid)
		sfiles[sp2] = true
	for ctx: String in ["menu", "explore", "combat", "boss", "loot", "chest", "quest", "valley", "skill", "damage"]:
		_check(SfxCatalog.ids_for_use(ctx).size() > 0, "konteks SFX ada: " + ctx)
	_check(SfxCatalog.ids_for_use("tak_ada_ctx").is_empty(), "konteks tak dikenal kosong")
	_check(SfxCatalog.path_for("tak_ada_id").is_empty(), "SFX tak dikenal kosong")
	# --- AudioManager lazy: 1 SFX + 1 musik (tanpa preload semua) ---
	var am := AudioManager.new()
	root.add_child(am)
	await process_frame
	am.play("owl_ui_001")
	await process_frame
	am.play_music("glizzy_forest")
	_check(am.is_music_playing() and am.current_music_id() == "glizzy_forest", "lazy play musik G1")
	am.stop_music()
	_check(not am.is_music_playing(), "stop musik G1")
	am.play_music("tak_ada_id")
	_check(not am.is_music_playing(), "musik tak dikenal aman")
	# --- manifest 27 item ---
	var mtxt: String = FileAccess.get_file_as_string("./ASSET_MANIFEST.json")
	var mj: Dictionary = JSON.parse_string(mtxt) as Dictionary
	_check(not mj.is_empty() and (mj.get("assets", []) as Array).size() == 27, "manifest 27 item")
	# --- size gate via registry ---
	var reg := PackRegistry.new()
	_check(reg.load_all() == 6, "registry 6 paket")
	var ini: PackDef = reg.get_pack("initial")
	_check(ini != null and ini.installed_bytes >= TARGET, "size gate initial %d >= %d" % [ini.installed_bytes, TARGET])
	_check(absi(ini.installed_bytes - EXP_INITIAL) <= TOL, "initial %d ~= hitung %d" % [ini.installed_bytes, EXP_INITIAL])
	var em: PackDef = reg.get_pack("emberfall")
	_check(em != null and absi(em.installed_bytes - EXP_EMBER) <= TOL, "emberfall %d ~= %d" % [em.installed_bytes, EXP_EMBER])
	var lu: PackDef = reg.get_pack("luminara")
	_check(lu != null and absi(lu.installed_bytes - EXP_LUMINARA) <= TOL, "luminara %d ~= %d" % [lu.installed_bytes, EXP_LUMINARA])
	_check(not reg.is_available("emberfall") and not reg.is_available("luminara"), "pack tetap UNAVAILABLE")
	# --- tak-yatim: tiap file audio baru ada di katalog ---
	for d: String in ["./Assets/Audio/Owlish", "./Assets/Audio/Atmospheric"]:
		for dp: String in [d]:
			for sub: String in DirAccess.get_directories_at(dp):
				for fn: String in DirAccess.get_files_at(dp + "/" + sub):
					if fn.ends_with(".import") or fn.ends_with(".uid"):
						continue
					_check(sfiles.has("res://Assets/Audio/" + dp.get_file() + "/" + sub + "/" + fn) or sfiles.has("res://Assets/Audio/Owlish/" + sub + "/" + fn) or sfiles.has("res://Assets/Audio/Atmospheric/" + sub + "/" + fn), "tak yatim owlish/atmos: " + sub + "/" + fn)
	for fn2: String in DirAccess.get_files_at("./Assets/Audio/Impacts"):
		if fn2.ends_with(".import") or fn2.ends_with(".uid") or not fn2.ends_with(".ogg"):
			continue
		var rp: String = "res://Assets/Audio/Impacts/" + fn2
		var in_sfx: bool = sfiles.has(rp)
		var in_map: bool = (fn2 in ["footstep_concrete_000.ogg", "footstep_concrete_001.ogg", "footstep_concrete_002.ogg", "impactMetal_heavy_000.ogg", "impactMetal_heavy_001.ogg", "impactMining_000.ogg", "impactMining_001.ogg", "impactPunch_heavy_000.ogg"])
		_check(in_sfx or in_map, "tak yatim impacts: " + fn2)
	for fn3: String in DirAccess.get_files_at("./Assets/Audio/MusicLibrary"):
		if fn3.ends_with(".import") or fn3.ends_with(".uid"):
			continue
		_check(mfiles.has("res://Assets/Audio/MusicLibrary/" + fn3), "tak yatim musik: " + fn3)
	am.queue_free()
	print("G1001 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
