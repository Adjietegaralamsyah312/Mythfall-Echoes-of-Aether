class_name GameUI
extends CanvasLayer
## B5 panel final: XP/level, cooldown, tracker minimizable, minimap 200px,
## QuestLog, DialoguePanel, PauseMenu, SettingsPanel, error popup jujur.
## Dibangun via kode (tanpa .tscn rapuh); Bahasa Indonesia; tombol 64px+.
## ponytail: 1 file untuk semua panel; upgrade path pisah .tscn bila
## desainer butuh layout visual.

signal save_requested
signal settings_changed(settings: Dictionary)

class Minimap extends Control:
	var player_pos: Vector2 = Vector2.ZERO
	var bounds: Rect2 = Rect2(0, 0, 2560, 1440)
	var npcs: Array[Vector2] = []
	var objective: Vector2 = Vector2.ZERO
	var has_objective: bool = false
	var discovered_here: bool = true
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.09, 0.85))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.3), false, 2.0)
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			return
		var sc: Vector2 = size / bounds.size
		var pp: Vector2 = (player_pos - bounds.position) * sc
		draw_circle(pp.clamp(Vector2.ZERO, size), 5.0, Color.WHITE)
		for n: Vector2 in npcs:
			draw_circle(((n - bounds.position) * sc).clamp(Vector2.ZERO, size), 3.5, Color(0.4, 1.0, 0.5))
		if has_objective:
			var op: Vector2 = ((objective - bounds.position) * sc).clamp(Vector2.ZERO, size)
			draw_circle(op, 5.0, Color(1.0, 0.85, 0.3))
			draw_arc(op, 8.0, 0.0, TAU, 12, Color(1.0, 0.85, 0.3), 2.0)

var main: Node = null
var player: PlayerUnit = null
var progression: Progression = null
var quest_manager: QuestManager = null
var region_manager: RegionManager = null
var audio: AudioManager = null

var settings: Dictionary = {
	"master": 1.0, "music": 0.8, "sfx": 1.0,
	"sensitivity": 1.0, "quality": "Balanced", "ui_scale": 1.0,
}

var _root: Control
var _level_label: Label
var _xp_bar: ProgressBar
var _cd_bar: ProgressBar
var _cd_label: Label
var _tracker: PanelContainer
var _tracker_text: Label
var _tracker_min: Button
var _tracker_body: VBoxContainer
var _tracker_mini: bool = false
var _minimap: Minimap
var _map_toggle: Button
var _toolbar_q: Button
var _toolbar_p: Button
var _toolbar_m: Button
var _music_panel: PanelContainer
var _music_now: Label
var _music_list: VBoxContainer
var _questlog: PanelContainer
var _quest_list: Label
var _dialog: PanelContainer
var _dialog_title: Label
var _dialog_text: Label
var _dialog_next: Button
var _dialog_close: Button
var _dialog_lines: Array[String] = []
var _dialog_idx: int = 0
var _pause: PanelContainer
var _settings_panel: PanelContainer
var _error: PanelContainer
var _error_text: Label
var _s_master: HSlider
var _s_music: HSlider
var _s_sfx: HSlider
var _s_sens: HSlider
var _s_quality: OptionButton
var _s_scale: HSlider
var _map_t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20


func bind(m: Node, p: PlayerUnit, pr: Progression, qm: QuestManager, rm: RegionManager, au: AudioManager) -> void:
	main = m
	player = p
	progression = pr
	quest_manager = qm
	region_manager = rm
	audio = au


func build_all() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_stats()
	_build_tracker()
	_build_minimap()
	_build_toolbar()
	_build_questlog()
	_build_dialog()
	_build_pause()
	_build_settings()
	_build_music()
	_build_error()
	apply_settings(settings)


func _mkbtn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(96, 64)
	b.focus_mode = Control.FOCUS_ALL
	return b


func _build_stats() -> void:
	_level_label = Label.new()
	_level_label.position = Vector2(16, 82)
	_level_label.size = Vector2(280, 24)
	_level_label.text = "Lv 1"
	_root.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.position = Vector2(16, 106)
	_xp_bar.size = Vector2(280, 14)
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 100.0
	_root.add_child(_xp_bar)
	_cd_bar = ProgressBar.new()
	_cd_bar.position = Vector2(16, 124)
	_cd_bar.size = Vector2(280, 10)
	_cd_bar.show_percentage = false
	_cd_bar.max_value = 1.0
	_cd_bar.value = 1.0
	# Warna cooldown: hijau=ready, kuning=charging, merah=cooldown
	_cd_bar.add_theme_color_override("fill", Color(0.3, 0.85, 0.4))
	_cd_bar.add_theme_color_override("background", Color(0.05, 0.05, 0.1, 0.7))
	_root.add_child(_cd_bar)
	# Label cooldown singkat
	_cd_label = Label.new()
	_cd_label.position = Vector2(16, 134)
	_cd_label.size = Vector2(280, 16)
	_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cd_label.add_theme_font_size_override("font_size", 12)
	_cd_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_cd_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_cd_label.add_theme_constant_override("outline_size", 2)
	_cd_label.text = ""
	_root.add_child(_cd_label)


func _build_tracker() -> void:
	_tracker = PanelContainer.new()
	_tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tracker.position = Vector2(-376, 84)
	_tracker.size = Vector2(360, 110)
	_tracker.custom_minimum_size = Vector2(360, 64)
	var vb := VBoxContainer.new()
	_tracker.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := Label.new()
	title.text = "Quest Aktif"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_tracker_min = Button.new()
	_tracker_min.text = "-"
	_tracker_min.custom_minimum_size = Vector2(64, 64)
	_tracker_min.focus_mode = Control.FOCUS_ALL
	_tracker_min.pressed.connect(_on_tracker_min)
	top.add_child(_tracker_min)
	_tracker_body = VBoxContainer.new()
	vb.add_child(_tracker_body)
	_tracker_text = Label.new()
	_tracker_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tracker_text.custom_minimum_size = Vector2(330, 48)
	_tracker_text.text = "Tidak ada quest aktif."
	_tracker_body.add_child(_tracker_text)
	_root.add_child(_tracker)


func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-216, 210)
	_minimap.size = Vector2(200, 200)
	_minimap.custom_minimum_size = Vector2(200, 200)
	_root.add_child(_minimap)
	_map_toggle = Button.new()
	_map_toggle.text = "Peta"
	_map_toggle.custom_minimum_size = Vector2(96, 64)
	_map_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_map_toggle.position = Vector2(-216, 414)
	_map_toggle.pressed.connect(_on_map_toggle)
	_root.add_child(_map_toggle)


func _build_toolbar() -> void:
	# ponytail: bar tengah-atas (bukan x absolut) agar tetap di tengah
	# pada layar lebar/expand; container IGNORE agar tak menelan klik dunia.
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.position = Vector2(-168, 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_constant_override("separation", 16)
	_root.add_child(bar)
	_toolbar_q = _mkbtn("Quest")
	_toolbar_q.pressed.connect(toggle_questlog)
	bar.add_child(_toolbar_q)
	_toolbar_p = _mkbtn("Jeda")
	_toolbar_p.pressed.connect(toggle_pause)
	bar.add_child(_toolbar_p)
	_toolbar_m = _mkbtn("Musik")
	_toolbar_m.pressed.connect(toggle_music)
	bar.add_child(_toolbar_m)


func _panel_center(w: float, h: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-w / 2.0, -h / 2.0)
	p.size = Vector2(w, h)
	p.custom_minimum_size = Vector2(w, h)
	p.visible = false
	_root.add_child(p)
	return p


func _build_questlog() -> void:
	_questlog = _panel_center(700, 440)
	var vb := VBoxContainer.new()
	_questlog.add_child(vb)
	var t := Label.new()
	t.text = "Quest Log"
	vb.add_child(t)
	_quest_list = Label.new()
	_quest_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_list.custom_minimum_size = Vector2(660, 300)
	_quest_list.text = "Memuat..."
	_quest_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_quest_list)
	var c: Button = _mkbtn("Tutup")
	c.pressed.connect(toggle_questlog)
	vb.add_child(c)


func _build_dialog() -> void:
	_dialog = PanelContainer.new()
	_dialog.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_dialog.position = Vector2(-400, -220)
	_dialog.size = Vector2(800, 190)
	_dialog.custom_minimum_size = Vector2(800, 190)
	_dialog.visible = false
	_root.add_child(_dialog)
	var vb := VBoxContainer.new()
	_dialog.add_child(vb)
	_dialog_title = Label.new()
	_dialog_title.text = "NPC"
	vb.add_child(_dialog_title)
	_dialog_text = Label.new()
	_dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_text.custom_minimum_size = Vector2(760, 70)
	_dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_dialog_text)
	var row := HBoxContainer.new()
	vb.add_child(row)
	_dialog_next = _mkbtn("Lanjut")
	_dialog_next.pressed.connect(next_dialog)
	row.add_child(_dialog_next)
	_dialog_close = _mkbtn("Tutup")
	_dialog_close.pressed.connect(close_dialog)
	row.add_child(_dialog_close)


func _build_pause() -> void:
	_pause = _panel_center(420, 430)
	var vb := VBoxContainer.new()
	_pause.add_child(vb)
	var t := Label.new()
	t.text = "Jeda"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var r: Button = _mkbtn("Lanjutkan")
	r.pressed.connect(toggle_pause)
	vb.add_child(r)
	var s: Button = _mkbtn("Pengaturan")
	s.pressed.connect(toggle_settings)
	vb.add_child(s)
	var sv: Button = _mkbtn("Simpan")
	sv.pressed.connect(func() -> void: save_requested.emit())
	vb.add_child(sv)
	var q: Button = _mkbtn("Menu Utama")
	q.pressed.connect(_on_quit)
	vb.add_child(q)


func _build_settings() -> void:
	_settings_panel = _panel_center(560, 500)
	var vb := VBoxContainer.new()
	_settings_panel.add_child(vb)
	var t := Label.new()
	t.text = "Pengaturan"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_s_master = _mk_slider(vb, "Master", 100.0)
	_s_music = _mk_slider(vb, "Musik", 80.0)
	_s_sfx = _mk_slider(vb, "SFX", 100.0)
	_s_sens = _mk_slider(vb, "Sensitivitas", 100.0)
	_s_quality = OptionButton.new()
	_s_quality.custom_minimum_size = Vector2(200, 64)
	_s_quality.add_item("Low", 0)
	_s_quality.add_item("Balanced", 1)
	_s_quality.add_item("High", 2)
	_s_quality.selected = 1
	var qr := HBoxContainer.new()
	vb.add_child(qr)
	var ql := Label.new()
	ql.text = "Kualitas"
	ql.custom_minimum_size = Vector2(200, 64)
	qr.add_child(ql)
	qr.add_child(_s_quality)
	_s_scale = _mk_slider(vb, "Skala UI", 100.0)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var ok: Button = _mkbtn("Simpan")
	ok.pressed.connect(_on_settings_save)
	row.add_child(ok)
	var packs: Button = _mkbtn("Paket Konten")
	packs.custom_minimum_size = Vector2(170, 64)
	packs.pressed.connect(_open_packs)
	row.add_child(packs)
	var back: Button = _mkbtn("Kembali")
	back.pressed.connect(toggle_settings)
	row.add_child(back)


func _mk_slider(vb: VBoxContainer, label: String, val: float) -> HSlider:
	var row := HBoxContainer.new()
	vb.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(200, 64)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 150.0 if label == "Sensitivitas" else 120.0 if label == "Skala UI" else 100.0
	s.value = val
	s.custom_minimum_size = Vector2(280, 64)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	return s


func _build_music() -> void:
	_music_panel = _panel_center(560, 560)
	var vb := VBoxContainer.new()
	_music_panel.add_child(vb)
	var t := Label.new()
	t.text = "Soundtrack (CC0)"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_music_now = Label.new()
	_music_now.text = "Tidak ada musik."
	_music_now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_music_now)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(520, 340)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sc)
	_music_list = VBoxContainer.new()
	_music_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_music_list)
	for tr: Dictionary in MusicCatalog.TRACKS:
		var b := Button.new()
		b.text = "%s [%s]" % [str(tr.get("title", "")), str(tr.get("category", ""))]
		b.custom_minimum_size = Vector2(460, 64)
		b.focus_mode = Control.FOCUS_ALL
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tid: String = str(tr.get("id", ""))
		b.pressed.connect(_on_music_pick.bind(tid))
		_music_list.add_child(b)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var stop := _mkbtn("Stop")
	stop.pressed.connect(_on_music_stop)
	row.add_child(stop)
	var c: Button = _mkbtn("Tutup")
	c.pressed.connect(toggle_music)
	row.add_child(c)


func toggle_music() -> void:
	_click()
	_music_panel.visible = not _music_panel.visible
	if _music_panel.visible:
		_refresh_music_now()


func _refresh_music_now() -> void:
	if audio != null and audio.is_music_playing():
		var t: Dictionary = MusicCatalog.get_track(audio.current_music_id())
		_music_now.text = "Main: %s (%s, CC0 %s)" % [str(t.get("title", "?")), str(t.get("category", "")), str(t.get("creator", ""))]
	elif audio != null and audio.is_ambient_playing():
		_music_now.text = "Main: Ambient gua (Emberfall/crypt)."
	else:
		_music_now.text = "Tidak ada musik."


func _on_music_pick(track_id: String) -> void:
	if audio != null:
		audio.play_music(track_id)
	_refresh_music_now()


func _on_music_stop() -> void:
	if audio != null:
		audio.stop_music()
	_refresh_music_now()


func _build_error() -> void:
	_error = _panel_center(480, 220)
	var vb := VBoxContainer.new()
	_error.add_child(vb)
	_error_text = Label.new()
	_error_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_text.custom_minimum_size = Vector2(440, 110)
	vb.add_child(_error_text)
	var ok: Button = _mkbtn("OK")
	ok.pressed.connect(func() -> void: _error.visible = false)
	vb.add_child(ok)


func show_error(msg: String) -> void:
	_error_text.text = msg
	_error.visible = true


func _on_tracker_min() -> void:
	_tracker_mini = not _tracker_mini
	_tracker_body.visible = not _tracker_mini
	_tracker_min.text = "+" if _tracker_mini else "-"
	_click()


func _on_map_toggle() -> void:
	_minimap.visible = not _minimap.visible
	_click()


func _on_quit() -> void:
	get_tree().paused = false
	_pause.visible = false
	if main != null and main.has_method("quit_to_menu"):
		main.quit_to_menu()


func _on_settings_save() -> void:
	settings["master"] = _s_master.value / 100.0
	settings["music"] = _s_music.value / 100.0
	settings["sfx"] = _s_sfx.value / 100.0
	settings["sensitivity"] = _s_sens.value / 100.0
	settings["ui_scale"] = _s_scale.value / 100.0
	var q: String = _s_quality.get_item_text(_s_quality.selected)
	settings["quality"] = q
	apply_settings(settings)
	settings_changed.emit(settings)
	_click()
	_settings_panel.visible = false
	if _pause.visible:
		pass


func apply_settings(s: Dictionary) -> void:
	for k: String in settings.keys():
		if s.has(k):
			settings[k] = s[k]
	_s_master.value = float(settings["master"]) * 100.0
	_s_music.value = float(settings["music"]) * 100.0
	_s_sfx.value = float(settings["sfx"]) * 100.0
	_s_sens.value = float(settings["sensitivity"]) * 100.0
	_s_scale.value = float(settings["ui_scale"]) * 100.0
	for i: int in _s_quality.item_count:
		if _s_quality.get_item_text(i) == str(settings["quality"]):
			_s_quality.selected = i
	_root.scale = Vector2.ONE * float(settings["ui_scale"])

	## F-D: Text readability - minimum skala UI 0.8 agar teks tetap terbaca.
	## (VFX quality diatur Main via _apply_settings_side_effects, bukan di sini.)
	var scale: float = float(settings["ui_scale"])
	var min_scale: float = 0.8
	if scale < min_scale:
		settings["ui_scale"] = min_scale
		_root.scale = Vector2.ONE * min_scale
		_s_scale.value = min_scale * 100.0

	if audio != null:
		audio.apply_volumes(float(settings["master"]), float(settings["music"]), float(settings["sfx"]))


func toggle_questlog() -> void:
	_click()
	_questlog.visible = not _questlog.visible
	if _questlog.visible:
		refresh_questlog()


func toggle_pause() -> void:
	_click()
	var want: bool = not _pause.visible
	_pause.visible = want
	get_tree().paused = want
	if not want and _settings_panel.visible:
		_settings_panel.visible = false


func toggle_settings() -> void:
	_click()
	_settings_panel.visible = not _settings_panel.visible


## D2: buka panel Paket Konten di atas overlay (tanpa rombak UI lain).
func _open_packs() -> void:
	_click()
	ContentPacksPanel.open_in(_root)


func is_dialogue_open() -> bool:
	return _dialog.visible


func show_dialogue(lines: Array[String], title: String) -> void:
	_dialog_lines = lines.duplicate()
	_dialog_idx = 0
	_dialog_title.text = title
	_dialog.visible = not _dialog_lines.is_empty()
	_refresh_dialog()


func next_dialog() -> void:
	_click()
	_dialog_idx += 1
	if _dialog_idx >= _dialog_lines.size():
		close_dialog()
		return
	_refresh_dialog()


func close_dialog() -> void:
	_click()
	_dialog.visible = false
	_dialog_lines.clear()
	_dialog_idx = 0


func _refresh_dialog() -> void:
	if _dialog_idx < _dialog_lines.size():
		_dialog_text.text = _dialog_lines[_dialog_idx]
	_dialog_next.disabled = false


func refresh_xp() -> void:
	if progression == null:
		return
	_level_label.text = "Lv %d" % progression.level
	_xp_bar.max_value = float(maxi(1, progression.xp_needed(progression.level)))
	_xp_bar.value = float(progression.xp)


func set_cooldown(frac: float) -> void:
	frac = clampf(frac, 0.0, 1.0)
	_cd_bar.value = frac
	if frac >= 1.0:
		_cd_label.text = "Serangan: SIAP"
		_cd_bar.add_theme_color_override("fill", Color(0.3, 0.85, 0.4))
	elif frac > 0.5:
		var cd_val: float = ceil((1.0 - frac) * (player.stats.attack_cooldown if player.stats != null else 0.45) * 10.0) / 10.0
		_cd_label.text = "Serangan: %ds" % cd_val
		_cd_bar.add_theme_color_override("fill", Color(1.0, 0.8, 0.3))
	else:
		var cd_val: float = ceil((1.0 - frac) * (player.stats.attack_cooldown if player.stats != null else 0.45) * 10.0) / 10.0
		_cd_label.text = "Serangan: %ds" % cd_val
		_cd_bar.add_theme_color_override("fill", Color(1.0, 0.4, 0.3))


func refresh_tracker() -> void:
	if quest_manager == null:
		return
	var act: Array[QuestDef] = quest_manager.active_quests()
	if act.is_empty():
		_tracker_text.text = "Tidak ada quest aktif. Bicara dengan Elder Maren."
		return
	var q: QuestDef = act[0]
	var prog: Array[int] = quest_manager.progress_of(q.quest_id)
	var parts: PackedStringArray = []
	for i: int in q.objectives.size():
		var o: Dictionary = q.objectives[i] as Dictionary
		parts.append("%d/%d %s" % [mini(int(prog[i]), int(o.get("count", 1))), int(o.get("count", 1)), str(o.get("target_id", ""))])
	_tracker_text.text = "%s\n%s" % [q.display_name, ", ".join(parts)]


func refresh_questlog() -> void:
	if quest_manager == null:
		_quest_list.text = "Gagal memuat quest."
		return
	var lines: PackedStringArray = []
	for group: String in [QuestManager.AVAILABLE, QuestManager.ACTIVE, QuestManager.COMPLETED]:
		lines.append("== %s ==" % {"available": "Tersedia", "active": "Aktif", "completed": "Selesai"}.get(group, group))
		var any: bool = false
		for id: String in ["dawnroot_intro", "dawnroot_wilds", "dawnroot_sealed_dungeon"]:
			if quest_manager.status_of(id) != group:
				continue
			var d: QuestDef = quest_manager.get_def(id)
			if d == null:
				continue
			any = true
			var prog: Array[int] = quest_manager.progress_of(id)
			var parts: PackedStringArray = []
			for i: int in d.objectives.size():
				var o: Dictionary = d.objectives[i] as Dictionary
				parts.append("%d/%d %s" % [int(prog[i]), int(o.get("count", 1)), str(o.get("target_id", ""))])
			lines.append("- %s: %s" % [d.display_name, ", ".join(parts)])
		if not any:
			lines.append("(kosong)")
		lines.append("")
	_quest_list.text = "\n".join(lines)


func _process(delta: float) -> void:
	_map_t -= delta
	if _map_t <= 0.0:
		_map_t = 0.25
		_update_minimap()
	if player != null and main != null and main.get("_swing_cd") != null:
		var cd: float = float(main.get("_swing_cd"))
		var total: float = player.stats.attack_cooldown if player.stats != null else 0.45
		set_cooldown(1.0 - clampf(cd / maxf(0.01, total), 0.0, 1.0))


func _update_minimap() -> void:
	if not is_instance_valid(_minimap) or not _minimap.visible:
		return
	if player != null:
		_minimap.player_pos = player.global_position
	if region_manager != null:
		var def: RegionDef = region_manager.get_def(region_manager.current_region_id)
		if def != null:
			_minimap.bounds = Rect2(def.limit_left, def.limit_top, def.limit_right - def.limit_left, def.limit_bottom - def.limit_top)
	var pts: Array[Vector2] = []
	for n: Node in get_tree().get_nodes_in_group("npc"):
		var c: Node2D = n as Node2D
		if c != null:
			pts.append(c.global_position)
	_minimap.npcs = pts
	_minimap.has_objective = false
	if quest_manager != null:
		var act: Array[QuestDef] = quest_manager.active_quests()
		if not act.is_empty():
			var target: Node2D = null
			for n: Node in get_tree().get_nodes_in_group("enemy"):
				target = n as Node2D
				break
			if target == null:
				for n: Node in get_tree().get_nodes_in_group("chest"):
					var c2: Chest = n as Chest
					if c2 != null and not c2.is_opened():
						target = c2
						break
			if target != null:
				_minimap.objective = target.global_position
				_minimap.has_objective = true
	_minimap.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _dialog.visible and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		next_dialog()
		get_viewport().set_input_as_handled()


func _click() -> void:
	if audio != null:
		audio.play("ui")
