extends Node2D
## B4 Main: boot gameplay -> RegionManager load valley, spawn player di
## spawn_pos, kamera limit ikut map, transisi valley<->crypt via Area2D,
## chest sekali-ambil, respawn di checkpoint. API B2/B3 dipertahankan
## (progression/inventory/quest_manager/_spawn_loot/_on_interacted/
## notify_dungeon_entered/_spawn_test_*) agar tes lama tetap hijau.
## Sinyal B5: region_manager.checkpoint_reached/region_discovered.

const MENU_SCENE: String = "res://Scenes/MainMenu/MainMenu.tscn"
const VERSION: String = "v0.5.0-b5"
const SPAWN_POS: Vector2 = Vector2(640, 1150)
const VALLEY_ID: String = "dawnroot_valley"
const CRYPT_ID: String = "dawnroot_crypt"
const EMBERFALL_ID: String = "emberfall_highlands"
const LUMINARA_ID: String = "luminara_desert"
const VALLEY_RETURN_POS: Vector2 = Vector2(640, 300)
const SLIME_SCENE: String = "res://Scenes/Enemies/Slime.tscn"
const SKELETON_SCENE: String = "res://Scenes/Enemies/Skeleton.tscn"
const WISP_SCENE: String = "res://Scenes/Enemies/Wisp.tscn"
const ELITE_SCENE: String = "res://Scenes/Enemies/EliteDawnroot.tscn"
const EMBER_SCENE: String = "res://Scenes/Enemies/EmberWisp.tscn"
const ELDER_SCENE: String = "res://Scenes/NPC/ElderMaren.tscn"
const VILLAGER_SCENE: String = "res://Scenes/NPC/Villager.tscn"
const LOOT_SCENE: String = "res://Scenes/World/LootPickup.tscn"
const ITEM_PATHS: Array[String] = [
	"res://Data/Items/health_potion.tres",
	"res://Data/Items/rusty_sword.tres",
	"res://Data/Items/aether_shard.tres",
	"res://Data/Items/guard_helm.tres",
]
const QUEST_PATHS: Array[String] = [
	"res://Data/Quests/dawnroot_intro.tres",
	"res://Data/Quests/dawnroot_wilds.tres",
	"res://Data/Quests/dawnroot_sealed_dungeon.tres",
]
const REGION_PATHS: Array[String] = [
	"res://Data/Regions/dawnroot_valley.tres",
	"res://Data/Regions/dawnroot_crypt.tres",
	"res://Data/Regions/emberfall_highlands.tres",
	"res://Data/Regions/luminara_desert.tres",
]
## Marker valley/crypt -> scene musuh (legacy EnemySpawn* = slime/skeleton/wisp).
const ENCOUNTER_MAP: Dictionary = {
	"SlimeSpawn": SLIME_SCENE,
	"SkeletonSpawn": SKELETON_SCENE,
	"WispSpawn": WISP_SCENE,
	"EliteSpawn": ELITE_SCENE,
	"EmberSpawn": EMBER_SCENE,
	"EnemySpawn1": SLIME_SCENE,
	"EnemySpawn2": SKELETON_SCENE,
	"EnemySpawn3": WISP_SCENE,
}

var progression: Progression
var inventory: Inventory
var quest_manager: QuestManager
var region_manager: RegionManager
var save_manager: SaveManager
var audio: AudioManager
var ui: GameUI
var vfx: VFX

var _item_db: Dictionary = {}
var _swing_cd: float = 0.0
var _transition_cd: float = 0.0
var _step_t: float = 0.0
var _booted: bool = false
var _opened: Dictionary = {} # region_id -> Array[String] nama chest terbuka
var _last_hp: float = -1.0
var _want_load: bool = false
## Kompat B3: tes lama membaca main._dialog_label.visible.
var _dialog_label: Control

@onready var _player: PlayerUnit = $Player
@onready var _hp: ProgressBar = $HUD/HPBar
@onready var _sp: ProgressBar = $HUD/StaminaBar
@onready var _prompt: Label = $HUD/InteractPrompt
@onready var _region_root: Node2D = $RegionRoot


func _ready() -> void:
	($HUD/VersionLabel as Label).text = "Mythfall %s" % VERSION
	_want_load = get_tree().has_meta("mythfall_load_save") and bool(get_tree().get_meta("mythfall_load_save"))
	get_tree().remove_meta("mythfall_load_save")
	save_manager = SaveManager.new()
	add_child(save_manager)
	audio = AudioManager.new()
	add_child(audio)
	vfx = VFX.new()
	add_child(vfx)
	ui = GameUI.new()
	add_child(ui)
	_hp.max_value = _player.stats.max_hp
	_hp.value = _player.hp
	_sp.max_value = _player.stats.max_stamina
	_sp.value = _player.stamina
	_last_hp = _player.hp
	_player.health_changed.connect(_on_hp)
	_player.stamina_changed.connect(_on_sp)
	_player.died.connect(_on_died)
	progression = Progression.new()
	add_child(progression)
	inventory = Inventory.new()
	add_child(inventory)
	for p: String in ITEM_PATHS:
		var it: ItemDef = load(p) as ItemDef
		if it != null:
			_item_db[it.item_id] = it
	_player.attacked.connect(_on_player_attacked)
	_player.interacted.connect(_on_interacted)
	progression.leveled_up.connect(_on_leveled_up)
	progression.xp_changed.connect(_on_xp_changed)
	quest_manager = QuestManager.new()
	add_child(quest_manager)
	quest_manager.setup(_load_quest_defs())
	quest_manager.quest_updated.connect(_on_quest_updated)
	quest_manager.quest_completed.connect(_on_quest_completed)
	region_manager = $RegionManager as RegionManager
	region_manager.setup(_load_region_defs())
	region_manager.checkpoint_reached.connect(_on_checkpoint_reached)
	ui.bind(self, _player, progression, quest_manager, region_manager, audio)
	ui.build_all()
	_dialog_label = ui.get("_dialog")
	ui.save_requested.connect(save_now)
	ui.settings_changed.connect(_on_settings_changed)
	save_manager.save_failed.connect(_on_save_failed)
	save_manager.load_failed.connect(_on_save_failed)
	_apply_saved_settings()
	travel_to(VALLEY_ID)
	if _want_load:
		_try_continue()


func _process(delta: float) -> void:
	_swing_cd = maxf(0.0, _swing_cd - delta)
	_transition_cd = maxf(0.0, _transition_cd - delta)
	_step_t = maxf(0.0, _step_t - delta)
	var dlg: bool = ui != null and ui.is_dialogue_open()
	_prompt.visible = not _player.is_dead() and _player.has_interact_target() and not dlg
	# ponytail: footstep konkret hangus hanya di Emberfall; upgrade path
	# surface-deteksi bila region bertambah.
	if _booted and region_manager != null and region_manager.current_region_id == EMBERFALL_ID:
		if not _player.is_dead() and _player.velocity.length() > 20.0 and _step_t <= 0.0:
			if audio != null:
				audio.play("footstep_ember")
			_step_t = 0.34


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if ui != null and not ui.is_dialogue_open():
			ui.toggle_pause()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).physical_keycode == KEY_Q:
			if ui != null:
				ui.toggle_questlog()
				get_viewport().set_input_as_handled()


## B4: panggil saat player masuki dungeon (mis. dawnroot_crypt).
func notify_dungeon_entered(dungeon_id: String) -> void:
	if quest_manager != null:
		quest_manager.notify_enter(dungeon_id)


## B4: pindah region (dipicu Area2D entrance/exit atau tes headless).
func travel_to(region_id: String) -> void:
	if _transition_cd > 0.0 and _booted:
		return
	if audio != null and _booted:
		audio.play("door_open")
	_clear_enemies()
	var node: Node2D = region_manager.load_region(region_id, _region_root)
	if node == null:
		push_error("Main: gagal travel ke " + region_id)
		return
	_after_load_region(region_id, node)
	_transition_cd = 1.0
	_booted = true


func _after_load_region(region_id: String, node: Node2D) -> void:
	var def: RegionDef = region_manager.get_def(region_id)
	if def == null:
		return
	if region_id == CRYPT_ID or region_id == EMBERFALL_ID:
		_player.position = def.checkpoint_pos
		region_manager.checkpoint_region = region_id
		region_manager.checkpoint_pos = def.checkpoint_pos
	elif region_id == VALLEY_ID and _booted:
		_player.position = VALLEY_RETURN_POS
	else:
		_player.position = def.spawn_pos
		region_manager.checkpoint_region = region_id
		region_manager.checkpoint_pos = def.checkpoint_pos
	_apply_camera_limits(def)
	_connect_region_signals(node)
	_restore_chests(region_id, node)
	# ponytail: BGM katalog (valley/luminara) vs ambient gua (Emberfall/crypt);
	# valley/desert lain tanpa musik. Anti-overlap di AudioManager.
	if audio != null:
		var bgm: String = MusicCatalog.auto_bgm(region_id)
		if not bgm.is_empty():
			audio.play_music(bgm)
		elif region_id == EMBERFALL_ID or region_id == CRYPT_ID:
			audio.play_ambient("ambient_ember")
		else:
			audio.stop_ambient()
			audio.stop_music()
	var spawned: int = _spawn_region_encounters(node)
	if spawned <= 0:
		_spawn_test_enemies()
	if get_tree().get_nodes_in_group("npc").is_empty():
		_spawn_test_npcs()
	if region_id == CRYPT_ID:
		notify_dungeon_entered("dawnroot_crypt")


func _apply_camera_limits(def: RegionDef) -> void:
	var cam: Camera2D = _player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	cam.limit_left = def.limit_left
	cam.limit_top = def.limit_top
	cam.limit_right = def.limit_right
	cam.limit_bottom = def.limit_bottom


func _connect_region_signals(node: Node2D) -> void:
	if node.has_signal("request_enter_dungeon"):
		if not node.is_connected("request_enter_dungeon", _on_enter_requested):
			node.connect("request_enter_dungeon", _on_enter_requested)
	if node.has_signal("request_exit_to_valley"):
		if not node.is_connected("request_exit_to_valley", _on_exit_requested):
			node.connect("request_exit_to_valley", _on_exit_requested)
	if node.has_signal("checkpoint_touched"):
		if not node.is_connected("checkpoint_touched", _on_checkpoint_touched):
			node.connect("checkpoint_touched", _on_checkpoint_touched)


func _on_enter_requested(dungeon_id: String) -> void:
	# ponytail: deferred karena body_entered jalan saat physics flush;
	# upgrade path transisi fade bila perlu.
	travel_to.call_deferred(dungeon_id)


func _on_exit_requested() -> void:
	travel_to.call_deferred(VALLEY_ID)


func _on_checkpoint_touched(region_id: String, pos: Vector2) -> void:
	region_manager.reach_checkpoint(region_id, pos)


func _on_checkpoint_reached(region_id: String, _pos: Vector2) -> void:
	if audio != null:
		audio.play("door_close")
	save_now(true)


func _spawn_region_encounters(node: Node2D) -> int:
	var count: int = 0
	for m: Node in node.find_children("*", "Marker2D", true, false):
		var marker: Marker2D = m as Marker2D
		if marker == null:
			continue
		var path: String = ""
		for prefix: String in ENCOUNTER_MAP.keys():
			if marker.name.begins_with(prefix):
				path = str(ENCOUNTER_MAP[prefix])
				break
		if path.is_empty():
			continue
		_spawn_enemy_at(path, marker.global_position)
		count += 1
	return count


func _clear_enemies() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemy"):
		var e: EnemyBase = n as EnemyBase
		if e != null:
			e.queue_free()


func _restore_chests(region_id: String, node: Node2D) -> void:
	var done: Array = _opened.get(region_id, [])
	if done.is_empty():
		return
	for n: Node in get_tree().get_nodes_in_group("chest"):
		var c: Chest = n as Chest
		if c != null and node.is_ancestor_of(c) and done.has(c.name):
			c.set_opened_silent()


func _on_hp(hp: float, max_hp: float) -> void:
	_hp.max_value = max_hp
	_hp.value = hp
	if _last_hp > 0.0 and hp < _last_hp - 0.01:
		if audio != null:
			audio.play("hurt")
		if vfx != null:
			vfx.hit_at(_player.global_position)
	_last_hp = hp


func _on_sp(sp: float, max_sp: float) -> void:
	_sp.max_value = max_sp
	_sp.value = sp


func _on_died() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	if not region_manager.checkpoint_pos.is_zero_approx():
		_player.respawn(region_manager.checkpoint_pos)
	else:
		_player.respawn(SPAWN_POS)


func _on_leveled_up(new_level: int) -> void:
	# ponytail: bonus HP datar per level; upgrade path kurva B4+ bila perlu.
	_player.stats.max_hp += 15.0
	_player.hp = minf(_player.stats.max_hp, _player.hp + 30.0)
	if audio != null:
		audio.play("levelup")
	if ui != null:
		ui.refresh_xp()
		ui.refresh_tracker()


func _on_xp_changed(_xp: int, _level: int) -> void:
	if ui != null:
		ui.refresh_xp()


func _spawn_test_enemies() -> void:
	_spawn_enemy(SLIME_SCENE, "EnemySpawn1")
	_spawn_enemy(SKELETON_SCENE, "EnemySpawn2")
	_spawn_enemy(WISP_SCENE, "EnemySpawn3")


func _spawn_enemy(path: String, marker: String) -> void:
	var pos: Vector2 = _player.position
	var offsets: Dictionary = {
		"EnemySpawn1": Vector2(-240, 0),
		"EnemySpawn2": Vector2(240, 0),
		"EnemySpawn3": Vector2(0, 180),
	}
	var m: Node = null
	if is_instance_valid(region_manager.current_node):
		m = region_manager.current_node.find_child(marker, true, false)
	if m == null:
		m = get_node_or_null(marker)
	if m is Marker2D:
		pos = (m as Marker2D).global_position
	elif offsets.has(marker):
		pos = _player.position + (offsets[marker] as Vector2)
	_spawn_enemy_at(path, pos)


func _spawn_enemy_at(path: String, pos: Vector2) -> void:
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		push_error("Main: scene musuh hilang: " + path)
		return
	var e: EnemyBase = ps.instantiate() as EnemyBase
	e.position = pos
	add_child(e)
	e.died.connect(_on_enemy_died)
	if e.health != null:
		e.health.damaged.connect(_on_enemy_damaged.bind(e))


func _on_player_attacked() -> void:
	if _player.is_dead() or _swing_cd > 0.0:
		return
	_swing_cd = _player.stats.attack_cooldown
	if audio != null:
		audio.play("swing")
	var hb := Hitbox.new()
	hb.team = &"player"
	hb.damage = _player.stats.attack_damage + float(progression.attack_bonus())
	hb.knockback = 140.0
	hb.swing_id = randi_range(1, 2147483647)
	hb.add_to_group("player_hitbox")
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _player.stats.attack_range
	cs.shape = circle
	hb.add_child(cs)
	hb.position = _player.global_position + _player.facing * _player.stats.attack_range * 0.7
	add_child(hb)
	hb.monitoring = true
	get_tree().create_timer(0.18).timeout.connect(_free_swing.bind(hb))


func _free_swing(hb: Hitbox) -> void:
	if is_instance_valid(hb):
		hb.queue_free()


func _on_enemy_damaged(amount: float, _current: float, e: EnemyBase) -> void:
	if not is_instance_valid(e):
		return
	if audio != null:
		audio.play("hit")
		# ponytail: denting metal nyata hanya di Emberfall; upgrade path
		# per-enemy hit-sound bila dibutuhkan.
		if region_manager != null and region_manager.current_region_id == EMBERFALL_ID:
			audio.play("hit_metal")
	if vfx != null:
		vfx.hit_at(e.global_position)
		vfx.damage_number(e.global_position, amount)


func _on_enemy_died(e: EnemyBase) -> void:
	if e == null or e.stats == null:
		return
	if audio != null:
		audio.play("die")
	if vfx != null:
		vfx.death_at(e.global_position)
	progression.add_xp(e.stats.xp_reward)
	quest_manager.notify_kill(e.stats.enemy_id)
	quest_manager.notify_kill_elite(e.stats.enemy_id)
	for entry: Dictionary in e.stats.loot_table:
		var item_id: String = str(entry.get("item_id", ""))
		var chance: float = float(entry.get("chance", 0.0))
		if item_id.is_empty() or randf() >= chance:
			continue
		_spawn_loot(item_id, e.global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)), 1)


func _spawn_loot(item_id: String, pos: Vector2, qty: int) -> void:
	var def: ItemDef = _item_db.get(item_id) as ItemDef
	if def == null:
		push_warning("Main: loot item tak dikenal: " + item_id)
		return
	var ps: PackedScene = load(LOOT_SCENE) as PackedScene
	if ps == null:
		push_error("Main: LootPickup.tscn hilang")
		return
	var l: LootPickup = ps.instantiate() as LootPickup
	l.item = def
	l.qty = qty
	l.position = pos
	add_child(l)
	l.picked.connect(_on_loot_picked)


func _on_loot_picked(item_id: String, gained: int) -> void:
	if audio != null:
		audio.play("pickup")
	quest_manager.notify_collect(item_id, gained)
	if ui != null:
		ui.refresh_tracker()


func _load_quest_defs() -> Array[QuestDef]:
	var defs: Array[QuestDef] = []
	for p: String in QUEST_PATHS:
		var d: QuestDef = load(p) as QuestDef
		if d == null:
			push_error("Main: QuestDef hilang: " + p)
			continue
		defs.append(d)
	return defs


func _load_region_defs() -> Array[RegionDef]:
	var defs: Array[RegionDef] = []
	for p: String in REGION_PATHS:
		var d: RegionDef = load(p) as RegionDef
		if d == null:
			push_error("Main: RegionDef hilang: " + p)
			continue
		defs.append(d)
	return defs


func _spawn_test_npcs() -> void:
	_spawn_npc(ELDER_SCENE, Vector2(640, 240))
	_spawn_npc(VILLAGER_SCENE, Vector2(560, 300))
	var sari: NPC = _spawn_npc(VILLAGER_SCENE, Vector2(720, 300))
	if sari != null:
		sari.npc_id = "villager_sari"
		sari.display_name = "Sari"
		var lines: Array[String] = ["Aku menjaga lumbung selagi kakakku Bram di ladang.", "Pecahan Aether berpendar di hutan malam hari.", "Jangan pergi jauh tanpa pamit pada Elder Maren."]
		sari.idle_lines = lines


func _spawn_npc(path: String, pos: Vector2) -> NPC:
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		push_error("Main: scene NPC hilang: " + path)
		return null
	var n: NPC = ps.instantiate() as NPC
	n.position = pos
	add_child(n)
	return n


func _resolve_npc(t: Node) -> NPC:
	if t == null:
		return null
	if t is NPC:
		return t as NPC
	var p: Node = (t as Node).get_parent()
	if p is NPC:
		return p as NPC
	return null


func _resolve_chest(t: Node) -> Chest:
	if t == null:
		return null
	if t is Chest:
		return t as Chest
	var p: Node = (t as Node).get_parent()
	if p is Chest:
		return p as Chest
	if (t as Node).is_in_group("chest"):
		return t as Chest
	return null


func _on_interacted(target: Node2D) -> void:
	var npc: NPC = _resolve_npc(target)
	if npc != null:
		_talk_to(npc)
		return
	var chest: Chest = _resolve_chest(target)
	if chest != null:
		_open_chest(chest)


func _talk_to(npc: NPC) -> void:
	npc.face(_player.global_position)
	var before: Array[QuestDef] = quest_manager.active_or_available_from(npc.npc_id, QuestManager.COMPLETED)
	var accepted: Array[QuestDef] = quest_manager.available_from(npc.npc_id)
	for q: QuestDef in accepted:
		if quest_manager.accept(q.quest_id):
			_show_dialogue(q.accept_lines, q.display_name)
	quest_manager.notify_talk(npc.npc_id)
	var after: Array[QuestDef] = quest_manager.active_or_available_from(npc.npc_id, QuestManager.COMPLETED)
	for q: QuestDef in after:
		if not before.has(q):
			_show_dialogue(q.complete_lines, q.display_name + " — selesai")
			return
	if not accepted.is_empty():
		return
	var act: Array[QuestDef] = quest_manager.active_from(npc.npc_id)
	if not act.is_empty():
		_show_dialogue([_progress_line(act[0])], act[0].display_name)
		return
	_show_dialogue(npc.lines(), npc.display_name)


func _open_chest(chest: Chest) -> void:
	var loot: Array[Dictionary] = chest.open()
	if loot.is_empty():
		_show_dialogue(["Peti ini sudah kosong."], "Peti")
		return
	if audio != null:
		audio.play("chest")
	var region: String = region_manager.current_region_id
	var done: Array = _opened.get(region, [])
	if not done.has(chest.name):
		done.append(chest.name)
	_opened[region] = done
	var names: PackedStringArray = []
	var offsets: Array[Vector2] = [Vector2(24, 0), Vector2(-24, 0), Vector2(0, 24)]
	var i: int = 0
	for entry: Dictionary in loot:
		var item_id: String = str(entry.get("item_id", ""))
		var qty: int = maxi(1, int(entry.get("qty", 1)))
		if item_id.is_empty():
			continue
		names.append("%dx %s" % [qty, item_id])
		_spawn_loot(item_id, chest.global_position + offsets[i % offsets.size()], qty)
		i += 1
	_show_dialogue(["Membuka peti: " + ", ".join(names) + "."], "Peti")


func _progress_line(q: QuestDef) -> String:
	var parts: PackedStringArray = []
	var prog: Array[int] = quest_manager.progress_of(q.quest_id)
	for i: int in q.objectives.size():
		var o: Dictionary = q.objectives[i] as Dictionary
		parts.append("%d/%d %s" % [mini(int(prog[i]), int(o.get("count", 1))), int(o.get("count", 1)), str(o.get("target_id", ""))])
	return "Perkembangan: " + ", ".join(parts) + "."


func _on_quest_updated(quest_id: String) -> void:
	if ui != null:
		ui.refresh_tracker()


func _on_quest_completed(quest_id: String) -> void:
	var q: QuestDef = quest_manager.get_def(quest_id)
	if q == null:
		return
	if audio != null:
		audio.play("quest")
	if ui != null:
		ui.refresh_tracker()
	if q.reward_xp > 0:
		progression.add_xp(q.reward_xp)
	for entry: Dictionary in q.reward_items:
		var item_id: String = str(entry.get("item_id", ""))
		var qty: int = maxi(1, int(entry.get("qty", 1)))
		var def: ItemDef = _item_db.get(item_id) as ItemDef
		if def == null:
			push_warning("Main: reward item tak dikenal: " + item_id)
			continue
		var left: int = inventory.add(def, qty)
		if left > 0:
			_spawn_loot(item_id, _player.global_position + Vector2(24, 0), left)


func _show_dialogue(lines: Array[String], title: String) -> void:
	if ui != null:
		ui.show_dialogue(lines, title)


## B5 save: kumpulkan state penuh; autosave=true saat checkpoint.
func collect_save_data() -> Dictionary:
	var inv: Dictionary = {}
	for id: String in ["health_potion", "rusty_sword", "aether_shard", "guard_helm"]:
		var c: int = inventory.count(id)
		if c > 0:
			inv[id] = c
	return {
		"player": {
			"pos": _player.global_position,
			"level": progression.level,
			"xp": progression.xp,
			"hp": _player.hp,
			"inventory": inv,
		},
		"quest": quest_manager.to_dict(),
		"region": {
			"current": region_manager.current_region_id,
			"discovered": region_manager.discovered.duplicate(),
			"checkpoint_region": region_manager.checkpoint_region,
			"checkpoint_pos": region_manager.checkpoint_pos,
			"opened": _opened.duplicate(true),
		},
		"settings": ui.settings.duplicate() if ui != null else {},
	}


func save_now(autosave: bool = false) -> void:
	if save_manager == null:
		return
	var err: int = save_manager.save_game(collect_save_data())
	if err != OK and ui != null:
		ui.show_error("Gagal menyimpan progres. Ruang penyimpanan penuh?")
	elif not autosave and ui != null:
		ui.show_error("Progres tersimpan.")
		# ponytail: pakai popup error generik untuk konfirmasi hemat file.


func _apply_saved_settings() -> void:
	if save_manager == null or ui == null:
		return
	var s: Dictionary = save_manager.load_settings()
	if not s.is_empty():
		ui.apply_settings(s)
		_apply_settings_side_effects()


func _on_settings_changed(s: Dictionary) -> void:
	_apply_settings_side_effects()
	save_now(true)


func _apply_settings_side_effects() -> void:
	if ui == null:
		return
	var q: String = str(ui.settings.get("quality", "Balanced"))
	if vfx != null:
		vfx.set_quality(q)
	var tc: Node = get_node_or_null("TouchControls")
	if tc != null and tc.get("sensitivity") != null:
		tc.set("sensitivity", float(ui.settings.get("sensitivity", 1.0)))


func _try_continue() -> void:
	var d: Dictionary = save_manager.load_game()
	if d.is_empty():
		if ui != null:
			ui.show_error("Save tidak ditemukan atau rusak. Mulai baru.")
		return
	_apply_save_data(d)


func _apply_save_data(d: Dictionary) -> void:
	var p: Dictionary = d.get("player", {}) as Dictionary
	var pos: Vector2 = Vector2(640, 1150)
	if p.get("pos") is Vector2:
		pos = p["pos"] as Vector2
	elif p.get("pos") is Array:
		var a: Array = p["pos"] as Array
		if a.size() >= 2:
			pos = Vector2(float(a[0]), float(a[1]))
	progression.level = maxi(1, int(p.get("level", 1)))
	progression.xp = maxi(0, int(p.get("xp", 0)))
	inventory.clear()
	var inv: Dictionary = p.get("inventory", {}) as Dictionary
	for id: String in inv.keys():
		var def: ItemDef = _item_db.get(id) as ItemDef
		if def != null:
			inventory.add(def, maxi(1, int(inv[id])))
	quest_manager.from_dict(d.get("quest", {}) as Dictionary)
	var r: Dictionary = d.get("region", {}) as Dictionary
	region_manager.discovered = []
	for id: String in (r.get("discovered", []) as Array):
		region_manager.discovered.append(str(id))
	region_manager.checkpoint_region = str(r.get("checkpoint_region", "dawnroot_valley"))
	var cp: Variant = r.get("checkpoint_pos", Vector2(640, 1150))
	if cp is Vector2:
		region_manager.checkpoint_pos = cp
	elif cp is Array and (cp as Array).size() >= 2:
		region_manager.checkpoint_pos = Vector2(float((cp as Array)[0]), float((cp as Array)[1]))
	_opened = (r.get("opened", {}) as Dictionary).duplicate(true)
	var target: String = str(r.get("current", VALLEY_ID))
	if target.is_empty():
		target = VALLEY_ID
	_transition_cd = 0.0
	travel_to(target)
	_player.global_position = pos
	_player.hp = clampf(float(p.get("hp", _player.stats.max_hp)), 1.0, _player.stats.max_hp)
	_on_hp(_player.hp, _player.stats.max_hp)
	_apply_settings_side_effects()
	if ui != null:
		ui.refresh_xp()
		ui.refresh_tracker()


func _on_save_failed(reason: String) -> void:
	if ui != null:
		ui.show_error(reason)


func quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
