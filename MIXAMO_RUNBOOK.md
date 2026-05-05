# MIXAMO_RUNBOOK.md — How to plug Mixamo downloads into the game

James downloads `.fbx` files from mixamo.com. This file describes everything that happens after — most of it automated.

## Where to drop files

Save downloaded `.fbx` files into:
```
/Users/jamesmartinez/Documents/Claude/Projects/Realm of Eldoria/mixamo/
```
(The `mixamo/` subfolder. Create it if it doesn't exist.)

## Naming (helps the agent map to canonical slots — but optional)

Mixamo's default filenames are like `Breathing Idle.fbx`. Rename to match the canonical slots from RIGGING_STANDARD.md:
- `Breathing Idle.fbx` → `idle.fbx`
- `Walking.fbx` → `walk.fbx`
- `Running.fbx` → `run.fbx`
- `Sword And Shield Slash.fbx` → `attack_1.fbx`
- ...etc per the 12-slot list in MIXAMO_DOWNLOADS.md

If you don't rename, the Animation Sourcer agent will use fuzzy match (e.g. "Breathing Idle" → idle) but explicit names are more reliable.

## Push to repo (once files are ready)

Run:
```bash
bash "/Users/jamesmartinez/Documents/Claude/Projects/Realm of Eldoria/sync-mixamo.sh"
```
(Script provided below — copy + commit + push of all .fbx in mixamo/ to `eldoria-godot/assets/animations/source/`.)

## What happens automatically after push

1. **GitHub Action `build-eldoria.yml`** runs (~3 min):
   - Detects new `.fbx` in `assets/animations/source/`
   - Runs `fbx2gltf` (Facebook's converter, binary committed to `bin/`) to convert each to `.glb`
   - Imports the converted .glb in Godot headless
   - Extracts AnimationPlayer tracks from each
   - Builds `assets/animations/humanoid_base.tres` (a Godot AnimationLibrary)
   - Wires `Player.gd` and `NPC.gd` to load the library on `_ready()`
   - Exports the new web build
   - Commits everything to main
   - Cloudflare Worker auto-serves the new build at https://eldoria-api.james-m-martinez.workers.dev/eldoria/

2. **Animation Sourcer agent** (every 20 min) audits the result:
   - Confirms each canonical slot is populated
   - Updates `MIXAMO_DOWNLOADS.md` checkboxes
   - If any slots are still empty, files a TODO

3. **Hard-refresh game in Incognito** to see the new animations live (~5 min after push).

## Why mocap from Mixamo elevates Eldoria

Same animation data sits behind the character feel of Hades, Hollow Knight, Genshin Impact, hundreds of indie + AA games. It's free with your Adobe account — that's it. The kids' hero will breathe, walk, swing a sword the way real game protagonists do, not the floating T-pose we're stuck with right now.
