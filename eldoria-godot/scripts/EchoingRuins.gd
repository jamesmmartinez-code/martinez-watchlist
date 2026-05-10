extends Node
# Realm of Eldoria — EchoingRuins level flow controller.
#
# Manages the 7-section narrative arc of "The Echoing Ruins":
#   0 · Intro Combat        — two Drifters teach basic combat
#   1 · Enemy Intro         — Watcher revealed; player learns ranged threat
#   2 · First Adaptation    — Reactive Scout mirrors player; adaptation moment
#   3 · Ability Evolution   — dash threshold triggers mutation popup
#   4 · Mixed Arena         — Drifters + Watchers + Reactive Scout gauntlet
#   5 · Pre-Boss Test       — focused challenge proving mastery
#   6 · Echo Knight         — 3-phase adaptive boss fight
#
# Usage: attach to a Node in the level scene and call start() from _ready()
# or from whatever scene-transition hook you use.

signal section_complete(section_index)
signal level_complete

# ── External references ────────────────────────────────────────────────────
# Set these in the Inspector or via code before calling start().
@export var player_path: NodePath = NodePath("../Player")
@export var echo_knight_spawn: NodePath = NodePath("../Spawns/BossSpawn")
@export var spawn_root: NodePath = NodePath("../Spawns")
@export var hud_path: NodePath = NodePath("../HUD")          # optional

# Pre-defined named spawn positions the level scene should provide.
# Keys match strings used in _spawn_at(); missing keys fall back to origin.
var _spawn_positions: Dictionary = {}

# ── Section state ──────────────────────────────────────────────────────────
var _section: int = -1
var _alive_enemies: Array[Node] = []
var _boss: Node = null
var _player: Node = null
var _evolution_triggered: bool = false
var _evolution_dash_threshold: int = 5   # dashes needed to fire mutation moment

# ── Timing ─────────────────────────────────────────────────────────────────
var _wave_cleared: bool = false
var _next_section_timer: float = 0.0
const SECTION_DELAY: float = 1.8          # seconds between wave-clear and next spawn
var _ticking: bool = false

# ── Enemy script cache ─────────────────────────────────────────────────────
const ENEMY_SCRIPT   = preload("res://scripts/Enemy.gd")
const EK_SCRIPT      = preload("res://scripts/EchoKnight.gd")

# ── Preload simple mesh shapes for placeholder enemy visuals ───────────────
# Real project would use PackedScene — these capsules are the fallback.
const _ENEMY_RADIUS  = 0.4
const _ENEMY_HEIGHT  = 1.8

# ==========================================================================
func _ready() -> void:
	_player = get_node_or_null(player_path)
	if not _player:
		push_warning("EchoingRuins: player node not found at path '%s'" % player_path)
	_index_spawn_positions()
	# Listen for dash events to detect evolution moment
	if _player and _player.has_signal("dashed"):
		_player.dashed.connect(_on_player_dashed)

func start() -> void:
	_section = -1
	_alive_enemies.clear()
	_advance_section()

func _process(delta: float) -> void:
	if not _ticking:
		return
	# Wait for all enemies to die before starting the next section timer.
	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	if _alive_enemies.is_empty() and not _wave_cleared:
		_wave_cleared = true
		_next_section_timer = SECTION_DELAY

	if _wave_cleared:
		_next_section_timer -= delta
		if _next_section_timer <= 0.0:
			_wave_cleared = false
			_ticking   = false
			emit_signal("section_complete", _section)
			_advance_section()

# ==========================================================================
# Section sequencing
# ==========================================================================
func _advance_section() -> void:
	_section += 1
	match _section:
		0: _section_intro_combat()
		1: _section_watcher_intro()
		2: _section_reactive_scout()
		3: _section_ability_evolution()
		4: _section_mixed_arena()
		5: _section_pre_boss()
		6: _section_echo_knight()
		_: _on_level_complete()

# ── Section 0 · Intro Combat ───────────────────────────────────────────────
func _section_intro_combat() -> void:
	_say_narrator("Ancient footsteps echo in the dark…")
	var a := _spawn_enemy("drifter", "spawn_drifter_a", {"max_hp": 30, "damage": 4, "speed": 3.0})
	var b := _spawn_enemy("drifter", "spawn_drifter_b", {"max_hp": 30, "damage": 4, "speed": 3.0})
	_register_wave([a, b])

# ── Section 1 · Watcher Intro ──────────────────────────────────────────────
func _section_watcher_intro() -> void:
	_say_narrator("Something watches from the shadows…")
	var w := _spawn_enemy("watcher", "spawn_watcher_a", {"max_hp": 40, "damage": 7, "speed": 2.5})
	_register_wave([w])

# ── Section 2 · First Adaptation Moment ────────────────────────────────────
func _section_reactive_scout() -> void:
	_say_narrator("It studies you… learning your patterns.")
	var rs := _spawn_enemy("reactive_scout", "spawn_scout_a", {"max_hp": 50, "damage": 6, "speed": 4.5})
	_register_wave([rs])

# ── Section 3 · Ability Evolution ──────────────────────────────────────────
# No enemies — waits for the player to dash enough times, then evolves the
# slash ability and advances automatically.
func _section_ability_evolution() -> void:
	_say_narrator("Your technique sharpens. Something stirs within you…")
	# The evolution check is driven by _on_player_dashed().
	# Fallback: if the player already has enough dash count, fire immediately.
	var dash_raw := GameBrain.get_raw("dash_heavy") if is_instance_valid(GameBrain) else 0
	if dash_raw >= _evolution_dash_threshold or _evolution_triggered:
		_trigger_evolution()
	else:
		# Section will be advanced by _on_player_dashed once threshold is met.
		_ticking = false

func _on_player_dashed() -> void:
	if _section != 3 or _evolution_triggered:
		return
	var dash_raw := GameBrain.get_raw("dash_heavy") if is_instance_valid(GameBrain) else 0
	if dash_raw >= _evolution_dash_threshold:
		_trigger_evolution()

func _trigger_evolution() -> void:
	if _evolution_triggered:
		return
	_evolution_triggered = true
	# Mutate slash → Echo Strike if not already evolved.
	if is_instance_valid(GameBrain) and not GameBrain.has_evolution("slash_multihit"):
		GameBrain.set_evolution("slash_multihit")
	# Show a contextual popup if the player node exposes one.
	if _player and _player.has_method("_show_mutation_popup"):
		_player._show_mutation_popup("Echo Strike", "Your slash resonates — hitting twice!")
	# Wait a beat then advance.
	get_tree().create_timer(2.5).timeout.connect(_advance_section)

# ── Section 4 · Mixed Arena ────────────────────────────────────────────────
func _section_mixed_arena() -> void:
	_say_narrator("The ruins come alive.")
	var d1 := _spawn_enemy("drifter",        "spawn_drifter_a", {"max_hp": 35, "damage": 5, "speed": 3.5})
	var d2 := _spawn_enemy("drifter",        "spawn_drifter_c", {"max_hp": 35, "damage": 5, "speed": 3.5})
	var w  := _spawn_enemy("watcher",        "spawn_watcher_b", {"max_hp": 45, "damage": 7, "speed": 2.5})
	var rs := _spawn_enemy("reactive_scout", "spawn_scout_b",   {"max_hp": 55, "damage": 7, "speed": 4.5})
	_register_wave([d1, d2, w, rs])

# ── Section 5 · Pre-Boss Test ──────────────────────────────────────────────
func _section_pre_boss() -> void:
	_say_narrator("One last guardian stands between you and the Knight.")
	var rs1 := _spawn_enemy("reactive_scout", "spawn_scout_a", {"max_hp": 70, "damage": 8, "speed": 5.0})
	var rs2 := _spawn_enemy("reactive_scout", "spawn_scout_c", {"max_hp": 70, "damage": 8, "speed": 5.0})
	_register_wave([rs1, rs2])

# ── Section 6 · Echo Knight Boss ──────────────────────────────────────────
func _section_echo_knight() -> void:
	_say_narrator("The Echo Knight awakens. It knows everything you've done.")
	# Notify quest system that the player has reached the boss area.
	if is_instance_valid(QuestSystem):
		QuestSystem.on_area_entered("BossArea")
	if is_instance_valid(MapSystem):
		MapSystem.on_area_entered("BossArea")
	_boss = _spawn_echo_knight()
	if _boss:
		if _boss.has_signal("died"):
			_boss.died.connect(_on_boss_defeated)
		_alive_enemies = [_boss]
		_ticking = true

# ==========================================================================
# Boss defeated — grant reward and emit level_complete
# ==========================================================================
func _on_boss_defeated() -> void:
	_say_narrator("The Echo fades… silence reclaims the ruins.")
	# Stop wave-management loop immediately so _process can't re-advance sections.
	_ticking = false
	_alive_enemies.clear()
	# Unlock air_dash via SkillTree (registered in Player._setup_skill_tree)
	if is_instance_valid(SkillTree) and _player:
		SkillTree.try_unlock("air_dash", _player)
	# Fallback: if player exposes unlock_ability directly
	if _player and _player.has_method("unlock_ability"):
		_player.unlock_ability("air_dash")
	# Visual celebration
	if is_instance_valid(Juice):
		Juice.screen_flash(Color(0.8, 0.9, 1.0, 0.6), 0.5)
	# Short delay then level complete
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		emit_signal("level_complete")
	)

# ==========================================================================
# Spawning helpers
# ==========================================================================
func _spawn_enemy(kind: String, spawn_key: String, overrides: Dictionary = {}) -> Node:
	var pos := _get_spawn_pos(spawn_key)
	var body := CharacterBody3D.new()
	body.set_script(ENEMY_SCRIPT)
	# Apply overrides BEFORE _ready so the enemy sees them.
	if overrides.has("max_hp"):     body.set("max_hp",       overrides["max_hp"])
	if overrides.has("damage"):     body.set("damage",       overrides["damage"])
	# Enemy.gd exports "move_speed" not "speed" — using the wrong key is a
	# silent no-op that leaves all enemies at their default walk rate.
	if overrides.has("speed"):      body.set("move_speed",   overrides["speed"])
	if overrides.has("chase_speed"): body.set("chase_speed", overrides["chase_speed"])
	body.set("enemy_kind", kind)
	var spawn_node := get_node_or_null(spawn_root)
	var parent: Node = spawn_node if spawn_node else get_tree().current_scene
	parent.add_child(body)
	body.global_position = pos
	return body

func _spawn_echo_knight() -> Node:
	var spawn_node := get_node_or_null(echo_knight_spawn)
	var pos := spawn_node.global_position if spawn_node else Vector3.ZERO
	var body := CharacterBody3D.new()
	body.set_script(EK_SCRIPT)
	var parent: Node = get_node_or_null(spawn_root)
	if not parent:
		parent = get_tree().current_scene
	parent.add_child(body)
	body.global_position = pos
	return body

func _register_wave(enemies: Array) -> void:
	_alive_enemies = enemies.filter(func(e): return e != null and is_instance_valid(e))
	_ticking = true
	_wave_cleared = false

# ==========================================================================
# Spawn position registry
# ==========================================================================
func _index_spawn_positions() -> void:
	var root := get_node_or_null(spawn_root)
	if not root:
		return
	for child in root.get_children():
		_spawn_positions[child.name.to_lower()] = child.global_position

func _get_spawn_pos(key: String) -> Vector3:
	var k := key.to_lower()
	if _spawn_positions.has(k):
		return _spawn_positions[k]
	# Scatter around origin when no named marker exists.
	var idx := _alive_enemies.size()
	return Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0))

# ==========================================================================
# Narrator / HUD integration (graceful no-op when HUD isn't present)
# ==========================================================================
func _say_narrator(text: String) -> void:
	var hud := get_node_or_null(hud_path)
	if hud and hud.has_method("show_narrator"):
		hud.show_narrator(text)
	else:
		print("[EchoingRuins] ", text)

# ==========================================================================
# Public API
# ==========================================================================
func get_section() -> int:
	return _section

func skip_to_boss() -> void:
	# Debug shortcut — jump straight to section 6.
	_section = 5
	for e in _alive_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_alive_enemies.clear()
	_advance_section()
