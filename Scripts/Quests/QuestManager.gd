class_name QuestManager
extends Node
## B3 tracker quest: available/active/completed, chain prereq, reward data.
## Objective HANYA naik dari aksi relevan (cocok type + target_id).
## Serializable via to_dict/from_dict untuk save B5. Tanpa autoload.
## Sinyal B4/B5: quest_updated(quest_id), quest_completed(quest_id).
## B4 pakai notify_enter(dungeon_id) saat player masuki dungeon.
# ponytail: progress Array[int] paralel objectives; upgrade path
# objective Resource bila butuh kondisi kompleks (lokasi/waktu).

signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

const AVAILABLE: String = "available"
const ACTIVE: String = "active"
const COMPLETED: String = "completed"
const LOCKED: String = "locked"

var _defs: Dictionary = {} # quest_id -> QuestDef
var _status: Dictionary = {} # quest_id -> String
var _progress: Dictionary = {} # quest_id -> Array[int]


func setup(defs: Array[QuestDef]) -> void:
	_defs.clear()
	_status.clear()
	_progress.clear()
	for d: QuestDef in defs:
		if d == null or d.quest_id.is_empty():
			continue
		_defs[d.quest_id] = d
	for id: String in _defs.keys():
		if (_defs[id] as QuestDef).prereq_ids.is_empty():
			_status[id] = AVAILABLE
			_progress[id] = _zeros(id)


func status_of(quest_id: String) -> String:
	return str(_status.get(quest_id, LOCKED))


func get_def(quest_id: String) -> QuestDef:
	return _defs.get(quest_id) as QuestDef


func progress_of(quest_id: String) -> Array[int]:
	var p: Array[int] = []
	for n: int in (_progress.get(quest_id, []) as Array):
		p.append(int(n))
	return p


func available_quests() -> Array[QuestDef]:
	var out: Array[QuestDef] = []
	for id: String in _defs.keys():
		if status_of(id) == AVAILABLE:
			out.append(_defs[id] as QuestDef)
	return out


func active_quests() -> Array[QuestDef]:
	var out: Array[QuestDef] = []
	for id: String in _defs.keys():
		if status_of(id) == ACTIVE:
			out.append(_defs[id] as QuestDef)
	return out


func available_from(npc_id: String) -> Array[QuestDef]:
	return active_or_available_from(npc_id, AVAILABLE)


func active_from(npc_id: String) -> Array[QuestDef]:
	return active_or_available_from(npc_id, ACTIVE)


func active_or_available_from(npc_id: String, state: String) -> Array[QuestDef]:
	var out: Array[QuestDef] = []
	for id: String in _defs.keys():
		var d: QuestDef = _defs[id] as QuestDef
		if d.giver_npc_id == npc_id and status_of(id) == state:
			out.append(d)
	return out


func accept(quest_id: String) -> bool:
	if status_of(quest_id) != AVAILABLE or not _defs.has(quest_id):
		return false
	_status[quest_id] = ACTIVE
	_progress[quest_id] = _zeros(quest_id)
	quest_updated.emit(quest_id)
	return true


func notify_talk(npc_id: String) -> void:
	_advance(&"talk", npc_id, 1)


func notify_kill(enemy_id: String) -> void:
	_advance(&"kill", enemy_id, 1)


func notify_kill_elite(enemy_id: String) -> void:
	_advance(&"kill_elite", enemy_id, 1)


func notify_collect(item_id: String, qty: int = 1) -> void:
	if qty > 0:
		_advance(&"collect", item_id, qty)


## B4: panggil saat player masuki dungeon (dungeon_id mis. dawnroot_crypt).
func notify_enter(dungeon_id: String) -> void:
	_advance(&"enter", dungeon_id, 1)


func to_dict() -> Dictionary:
	var prog: Dictionary = {}
	for id: String in _progress.keys():
		prog[id] = (_progress[id] as Array).duplicate()
	return {"status": _status.duplicate(), "progress": prog}


func from_dict(d: Dictionary) -> void:
	var st: Dictionary = d.get("status", {}) as Dictionary
	var pr: Dictionary = d.get("progress", {}) as Dictionary
	for id: String in st.keys():
		if not _defs.has(id):
			continue
		var s: String = str(st[id])
		if s != AVAILABLE and s != ACTIVE and s != COMPLETED:
			continue
		_status[id] = s
		var want: int = (_defs[id] as QuestDef).objectives.size()
		var arr: Array[int] = []
		for n: int in (pr.get(id, []) as Array):
			arr.append(maxi(0, int(n)))
		while arr.size() < want:
			arr.append(0)
		_progress[id] = arr.slice(0, want)
		_clamp_progress(id)


func _advance(obj_type: StringName, target_id: String, qty: int) -> void:
	if target_id.is_empty() or qty <= 0:
		return
	var changed: Array[String] = []
	for id: String in _defs.keys():
		if status_of(id) != ACTIVE:
			continue
		var d: QuestDef = _defs[id] as QuestDef
		var prog: Array = _progress[id] as Array
		var touched: bool = false
		for i: int in d.objectives.size():
			var o: Dictionary = d.objectives[i] as Dictionary
			if str(o.get("type", "")) != str(obj_type):
				continue
			if str(o.get("target_id", "")) != target_id:
				continue
			var need: int = maxi(1, int(o.get("count", 1)))
			var have: int = int(prog[i])
			if have < need:
				prog[i] = mini(need, have + qty)
				touched = true
		if touched:
			changed.append(id)
	for id: String in changed:
		quest_updated.emit(id)
		if _is_done(id):
			_complete(id)


func _is_done(quest_id: String) -> bool:
	var d: QuestDef = _defs[quest_id] as QuestDef
	var prog: Array = _progress[quest_id] as Array
	for i: int in d.objectives.size():
		if int(prog[i]) < maxi(1, int((d.objectives[i] as Dictionary).get("count", 1))):
			return false
	return true


func _complete(quest_id: String) -> void:
	_status[quest_id] = COMPLETED
	quest_completed.emit(quest_id)
	for id: String in _defs.keys():
		if status_of(id) != LOCKED:
			continue
		var d: QuestDef = _defs[id] as QuestDef
		var ok: bool = not d.prereq_ids.is_empty()
		for pre: String in d.prereq_ids:
			if status_of(pre) != COMPLETED:
				ok = false
				break
		if ok:
			_status[id] = AVAILABLE
			_progress[id] = _zeros(id)
			quest_updated.emit(id)


func _zeros(quest_id: String) -> Array[int]:
	var out: Array[int] = []
	for _o: Dictionary in (_defs[quest_id] as QuestDef).objectives:
		out.append(0)
	return out


func _clamp_progress(quest_id: String) -> void:
	var d: QuestDef = _defs[quest_id] as QuestDef
	var prog: Array = _progress[quest_id] as Array
	for i: int in d.objectives.size():
		var need: int = maxi(1, int((d.objectives[i] as Dictionary).get("count", 1)))
		prog[i] = clampi(int(prog[i]), 0, need)
