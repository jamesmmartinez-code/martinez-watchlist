# Realm of Eldoria — Godot 4 project

## How to run (5 minutes once you've installed Godot)

1. **Install Godot 4.6** — you already have the download page open. Grab the **left button** (Godot Engine 4.6.2, *not* the .NET version). It's a single .app — drag it to `/Applications`.

2. **Open Godot.** When the project manager appears, click **Import**.

3. **Navigate to** this folder: `~/Library/Application Support/Claude/.../outputs/eldoria-godot/` and select `project.godot`.

4. Click **Import & Edit**. Godot opens the editor.

5. Press the **▶ Play** button (top-right) or hit **F5**. First run will ask which scene to play — pick `scenes/Main.tscn`.

## Controls

- **WASD** or **Arrow keys** — move
- **Right-mouse drag** — rotate camera
- **Mouse wheel** — zoom
- **Shift** — run (faster)
- **E** — interact with nearby NPCs
- **Space** — jump
- **Left-click** — attack

## What's in here

- `project.godot` — Godot project config + input bindings
- `scenes/Main.tscn` — main 3D scene (player, ground, NPCs, lighting, HUD)
- `scripts/Player.gd` — third-person character controller with stats (HP/MP/XP/Level)
- `scripts/CameraController.gd` — orbit camera with mouse-drag rotation
- `scripts/NPC.gd` — NPC interaction (proximity-based name labels + dialogue)
- `scripts/World.gd` — day/night cycle, dialogue UI, HUD bindings
- `assets/models/*.glb` — Soldier (player), CesiumMan (NPCs), Fox, Horse, Robot

## What's working in this scaffold

- Real Godot 4 third-person 3D with WASD movement, jump, run
- Camera follow with drag-to-rotate + scroll-to-zoom
- Two NPCs (Elder Maeve, Smith Edda) you can walk up to and press E
- Dialogue panel pops up with their text
- HP/MP/XP bars, level label
- Day/night cycle (1 real minute = 1 in-game hour)
- Procedural sky, fog, SSAO, glow, real shadows
- The 3D models from the HTML version (already imported)

## What's NOT yet in this scaffold (next iteration)

- Inventory system, gear equipping
- Combat (the click-attack just plays an anim)
- Quests
- Multiple zones / world transitions
- Music / sound effects
- AI dialogue (we'd hook the Anthropic API just like in the HTML)
- All the systems from the HTML version (talents, mythic, gathering, etc.)

## Why we moved to Godot

- The HTML file was 18,000 lines in one document. Editing was risky.
- Godot has real PBR rendering, real shadows, SSAO, real animation system.
- Real 3D editor — you can place props/buildings visually instead of by code.
- Asset Library — drop in fantasy character packs that look like fantasy.
- Web export — when we're ready, Godot can ship a browser build the kids play in their browser.

## Next steps

After you've got Godot installed and verified the scaffold runs, tell me what you want to port first:
- Combat system (with the existing 16 abilities)
- Inventory + gear visualization
- Multiple zones (forest, swamp, etc.)
- Add more NPCs / quests
- Better fantasy character models (Asset Library import)
