

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
