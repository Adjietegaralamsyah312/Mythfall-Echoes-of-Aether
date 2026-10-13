class_name ContentPacksPanel
extends PanelContainer
## D2 panel daftar 6 paket: nama, status, ukuran butuh/terpasang, tombol
## Unduh per paket AVAILABLE (disable + alasan jujur untuk BUILT_IN /
## UNAVAILABLE), progress bar + pesan error jujur, tombol kembali.
## Dibangun via kode (ikut pola GameUI); Bahasa Indonesia; tombol >=64px.
# ponytail: 1 file + .tscn tipis; upgrade path .tscn penuh bila desainer perlu.

signal closed

const PANEL_SCENE: String = "res://Scenes/UI/ContentPacksPanel.tscn"

var registry: PackRegistry
var installed: InstalledRegistry
var downloader: PackDownloader

var _rows: VBoxContainer
var _bar: ProgressBar
var _status: Label


static func open_in(parent: Node) -> ContentPacksPanel:
	var ps: PackedScene = load(PANEL_SCENE) as PackedScene
	if ps == null:
		return null
	var p: ContentPacksPanel = ps.instantiate() as ContentPacksPanel
	parent.add_child(p)
	p.closed.connect(func() -> void: p.queue_free())
	return p


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	registry = PackRegistry.new()
	registry.load_all()
	installed = InstalledRegistry.new()
	installed.load()
	downloader = PackDownloader.new()
	add_child(downloader)
	downloader.setup(registry, installed)
	downloader.download_progress.connect(_on_progress)
	downloader.download_finished.connect(_on_finished)
	downloader.download_failed.connect(_on_failed)
	_build()
	_refresh_rows()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	var title := Label.new()
	title.text = "Paket Konten"
	vb.add_child(title)
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(600, 48)
	info.text = "Paket tambahan dipilih manual — tak ada unduh otomatis. Paket bawaan sudah termasuk; paket ekspansi belum ada konten."
	vb.add_child(info)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(600, 24)
	_bar.show_percentage = true
	_bar.max_value = 100.0
	_bar.value = 0.0
	vb.add_child(_bar)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(600, 64)
	_status.text = "Pilih paket untuk mengunduh."
	vb.add_child(_status)
	var back := Button.new()
	back.text = "Kembali"
	back.custom_minimum_size = Vector2(200, 64)
	back.focus_mode = Control.FOCUS_ALL
	back.pressed.connect(func() -> void: closed.emit())
	vb.add_child(back)


func _refresh_rows() -> void:
	for c: Node in _rows.get_children():
		c.queue_free()
	await get_tree().process_frame
	if not is_instance_valid(_rows):
		return
	for p: PackDef in registry.list_packs():
		_rows.add_child(_row_for(p))


func _row_for(p: PackDef) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_l := Label.new()
	name_l.text = p.display_name
	info.add_child(name_l)
	var det := Label.new()
	det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	det.custom_minimum_size = Vector2(380, 64)
	det.text = _detail_text(p)
	info.add_child(det)
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 64)
	b.focus_mode = Control.FOCUS_ALL
	if registry.is_built_in(p.pack_id):
		b.text = "Bawaan"
		b.disabled = true
	elif not registry.is_available(p.pack_id):
		b.text = "Unduh"
		b.disabled = true
	else:
		b.text = "Unduh • " + PackDownloader.format_bytes(p.file_bytes)
		b.disabled = installed.is_installed(p.pack_id) and downloader != null and not downloader.is_downloading()
		var pid: String = p.pack_id
		b.pressed.connect(func() -> void: _on_download(pid))
	row.add_child(b)
	return row


func _detail_text(p: PackDef) -> String:
	var st: String = "Bawaan" if registry.is_built_in(p.pack_id) else ("Tersedia" if registry.is_available(p.pack_id) else "Belum tersedia")
	var parts: PackedStringArray = [st, "Butuh: " + PackDownloader.format_bytes(p.file_bytes)]
	if installed.is_installed(p.pack_id):
		var e: Dictionary = installed.get_entry(p.pack_id)
		parts.append("Terpasang ✓ v%s" % str(e.get("version", "?")))
	elif registry.is_built_in(p.pack_id):
		parts.append("Terpasang: " + PackDownloader.format_bytes(p.installed_bytes) + " (bawaan)")
	else:
		parts.append("Belum terpasang")
	if registry.is_built_in(p.pack_id):
		parts.append("Sudah termasuk instalasi.")
	elif not registry.is_available(p.pack_id):
		parts.append("Konten belum ada.")
	return " • ".join(parts)


func _on_download(pid: String) -> void:
	_status.text = "Memulai unduhan %s…" % pid
	_bar.value = 0.0
	downloader.start(pid)


func _on_progress(pid: String, got: int, total: int) -> void:
	_bar.max_value = float(maxi(1, total))
	_bar.value = float(got)
	var pct: int = int(100.0 * float(got) / float(maxi(1, total)))
	_status.text = "Mengunduh %s… %d%% (%s / %s)." % [pid, pct, PackDownloader.format_bytes(got), PackDownloader.format_bytes(total)]


func _on_finished(pid: String) -> void:
	_bar.value = _bar.max_value
	_status.text = "Selesai: %s terpasang." % pid
	_refresh_rows()


func _on_failed(pid: String, reason: String) -> void:
	var who: String = "" if pid.is_empty() else " (" + pid + ")"
	_status.text = "Gagal%s: %s" % [who, reason]
	_refresh_rows()
