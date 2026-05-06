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

# REFINE: character — five-bark catchphrase pool so Ember stops sounding like a tape loop.
# Picked uniformly per bark; no schedule change. Same bark cadence the rest of the script
# already enforces — just visual variety.
const BARK_LINES: PackedStringArray = PackedStringArray(["yip!", "arf!", "rrr!", "yip yip!", "yap!"])
# REFINE: character — bark color picks one of two ember tones per bark for visual variety.
const BARK_COLORS: PackedColorArray = PackedColorArray([Color(1.0, 0.85, 0.30), Color(1.0, 0.62, 0.18)])


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
	call_deferred("_normalize_to_height", _model, 0.7)  # foxes are short
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
	# REFINE: character — nameplate Y 1.2 → 1.10. Ember's fox is normalized to 0.7m tall (`_normalize_to_height(_model, 0.7)` above), so a label at world-relative Y=1.2 floats roughly 0.5m above the fox's head — disconnected. 1.10m sits the label ~0.40m above a 0.7m-tall back, reading as "tucked above the ear" instead of "hovering halo." Direct THEME §13 ground-contact framing (extended to nameplates: a label that floats off the model breaks ground-contact silhouette read at a distance).
	_label.position = Vector3(0, 1.10, 0)
	add_child(_label)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0
	if not _player:
		var pls := get_tree().get_nodes_in_group("player")
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
