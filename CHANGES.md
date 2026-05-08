## 2026-05-08 Auto: run 23 -- God-rays through canopy
I'm building: God-rays through canopy (Backlog #5)
THEME §1 cited: painterly warm amber light shafts through Whisperwood
THEME §12 cited: GPUParticles3D shafts drift/breathe — no static quads
THEME §13 cited: emitters at canopy height 5.5m, shafts fall to ground, no below-ground spawn
Mood board panel: dawn light through forest canopy, Ghibli/BotW morning mist
Files: WorldBuilder.gd +GOD_RAY_SPOTS const +_build_god_rays | World.gd +daylight god_ray_shafts fade
5-output: i=_safe_call wired in _ready; ii=GOD_RAY_SPOTS schema (5 emitters, NW/W arc); iii=_dlog feedback on spawn; iv=_make_soft_particle_texture+alpha ramp (no white-blob per PROBLEMS_LOG §1.3); v=god_ray_shafts group + World.gd amount_ratio tod hook
Next: Housing/player-shaped spaces or Adaptive difficulty

## Tech debt

### §15 Asset Budget Violation — Hero.glb (2026-05-08)
- **File**: `eldoria-godot/assets/models/Hero.glb`
- **Size**: 29 MiB (30,258 KB) — exceeds 20 MiB soft cap and 25 MiB hard cap per OPERATIONS.md §15
- **Status**: REFERENCED — cannot delete
  - Referenced in: `eldoria-godot/scripts/Player.gd`, `eldoria-godot/scripts/CharacterSelect.gd`, `eldoria-godot/scenes/Main.tscn`
- **Action required**: Compress or LOD-split Hero.glb to bring under 20 MiB before Cloudflare Pages migration
- **Detected by**: QA Watchdog run 2026-05-08T07:12 UTC



## 2026-05-08 Auto: run 22 -- Smith Edda forge UI (enchant/sell/buy)
Building: Forge UI enchant+sell+Mara shop
THEME s1 (parchment UI) + s12 (toast/button motion)
Files: Inventory.gd +enchant/sell/buy | World.gd +3 buttons+shop | Achievements.gd +first_enchant
5-output: i=show_dialogue wired; ii=attempt_* schema; iii=toast feedback; iv=first_enchant achievement; v=Achievements hook+ShopBtn role dispatch
Next: NPC memory or god-rays