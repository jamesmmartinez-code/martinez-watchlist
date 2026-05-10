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
var pitch: float = 0.55
var dragging: bool = false

@onready var _cam: Camera3D = $Camera3D

func _ready() -> void:
	# FIX 2026-05-09: Zero out any baked transform on Camera3D — the script owns
	# placement entirely. The scene had transform (0,4,7) baked in; on frame 0
	# before follow_target is found, _cam.position stays at that value but
	# global_position is still origin, so look_at fires with cam==target ->
	# degenerate projection matrix -> prepare_camera spam-errors in Web/WASM.
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

	# FIX: Pre-position camera on frame 0 so look_at never fires from zero distance
	if follow_target:
		global_position = follow_target.global_position + Vector3(0, 1.6, 0)
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
		pitch  = clamp(pitch + event.relative.y * sensitivity, 0.25, 1.15)

func _process(_delta: float) -> void:
	if not follow_target or not is_instance_valid(follow_target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			return

	var target_pos: Vector3 = follow_target.global_position + Vector3(0, 1.6, 0)
	global_position = global_position.lerp(target_pos, smooth_lerp)
	rotation = Vector3(0, yaw, 0)
	_update_camera_transform()

# Positions and orients the Camera3D safely.
# Split out so _ready() can call it on frame 0, preventing the
# "camera at distance zero -> degenerate look_at -> prepare_camera !res" crash
# that spams the Web/WASM console and leaves the screen black.
func _update_camera_transform() -> void:
	if not _cam:
		return
	var off: Vector3 = Vector3(0, sin(pitch) * distance, cos(pitch) * distance)
	_cam.position = off
	# GUARD: skip look_at if camera world pos == look target (zero-length direction
	# vector -> invalid projection matrix -> WebGL renderer crashes every frame).
	var look_target: Vector3 = global_position
	var cam_world: Vector3 = _cam.global_position
	if cam_world.distance_squared_to(look_target) > 0.0001:
		_cam.look_at(look_target, Vector3.UP)
