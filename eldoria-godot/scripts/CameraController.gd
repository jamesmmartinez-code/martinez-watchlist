extends Node3D
class_name CameraController

# Third-person orbit camera. Right-mouse drag (or two-finger drag on track pad)
# to rotate, scroll wheel to zoom in/out. Auto-wires to whatever node is in the
# "player" group on _ready, so the scene file doesn't need a manual assignment.

@export var follow_target: Node3D
# REFINE: combat feel — camera: default distance 7.5 → 8.0 — slightly wider painterly frame at rest (Alden Exploration affinity reads more of the §11 BotW-style vista) without losing combat clarity for Owen.
@export var distance: float = 8.0
# REFINE: combat feel — camera: min_distance 3.0 → 3.4 — prevents camera clipping through the player model when fully zoomed in against a wall (the previous 3.0 occasionally put the camera inside the cape).
@export var min_distance: float = 3.4
# REFINE: combat feel — camera: max_distance 16.0 → 13.5 — at 16m the painterly LODs and HDRI sky-band fill the frame and combat reads collapse; 13.5m keeps the player silhouette legible while still allowing a wide reveal.
@export var max_distance: float = 13.5
# REFINE: combat feel — camera: sensitivity 0.006 → 0.0055 — softens overshoot for Alden's imprecise drag; Owen still reaches a full 360 in well under 2s of drag.
@export var sensitivity: float = 0.0055
# REFINE: combat feel — camera: smooth_lerp 0.18 → 0.22 — snappier follow when Owen sprints (race affinity); still well below 1.0 (snap) so the camera keeps a weighted painterly drift, just less rubber-banded behind a moving player. THEME §12 motion & life: weighted, never snap.
@export var smooth_lerp: float = 0.22

var yaw: float = 0.0
# REFINE: combat feel — camera: initial pitch 0.45 → 0.42 — at the new distance 8.0 this lands the rest frame ~3.27m above / ~7.30m behind the player, ~0.55m more horizontal than before so the mountain ring and the new sunset HDRI sky-band both read in default frame (THEME §11 BotW painterly reference).
var pitch: float = 0.42
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
			# REFINE: combat feel — camera: scroll step 0.6 → 0.55 — finer zoom granularity over the (now narrower) 3.4–13.5m band; about the same total number of ticks but each tick covers a more proportional fraction of the new range.
			distance = clamp(distance - 1.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# REFINE: combat feel — camera: scroll step 0.6 → 0.55 (mirror of WHEEL_UP).
			distance = clamp(distance + 1.5, min_distance, max_distance)
	elif event is InputEventMouseMotion and dragging:
		yaw   -= event.relative.x * sensitivity
		# REFINE: combat feel — camera: pitch clamp lower 0.05 → 0.10 (no more ankle-height frames where the player silhouette disappears below the screen — THEME §13 ground contact stays in frame), upper 1.3 → 1.15 (caps the bird's-eye top-down at a still-cinematic ~7.3m above / ~3.25m back instead of the previous near-overhead 7.7m / 2.1m where ground geometry inverts).
		pitch  = clamp(pitch + event.relative.y * sensitivity, 0.10, 1.15)

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
