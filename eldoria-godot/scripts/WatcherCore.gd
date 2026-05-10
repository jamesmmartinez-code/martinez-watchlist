extends CharacterBody3D
class_name WatcherCore

# Realm of Eldoria — Watcher Core boss.
#
# Completely different feel from EchoKnight / Goblin Warlord:
#   • Floats — ignores gravity, smoothly tracks a height above the player.
#   • Ranged threat — fires bolt volleys, never melee-focuses.
#   • Zone control — expanding ring hazards and arena pressure.
#   • Drone spawner — summons Watcher enemies as orbital defenders.
#   • Slam spike — the only moment it descends: a punishing ground-slam
#     that opens a vulnerability window if the player dodges.
#
# Phase 0 — Patrol  (100–65% HP): single bolts, 1 drone, slow rings
# Phase 1 — Siege   (65–30% HP): volleys, 2 drones, faster rings
# Phase 2 — Overdrive (<30% HP): triple volley, 3 drones, eye-beam, frantic rings
#
# Attach BossPhase.gdshader to core_mesh for live phase-colour transitions.

@export var max_hp: int   = 420
@export var damage: int   = 14
@export var float_height: float = 4.5   # metres above the player's feet
@export var aggro_range: float   = 28.0
@export var xp_reward: int  = 550
@export var gold_reward: int = 220

# ── State ─────────────────────────────────────────────────────────────────
var hp: int
var _state: String = "idle"   # idle | patrol | combat | slam | dead
var _player: CharacterBody3D = null
var _phase: int = 0
var _attack_t: float = 0.0    # countdown to next attack
var _spawn_pos: Vector3

# ── Visual nodes (built in _ready) ───────────────────────────────────────
var _core_mesh: MeshInstance3D = null
var _ring_nodes: Array[Node3D] = []
var _label: Label3D = null
var _aura: OmniLight3D = null
var _core_shader: ShaderMaterial = null

# ── Drift floater (no CharacterBody gravity) ─────────────────────────────
var _float_vel_y: float = 0.0
const FLOAT_SPRING: float  = 6.0    # spring constant toward target height
const FLOAT_DAMPEN: float  = 0.55   # damping ratio — prevents oscillation

# ── Slam state ────────────────────────────────────────────────────────────
var _slamming: bool = false
var _slam_phase: String = ""   # "descend" | "impact" | "rise"

# ── Vulnerability window ──────────────────────────────────────────────────
var _vulnerability: bool  = false
var _vuln_timer:    float = 0.0
const VULN_MULT:   float = 1.5
const VULN_WINDOW: float = 1.2

# ── Adapt timer ───────────────────────────────────────────────────────────
var _adapt_t: float = 0.0
const ADAPT_INTERVAL: float = 5.0

# ── Attack pool ───────────────────────────────────────────────────────────
var _attack_pool: Array = []

signal died(boss)

const ENEMY_SCRIPT      = preload("res://scripts/Enemy.gd")
const WATCHER_BOLT_SCRIPT = preload("res://scripts/WatcherBolt.gd")
const BOSS_PHASE_SHADER = preload("res://shaders/BossPhase.gdshader")

# ── Voice lines ────────────────────────────────────────────────────────────
const LINES: Dictionary = {
	"intro":    "Target acquired. Processing…",
	"phase_1":  "Threat level elevated. Deploying countermeasures.",
	"phase_2":  "CRITICAL THRESHOLD. ALL SYSTEMS ENGAGE.",
	"drone":    "Defensive network active.",
	"slam":     "INITIATING GROUND STRIKE.",
	"low_hp":   "Core integrity failing. Must. Not. Stop.",
}
var _spoken: Dictionary = {}

# ==========================================================================
func _ready() -> void:
	hp = max_hp
	_spawn_pos = global_position
	_attack_pool = ["_wc_bolt", "_wc_bolt", "_wc_slam", "_wc_drone_spawn"]
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 4
	collision_mask  = 1 | 4

	# Capsule collider (smaller than ground bosses — it's a sphere core)
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new(); sp.radius = 0.9
	cs.shape = sp
	add_child(cs)

	_build_visuals()
	get_tree().create_timer(0.6).timeout.connect(_boss_intro)

# ==========================================================================
# Visual construction
# ==========================================================================
func _build_visuals() -> void:
	# ── Core sphere ─────────────────────────────────────────────────────────
	_core_mesh = MeshInstance3D.new()
	var sm     := SphereMesh.new(); sm.radius = 0.85; sm.height = 1.7
	_core_mesh.mesh = sm
	_core_shader = ShaderMaterial.new()
	_core_shader.shader = BOSS_PHASE_SHADER
	_core_shader.set_shader_parameter("phase",        0)
	_core_shader.set_shader_parameter("damage_flash", 0.0)
	_core_shader.set_shader_parameter("time_offset",  randf() * TAU)
	_core_shader.set_shader_parameter("color_phase0", Color(0.40, 0.65, 1.0))
	_core_shader.set_shader_parameter("color_phase1", Color(1.00, 0.55, 0.15))
	_core_shader.set_shader_parameter("color_phase2", Color(1.00, 0.12, 0.08))
	_core_mesh.material_override = _core_shader
	add_child(_core_mesh)

	# ── Three orbital rings at different tilts ──────────────────────────────
	var ring_tilts := [0.0, PI * 0.33, PI * 0.66]
	for tilt: float in ring_tilts:
		var ring_root := Node3D.new()
		ring_root.rotation.x = tilt
		add_child(ring_root)
		var ring_mi  := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 1.05
		ring_mesh.outer_radius = 1.25
		ring_mi.mesh = ring_mesh
		var ring_mat  := StandardMaterial3D.new()
		ring_mat.albedo_color              = Color(0.3, 0.55, 1.0, 0.85)
		ring_mat.emission_enabled          = true
		ring_mat.emission                  = Color(0.3, 0.55, 1.0)
		ring_mat.emission_energy_multiplier = 3.2
		ring_mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_mi.material_override = ring_mat
		ring_root.add_child(ring_mi)
		_ring_nodes.append(ring_root)

	# ── Label ──────────────────────────────────────────────────────────────
	_label = Label3D.new()
	_label.text               = "✦ Watcher Core ✦"
	_label.font_size          = 26
	_label.outline_size       = 6
	_label.outline_modulate   = Color(0, 0, 0)
	_label.modulate           = Color(0.40, 0.75, 1.0)
	_label.billboard          = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position           = Vector3(0, 2.2, 0)
	_label.no_depth_test      = true
	add_child(_label)

	# ── Aura light ──────────────────────────────────────────────────────────
	_aura = OmniLight3D.new()
	_aura.name          = "CoreAura"
	_aura.light_color   = Color(0.40, 0.65, 1.0)
	_aura.light_energy  = 3.0
	_aura.omni_range    = 16.0
	_aura.shadow_enabled = false
	add_child(_aura)

func _boss_intro() -> void:
	_say("intro")
	get_tree().call_group("world", "play_sfx", "boss_intro")
	get_tree().call_group("world", "update_boss_hp_bar", hp, max_hp, "Watcher Core")

	# ── Cinematic freeze + dramatic entrance ────────────────────────────────
	# Freeze player input for 1.8s so they watch the reveal, not mash buttons.
	if is_instance_valid(Juice):
		Juice.player_cinematic(1.80)
		Juice.screen_flash(Color(0.40, 0.70, 1.0, 0.70), 0.65)
		Juice.hit_stop(0.22)
		Juice.screen_shake(0.30, 0.50)
		Juice.camera_fov_punch(16.0, 0.50)
		Juice.show_notification("✦ The Watcher Core awakens ✦", Color(0.40, 0.80, 1.0))

	if UITheme and UITheme.has_method("spawn_damage_popup"):
		UITheme.spawn_damage_popup(get_tree().current_scene,
			global_position + Vector3(0, 3.5, 0),
			"✦ The Watcher Core activates ✦", Color(0.40, 0.75, 1.0), 50, 7)
	_state = "combat"

# ==========================================================================
# Physics — floating movement
# ==========================================================================
func _physics_process(delta: float) -> void:
	if _state == "dead":
		return

	# ── Phase-2 ambient tension — persistent subtle shake ──────────────────
	# Called every frame; Juice.screen_shake re-entry guard ensures only one
	# coroutine runs at a time.  Refreshes the shake timer so it persists as
	# long as we're in phase 2.  Stops naturally when calls cease (boss dies).
	if _phase >= 2 and is_instance_valid(Juice):
		Juice.screen_shake(0.12)

	# ── Animate rings (always spinning) ────────────────────────────────────
	var ring_speed_mult := 1.0 + float(_phase) * 0.6
	for i: int in _ring_nodes.size():
		_ring_nodes[i].rotation.y += delta * (1.2 + float(i) * 0.45) * ring_speed_mult

	# ── Damage flash decay ──────────────────────────────────────────────────
	if _core_shader:
		var flash: float = float(_core_shader.get_shader_parameter("damage_flash"))
		if flash > 0.0:
			_core_shader.set_shader_parameter("damage_flash", maxf(0.0, flash - delta * 6.0))

	# ── Vulnerability countdown ─────────────────────────────────────────────
	if _vuln_timer > 0.0:
		_vuln_timer = maxf(0.0, _vuln_timer - delta)
		if _vuln_timer <= 0.0:
			_vulnerability = false

	# ── Adaptation tick ─────────────────────────────────────────────────────
	_adapt_t += delta
	if _adapt_t >= ADAPT_INTERVAL:
		_adapt_t = 0.0
		_adapt_to_player()

	# ── Find player ─────────────────────────────────────────────────────────
	if not _player:
		var ps := get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			_player = ps[0]
	if not _player:
		_float_idle(delta)
		return

	# ── Phase transitions ────────────────────────────────────────────────────
	var hp_ratio := float(hp) / float(max_hp)
	if _phase == 0 and hp_ratio < 0.65:
		_enter_phase(1)
	elif _phase == 1 and hp_ratio < 0.30:
		_enter_phase(2)
	if hp_ratio < 0.12 and not _spoken.has("low_hp"):
		_say("low_hp")

	# ── Floating Y movement ──────────────────────────────────────────────────
	# Spring-damper toward target height above the player, unless slamming.
	if not _slamming:
		var target_y := _player.global_position.y + float_height
		var err_y    := target_y - global_position.y
		_float_vel_y  = lerp(_float_vel_y, err_y * FLOAT_SPRING, FLOAT_DAMPEN * delta * 10.0)
		_float_vel_y  = clampf(_float_vel_y, -8.0, 8.0)
		velocity.y    = _float_vel_y
	# Horizontal: orbit gently around player, drifting to stay at ideal range
	var to_player := _player.global_position - global_position
	to_player.y   = 0
	var dist_xz   := to_player.length()
	const IDEAL_DIST: float = 10.0
	var horiz_speed := 3.5 + float(_phase) * 1.0
	if dist_xz > IDEAL_DIST + 2.0:
		# Drift closer
		var dir := to_player.normalized()
		velocity.x = dir.x * horiz_speed
		velocity.z = dir.z * horiz_speed
	elif dist_xz < IDEAL_DIST - 2.0:
		# Drift back
		var dir := -to_player.normalized()
		velocity.x = dir.x * horiz_speed
		velocity.z = dir.z * horiz_speed
	else:
		# Lateral orbit strafe
		var perp := Vector3(-to_player.normalized().z, 0.0, to_player.normalized().x)
		velocity.x = perp.x * horiz_speed * 0.7
		velocity.z = perp.z * horiz_speed * 0.7

	# Face player
	if to_player.length() > 0.1:
		var tb := Basis.looking_at(to_player.normalized(), Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(tb, 5.0 * delta)

	# Attack timer
	_attack_t -= delta
	if _attack_t <= 0.0 and _state == "combat" and not _slamming:
		var pick: String = _attack_pool[randi() % _attack_pool.size()]
		call(pick)

	move_and_slide()

func _float_idle(delta: float) -> void:
	# Gentle hover in place when no player is found
	velocity = velocity.lerp(Vector3.ZERO, 4.0 * delta)
	var t := Time.get_ticks_msec() * 0.001
	velocity.y = sin(t * 0.8) * 0.5
	move_and_slide()

# ==========================================================================
# Phase system
# ==========================================================================
func _enter_phase(p: int) -> void:
	_phase = p
	if _core_shader:
		_core_shader.set_shader_parameter("phase", p)
	match p:
		1:
			_say("phase_1")
			_attack_pool = ["_wc_bolt", "_wc_volley", "_wc_slam",
			                "_wc_drone_spawn", "_wc_ring_hazard"]
			_aura.light_color  = Color(1.0, 0.55, 0.15)
			_aura.light_energy = 3.8
			_open_vulnerability(1.0)
			if is_instance_valid(Juice):
				Juice.screen_flash(Color(1.0, 0.55, 0.15, 0.4), 0.28)
				# Hit-stop punctuates the transition — player FEELS the power surge.
				Juice.hit_stop(0.10)
			get_tree().call_group("world", "play_sfx", "boss_phase")
		2:
			_say("phase_2")
			_attack_pool = ["_wc_volley", "_wc_volley", "_wc_slam",
			                "_wc_drone_spawn", "_wc_ring_hazard",
			                "_wc_ring_hazard", "_wc_eye_beam"]
			_aura.light_color  = Color(1.0, 0.12, 0.08)
			_aura.light_energy = 4.8
			damage = int(damage * 1.25)
			_open_vulnerability(1.5)
			if is_instance_valid(Juice):
				Juice.screen_flash(Color(1.0, 0.10, 0.10, 0.55), 0.35)
				# Heavier pause for the rage transition — enrage is the biggest moment.
				Juice.hit_stop(0.16)
			get_tree().call_group("world", "play_sfx", "boss_phase")

func _adapt_to_player() -> void:
	if _phase < 1: return
	var agg_r  := GameBrain.get_playstyle_ratio("aggressive")
	var dash_r := GameBrain.get_playstyle_ratio("dash_heavy")
	var air_r  := GameBrain.get_playstyle_ratio("airborne")
	# Aggressive rushers → more ring hazards to punish proximity
	if agg_r > 0.38 and _attack_pool.count("_wc_ring_hazard") < 3:
		_attack_pool.append("_wc_ring_hazard")
	# Dash-heavy → more bolt volleys with spread that catches dodges
	if dash_r > 0.28 and _attack_pool.count("_wc_volley") < 3:
		_attack_pool.append("_wc_volley")
	# Aerial → eye-beam (locks onto airborne target) enters pool earlier
	if air_r > 0.22 and "_wc_eye_beam" not in _attack_pool:
		_attack_pool.append("_wc_eye_beam")
	# Cap pool size
	while _attack_pool.size() > 10:
		_attack_pool.remove_at(0)

	# ── Rage escalation ────────────────────────────────────────────────────
	# Aggressive players make the boss attack sooner on the CURRENT countdown —
	# the effect is felt immediately, not "next attack".  Clamp at 0.8s so the
	# smallest legal gap between attacks never drops below human reaction time
	# for Alden (9yo).  Each adapt tick (every 5s) can apply multiple steps if
	# agg_r crosses both thresholds.
	if agg_r > 0.40:
		_attack_t = maxf(0.8, _attack_t * 0.90)   # 10% sooner
	if agg_r > 0.60:
		_attack_t = maxf(0.8, _attack_t * 0.85)   # another 15% sooner (×0.765 total)

func _open_vulnerability(dur: float) -> void:
	_vulnerability = true
	_vuln_timer    = dur
	# Visual cue: core briefly pulses to full-white so a sharp player sees the window
	if _core_shader:
		_core_shader.set_shader_parameter("damage_flash", 0.55)

# ==========================================================================
# Attack patterns
# ==========================================================================
func _wc_bolt() -> void:
	# Single aimed WatcherBolt — predictable, teachable.
	_attack_t = 1.8 + randf() * 0.4
	if not _player: return
	_fire_bolt(_player.global_position + Vector3(0, 0.9, 0))

func _wc_volley() -> void:
	# 3-bolt spread aimed at and ±18° from the player.
	_attack_t = 2.5
	if not _player: return
	var base_dir := (_player.global_position + Vector3(0, 0.9, 0)) - (global_position + Vector3(0, 0.6, 0))
	base_dir = base_dir.normalized()
	for angle_deg in [-18.0, 0.0, 18.0]:
		var fire_dir := base_dir.rotated(Vector3.UP, deg_to_rad(float(angle_deg)))
		_fire_bolt_dir(fire_dir)
		await get_tree().create_timer(0.12).timeout
		if _state == "dead": return

func _fire_bolt(target_world_pos: Vector3) -> void:
	var origin := global_position + Vector3(0, 0.6, 0)
	var dir    := (target_world_pos - origin).normalized()
	_fire_bolt_dir(dir)

func _fire_bolt_dir(dir: Vector3) -> void:
	var bolt := Area3D.new()
	bolt.set_script(WATCHER_BOLT_SCRIPT)
	bolt.global_position = global_position + Vector3(0, 0.6, 0)
	get_tree().current_scene.add_child(bolt)
	bolt.launch(dir, damage, self)

func _wc_slam() -> void:
	# Descend toward the player, slam the ground, rise back up.
	# The ground impact opens a vulnerability window — good players dodge then punish.
	if _slamming: return
	_attack_t = 4.5
	_say("slam")
	_slamming  = true
	_slam_phase = "telegraph"
	# Phase-change flash: core pulses white to warn
	if is_instance_valid(Juice):
		Juice.screen_flash(Color(0.5, 0.7, 1.0, 0.30), 0.20)
	_show_slam_ring()
	await get_tree().create_timer(0.70).timeout
	if _state == "dead": _slamming = false; return
	# Descend
	_slam_phase = "descend"
	var descend_t := 0.0
	while descend_t < 0.55 and _state != "dead":
		var down := Vector3(0, -1, 0)
		velocity.y = down.y * 22.0
		move_and_slide()
		if global_position.y <= (_spawn_pos.y + 0.5):
			break
		await get_tree().create_timer(0.04).timeout
		descend_t += 0.04
	# Impact
	_slam_phase = "impact"
	velocity.y  = 0.0
	if is_instance_valid(Juice):
		Juice.hit_stop_tier(int(damage * 1.6))
		Juice.screen_flash(Color(0.5, 0.7, 1.0, 0.50), 0.22)
	# Deal AoE damage at ground level
	for p in get_tree().get_nodes_in_group("player"):
		if p.global_position.distance_to(global_position) < 5.5:
			p.take_damage(int(damage * 1.6))
			var d := (p.global_position - global_position).normalized()
			p.velocity += d * 9.0 + Vector3.UP * 4.5
	_open_vulnerability(VULN_WINDOW)
	# Rise
	await get_tree().create_timer(0.35).timeout
	if _state == "dead": _slamming = false; return
	_slam_phase = "rise"
	var rise_t := 0.0
	var target_rise_y := (_player.global_position.y if _player else global_position.y) + float_height
	while rise_t < 0.7 and _state != "dead":
		velocity.y = 16.0
		move_and_slide()
		if global_position.y >= target_rise_y: break
		await get_tree().create_timer(0.04).timeout
		rise_t += 0.04
	_slamming   = false
	_slam_phase = ""
	velocity.y  = 0.0

func _wc_drone_spawn() -> void:
	# Summon Watcher enemies as orbital defenders.
	# Count scales with phase.
	_attack_t = 3.2
	var count := 1 + _phase   # phase 0→1, 1→2, 2→3
	_say("drone")
	for i: int in count:
		var ang  := (float(i) / float(count)) * TAU
		var pos  := global_position + Vector3(cos(ang) * 3.5, -2.0, sin(ang) * 3.5)
		var drone := CharacterBody3D.new()
		drone.set_script(ENEMY_SCRIPT)
		drone.set("enemy_kind",  "watcher")
		drone.set("enemy_name",  "Core Drone")
		drone.set("max_hp",      25 + _phase * 10)
		drone.set("damage",      int(damage * 0.65))
		drone.set("move_speed",  2.5)
		drone.set("xp_reward",   20)
		get_tree().current_scene.add_child(drone)
		drone.global_position = pos

func _wc_ring_hazard() -> void:
	# A ring of damage zones that expands outward from under the boss,
	# forcing the player to jump over or sprint through.
	_attack_t = 3.8
	var ring_count := 6 + _phase * 2   # more segments at higher phases
	var expand_dur := 1.6 - _phase * 0.2   # faster at higher phases
	_show_expanding_ring(ring_count, 8.0, expand_dur)

func _wc_eye_beam() -> void:
	# Phase 2 only: a sustained tracking beam aimed at the player for 1.2s.
	# Does rapid small-tick damage.  Broadcast telegraph to give player time to dodge.
	_attack_t = 4.5
	var beam_line := _make_beam_visual()
	var ticks := 0
	var tick_max := 12
	while ticks < tick_max and _state != "dead":
		await get_tree().create_timer(0.10).timeout
		ticks += 1
		if not _player: break
		# Update beam endpoint
		var origin := global_position + Vector3(0, 0.5, 0)
		var target  := _player.global_position + Vector3(0, 0.9, 0)
		_update_beam_visual(beam_line, origin, target)
		# Tiny tick damage
		if _player.global_position.distance_to(global_position) < 20.0:
			if _player.has_method("take_damage"):
				_player.take_damage(int(damage * 0.25))
	if is_instance_valid(beam_line):
		beam_line.queue_free()
	_open_vulnerability(VULN_WINDOW * 0.8)

# ==========================================================================
# Telegraph / visual helpers
# ==========================================================================
func _show_slam_ring() -> void:
	var ring := MeshInstance3D.new()
	var pm   := PlaneMesh.new(); pm.size = Vector2(11.0, 11.0)
	ring.mesh = pm
	var rm   := StandardMaterial3D.new()
	rm.albedo_color              = Color(0.4, 0.65, 1.0, 0.55)
	rm.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.emission_enabled          = true
	rm.emission                  = Color(0.4, 0.65, 1.0)
	rm.emission_energy_multiplier = 2.8
	rm.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm
	ring.position = global_position + Vector3(0, 0.06, 0)
	get_tree().current_scene.add_child(ring)
	var tw := create_tween()
	tw.tween_interval(0.70)
	tw.tween_callback(ring.queue_free)

func _show_expanding_ring(segment_count: int, max_radius: float, dur: float) -> void:
	# Build individual segment planes and tween them outward.
	var mats_and_meshes: Array = []
	for i: int in segment_count:
		var ang    := (float(i) / float(segment_count)) * TAU
		var seg_mi := MeshInstance3D.new()
		var seg_pm := PlaneMesh.new(); seg_pm.size = Vector2(1.2, 1.8)
		seg_mi.mesh = seg_pm
		var seg_mat := StandardMaterial3D.new()
		seg_mat.albedo_color              = Color(0.4, 0.65, 1.0, 0.70)
		seg_mat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
		seg_mat.emission_enabled          = true
		seg_mat.emission                  = Color(0.4, 0.65, 1.0)
		seg_mat.emission_energy_multiplier = 2.6
		seg_mat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
		seg_mi.material_override = seg_mat
		var start_pos := global_position + Vector3(0, 0.06, 0)
		seg_mi.position = start_pos
		seg_mi.rotation.y = ang
		get_tree().current_scene.add_child(seg_mi)
		mats_and_meshes.append(seg_mi)
		var dest := global_position + Vector3(cos(ang) * max_radius, 0.06, sin(ang) * max_radius)
		var tw   := create_tween()
		tw.tween_property(seg_mi, "position", dest, dur).set_trans(Tween.TRANS_EXPO)
		tw.tween_callback(seg_mi.queue_free)
	# Deal damage to players caught in the ring mid-expansion
	_ring_hazard_damage(max_radius, dur)

func _ring_hazard_damage(max_radius: float, dur: float) -> void:
	var steps := 8
	for _s in steps:
		await get_tree().create_timer(dur / float(steps)).timeout
		if _state == "dead": return
		for p in get_tree().get_nodes_in_group("player"):
			var dist_xz := Vector2(p.global_position.x - global_position.x,
			                       p.global_position.z - global_position.z).length()
			# Ring sweeps outward — damage band is ±1m of the current wave front
			var wave_r := max_radius * (float(_s + 1) / float(steps))
			if abs(dist_xz - wave_r) < 1.0 and abs(p.global_position.y - global_position.y) < 3.0:
				p.take_damage(int(damage * 0.55))
				if is_instance_valid(Juice):
					Juice.hit_stop(0.03)

func _make_beam_visual() -> MeshInstance3D:
	var line_mi := MeshInstance3D.new()
	var line_pm := PlaneMesh.new(); line_pm.size = Vector2(0.3, 18.0)
	line_mi.mesh = line_pm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color              = Color(0.9, 0.95, 1.0, 0.85)
	bmat.transparency              = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.emission_enabled          = true
	bmat.emission                  = Color(0.5, 0.75, 1.0)
	bmat.emission_energy_multiplier = 5.0
	bmat.shading_mode              = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mi.material_override = bmat
	get_tree().current_scene.add_child(line_mi)
	return line_mi

func _update_beam_visual(line_mi: MeshInstance3D, origin: Vector3, target: Vector3) -> void:
	if not is_instance_valid(line_mi): return
	var mid  := (origin + target) * 0.5
	line_mi.position  = mid
	var dir  := (target - origin).normalized()
	if dir.length() > 0.001:
		line_mi.rotation.y = atan2(dir.x, dir.z)
		line_mi.rotation.x = -asin(dir.y)

# ==========================================================================
# Damage / death
# ==========================================================================
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead": return
	if _vulnerability:
		amount = int(float(amount) * VULN_MULT)
	hp = max(0, hp - amount)

	# Shader damage flash
	if _core_shader:
		_core_shader.set_shader_parameter("damage_flash", 1.0)
	# Squash & stretch the core for tactile feedback
	if is_instance_valid(Juice):
		Juice.squash(_core_mesh, 0.25)
		Juice.hit_stop_tier(amount)

	get_tree().call_group("world", "update_boss_hp_bar", hp, max_hp, "Watcher Core")
	if UITheme and UITheme.has_method("spawn_damage_popup"):
		UITheme.spawn_damage_popup(get_tree().current_scene,
			global_position + Vector3(randf_range(-0.3, 0.3), 2.0, randf_range(-0.3, 0.3)),
			str(amount), Color(0.7, 0.9, 1.0), 44, 6)
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _die(source: Node) -> void:
	_state = "dead"
	if _core_mesh: _core_mesh.visible = false
	for r in _ring_nodes:
		if is_instance_valid(r): r.visible = false
	if _label: _label.visible = false
	if _aura:  _aura.visible  = false
	get_tree().call_group("world", "hide_boss_hp_bar")
	get_tree().call_group("world", "_show_toast", "✦ Watcher Core destroyed! ✦")
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	died.emit(self)
	get_tree().call_group("quest_listeners", "on_enemy_killed", "watcher_core")
	get_tree().call_group("world", "set_world_flag", "watcher_core_slain", true)

# ==========================================================================
# Voice helper
# ==========================================================================
func _say(key: String) -> void:
	if _spoken.has(key) or not LINES.has(key): return
	_spoken[key] = true
	if UITheme and UITheme.has_method("spawn_damage_popup"):
		UITheme.spawn_damage_popup(get_tree().current_scene,
			global_position + Vector3(0, 3.8, 0),
			LINES[key], Color(0.40, 0.75, 1.0), 40, 5)
	get_tree().call_group("world", "_show_toast", LINES[key])
