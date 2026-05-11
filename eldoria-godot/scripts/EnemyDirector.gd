extends Node
# Realm of Eldoria — EnemyDirector (autoload singleton)
#
# Central AI Director: controls pacing, spawns enemies intelligently, and
# reacts to player skill in real time.  Inspired by the Left 4 Dead AI Director.
#
# Registered as autoload "EnemyDirector" in project.godot [autoload].
#
# ── Philosophy ────────────────────────────────────────────────────────────────
# The director never spawns randomly.  It tracks four quantities:
#
#   intensity   — how stressed the combat is right now  (0 = calm, 1 = chaos)
#   wave_state  — CALM | BUILD | PEAK | REST
#   spawn_timer — time until the next spawn decision
#   _dc_count   — director-spawned enemies currently alive
#
# Intensity rises from: enemies alive, player taking hits, sustained aggression.
# Intensity falls from: killing enemies, idle time, REST-state forced decay.
#
# Wave-state machine (L4D-style):
#   CALM  → BUILD when intensity ≥ 0.25 for 3 s
#   BUILD → PEAK  when intensity ≥ 0.65 and BUILD lasted ≥ 5 s
#   PEAK  → REST  when PEAK lasted ≥ 20 s  OR  intensity drops below 0.45
#   REST  → CALM  after ≥ 8 s AND intensity < 0.15  (enforces recovery breath)
#
# Enemy type by intensity tier:
#   < 0.30 → drifter     (basic shambling melee)
#   < 0.60 → mix         (drifter 30% / reactive_scout 70%)
#   ≥ 0.60 → elite mix   (watcher 45% / reactive_scout 55%)
#   ≥ 0.95 + rare → WatcherCore boss (opt-in, 5-min cooldown)
#
# Spawn position bias:
#   55% behind player (120–240° off look direction), 45% side arcs, 18–28 m.
#   Never inside the player's forward ±45° cone.
#
# ── Integration ───────────────────────────────────────────────────────────────
# WorldManager calls set_combat_active(true/false) on every area transition.
# Safe areas (Village, PlayerHome, CharacterSelect) set active = false.
# Combat areas (EchoingRuins, ForestPass, etc.) set active = true.
#
# Director-spawned Enemy nodes use Enemy.gd and join the "enemies" group, so:
#   • Quest kill objectives advance automatically (via call_group "quest_listeners")
#   • GameBrain ratio tracking works exactly like hand-placed enemies
#   • They count toward kill achievements

# ==========================================================================
# Constants
# ==========================================================================
const INTENSITY_DECAY_BASE:  float = 0.08   # per second when no enemies
const INTENSITY_PER_ENEMY:   float = 0.012  # per living director enemy per second
const INTENSITY_AGG_MULT:    float = 0.025  # GameBrain agg ratio contribution /s
const INTENSITY_DEF_MULT:    float = 0.035  # defensive (taking hits) contribution /s
const REST_DECAY_MULT:       float = 2.5    # intensity falls faster in REST

const BUILD_THRESHOLD:  float = 0.25   # intensity needed to leave CALM
const PEAK_THRESHOLD:   float = 0.65   # intensity needed to leave BUILD
const PEAK_EXIT_LOW:    float = 0.45   # peak ends early if intensity drops here
const REST_EXIT_LOW:    float = 0.15   # REST ends only when intensity drops this far

const MIN_BUILD_TIME:   float = 5.0    # must BUILD for at least this long
const MIN_REST_TIME:    float = 8.0    # always rest at least this long after a peak
const MAX_PEAK_TIME:    float = 22.0   # force rest after this long in peak

const MAX_DC_ENEMIES:   int   = 6      # director-spawned enemies alive at once
const MAX_TOTAL_ENEMIES: int  = 14     # total scene enemies (director + hand-placed)

const SPAWN_DIST_MIN:   float = 18.0   # minimum spawn distance from player
const SPAWN_DIST_MAX:   float = 28.0   # maximum spawn distance from player

const BOSS_COOLDOWN_TIME:    float = 300.0  # 5 min between director-spawned bosses
const BOSS_SESSION_GATE:     float = 120.0  # must be in combat zone this long first
const BOSS_SPAWN_CHANCE:     float = 0.04   # 4 % chance per spawn decision at ≥ 0.95

# ── Safe areas — director deactivates when player enters these ─────────────
const SAFE_AREAS: Array[String] = [
	"Village", "PlayerHome", "Hub", "CharacterSelect", "MainMenu",
	"TownSquare", "Tavern",
]

# ==========================================================================
# State
# ==========================================================================
enum WaveState { CALM, BUILD, PEAK, REST }

var intensity:   float     = 0.0
var wave_state:  WaveState = WaveState.CALM

var _state_timer:  float = 0.0   # time spent in current wave state
var _spawn_timer:  float = 3.0   # countdown to next spawn decision
var _dc_count:     int   = 0     # director-spawned enemies alive
var _session_t:    float = 0.0   # time in current combat zone
var _boss_alive:   bool  = false
var _boss_cooldown: float = 0.0

# Set to true by level scripts that want the director to be able to
# escalate all the way to a WatcherCore boss spawn.  Off by default so
# scripted level bosses (EchoingRuins) aren't doubled.
var allow_boss_spawn: bool = false

# Director spawning is only active inside registered combat zones.
var _combat_active: bool = false

var _player: Node3D = null  # typed Node3D so global_position/transform infer correctly

# ==========================================================================
# Signals
# ==========================================================================
signal intensity_changed(value: float)
signal wave_state_changed(state: WaveState)
signal director_boss_spawned()
signal director_boss_died()

# ==========================================================================
# Scripts
# ==========================================================================
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")
const BOSS_SCRIPT  = preload("res://scripts/WatcherCore.gd")

# ==========================================================================
# Lifecycle
# ==========================================================================
func _ready() -> void:
	# Find player at boot; also re-checked every frame if lost.
	_find_player()

func _process(delta: float) -> void:
	if not _combat_active:
		return

	_find_player()
	if not _player or not is_instance_valid(_player):
		return

	_session_t    += delta
	_boss_cooldown = maxf(0.0, _boss_cooldown - delta)

	_update_intensity(delta)
	_update_wave_state(delta)
	_handle_spawning(delta)

# ==========================================================================
# Intensity
# ==========================================================================
func _update_intensity(delta: float) -> void:
	# ── Decay ─────────────────────────────────────────────────────────────
	var decay := INTENSITY_DECAY_BASE
	if wave_state == WaveState.REST:
		decay *= REST_DECAY_MULT   # force rapid cool-down in rest period
	intensity -= decay * delta

	# ── Enemy pressure ────────────────────────────────────────────────────
	intensity += float(_dc_count) * INTENSITY_PER_ENEMY * delta

	# ── Player behaviour influence (from GameBrain ratios) ─────────────────
	# agg_r: aggressive play style → game should get harder
	# def_r: "defensive" proxy here = taking damage → player is struggling
	if is_instance_valid(GameBrain):
		var agg_r := GameBrain.get_playstyle_ratio("aggressive")
		var def_r := GameBrain.get_playstyle_ratio("defensive")
		intensity += agg_r * INTENSITY_AGG_MULT * delta
		intensity += def_r * INTENSITY_DEF_MULT * delta

	# ── WorldState corruption boost ────────────────────────────────────────
	# Corrupt world passively increases baseline threat.
	if is_instance_valid(WorldState):
		intensity += WorldState.get_corruption_intensity_bonus() * delta

	intensity = clampf(intensity, 0.0, 1.0)
	emit_signal("intensity_changed", intensity)

# ==========================================================================
# Wave-state machine
# ==========================================================================
func _update_wave_state(delta: float) -> void:
	_state_timer += delta
	match wave_state:
		WaveState.CALM:
			if intensity >= BUILD_THRESHOLD and _state_timer >= 3.0:
				_set_state(WaveState.BUILD)
		WaveState.BUILD:
			if intensity >= PEAK_THRESHOLD and _state_timer >= MIN_BUILD_TIME:
				_set_state(WaveState.PEAK)
			elif intensity < BUILD_THRESHOLD * 0.5:
				# Dropped too low before peaking — back to calm
				_set_state(WaveState.CALM)
		WaveState.PEAK:
			if _state_timer >= MAX_PEAK_TIME or intensity < PEAK_EXIT_LOW:
				_set_state(WaveState.REST)
		WaveState.REST:
			if _state_timer >= MIN_REST_TIME and intensity < REST_EXIT_LOW:
				_set_state(WaveState.CALM)

func _set_state(s: WaveState) -> void:
	wave_state   = s
	_state_timer = 0.0
	emit_signal("wave_state_changed", s)

# ==========================================================================
# Spawning
# ==========================================================================
func _handle_spawning(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	# No spawning during the mandatory rest period.
	if wave_state == WaveState.REST:
		_spawn_timer = 2.0
		return

	# Enemy caps — scale ceiling with WorldState season density multiplier.
	var density_mult := 1.0
	if is_instance_valid(WorldState):
		density_mult = WorldState.get_enemy_density_multiplier()
	var dc_cap   := int(float(MAX_DC_ENEMIES) * density_mult)
	var tot_cap  := int(float(MAX_TOTAL_ENEMIES) * density_mult)
	var total    := get_tree().get_nodes_in_group("enemies").size()
	if total >= tot_cap or _dc_count >= dc_cap:
		_spawn_timer = 1.5
		return

	_decide_spawn()

	# Spawn interval: 3.5 s at calm → 0.6 s at full chaos.
	# CALM state enforces a slower floor to prevent drip-spawns.
	var interval := lerpf(3.5, 0.6, intensity)
	if wave_state == WaveState.CALM:
		interval = maxf(interval, 4.5)
	_spawn_timer = interval

func _decide_spawn() -> void:
	# Boss escalation — opt-in, rare, gated behind session time and cooldown.
	if allow_boss_spawn and not _boss_alive and _boss_cooldown <= 0.0:
		if intensity >= 0.95 and _session_t >= BOSS_SESSION_GATE and randf() < BOSS_SPAWN_CHANCE:
			_spawn_boss()
			return

	# ── Faction-aware spawn bias ───────────────────────────────────────────
	# During war/apocalypse seasons, dominant factions spawn at higher rates.
	# This makes the world feel like it's fighting itself, not just the player.
	if is_instance_valid(FactionSystem) and is_instance_valid(WorldState):
		var dominant := FactionSystem.get_dominant_faction()
		var s := WorldState.season
		if (s == "war" or s == "apocalypse") and not dominant.is_empty():
			# 35% chance to reinforce the dominant faction's kind
			if randf() < 0.35:
				var kind := _faction_kind_for_director(dominant)
				if not kind.is_empty():
					_spawn_enemy(kind)
					return

	# Regular enemy by intensity tier.
	if intensity < 0.30:
		_spawn_enemy("drifter")
	elif intensity < 0.60:
		_spawn_enemy("drifter" if randf() < 0.30 else "reactive_scout")
	else:
		_spawn_enemy("watcher" if randf() < 0.45 else "reactive_scout")

func _faction_kind_for_director(faction_id: String) -> String:
	# Maps a faction to a director-spawnable kind (must exist in KIND_PACKAGES).
	# Returns "" if the faction has no valid director archetype.
	match faction_id:
		"drifters":     return "drifter"
		"watchers":     return "watcher"
		"goblins":      return "reactive_scout"   # closest to goblin_scout energy
		"bandits":      return "reactive_scout"   # reuse scout stats; tint differs
		"undead":       return "drifter"           # skeleton → drifter archetype
		"crystal_order": return "watcher"          # guardian → ranged archetype
	return ""

# ==========================================================================
# Enemy spawn
# ==========================================================================
# Kind packages: these are the BASE stats the Director uses.
# randomize_stats_from_visuals() runs inside Enemy._ready() and applies
# a ±20 % brightness multiplier on top — so the variation is natural.
const KIND_PACKAGES: Dictionary = {
	"drifter": {
		"enemy_name": "Drifter",
		"max_hp": 18, "damage": 6, "move_speed": 2.2, "chase_speed": 3.8,
		"aggro_range": 8.0, "xp_reward": 12, "gold_reward": 2,
		"tint": Color(0.62, 0.52, 0.38),   # dusty brown — reads as "weak"
	},
	"reactive_scout": {
		"enemy_name": "Scout",
		"max_hp": 24, "damage": 9, "move_speed": 3.8, "chase_speed": 6.2,
		"aggro_range": 10.0, "xp_reward": 22, "gold_reward": 4,
		"tint": Color(0.25, 0.88, 0.42),   # vivid green — reads as "fast/dangerous"
	},
	"watcher": {
		"enemy_name": "Watcher",
		"max_hp": 34, "damage": 11, "move_speed": 1.8, "chase_speed": 2.6,
		"aggro_range": 14.0, "xp_reward": 28, "gold_reward": 6,
		"tint": Color(0.38, 0.60, 0.92),   # spectral blue — reads as "alien/ranged"
	},
}

func _spawn_enemy(kind: String) -> void:
	var pkg: Dictionary = KIND_PACKAGES.get(kind, KIND_PACKAGES["drifter"])
	var spawn_pos := _get_spawn_position()

	var enemy := CharacterBody3D.new()
	enemy.set_script(ENEMY_SCRIPT)

	# Set kind + all base stats BEFORE add_child so Enemy._ready() sees them.
	# randomize_stats_from_visuals() then multiplies these by ±20% brightness.
	enemy.set("enemy_kind",    kind)
	enemy.set("enemy_name",    pkg["enemy_name"])
	enemy.set("max_hp",        pkg["max_hp"])
	enemy.set("damage",        pkg["damage"])
	enemy.set("move_speed",    pkg["move_speed"])
	enemy.set("chase_speed",   pkg["chase_speed"])
	enemy.set("aggro_range",   pkg["aggro_range"])
	enemy.set("xp_reward",     pkg["xp_reward"])
	enemy.set("gold_reward",   pkg["gold_reward"])
	enemy.set("tint",          pkg["tint"])

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos

	_dc_count += 1
	# Connect to died — Enemy emits died(self)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _spawn_boss() -> void:
	_boss_alive  = true
	_boss_cooldown = BOSS_COOLDOWN_TIME

	var spawn_pos := _get_spawn_position()
	spawn_pos.y  += 4.5   # WatcherCore floats — start already at combat height

	var boss := CharacterBody3D.new()
	boss.set_script(BOSS_SCRIPT)
	get_tree().current_scene.add_child(boss)
	boss.global_position = spawn_pos

	if boss.has_signal("died"):
		boss.died.connect(_on_boss_died)

	emit_signal("director_boss_spawned")

	# Alert player: dramatic flash + QuestSystem narrative hook
	if is_instance_valid(Juice):
		Juice.screen_flash(Color(1.0, 0.10, 0.10, 0.55), 0.45)
		Juice.screen_shake(0.25, 0.6)
	if is_instance_valid(QuestSystem):
		QuestSystem.on_area_entered("BossArea")   # advances reach_boss_chamber if active

# ==========================================================================
# Spawn position
# ==========================================================================
func _get_spawn_position() -> Vector3:
	if not _player:
		return Vector3.ZERO
	var player_pos: Vector3 = _player.global_position

	# Derive look direction (Y-flattened forward vector)
	var look: Vector3 = -_player.global_transform.basis.z
	look.y = 0.0
	look = look.normalized() if look.length_squared() > 0.01 else Vector3.FORWARD

	# Angle bias — never spawn in the player's forward ±45° cone.
	# 55 % behind (120–240° off forward), 45 % side arcs (60–120° either side).
	var angle_off: float = 0.0
	if randf() < 0.55:
		# Behind player: 2/3π – 4/3π radians
		angle_off = randf_range(PI * 0.67, PI * 1.33)
	else:
		# Lateral: 1/3π – 2/3π left OR right
		var side: float = 1.0 if randf() < 0.5 else -1.0
		angle_off = randf_range(PI * 0.33, PI * 0.67) * side

	var dist: float = randf_range(SPAWN_DIST_MIN, SPAWN_DIST_MAX)
	var dir: Vector3 = look.rotated(Vector3.UP, angle_off)
	var pos: Vector3 = player_pos + dir * dist
	pos.y = player_pos.y   # keep spawn at player's height level

	return pos

# ==========================================================================
# Death callbacks
# ==========================================================================
func _on_enemy_died(_enemy: Node) -> void:
	_dc_count = maxi(0, _dc_count - 1)
	# Reward: killing reduces pressure — player feels the relief.
	intensity = maxf(0.0, intensity - 0.06)
	# Notify FactionSystem so faction strength degrades correctly.
	if is_instance_valid(FactionSystem) and is_instance_valid(_enemy):
		var fid: String = str(_enemy.get("faction_id") if _enemy.get("faction_id") != null else "")
		if not fid.is_empty():
			FactionSystem.on_faction_enemy_died(fid)

func _on_boss_died(_boss: Node = null) -> void:
	_boss_alive = false
	# Big relief after killing a director boss — force a rest.
	intensity = maxf(0.0, intensity - 0.40)
	_set_state(WaveState.REST)
	emit_signal("director_boss_died")
	if is_instance_valid(Juice):
		Juice.screen_flash(Color(0.80, 0.90, 1.00, 0.40), 0.60)

# ==========================================================================
# Public API
# ==========================================================================
func set_combat_active(active: bool) -> void:
	# Called by WorldManager on every area transition.
	_combat_active = active
	if active:
		# Carry intensity over — returning mid-fight should feel continuous.
		_session_t  = 0.0
		_spawn_timer = 3.0   # brief grace period on area entry
	else:
		# Leaving a combat zone: gently drain intensity and rest.
		intensity   = maxf(0.0, intensity - 0.30)
		_set_state(WaveState.CALM)
		_spawn_timer = 5.0

func set_player(p: Node) -> void:
	_player = p

func get_wave_state_name() -> String:
	return WaveState.keys()[wave_state]

func get_intensity_tier() -> String:
	if intensity < 0.30: return "calm"
	elif intensity < 0.60: return "building"
	elif intensity < 0.85: return "peak"
	else: return "critical"

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	return {
		"intensity":    intensity,
		"boss_cooldown": _boss_cooldown,
	}

func load_save_data(data: Dictionary) -> void:
	intensity      = float(data.get("intensity", 0.0))
	_boss_cooldown = float(data.get("boss_cooldown", 0.0))

# ==========================================================================
# Helpers
# ==========================================================================
func _find_player() -> void:
	if _player and is_instance_valid(_player):
		return
	var ps: Array[Node3D] = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		_player = ps[0]
	else:
		_player = get_tree().current_scene.get_node_or_null("Player") \
		          if get_tree().current_scene else null
