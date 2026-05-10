extends Node
# Realm of Eldoria — SkillTree (autoload singleton)
#
# Data-driven skill registry.  Handles two unlock types:
#
#   Static  — gated by player level + optional skill_points cost + deps.
#             Player calls SkillTree.try_unlock("hp_boost", self) when they
#             spend a point.
#
#   Dynamic — gated by GameBrain playstyle ratios or raw counts.
#             SkillTree.update_dynamic(player) is called every ADAPT_INTERVAL
#             seconds from Player.gd and auto-fires matching unlocks.
#
# Registered as autoload "SkillTree" in project.godot [autoload].
# ─────────────────────────────────────────────────────────────────────────

# Each skill entry is a Dictionary:
# {
#   "name":            String              — display name
#   "description":     String              — tooltip text
#   "level":           int    (opt)        — minimum player level
#   "cost":            int    (opt, def 0) — skill points required
#   "deps":            Array[String] (opt) — skills that must be unlocked first
#   "dynamic":         bool   (opt)        — true = auto-unlocks via GameBrain
#   "ratio_key":       String (dyn)        — GameBrain.get_playstyle_ratio key
#   "ratio_threshold": float  (dyn)        — minimum ratio to auto-unlock
#   "raw_key":         String (dyn)        — GameBrain.get_raw key (raw count)
#   "raw_threshold":   int    (dyn)        — minimum raw count to auto-unlock
#   "effect":          Callable (opt)      — func(player) applied on unlock
#   "slot":            int    (opt)        — ability slot this affects (0-3)
#   "exclusive_with":  Array[String] (opt) — can't coexist with these ids
# }

var _skills: Dictionary = {}    # id → skill dict
var _unlocked: Array[String] = []  # ids that are currently unlocked

signal skill_unlocked(id: String, skill: Dictionary)

# ── Registration ──────────────────────────────────────────────────────────

func register(id: String, data: Dictionary) -> void:
	_skills[id] = data

func register_batch(entries: Dictionary) -> void:
	for id: String in entries:
		register(id, entries[id])

# ── Queries ───────────────────────────────────────────────────────────────

func is_unlocked(id: String) -> bool:
	return id in _unlocked

func can_unlock(id: String, player: Node) -> bool:
	if is_unlocked(id):
		return false
	var sk: Dictionary = _skills.get(id, {})
	if sk.is_empty():
		return false
	# Level gate
	if sk.has("level") and (player.get("level") if "level" in player else 1) < int(sk["level"]):
		return false
	# Dependency check
	for dep: String in sk.get("deps", []):
		if not is_unlocked(dep):
			return false
	# Mutually exclusive
	for exc: String in sk.get("exclusive_with", []):
		if is_unlocked(exc):
			return false
	# Skill point cost
	var cost: int = int(sk.get("cost", 0))
	if cost > 0 and (player.get("skill_points") if "skill_points" in player else 0) < cost:
		return false
	return true

# ── Manual unlock (called by player spending skill points) ────────────────

func try_unlock(id: String, player: Node) -> bool:
	if not can_unlock(id, player):
		return false
	_do_unlock(id, player)
	return true

# ── Dynamic auto-unlock (called from Player._tick_adapt via SkillTree.update_dynamic) ─

func update_dynamic(player: Node) -> void:
	for id: String in _skills:
		if is_unlocked(id):
			continue
		var sk: Dictionary = _skills[id]
		if not sk.get("dynamic", false):
			continue
		if not _meets_dynamic_conditions(sk):
			continue
		_do_unlock(id, player)

func _meets_dynamic_conditions(sk: Dictionary) -> bool:
	# ratio check
	var ratio_key: String = sk.get("ratio_key", "")
	if ratio_key != "":
		var threshold: float = float(sk.get("ratio_threshold", 0.0))
		if GameBrain.get_playstyle_ratio(ratio_key) < threshold:
			return false
	# raw count check
	var raw_key: String = sk.get("raw_key", "")
	if raw_key != "":
		var raw_threshold: int = int(sk.get("raw_threshold", 0))
		if GameBrain.get_raw(raw_key) < raw_threshold:
			return false
	return true

func _do_unlock(id: String, player: Node) -> void:
	if id in _unlocked:
		return
	_unlocked.append(id)
	var sk: Dictionary = _skills[id]
	# Deduct skill points
	var cost: int = int(sk.get("cost", 0))
	if cost > 0 and player and "skill_points" in player:
		player.skill_points = max(0, player.skill_points - cost)
	# Apply effect
	if sk.has("effect") and sk["effect"] is Callable:
		sk["effect"].call(player)
	skill_unlocked.emit(id, sk)

# ── Save / load ───────────────────────────────────────────────────────────

func get_save_data() -> Dictionary:
	return {"unlocked": _unlocked.duplicate()}

func load_save_data(data: Dictionary) -> void:
	# Restore unlocked list WITHOUT re-running effects (they were applied live).
	if data.has("unlocked"):
		_unlocked = Array(data["unlocked"])

# ── Debug ─────────────────────────────────────────────────────────────────

func debug_print() -> void:
	print("── SkillTree ─────────────────────")
	for id: String in _skills:
		var state := "✅" if is_unlocked(id) else "🔒"
		var dyn   := " [dynamic]" if _skills[id].get("dynamic", false) else ""
		print("  %s %s%s" % [state, id, dyn])
	print("─────────────────────────────────")
