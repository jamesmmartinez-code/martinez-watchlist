@tool
# scripts/dev/build_anim_library.gd
# ----------------------------------------------------------------------------
# Animation Sourcer pipeline — STAGE 2 of 2.
#
# Stage 1 (LOCAL or CI, before this runs): convert every *.fbx in
#   assets/animations/source/**/ → *.glb in the SAME folder structure under
#   assets/animations/imported/<pack>/<file>.glb.
#   Use Blender headless or fbx2gltf:
#
#     # Blender (recommended — handles animation-only FBX cleanly):
#     blender --background --python tools/fbx2glb.py
#
#     # OR fbx2gltf (Facebook):
#     find assets/animations/source -iname '*.fbx' -print0 | \
#       xargs -0 -I{} bash -c 'OUT="${1/source/imported}"; OUT="${OUT%.fbx}.glb"; \
#         mkdir -p "$(dirname "$OUT")"; FBX2glTF -i "$1" -o "${OUT%.glb}"' _ {}
#
# Stage 2 (THIS SCRIPT): walks slot_mapping.json, opens each GLB as a
#   PackedScene, extracts its first non-empty animation, renames it to the
#   canonical slot, packs everything into a single AnimationLibrary .tres
#   per top-level mapping key (humanoid_base / humanoid_pathfinder / ...).
#
# Run headless (no editor UI):
#
#   <godot_bin> --headless --path eldoria-godot \
#     --script res://scripts/dev/build_anim_library.gd
#
# Outputs:
#   assets/animations/humanoid_base.tres
#   assets/animations/humanoid_pathfinder.tres
#   assets/animations/humanoid_vanguard.tres
#
# Per RIGGING_STANDARD.md every track in every output .tres should target
# `mixamorig:*` bones — Mixamo packs are compliant by default. The script
# logs any track whose target path doesn't match `mixamorig:*` so you know
# to remap before commit.
# ----------------------------------------------------------------------------
extends SceneTree

const SOURCE_ROOT_FBX := "res://assets/animations/source"
const IMPORTED_ROOT_GLB := "res://assets/animations/imported"
const MAPPING_PATH := "res://assets/animations/slot_mapping.json"
const OUTPUT_DIR := "res://assets/animations"

func _init() -> void:
    print("=== Eldoria Animation Library Builder ===")
    var mapping := _load_mapping()
    if mapping.is_empty():
        push_error("Could not load slot_mapping.json at %s" % MAPPING_PATH)
        quit(1)
        return

    var built := 0
    var slots_total := 0
    var slots_ok := 0
    for lib_name in mapping.keys():
        if String(lib_name).begins_with("_"):
            continue
        var lib_def: Dictionary = mapping[lib_name]
        var slots: Dictionary = lib_def.get("slots", {})
        if slots.is_empty():
            print("  (skip %s — empty slots)" % lib_name)
            continue
        var lib := AnimationLibrary.new()
        var lib_ok := 0
        var lib_total := 0
        for slot_name in slots.keys():
            lib_total += 1
            slots_total += 1
            var rel: String = slots[slot_name]
            # Look for a corresponding .glb in imported/, with .fbx fallback for
            # editor builds where Godot's bundled fbx2gltf is set up.
            var glb_path := "%s/%s" % [IMPORTED_ROOT_GLB, rel.replace(".fbx", ".glb")]
            var fbx_path := "%s/%s" % [SOURCE_ROOT_FBX, rel]
            var src_path := glb_path if ResourceLoader.exists(glb_path) else fbx_path
            if not ResourceLoader.exists(src_path):
                push_warning("  [%s/%s] missing source: %s" % [lib_name, slot_name, src_path])
                continue
            var packed := load(src_path) as PackedScene
            if packed == null:
                push_warning("  [%s/%s] load failed: %s" % [lib_name, slot_name, src_path])
                continue
            var inst := packed.instantiate()
            var ap: AnimationPlayer = _find_animation_player(inst)
            var anim: Animation = null
            var picked_name := ""
            if ap != null:
                # Mixamo exports one anim per file, named "mixamo.com" or similar.
                # Pick the longest non-trivial one to skip empty stub tracks.
                var best_len := -1.0
                for n in ap.get_animation_list():
                    var a := ap.get_animation(n)
                    if a != null and a.length > best_len:
                        best_len = a.length
                        anim = a
                        picked_name = n
            if anim == null:
                push_warning("  [%s/%s] no animation in %s" % [lib_name, slot_name, src_path])
                inst.queue_free()
                continue
            # Validate every bone-targeted track points at mixamorig:* per
            # RIGGING_STANDARD.md. Log violators — they need a remap.
            var bad_tracks := 0
            for ti in range(anim.get_track_count()):
                var path := String(anim.track_get_path(ti))
                # Skin/value/scale tracks may not hit a bone; only flag the
                # ones that look like skeleton paths but aren't canonical.
                if path.find(":") != -1 and path.find("mixamorig:") == -1:
                    bad_tracks += 1
            if bad_tracks > 0:
                push_warning("  [%s/%s] %d tracks not targeting mixamorig:*" % [lib_name, slot_name, bad_tracks])
            # Duplicate the resource so library owns its own copy (the loaded
            # PackedScene's Animation may be shared / read-only after import).
            var copy: Animation = anim.duplicate(true)
            lib.add_animation(StringName(slot_name), copy)
            lib_ok += 1
            slots_ok += 1
            inst.queue_free()
            print("  [%s] %-12s ← %s (%.2fs)" % [lib_name, slot_name, rel, anim.length])

        var out_path := "%s/%s.tres" % [OUTPUT_DIR, lib_name]
        var err := ResourceSaver.save(lib, out_path)
        if err == OK:
            print("  → wrote %s (%d/%d slots)\n" % [out_path, lib_ok, lib_total])
            built += 1
        else:
            push_error("  → save failed for %s (err=%d)" % [out_path, err])

    print("=== Build complete: %d libraries, %d/%d slots packed ===" % [built, slots_ok, slots_total])
    quit(0)


func _load_mapping() -> Dictionary:
    var f := FileAccess.open(MAPPING_PATH, FileAccess.READ)
    if f == null:
        return {}
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("slot_mapping.json did not parse as a Dictionary")
        return {}
    return parsed


func _find_animation_player(n: Node) -> AnimationPlayer:
    if n is AnimationPlayer:
        return n
    for c in n.get_children():
        var found := _find_animation_player(c)
        if found != null:
            return found
    return null
