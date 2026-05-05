extends CharacterBody3D
class_name Pet

# A companion fox that follows the player, gives a small XP buff (passive)
# and barks at nearby enemies (visual only — no damage).

# REFINE: character — tighter sit-stay so Ember feels attentive (Alden's companion affinity).
@export var follow_distance: float = 2.2
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

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")

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
	_label.position = Vector3(0, 1.2, 0)
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
		var spd: float = clamp(dist * 1.4, 1.5, max_speed)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		var target_basis := Basis.looking_at(dir, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, 8.0 * delta)
	else:
		# REFINE: character — stickier stop so Ember settles next to the player instead of skating past.
		velocity.x *= 0.80
		velocity.z *= 0.80

	# Bark at nearby enemies every couple seconds
	_bark_t -= delta
	if _bark_t <= 0:
		# REFINE: character — jittered bark cadence (was a flat 2.5s metronome) so Ember sounds alive.
		_bark_t = randf_range(1.8, 2.6)
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_to(global_position) < bark_radius:
				_bark()
				break

	move_and_slide()

func _bark() -> void:
	var pop := Label3D.new()
	pop.set_script(DAMAGE_NUMBER_SCRIPT)
	# REFINE: character — pick a bark line from the catchphrase pool (replaces the single "yip!").
	pop.text = BARK_LINES[randi() % BARK_LINES.size()]
	pop.font_size = 24
	pop.outline_size = 4
	pop.outline_modulate = Color(0, 0, 0)
	# REFINE: character — alternating ember tones per bark for tiny visual rhythm.
	pop.modulate = BARK_COLORS[randi() % BARK_COLORS.size()]
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test = true
	pop.position = global_position + Vector3(0, 1.5, 0)
	get_tree().current_scene.add_child(pop)
