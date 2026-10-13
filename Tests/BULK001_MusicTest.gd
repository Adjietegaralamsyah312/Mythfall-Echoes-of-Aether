extends SceneTree
## BULK-001 headless: `godot --headless --path . -s Tests/BULK001_MusicTest.gd`
## Uji: katalog 16 ID unik + file nyata + CC0; auto-BGM mapping;
## play/stop/no-overlap AudioManager; manifest 21 item; size gate ≥100M;
## dekor Scorched/DesertDebris di scene; MusicLibrary tanpa yatim;
## panel Musik GameUI (16 tombol + pilih + stop).
# ponytail: assert manual; upgrade path GUT bila suite membesar.

const TOL: int = 16384
const TARGET: int = 100_000_000
const EXP_INITIAL: int = 127584207
const EXP_EMBER: int = 329853
const EXP_LUMINARA: int = 1672604

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
	# --- katalog: 16 trek, ID unik, file nyata, CC0 ---
	_check(MusicCatalog.TRACKS.size() == 16, "katalog 16 trek (dapat %d)" % MusicCatalog.TRACKS.size())
	var ids: Dictionary = {}
	var files: Dictionary = {}
	for t: Dictionary in MusicCatalog.TRACKS:
		var tid: String = str(t.get("id", ""))
		_check(not tid.is_empty() and not ids.has(tid), "ID unik tak kosong: " + tid)
		ids[tid] = true
		var fp: String = MusicCatalog.file_for(tid)
		_check(not fp.is_empty() and _exists_res(fp), "file nyata: " + tid + " -> " + fp)
		files[fp] = true
		_check(str(t.get("license", "")) == "CC0", "lisensi CC0: " + tid)
		_check(not str(t.get("source", "")).is_empty(), "sumber tercatat: " + tid)
	# --- auto-BGM: hanya yg cocok; ember/crypt = ambient (kosong di sini) ---
	_check(MusicCatalog.auto_bgm("menu") == "wandering_woodlands", "auto menu")
	_check(MusicCatalog.auto_bgm("dawnroot_valley") == "back_to_nature", "auto valley")
	_check(MusicCatalog.auto_bgm("luminara_desert") == "homestead", "auto luminara")
	_check(MusicCatalog.auto_bgm("emberfall_highlands").is_empty(), "emberfall tanpa auto-BGM (ambient)")
	_check(MusicCatalog.auto_bgm("dawnroot_crypt").is_empty(), "crypt tanpa auto-BGM (ambient)")
	_check(MusicCatalog.tracks_for_use("combat").size() >= 3, "combat opsional >= 3")
	_check(MusicCatalog.tracks_for_use("optional").size() >= 3, "chiptune opsional >= 3")
	_check(MusicCatalog.file_for("tak_ada_id").is_empty(), "ID tak dikenal -> path kosong")
	# --- AudioManager: play/stop/anti-overlap (satu sistem) ---
	var am := AudioManager.new()
	root.add_child(am)
	await process_frame
	am.play_music("back_to_nature")
	_check(am.is_music_playing() and am.current_music_id() == "back_to_nature", "play_music valley")
	am.play_music("back_to_nature")
	_check(am.is_music_playing() and am.current_music_id() == "back_to_nature", "play sama = no-op")
	am.play_ambient("ambient_ember")
	_check(not am.is_music_playing() and am.is_ambient_playing(), "ambient hentikan musik (anti-overlap)")
	am.play_music("homestead")
	_check(am.is_music_playing() and not am.is_ambient_playing(), "musik hentikan ambient (anti-overlap)")
	am.stop_music()
	_check(not am.is_music_playing() and am.current_music_id().is_empty(), "stop_music")
	am.play_music("tak_ada_id")
	_check(not am.is_music_playing(), "ID tak dikenal aman (tak main)")
	# --- manifest 21 item + entri BULK ---
	var mtxt: String = FileAccess.get_file_as_string("./ASSET_MANIFEST.json")
	var mj: Dictionary = JSON.parse_string(mtxt) as Dictionary
	_check(not mj.is_empty() and (mj.get("assets", []) as Array).size() == 21, "manifest 21 item")
	var mpaths: Array = []
	for a: Variant in (mj.get("assets", []) as Array):
		mpaths.append(str((a as Dictionary).get("path", "")))
	for fp2: String in ["Assets/Audio/MusicLibrary/Action_A.wav", "Assets/Audio/MusicLibrary/Battle.wav", "Assets/Audio/MusicLibrary/Horror.wav", "Assets/Audio/MusicLibrary/chiptune_1B2.wav", "Assets/Audio/MusicLibrary/chiptune_2.wav", "Assets/Audio/MusicLibrary (fantasy-song-pack-v1, 8 MP3)", "Assets/Environment/Scorched + DesertDebris (tiny-rpg-forest subset)"]:
		_check(mpaths.has(fp2), "manifest ada BULK: " + fp2)
	# --- size gate ≥100M via registry ---
	var reg := PackRegistry.new()
	_check(reg.load_all() == 6, "registry 6 paket")
	var ini: PackDef = reg.get_pack("initial")
	_check(ini != null and ini.installed_bytes >= TARGET, "size gate initial %d >= %d" % [ini.installed_bytes, TARGET])
	_check(absi(ini.installed_bytes - EXP_INITIAL) <= TOL, "initial %d ~= hitung %d" % [ini.installed_bytes, EXP_INITIAL])
	var em: PackDef = reg.get_pack("emberfall")
	_check(em != null and em.contents.size() == 11, "emberfall 11 contents (dapat %d)" % em.contents.size())
	_check(absi(em.installed_bytes - EXP_EMBER) <= TOL, "emberfall %d ~= hitung %d" % [em.installed_bytes, EXP_EMBER])
	_check(em.contents.has("res://Assets/Environment/Scorched"), "emberfall contents ada Scorched")
	var lu: PackDef = reg.get_pack("luminara")
	_check(lu != null and lu.contents.size() == 7, "luminara 7 contents (dapat %d)" % lu.contents.size())
	_check(absi(lu.installed_bytes - EXP_LUMINARA) <= TOL, "luminara %d ~= hitung %d" % [lu.installed_bytes, EXP_LUMINARA])
	_check(lu.contents.has("res://Assets/Environment/DesertDebris"), "luminara contents ada DesertDebris")
	_check(not reg.is_available("emberfall") and not reg.is_available("luminara"), "pack tetap UNAVAILABLE (tanpa hosting)")
	# --- tanpa yatim: tiap file MusicLibrary ada di katalog ---
	var libdir: String = "./Assets/Audio/MusicLibrary"
	for fn: String in DirAccess.get_files_at(libdir):
		if fn.ends_with(".import") or fn.ends_with(".uid"):
			continue
		_check(files.has("res://Assets/Audio/MusicLibrary/" + fn), "tak yatim: " + fn)
	# --- dekor visual di scene nyata ---
	var eps: PackedScene = load("res://Scenes/World/EmberfallHighlands.tscn") as PackedScene
	_check(eps != null, "EmberfallHighlands.tscn load")
	var en: Node2D = eps.instantiate() as Node2D
	root.add_child(en)
	await process_frame
	_check(en.get_node_or_null("ScorchedTree1") is Sprite2D, "ScorchedTree1 di Emberfall")
	_check(en.get_node_or_null("ScorchedMonument") is Sprite2D, "ScorchedMonument di Emberfall")
	en.queue_free()
	await process_frame
	var lps: PackedScene = load("res://Scenes/World/LuminaraDesert.tscn") as PackedScene
	_check(lps != null, "LuminaraDesert.tscn load")
	var ln: Node2D = lps.instantiate() as Node2D
	root.add_child(ln)
	await process_frame
	_check(ln.get_node_or_null("DesertTrunk1") is Sprite2D, "DesertTrunk1 di Luminara")
	_check(ln.get_node_or_null("DesertRock1") is Sprite2D, "DesertRock1 di Luminara")
	ln.queue_free()
	await process_frame
	# --- panel Musik GameUI: 16 tombol + pilih + stop ---
	var ui := GameUI.new()
	root.add_child(ui)
	ui.audio = am
	ui.build_all()
	var panel: PanelContainer = ui.get("_music_panel") as PanelContainer
	_check(panel != null, "panel Musik ada")
	var lst: VBoxContainer = ui.get("_music_list") as VBoxContainer
	_check(lst != null and lst.get_child_count() == 16, "16 tombol trek (dapat %d)" % (lst.get_child_count() if lst != null else -1))
	ui.toggle_music()
	_check(panel.visible, "panel Musik tampil via toggle")
	ui._on_music_pick("battle")
	_check(am.is_music_playing() and am.current_music_id() == "battle", "pilih trek via UI main")
	ui._on_music_stop()
	_check(not am.is_music_playing(), "stop via UI")
	ui.queue_free()
	am.queue_free()
	print("BULK001 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
