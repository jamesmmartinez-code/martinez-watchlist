extends Node
# Realm of Eldoria — QuestSystem (autoload singleton)
#
# Central quest manager.  Tracks active and completed quests, advances
# objectives from game events, and distributes rewards on completion.
#
# Registered as autoload "QuestSystem" in project.godot [autoload].
# Access anywhere:
#   QuestSystem.add_quest(QuestData.make("kill_drifters","Hunt the Drifters")
#       .add_kill_objective("drifter", 5)
#       .set_rewards({"xp": 80}))
#
# Hook into game events:
#   QuestSystem.on_enemy_killed("drifter")
#   QuestSystem.on_area_entered("BossArea")
#   QuestSystem.on_item_collected("ancient_relic")

signal quest_added(quest: QuestData)
signal quest_completed(quest: QuestData)
signal quest_failed(quest: QuestData)
signal objective_advanced(quest: QuestData, obj: QuestData.QuestObjective)

# ── Quest stores ──────────────────────────────────────────────────────────
var active_quests:    Dictionary = {}   # id → QuestData
var completed_quests: Dictionary = {}   # id → QuestData
var failed_quests:    Dictionary = {}   # id → QuestData

# ── Player reference (set externally or on_player_ready) ──────────────────
var _player: Node = null

func _ready() -> void:
	# Join the same group Enemy._die() broadcasts to so kill objectives advance
	# automatically whenever any enemy dies — no extra callsites needed.
	add_to_group("quest_listeners")

func set_player(p: Node) -> void:
	_player = p

# ==========================================================================
# Quest management
# ==========================================================================
func add_quest(quest: QuestData) -> void:
	if active_quests.has(quest.id) or completed_quests.has(quest.id):
		return
	active_quests[quest.id] = quest
	emit_signal("quest_added", quest)

func get_quest(id: String) -> QuestData:
	return active_quests.get(id, completed_quests.get(id, null))

func is_active(id: String) -> bool:
	return active_quests.has(id)

func is_completed(id: String) -> bool:
	return completed_quests.has(id)

func complete_quest(id: String) -> void:
	if not active_quests.has(id):
		return
	var quest: QuestData = active_quests[id]
	quest.completed = true
	completed_quests[id] = quest
	active_quests.erase(id)
	_give_rewards(quest.rewards)
	emit_signal("quest_completed", quest)
	# Update map — clear associated objective markers.
	if is_instance_valid(MapSystem):
		MapSystem.clear_objective(id)

func fail_quest(id: String) -> void:
	if not active_quests.has(id):
		return
	var quest: QuestData = active_quests[id]
	quest.failed = true
	failed_quests[id] = quest
	active_quests.erase(id)
	emit_signal("quest_failed", quest)

# ==========================================================================
# Game-event hooks  (call these from wherever the events originate)
# ==========================================================================
func on_enemy_killed(enemy_kind: String) -> void:
	for quest: QuestData in active_quests.values():
		for obj in quest.objectives:
			if obj.type == "kill" and obj.target == enemy_kind and not obj.completed:
				obj.advance(1)
				emit_signal("objective_advanced", quest, obj)
	_check_all_completions()
	# Dynamic quest unlock: check if a new adaptive quest should trigger.
	_check_dynamic_triggers()

func on_area_entered(area_name: String) -> void:
	for quest: QuestData in active_quests.values():
		for obj in quest.objectives:
			if obj.type == "reach" and obj.target == area_name and not obj.completed:
				obj.advance(1)
				emit_signal("objective_advanced", quest, obj)
	_check_all_completions()

func on_item_collected(item_id: String) -> void:
	for quest: QuestData in active_quests.values():
		for obj in quest.objectives:
			if obj.type == "collect" and obj.target == item_id and not obj.completed:
				obj.advance(1)
				emit_signal("objective_advanced", quest, obj)
	_check_all_completions()

# ==========================================================================
# Completion check
# ==========================================================================
func _check_all_completions() -> void:
	# Snapshot keys to avoid modifying dict during iteration.
	var ids := active_quests.keys().duplicate()
	for id in ids:
		var quest: QuestData = active_quests.get(id)
		if quest and quest.all_objectives_done():
			complete_quest(id)

# ==========================================================================
# Dynamic adaptive quests
# ==========================================================================
# Quests with a dynamic_trigger are hidden until the playstyle ratio
# threshold is met.  Called on every kill event (cheap dictionary scan).
var _dynamic_pool: Array[QuestData] = []

func register_dynamic_quest(quest: QuestData) -> void:
	# Adds to the pool without activating it immediately.
	_dynamic_pool.append(quest)

func _check_dynamic_triggers() -> void:
	if not is_instance_valid(GameBrain):
		return
	var remaining: Array[QuestData] = []
	for quest: QuestData in _dynamic_pool:
		var trigger := quest.dynamic_trigger
		if trigger.is_empty():
			add_quest(quest)
		else:
			var ratio := GameBrain.get_playstyle_ratio(trigger.get("key", ""))
			if ratio >= float(trigger.get("min", 1.0)):
				add_quest(quest)
			else:
				remaining.append(quest)
	_dynamic_pool = remaining

# ==========================================================================
# Rewards
# ==========================================================================
func _give_rewards(rewards: Dictionary) -> void:
	if rewards.is_empty() or not _player:
		return
	if rewards.has("xp") and _player.has_method("gain_xp"):
		_player.gain_xp(int(rewards["xp"]))
	if rewards.has("item") and _player.has_method("add_item"):
		_player.add_item(rewards["item"])
	if rewards.has("ability") and _player.has_method("unlock_ability"):
		_player.unlock_ability(rewards["ability"])
	if rewards.has("skill") and is_instance_valid(SkillTree):
		SkillTree.try_unlock(rewards["skill"], _player)
	if rewards.has("evolution") and is_instance_valid(GameBrain):
		GameBrain.set_evolution(rewards["evolution"])

# ==========================================================================
# Built-in quest definitions (Echoing Ruins campaign)
# ==========================================================================
func register_echoing_ruins_quests() -> void:
	# Main story quest.
	add_quest(
		QuestData.make("echoing_ruins_main", "Silence the Echo",
			"Defeat the Echo Knight lurking in the ancient ruins.")
			.add_kill_objective("EchoKnight", 1)
			.set_rewards({"xp": 250, "skill": "air_dash"})
	)

	# Standard combat quests.
	add_quest(
		QuestData.make("drifter_hunt", "Clear the Path",
			"Drifters block the entrance. Drive them back.")
			.add_kill_objective("drifter", 5)
			.set_rewards({"xp": 60})
	)

	add_quest(
		QuestData.make("watcher_silence", "Silence the Watchers",
			"The Watchers' bolts have been harrasing the approach.")
			.add_kill_objective("watcher", 3)
			.set_rewards({"xp": 90})
	)

	# Exploration quest.
	add_quest(
		QuestData.make("reach_boss_chamber", "Find the Echo Chamber",
			"Explore deeper into the ruins to find the boss arena.")
			.add_reach_objective("BossArea")
			.set_rewards({"xp": 40})
	)

	# Dynamic — only triggers for aggressive players.
	register_dynamic_quest(
		QuestData.make("berserker_trial", "The Berserker's Trial",
			"Your aggression has been noticed.  A harder challenge awaits.")
			.add_kill_objective("reactive_scout", 3)
			.set_rewards({"xp": 120, "evolution": "heavy_armor_break"})
			.with_trigger("aggressive", 0.40)
	)

	# Dynamic — only triggers for airborne players.
	register_dynamic_quest(
		QuestData.make("sky_mastery", "Sky Mastery",
			"You fight from the air.  Prove you can do it under pressure.")
			.add_kill_objective("watcher", 5)
			.set_rewards({"xp": 100, "evolution": "fireball_pyro"})
			.with_trigger("airborne", 0.25)
	)

# ==========================================================================
# Procedural quest generation
# ==========================================================================
# Called by NarrativeSystem when notable world events happen.
# Each generator uses a deterministic ID so duplicate quests are silently
# skipped by the existing add_quest() guard.

func generate_from_nemesis(nd: NemesisData) -> void:
	# One active revenge quest per nemesis at a time.
	var id := "revenge_" + nd.nemesis_id
	if is_active(id) or is_completed(id):
		return
	var desc: String
	if nd.killed_player:
		desc = "Take revenge on %s — they have claimed your life." % nd.nemesis_name
	elif nd.escaped:
		desc = "%s escaped your blade. Finish what you started." % nd.nemesis_name
	else:
		desc = "Hunt down %s before they grow stronger." % nd.nemesis_name

	var xp_reward := 80 + nd.level * 40
	add_quest(
		QuestData.make(id, "Nemesis: " + nd.nemesis_name, desc)
			.add_kill_objective(nd.enemy_kind, 1)
			.set_rewards({"xp": xp_reward})
	)

func generate_from_zone_capture(zone_id: String, capturing_faction: String, lost_faction: String) -> void:
	var id := "retake_" + zone_id
	if is_active(id) or is_completed(id):
		return
	# Only generate if the capturing faction is hostile to the player
	if is_instance_valid(FactionSystem) and not FactionSystem.is_hostile("player", capturing_faction):
		return
	var faction_name := capturing_faction.capitalize()
	add_quest(
		QuestData.make(id, "Zone Under Siege",
			"The %s have seized %s. Drive them back." % [faction_name, zone_id.replace("_", " ")])
			.add_kill_objective(FactionSystem.get_faction_for_kind(capturing_faction) \
				if FactionSystem.KIND_TO_FACTION_ID.values().has(capturing_faction) else "drifter", 4)
			.set_rewards({"xp": 70, "rep": {"faction": lost_faction, "amount": 15}})
	)

func generate_from_faction_war(attacker_faction: String, defender_faction: String) -> void:
	var id := "faction_war_" + attacker_faction + "_vs_" + defender_faction
	if is_active(id) or is_completed(id):
		return
	var af := attacker_faction.capitalize()
	var df := defender_faction.capitalize()
	add_quest(
		QuestData.make(id, "Open War",
			"The %s are attacking the %s. Choose a side or seize the chaos." % [af, df])
			.add_kill_objective("drifter", 6)
			.set_rewards({"xp": 110})
	)

func generate_corruption_quest() -> void:
	var id := "purge_corruption_%d" % (int(WorldState.day) if is_instance_valid(WorldState) else 0)
	if is_active(id) or is_completed(id):
		return
	add_quest(
		QuestData.make(id, "Cleanse the Dark",
			"The corruption spreads. Defeat the undead corrupting these lands.")
			.add_kill_objective("skeleton", 5)
			.set_rewards({"xp": 100})
	)

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	var _serialize_quest := func(q: QuestData) -> Dictionary:
		var objs: Array = []
		for obj in q.objectives:
			objs.append({"type": obj.type, "target": obj.target,
			              "required": obj.required, "progress": obj.progress,
			              "completed": obj.completed})
		return {"id": q.id, "completed": q.completed, "objectives": objs}

	var active_data:    Array = []
	var completed_data: Array = []
	for q: QuestData in active_quests.values():
		active_data.append(_serialize_quest.call(q))
	for q: QuestData in completed_quests.values():
		completed_data.append(_serialize_quest.call(q))
	return {"active": active_data, "completed": completed_data}

func load_save_data(data: Dictionary) -> void:
	# Restore progress on objectives of already-registered quests.
	var _apply := func(entries: Array, store: Dictionary) -> void:
		for entry: Dictionary in entries:
			var id: String = entry.get("id", "")
			if not store.has(id):
				continue
			var quest: QuestData = store[id]
			for i in mini(entry["objectives"].size(), quest.objectives.size()):
				var saved = entry["objectives"][i]
				quest.objectives[i].progress  = int(saved.get("progress", 0))
				quest.objectives[i].completed = bool(saved.get("completed", false))
	_apply.call(data.get("active", []),    active_quests)
	_apply.call(data.get("completed", []), completed_quests)
