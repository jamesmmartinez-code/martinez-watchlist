
## Adaptive Difficulty per Player (run 24)
- player_difficulty_state: dict in World.gd tracking session deaths/kills/seconds
- diff_scalar in [0.70, 1.30]: <0.90 = eased, 0.90-1.10 = normal, >1.10 = hardened
- _apply_adaptive_difficulty() fires every 10s, group-calls receive_difficulty_scalar on enemies
- Enemy live params (cooldown/chase_speed/damage) lerp 40% toward target each push
- HUD: DifficultyLabel shows ▿ eased / ◇ normal / ▴ hardened
- Two-axis system: faction pressure (spawn-time) × player performance (live 10s pulse)





## Enchant+Shop System (run 22)
- Edda: Reforge, Enchant (8 shards, random prefix), Sell Weapon (60%)
- Mara: buy panel (potions, antidote, crystal shard)
- first_enchant_done -> achievement first_enchant -> title the Rune-Touched


## God-rays through Canopy (run 23)
- 5 GPUParticles3D shaft emitters placed in Whisperwood NW/W arc at canopy height (5.5m)
- GOD_RAY_SPOTS schema in WorldBuilder.gd — warm amber/gold tints (Color ~1.0, 0.85, 0.50)
- Shafts fall downward 0.10-0.20 m/s with tangential sway — THEME §12 motion
- World.gd time-of-day fade: amount_ratio dims at dusk, off at night, full at midday
- group "god_ray_shafts" is the read/write hook for future weather/weather passes

## Player Home — Briarwood Cottage (run 24)
- Cottage at Vector3(0, 0, 14) — north edge of Briarwood plaza, always visible
- Interior (hearth flame, candle flicker, storage chest, chimney smoke) unlocks after first_quest_done
- PlayerHome.gd joins group "player_home" for future WeatherSystem / SeasonSystem hooks
- StorageChest joins group "chests" — Minimap plots bronze ring on it
- World flag "player_home_visited" set on first E-key interaction
- Achievement "hearthkeeper" / title "the Hearthkeeper" unlocks on first_quest_done + player_home_visited
