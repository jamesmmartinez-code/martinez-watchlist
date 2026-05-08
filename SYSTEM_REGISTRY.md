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
