extends CanvasLayer
## 2026-05-06 — debug HoverInspector. Mouse over any object → tooltip shows
## its name, class, world-AABB height, and parent group. Helps diagnose
## "what is this giant brown thing" without console-diving.
##
## Toggle with F3. On by default in dev builds.

var _enabled: bool = true
var _label: Label
var _last_target: Node = null

func _ready() -> void:
	layer = 100  # render on top
	_label = Label.new()
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_font_size_override("font_size", 14)
	_label.position = Vector2(20, 20)
	_label.size = Vector2(500, 100)
	_label.visible = false
	add_child(_label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_enabled = not _enabled
		_label.visible = _enabled
		print("[HoverInspector] %s" % ("ON" if _enabled else "OFF"))
		return
	if not _enabled: return
	if event is InputEventMouseMotion:
		_inspect_under_mouse(event.position)

func _inspect_under_mouse(mouse_pos: Vector2) -> void:
	var vp := get_viewport()
	if vp == null: return
	var cam := vp.get_camera_3d()
	if cam == null: return
	var from: Vector3 = cam.project_ray_origin(mouse_pos)
	var dir: Vector3 = cam.project_ray_normal(mouse_pos)
	var to: Vector3 = from + dir * 1000.0
	var space := cam.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		_label.text = "(nothing under cursor)"
		_label.position = mouse_pos + Vector2(15, 15)
		return
	var node: Node = hit.get("collider", null)
	if node == null:
		_label.text = "(hit unknown)"
		return
	# Find a meaningful name — walk up to find named ancestor
	var named: Node = node
	while named != null and (named.name == "" or named.name.begins_with("@")):
		named = named.get_parent()
	var name_str: String = str(named.name) if named != null else "?"
	var class_str := node.get_class()
	# Compute world AABB by walking VisualInstance3D children of the collider's parent
	var aabb_str := "?"
	var parent3d: Node = node.get_parent()
	if parent3d is Node3D:
		var aabb := AABB()
		var has: bool = false
		for v in (parent3d as Node3D).find_children("*", "VisualInstance3D", true):
			var vi := v as VisualInstance3D
			if vi == null: continue
			var a := vi.global_transform * vi.get_aabb()
			if not has: aabb = a; has = true
			else: aabb = aabb.merge(a)
		if has:
			aabb_str = "%.1fm tall × %.1fm wide" % [aabb.size.y, max(aabb.size.x, aabb.size.z)]
	# Group membership
	var groups_str := ""
	if named != null:
		var gs := named.get_groups()
		if gs.size() > 0:
			groups_str = " [%s]" % ", ".join(gs.map(func(g): return str(g)))
	# Path from root for navigation
	var path_str: String = str(named.get_path()) if named != null else ""
	_label.text = "%s%s\n  class: %s\n  AABB:  %s\n  path:  %s\n  hit:   %s" % [
		name_str, groups_str, class_str, aabb_str, path_str, hit.position
	]
	_label.position = mouse_pos + Vector2(15, 15)
