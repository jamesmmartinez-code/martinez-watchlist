extends CharacterBody3D
class_name Enemy

# Realm of Eldoria — Goblin / Wolf / Bandit enemy.
# Wanders idly until player enters aggro_range, then chases and melees.
# On death drops XP + gold, respawns after respawn_delay seconds.

@export var enemy_name: String = "Goblin Scout"
@export var enemy_kind: String = "goblin"   # "goblin" | "wolf" | "bandit"
@export var max_hp: int = 28
@export var damage: int = 6
@export var move_speed: float = 2.6
@export var chase_speed: float = 4.6
# REFINE: combat-feel — aggro pulled in from 9.0 → 8.0; kid-friendly for Alden, still tense in clusters.
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.6
# REFINE: combat-feel — longer recovery (1.2 → 1.45) so kids have a clean window to reposition between hits.
@export var attack_cooldown: float = 1.45
@export var xp_reward: int = 18
@export var gold_reward: int = 4
@export var respawn_delay: float = 35.0
@export var tint: Color = Color(0.45, 0.85, 0.30)
@export var enemy_model: PackedScene = preload("res://assets/models/CesiumMan.glb")  # 2026-05-08: worker_girl.glb missing
# THEME §4 — per-kind real fantasy models override the placeholder RobotExpressive.
# Source-credited GLBs (CC-BY) live under assets/models/enemies/. When a kind has
# a dedicated model here, _spawn_model uses it AND skips the green-tint modulate
# (the model carries its own hand-painted textures — tinting muddies them).
# KIND_MODEL_PATHS: maps enemy_kind -> GLB path for all available enemy assets.
# Uses load() not preload() so missing files degrade gracefully (null -> fallback)
# rather than aborting parse. Keep in sync with assets/models/enemies/.
# run-25: fixed goblin->goblin.glb (was wolf.glb); added bandit, skeleton,
# crystal_elemental, goblin_scout; removed 7 non-existent actor-pack GLBs that
# caused preload() parse crashes.
const KIND_MODEL_PATHS: Dictionary = {
	"goblin":            "res://assets/models/enemies/goblin.glb",
	"goblin_scout":      "res://assets/models/enemies/goblin_scout.glb",
	"wolf":              "res://assets/models/enemies/wolf.glb",
	"bandit":            "res://assets/models/enemies/bandit.glb",
	"skeleton":          "res://assets/models/enemies/skeleton.glb",
	"crystal_elemental": "res://assets/models/enemies/crystal_elemental.glb",
	# Echoing Ruins archetypes (reuse existing GLBs until dedicated models ship)
	"drifter":           "res://assets/models/enemies/goblin.glb",
	"watcher":           "res://assets/models/enemies/skeleton.glb",
	"reactive_scout":    "res://assets/models/enemies/goblin_scout.glb",
}

func _get_kind_model(kind: String) -> PackedScene:
	# Returns the per-kind GLB scene, or null if unavailable (caller falls back
	# to enemy_model placeholder). load() is used intentionally — preload() on
	# a missing path aborts the entire script parse in Godot 4.x.
	# bandit_captain reuses the bandit rig until a dedicated GLB ships
	var resolved_kind: String = "bandit" if kind == "bandit_captain" else kind
	var path: String = KIND_MODEL_PATHS.get(resolved_kind, "")
	if path.is_empty():
		return null
	var res: Resource = load(path)
	if res == null or not (res is PackedScene):
		return null
	return res as PackedScene

# Map of enemy kind → faction id for the run-7 adaptive-cooldown schema.
# When a kind's faction has a `pressure` entry in `World.factions`, the enemy
# resolves its `attack_cooldown` against that scalar at spawn — the THIRD
# output on the same scalar that already drives NPC.gd dialogue tier 3 (run 4)
# and WorldBuilder spawn density (runs 5–6). Kinds NOT in this map (e.g.
# bandit until a bandit faction exists) keep the @export'd baseline.
# See SYSTEM_REGISTRY.md "Enemy Cooldown Schema."
const KIND_TO_FACTION := {
	"goblin": "whisperwood_goblins",
	"wolf": "dire_wolves",
	"skeleton": "crystal_caves",
	"crystal_elemental": "crystal_caves",
	"crystal_guardian": "crystal_caves",
}

# Cooldown band: baseline = kid-friendly recovery valve (Alden's 9-yo timing
# window). Min = Owen's mastery rung (still readable, but punishing). NEVER
# widen this band without re-reading PLAYER_MODEL.md — these endpoints are
# tuned to the 9/11-year-old combat-feel target.
const ATTACK_COOLDOWN_BASELINE: float = 1.45
const ATTACK_COOLDOWN_MIN: float = 1.05
# Threshold below which an enemy reads as "agitated" to the player and earns
# a ⚡ prefix on its floating name. Corresponds to roughly pressure ≤ 0.625
# — clearly past the first reducer for either goblins or wolves.
const AGITATED_COOLDOWN_THRESHOLD: float = 1.30

var hp: int
var _state: String = "idle"  # idle | wander | chase | attack | dead
var _player: CharacterBody3D = null
var _attack_timer: float = 0.0
var _wander_timer: float = 0.0
var _wander_target: Vector3
var _spawn_pos: Vector3
var _spawn_y: float = 0.0
var _gravity: float = 20.0
var _model: Node3D
var _hp_bar: Node3D
var _label: Label3D
# REFINE: character — THEME §12 MOTION & LIFE. Enemies in wander/idle state
# now breathe with the same dual-harmonic Y-bob that NPCs already use (NPC.gd
# line 294). Without this, a goblin standing in its wander dwell-pause read as
# a plastic figurine — animation plays, but the body is stationary. The bob
# (±0.018m primary + ±0.006m secondary) is invisible at combat distance but
# legible at 6–8m as "creature that breathes." Phase is randomised per-enemy
# at _ready so a goblin camp's three scouts never rise and fall in unison.
# Skips while chasing / attacking (state != "wander") and while dead — the
# same gate NPC.gd uses for its schedule-walker override.
var _breathe_phase: float = 0.0   # primary slow chest-rise harmonic
var _breathe_phase2: float = 0.0  # secondary fast shoulder-shift harmonic
# REFINE: combat-feel — THEME §12 MOTION & LIFE. Attack telegraph windup:
# tracks how much of the attack_cooldown has been "charging" since the timer
# last reset. When dist < attack_range and _attack_timer > 0, this counts UP
# from 0; the label color lerps toward warm-orange as the swing approaches.
# _base_label_color cached at _ready so resets are precise (not hardcoded).
var _attack_charge_timer: float = 0.0  # seconds since last swing (counts up while in attack state)
var _base_label_color: Color = Color(1.0, 0.55, 0.45)  # overwritten in _ready after label built
var _knockback_vel:  Vector3 = Vector3.ZERO  # applied in _physics_process, decays each frame
# Stagger — AI pauses for this many seconds after taking a hit.
# Tier: light (<8 dmg)=0s, medium (<20)=0.25s, heavy (≥20)=0.55s
var _stagger_timer: float = 0.0

# ── Utility AI / Detection ─────────────────────────────────────────────────
# detection_level builds while the player is in line-of-sight, decays when
# hidden. Once above DETECT_THRESHOLD the enemy chases. When LoS is fully
# lost (level reaches 0) the enemy gives up and resumes wandering.
# blackboard stores persistent per-enemy AI memory (last known player pos).
var detection_level: float  = 0.0     # 0 = unaware, 100 = fully alerted
const DETECT_RATE:      float = 18.0  # gain/s while player is in LoS
const DETECT_DECAY:     float = 6.0   # lose/s when LoS breaks
const DETECT_THRESHOLD: float = 30.0  # cross this to start chasing
const DETECT_MAX:       float = 100.0
var _in_los:    bool       = false    # line-of-sight result this frame
var blackboard: Dictionary = {}       # AI memory keyed by string
var _adapt_timer: float    = 0.0     # ticks up to ENEMY_ADAPT_INTERVAL then resets
const ENEMY_ADAPT_INTERVAL: float = 6.0

# ── Watcher ranged mode ───────────────────────────────────────────────────
# Populated at _ready() for enemy_kind=="watcher". Controls ranged-stance
# distances and the bolt fire timer.
var _ranged_mode:    bool  = false
var _bolt_timer:     float = 0.0
const WATCHER_IDEAL_DIST: float = 10.0  # preferred engagement range
const WATCHER_FLEE_DIST:  float = 5.0   # closer than this → retreat
const WATCHER_SHOOT_CD:   float = 2.5   # seconds between bolt fires

# ── Reactive Scout — aggressive detect/adapt interval ────────────────────
var _reactive_mode:  bool  = false   # set true for enemy_kind=="reactive_scout"

const DAMAGE_NUMBER_SCRIPT   = preload("res://scripts/DamageNumber.gd")
const WATCHER_BOLT_SCRIPT    = preload("res://scripts/WatcherBolt.gd")
const ENEMY_VARIANT_SHADER   = preload("res://shaders/EnemyVariant.gdshader")

# Non-null when the fallback-capsule path is active: stores the ShaderMaterial
# applied to every MeshInstance3D in the placeholder model so damage_flash can
# be set as a uniform (smooth per-frame decay) rather than swapping materials.
var _variant_shader_mat: ShaderMaterial = null
# Per-instance brightness seed (0.78–1.18).  Generated once in _ready so BOTH
# the shader tint and randomize_stats_from_visuals() draw from the same value.
# Bright (>1.09) = aggressive/fast/squishier.  Dark (<0.89) = defensive/tanky/slow.
var _variant_brightness: float = 1.0
var _behavior_type: String     = "balanced"   # "aggressive" | "balanced" | "defensive"

# ── Faction ───────────────────────────────────────────────────────────────
# Set in _ready() from FactionSystem.KIND_TO_FACTION_ID.  Read by FactionZone
# for zone influence, and by other enemies for inter-faction combat targeting.
var faction_id: String = ""
# Secondary target: another enemy from a hostile faction.  Evaluated at each
# adapt tick only if the player is far away / not in aggro range.
var _faction_target: Enemy = null

# ── Nemesis ───────────────────────────────────────────────────────────────
# Set by NemesisSystem.register_enemy() — null for non-tracked enemies.
var nemesis_data = null   # NemesisData resource (typed loosely to avoid circular load)

signal died(enemy)

func _ready() -> void:
	hp = max_hp
	# Run-7: faction-pressure-driven attack cooldown. Resolved ONCE at spawn
	# (not per-frame) so combat hot path stays cheap. Mutates `attack_cooldown`
	# in-place — the existing _do_attack() path is untouched.
	_resolve_adaptive_cooldown()
	_spawn_pos = global_position
	_spawn_y = global_position.y

	# Generate per-instance brightness BEFORE calling randomize_stats_from_visuals
	# so both the shader and the stat system share the same value.
	# Range 0.78–1.18 is wide enough to be visible on screen but not so extreme
	# that stats become unbalanced for Alden (9yo) / Owen (11yo).
	var _rng := RandomNumberGenerator.new(); _rng.randomize()
	_variant_brightness = _rng.randf_range(0.78, 1.18)
	randomize_stats_from_visuals()

	# REFINE: character — randomise breathe phases so nearby enemies never sync.
	var _rng_breathe := RandomNumberGenerator.new(); _rng_breathe.randomize()
	_breathe_phase = _rng_breathe.randf() * TAU
	_breathe_phase2 = _rng_breathe.randf() * TAU
	add_to_group("enemies")
	# ── Faction allegiance ────────────────────────────────────────────────────
	if is_instance_valid(FactionSystem):
		faction_id = FactionSystem.get_faction_for_kind(enemy_kind)
	# ── Nemesis registration ──────────────────────────────────────────────────
	# Director-spawned enemies are registered AFTER _ready runs so stats are
	# final.  Traits are applied on top of already-randomised stats.
	if is_instance_valid(NemesisSystem) and nemesis_data == null:
		call_deferred("_register_as_nemesis_candidate")
	elif nemesis_data != null and is_instance_valid(NemesisSystem):
		# Respawned nemesis — apply traits immediately (data already set)
		NemesisSystem.apply_traits(self)
		NemesisSystem.apply_visuals(self)
	# ── Kind-specific mode flags ─────────────────────────────────────────────
	_ranged_mode   = (enemy_kind == "watcher")
	_reactive_mode = (enemy_kind == "reactive_scout")
	if _reactive_mode:
		# Scouts detect the player much faster and adapt every 2s
		const REACT_DETECT_RATE: float = 40.0  # will shadow the outer const locally
		detection_level = 0.0  # still starts at 0
		_adapt_timer = 4.0     # force first adapt soon after spawn
	collision_layer = 4    # enemy layer
	collision_mask = 1 | 4 # collide with world (1) and other enemies (4)

	# Capsule collider
	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.40; caps.height = 1.6
	cs.shape = caps
	cs.position.y = 0.9
	add_child(cs)

	# Hit area for player attacks (a slightly larger area than the body) — layer 4 (hitbox)
	var hit_area := Area3D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 4   # hitbox layer — player weapons scan this
	hit_area.collision_mask = 0
	add_child(hit_area)
	var hac := CollisionShape3D.new()
	var hcaps := CapsuleShape3D.new()
	hcaps.radius = 0.55; hcaps.height = 1.8
	hac.shape = hcaps
	hac.position.y = 0.9
	hit_area.add_child(hac)

	# Hurt area — the zone that deals contact damage to the player (separate from hitbox) — layer 5 (hurtbox)
	# Keeping hitbox and hurtbox as separate Area3D nodes means weapons and
	# contact-damage zones can be tuned independently and never interfere.
	var hurt_area := Area3D.new()
	hurt_area.name = "HurtBox"
	hurt_area.collision_layer = 5   # hurtbox layer — enemy contact damage zone
	hurt_area.collision_mask = 2    # scan player layer (2) for contact overlap
	hurt_area.monitoring = true
	hurt_area.monitorable = true
	add_child(hurt_area)
	var hbc := CollisionShape3D.new()
	var hbcaps := CapsuleShape3D.new()
	hbcaps.radius = 0.42; hbcaps.height = 1.6   # slightly tighter than hitbox — only close contact
	hbc.shape = hbcaps
	hbc.position.y = 0.9
	hurt_area.add_child(hbc)

	# Visual model
	_spawn_model()

	# Floating name label
	_label = Label3D.new()
	_label.text = enemy_name
	_label.font_size = 22
	_label.outline_size = 4
	_label.outline_modulate = Color(0, 0, 0)
	_label.modulate = Color(1.0, 0.55, 0.45) if enemy_kind == "goblin" else Color(0.85, 0.85, 1.0)
	_base_label_color = _label.modulate  # REFINE: combat-feel — cache base for telegraph reset
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.1, 0)
	_label.no_depth_test = true
	add_child(_label)

	# Floating HP bar (a billboard plane that scales)
	_hp_bar = _make_hp_bar()
	add_child(_hp_bar)

	_pick_wander_target()

func _spawn_model() -> void:
	if _model:
		_model.queue_free()
	# THEME §4: prefer a per-kind hand-crafted GLB (assets/models/enemies/) when present;
	# fall back to the @export'd placeholder for kinds we haven't sourced yet.
	var kind_scene: PackedScene = _get_kind_model(enemy_kind)
	var src: PackedScene = kind_scene if kind_scene != null else enemy_model
	var uses_real_model: bool = kind_scene != null
	_model = src.instantiate()
	# 2026-05-08: multiply the import's root_scale rather than replacing it.
	# Actor-pack GLBs are cm-unit with root_scale=0.01 baked in; assigning an
	# absolute scale like 0.85 inflated them to ~153 m, then _normalize clamped
	# at 0.05 left them stuck at ~9 m.  These values are now *relative* factors.
	var kind_mult := Vector3(1.0, 1.0, 1.0)
	match enemy_kind:
		"goblin":
			kind_mult = Vector3(0.85, 0.85, 0.85)
		"wolf":
			kind_mult = Vector3(0.70, 0.70, 1.05)
			_model.rotation.x = -PI / 2  # quadruped
		"bandit":
			kind_mult = Vector3(1.05, 1.05, 1.05)
		"skeleton":
			kind_mult = Vector3(1.00, 1.05, 1.00)
		"crystal_elemental":
			kind_mult = Vector3(1.10, 1.20, 1.10)
		"crystal_guardian":
			kind_mult = Vector3(1.55, 1.65, 1.55)
	_model.scale = _model.scale * kind_mult
	add_child(_model)
	var _norm_target: float = _NORMALIZE_TARGET_BY_KIND.get(enemy_kind, 1.55)
	call_deferred("_normalize_to_height", _model, _norm_target)
	# Kill any autoplay animation immediately after add_child so the mixer
	# never fires bone-path tracks that can't resolve in this scene tree.
	# (Mixamo / humanoid GLBs often have 'humanoid/yes' or 'humanoid/no' set
	# as the autoplay clip; those tracks reference full paths like
	# 'humanoid_canonical/Skeleton3D:mixamorig_*' which break when the GLB
	# is instantiated as a child with a different root name.)
	call_deferred("_stop_model_autoplay", _model)
	# Real fantasy models carry their own painted textures — applying a tint
	# would muddy them.  For fallback placeholders, apply the EnemyVariant
	# spatial shader so each instance gets a unique hue-brightness, emissive
	# eye-glow, and a per-frame-decay damage_flash without material swapping.
	if not uses_real_model:
		_apply_variant_shader()
	else:
		# Auto-play idle animation if the model carries one (e.g. goblin_scout.glb has IdleAnimation).
		call_deferred("_play_model_idle_anim")

# ==========================================================================
# EnemyVariant shader — applied to placeholder (non-GLB) models only.
# Creates a single ShaderMaterial, sets per-instance randomised uniforms,
# then defers propagating it to all MeshInstance3D children so the scene
# tree is fully ready before we walk it.
# ==========================================================================
# ==========================================================================
# Procedural stats — tie visual brightness to combat feel
# ==========================================================================
func randomize_stats_from_visuals() -> void:
	# Visual brightness drives combat stats so the visual read IS the tactical
	# read — kids spot a threat before they analyse its numbers:
	#   Bright (>1.09): vivid tint → faster, more aggressive, slightly squishier.
	#   Dark  (<0.89):  muted tint → slower, more cautious, tankier.
	# Stat changes are applied to the @export values so faction-pressure cooldown
	# (already resolved above in _resolve_adaptive_cooldown) is untouched.
	var b := _variant_brightness
	move_speed  = maxf(1.4, move_speed  * b)
	chase_speed = maxf(2.2, chase_speed * b)
	# Inverse HP scaling: bright = squishier (fast but fragile); dark = tanky.
	max_hp = maxi(6, int(float(max_hp) * (2.0 - b)))
	hp     = max_hp   # keep current HP in sync (called before combat starts)
	# Set behavior archetype — used by utility AI to tune retreat threshold
	# and adaptation speed without touching the core decision scoring.
	if b > 1.09:
		_behavior_type = "aggressive"
	elif b < 0.89:
		_behavior_type = "defensive"
	else:
		_behavior_type = "balanced"

func _apply_variant_shader() -> void:
	# Uses _variant_brightness generated in _ready() rather than its own RNG
	# so the shader colour and combat stats always match the same seed.
	var b := _variant_brightness
	var mat := ShaderMaterial.new()
	mat.shader = ENEMY_VARIANT_SHADER
	# variant_color: tint scaled by brightness (clamped to valid colour range).
	mat.set_shader_parameter("variant_color",
		Color(clampf(tint.r * b, 0.0, 1.0),
		      clampf(tint.g * b, 0.0, 1.0),
		      clampf(tint.b * b, 0.0, 1.0), 1.0))
	# emissive_color: per-kind lore glow (eye zone at UV.y ≈ 0.85).
	mat.set_shader_parameter("emissive_color",    _get_kind_emissive())
	mat.set_shader_parameter("emissive_strength", 0.35)
	# Derive roughness and time_offset from the same brightness seed so no
	# second RNG call is needed — slight algebraic scatter is enough.
	mat.set_shader_parameter("roughness",   clampf(0.75 - (b - 1.0) * 0.2, 0.55, 0.90))
	mat.set_shader_parameter("time_offset", b * TAU)   # unique per instance, no RNG
	mat.set_shader_parameter("damage_flash",  0.0)
	mat.set_shader_parameter("attack_flash",  0.0)
	mat.set_shader_parameter("dissolve",      0.0)
	_variant_shader_mat = mat
	# Defer so the instantiated GLB sub-tree is fully parented before we walk it.
	call_deferred("_apply_shader_to_meshes", _model, mat)

func _get_kind_emissive() -> Color:
	# Each enemy kind's "eye glow" colour supports the lore read at a glance.
	# Watchers: spectral blue (alien, watchful).  Drifters: amber rot (undead).
	# Scouts: electric green (fast, dangerous).  Defaults mirror the orange
	# used by the shader's built-in emissive_color default.
	match enemy_kind:
		"watcher":                       return Color(0.35, 0.70, 1.00)  # spectral blue
		"drifter":                        return Color(1.00, 0.50, 0.10)  # amber rot
		"reactive_scout":                 return Color(0.25, 1.00, 0.40)  # electric green
		"goblin", "goblin_scout":         return Color(0.20, 0.90, 0.25)  # sickly goblin green
		"skeleton":                       return Color(0.80, 0.80, 1.00)  # pale undead blue-white
		"bandit", "bandit_captain":       return Color(1.00, 0.40, 0.20)  # fire-orange outlaw
		"crystal_elemental", "crystal_guardian": return Color(0.30, 0.60, 1.00)  # crystal blue
		_:                                return Color(1.00, 0.40, 0.10)  # warm orange fallback

func _apply_shader_to_meshes(node: Node, mat: ShaderMaterial) -> void:
	# Recursively set material_override on every MeshInstance3D so the shader
	# covers multi-mesh GLB hierarchies (e.g. separate body / clothing meshes).
	if not is_instance_valid(node):
		return
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_shader_to_meshes(child, mat)

func _stop_model_autoplay(model: Node) -> void:
	# Called one deferred frame after add_child so any autoplay the GLB
	# has baked in is immediately stopped before its tracks are evaluated.
	# Humanoid retarget GLBs (Mixamo) often have 'humanoid/yes' as autoplay;
	# their tracks reference full scene-tree paths that break when the model
	# is used as a child node rather than the scene root — producing the
	# "couldn't resolve track: humanoid_canonical/Skeleton3D:mixamorig_*"
	# spam in the HTML5 console.
	if not is_instance_valid(model): return
	var ap: AnimationPlayer = _find_animation_player(model)
	if ap == null: return
	ap.stop()   # silence whatever autoplay fired; _play_model_idle_anim replaces it

func _play_model_idle_anim() -> void:
	# Retry up to 5 frames (model sub-tree may not be fully ready frame 0).
	# Always calls ap.stop() first — belt-and-suspenders against autoplay
	# animations that fire before this deferred call runs (the dedicated
	# _stop_model_autoplay handles the first frame; this guards later retries).
	#
	# Bad-animation skip list (generates unresolvable bone-path warnings):
	#   humanoid/yes, humanoid/no, humanoid/wave — Mixamo humanoid retarget clips
	#   any name starting with "humanoid/" that isn't idle / walk / run
	for _attempt in 5:
		await get_tree().process_frame
		if not is_instance_valid(_model): return
		var ap: AnimationPlayer = _find_animation_player(_model)
		if ap == null: continue
		ap.stop()   # ensure nothing bad is still playing from a previous frame
		# ── Priority 1: exact known-good idle names ───────────────────────
		for n in ["IdleAnimation", "Idle", "idle", "ANIM_Idle", "Armature|Idle",
				"humanoid/Idle", "humanoid/idle", "mixamo_com"]:
			if ap.has_animation(n):
				ap.play(n)
				return
		var names := ap.get_animation_list()
		# ── Priority 2: any name containing "idle" ────────────────────────
		for n in names:
			if "idle" in n.to_lower():
				ap.play(n)
				return
		# ── Priority 3: anything that isn't a known-bad gesture ──────────
		# Skip: humanoid/yes, humanoid/no, humanoid/wave and any variant.
		# These retarget animations reference root-relative bone paths
		# (humanoid_canonical/Skeleton3D:mixamorig_*) that can't resolve when
		# the GLB is instantiated as a child node rather than the scene root.
		for n in names:
			var nl := n.to_lower()
			if "wave" in nl or "/yes" in nl or "/no" in nl:
				continue
			# Also skip pure gesture/expression names even without a slash
			if nl in ["yes", "no", "wave", "thumbsup", "dying", "dance"]:
				continue
			ap.play(n)
			return

func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_animation_player(c)
		if found != null:
			return found
	return null

func _make_hp_bar() -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(0, 2.4, 0)
	# Background (red)
	var bg := MeshInstance3D.new()
	var bgm := StandardMaterial3D.new()
	bgm.albedo_color = Color(0.5, 0.06, 0.06)
	bgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bgm.no_depth_test = true
	bgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qm := QuadMesh.new()
	qm.size = Vector2(1.4, 0.14)
	bg.mesh = qm
	bg.material_override = bgm
	root.add_child(bg)
	# Foreground (green)
	var fg := MeshInstance3D.new()
	var fgm := StandardMaterial3D.new()
	fgm.albedo_color = Color(0.30, 0.85, 0.35)
	fgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fgm.no_depth_test = true
	fgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qmf := QuadMesh.new()
	qmf.size = Vector2(1.36, 0.10)
	fg.mesh = qmf
	fg.material_override = fgm
	fg.name = "HPFill"
	fg.position.z = 0.001
	root.add_child(fg)
	return root

func _update_hp_bar() -> void:
	if not _hp_bar: return
	var fill := _hp_bar.get_node_or_null("HPFill")
	if not fill: return
	var ratio := float(hp) / float(max_hp)
	fill.scale.x = max(0.001, ratio)
	# Hide HP bar at full HP for cleaner look
	_hp_bar.visible = (hp < max_hp and hp > 0)
	# REFINE: combat-feel — HP bar color progression. THEME §3 fantasy-warm palette.
	# Green (ratio > 0.60) → yellow (0.30–0.60) → red (<0.30). Smooth lerp so
	# there is no two-state pop — Alden reads "almost dead" at a glance; Owen gets
	# tactical press/retreat intel. Warm red keeps within fantasy-warm range (no
	# pure red). Uses the HPFill material_override already set at build time.
	if fill.material_override:
		var mat := fill.material_override as StandardMaterial3D
		if mat:
			var hp_color: Color
			if ratio > 0.60:
				# full health green → mid yellow: lerp in upper band
				var t: float = (ratio - 0.60) / 0.40  # 1.0 at full, 0.0 at 0.60
				hp_color = Color(0.30, 0.85, 0.35).lerp(Color(0.95, 0.85, 0.10), 1.0 - t)
			elif ratio > 0.30:
				# mid yellow → danger orange: lerp in mid band
				var t: float = (ratio - 0.30) / 0.30  # 1.0 at 0.60, 0.0 at 0.30
				hp_color = Color(0.95, 0.85, 0.10).lerp(Color(0.90, 0.20, 0.10), 1.0 - t)
			else:
				# danger orange → critical red: lerp in low band
				var t: float = ratio / 0.30  # 1.0 at 0.30, 0.0 at 0
				hp_color = Color(0.90, 0.20, 0.10).lerp(Color(0.80, 0.10, 0.05), 1.0 - t)
			mat.albedo_color = hp_color

func _process(delta: float) -> void:
	# REFINE: character — THEME §12 MOTION & LIFE. Dual-harmonic Y-bob breathing
	# while in wander/idle state. Mirrors NPC.gd line 294's pattern exactly:
	#   primary  2.513 rad/s  (~0.40 Hz) — slow chest-rise,  ±0.018 m
	#   secondary 10.982 rad/s (~1.75 Hz) — fast shoulder-shift, ±0.006 m
	# Both frequencies are irrational multiples; the combined waveform never
	# repeats within a 60s window (same design principle as the run-25 NPC bob).
	# Skip while chasing / attacking / dead — only the dwell-pause between
	# wander steps reads as "standing still enough to breathe." Skip while
	# actively moving (to_target length > arrival_radius) is handled naturally:
	# _physics_process owns global_position.y during movement via move_and_slide;
	# the breathe bob only writes .y when the body is at rest.
	if _state == "wander" and _spawn_y != INF:
		var t := Time.get_ticks_msec() * 0.001  # seconds, monotonic
		# REFINE: character — wolves skip the bob (quadruped — body-rock is the
		# right motion, but that requires animation-layer access; Y-bob on a
		# four-legged model reads as floating). Crystal Guardian is a gargantuan
		# boss (4.00m) — at that scale ±0.018m is invisible; skip for cleanliness.
		if enemy_kind != "wolf" and enemy_kind != "crystal_guardian":
			var bob: float = sin(t * 2.513 + _breathe_phase) * 0.018 \
				+ sin(t * 10.982 + _breathe_phase2) * 0.006
			global_position.y = _spawn_y + bob
	# REFINE: combat-feel — THEME §12 MOTION & LIFE. Attack telegraph windup.
	# When the enemy is in attack state and the attack_timer is counting down,
	# the floating name label lerps from its base color toward warm-orange
	# (Color 0.98, 0.38, 0.18) in the 0.22s window before the swing lands.
	# This gives Alden (9yo) a readable "danger flash" cue and lets Owen (11yo)
	# time a dodge. The label resets to _base_label_color in non-attack states
	# so a broken-off windup never leaves the name stuck orange.
	# _attack_charge_timer counts UP while in attack state (reset on each swing);
	# it measures the gap since the last attack fired, not the cooldown itself.
	if not _label: return
	if _state == "attack" and _attack_timer > 0.0:
		_attack_charge_timer += delta
		# windup_window: the last 0.22s of the cooldown is the "telegraph zone"
		var windup_window: float = 0.22
		var time_to_swing: float = _attack_timer  # counts down toward 0
		if time_to_swing <= windup_window:
			# t=0 when swing is 0.22s away, t=1 when swing lands
			var t: float = 1.0 - (time_to_swing / windup_window)
			_label.modulate = _base_label_color.lerp(Color(0.98, 0.38, 0.18), t)
		else:
			_label.modulate = _base_label_color
	else:
		# chase / wander / dead — always reset telegraph color
		_attack_charge_timer = 0.0
		_label.modulate = _base_label_color

func _physics_process(delta: float) -> void:
	if _state == "dead":
		return

	# EnemyVariant shader: per-frame uniform updates.
	# Guard on _variant_shader_mat so real-GLB enemies skip entirely.
	if _variant_shader_mat:
		# Damage flash decay (rate 6.0×/s — red flash on hit)
		var flash: float = float(_variant_shader_mat.get_shader_parameter("damage_flash"))
		if flash > 0.0:
			_variant_shader_mat.set_shader_parameter("damage_flash",
				maxf(0.0, flash - delta * 6.0))
		# Attack flash decay (rate 5.0×/s — orange telegraph on swing)
		var atk_flash: float = float(_variant_shader_mat.get_shader_parameter("attack_flash"))
		if atk_flash > 0.0:
			_variant_shader_mat.set_shader_parameter("attack_flash",
				maxf(0.0, atk_flash - delta * 5.0))
		# HP-ratio glow: emissive_strength rises from 0.35 at full HP to 1.5 near
		# death — enemies literally glow more as they get desperate.  Both a visual
		# threat cue ("this one is almost dead, press the advantage") AND a survival
		# signal ("this one is fading — feel that").
		var hp_ratio := float(hp) / float(max_hp)
		_variant_shader_mat.set_shader_parameter("emissive_strength",
			clampf(0.35 + (1.0 - hp_ratio) * 1.15, 0.35, 1.5))

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

	# Apply knockback — decays exponentially each frame so the slide is physical
	if _knockback_vel.length() > 0.05:
		velocity.x += _knockback_vel.x
		velocity.z += _knockback_vel.z
		_knockback_vel = _knockback_vel.lerp(Vector3.ZERO, 14.0 * delta)

	# Stagger — while timer is live, skip AI logic entirely (enemy stands stunned)
	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
		move_and_slide()
		return

	# Find player
	if not _player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
		else:
			# Fallback: search for the Player node
			_player = get_tree().current_scene.get_node_or_null("Player")
	if not _player:
		_idle_drift(delta)
		move_and_slide()
		return

	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()

	_attack_timer = max(0.0, _attack_timer - delta)

	# ── Adaptive behaviour tick ────────────────────────────────────────────
	var adapt_interval: float = 2.0 if _reactive_mode else ENEMY_ADAPT_INTERVAL
	_adapt_timer += delta
	if _adapt_timer >= adapt_interval:
		_adapt_timer = 0.0
		_adapt_to_player()

	# ── Watcher bolt cooldown ───────────────────────────────────────────────
	if _ranged_mode and _bolt_timer > 0.0:
		_bolt_timer = maxf(0.0, _bolt_timer - delta)

	# ── Detection / Utility AI ─────────────────────────────────────────────
	# Only run LoS check when player is close enough to matter (perf guard).
	_in_los = dist < aggro_range and _check_line_of_sight()
	# Reactive scouts detect the player more than twice as fast — they're
	# designed to read and respond, so they can't be "snuck up on" as easily.
	var effective_detect_rate := 40.0 if _reactive_mode else DETECT_RATE
	if _in_los:
		detection_level = minf(detection_level + effective_detect_rate * delta, DETECT_MAX)
		blackboard["last_seen_pos"] = _player.global_position
	else:
		detection_level = maxf(detection_level - DETECT_DECAY * delta, 0.0)
		if detection_level <= 0.0:
			blackboard.erase("last_seen_pos")  # fully lost — give up the hunt

	var action := _utility_action(dist)

	if action == "attack":
		_state = "attack"
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _attack_timer <= 0:
			_do_attack()
	elif action == "chase":
		_state = "chase"
		# If we have LoS chase the real position; otherwise hunt the last known pos
		var chase_pos: Vector3 = _player.global_position if _in_los \
			else blackboard.get("last_seen_pos", _player.global_position)
		var to_target := chase_pos - global_position
		to_target.y = 0
		if to_target.length() > 0.5:
			var dir := to_target.normalized()
			velocity.x = dir.x * chase_speed
			velocity.z = dir.z * chase_speed
			_face_target(to_target, delta)
		else:
			# Reached last-known position but player not visible — abandon
			velocity.x = 0; velocity.z = 0
			if not _in_los:
				blackboard.erase("last_seen_pos")
	elif action == "watcher_range":
		_state = "chase"
		# Strafe to keep ideal distance — advance if too far, retreat if too close
		var dist_now := to_player.length()
		if dist_now > WATCHER_IDEAL_DIST + 1.5:
			var dir := to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		elif dist_now < WATCHER_IDEAL_DIST - 1.5:
			var dir := -to_player.normalized()
			velocity.x = dir.x * chase_speed
			velocity.z = dir.z * chase_speed
		else:
			velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _bolt_timer <= 0.0:
			_bolt_timer = WATCHER_SHOOT_CD
			_fire_watcher_bolt()
	elif action == "retreat":
		_state = "wander"
		# Flee back toward spawn at full chase speed
		var to_spawn := _spawn_pos - global_position
		to_spawn.y = 0
		if to_spawn.length() > 1.0:
			var dir := to_spawn.normalized()
			velocity.x = dir.x * chase_speed
			velocity.z = dir.z * chase_speed
			_face_target(to_spawn, delta)
		else:
			velocity.x = 0; velocity.z = 0
	else:
		# ── Inter-faction engagement ──────────────────────────────────────────
		# If wandering AND a hostile faction enemy is nearby, engage them instead.
		if is_instance_valid(_faction_target) and _state == "wander":
			var to_ft := _faction_target.global_position - global_position
			to_ft.y = 0
			var ft_dist := to_ft.length()
			if ft_dist <= attack_range:
				# In range — attack the faction enemy
				_state = "attack"
				velocity.x = 0; velocity.z = 0
				_face_target(to_ft, delta)
				if _attack_timer <= 0:
					# Reuse the attack logic — faction enemies take the same damage call.
					if _faction_target.has_method("take_damage"):
						_faction_target.take_damage(damage, self)
					_attack_timer = attack_cooldown
			elif ft_dist <= aggro_range * 1.2:
				# Chase the faction enemy
				_state = "chase"
				var dir2 := to_ft.normalized()
				velocity.x = dir2.x * move_speed
				velocity.z = dir2.z * move_speed
				_face_target(to_ft, delta)
			else:
				_faction_target = null   # lost them
				_idle_drift(delta)
		else:
			_idle_drift(delta)

	move_and_slide()

func _face_target(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001:
		return
	var target_basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, 8.0 * delta)

func _idle_drift(delta: float) -> void:
	_state = "wander"
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_wander_target()
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0
	if to_target.length() < 0.5:
		velocity.x = 0; velocity.z = 0
		return
	var dir := to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face_target(to_target, delta)

func _pick_wander_target() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var ang := rng.randf() * TAU
	var dist := rng.randf_range(2.0, 7.0)
	_wander_target = _spawn_pos + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
	_wander_timer = rng.randf_range(2.0, 5.0)

func _fire_watcher_bolt() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var bolt := Area3D.new()
	bolt.set_script(WATCHER_BOLT_SCRIPT)
	bolt.global_position = global_position + Vector3(0, 1.0, 0)
	get_tree().current_scene.add_child(bolt)
	var dir := (_player.global_position + Vector3(0, 0.9, 0)) - bolt.global_position
	bolt.launch(dir.normalized(), damage, self)

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	# ── Attack telegraph flash — orange pulse just before damage ──────────────
	if _variant_shader_mat:
		_variant_shader_mat.set_shader_parameter("attack_flash", 1.0)
		# attack_flash decays in _physics_process at the same rate as damage_flash
	if _player and _player.has_method("take_damage"):
		var dmg := damage
		# Adaptation: anti-air — bonus 40% damage when player is airborne
		if blackboard.get("anti_air", false) and not _player.is_on_floor():
			dmg = int(dmg * 1.40)
		_player.take_damage(dmg, self)   # pass self so Player tracks _last_attacker for NemesisSystem
		# ── Directional camera shove toward impact ────────────────────────────
		var dir := (_player.global_position - global_position).normalized()
		if is_instance_valid(Juice):
			Juice.directional_shake(dir, 0.10)
		# REFINE: combat-feel — heavier knockback (3.0 → 4.5) for a more readable "hit" beat. Adds breathing space too.
		_player.velocity += dir * 4.5

# ──────────────────────────────────────────────────────────────────────────
# Take damage from player
# ──────────────────────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead":
		return
	hp = max(0, hp - amount)
	_update_hp_bar()
	_spawn_damage_number(amount, false)

	# ── Stagger tier (determines how long AI pauses) ───────────────────────
	if amount >= 20:
		_stagger_timer = 0.55   # heavy: full knockstun
	elif amount >= 8:
		_stagger_timer = 0.25   # medium: brief stagger
	# else light (<8): no stagger, enemy keeps chasing

	# ── Knockback — push away from the attacker ────────────────────────────
	if source and is_instance_valid(source):
		var kb: Vector3 = global_position - source.global_position
		kb.y = 0
		if kb.length() > 0.001:
			var kb_strength: float = 6.0 if amount < 20 else 9.0   # heavier hit = more fly
			_knockback_vel = kb.normalized() * kb_strength

	# ── Hit flash — squash-and-stretch + red colour feedback ─────────────
	# Squash tween works on any Node3D.  Colour feedback uses one of two paths:
	#   • EnemyVariant shader active → set damage_flash=1.0 uniform and let
	#     _physics_process decay it at 6×/s — no material swap, no allocation.
	#   • Real GLB model → _flash_hurt_color() temporarily overrides materials.
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.18, 0.82, 1.18), 0.055).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector3(1.0,  1.0,  1.0),  0.12).set_trans(Tween.TRANS_ELASTIC)
	if _variant_shader_mat:
		_variant_shader_mat.set_shader_parameter("damage_flash", 1.0)
	else:
		_flash_hurt_color()

	# ── Juice feedback — scale with hit weight ────────────────────────────
	# hit_stop_tier re-entry logic handles duplicates (Player.gd may call it too).
	# Screen flash only on heavy hits so small pokes don't fatigue the player.
	if is_instance_valid(Juice):
		Juice.hit_stop_tier(amount)
		if amount >= 25:
			Juice.screen_flash(Color(1.0, 0.30, 0.20, 0.18), 0.15)

	# Aggro the attacker if not already chasing
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _flash_hurt_color() -> void:
	# Temporarily set a red override on all MeshInstance3D children, then restore.
	# Using material_override means no shader edits needed — StandardMaterial3D only.
	var meshes: Array = _collect_mesh_instances(self)
	if meshes.is_empty():
		return
	var flash := StandardMaterial3D.new()
	flash.albedo_color            = Color(1.0, 0.15, 0.15)
	flash.emission_enabled        = true
	flash.emission                = Color(1.0, 0.0, 0.0)
	flash.emission_energy_multiplier = 1.2
	var originals: Array = []
	for mi: MeshInstance3D in meshes:
		originals.append(mi.material_override)
		mi.material_override = flash
	await get_tree().create_timer(0.10).timeout
	for i: int in meshes.size():
		if is_instance_valid(meshes[i]):
			(meshes[i] as MeshInstance3D).material_override = originals[i]

func _collect_mesh_instances(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_collect_mesh_instances(child))
	return result

func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var dn := Label3D.new()
	dn.set_script(DAMAGE_NUMBER_SCRIPT)
	dn.text = ("%d!" % amount) if is_crit else str(amount)
	# REFINE: combat-feel — chunkier font + warmer crit gold + brighter normal hit so damage reads at a glance.
	dn.font_size = 62 if is_crit else 44
	dn.outline_size = 7
	dn.outline_modulate = Color(0, 0, 0)
	dn.modulate = Color(1.0, 0.88, 0.22) if is_crit else Color(1.0, 0.72, 0.32)
	dn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dn.no_depth_test = true
	dn.position = global_position + Vector3(randf_range(-0.3, 0.3), 1.8, randf_range(-0.3, 0.3))
	get_tree().current_scene.add_child(dn)

func _die(source: Node) -> void:
	_state = "dead"
	get_tree().call_group("world", "play_sfx", "enemy_death")
	# ── Dissolve death animation ──────────────────────────────────────────────
	# Shader-based crumble for fallback capsule enemies; instant hide for GLBs.
	# Both paths hide bars and label immediately (they aren't part of the model).
	if _hp_bar: _hp_bar.visible = false
	if _label:  _label.visible  = false
	if _variant_shader_mat and _model:
		# Animate dissolve 0→1 over 0.45s then hide the model
		var tw := create_tween()
		tw.tween_method(
			func(v: float) -> void:
				if is_instance_valid(_variant_shader_mat):
					_variant_shader_mat.set_shader_parameter("dissolve", v),
			0.0, 1.0, 0.45
		).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void:
			if is_instance_valid(_model): _model.visible = false)
	elif _model:
		_model.visible = false
	# Drop loot — XP/gold to player
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	# Roll item loot from drop table — equipment may roll affix variants
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var drops = Items.roll_loot(enemy_kind, rng)
	var world = get_tree().current_scene
	for d in drops:
		if source and source.get("inventory"):
			# 35% chance equipment becomes an affix variant for richer loot
			var base = Items.get_item(d.id)
			if base.has("slot") and base.slot != "" and rng.randf() < 0.35:
				var affix = Items.generate_affix_item(d.id, rng)
				if not affix.is_empty():
					if world and world.has_method("register_runtime_item"):
						world.register_runtime_item(affix)
					source.inventory.add_item(affix.runtime_id, 1)
					_spawn_loot_popup(affix, 1)
					continue
			source.inventory.add_item(d.id, d.qty)
			get_tree().call_group("world", "play_sfx", "loot_pickup")
			var item = Items.get_item(d.id)
			_spawn_loot_popup(item, d.qty)
	# Floating "+XP" popup
	var xp_pop := Label3D.new()
	xp_pop.set_script(DAMAGE_NUMBER_SCRIPT)
	xp_pop.text = "+%d XP" % xp_reward
	xp_pop.font_size = 36
	xp_pop.outline_size = 5
	xp_pop.outline_modulate = Color(0, 0, 0)
	xp_pop.modulate = Color(0.55, 0.95, 0.45)
	xp_pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	xp_pop.no_depth_test = true
	xp_pop.position = global_position + Vector3(0, 2.0, 0)
	get_tree().current_scene.add_child(xp_pop)
	died.emit(self)
	# ── Nemesis + narrative hooks ─────────────────────────────────────────────
	if is_instance_valid(NemesisSystem):
		NemesisSystem.on_enemy_defeated(self)
	if is_instance_valid(NarrativeSystem):
		var evt_data := {"faction": faction_id, "kind": enemy_kind}
		if nemesis_data != null:
			evt_data["nemesis"] = nemesis_data
		NarrativeSystem.record_event("enemy_killed", evt_data)
	# Notify quest system
	get_tree().call_group("quest_listeners", "on_enemy_killed", enemy_kind)
	# run-31 (Builder): set world flag when Crystal Guardian is slain so the
	# cave_delver achievement can fire. Uses call_group("world") so it degrades
	# gracefully when World.gd is not yet initialised (no crash on early test scenes).
	# THEME §1 "consequence is lived-in" — clearing the boss changes the world state.
	if enemy_kind == "crystal_guardian":
		get_tree().call_group("world", "set_world_flag", "crystal_guardian_slain", true)
		get_tree().call_group("world", "_check_achievements")
	# run-33: notify nearby NPCs — Backlog #8. THEME §1 §12.
	get_tree().call_group("world", "record_npc_defense_witness", global_position)
	# Schedule respawn
	await get_tree().create_timer(respawn_delay).timeout
	_respawn()

func _respawn() -> void:
	hp = max_hp
	global_position = _spawn_pos
	if _model: _model.visible = true
	if _label:
		_label.visible = true
		_label.modulate = _base_label_color  # REFINE: combat-feel — clear telegraph color on respawn
	_attack_charge_timer = 0.0
	_state = "idle"
	_player = null
	# Reset Utility AI state so the enemy starts fresh
	detection_level = 0.0
	_in_los         = false
	blackboard.clear()
	_update_hp_bar()

func _spawn_loot_popup(item: Dictionary, qty: int) -> void:
	if item.is_empty():
		return
	var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	var pop := Label3D.new()
	pop.set_script(DAMAGE_NUMBER_SCRIPT)
	pop.text = "+ %s%s" % [item.get("name", "?"), (" x%d" % qty) if qty > 1 else ""]
	pop.font_size = 28
	pop.outline_size = 5
	pop.outline_modulate = Color(0, 0, 0)
	pop.modulate = color
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test = true
	pop.position = global_position + Vector3(0, 2.4, 0)
	get_tree().current_scene.add_child(pop)

# ──────────────────────────────────────────────────────────────────────────
# Run-7: Adaptive attack cooldown (THIRD output on faction_pressure scalar).
# ──────────────────────────────────────────────────────────────────────────
# Reads `World.faction_pressure(faction_id)` once at spawn and lerps the
# enemy's attack_cooldown across the kid-tuned [1.05, 1.45] band. Pressure
# 1.0 (fresh save) → 1.45 (Alden's recovery valve). Pressure 0.0 (faction
# tamed) → 1.05 (Owen's mastery rung; the few survivors hit fast). Same
# fail-soft contract as WorldBuilder spawn density: missing world node,
# missing accessor, or unmapped kind ALL fall through to baseline — never
# crash. See SYSTEM_REGISTRY.md "Enemy Cooldown Schema" for the contract.
# ── Line-of-sight + Utility AI ────────────────────────────────────────────
func _check_line_of_sight() -> bool:
	if not _player or not is_instance_valid(_player):
		return false
	var space := get_world_3d().direct_space_state
	if not space:
		return false
	var from := global_position + Vector3(0, 0.9, 0)
	var to   := _player.global_position + Vector3(0, 0.9, 0)
	var q    := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1   # world geometry only — ignores other enemies
	q.exclude         = [get_rid()]
	return space.intersect_ray(q).is_empty()

func _adapt_to_player() -> void:
	# Read from the GameBrain singleton — no player reference needed here.
	# Ratios are scale-invariant so a 5-min session and a 2-hour session
	# react consistently to the same relative playstyle habits.
	var dash_r  := GameBrain.get_playstyle_ratio("dash_heavy")
	var air_r   := GameBrain.get_playstyle_ratio("airborne")
	var def_r   := GameBrain.get_playstyle_ratio("defensive")
	var agg_r   := GameBrain.get_playstyle_ratio("aggressive")

	# Dash-heavy player (>30% of all actions) → zone-denial awareness
	if dash_r > 0.30:
		blackboard["counter_dash"] = true
	else:
		blackboard.erase("counter_dash")

	# Airborne player (>25% of actions) → anti-air timing on swings
	if air_r > 0.25:
		blackboard["anti_air"] = true
	else:
		blackboard.erase("anti_air")

	# Passive/defensive ratio → tighten cooldown to punish passivity
	if def_r > 0.25 and agg_r < 0.15:
		attack_cooldown = maxf(ATTACK_COOLDOWN_MIN, attack_cooldown - 0.10)

	# Behavior-type modifier: aggressive enemies adapt faster (shorter interval
	# until next adapt tick); defensive types are content to wait and react less.
	# We shorten the remaining adapt timer rather than the interval constant so
	# the next tick fires sooner without permanently warpng the rhythm.
	if _behavior_type == "aggressive":
		_adapt_timer = maxf(0.0, _adapt_timer - 1.0)  # adapt fires ~1s sooner

	# ── Inter-faction scan ────────────────────────────────────────────────────
	# Only bother if we have a known faction and the player is not close.
	if not faction_id.is_empty() and _state == "wander":
		_scan_faction_targets()

func _scan_faction_targets() -> void:
	# Look for a nearby enemy from a hostile faction (secondary target).
	# Runs at adapt-tick rate — not every frame — so it's cheap.
	# Result is stored in _faction_target; the wander state uses it as an
	# engagement target when the player is out of aggro range.
	_faction_target = null
	if not is_instance_valid(FactionSystem):
		return
	var closest_dist := aggro_range * 1.4   # slightly wider than normal aggro
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == self or not is_instance_valid(candidate):
			continue
		var cand_faction: String = str(candidate.get("faction_id") if candidate.get("faction_id") != null else "")
		if cand_faction.is_empty() or cand_faction == faction_id:
			continue
		if not FactionSystem.is_hostile(faction_id, cand_faction):
			continue
		var d := global_position.distance_to(candidate.global_position)
		if d < closest_dist:
			closest_dist = d
			_faction_target = candidate as Enemy

func _utility_action(dist: float) -> String:
	# Score-based decision each frame.  Returns the highest-value action name.
	# Retreat threshold varies by behavior archetype (set from visual brightness):
	#   aggressive = fights until almost dead (0.10) — bright enemies press hard.
	#   defensive  = flees early            (0.30) — dark enemies value survival.
	#   balanced   = standard               (0.18)
	var retreat_hp: float = 0.10 if _behavior_type == "aggressive" else \
	                        0.30 if _behavior_type == "defensive"  else 0.18
	if float(hp) / float(max_hp) < retreat_hp and dist < aggro_range * 1.5:
		return "retreat"

	# Watcher: ranged stance — stay at ideal distance, never melee
	if _ranged_mode:
		if dist < WATCHER_FLEE_DIST:
			return "retreat"   # flee if player closes in
		if dist < aggro_range and (detection_level >= DETECT_THRESHOLD or _in_los):
			return "watcher_range"  # hold distance + fire bolts
		return "wander"

	# Attack: close enough to swing
	if dist <= attack_range:
		return "attack"
	# Chase: we have detection momentum OR we remember where the player was
	if detection_level >= DETECT_THRESHOLD or blackboard.has("last_seen_pos"):
		return "chase"
	return "wander"

func _register_as_nemesis_candidate() -> void:
	# Called deferred from _ready() so stats are fully resolved first.
	# Only director-spawned enemies (those in the "enemies" group and not
	# named bosses) are eligible for nemesis tracking.
	if not is_in_group("enemies"):
		return
	if is_instance_valid(NemesisSystem) and nemesis_data == null:
		NemesisSystem.register_enemy(self)

func _resolve_adaptive_cooldown() -> void:
	var faction_id: String = KIND_TO_FACTION.get(enemy_kind, "")
	if faction_id == "":
		return  # Unmapped kind (bandit, etc.) → baseline
	var world_node: Node = get_tree().get_first_node_in_group("world")
	if world_node == null or not world_node.has_method("faction_pressure"):
		return  # Older World.gd or world not yet ready → baseline
	var pressure: float = float(world_node.faction_pressure(faction_id))
	# pressure ∈ [0,1] guaranteed by World.apply_consequence's clamp, but
	# we re-clamp defensively in case a future writer bypasses the resolver.
	pressure = clamp(pressure, 0.0, 1.0)
	var resolved: float = lerp(ATTACK_COOLDOWN_BASELINE, ATTACK_COOLDOWN_MIN, 1.0 - pressure)
	resolved = clamp(resolved, ATTACK_COOLDOWN_MIN, ATTACK_COOLDOWN_BASELINE)
	assert(resolved >= ATTACK_COOLDOWN_MIN and resolved <= ATTACK_COOLDOWN_BASELINE,
		"Enemy.attack_cooldown out of contract band [1.05, 1.45]")
	attack_cooldown = resolved
	# Player-facing feedback (Rule 2.iii): visible ⚡ prefix on the floating
	# name when this enemy is agitated. Reads at a glance: "this one will
	# hit faster." Applied via enemy_name BEFORE the label is built later
	# in _ready(), so the label picks up the prefix automatically.
	if resolved < AGITATED_COOLDOWN_THRESHOLD:
		enemy_name = "⚡ " + enemy_name


# Per-kind normalize targets — scale-eng 2026-05-08.
# bandit_captain clamped 2.30→2.50 (canon boss floor; joins boss_silhouettes).
# Kinds not listed here use default 1.55m (medium enemy).
const _NORMALIZE_TARGET_BY_KIND := {
	# ── Gargantuan / boss ─────────────────────────────────────────────────────
	"crystal_guardian": 4.00, # SIZE_STANDARDS §2 gargantuan boss
	"goblin_warlord":   2.80, # SIZE_STANDARDS §2 boss-standard
	"bandit_captain":   2.50, # scale-eng 2026-05-08: boss floor 2.5m
	# ── Medium enemies (1.55m) — listed explicitly for clarity ───────────────
	"bandit":           1.55, # SIZE_STANDARDS §2 medium enemy — char-spec 2026-05-08
	"skeleton":         1.55, # SIZE_STANDARDS §2 medium enemy — char-spec 2026-05-08
	"crystal_elemental":1.55, # SIZE_STANDARDS §2 medium enemy — char-spec 2026-05-08
	# ── Small enemies (1.20m) ─────────────────────────────────────────────────
	"goblin":           1.20, # SIZE_STANDARDS §2 small enemy — char-spec 2026-05-08
	"goblin_scout":     1.20, # SIZE_STANDARDS §2 small enemy — char-spec 2026-05-08
	# ── Echoing Ruins archetypes ──────────────────────────────────────────────
	"drifter":          1.10, # shambling melee; smaller than goblin — feels weak
	"watcher":          1.40, # robed ranged; medium height for visual read
	"reactive_scout":   1.20, # nimble and small — reads as fast/dangerous
	# ── Quadrupeds ────────────────────────────────────────────────────────────
	"wolf":             1.00, # SIZE_STANDARDS §1 mount-adjacent quadruped
}

# Normalize 3D model scale so it ends up ~target_height tall.
# Prevents giants from Sketchfab GLBs with mixed units.
func _normalize_to_height(model: Node, target_height: float) -> void:
	# 2026-05-08: multiply the current scale rather than replacing it, so the
	# import root_scale is preserved as the baseline. Lower clamp floor to 0.001
	# so Actor-pack cm-unit models (correct world scale ≈ 0.01) are reachable.
	await get_tree().process_frame
	if not is_instance_valid(model): return
	var aabb := AABB()
	var has := false
	for c in model.find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	var correction: float = clamp(target_height / aabb.size.y, 0.001, 100.0)
	model.scale = model.scale * correction
