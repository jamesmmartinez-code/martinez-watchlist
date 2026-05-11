extends CharacterBody3D
class_name EchoKnight

# Realm of Eldoria — Echo Knight boss (Echoing Ruins level finale).
#
# The Echo Knight is the first boss that explicitly mirrors the player.
# It reads GameBrain ratios and blackboard dodge memory to adapt mid-fight
# in a way the player can *notice* — the boss TELLS them what it sees.
#
# Phase 0 — Observation  (100–60% HP): simple patterns, voice-reads player
# Phase 1 — Adaptation   (60–30% HP): counter-attacks match player habits
# Phase 2 — Punishment   (<30% HP):   instant prediction + enrage
#
# Spawn via EchoingRuins.gd _spawn_boss() or add to scene directly.

@export var max_hp: int = 300
@export var damage: int = 18
@export var move_speed: float = 3.5
@export var chase_speed: float = 6.0
@export var aggro_range: float = 20.0
@export var attack_range: float = 2.4
@export var xp_reward:  int = 450
@export var gold_reward: int = 180

var hp: int
var _state: String = "idle"
var _player: CharacterBody3D = null
var _gravity: float = 20.0
var _model: Node3D = null
var _label: Label3D = null
var _phase: int = 0          # 0, 1, 2
var _next_attack_t: float = 0.0
var _spawn_pos: Vector3
var _blackboard: Dictionary = {}   # dodge_left, dodge_right counters + flags

# ── Per-phase attack pool ──────────────────────────────────────────────────
var _attack_pool: Array = []

# ── Vulnerability window (reward after big attacks) ───────────────────────
var _vulnerability: bool = false
var _vuln_timer: float   = 0.0
const VULN_MULT:   float = 1.5
const VULN_WINDOW: float = 0.85

# ── Adapt timer ───────────────────────────────────────────────────────────
var _adapt_timer: float = 0.0
const ADAPT_INTERVAL: float = 4.0   # tighter than Boss.gd — Echo Knight reacts faster

signal died(boss)

const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")

# ── Echo Knight dialogue ───────────────────────────────────────────────────
# Keyed by moment — shown once per fight.
const LINES: Dictionary = {
	"intro":       "I see you, little one…",
	"first_blood": "Interesting technique.",
	"phase_1":     "I see your patterns NOW.",
	"counter_dash":"PREDICTABLE.",
	"counter_air": "Ground yourself, child.",
	"counter_spam":"You fight with your fists, not your mind.",
	"phase_2":     "YOU CANNOT CHANGE WHAT YOU ARE!",
	"low_hp":      "Still you stand?  Remarkable.",
}
var _spoken: Dictionary = {}   # tracks which lines have fired

func _ready() -> void:
	hp = max_hp
	_spawn_pos = global_position
	_attack_pool = ["_ek_melee", "_ek_lunge", "_ek_sweep"]
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 4
	collision_mask  = 1 | 4

	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.55; caps.height = 2.0
	cs.shape = caps; cs.position.y = 1.1
	add_child(cs)

	# Visual — a spectral silver knight (reuse Boss.glb until EchoKnight.glb ships)
	var src := load("res://assets/models/Boss.glb") as PackedScene
	if src:
		_model = src.instantiate()
		_model.scale = Vector3(1.2, 1.2, 1.2)
		add_child(_model)
		call_deferred("_normalize_model", _model, 2.4)

	# Name label
	_label = Label3D.new()
	_label.text = "✦ Echo Knight ✦"
	_label.font_size = 28
	_label.outline_size = 6
	_label.outline_modulate = Color(0, 0, 0)
	_label.modulate = Color(0.6, 0.8, 1.0)   # cool blue — distinct from Warlord red
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position  = Vector3(0, 3.0, 0)
	_label.no_depth_test = true
	add_child(_label)

	# Aura — cool blue shimmer
	var aura := OmniLight3D.new()
	aura.name      = "EchoAura"
	aura.light_color  = Color(0.4, 0.6, 1.0)
	aura.light_energy = 2.6
	aura.omni_range   = 14.0
	aura.position.y   = 1.4
	add_child(aura)

	# Intro sting after a short delay
	get_tree().create_timer(0.8).timeout.connect(_boss_intro)

func _boss_intro() -> void:
	_say("intro")
	get_tree().call_group("world", "play_sfx", "boss_intro")
	get_tree().call_group("world", "update_boss_hp_bar", hp, max_hp, "Echo Knight")
	UITheme.spawn_damage_popup(get_tree().current_scene,
		global_position + Vector3(0, 3.8, 0),
		"✦ The Echo Knight awakens ✦", Color(0.6, 0.8, 1.0), 52, 7)

# ── Physics ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _state == "dead":
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

	# Vulnerability tick
	if _vuln_timer > 0.0:
		_vuln_timer = maxf(0.0, _vuln_timer - delta)
		if _vuln_timer <= 0.0:
			_vulnerability = false

	# Adapt tick
	_adapt_timer += delta
	if _adapt_timer >= ADAPT_INTERVAL:
		_adapt_timer = 0.0
		_adapt_to_player()

	if not _player:
		var ps: Array[Node3D] = get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			_player = ps[0]
	if not _player:
		move_and_slide(); return

	# Phase transitions
	var hp_ratio := float(hp) / float(max_hp)
	if _phase == 0 and hp_ratio < 0.6:
		_enter_phase(1)
	elif _phase == 1 and hp_ratio < 0.30:
		_enter_phase(2)
	if hp_ratio < 0.15 and not _spoken.has("low_hp"):
		_say("low_hp")

	var to_player := _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()
	_next_attack_t -= delta

	# Observe dodge direction while in melee range
	if dist < attack_range + 1.5:
		_observe_dodge()

	if dist < attack_range:
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _next_attack_t <= 0.0 and not _attack_pool.is_empty():
			call(_attack_pool[randi() % _attack_pool.size()])
	elif dist < aggro_range:
		var dir := to_player.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_target(to_player, delta)
		if _next_attack_t <= 0.0 and dist < 8.0:
			_ek_lunge()

	move_and_slide()

# ── Phase system ──────────────────────────────────────────────────────────
func _enter_phase(p: int) -> void:
	_phase = p
	match p:
		1:
			# Adaptation phase — pool gains mirror attacks
			_say("phase_1")
			chase_speed += 0.8
			_attack_pool = ["_ek_melee", "_ek_lunge", "_ek_sweep", "_ek_mirror"]
			_open_vulnerability(1.2)   # brief opening as phase shift settles
			get_tree().call_group("world", "play_sfx", "boss_phase")
		2:
			# Punishment phase — fast, punishing, prediction attacks
			_say("phase_2")
			chase_speed += 1.2
			damage = int(damage * 1.25)
			_attack_pool = ["_ek_mirror", "_ek_predict", "_ek_sweep", "_ek_mirror", "_ek_predict"]
			_open_vulnerability(1.5)
			# Screen flash — cool blue for this boss
			if Juice.juice_enabled:
				Juice.screen_flash(Color(0.5, 0.7, 1.0, 0.6), 0.25)
			get_tree().call_group("world", "play_sfx", "boss_phase")

func _open_vulnerability(dur: float) -> void:
	_vulnerability = true
	_vuln_timer    = dur

# ── Adaptation ────────────────────────────────────────────────────────────
func _adapt_to_player() -> void:
	if _phase < 1:
		return   # phase 0 = observation only
	var agg_r  := GameBrain.get_playstyle_ratio("aggressive")
	var dash_r := GameBrain.get_playstyle_ratio("dash_heavy")
	var air_r  := GameBrain.get_playstyle_ratio("airborne")

	# Aggressive spammer → pool floods with counter_parry
	if agg_r > 0.40 and _attack_pool.count("_ek_parry") < 2:
		_attack_pool.append("_ek_parry")
		_say("counter_spam")
	# Dash-heavy → prediction attack targets dash landing
	if dash_r > 0.28 and _attack_pool.count("_ek_predict") < 2:
		_attack_pool.append("_ek_predict")
		_say("counter_dash")
	# Airborne → upward slam
	if air_r > 0.22 and _attack_pool.count("_ek_anti_air") < 2:
		_attack_pool.append("_ek_anti_air")
		_say("counter_air")
	# Cap pool
	while _attack_pool.size() > 8:
		_attack_pool.remove_at(0)

func _observe_dodge() -> void:
	if not _player or not is_instance_valid(_player):
		return
	var pv := Vector3(_player.velocity.x, 0, _player.velocity.z)
	if pv.length() < 0.3:
		return
	var dot := pv.normalized().dot(global_transform.basis.x)
	if dot > 0.35:
		_blackboard["dodge_right"] = _blackboard.get("dodge_right", 0) + 1
	elif dot < -0.35:
		_blackboard["dodge_left"] = _blackboard.get("dodge_left", 0) + 1

# ── Attack patterns ───────────────────────────────────────────────────────
func _ek_melee() -> void:
	_next_attack_t = 1.3
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)
		var d := (_player.global_position - global_position).normalized()
		_player.velocity += d * 5.0 + Vector3.UP * 2.0
		if Juice.juice_enabled:
			Juice.hit_stop_tier(damage)

func _ek_lunge() -> void:
	# Quick dash-lunge — telegraphed by a brief glow
	_next_attack_t = 3.0
	_show_telegraph_line(global_position, (-global_transform.basis.z).normalized(), 6.0, 0.55)
	await get_tree().create_timer(0.55).timeout
	if _state == "dead": return
	var dir := Vector3.ZERO
	if _player:
		dir = (_player.global_position - global_position); dir.y = 0; dir = dir.normalized()
	var t := 0.0
	while t < 0.4 and _state != "dead":
		velocity = dir * 14.0; velocity.y = -1.0
		move_and_slide()
		if _player and _player.global_position.distance_to(global_position) < 1.8:
			if _player.has_method("take_damage"):
				_player.take_damage(int(damage * 1.3))
				_player.velocity += dir * 7.0 + Vector3.UP * 2.5
				if Juice.juice_enabled:
					Juice.hit_stop_tier(int(damage * 1.3))
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	_open_vulnerability(VULN_WINDOW)

func _ek_sweep() -> void:
	# Wide AoE swing — ring telegraph, then damage all nearby
	_next_attack_t = 3.8
	_say_chance("first_blood")
	_show_telegraph_ring(global_position, 4.5, 0.80)
	await get_tree().create_timer(0.80).timeout
	if _state == "dead": return
	for p: Node3D in get_tree().get_nodes_in_group("player"):
		if p.global_position.distance_to(global_position) < 4.5:
			p.take_damage(int(damage * 1.2))
			var d := (p.global_position - global_position).normalized()
			p.velocity += d * 6.0 + Vector3.UP * 3.0
			if Juice.juice_enabled:
				Juice.hit_stop_tier(int(damage * 1.2))
				Juice.screen_flash(Color(0.5, 0.7, 1.0, 0.30), 0.14)
	_open_vulnerability(VULN_WINDOW)

func _ek_mirror() -> void:
	# Echo Knight mirrors the player's last used skill — dashes if they dashed,
	# uses a ranged bolt if they use Fireball, etc.
	_next_attack_t = 2.2
	var dominant := _dominant_style()
	match dominant:
		"dash_heavy":
			# Mirror dash → lunge right through them
			_ek_lunge()
		"airborne":
			# Mirror jump → AoE slam from above
			_ek_anti_air()
		_:
			# Default: mirror melee
			_ek_melee()

func _ek_predict() -> void:
	# Prediction attack: aims at player's likely next position based on dodge bias
	_next_attack_t = 2.8
	if not _player: return
	var angle_bias := 0.0
	var dl: int = _blackboard.get("dodge_left",  0)
	var dr: int = _blackboard.get("dodge_right", 0)
	if dl > dr + 3:   angle_bias = deg_to_rad(-22.0)
	elif dr > dl + 3: angle_bias = deg_to_rad( 22.0)
	var dir := (_player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized().rotated(Vector3.UP, angle_bias)
	_show_telegraph_line(global_position, dir, 7.0, 0.45)
	await get_tree().create_timer(0.45).timeout
	if _state == "dead": return
	# Rush in the predicted direction
	var t := 0.0
	while t < 0.5 and _state != "dead":
		velocity = dir * 16.0; velocity.y = -1.0; move_and_slide()
		if _player and _player.global_position.distance_to(global_position) < 2.0:
			_player.take_damage(int(damage * 1.5))
			_player.velocity += dir * 9.0 + Vector3.UP * 3.0
			if Juice.juice_enabled:
				Juice.hit_stop_tier(int(damage * 1.5))
				Juice.screen_flash(Color(0.5, 0.7, 1.0, 0.45), 0.18)
			break
		await get_tree().create_timer(0.05).timeout
		t += 0.05

func _ek_parry() -> void:
	# Parry window: if player attacks within next 0.6s, reflect damage
	_next_attack_t = 2.5
	_blackboard["parrying"] = true
	UITheme.spawn_damage_popup(get_tree().current_scene,
		global_position + Vector3(0, 3.0, 0), "⚡ PARRY!", Color(0.6, 0.8, 1.0), 40, 5)
	await get_tree().create_timer(0.60).timeout
	_blackboard.erase("parrying")

func _ek_anti_air() -> void:
	# Upward AoE — punishes aerial players
	_next_attack_t = 3.2
	_show_telegraph_ring(global_position, 4.0, 0.70)
	await get_tree().create_timer(0.70).timeout
	if _state == "dead": return
	for p: Node3D in get_tree().get_nodes_in_group("player"):
		if p.global_position.distance_to(global_position) < 4.5:
			p.take_damage(int(damage * 1.1))
			p.velocity += Vector3.UP * 8.0   # extra upward force — punishes air time
			if Juice.juice_enabled:
				Juice.hit_stop_tier(int(damage * 1.1))
	_open_vulnerability(VULN_WINDOW)

# ── Helpers ───────────────────────────────────────────────────────────────
func _dominant_style() -> String:
	var keys := ["aggressive", "airborne", "dash_heavy", "defensive"]
	var best := "aggressive"; var best_r := 0.0
	for k in keys:
		var r := GameBrain.get_playstyle_ratio(k)
		if r > best_r: best_r = r; best = k
	return best

func _face_target(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001: return
	global_transform.basis = global_transform.basis.slerp(
		Basis.looking_at(dir.normalized(), Vector3.UP), 8.0 * delta)

func _say(key: String) -> void:
	if _spoken.has(key) or not LINES.has(key):
		return
	_spoken[key] = true
	UITheme.spawn_damage_popup(get_tree().current_scene,
		global_position + Vector3(0, 4.0, 0), LINES[key], Color(0.6, 0.8, 1.0), 42, 6)
	get_tree().call_group("world", "_show_toast", LINES[key])

func _say_chance(key: String) -> void:
	if randf() > 0.4: return
	_say(key)

func _show_telegraph_ring(center: Vector3, radius: float, dur: float) -> void:
	var ring := MeshInstance3D.new()
	var pm   := PlaneMesh.new(); pm.size = Vector2(radius * 2.0, radius * 2.0)
	ring.mesh = pm
	var rm := StandardMaterial3D.new()
	rm.albedo_color  = Color(0.4, 0.6, 1.0, 0.68)
	rm.transparency  = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.emission_enabled = true; rm.emission = Color(0.4, 0.6, 1.0)
	rm.emission_energy_multiplier = 2.4; rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm
	ring.position = center + Vector3(0, 0.05, 0)
	get_tree().current_scene.add_child(ring)
	var t := create_tween(); t.tween_interval(dur); t.tween_callback(ring.queue_free)

func _show_telegraph_line(start: Vector3, dir: Vector3, length: float, dur: float) -> void:
	var line := MeshInstance3D.new()
	var pm   := PlaneMesh.new(); pm.size = Vector2(2.0, length)
	line.mesh = pm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.4, 0.6, 1.0, 0.68)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.emission_enabled = true; lm.emission = Color(0.4, 0.6, 1.0)
	lm.emission_energy_multiplier = 2.4; lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = lm
	line.position  = start + dir * (length * 0.5) + Vector3(0, 0.05, 0)
	line.rotation.y = atan2(dir.x, dir.z)
	get_tree().current_scene.add_child(line)
	var t := create_tween(); t.tween_interval(dur); t.tween_callback(line.queue_free)

func _normalize_model(model: Node, target_h: float) -> void:
	await get_tree().process_frame
	if not is_instance_valid(model): return
	var aabb := AABB(); var has := false
	for c in model.find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		var a := v.global_transform * v.get_aabb()
		if not has: aabb = a; has = true
		else: aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001: return
	model.scale = model.scale * clamp(target_h / aabb.size.y, 0.001, 10.0)

# ── Damage / death ─────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead": return
	# Parry: if parry window is active, reflect damage back to attacker
	if _blackboard.get("parrying", false) and source and source.has_method("take_damage"):
		source.take_damage(int(float(amount) * 1.5))
		UITheme.spawn_damage_popup(get_tree().current_scene,
			global_position + Vector3(0, 2.5, 0), "REFLECTED!", Color(0.6, 0.8, 1.0), 36, 5)
		return
	if _vulnerability:
		amount = int(float(amount) * VULN_MULT)
	hp = max(0, hp - amount)
	get_tree().call_group("world", "update_boss_hp_bar", hp, max_hp, "Echo Knight")
	UITheme.spawn_damage_popup(get_tree().current_scene,
		global_position + Vector3(randf_range(-0.3, 0.3), 2.4, randf_range(-0.3, 0.3)),
		str(amount), Color(0.8, 0.9, 1.0), 46, 6)
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _die(source: Node) -> void:
	_state = "dead"
	if _model: _model.visible = false
	if _label: _label.visible = false
	var aura := get_node_or_null("EchoAura")
	if aura: aura.visible = false
	get_tree().call_group("world", "hide_boss_hp_bar")
	get_tree().call_group("world", "_show_toast", "✦ Echo Knight slain! ✦")
	# Rewards
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	# Signal level flow controller that boss is down
	died.emit(self)
	# Quest / world flag
	get_tree().call_group("quest_listeners", "on_enemy_killed", "echo_knight")
	get_tree().call_group("world", "set_world_flag", "echo_knight_slain", true)
