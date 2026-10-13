extends SceneTree
## D2 headless test: `godot --headless --path . -s Tests/D2_PackTest.gd`
## Uji: tolak unavailable/built-in/tak dikenal; zip-slip ditolak (zip dibuat
## saat uji di user://d2_tmp_*, TIDAK di-commit); sha mismatch ditolak; registry
## roundtrip + corrupt fallback; HTTP URL tak valid -> gagal jaringan jujur
## (bukan PASS palsu); sinyal progress terpancar; panel 6 baris + tombol
## disable beralasan. ponytail: assert manual.
## Catatan jujur: file uji sementara memakai user://d2_tmp_* (bukan /tmp,
## karena /tmp tak ada/tak tulis di Android); tetap tak di-commit.

const TMP_REG: String = "user://d2_tmp_installed.json"
const TMP_DL_REG: String = "user://d2_tmp_installed_dl.json"
const TMP_SLIP_ZIP: String = "user://d2_tmp_slip.zip"
const TMP_SLIP_OUT: String = "user://d2_tmp_slip_out"
const TMP_OK_ZIP: String = "user://d2_tmp_ok.zip"
const TMP_OK_OUT: String = "user://d2_tmp_ok_out"
const TMP_SHA: String = "user://d2_tmp_sha.bin"

var _fail: int = 0


func _initialize() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_fail += 1
		printerr("FAIL: ", label)


func _mkzip(path: String, entries: Dictionary) -> bool:
	var zp := ZIPPacker.new()
	if zp.open(path) != OK:
		return false
	for name: String in entries.keys():
		if zp.start_file(name) != OK:
			zp.close()
			return false
		if zp.write_file((entries[name] as String).to_utf8_buffer()) != OK:
			zp.close()
			return false
		zp.close_file()
	zp.close()
	return true


func _run() -> void:
	# --- 1. Kontrak D1 utuh ---
	var reg := PackRegistry.new()
	_check(reg.load_all() == 6, "registry 6 paket")
	_check(reg.is_built_in("initial"), "initial BUILT_IN")
	for pid: String in ["emberfall", "luminara", "veilwood", "azure", "aether_crown"]:
		_check(not reg.is_available(pid), pid + " tetap UNAVAILABLE")
		var p: PackDef = reg.get_pack(pid)
		_check(p != null and p.file_bytes == -1 and p.download_url.is_empty(), pid + " ukuran -1 + URL kosong (jujur)")
	_check(reg.installed_size("initial") == 298001776, "installed_size initial 298001776 (G1: union +owlish/atmos/impacts-sisa/musik30)") # F3: union +luminara

	# --- 2. Registry roundtrip + corrupt ---
	for f: String in [TMP_REG]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	var ir := InstalledRegistry.new()
	ir.path = TMP_REG
	_check(ir.load(), "registry baru load OK")
	_check(ir.list_installed().is_empty(), "registry baru kosong")
	_check(ir.mark_installed("emberfall", "0.0.1", 12345) == OK, "mark_installed OK")
	var ir2 := InstalledRegistry.new()
	ir2.path = TMP_REG
	_check(ir2.load() and ir2.is_installed("emberfall"), "roundtrip terpasang")
	_check(str(ir2.get_entry("emberfall").get("version", "")) == "0.0.1", "roundtrip versi 0.0.1")
	_check(ir2.remove("emberfall") == OK and not ir2.is_installed("emberfall"), "remove hilang")
	var cf := FileAccess.open(TMP_REG, FileAccess.WRITE)
	cf.store_string("{{{bukan json rusak")
	cf.close()
	var ir3 := InstalledRegistry.new()
	ir3.path = TMP_REG
	_check(not ir3.load(), "corrupt -> load false jujur")
	_check(ir3.list_installed().is_empty() and not ir3.last_error.is_empty(), "corrupt -> reset aman + alasan")

	# --- 3. Unduh DITOLAK jujur ---
	var inst := InstalledRegistry.new()
	inst.path = TMP_DL_REG
	inst.load()
	var dl := PackDownloader.new()
	dl.timeout_sec = 5.0
	root.add_child(dl)
	dl.setup(reg, inst)
	await process_frame
	await process_frame
	var failed: Array = []
	var prog: Array = []
	dl.download_failed.connect(func(pid: String, reason: String) -> void: failed.append([pid, reason]))
	dl.download_progress.connect(func(pid: String, got: int, total: int) -> void: prog.append([pid, got, total]))
	_check(dl.start("emberfall") != OK, "tolak emberfall UNAVAILABLE")
	_check(dl.start("initial") != OK, "tolak initial BUILT_IN")
	_check(dl.start("tak_ada") != OK, "tolak pack_id tak dikenal")
	_check(failed.size() == 3, "3 penolakan pancarkan download_failed (dapat %d)" % failed.size())
	_check(str(failed[0][1]).contains("belum tersedia"), "alasan unavailable jujur: " + str(failed[0][1]))
	_check(str(failed[1][1]).contains("bawaan"), "alasan built-in jujur: " + str(failed[1][1]))
	_check(not dl.is_downloading(), "tak ada unduhan berjalan pasca-tolak")

	# --- 4. Zip-slip ditolak; zip bersih lolos ---
	_check(_mkzip(TMP_SLIP_ZIP, {"ok.txt": "ok", "../evil.txt": "x", "/abs.txt": "x", "sub/../../escape.txt": "x"}), "zip slip uji dibuat di folder uji")
	_check(PackDownloader.is_entry_safe("ok.txt"), "entri normal aman")
	_check(not PackDownloader.is_entry_safe("../evil.txt"), "tolak ../evil.txt")
	_check(not PackDownloader.is_entry_safe("/abs.txt"), "tolak /abs.txt")
	_check(not PackDownloader.is_entry_safe("sub/../../escape.txt"), "tolak traversal dalam")
	var slip_err: String = PackDownloader.extract_zip(TMP_SLIP_ZIP, TMP_SLIP_OUT)
	_check(not slip_err.is_empty() and slip_err.contains("berbahaya"), "ekstrak slip ditolak: " + slip_err)
	_check(not FileAccess.file_exists("user://evil.txt") and not FileAccess.file_exists(TMP_SLIP_OUT + "/ok.txt"), "tak ada file slip tertulis")
	_check(_mkzip(TMP_OK_ZIP, {"data.txt": "halo", "sub/nested.txt": "dalam"}), "zip bersih dibuat di folder uji")
	_check(PackDownloader.extract_zip(TMP_OK_ZIP, TMP_OK_OUT).is_empty(), "zip bersih terekstrak")
	var rf := FileAccess.open(TMP_OK_OUT + "/sub/nested.txt", FileAccess.READ)
	_check(rf != null and rf.get_as_text() == "dalam", "isi nested benar")
	if rf != null:
		rf.close()

	# --- 5. SHA-256 ---
	var sf := FileAccess.open(TMP_SHA, FileAccess.WRITE)
	sf.store_string("halo-mythfall-d2")
	sf.close()
	var real_sha: String = FileAccess.get_sha256(TMP_SHA)
	_check(PackDownloader.verify_sha256(TMP_SHA, real_sha), "sha benar diterima")
	_check(not PackDownloader.verify_sha256(TMP_SHA, "0".repeat(64)), "sha salah ditolak")
	_check(not PackDownloader.verify_sha256(TMP_SHA, ""), "sha kosong ditolak")
	_check(not PackDownloader.verify_sha256("user://d2_tmp_tak_ada.bin", real_sha), "file hilang ditolak")

	# --- 6. HTTP tak valid -> gagal jaringan jujur + progres terpancar ---
	failed.clear()
	prog.clear()
	var net_def := PackDef.new()
	net_def.pack_id = "uji_net"
	net_def.display_name = "Uji Net"
	net_def.status = PackDef.Status.AVAILABLE
	net_def.download_url = "http://127.0.0.1:9/d2-tak-ada.zip"
	net_def.file_bytes = 1024
	net_def.sha256 = "0".repeat(64)
	_check(dl.start_with_def(net_def) == OK, "unduh URL tak valid diterima (lalu gagal jujur)")
	var frames: int = 0
	while failed.is_empty() and frames < 900:
		await process_frame
		frames += 1
	_check(not failed.is_empty(), "gagal jaringan pancarkan download_failed")
	if not failed.is_empty():
		_check(str(failed[0][1]).contains("jaringan") or str(failed[0][1]).contains("terhubung") or str(failed[0][1]).contains("Waktu habis"), "alasan jaringan jujur: " + str(failed[0][1]))
	_check(not prog.is_empty(), "sinyal download_progress terpancar (dapat %d)" % prog.size())
	_check(not inst.is_installed("uji_net"), "gagal unduh tak tercatat terpasang")
	dl.cancel()

	# --- 7. Panel: 6 baris, disable beralasan, kembali ---
	var ps: PackedScene = load("res://Scenes/UI/ContentPacksPanel.tscn") as PackedScene
	_check(ps != null, "ContentPacksPanel.tscn nyata")
	var panel: ContentPacksPanel = ps.instantiate() as ContentPacksPanel
	root.add_child(panel)
	for i: int in 4:
		await process_frame
	var rows: Array[Node] = panel._rows.get_children()
	_check(rows.size() == 6, "panel 6 baris (dapat %d)" % rows.size())
	var disabled_count: int = 0
	for r: Node in rows:
		var btn: Button = (r as HBoxContainer).get_child(1) as Button
		if btn != null and btn.disabled:
			disabled_count += 1
	_check(disabled_count == 6, "6 tombol disable jujur (1 bawaan + 5 unavailable, dapat %d)" % disabled_count)
	_check(panel._status != null and panel._bar != null, "panel punya bar + status")
	panel.queue_free()
	dl.queue_free()

	# --- bersih-bersih user://d2_tmp_* (tak ada dummy di-commit) ---
	for f: String in [TMP_REG, TMP_DL_REG, TMP_SLIP_ZIP, TMP_OK_ZIP, TMP_SHA]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	for f: String in [TMP_OK_OUT + "/data.txt", TMP_OK_OUT + "/sub/nested.txt"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(TMP_OK_OUT + "/sub")
	DirAccess.remove_absolute(TMP_OK_OUT)
	DirAccess.remove_absolute(TMP_SLIP_OUT)

	print("D2 TEST %s fails=%d" % ["FAIL" if _fail > 0 else "OK", _fail])
	quit(_fail)
