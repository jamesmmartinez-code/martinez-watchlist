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

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")

signal died(enemy)

func _ready() -> void:
	hp = max_hp
	# Run-7: faction-pressure-driven attack cooldown. Resolved ONCE at spawn
	# (not per-frame) so combat hot path stays cheap. Mutates `attack_cooldown`
	# in-place — the existing _do_attack() path is untouched.
	_resolve_adaptive_cooldown()
	_spawn_pos = global_position
	_spawn_y = global_position.y
	# REFINE: character — randomise breathe phases so nearby enemies never sync.
	var _rng_breathe := RandomNumberGenerator.new(); _rng_breathe.randomize()
	_breathe_phase = _rng_breathe.randf() * TAU
	_breathe_phase2 = _rng_breathe.randf() * TAU
	add_to_group("enemies")
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
	# Real fantasy models carry their own painted textures — applying the
	# placeholder's green tint would muddy them. Tint only the fallback robot.
	if not uses_real_model:
		_model.call_deferred("propagate_call", "set", ["modulate", tint])
	else:
		# Auto-play idle animation if the model carries one (e.g. goblin_scout.glb has IdleAnimation).
		call_deferred("_play_model_idle_anim")

func _play_model_idle_anim() -> void:
	# 2026-05-08: retry up to 5 frames; added humanoid/* spellings; skip known
	# non-idle gestures (wave/yes/no) to avoid AnimationMixer bone-path warnings.
	for _attempt in 5:
		await get_tree().process_frame
		if not is_instance_valid(_model): return
		var ap: AnimationPlayer = _find_animation_player(_model)
		if ap == null: continue
		# Named candidates (broadened to include humanoid-library spellings)
		for n in ["IdleAnimation", "Idle", "idle", "ANIM_Idle", "Armature|Idle",
				"humanoid/Idle", "humanoid/idle", "mixamo_com"]:
			if ap.has_animation(n):
				ap.play(n)
				return
		# Prefer any name containing "idle"
		var names := ap.get_animation_list()
		for n in names:
			if "idle" in n.to_lower():
				ap.play(n)
				return
		# Last resort: skip wave / yes / no gestures
		for n in names:
			var nl := n.to_lower()
			if "wave" in nl or "/yes" in nl or "/no" in nl:
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
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

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

	if dist < attack_range:
		_state = "attack"
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _attack_timer <= 0:
			_do_attack()
	elif dist < aggro_range:
		_state = "chase"
		var dir := to_player.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_target(to_player, delta)
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

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)
		# REFINE: combat-feel — heavier knockback (3.0 → 4.5) for a more readable "hit" beat. Adds breathing space too.
		var dir := (_player.global_position - global_position).normalized()
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
	# Aggro the attacker if not already chasing
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

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
	# Hide model + bars
	if _model: _model.visible = false
	if _hp_bar: _hp_bar.visible = false
	if _label: _label.visible = false
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
