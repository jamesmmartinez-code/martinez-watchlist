extends Node3D
class_name CameraController

# Third-person orbit camera. Right-mouse drag (or two-finger drag on track pad)
# to rotate, scroll wheel to zoom in/out. Auto-wires to whatever node is in the
# "player" group on _ready, so the scene file doesn't need a manual assignment.

@export var follow_target: Node3D
@export var distance: float = 8.0
@export var min_distance: float = 3.4
@export var max_distance: float = 13.5
@export var sensitivity: float = 0.0055
@export var smooth_lerp: float = 0.22

var yaw: float = 0.0
var pitch: float = 0.42
var dragging: bool = false

@onready var _cam: Camera3D = $Camera3D

func _ready() -> void:
	# FIX: Zero out any baked transform on the Camera3D — the script owns placement.
	# Without this, the scene's saved transform (0, 4, 7) conflicts with the
	# script's off-vector, and on the first frame before follow_target is found,
	# _cam.position is effectively zero → look_at fires with a degenerate matrix
	# → prepare_camera spam-errors in the Web/WASM renderer.
	if _cam:
		_cam.position = Vector3.ZERO
		_cam.near = 0.1
		_cam.far = 4000.0

	# Auto-wire the follow target if not set in editor
	if not follow_target:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			var root := get_tree().current_scene
			if root:
				follow_target = root.get_node_or_null("Player")

	# FIX: Pre-position camera before the first _process() tick so look_at
	# never fires from a zero-distance state.
	if follow_target:
		global_position = follow_target.global_position + Vector3(0, 1.4, 0)
		_update_camera_transform()

	# Tell Player about us so it can use camera-relative movement
	var p = follow_target
	if p and "camera_pivot" in p and p.camera_pivot == null:
		p.camera_pivot = self

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if dragging else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 1.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 1.5, min_distance, max_distance)
	elif event is InputEventMouseMotion and dragging:
		yaw   -= event.relative.x * sensitivity
		pitch  = clamp(pitch + event.relative.y * sensitivity, 0.10, 1.15)

func _process(_delta: float) -> void:
	# Re-find the player if we lost it (e.g., respawn replaced the node)
	if not follow_target or not is_instance_valid(follow_target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			return

	# Smoothly follow target
	var target_pos: Vector3 = follow_target.global_position + Vector3(0, 1.4, 0)
	global_position = global_position.lerp(target_pos, smooth_lerp)

	# Apply yaw rotation to the pivot
	rotation = Vector3(0, yaw, 0)

	_update_camera_transform()

# Positions and orients the Camera3D safely.
# Extracted into its own function so _ready() can call it on frame 0 — this
# prevents the "camera at distance zero → degenerate look_at matrix" crash that
# causes prepare_camera to spam errors in the Godot Web/WASM build.
func _update_camera_transform() -> void:
	if not _cam:
		return
	var off: Vector3 = Vector3(0, sin(pitch) * distance, cos(pitch) * distance)
	_cam.position = off
	# look_at target is the pivot world position (player chest height).
	# GUARD: skip if camera world pos equals the look target — a zero-length
	# direction vector produces an invalid projection matrix and crashes the
	# WebGL renderer with "prepare_camera: !res" on every frame.
	var look_target: Vector3 = global_position
	var cam_world: Vector3 = _cam.global_position
	if cam_world.distance_squared_to(look_target) > 0.0001:
		_cam.look_at(look_target, Vector3.UP)
