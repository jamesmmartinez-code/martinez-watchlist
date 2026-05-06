# Animation Sourcer — Mac batch step

The cloud agent can't reach `~/Documents/Claude/Projects/Realm of Eldoria/mixamo/`,
so the heavy retarget step has to run on your Mac mini once. After that, every
~20 min the cloud half wires the resulting `humanoid_base.glb` into every
NPC/boss `.tscn` automatically.

## One-time setup

1. **Install Blender** (only if you don't have it yet):

   ```sh
   brew install --cask blender
   ```

2. **Make sure your Mixamo dump is in place** at:

   ```
   ~/Documents/Claude/Projects/Realm of Eldoria/mixamo/
   ```

   Each pack subfolder should contain its `Ch05_nonPBR.fbx` plus the animation
   FBXs. Loose top-level FBXs (`Idle.fbx`, `Walking.fbx`, etc.) are also picked up.

## Run the batch

From the repo root (`~/Documents/Claude/Projects/Realm of Eldoria/`):

```sh
/Applications/Blender.app/Contents/MacOS/Blender \
    --background --python outputs/animations/build_humanoid_base.py
```

It takes a few minutes (480+ FBXs to import). When it finishes, you'll see a
report like:

```
[anim] CANONICAL ANIMATION MATCHES
[anim] ============================================================
[anim]   OK         idle       →  breathing_idle
[anim]   OK         walk       →  walking
[anim]   OK         run        →  running
[anim]   OK         attack_1   →  sword_and_shield_slash
[anim]     MISSING  attack_3   →
[anim]   OK         hurt       →  hit_reaction
[anim]   OK         die        →  dying
...
```

If anything is `MISSING`, grab a matching clip off Mixamo, drop the FBX into
`mixamo/` (or as a top-level loose FBX), and re-run the same command.

## Commit the result

The script writes directly into the repo at:

```
eldoria-godot/assets/animations/humanoid_base.glb
```

Commit + push that file:

```sh
cd ~/Documents/Claude/Projects/Realm of Eldoria
git add eldoria-godot/assets/animations/humanoid_base.glb
git commit -m "Animation: regenerate humanoid_base.glb from Mixamo dump"
git push
```

Once it's on `main`, the cloud Animation Sourcer agent will pick it up on its
next 20-minute cycle and:

* generate `humanoid_base.tres` (Godot AnimationLibrary)
* wire an `AnimationPlayer` referencing it into every `data/npcs/*.tscn`
* drop fallback players into `data/bosses/*.tscn`
* regenerate `_canonical_anim_map.tres` (role → animation name)

You don't have to do anything else after that.

## What the script does (for reference)

* Walks every Mixamo pack + loose FBX.
* Picks the first `Ch05_nonPBR.fbx` it finds as the canonical retarget rig.
* Imports each animation FBX, harvests the action, renames it by filename
  (lowercased, spaces → underscores).
* Pushes every action as an NLA strip on the canonical armature.
* Exports a single `humanoid_base.glb` (~30–80 MB, no LFS needed).
* Fuzzy-matches the canonical 12 clips (`idle / walk / run / attack_1..3 /
  hurt / die / victory / wave / yes / no`) and reports any gaps.

The script is idempotent — re-run it any time you add/remove FBXs in the
Mixamo folder.
