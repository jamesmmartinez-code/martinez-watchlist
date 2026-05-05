extends Node3D
class_name CameraController

# Third-person orbit camera. Right-mouse drag (or two-finger drag on track pad)
# to rotate, scroll wheel to zoom in/out. Auto-wires to whatever node is in the
# "player" group on _ready, so the scene file doesn't need a manual assignment.

@export var follow_target: Node3D
@export var distance: float = 7.5
@export var min_distance: float = 3.0
@export var max_distance: float = 16.0
@export var sensitivity: float = 0.006
@export var smooth_lerp: float = 0.18

var yaw: float = 0.0
var pitch: float = 0.45
var dragging: bool = false

@onready var _cam: Camera3D = $Camera3D

func _ready() -> void:
	# Auto-wire the follow target if not set in editor
	if not follow_target:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			# Fallback: try to find a node named "Player" at the scene root
			var root := get_tree().current_scene
			if root:
				follow_target = root.get_node_or_null("Player")
	# Snap to target on first frame so we don't lerp from origin
	if follow_target:
		global_position = follow_target.global_position + Vector3(0, 1.4, 0)
	# Tell Player about us so it can use camera-relative movement
	var p = follow_target
	if p and "camera_pivot" in p and p.camera_pivot == null:
		p.camera_pivot = self

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			# Capture the mouse cursor while dragging so the user can drag freely
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if dragging else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 0.6, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 0.6, min_distance, max_distance)
	elif event is InputEventMouseMotion and dragging:
		yaw   -= event.relative.x * sensitivity
		pitch  = clamp(pitch + event.relative.y * sensitivity, 0.05, 1.3)

func _process(delta: float) -> void:
	# Re-find the player if we lost it (e.g., respawn replaced the node)
	if not follow_target or not is_instance_valid(follow_target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			return

	# Smoothly follow target — track the player's position
	var target_pos: Vector3 = follow_target.global_position + Vector3(0, 1.4, 0)
	global_position = global_position.lerp(target_pos, smooth_lerp)

	# Apply yaw rotation to the pivot
	rotation = Vector3(0, yaw, 0)

	# Position camera behind/above the pivot based on pitch + distance
	if _cam:
		var off: Vector3 = Vector3(0, sin(pitch) * distance, cos(pitch) * distance)
		_cam.position = off
		# Look back at the pivot point (which sits at the player's chest height)
		_cam.look_at(global_position + Vector3(0, 0, 0), Vector3.UP)
