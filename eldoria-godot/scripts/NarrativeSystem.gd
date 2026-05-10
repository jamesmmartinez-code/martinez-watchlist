extends Node
# Realm of Eldoria — NarrativeSystem (autoload singleton)
#
# Connects every system into a coherent story without coupling them directly.
# Any system can call NarrativeSystem.record_event("type", data) and the
# narrative layer decides what world/quest/faction responses to trigger.
#
# Registered as autoload "NarrativeSystem" in project.godot [autoload].
#
# ── Supported event types ─────────────────────────────────────────────────────
#   "enemy_killed"     — data: {faction, kind, [nemesis]}
#   "player_died"      — data: {attacker}
#   "nemesis_formed"   — data: {nemesis: NemesisData}
#   "nemesis_escaped"  — data: {nemesis: NemesisData}
#   "nemesis_defeated" — data: {nemesis: NemesisData}
#   "zone_captured"    — data: {zone_id, faction, old_faction}
#   "leader_killed"    — data: {faction, [nemesis]}
#   "used_dark_power"  — data: {}
#   "faction_war"      — data: {attacker_faction, defender_faction}
#   "corruption_spike" — data: {level}
#
# ── Design rule ──────────────────────────────────────────────────────────────
# NarrativeSystem READS from other autoloads; it does NOT own data.
# Ownership: nemeses → NemesisSystem, quests → QuestSystem, world → WorldState.

# ==========================================================================
# State
# ==========================================================================
const EVENT_LOG_MAX: int = 200

var event_log: Array = []   # Array of {type, data, day} dicts

# ==========================================================================
# Signals
# ==========================================================================
signal event_recorded(type: String, data: Dictionary)

# ==========================================================================
# Core API
# ==========================================================================
func record_event(type: String, data: Dictionary = {}) -> void:
	var entry := {
		"type": type,
		"data": data,
		"day":  int(WorldState.day) if is_instance_valid(WorldState) else 0,
	}
	event_log.append(entry)
	if event_log.size() > EVENT_LOG_MAX:
		event_log.pop_front()

	emit_signal("event_recorded", type, data)
	_process_event(entry)

func get_events_of_type(type: String) -> Array:
	var out: Array = []
	for e in event_log:
		if e["type"] == type:
			out.append(e)
	return out

func event_count(type: String) -> int:
	return get_events_of_type(type).size()

# ==========================================================================
# Event → world consequence
# ==========================================================================
func _process_event(e: Dictionary) -> void:
	match e["type"]:
		"enemy_killed":
			_on_enemy_killed(e["data"])
		"player_died":
			_on_player_died(e["data"])
		"nemesis_formed":
			_on_nemesis_formed(e["data"])
		"nemesis_escaped":
			_on_nemesis_escaped(e["data"])
		"nemesis_defeated":
			_on_nemesis_defeated(e["data"])
		"zone_captured":
			_on_zone_captured(e["data"])
		"leader_killed":
			_on_leader_killed(e["data"])
		"used_dark_power":
			_on_dark_power()
		"faction_war":
			_on_faction_war(e["data"])
		"corruption_spike":
			_on_corruption_spike(e["data"])

# ── Individual handlers ────────────────────────────────────────────────────

func _on_enemy_killed(data: Dictionary) -> void:
	var faction: String = str(data.get("faction", ""))
	if faction.is_empty():
		return
	# Weaken the faction — each individual kill chips away at their strength
	if is_instance_valid(FactionSystem):
		FactionSystem.on_faction_enemy_died(faction)
	# Notify FactionSystem player impact
	if is_instance_valid(FactionSystem):
		FactionSystem.on_player_killed_faction_enemy(faction)
	# World flag: "been in combat with X" — used by NPCs for dialogue
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("fought_" + faction)

func _on_player_died(data: Dictionary) -> void:
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("player_has_died")
	# Mild corruption penalty — dying lets darkness creep in
	if is_instance_valid(WorldState):
		WorldState.add_corruption(0.01)

func _on_nemesis_formed(data: Dictionary) -> void:
	var nd = data.get("nemesis")
	if not nd:
		return
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("has_nemesis")
	# Generate a revenge quest in QuestSystem
	if is_instance_valid(QuestSystem):
		QuestSystem.generate_from_nemesis(nd)

func _on_nemesis_escaped(data: Dictionary) -> void:
	var nd = data.get("nemesis")
	if not nd:
		return
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("nemesis_escaped")

func _on_nemesis_defeated(data: Dictionary) -> void:
	var nd = data.get("nemesis")
	if not nd:
		return
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("nemesis_slain_" + str(nd.nemesis_name).to_lower().replace(" ", "_"))
	# Reward: clearing a nemesis reduces corruption slightly
	if is_instance_valid(WorldState):
		WorldState.reduce_corruption(0.03)

func _on_zone_captured(data: Dictionary) -> void:
	var faction: String  = str(data.get("faction", ""))
	var old_f: String    = str(data.get("old_faction", ""))
	var zone: String     = str(data.get("zone_id", ""))

	if is_instance_valid(GameBrain):
		GameBrain.set_flag("zone_captured_" + zone)

	# If factions are hostile to each other this is a real war event
	if is_instance_valid(FactionSystem) and not faction.is_empty() and not old_f.is_empty():
		if FactionSystem.is_hostile(faction, old_f):
			record_event("faction_war", {"attacker_faction": faction, "defender_faction": old_f})

	# Generate a defend/retake quest
	if is_instance_valid(QuestSystem) and not faction.is_empty():
		QuestSystem.generate_from_zone_capture(zone, faction, old_f)

func _on_leader_killed(data: Dictionary) -> void:
	var faction: String = str(data.get("faction", ""))
	if faction.is_empty():
		return
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("leader_dead_" + faction)
	if is_instance_valid(FactionSystem):
		FactionSystem.weaken_faction(faction, 0.30)   # heavy blow to the faction

func _on_dark_power() -> void:
	if is_instance_valid(WorldState):
		WorldState.add_corruption(0.08)
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("used_dark_power")

func _on_faction_war(data: Dictionary) -> void:
	var af: String = str(data.get("attacker_faction", ""))
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("faction_war_active")
	# Generate a faction-war quest
	if is_instance_valid(QuestSystem) and not af.is_empty():
		QuestSystem.generate_from_faction_war(af, str(data.get("defender_faction", "")))

func _on_corruption_spike(data: Dictionary) -> void:
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("corruption_critical")
	# Generate an emergency purge quest
	if is_instance_valid(QuestSystem):
		QuestSystem.generate_corruption_quest()

# ==========================================================================
# Dynamic NPC dialogue context
# ==========================================================================
func get_npc_context_line() -> String:
	# Called by NPC.gd to inject a world-state–driven line into dialogue.
	if is_instance_valid(WorldState) and WorldState.corruption_level > 0.70:
		return "The world is rotting from within."
	if is_instance_valid(GameBrain) and GameBrain.has_flag("leader_dead_watchers"):
		return "You destroyed their sentinel... the Watchers are in chaos."
	if is_instance_valid(NemesisSystem) and NemesisSystem.nemeses.size() > 0:
		var nd: NemesisData = NemesisSystem.nemeses.values()[0] as NemesisData
		if nd and nd.killed_player:
			return "Be careful — " + nd.nemesis_name + " is still out there."
	if is_instance_valid(FactionSystem):
		var rep: int = int(FactionSystem.reputation.get("drifters", 0))
		if rep > 40:
			return "The Drifters speak well of you these days."
	if is_instance_valid(WorldState) and WorldState.season == "war":
		return "Stay alert — factions are at each other's throats."
	return ""

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	# Only save the last 50 events (enough for narrative continuity)
	var recent := event_log.slice(max(0, event_log.size() - 50))
	var out: Array = []
	for e in recent:
		# Strip non-serialisable values (NemesisData objects etc.)
		out.append({"type": e["type"], "day": e["day"]})
	return {"event_log": out}

func load_save_data(data: Dictionary) -> void:
	event_log.clear()
	for e in data.get("event_log", []):
		event_log.append({"type": str(e.get("type", "")), "day": int(e.get("day", 0)), "data": {}})
