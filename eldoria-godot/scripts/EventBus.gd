extends Node
# Realm of Eldoria — EventBus (autoload singleton)
#
# Central signal hub for loose coupling between game systems.
# Any system can emit here; any system can listen here — without needing a
# direct node reference to the emitter.
#
# Registered as autoload "EventBus" in project.godot [autoload].
#
# ── Design rules ─────────────────────────────────────────────────────────────
#   • ONLY signals live here — no logic, no state.
#   • Argument types use Node (not specific scripts) so systems stay decoupled.
#   • NarrativeSystem is still the semantic layer; EventBus is raw event pipe.
#
# ── Usage ─────────────────────────────────────────────────────────────────────
#   Emit:    EventBus.enemy_killed.emit(enemy_node)
#   Listen:  EventBus.enemy_killed.connect(_my_callback)

# ==========================================================================
# Entity lifecycle
# ==========================================================================
signal enemy_killed(enemy: Node)          # any enemy died (director, quests, etc.)
signal enemy_spawned(enemy: Node)         # director placed a new enemy
signal boss_defeated(boss: Node)          # boss fight over
signal player_died(player: Node)          # player death before respawn

# ==========================================================================
# World / zone events
# ==========================================================================
signal zone_captured(zone_id: String, faction_id: String)   # zone ownership changed
signal corruption_spike(level: float)                        # crossed a major threshold
signal season_changed(new_season: String)                    # world season transition

# ==========================================================================
# Narrative / progression
# ==========================================================================
signal nemesis_formed(data: Object)      # NemesisData — new nemesis born
signal nemesis_defeated(data: Object)    # nemesis permanently slain
signal quest_started(quest: Object)      # QuestData — just added
signal quest_completed(quest: Object)    # QuestData — all objectives done
signal level_complete(level_name: String)  # level transition triggered

# ==========================================================================
# Faction events
# ==========================================================================
signal faction_war_declared(attacker: String, defender: String)
signal faction_weakened(faction_id: String, new_strength: float)
