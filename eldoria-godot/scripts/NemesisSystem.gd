extends Node
# Realm of Eldoria — NemesisSystem (autoload singleton)
#
# Shadow-of-Mordor inspired enemy memory layer.  Every significant enemy
# encounter is remembered.  When an enemy kills the player they level up,
# gain a new trait, and eventually respawn stronger with their history intact.
#
# Registered as autoload "NemesisSystem" in project.godot [autoload].
#
# ── Flow ──────────────────────────────────────────────────────────────────────
#   Enemy spawns  →  NemesisSystem.register_enemy(enemy)
#                    (assigns ID, creates NemesisData, stores in nemeses dict)
#
#   Enemy defeated by player  →  NemesisSystem.on_enemy_defeated(enemy)
#                                30 % escape → evolve + respawn later
#
#   Enemy kills player  →  NemesisSystem.on_player_killed_by(enemy)
#                           enemy levels up + gains trait + comes back
#
# ── Integration ───────────────────────────────────────────────────────────────
# Enemy._die()    calls on_enemy_defeated(self)
# Player._die()   calls on_player_killed_by(_last_attacker)
# NarrativeSystem.record_event("nemesis_formed") triggers a revenge quest

# ==========================================================================
# State
# ==========================================================================
var nemeses: Dictionary = {}   # nemesis_id → NemesisData

# How many active nemeses can be alive at once (prevents runaway growth)
const MAX_ACTIVE_NEMESES: int  = 6
# Chance that a defeated enemy escapes rather than dying permanently
const ESCAPE_CHANCE: float     = 0.28
# Seconds before an escaped/levelled nemesis respawns
const RESPAWN_DELAY: float     = 22.0

# Reference to Enemy script for respawn spawning
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")

# ==========================================================================
# Signals
# ==========================================================================
signal nemesis_formed(data: NemesisData)
signal nemesis_respawned(data: NemesisData)
signal nemesis_defeated(data: NemesisData)

# ==========================================================================
# Registration
# ==========================================================================
func register_enemy(enemy: Node) -> void:
	# Only director-spawned and boss-tier enemies become nemeses.
	# Hand-placed named bosses (EchoKnight, WatcherCore) are handled
	# separately and are not registered here to avoid double-tracking.
	if enemy.has_meta("nemesis_id"):
		return   # already registered
	if nemeses.size() >= MAX_ACTIVE_NEMESES:
		return   # at cap — don't track more until one is resolved

	var id := "%d_%d" % [Time.get_ticks_msec(), randi()]
	enemy.set_meta("nemesis_id", id)

	var data := NemesisData.new()
	data.nemesis_id  = id
	data.nemesis_name = generate_name()
	data.level       = 1
	data.faction_id  = str(enemy.get("faction_id") if enemy.get("faction_id") != null else "")
	data.enemy_kind  = str(enemy.get("enemy_kind") if enemy.get("enemy_kind") != null else "drifter")

	nemeses[id] = data
	enemy.set("nemesis_data", data)   # Enemy.gd declares var nemesis_data = null

func apply_traits(enemy: Node) -> void:
	# Apply stored NemesisData traits to a live enemy node's stats.
	# Called right after register_enemy (or after respawn add_child).
	var data: NemesisData = enemy.get("nemesis_data") as NemesisData
	if not data:
		return
	for t: String in data.traits:
		_apply_single_trait(enemy, t)

func _apply_single_trait(enemy: Node, t: String) -> void:
	match t:
		"fast":
			var spd: float = float(enemy.get("move_speed") if enemy.get("move_speed") != null else 2.6)
			var cspd: float = float(enemy.get("chase_speed") if enemy.get("chase_speed") != null else 4.6)
			enemy.set("move_speed",  spd  * 1.25)
			enemy.set("chase_speed", cspd * 1.25)
		"armored":
			var mhp: int = int(enemy.get("max_hp") if enemy.get("max_hp") != null else 20)
			var dmg: int = int(enemy.get("damage") if enemy.get("damage") != null else 6)
			enemy.set("max_hp", int(float(mhp) * 1.40))
			enemy.set("damage", int(float(dmg) * 0.85))
		"rage_mode":
			var mhp: int = int(enemy.get("max_hp") if enemy.get("max_hp") != null else 20)
			var dmg: int = int(enemy.get("damage") if enemy.get("damage") != null else 6)
			enemy.set("max_hp", int(float(mhp) * 1.30))
			enemy.set("damage", int(float(dmg) * 1.30))
		"dash_counter":
			var ar: float = float(enemy.get("aggro_range") if enemy.get("aggro_range") != null else 8.0)
			enemy.set("aggro_range", ar * 1.30)
		"poisonous":
			var cd: float = float(enemy.get("attack_cooldown") if enemy.get("attack_cooldown") != null else 1.45)
			enemy.set("attack_cooldown", maxf(0.85, cd * 0.82))
		"regenerating":
			# Handled in Enemy._physics_process via nemesis_data.has_trait("regenerating")
			pass
		"fire_resistant":
			# Reserved for elemental damage — no mechanical effect yet
			pass

# ==========================================================================
# Encounter callbacks
# ==========================================================================
func on_enemy_defeated(enemy: Node) -> void:
	var data: NemesisData = enemy.get("nemesis_data") as NemesisData
	if not data:
		return

	data.times_defeated += 1
	data.add_history("defeated by player (day %d)" % \
		(int(WorldState.day) if is_instance_valid(WorldState) else 0))

	# Random escape — enemy survives, levels up, comes back
	if data.times_defeated < 3 and randf() < ESCAPE_CHANCE:
		data.escaped = true
		data.add_history("escaped — will return stronger")
		_evolve(data)
		emit_signal("nemesis_formed", data)
		if is_instance_valid(NarrativeSystem):
			NarrativeSystem.record_event("nemesis_escaped", {"nemesis": data})
		_respawn_later(data, enemy.global_position)
	else:
		# Truly defeated — remove from tracking
		data.add_history("slain permanently")
		nemeses.erase(data.nemesis_id)
		emit_signal("nemesis_defeated", data)
		if is_instance_valid(NarrativeSystem):
			NarrativeSystem.record_event("nemesis_defeated", {"nemesis": data})

func on_player_killed_by(attacker: Node) -> void:
	if not attacker or not is_instance_valid(attacker):
		return

	# Get or create nemesis data for this attacker
	if not attacker.has_meta("nemesis_id"):
		# Spontaneous — this enemy just became notable by killing the player
		register_enemy(attacker)

	var data: NemesisData = attacker.get("nemesis_data") as NemesisData
	if not data:
		return

	data.killed_player = true
	data.add_history("killed the player (day %d)" % \
		(int(WorldState.day) if is_instance_valid(WorldState) else 0))
	_evolve(data)

	if is_instance_valid(NarrativeSystem):
		NarrativeSystem.record_event("nemesis_formed", {"nemesis": data})

	emit_signal("nemesis_formed", data)

# ==========================================================================
# Evolution
# ==========================================================================
func _evolve(data: NemesisData) -> void:
	var trait_pool: Array[String] = [
		"fast", "armored", "rage_mode", "dash_counter", "poisonous", "regenerating"
	]
	# Don't re-grant traits the nemesis already has
	var available: Array[String] = []
	for t: String in trait_pool:
		if not data.has_trait(t):
			available.append(t)

	if available.size() > 0:
		var picked: String = available[randi() % available.size()]
		data.add_trait(picked)
		data.add_history("evolved trait: " + picked)

	data.level += 1

# ==========================================================================
# Respawn
# ==========================================================================
func _respawn_later(data: NemesisData, near_pos: Vector3) -> void:
	# Await in a coroutine on this node so it survives scene changes.
	_do_respawn.call_deferred(data, near_pos)

func _do_respawn(data: NemesisData, near_pos: Vector3) -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout

	# Don't respawn if nemesis was resolved while waiting
	if not nemeses.has(data.nemesis_id):
		return

	var scene := get_tree().current_scene
	if not scene:
		return

	var enemy := CharacterBody3D.new()
	enemy.set_script(ENEMY_SCRIPT)
	enemy.set("enemy_kind", data.enemy_kind)
	enemy.set("nemesis_data", data)
	enemy.set_meta("nemesis_id", data.nemesis_id)

	# Level bonus: each level adds 15% max HP
	var base_hp: int = 20
	var scaled_hp: int = int(float(base_hp) * (1.0 + float(data.level - 1) * 0.15))
	enemy.set("max_hp", scaled_hp)
	enemy.set("enemy_name", data.nemesis_name)

	# Offset spawn 6-10m from last known position
	var offset := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	scene.add_child(enemy)
	enemy.global_position = near_pos + offset

	apply_traits(enemy)
	data.spawned_count += 1
	data.escaped = false
	data.add_history("respawned (level %d)" % data.level)

	# Notify EnemyDirector so it tracks the count
	if is_instance_valid(EnemyDirector):
		EnemyDirector._dc_count += 1
		if enemy.has_signal("died"):
			enemy.died.connect(EnemyDirector._on_enemy_died)

	emit_signal("nemesis_respawned", data)

	# Flash the screen to announce their return (kids love this moment)
	if is_instance_valid(Juice):
		Juice.screen_flash(Color(0.85, 0.20, 0.20, 0.40), 0.55)

# ==========================================================================
# Name generator
# ==========================================================================
const _NAME_FIRST: Array[String] = [
	"Gor", "Thal", "Zek", "Mor", "Karn", "Sket", "Vral", "Osh", "Drek", "Nul"
]
const _NAME_TITLE: Array[String] = [
	"the Skull", "the Breaker", "the Hollow", "Ashbane", "the Relentless",
	"of the Void", "Darkmantle", "the Undying", "Ironfang", "the Bitter"
]

func generate_name() -> String:
	var first := _NAME_FIRST[randi() % _NAME_FIRST.size()]
	var title := _NAME_TITLE[randi() % _NAME_TITLE.size()]
	return first + " " + title

# ==========================================================================
# Taunts (called by NPC.gd or overhead labels when nemesis is present)
# ==========================================================================
func get_taunt(data: NemesisData) -> String:
	if data.killed_player and data.times_defeated == 0:
		return "I remember you... you fell before."
	if data.times_defeated >= 3:
		return "You can't kill me! I keep coming back!"
	if data.escaped:
		return "You thought I was dead?"
	if data.has_trait("rage_mode"):
		return "Your blood will feed my rage!"
	if data.level >= 3:
		return "I have grown beyond what you know!"
	return "You are nothing."

# ==========================================================================
# Visual evolution (tint + scale by level)
# ==========================================================================
func apply_visuals(enemy: Node) -> void:
	var data: NemesisData = enemy.get("nemesis_data") as NemesisData
	if not data or data.level <= 1:
		return
	# Scale up slightly per level — max 30% larger at level 4
	var scale_mult := 1.0 + float(data.level - 1) * 0.08
	scale_mult = clampf(scale_mult, 1.0, 1.30)
	var model := enemy.get_node_or_null("Model") if enemy.has_method("get_node_or_null") else null
	if not model:
		enemy.scale = Vector3.ONE * scale_mult
	# Red tint intensifies per level
	if data.level >= 3 and enemy.has_method("get_node_or_null"):
		var mesh := enemy.get_node_or_null("Model")
		if mesh and mesh.is_class("MeshInstance3D"):
			mesh.modulate = Color(1.0, 0.3 + float(data.level) * 0.05, 0.3)

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	var out: Dictionary = {}
	for id: String in nemeses:
		out[id] = nemeses[id].to_dict()
	return out

func load_save_data(data: Dictionary) -> void:
	nemeses.clear()
	for id: String in data:
		var nd := NemesisData.new()
		nd.from_dict(data[id])
		nemeses[id] = nd
