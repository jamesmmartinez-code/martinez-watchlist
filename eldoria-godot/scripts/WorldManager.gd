extends Node
# Realm of Eldoria — WorldManager
#
# Area-based world controller.  Attach this to a "WorldManager" node
# inside World.tscn (sibling of the Areas node and TransitionLayer).
#
# Scene layout expected:
#   World (Node3D)
#   ├── Player
#   ├── WorldManager       ← this script
#   ├── WorldStreamer       ← optional streaming companion
#   ├── Areas (Node3D)
#   │   ├── Area_EchoingRuins
#   │   ├── Area_ForestPass
#   │   └── …
#   ├── TransitionLayer    ← must have fade_in() / fade_out() methods
#   └── UI
#
# Any script in the game can reach this node via get_tree().current_scene:
#   var wm = get_tree().current_scene.get_node_or_null("WorldManager")
# Or you can promote it to an autoload if preferred.

signal area_changed(area_name: String)
signal transition_started(area_name: String)

# ── Configuration ──────────────────────────────────────────────────────────
@export var areas_path: NodePath      = NodePath("../Areas")
@export var transition_path: NodePath = NodePath("../TransitionLayer")
@export var player_path: NodePath     = NodePath("../Player")

# ── Internal state ─────────────────────────────────────────────────────────
var current_area: Node = null
var _transition: Node  = null
var _player: Node      = null
var _busy: bool        = false     # prevent overlapping transitions

func _ready() -> void:
	_transition = get_node_or_null(transition_path)
	_player     = get_node_or_null(player_path)
	# Boot: make first area visible, hide others.
	var areas := get_node_or_null(areas_path)
	if areas and areas.get_child_count() > 0:
		for child in areas.get_children():
			child.visible = false
			child.process_mode = Node.PROCESS_MODE_DISABLED
		var first := areas.get_child(0)
		_activate(first)
		current_area = first

# ==========================================================================
# Public API
# ==========================================================================
func transition_to(area_name: String) -> void:
	if _busy:
		return
	_busy = true
	emit_signal("transition_started", area_name)

	if _transition:
		await _transition.fade_out()

	_load_area(area_name)

	if _transition:
		await _transition.fade_in()

	_busy = false

func get_current_area_name() -> String:
	return current_area.name if current_area else ""

func is_area_visible(area_name: String) -> bool:
	var areas := get_node_or_null(areas_path)
	if not areas:
		return false
	var a := areas.get_node_or_null(area_name)
	return a != null and a.visible

# ==========================================================================
# Internal helpers
# ==========================================================================
func _load_area(area_name: String) -> void:
	var areas := get_node_or_null(areas_path)
	if not areas:
		push_warning("WorldManager: Areas node not found at path '%s'" % areas_path)
		return

	# Deactivate every area.
	for area in areas.get_children():
		area.visible = false
		area.process_mode = Node.PROCESS_MODE_DISABLED

	var next := areas.get_node_or_null(area_name)
	if not next:
		push_warning("WorldManager: area '%s' not found in Areas node" % area_name)
		return

	_activate(next)
	current_area = next

	# Notify singletons.
	emit_signal("area_changed", area_name)
	if is_instance_valid(GameBrain):
		GameBrain.on_area_changed(area_name)
	if is_instance_valid(MapSystem):
		MapSystem.on_area_entered(area_name)

	# Notify EnemyDirector — combat active in non-safe areas.
	if is_instance_valid(EnemyDirector):
		var is_safe := area_name in EnemyDirector.SAFE_AREAS
		EnemyDirector.set_combat_active(not is_safe)

	# Let the area itself know it was entered (optional hook).
	if next.has_method("on_area_entered"):
		next.on_area_entered(_player)

func _activate(node: Node) -> void:
	node.visible      = true
	node.process_mode = Node.PROCESS_MODE_INHERIT
