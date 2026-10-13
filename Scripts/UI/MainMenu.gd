extends Control
## B5 MainMenu nyata: New Game, Continue (save valid, disable jujur bila
## tak ada), Settings (volume/sensitivitas/kualitas/skala UI tersimpan),
## Credits nyata (aset CC0 + roadmap jujur), Quit.

const MAIN_SCENE: String = "res://Scenes/World/Main.tscn"
const VERSION: String = "v0.5.0-b5"

var _sm: SaveManager
var _status: Label
var _continue_btn: Button
var _settings_panel: PanelContainer
var _credits_panel: PanelContainer
var _sliders: Dictionary = {}
var _quality: OptionButton


func _ready() -> void:
	_sm = SaveManager.new()
	add_child(_sm)
	_status = $Center/Layout/StatusLabel as Label
	($Center/Layout/VersionLabel as Label).text = VERSION
	($Center/Layout/SubtitleLabel as Label).text = "Vertical slice: Dawnroot Valley (single-player offline)"
	for b: Button in [($Center/Layout/NewGameButton as Button), ($Center/Layout/ContinueButton as Button), ($Center/Layout/SettingsButton as Button), ($Center/Layout/CreditsButton as Button), ($Center/Layout/QuitButton as Button)]:
		b.custom_minimum_size = Vector2(280, 64)
	_continue_btn = $Center/Layout/ContinueButton as Button
	($Center/Layout/NewGameButton as Button).pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)
	($Center/Layout/SettingsButton as Button).pressed.connect(_on_settings)
	($Center/Layout/CreditsButton as Button).pressed.connect(_on_credits)
	($Center/Layout/QuitButton as Button).pressed.connect(_on_quit)
	_build_settings()
	_build_credits()
	_refresh_continue()


func _refresh_continue() -> void:
	var d: Dictionary = _sm.load_game()
	if d.is_empty():
		_continue_btn.disabled = true
		if not _sm.has_save():
			_status.text = "Belum ada save. Mulai New Game."
		else:
			_status.text = "Save rusak/tak valid — mulai baru aman."
	else:
		_continue_btn.disabled = false
		var p: Dictionary = d.get("player", {}) as Dictionary
		_status.text = "Lanjut Lv %d — %s." % [int(p.get("level", 1)), str((d.get("region", {}) as Dictionary).get("current", "dawnroot_valley"))]


func _on_new_game() -> void:
	if get_tree().has_meta("mythfall_load_save"):
		get_tree().remove_meta("mythfall_load_save")
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_continue() -> void:
	if _sm.load_game().is_empty():
		_status.text = "Save tidak valid. Mulai New Game."
		_refresh_continue()
		return
	get_tree().set_meta("mythfall_load_save", true)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_settings() -> void:
	_credits_panel.visible = false
	_settings_panel.visible = not _settings_panel.visible


func _on_credits() -> void:
	_settings_panel.visible = false
	_credits_panel.visible = not _credits_panel.visible


func _on_quit() -> void:
	get_tree().quit()


func _panel(w: float, h: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-w / 2.0, -h / 2.0)
	p.size = Vector2(w, h)
	p.custom_minimum_size = Vector2(w, h)
	p.visible = false
	add_child(p)
	return p


func _slider(vb: VBoxContainer, key: String, label: String, val: float, maxv: float) -> void:
	var row := HBoxContainer.new()
	vb.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(220, 64)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = maxv
	s.value = val
	s.custom_minimum_size = Vector2(280, 64)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	_sliders[key] = s


func _build_settings() -> void:
	_settings_panel = _panel(620, 520)
	var vb := VBoxContainer.new()
	_settings_panel.add_child(vb)
	var t := Label.new()
	t.text = "Pengaturan"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s: Dictionary = _sm.load_settings()
	_slider(vb, "master", "Master", float(s.get("master", 1.0)) * 100.0, 100.0)
	_slider(vb, "music", "Musik", float(s.get("music", 0.8)) * 100.0, 100.0)
	_slider(vb, "sfx", "SFX", float(s.get("sfx", 1.0)) * 100.0, 100.0)
	_slider(vb, "sensitivity", "Sensitivitas", float(s.get("sensitivity", 1.0)) * 100.0, 150.0)
	_quality = OptionButton.new()
	_quality.custom_minimum_size = Vector2(200, 64)
	_quality.add_item("Low", 0)
	_quality.add_item("Balanced", 1)
	_quality.add_item("High", 2)
	_quality.selected = {"Low": 0, "Balanced": 1, "High": 2}.get(str(s.get("quality", "Balanced")), 1)
	var qr := HBoxContainer.new()
	vb.add_child(qr)
	var ql := Label.new()
	ql.text = "Kualitas"
	ql.custom_minimum_size = Vector2(220, 64)
	qr.add_child(ql)
	qr.add_child(_quality)
	_slider(vb, "ui_scale", "Skala UI", float(s.get("ui_scale", 1.0)) * 100.0, 120.0)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var ok := Button.new()
	ok.text = "Simpan"
	ok.custom_minimum_size = Vector2(140, 64)
	ok.pressed.connect(_on_settings_save)
	row.add_child(ok)
	var packs := Button.new()
	packs.text = "Paket Konten"
	packs.custom_minimum_size = Vector2(170, 64)
	packs.pressed.connect(_on_packs)
	row.add_child(packs)
	var back := Button.new()
	back.text = "Kembali"
	back.custom_minimum_size = Vector2(140, 64)
	back.pressed.connect(func() -> void: _settings_panel.visible = false)
	row.add_child(back)


func _on_packs() -> void:
	_settings_panel.visible = false
	ContentPacksPanel.open_in(self)


func _on_settings_save() -> void:
	_sm.store_settings({
		"master": (_sliders["master"] as HSlider).value / 100.0,
		"music": (_sliders["music"] as HSlider).value / 100.0,
		"sfx": (_sliders["sfx"] as HSlider).value / 100.0,
		"sensitivity": (_sliders["sensitivity"] as HSlider).value / 100.0,
		"quality": _quality.get_item_text(_quality.selected),
		"ui_scale": (_sliders["ui_scale"] as HSlider).value / 100.0,
	})
	_status.text = "Pengaturan tersimpan."
	_settings_panel.visible = false


func _build_credits() -> void:
	_credits_panel = _panel(700, 480)
	var vb := VBoxContainer.new()
	_credits_panel.add_child(vb)
	var t := Label.new()
	t.text = "Credits"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(660, 340)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.text = "Mythfall: Echoes of Aether — vertical slice Dawnroot Valley.\n\nAset CC0 oleh Kenney (kenney.nl): Roguelike RPG Pack, Tiny Town, Roguelike Characters, Fantasy UI Borders, RPG Audio.\nLihat ASSET_CREDITS.md + LICENSES/ untuk lisensi.\n\nMusik ambient: BELUM tersedia (Preview.ogg hanya demo, tak dipakai).\nSFX jatuh: drawKnife/knifeSlice/cloth/chop/handleCoins/book/door/metalClick.\n\nGameplay lanjutan (Emberfall dkk): roadmap, bukan klaim selesai."
	vb.add_child(body)
	var back := Button.new()
	back.text = "Kembali"
	back.custom_minimum_size = Vector2(140, 64)
	back.pressed.connect(func() -> void: _credits_panel.visible = false)
	vb.add_child(back)
