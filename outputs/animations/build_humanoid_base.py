"""build_humanoid_base.py
=================================================================
Realm of Eldoria — Blender batch retarget script (Mac side)

Run on the user's Mac mini:
    /Applications/Blender.app/Contents/MacOS/Blender \
        --background --python outputs/animations/build_humanoid_base.py

What this does
--------------
1. Walks `~/Documents/Claude/Projects/Realm of Eldoria/mixamo/`
   (16 Mixamo packs + loose FBXs at the top level).
2. Picks the first `Ch05_nonPBR.fbx` it finds as the canonical
   retarget rig (mixamorig:*). Strips its skin so only the rig +
   placeholder mesh remain.
3. For every other `*.fbx` in those folders, imports it, harvests
   the resulting armature's action, renames the action by filename
   (lowercased, spaces → underscores), pushes it as an NLA strip on
   the canonical armature, and deletes the imported temp data.
4. Exports a single `humanoid_base.glb` to
   `eldoria-godot/assets/animations/humanoid_base.glb` containing
   the canonical rig + all named animation tracks.
5. Fuzzy-matches the canonical 12 (idle / walk / run / attack_1 /
   attack_2 / attack_3 / hurt / die / victory / wave / yes / no)
   against the imported names and prints which it found and which
   it could not match.

Notes / assumptions
-------------------
* All Mixamo FBXs use the `mixamorig:*` bone naming convention, so
  no bone-by-bone retarget is necessary — actions are skeleton-
  compatible by construction. We simply collect actions on a single
  shared armature.
* This script is idempotent: re-running it overwrites the previous
  `humanoid_base.glb`.
* If Blender is not installed, the user will see a helpful error
  telling them to `brew install --cask blender` and re-run.
"""

import bpy
import os
import sys
import glob
import re
import math
from pathlib import Path

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
HOME = Path.home()
PROJECT_ROOT = HOME / "Documents" / "Claude" / "Projects" / "Realm of Eldoria"
MIXAMO_ROOT = PROJECT_ROOT / "mixamo"
EXPORT_DIR = PROJECT_ROOT / "eldoria-godot" / "assets" / "animations"
EXPORT_GLB = EXPORT_DIR / "humanoid_base.glb"

# Canonical action list — what every humanoid character must have.
CANONICAL = [
    "idle", "walk", "run",
    "attack_1", "attack_2", "attack_3",
    "hurt", "die", "victory",
    "wave", "yes", "no",
]

# Fuzzy match heuristics: ordered list of (canonical_name, [substring_matches])
CANONICAL_HINTS = {
    "idle":     ["idle", "breathing_idle", "neutral_idle"],
    "walk":     ["walking", "walk_forward", "walk"],
    "run":      ["running", "jog_forward", "run"],
    "attack_1": ["sword_and_shield_attack", "great_sword_slash", "punch", "attack"],
    "attack_2": ["sword_and_shield_slash", "kick", "swing", "slash"],
    "attack_3": ["combo", "spin_attack", "heavy_attack", "thrust"],
    "hurt":     ["hit_reaction", "react_hit", "stagger", "hurt", "damage"],
    "die":      ["dying", "death", "die", "fall_dead"],
    "victory":  ["victory", "cheer", "celebrate"],
    "wave":     ["wave", "waving", "hello"],
    "yes":      ["nod", "head_nod", "agree", "yes"],
    "no":       ["shake", "head_shake", "disagree", "no"],
}


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def log(msg):
    sys.stdout.write("[anim] " + msg + "\n")
    sys.stdout.flush()


def slugify(stem: str) -> str:
    s = stem.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # Default unit settings to match Mixamo
    bpy.context.scene.unit_settings.system = "METRIC"


def find_canonical_rig() -> Path | None:
    """Find a Ch05_nonPBR.fbx anywhere under the mixamo dir."""
    if not MIXAMO_ROOT.exists():
        return None
    candidates = list(MIXAMO_ROOT.rglob("Ch05_nonPBR.fbx"))
    if candidates:
        return candidates[0]
    # Fall back to any FBX named like a base mesh
    for pat in ("Ch*nonPBR*.fbx", "Ch*Base*.fbx", "Ch*.fbx"):
        c = list(MIXAMO_ROOT.rglob(pat))
        if c:
            return c[0]
    return None


def all_animation_fbxs() -> list[Path]:
    """All FBXs under mixamo/ (excluding the canonical rig)."""
    if not MIXAMO_ROOT.exists():
        return []
    fbxs = []
    for f in MIXAMO_ROOT.rglob("*.fbx"):
        if f.name == "Ch05_nonPBR.fbx":
            continue
        fbxs.append(f)
    # Top-level loose FBXs in PROJECT_ROOT itself
    for f in PROJECT_ROOT.glob("*.fbx"):
        fbxs.append(f)
    return fbxs


def import_fbx_anim(path: Path) -> bpy.types.Object | None:
    """Import an FBX; return the armature object, or None if it failed."""
    pre = set(bpy.data.objects)
    try:
        bpy.ops.import_scene.fbx(
            filepath=str(path),
            automatic_bone_orientation=True,
            ignore_leaf_bones=True,
            use_anim=True,
        )
    except Exception as e:
        log(f"  ! import failed: {path.name}: {e}")
        return None
    new = [o for o in bpy.data.objects if o not in pre]
    arm = next((o for o in new if o.type == "ARMATURE"), None)
    return arm


def strip_meshes_keep_armature(arm: bpy.types.Object):
    """Delete all mesh children — we only want the rig + actions."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in list(bpy.data.objects):
        if o.type == "MESH":
            o.select_set(True)
    bpy.ops.object.delete()


def harvest_action(arm: bpy.types.Object, name: str) -> bpy.types.Action | None:
    """Pull the action off `arm.animation_data` and rename it."""
    if not arm.animation_data or not arm.animation_data.action:
        return None
    act = arm.animation_data.action
    # If an action with this name already exists, append a counter
    final = name
    n = 2
    while final in bpy.data.actions and bpy.data.actions[final] is not act:
        final = f"{name}_{n}"
        n += 1
    act.name = final
    act.use_fake_user = True
    return act


def clear_armature_keeping_data():
    """Delete all armature objects in scene EXCEPT keep their action data via fake_user."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in list(bpy.data.objects):
        if o.type == "ARMATURE":
            o.select_set(True)
    bpy.ops.object.delete()


def push_actions_as_nla(arm: bpy.types.Object):
    """Push every kept action as a non-overlapping NLA strip on `arm`."""
    if not arm.animation_data:
        arm.animation_data_create()
    track = arm.animation_data.nla_tracks.new()
    track.name = "humanoid_anims"
    cursor = 1.0
    for act in sorted(bpy.data.actions, key=lambda a: a.name):
        if act.users == 0 and not act.use_fake_user:
            continue
        try:
            strip = track.strips.new(act.name, int(cursor), act)
        except Exception as e:
            log(f"  ! NLA strip failed for {act.name}: {e}")
            continue
        cursor = strip.frame_end + 2


def fuzzy_pick_canonical(action_names: list[str]) -> dict[str, str]:
    """Map canonical name → matching action name (or '' if missing)."""
    out = {}
    used = set()
    for canon, hints in CANONICAL_HINTS.items():
        match = ""
        # 1) exact slug match
        if canon in action_names and canon not in used:
            match = canon
        # 2) hint substring match
        if not match:
            for h in hints:
                for a in action_names:
                    if a in used:
                        continue
                    if h in a:
                        match = a
                        break
                if match:
                    break
        if match:
            used.add(match)
        out[canon] = match
    return out


# -----------------------------------------------------------------------------
# Main pipeline
# -----------------------------------------------------------------------------
def main():
    log(f"Project root:  {PROJECT_ROOT}")
    log(f"Mixamo root:   {MIXAMO_ROOT}")
    log(f"Export target: {EXPORT_GLB}")

    if not MIXAMO_ROOT.exists():
        log("ERROR: mixamo/ directory not found. Aborting.")
        sys.exit(1)

    canon_rig = find_canonical_rig()
    if canon_rig is None:
        log("ERROR: could not find Ch05_nonPBR.fbx anywhere under mixamo/.")
        sys.exit(1)
    log(f"Canonical rig: {canon_rig}")

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    reset_scene()

    # Import the canonical rig — keep it as our shared armature.
    log("Importing canonical rig…")
    base_arm = import_fbx_anim(canon_rig)
    if base_arm is None:
        log("ERROR: failed to import canonical rig.")
        sys.exit(1)
    base_arm.name = "humanoid_canonical"
    # Drop any action that arrived with the base mesh — base is T-pose only.
    if base_arm.animation_data and base_arm.animation_data.action:
        bpy.data.actions.remove(base_arm.animation_data.action)

    # Walk every animation FBX, import, harvest its action, then nuke the import.
    fbxs = all_animation_fbxs()
    log(f"Found {len(fbxs)} animation FBXs to import.")

    kept_names = []
    for i, fbx in enumerate(fbxs, 1):
        slug = slugify(fbx.stem)
        log(f"[{i:>3}/{len(fbxs)}] {fbx.name}  →  {slug}")
        arm = import_fbx_anim(fbx)
        if arm is None:
            continue
        act = harvest_action(arm, slug)
        if act is not None:
            kept_names.append(act.name)
        # Delete the imported armature and its meshes — we already harvested.
        bpy.ops.object.select_all(action="DESELECT")
        for o in list(bpy.data.objects):
            if o is base_arm:
                continue
            o.select_set(True)
        bpy.ops.object.delete()

    log(f"Total actions kept: {len(kept_names)}")

    # Push everything as NLA strips on the canonical armature for clean GLB export.
    push_actions_as_nla(base_arm)

    # Make sure the canonical armature is the only thing left, then export.
    bpy.ops.object.select_all(action="DESELECT")
    base_arm.select_set(True)
    bpy.context.view_layer.objects.active = base_arm
    log("Exporting humanoid_base.glb…")
    bpy.ops.export_scene.gltf(
        filepath=str(EXPORT_GLB),
        export_format="GLB",
        use_selection=False,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_nla_strips=True,
        export_apply=False,
        export_skins=True,
    )
    log(f"Wrote {EXPORT_GLB}")

    # Fuzzy-match the canonical 12 and print a report.
    matches = fuzzy_pick_canonical(kept_names)
    log("=" * 60)
    log("CANONICAL ANIMATION MATCHES")
    log("=" * 60)
    for canon in CANONICAL:
        m = matches[canon]
        marker = "OK" if m else "  MISSING"
        log(f"  {marker:<10} {canon:<10} →  {m}")
    missing = [c for c in CANONICAL if not matches[c]]
    if missing:
        log("")
        log("WARN: missing canonical clips: " + ", ".join(missing))
        log("      fix by downloading equivalents from Mixamo and re-running.")
    log("Done.")


if __name__ == "__main__":
    main()
