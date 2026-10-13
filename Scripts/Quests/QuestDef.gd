class_name QuestDef
extends Resource
## B3 definisi quest (kontrak B4/B5: quest_id stabil).
## objectives: Array[Dictionary] [{type, target_id, count}],
##   type: talk/kill/collect/enter/kill_elite.
## reward_items: Array[Dictionary] [{item_id, qty}].
## Dialogue Bahasa Indonesia inline (accept/complete); idle NPC di NPC.
# ponytail: Resource flat tanpa DialogueDef terpisah; upgrade path
# Data/Dialogue/*.tres bila dialog bercabang/bersyarat dibutuhkan.

@export var quest_id: String = ""
@export var display_name: String = ""
@export var giver_npc_id: String = ""
@export var prereq_ids: Array[String] = []
@export var objectives: Array[Dictionary] = []
@export var reward_xp: int = 0
@export var reward_items: Array[Dictionary] = []
@export var accept_lines: Array[String] = []
@export var complete_lines: Array[String] = []
