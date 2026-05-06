"""
fbx2glb.py — convert every .fbx under eldoria-godot/assets/animations/source/
to a matching .glb under eldoria-godot/assets/animations/imported/, preserving
the pack folder structure.

Stage 1 of the Animation Sourcer pipeline. Stage 2
(scripts/dev/build_anim_library.gd) reads the .glb output and packs it into
humanoid_*.tres AnimationLibrary resources.

Run with Blender (3.4+ recommended; Mixamo FBX needs a recent FBX importer):

    blender --background --python tools/fbx2glb.py

Or limit to specific files / packs by editing INCLUDE_PATTERNS.

WHY Blender vs FBX2glTF: Blender's FBX importer reliably preserves Mixamo
animation curves, mixamorig:* bone names, and the T-pose rest. FBX2glTF
sometimes drops the rest pose or flattens the rig hierarchy on packs that
ship without "with skin", which is the case for ANY Mixamo download after
the first one in a session.
"""
import bpy
import os
import sys
import glob

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_ROOT = os.path.join(REPO_ROOT, "eldoria-godot", "assets", "animations", "source")
OUTPUT_ROOT = os.path.join(REPO_ROOT, "eldoria-godot", "assets", "animations", "imported")

# Optional filter — leave [] to convert ALL .fbx under SOURCE_ROOT.
# Example: ["Pro_Melee_Axe_Pack/*.fbx", "Gestures_Pack_Basic/*.fbx"]
INCLUDE_PATTERNS = []


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def convert_one(fbx_path: str, glb_path: str) -> bool:
    print(f"  {os.path.relpath(fbx_path, REPO_ROOT)}", flush=True)
    reset_scene()
    try:
        bpy.ops.import_scene.fbx(
            filepath=fbx_path,
            use_anim=True,
            use_custom_props=False,
            ignore_leaf_bones=False,
            automatic_bone_orientation=False,
        )
    except Exception as e:
        print(f"    ! FBX import failed: {e}", flush=True)
        return False

    os.makedirs(os.path.dirname(glb_path), exist_ok=True)
    try:
        bpy.ops.export_scene.gltf(
            filepath=glb_path,
            export_format="GLB",
            export_animations=True,
            export_animation_mode="ACTIONS",
            export_optimize_animation_size=True,
            export_skins=True,
            export_def_bones=False,
            export_yup=True,
        )
    except Exception as e:
        print(f"    ! GLB export failed: {e}", flush=True)
        return False
    return True


def collect_fbx() -> list[str]:
    if INCLUDE_PATTERNS:
        out = []
        for pat in INCLUDE_PATTERNS:
            out.extend(glob.glob(os.path.join(SOURCE_ROOT, pat)))
        return sorted(out)
    out = []
    for root, _, files in os.walk(SOURCE_ROOT):
        for fn in files:
            if fn.lower().endswith(".fbx"):
                out.append(os.path.join(root, fn))
    return sorted(out)


def main():
    fbx_files = collect_fbx()
    if not fbx_files:
        print(f"No .fbx files found under {SOURCE_ROOT}", file=sys.stderr)
        sys.exit(1)
    print(f"=== fbx2glb: {len(fbx_files)} files ===", flush=True)
    ok = 0
    skipped = 0
    failed = 0
    for fbx in fbx_files:
        rel = os.path.relpath(fbx, SOURCE_ROOT)
        glb = os.path.join(OUTPUT_ROOT, rel[:-4] + ".glb")
        # Skip if up-to-date.
        if os.path.isfile(glb) and os.path.getmtime(glb) >= os.path.getmtime(fbx):
            skipped += 1
            continue
        if convert_one(fbx, glb):
            ok += 1
        else:
            failed += 1
    print(f"=== done: {ok} converted, {skipped} up-to-date, {failed} failed ===", flush=True)


if __name__ == "__main__":
    main()
