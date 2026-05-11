extends CharacterBody3D
class_name Pet

# A companion fox that follows the player, gives a small XP buff (passive)
# and barks at nearby enemies (visual only — no damage).

# REFINE: character — follow_distance 2.2 → 2.0. Compounds on the existing stickier-stop (vel × 0.80 in the else-branch): Ember now settles a half-pace closer, reading as "tucked next to player" instead of "loitering near." Directly serves Alden's Companions affinity (PLAYER_MODEL.md — "Pets and companions that follow and emote") and THEME §12 (Pet Ember micro-behaviors: sit when idle).
@export var follow_distance: float = 2.0
# REFINE: character — tiny speed bump so Ember keeps up on Owen's sprint without teleport-snap.
@export var max_speed: float = 8.5
# REFINE: character — wider bark perimeter so Ember warns *before* the goblin reaches the player.
@export var bark_radius: float = 9.0
@export var pet_model: PackedScene = preload("res://assets/models/Fox.glb")

var _player: Node3D = null
var _gravity: float = 20.0
var _bark_t: float = 0.0
var _model: Node3D
var _label: Label3D
# REFINE: character — spawn-Y cached at _ready so the idle bob knows where to oscillate around.
var _spawn_y: float = 0.0

# REFINE: character — five-bark catchphrase pool so Ember stops sounding like a tape loop.
# Picked uniformly per bark; no schedule change. Same bark cadence the rest of the script
# already enforces — just visual variety.
const BARK_LINES: Array[String] = ["yip!", "arf!", "rrr!", "yip yip!", "yap!"]
# REFINE: character — bark color picks one of two ember tones per bark for visual variety.
const BARK_COLORS: Array[Color] = [Color(1.0, 0.85, 0.30), Color(1.0, 0.62, 0.18)]


func _ready() -> void:
	add_to_group("pets")
	collision_layer = 0  # don't physically block anything
	collision_mask = 1   # collide only with the world to stay grounded

	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.25; caps.height = 0.6
	cs.shape = caps
	cs.position.y = 0.4
	add_child(cs)

	# Visual model
	_model = pet_model.instantiate()
	# char-spec 2026-05-06: 0.7 → 0.55 per SIZE_STANDARDS.md §1 (pet canon below kid knee).
	call_deferred("_normalize_to_height", _model, 0.55)  # foxes are short
	_model.scale = Vector3(0.018, 0.018, 0.018)
	add_child(_model)

	_label = Label3D.new()
	_label.text = "🦊 Ember"
	# REFINE: character — nameplate +2pt so Alden can read "Ember" from the back of the screen.
	_label.font_size = 20
	_label.outline_size = 4
	_label.outline_modulate = Color(0, 0, 0)
	# REFINE: character — slightly hotter ember tone so Ember's nameplate reads as fire-fox in dusk.
	_label.modulate = Color(1.0, 0.55, 0.18)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# REFINE: character — nameplate Y 1.10 → 0.95. char-spec 2026-05-06 dropped Ember's
	# fox normalize target 0.7→0.55 to match SIZE_STANDARDS.md §1 (pet canon below kid knee).
	# At 0.55m tall, the previous Y=1.10 label sat 0.55m above the fox's back — disconnected
	# halo. Y=0.95 keeps the same ~0.40m offset over the new fox-back, restoring the
	# "tucked above the ear" read (THEME §13 ground-contact framing).
	_label.position = Vector3(0, 0.95, 0)
	add_child(_label)
	# REFINE: character — cache ground-Y so _process idle bob oscillates around the spawn floor, not a drifting world position.
	_spawn_y = global_position.y

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0
	if not _player:
		var pls: Array[Node] = get_tree().get_nodes_in_group("player")
		if pls.size() > 0:
			_player = pls[0]
	if not _player:
		move_and_slide()
		return
	var to_p: Vector3 = _player.global_position - global_position
	to_p.y = 0
	var dist := to_p.length()
	if dist > follow_distance:
		var dir := to_p.normalized()
		# REFINE: character — close-approach floor 1.5 → 1.7 m/s. The clamp's lower bound governs Ember's gait when (dist · 1.4) < floor — i.e. when Ember is just barely outside follow_distance and closing the last small gap. Old 1.5 m/s read as a hesitating shuffle at the gap-close beat; 1.7 m/s reads as a deliberate step. Still ~5× below the new max_speed 8.5, so sprint catch-up behaviour is unchanged. Pairs with the new tighter follow_distance 2.0 (the gap-close beat fires more often now that idle-distance is shorter).
		var spd: float = clamp(dist * 1.4, 1.7, max_speed)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		var target_basis := Basis.looking_at(dir, Vector3.UP)
		# REFINE: character — body-turn slerp factor 8.0 → 6.0. THEME §12 "weighted, never snap." At 60 fps the old 8.0·dt ≈ 0.133 lerp/frame is on the snappy side for a small companion fox; 6.0·dt ≈ 0.100 lerp/frame still tracks confidently but reads as a painterly head-and-shoulders weight-shift instead of a marionette swivel. Compounds on the cross-system §12 cadence rhythm authored across the recent CameraController.gd run (smooth_lerp 0.18 → 0.22) and Minimap.gd run (player pulse 3.0 → 2.5 rad/s).
		global_transform.basis = global_transform.basis.slerp(target_basis, 6.0 * delta)
	else:
		# REFINE: character — stickier stop so Ember settles next to the player instead of skating past.
		velocity.x *= 0.80
		velocity.z *= 0.80

	# Bark at nearby enemies every couple seconds
	_bark_t -= delta
	if _bark_t <= 0:
		# REFINE: character — jittered bark cadence (was a flat 2.5s metronome) so Ember sounds alive.
		# REFINE: character — cadence 1.8–2.6 → 2.0–2.7. Compounds on the recent Minimap.gd run that slowed enemy aggro flash rate 8.0 → 6.5 rad/s on the same logic ("warning is a heartbeat, not a strobe"). Ember's bark and the minimap flash are paired threat cues; their rhythms should align. Lower-bound +0.2s pulls the loudest case off the strobe edge; upper-bound +0.1s nudges the quiet rhythm slightly slower so the band doesn't squeeze. Mean cadence 2.20 → 2.35s. Alden's low-to-medium combat tolerance directly served (PLAYER_MODEL.md — Combat tolerance: low-to-medium; gets discouraged by deaths).
		_bark_t = randf_range(2.0, 2.7)
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_to(global_position) < bark_radius:
				_bark()
				break

	move_and_slide()

func _bark() -> void:
	# REFINE: character — pick a bark line from the catchphrase pool (replaces the single "yip!").
	# REFINE: character — alternating ember tones per bark for tiny visual rhythm.
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 1.5, 0), BARK_LINES[randi() % BARK_LINES.size()], BARK_COLORS[randi() % BARK_COLORS.size()], 24, 4)

func _process(_delta: float) -> void:
	# REFINE: character — THEME §12 MOTION & LIFE. Ember idle dual-harmonic body-bob.
	# Pet.gd previously had no _process at all — Ember was a perfectly still fox when
	# not moving (the _physics_process only fires when velocity matters). THEME §12
	# bans "static = dead" for any living thing; a companion pet at the player's side
	# is the highest-visibility case. Two harmonics mirror the NPC/Enemy dual-bob
	# pattern (primary 2.513 rad/s slow chest-rise, secondary 10.982 rad/s shoulder-shift)
	# but at ¾ amplitude (±0.014 + ±0.004 m) because Ember is a fox curled below knee
	# height — large motion would read as floating rather than breathing.
	# The bob ONLY fires when Ember is at rest (velocity.length() < 0.4) so it never
	# fights _physics_process during sprinting/following (which already animates the body
	# through locomotion). A second oscillation on model rotation.z (±0.04 rad, slow
	# 0.83 rad/s ≈ a lazy wag period of ~7.6 s) gives Ember a visible tail-weight-shift
	# that reads as an idle tail-wag without requiring skeleton access. Both phases are
	# seeded from global_position so Ember's wag never syncs with a second pet.
	if _model == null:
		return
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var phase1: float = global_position.x * 0.61 + global_position.z * 0.37
	var phase2: float = global_position.x * 1.13 + global_position.z * 0.79  # REFINE: second harmonic phase, incommensurable with phase1
	if velocity.length() < 0.4:
		# REFINE: character — idle body-bob primary (slow chest-rise) + secondary (fast shoulder-shift).
		var bob: float = sin(t * 2.513 + phase1) * 0.014 + sin(t * 10.982 + phase2) * 0.004
		global_position.y = _spawn_y + bob  # REFINE: oscillate around cached ground-Y
		# REFINE: character — idle tail-wag weight-shift via model Z-lean. ±0.04 rad at 0.83 rad/s.
		# Frequencies 0.83 and 1.97 are incommensurable (ratio ≈ 2.374) so the lean never repeats.
		var wag: float = sin(t * 0.83 + phase1) * 0.04 + sin(t * 1.97 + phase2) * 0.016
		_model.rotation.z = wag

# Normalize 3D model scale so it ends up ~target_height tall.
# Prevents giants from Sketchfab GLBs with mixed units.
func _normalize_to_height(model: Node, target_height: float) -> void:
	await get_tree().process_frame
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
	# scale-eng 2026-05-05: iterative shrink, floor 0.05 → 0.001. Fox / pet GLBs from
	# Sketchfab can be 100× off — old floor stranded Ember at ~3m instead of 0.7m.
	var _pass_n: int = 0
	while _pass_n < 6 and aabb.size.y > 0.001 and (aabb.size.y < target_height * 0.80 or aabb.size.y > target_height * 1.20):
		var _s: float = clamp(target_height / aabb.size.y, 0.001, 5.0)
		if model is Node3D:
			(model as Node3D).scale = (model as Node3D).scale * _s
		else:
			model.scale = Vector3(_s, _s, _s)
		await get_tree().process_frame
		if not is_instance_valid(model): return
		aabb = AABB(); has = false
		for c_re in model.find_children("*", "VisualInstance3D", true):
			var v_re := c_re as VisualInstance3D
			if not v_re: continue
			var a_re := v_re.global_transform * v_re.get_aabb()
			if not has: aabb = a_re; has = true
			else: aabb = aabb.merge(a_re)
		_pass_n += 1
