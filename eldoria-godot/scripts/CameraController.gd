extends Node3D
class_name CameraController

# ─────────────────────────────────────────────────────────────────────────────
# Realm of Eldoria — MMORPG third-person camera
#
# Node setup (CameraController lives as a sibling of Player, or child):
#   CameraController          ← this script   (handles Y / yaw)
#     └── CameraPitch         ← Node3D child  (handles X / pitch)
#           └── Camera3D      ← the actual camera
#
# Mouse behaviour:
#   • Click anywhere in the window  → capture mouse, camera rotates freely
#   • Escape / right-click release  → release mouse
#   • Scroll wheel                  → zoom in / out
#   • WASD moves player relative to the camera direction (set in Player.gd)
# ─────────────────────────────────────────────────────────────────────────────

@export var follow_target:  Node3D
@export var distance:       float = 10.0
@export var min_distance:   float = 3.4
@export var max_distance:   float = 13.5
@export var sensitivity:    float = 0.003
@export var smooth_follow:  float = 0.22

# Pivot child that handles pitch so yaw stays clean on this node
@onready var _pitch_node: Node3D  = get_node_or_null("CameraPitch")
@onready var _cam:        Camera3D = (
	_pitch_node.get_node_or_null("Camera3D") if _pitch_node
	else get_node_or_null("Camera3D")
)

var _yaw:   float = 0.0
var _pitch: float = 0.85   # radians; 0 = horizon, π/2 = straight down

func _ready() -> void:
	# Ensure Camera3D has no stale baked transform (script owns placement entirely).
	if _cam:
		_cam.position = Vector3.ZERO
		_cam.near     = 0.1
		_cam.far      = 4000.0

	# Auto-wire follow target if not set in the editor.
	if not follow_target:
		var players := get_tree().get_nodes_in_group("player")
		follow_target = players[0] if players.size() > 0 else \
			get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null

	# Pre-position on frame 0 so look_at never fires at zero distance.
	if follow_target:
		global_position = follow_target.global_position + Vector3(0, 1.2, 0)
		_apply_camera_transform()

	# Tell Player about us so it can use camera-relative movement.
	if follow_target and "camera_pivot" in follow_target and follow_target.camera_pivot == null:
		follow_target.camera_pivot = self

func _unhandled_input(event: InputEvent) -> void:
	# ── Mouse capture ──────────────────────────────────────────────────────
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if event.pressed:
					# Any click inside the window captures the mouse.
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
					# Right-release releases (allows right-click menus when not dragging).
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			MOUSE_BUTTON_WHEEL_UP:
				distance = clamp(distance - 1.5, min_distance, max_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = clamp(distance + 1.5, min_distance, max_distance)

	# ── Escape releases mouse ──────────────────────────────────────────────
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# ── Mouse look (only when captured) ───────────────────────────────────
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw  -= event.relative.x * sensitivity
		_pitch = clamp(_pitch + event.relative.y * sensitivity, 0.20, 1.35)

func _process(_delta: float) -> void:
	# Re-acquire follow target if it was swapped out.
	if not follow_target or not is_instance_valid(follow_target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			follow_target = players[0]
		else:
			return

	# Smooth-follow the player's head position.
	var head: Vector3 = follow_target.global_position + Vector3(0, 1.2, 0)
	global_position = global_position.lerp(head, smooth_follow)

	# Apply yaw to this node, pitch to the child node.
	rotation.y = _yaw
	if _pitch_node:
		_pitch_node.rotation.x = _pitch

	_apply_camera_transform()

# ─── Places Camera3D along the orbit arc and points it at the pivot ───────────
func _apply_camera_transform() -> void:
	if not _cam:
		return

	# Build offset in the pitch-node's local space (or this node's if no pitch child).
	var ref: Node3D = _pitch_node if _pitch_node else self
	var off := Vector3(0, sin(_pitch) * distance, cos(_pitch) * distance)
	_cam.position = off

	# Guard: skip look_at when cam is at the same world-pos as pivot
	# (zero-length direction → degenerate WebGL projection → black screen + spam).
	var look_target := global_position
	var cam_world   := _cam.global_position
	if cam_world.distance_squared_to(look_target) > 0.0001:
		_cam.look_at(look_target, Vector3.UP)
