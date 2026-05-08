## Character polish — ambient barks wired for all 7 NPCs (run 27)
- THEME §12 MOTION & LIFE: NPC ambient bark system (NPC.gd run 26) had no
  authored lines in WorldBuilder.gd — every NPC was silent. All 7 are now
  wired with role-specific idle one-liners that float above their heads.
- _build_npc now reads "bark_lines" / "bark_min" / "bark_max" from each
  NPC dict and assigns npc.ambient_bark_lines / interval_min / interval_max.
- Bark intervals tuned per personality:
    Hala  15–26s  (trainer: never rests — drill counts at the air)
    Mara  18–30s  (merchant: stock-counting and coin grumbles)
    Edda  20–32s  (smith: forge grumbles, blade philosophy)
    Roan  20–34s  (stable: talks to Pippin and the road)
    Bram  22–35s  (innkeeper: mugs, fires, village gossip)
    Maeve 28–42s  (elder: slow, deliberate herb wisdom)
    Lyra  25–40s  (herbalist: talks to her plants)
- 6 bark lines per NPC (42 total) — authored per character voice, never
  duplicating existing dialogue lines. THEME §12 cited.
- Branch: auto/polisher


## Visual polish — god-ray wind-sway + hearth flicker depth (run 25)
- God-ray shafts (run 23 follow-up): per-shaft wind-sway via XZ position hash
  (freq 0.23 Hz, ±8% amplitude). 5 emitters now breathe independently.
- PlayerHome candle: dual-harmonic flicker (1.4 Hz primary + 5.18 Hz secondary).
  Second frequency incommensurable — never visually repeats within 30s window.
- PlayerHome hearth OmniLight3D: pulsed in _process at 0.73× candle rate,
  phase π/3, range 1.8–2.3 energy. Hearth + candle breathe in sympathy.
- THEME §12 cited: MOTION & LIFE — per-shaft independence, dual-harmonic flame.




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
