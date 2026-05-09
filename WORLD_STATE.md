## Combat-feel polish — HP bar color lerp + attack telegraph (run 32)
- HP fill color: smooth tri-band lerp on hp ratio. >60% = green→yellow transition;
  30–60% = yellow→warm-red transition; <30% = warm-red deepen (0.90,0.20,0.10 → 0.70,0.05,0.05).
  No two-state pop — lerp is continuous per hp point. THEME §3 palette: warm red, not pure-red.
  Alden (9yo visual learner) reads "almost dead" at a glance; Owen (11yo mastery) gets
  tactical press/retreat intel. Zero new nodes — modulates existing HPFill StandardMaterial3D.
- Attack telegraph windup: in the 0.22s window before each swing, enemy label lerps from its
  base color toward warm-orange TELEGRAPH_COLOR (0.98, 0.38, 0.18) as _attack_timer → 0.
  At the moment the hit fires (_do_attack resets timer to attack_cooldown), the lerp immediately
  pulls back toward base — flash is fast, readable, self-resetting. Resets to base color also
  in chase and wander/idle states so a broken-off windup never leaves the label stuck orange.
- _label_base_color var cached at _ready (deferred 1 frame) so the reset value is exact, not
  a hardcoded white. TELEGRAPH_WINDOW + TELEGRAPH_COLOR defined as module-level consts for
  Godot 4.6 parse safety (not inside func body).
- THEME §12 MOTION & LIFE cited: static HP bar gains continuous color motion; label gains
  temporal motion — breathing danger before the hit lands.
- Branch: auto/polisher

## Balance polish — level-up stat grants + stat-delta popup (run 31)
- HP grant per level-up: 18 → 22 (+22%). Base 120 HP, +18 was thin for Alden
  (9yo visual learner who reads the HP bar). +22 = +18%/level: each ding
  visibly fills the bar further. TTK band intact: goblin (6 dmg) still takes
  20+ hits at level 5 — kid-safe recovery window preserved.
- MP grant per level-up: 10 → 14 (+40%). Base 30 MP left level-5 players at
  70 MP — one or two spells per fight. +14 reaches 86 MP at L5: enough for
  3–4 skill uses per fight. Encourages Owen (11yo mastery axis) to weave skills
  rather than hoard mana.
- Stat-delta popup: after "LEVEL UP!" floater, a second Label3D ("+22 HP  +14 MP",
  font 28, mint-green Color(0.55, 0.95, 0.65)) spawns offset +0.6 on X so the
  two floaters don't overlap. Reuses DAMAGE_NUMBER_SCRIPT billboard/fade — zero
  new nodes, zero scene edits. THEME §12: the level-up beat already fired; now
  it SPEAKS the gain rather than leaving kids guessing what changed.
- THEME §12 MOTION & LIFE cited: existing popup system deepened.
- Branch: auto/polisher


## Character polish — Enemy idle Y-bob breathing (run 30)
- Enemy.gd: _breathe_phase + _breathe_phase2 vars added; randomised per-enemy in _ready() so nearby
  goblins never rise/fall in unison (same pattern as NPC.gd run 25 dual-harmonic).
- _process(delta) added (was absent — Enemy.gd used only _physics_process). Fires dual-harmonic
  Y-bob on global_position.y when _state == "wander" (idle dwell-pause between steps).
  Primary: sin(t * 2.513 + phase) * 0.018 m (~0.40 Hz, slow chest-rise).
  Secondary: sin(t * 10.982 + phase2) * 0.006 m (~1.75 Hz, shoulder-shift).
- Wolves and crystal_guardian excluded: wolves are quadrupeds (Y-bob on four-legged silhouette
  reads as floating, not breathing); crystal_guardian is 4.00m — ±0.018m is invisible at that scale.
- _spawn_y cached at _ready() (alongside existing _spawn_pos) as the ground-truth rest height.
  bob writes to global_position.y = _spawn_y + bob — preserves THEME §13 ground contact.
  _respawn() already resets to _spawn_pos so _spawn_y stays correct across respawn cycles.
- THEME §12 §13 cited: every enemy in wander dwell-pause now visibly breathes; ground contact
  maintained via _spawn_y anchor. Deepens what NPC.gd already has to the enemy layer.
- Branch: auto/polisher



## NPC Relationship Score System (run 29)
- npc_memory[name] now carries gifts: int and insults: int in addition to visit fields
- npc_relationship_score(name) = clamp(gifts - insults, -10, 10) on World
- NPC.gd warmed_relationship_min tier: fires ABOVE visit-count, BELOW faction-pressure
  tier ordering: json-tree > npc_flag > world_flag > faction_pressure > relationship_score > visit_count
- Achievement villager_friend: any NPC score >= 3 -> title the Beloved (priority 18)
- record_npc_gift / record_npc_insult call _check_achievements on each write
- Future: attempt_enchant gift to Edda score +1 (wired next pass)


## Faction State — Bandit Road Defense (run 29)
- road_defense_score: float[0..10] in World.gd — increments on bandit kills (+1.0) and captain kills (+2.0)
- Decays 5%/s via _process so defended roads soften over time (THEME §12 MOTION — not permanent)
- defense_damper in update_bandit_pressure(): at score=5 reduces bandit boldness by ~0.15 below passive derivation
- bandit_road_cleared world flag: set when score>=3; triggers "The road breathes easier." toast + minimap ping
- _tick_bandit_patrol() fires every 90s: if boldness>0.50 spawns a lone Bandit Patrol 20m south of player
- Roan warmed_world_flag tier: "bandit_road_cleared" → 4 time-of-day gratitude lines fire when road is cleared
  but bandits_emergent is NOT active (player pre-empted the threat)
- THEME §1: consequence is proportional — each kill immediately shifts boldness; Roan notices
- THEME §12: score decays continuously; patrol timer ticks every frame; road is never static at high boldness

## Ambient NPC Barks (run 27)
- All 7 villagers now emit idle one-liner barks every 22-38s when player is not in interact range
- Bark lines authored per-role: Maeve (elder-wisdom), Edda (forge-rhythm), Mara (merchant-tallies),
  Lyra (botanical-dreamy), Bram (pub-warm), Roan (horse-road), Hala (drill-counts)
- NPC.gd bark system (run 26 scaffold) now fully activated — Label3D float + 3s fade
- THEME §12 MOTION & LIFE: village sounds inhabited, not posed; each NPC has a distinct voice
- group 'npcs' unchanged; schedule + dialogue-json systems compose without conflict


## Combat-feel polish — HP bar color + attack telegraph (run 28)
- HP bar color progression: green (>60%) → yellow (30–60%) → red (<30%).
  Smooth lerp on ratio — no two-state pop. Palette stays within THEME §3
  fantasy-warm range (warm red 0.90, 0.20, 0.10; no pure-red). Alden reads
  "almost dead" at a glance; Owen gets tactical press/retreat intel.
- Attack telegraph windup: enemy label flashes warm-orange (0.98, 0.38, 0.18)
  in the 0.22s window before each swing, lerping from base color as timer
  approaches 0. Label resets to base color in chase/idle states so a broken-
  off windup doesn't leave the name stuck orange.
- Both changes use existing scene nodes (_hp_bar HPFill material, _label) —
  zero new nodes or scene edits required. THEME §12 cited: the label now has
  temporal motion, "breathing" danger before the hit lands.
- THEME §12 MOTION & LIFE cited: static UI gains a timing cue.


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


## Enemy GLB Asset Wiring (run 25)
- Enemy.gd KIND_MODELS preload() crash removed; replaced with KIND_MODEL_PATHS + _get_kind_model(load())
- Active enemy GLB mappings: goblin→goblin.glb, goblin_scout→goblin_scout.glb, wolf→wolf.glb,
  bandit→bandit.glb, skeleton→skeleton.glb, crystal_elemental→crystal_elemental.glb
- bandit_captain resolves to bandit.glb until dedicated GLB ships
- crystal_guardian falls back to CesiumMan.glb placeholder (no GLB yet; SIZE_STANDARDS §2 scale-mult still applied)
- _NORMALIZE_TARGET_BY_KIND: bandit_captain clamped 2.30→2.50m (boss floor; joins boss_silhouettes)

## New Villagers — Village Guard + Farm Worker (run 30)
- **Village Guard** — warrior.glb, north gate Vector3(0,0,18), role=guard. Patrols gate day/night. Warm after first_quest_done. 5 barks 25-40s.
- **Farm Worker** — worker_girl.glb, east fields Vector3(18,0,5), role=villager. Field→market→home schedule. Memory tier at 2 visits. Warm after first_quest_done. 5 barks 20-35s.
- Both in group "npcs" — Minimap gold-dot plots. Both have 4-bucket schedule_anchors.
- warmed_relationship_min wiring added to _make_npc (completes run 29 schema).
