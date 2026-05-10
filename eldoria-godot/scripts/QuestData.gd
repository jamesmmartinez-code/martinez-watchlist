extends RefCounted
# Realm of Eldoria — QuestData
# Lightweight data classes used by QuestSystem.
# No signals; QuestSystem owns the state machine.

class_name QuestData

# ── Quest-level fields ─────────────────────────────────────────────────────
var id:          String  = ""
var title:       String  = ""
var description: String  = ""
var completed:   bool    = false
var failed:      bool    = false
var hidden:      bool    = false    # not shown in log until triggered

# Reward bundle applied by QuestSystem on completion.
# Keys: "xp" (int), "item" (String id), "ability" (String id),
#       "skill" (String SkillTree id), "evolution" (String GameBrain key)
var rewards:     Dictionary = {}

# Ordered list of QuestObjective instances.
var objectives:  Array = []

# Optional: restrict quest to a playstyle ratio threshold.
# e.g. { "key": "aggressive", "min": 0.35 }
var dynamic_trigger: Dictionary = {}

# ── Convenience constructors ───────────────────────────────────────────────
static func make(p_id: String, p_title: String, p_desc: String = "") -> QuestData:
	var q       := QuestData.new()
	q.id          = p_id
	q.title       = p_title
	q.description = p_desc
	return q

func add_kill_objective(target: String, required: int = 1) -> QuestData:
	objectives.append(QuestObjective.kill(target, required))
	return self

func add_reach_objective(area: String) -> QuestData:
	objectives.append(QuestObjective.reach(area))
	return self

func add_collect_objective(item_id: String, required: int = 1) -> QuestData:
	objectives.append(QuestObjective.collect(item_id, required))
	return self

func set_rewards(p_rewards: Dictionary) -> QuestData:
	rewards = p_rewards
	return self

func with_trigger(ratio_key: String, min_ratio: float) -> QuestData:
	dynamic_trigger = {"key": ratio_key, "min": min_ratio}
	return self

func all_objectives_done() -> bool:
	for obj in objectives:
		if not obj.completed:
			return false
	return true


# ===========================================================================
# QuestObjective — inner data class
# ===========================================================================
class QuestObjective:
	var type:      String = ""    # "kill" | "reach" | "collect"
	var target:    String = ""    # enemy kind, area name, or item id
	var required:  int    = 1
	var progress:  int    = 0
	var completed: bool   = false
	var label:     String = ""    # display string override

	static func kill(target: String, req: int = 1) -> QuestObjective:
		var o      := QuestObjective.new()
		o.type      = "kill"
		o.target    = target
		o.required  = req
		o.label     = "Defeat %d %s" % [req, target]
		return o

	static func reach(area: String) -> QuestObjective:
		var o   := QuestObjective.new()
		o.type   = "reach"
		o.target = area
		o.label  = "Reach %s" % area
		o.required = 1
		return o

	static func collect(item_id: String, req: int = 1) -> QuestObjective:
		var o      := QuestObjective.new()
		o.type      = "collect"
		o.target    = item_id
		o.required  = req
		o.label     = "Collect %d × %s" % [req, item_id]
		return o

	func advance(amount: int = 1) -> void:
		if completed:
			return
		progress = mini(progress + amount, required)
		if progress >= required:
			completed = true

	func get_display() -> String:
		if label != "":
			return label
		return "%s %s (%d/%d)" % [type, target, progress, required]
