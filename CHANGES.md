- QA 2026-05-08T13:50 UTC: Build=None (no workflow runs yet), Pages=building, §15 violation: Hero.glb 29MiB > 20MiB soft cap — REFERENCED in Main.tscn, cannot delete; already logged as tech debt. No new action taken this run.
- QA 2026-05-08T13:16 UTC: `eldoria-godot/assets/models/Hero.glb` is 29 MiB -- exceeds OPERATIONS.md §15 soft cap (20 MiB) and hard cap (25 MiB). Referenced in Main.tscn, cannot delete. Action: mesh optimization/LOD reduction needed.

## Tech debt
## 2026-05-08 Auto: run 24 -- Housing / Player Home (Backlog #10)
I'm building: Housing / player-shaped spaces (Backlog #10)
THEME §1 cited: timber-frame + thatched roof identical to village houses — no modern materials
THEME §3 cited: warm amber window glow, sunset-gold nameplate (#FFD86B)
THEME §12 cited: hearth CPUParticles3D sparks, candle sine-flicker in _process, chimney smoke
THEME §13 cited: all geometry base at y=0; no floating edges, no buried foundations
Mood board panel: cosy fantasy cottage at dusk, warm light through leaded windows
Files: scripts/PlayerHome.gd (NEW) | WorldBuilder.gd +HOME_POS +HOME_SCRIPT +_build_player_home | Achievements.gd +hearthkeeper
5-output: i=_build_player_home wired via _safe_call in WorldBuilder._ready; ii=HOME_POS+HOME_SCRIPT schema + interior_unlocked bool + "player_home" group; iii=E-key toast feedback ("Home. The hearth is warm." / locked line); iv=interior gated on has_world_flag("first_quest_done") re-evaluated each _ready; v="player_home" group hook (WeatherSystem/SeasonSystem) + World flag "player_home_visited" + Achievements "hearthkeeper" + "chests" group on StorageChest for Minimap pin
Next: Adaptive difficulty per-player (Backlog #11) or NPC faction dialogue for hearthkeeper title

- QA 2026-05-08: `eldoria-godot/assets/models/Hero.glb` is 30 MiB -- exceeds OPERATIONS.md s15 soft cap (20 MiB) and hard cap (25 MiB). Referenced in Main.tscn, cannot delete. Action: mesh optimization/LOD reduction needed.

## 2026-05-08 Auto: run 23 -- God-rays through canopy
I'm building: God-rays through canopy (Backlog #5)
THEME Â§1 cited: painterly warm amber light shafts through Whisperwood
THEME Â§12 cited: GPUParticles3D shafts drift/breathe â no static quads
THEME Â§13 cited: emitters at canopy height 5.5m, shafts fall to ground, no below-ground spawn
Mood board panel: dawn light through forest canopy, Ghibli/BotW morning mist
Files: WorldBuilder.gd +GOD_RAY_SPOTS const +_build_god_rays | World.gd +daylight god_ray_shafts fade
5-output: i=_safe_call wired in _ready; ii=GOD_RAY_SPOTS schema (5 emitters, NW/W arc); iii=_dlog feedback on spawn; iv=_make_soft_particle_texture+alpha ramp (no white-blob per PROBLEMS_LOG Â§1.3); v=god_ray_shafts group + World.gd amount_ratio tod hook
Next: Housing/player-shaped spaces or Adaptive difficulty

## Tech debt

### Â§15 Asset Budget Violation â Hero.glb (2026-05-08)
- **File**: `eldoria-godot/assets/models/Hero.glb`
- **Size**: 29 MiB (30,258 KB) â exceeds 20 MiB soft cap and 25 MiB hard cap per OPERATIONS.md Â§15
- **Status**: REFERENCED â cannot delete
  - Referenced in: `eldoria-godot/scripts/Player.gd`, `eldoria-godot/scripts/CharacterSelect.gd`, `eldoria-godot/scenes/Main.tscn`
- **Action required**: Compress or LOD-split Hero.glb to bring under 20 MiB before Cloudflare Pages migration
- **Detected by**: QA Watchdog run 2026-05-08T07:12 UTC



## 2026-05-08 Auto: run 22 -- Smith Edda forge UI (enchant/sell/buy)
Building: Forge UI enchant+sell+Mara shop
THEME s1 (parchment UI) + s12 (toast/button motion)
Files: Inventory.gd +enchant/sell/buy | World.gd +3 buttons+shop | Achievements.gd +first_enchant
5-output: i=show_dialogue wired; ii=attempt_* schema; iii=toast feedback; iv=first_enchant achievement; v=Achievements hook+ShopBtn role dispatch
Next: NPC memory or god-rays