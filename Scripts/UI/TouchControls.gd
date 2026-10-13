extends CanvasLayer
## B1 TouchControls: joystick kiri + tombol kanan, emit ke Input action sama
## (move_*, attack, dodge, skill, interact, pause). Keyboard/joypad tetap jalan.
## ponytail: Button biasa + StyleBoxFlat (tanpa TouchScreenButton/texture);
## upgrade path TouchScreenButton bila butuh shape sentuh presisi.

const JOY_CENTER: Vector2 = Vector2(120, 120)
const JOY_RADIUS: float = 100.0
const JOY_DEADZONE: float = 0.2
const KNOB_HALF: float = 42.0
const HL: Color = Color(0.75, 0.95, 1.0, 1.0)

var _joy_value: Vector2 = Vector2.ZERO
var _joy_touch: int = -1
var _joy_mouse: bool = false
var _touch_seen: bool = false
var _force_show: bool = false
var _force_hide: bool = false
## B5 sensitivitas joystick (0.5-1.5) dari SettingsPanel.
var sensitivity: float = 1.0

@onready var _ui: Control = $TouchUI
@onready var _joy: Control = $TouchUI/JoystickBase
@onready var _knob: Panel = $TouchUI/JoystickBase/Knob
@onready var _toggle: Button = $TouchToggle


func _ready() -> void:
	_toggle.pressed.connect(_on_toggle)
	_joy.gui_input.connect(_on_joy_gui)
	_bind_btn("TouchUI/ButtonsRight/AttackButton", "attack")
	_bind_btn("TouchUI/ButtonsRight/DodgeButton", "dodge")
	_bind_btn("TouchUI/ButtonsRight/SkillButton", "skill")
	_bind_btn("TouchUI/ButtonsRight/InteractButton", "interact")
	_bind_btn("TouchUI/ButtonsRight/PauseButton", "pause")
	_update_visibility()


func _process(_delta: float) -> void:
	if not _ui.visible:
		return
	_feed_move("move_left", maxf(0.0, -_joy_value.x))
	_feed_move("move_right", maxf(0.0, _joy_value.x))
	_feed_move("move_up", maxf(0.0, -_joy_value.y))
	_feed_move("move_down", maxf(0.0, _joy_value.y))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_touch_seen = true
		_update_visibility()
		var st: InputEventScreenTouch = event
		if st.pressed:
			_try_grab(st.index, st.position)
		elif st.index == _joy_touch:
			_joy_reset()
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		if sd.index == _joy_touch:
			_joy_update(_to_local(sd.position))
	elif event is InputEventMouseMotion and _joy_mouse:
		_joy_update(_to_local((event as InputEventMouseMotion).position))
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and _joy_mouse:
			_joy_reset()


func _on_joy_gui(event: InputEvent) -> void:
	# gui_input: event.position sudah koordinat lokal kontrol.
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_joy_touch = st.index
			_joy_update(st.position)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_joy_mouse = true
			_joy_update(mb.position)


func _on_toggle() -> void:
	if _ui.visible:
		_force_hide = true
		_force_show = false
	else:
		_force_show = true
		_force_hide = false
	_update_visibility()


func _bind_btn(path: NodePath, action: StringName) -> void:
	var b: Button = get_node(path) as Button
	b.button_down.connect(_press.bind(action))
	b.button_up.connect(_release.bind(action))
	b.button_down.connect(_fx.bind(b, true))
	b.button_up.connect(_fx.bind(b, false))


func _fx(b: Button, down: bool) -> void:
	b.modulate = HL if down else Color.WHITE


func _press(action: StringName) -> void:
	Input.action_press(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)


func _release(action: StringName) -> void:
	Input.action_release(action)
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _feed_move(action: StringName, strength: float) -> void:
	if strength > 0.02:
		Input.action_press(action, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(action)


func _try_grab(index: int, viewport_pos: Vector2) -> void:
	if _joy_touch == -1 and _joy.get_global_rect().has_point(viewport_pos):
		_joy_touch = index
		_joy_update(_to_local(viewport_pos))


func _to_local(viewport_pos: Vector2) -> Vector2:
	return _joy.get_global_transform().affine_inverse() * viewport_pos


func _joy_update(local: Vector2) -> void:
	var off: Vector2 = local - JOY_CENTER
	if off.length() > JOY_RADIUS:
		off = off.normalized() * JOY_RADIUS
	if off.length() < JOY_DEADZONE * JOY_RADIUS:
		_joy_value = Vector2.ZERO
		_knob.position = JOY_CENTER - Vector2(KNOB_HALF, KNOB_HALF)
		return
	_joy_value = (off / JOY_RADIUS * sensitivity).limit_length(1.0)
	_knob.position = JOY_CENTER + off - Vector2(KNOB_HALF, KNOB_HALF)


func _joy_reset() -> void:
	_joy_value = Vector2.ZERO
	_joy_touch = -1
	_joy_mouse = false
	_knob.position = JOY_CENTER - Vector2(KNOB_HALF, KNOB_HALF)


func _update_visibility() -> void:
	var base: bool = DisplayServer.is_touchscreen_available() or _touch_seen
	var show: bool = _force_show or (base and not _force_hide)
	# ponytail: default ikut base (hemat satu state); toggle manual untuk uji Termux.
	if not _force_show and not _force_hide:
		show = base
	_ui.visible = show
	_toggle.text = "Touch: ON" if show else "Touch: OFF"
	if not show:
		_joy_reset()
		_feed_move("move_left", 0.0)
		_feed_move("move_right", 0.0)
		_feed_move("move_up", 0.0)
		_feed_move("move_down", 0.0)
