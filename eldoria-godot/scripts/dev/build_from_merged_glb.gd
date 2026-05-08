@tool
# scripts/dev/build_from_merged_glb.gd
# One-shot script: reads humanoid_base.glb (pre-merged, all 13 slots named correctly)
# and writes humanoid_base.tres AnimationLibrary.
#
# Run headless:
#   <godot_bin> --headless --path eldoria-godot \
#     --script res://scripts/dev/build_from_merged_glb.gd
#
# Requires: assets/animations/humanoid_base.glb (already on main)
# Produces: assets/animations/humanoid_base.tres

extends SceneTree

const GLB_PATH   := "res://assets/animations/humanoid_base.glb"
const OUT_PATH   := "res://assets/animations/humanoid_base.tres"

func _init() -> void:
	print("=== Building humanoid_base.tres from merged GLB ===")

	if not ResourceLoader.exists(GLB_PATH):
		push_error("Missing: " + GLB_PATH)
		quit(1)
		return

	var packed := load(GLB_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load GLB as PackedScene: " + GLB_PATH)
		quit(1)
		return

	var inst := packed.instantiate()
	var ap   := _find_anim_player(inst)
	if ap == null:
		push_error("No AnimationPlayer found in GLB scene tree")
		inst.queue_free()
		quit(1)
		return

	var lib := AnimationLibrary.new()
	var ok  := 0

	for anim_name in ap.get_animation_list():
		var anim := ap.get_animation(anim_name)
		if anim == null:
			continue
		var copy : Animation = anim.duplicate(true)
		lib.add_animation(StringName(anim_name), copy)
		print("  added '%s'  (%.3fs)" % [anim_name, anim.length])
		ok += 1

	inst.queue_free()

	var err := ResourceSaver.save(lib, OUT_PATH)
	if err == OK:
		print("\n-> Wrote %s  (%d animations)" % [OUT_PATH, ok])
		quit(0)
	else:
		push_error("ResourceSaver.save failed (err=%d)" % err)
		quit(1)


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for child in n.get_children():
		var found := _find_anim_player(child)
		if found != null:
			return found
	return null

