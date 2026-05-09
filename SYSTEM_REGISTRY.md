## NPC Relationship Score (run 29)
World.gd schema extension to npc_memory:
  npc_memory[name][gifts]: int  (incremented by record_npc_gift)
  npc_memory[name][insults]: int  (incremented by record_npc_insult)
World.gd new methods:
  record_npc_gift(npc_name: String) -> void      -- mutator, calls _check_achievements
  record_npc_insult(npc_name: String) -> void    -- mutator, calls _check_achievements
  npc_relationship_score(npc_name: String) -> int -- clamp(gifts-insults, -10, 10)
  npc_any_relationship_above(min_score: int) -> bool -- for achievement predicate
NPC.gd new exports:
  warmed_relationship_min: int (default 0 = disabled)
  warmed_relationship_dialogue_variants: PackedStringArray
  Tier position: ABOVE visit-count, BELOW faction-pressure
Achievements.gd:
  villager_friend: predicate kind=npc_relationship_min, min_score=3
    -> title the Beloved, priority 18
  _eval_predicate extended with npc_relationship_min kind


## Road Defense System (run 29)
World.gd schema:
  road_defense_score: float[0..10] — increments: bandit kill +1.0, bandit_captain kill +2.0; decays 5%/s
  _bandit_patrol_timer: float — counts up to BANDIT_PATROL_INTERVAL (90s), then fires _tick_bandit_patrol()
  BANDIT_PATROL_BOLDNESS_THRESHOLD: float = 0.50 — min boldness to spawn patrol
  ROAD_DEFENSE_DECAY: float = 0.05  — per-second decay multiplier
  ROAD_DEFENSE_CAP: float = 10.0    — max score
Mutators:
  record_road_kill(kind: String) — called by Enemy._die() for bandit/bandit_captain
    increments score, calls update_bandit_pressure(), sets bandit_road_cleared flag at score>=3
Evals:
  get_road_defense_score() -> float
  faction_pressure("bandits") -> float  (boldness; pre-existing)
Derived: update_bandit_pressure() defense_damper = clamp(score/CAP * 0.30, 0, 0.30)
  reduces raw bandit boldness proportionally — at score=10: -0.30 damper
Patrol: _tick_bandit_patrol() — spawns "Bandit Patrol" bandit 20m south of player via WorldBuilder._spawn_enemy
Hooks:
  Enemy._die() bandit/bandit_captain → record_road_kill()
  World._process → _bandit_patrol_timer → _tick_bandit_patrol()
  Roan warmed_world_flag:"bandit_road_cleared" (4 lines, time-of-day buckets)
Flags: bandit_road_cleared (world_flag, set at score>=3, never cleared this session)

## Ambient NPC Barks (run 27)
Schema: NPCS[] dict key `bark_lines: Array[String]` (4 lines per NPC)
Wiring: WorldBuilder._make_npc() → npc.ambient_bark_lines.append() loop
Runtime: NPC._ready sets _bark_cooldown = randf_range(interval_min, interval_max)
         NPC._process → _tick_ambient_bark(delta) → Label3D float + 3s fade
Guard: no bark when _bark_label != null (dedup); no bark when player in interact range
Intervals: NPC.gd defaults 22-38s (per-role override queued for next pass)
NPCs wired: Elder Maeve, Smith Edda, Mara the Merchant, Herbalist Lyra,
            Innkeeper Bram, Stablemaster Roan, Trainer Hala




## Adaptive Difficulty per Player (run 24)
player_difficulty_state: {session_deaths: int, session_kills: int, session_seconds: float, diff_scalar: float[0.70-1.30], tier: String}
World mutators: record_player_death(), record_player_kill(kind)
World evals: get_difficulty_tier() -> String, get_difficulty_scalar() -> float
World internal: _apply_adaptive_difficulty() every 10s, _refresh_difficulty_hud(tier)
Enemy hook: receive_difficulty_scalar(scalar) — live-lerps cooldown/chase_speed/damage
Player hooks: _die() -> record_player_death | on_enemy_killed() -> record_player_kill
HUD: DifficultyLabel at Vector2(8,96) below RenownLabel — glyph ▿/◇/▴





## Shop+Enchant (run 22)
Mara: MARA_STOCK, _build_shop_panel, attempt_buy_item
Edda enchant: ENCHANT_SHARD_COST=8, attempt_enchant
Edda sell: SELL_RATE=0.60, attempt_sell_weapon
Achievement: first_enchant (world_flag first_enchant_done, priority 28)


## God-ray Shafts (run 23)
GOD_RAY_SPOTS: Array of 5 dicts (pos: Vector3, color: Color, amount: int)
_build_god_rays: spawns GPUParticles3D shaft emitters, joins group "god_ray_shafts"
World.gd hook: amount_ratio fade keyed to elev2 (sin of time_of_day arc)
Schema: shaft_color=warm amber, emission_energy_multiplier=0.80, lifetime=32s, spread=4deg

## Player Home (run 24)
PlayerHome.gd: StaticBody3D at WorldBuilder.HOME_POS = Vector3(0,0,14)
  interior_unlocked: bool — gated on World.has_world_flag("first_quest_done")
  unlock_interior(): public — spawns hearth light+flame, candle, storage chest, chimney smoke
  _on_player_interact(): sets world_flag "player_home_visited", shows toast
  group "player_home": hook for WeatherSystem / SeasonSystem / future housing passes
  group "chests" (StorageChest only): Minimap plots bronze ring
WorldBuilder hooks: HOME_POS const, HOME_SCRIPT const, _build_player_home() via _safe_call
Achievement "hearthkeeper": predicate all_of[first_quest_done, player_home_visited] → title "the Hearthkeeper" (priority 22)



## Enemy Model Registry (run 25)
KIND_MODEL_PATHS: Dictionary — maps enemy_kind string → GLB asset path
  "goblin"            → "res://assets/models/enemies/goblin.glb"
  "goblin_scout"      → "res://assets/models/enemies/goblin_scout.glb"
  "wolf"              → "res://assets/models/enemies/wolf.glb"
  "bandit"            → "res://assets/models/enemies/bandit.glb"
  "skeleton"          → "res://assets/models/enemies/skeleton.glb"
  "crystal_elemental" → "res://assets/models/enemies/crystal_elemental.glb"
_get_kind_model(kind: String) -> PackedScene
  bandit_captain resolves to bandit path
  Unknown kinds or missing files return null → caller uses enemy_model placeholder
  load() used (not preload()) so missing assets degrade gracefully at runtime
_NORMALIZE_TARGET_BY_KIND: per-kind height targets (scale-eng 2026-05-08)
  crystal_guardian=4.00m, bandit_captain=2.50m, wolf=1.00m, goblin_warlord=2.80m

## New Villager NPCs — Village Guard + Farm Worker (run 30)
NPC_MODELS: "Village Guard"→warrior.glb, "Farm Worker"→worker_girl.glb
NPC_SCALES: Village Guard 1.05×, Farm Worker 1.00×
NPCS[7]: Village Guard — role=guard, pos=Vector3(0,0,18), warm_flag=first_quest_done, 4-bucket schedule, 5 barks 25-40s
NPCS[8]: Farm Worker — role=villager, pos=Vector3(18,0,5), warm_flag=first_quest_done, memory_visits_min=2, 4-bucket schedule, 5 barks 20-35s
_make_npc new wiring: warmed_relationship_min + warmed_relationship_dialogue_variants (completes run 29 NPC.gd schema)
GLBs now used: warrior.glb (was unused), worker_girl.glb (was unused)
Hooks: group "npcs" (Minimap), schedule_anchors (NPC walker), warmed_relationship_min (ready for gift/insult)