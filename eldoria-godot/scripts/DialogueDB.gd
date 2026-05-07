# DialogueDB.gd — JSON-driven dialogue tree loader.
#
# Reads mood-keyed dialogue JSONs from `res://data/dialogue/<npc_slug>.json`
# and applies a predicate priority order to choose a single line for a given
# (npc, world-context) pair.
#
# This is the FIRST live consumer of the lore agent's mood-keyed dialogue
# JSONs (see `data/dialogue/elder_maeve.json`, `smith_edda.json`). Until this
# run, those files were canon-only — informational, not in-game. The integrator
# run on 2026-05-04 explicitly logged this gap as the next-builder priority.
#
# ──────────────────────────────────────────────────────────────────────────
# PREDICATE PRIORITY (highest fires first; first match wins):
#
#   1. low_health_player           — Player.hp / Player.max_hp < `low_hp_below`
#   2. boss_slain                  — World.has_world_flag("warlord_dead")
#   3. boss_alive                  — World.has_world_flag("seen_warlord")  *
#   4. high_renown                 — World.player_renown >= renown_threshold *
#   5. stranger                    — World.npc_seen has no entry for npc *
#   6. festival keys               — World.current_festival == key *
#                                    (longnight_vigil / honeysong_eve /
#                                     spring_first_warm_day are looked up by
#                                     the festival name)
#   7. after_first_quest_complete  — World.npc_has_flag(npc, warmed_flag)
#                                    OR World.has_world_flag("first_quest_done")
#   8. mood bucket (tod)           — morning / midday / evening / night
#   9. default                     — fallback
#
#   * = fail-soft. The current World autoload doesn't track renown / npc_seen /
#       current_festival yet. Predicates that can't be evaluated are skipped,
#       which means they LIGHT UP automatically the day a future run adds
#       those fields to World — no DialogueDB edit required.
#
# ──────────────────────────────────────────────────────────────────────────
# Composes with the existing variants/warmed_* PackedStringArray system on
# NPC.gd: NPC.gd consults DialogueDB FIRST when `use_dialogue_json` is set,
# falls back to the variants pipeline on miss. Tree shape mirrors the JSONs
# already on disk; no JSON re-authoring required.
#
# ──────────────────────────────────────────────────────────────────────────
# Future hooks (≥ 2):
#   1. The other 5 NPCs (Mara, Lyra, Bram, Roan, Hala) need only a JSON file
#      under data/dialogue/ with the same shape and `use_json_dialogue: true`
#      in WorldBuilder.NPCS — zero code change.
#   2. World.player_renown — when added (any int), `high_renown` keys for
#      Maeve + Edda fire automatically (their JSONs already define them).
#   3. World.current_festival — when a calendar/festival system lands, the
#      seasonal keys (longnight_vigil, honeysong_eve, spring_first_warm_day)
#      already in the JSONs become live without any JSON edit.
#   4. World.npc_seen — when a "first interaction" tracker lands, every NPC's
#      `stranger` key fires for first-interact-ever, and only then.
#   5. Per-line portrait / voice-clip extension: DialogueDB.choose_line could
#      return a Dictionary (line + portrait_path + voice_clip) if any future
#      JSON adds those fields. Tree schema is already extensible.
class_name DialogueDB
extends RefCounted

const DIALOGUE_DIR: String = "res://data/dialogue/"

# Static cache of parsed JSON trees, keyed by canonical npc slug.
# Entries: {} = miss/load failed (cached negative); non-empty Dictionary = hit.
static var _cache: Dictionary = {}

# Map "Elder Maeve" -> "elder_maeve" (lowercase, spaces -> underscores, trimmed).
static func _slug(npc_name: String) -> String:
	return npc_name.to_lower().replace(" ", "_").strip_edges()

# Load (and cache) the dialogue tree for a given NPC name. Returns {} on miss.
# Safe to call repeatedly: results are cached forever (including negative cache).
static func load_for(npc_name: String) -> Dictionary:
	var key: String = _slug(npc_name)
	if _cache.has(key):
		return _cache[key]
	var path: String = DIALOGUE_DIR + key + ".json"
	if not FileAccess.file_exists(path):
		_cache[key] = {}
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		_cache[key] = {}
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_cache[key] = {}
		return {}
	var tree: Dictionary = parsed
	_cache[key] = tree
	return tree

# Time-of-day bucket key — same boundaries as NPC.gd's variants[bucket].
static func _mood_key_for_tod(tod: float) -> String:
	if tod >= 5.0 and tod < 11.0:
		return "morning"
	if tod >= 11.0 and tod < 17.0:
		return "midday"
	if tod >= 17.0 and tod < 21.0:
		return "evening"
	return "night"

# Resolve the best available line for an NPC given the world ctx.
# Returns "" on miss (caller should fall back to NPC.gd variants/dialogue).
#
# ctx fields (all optional — missing = predicate skipped, fail-soft):
#   "world"            : Node    — World autoload, queried for flags / pressure
#   "tod"              : float   — time of day, 0..24 (default 11.0)
#   "hp_ratio"         : float   — player.hp / player.max_hp, 0..1 (default 1.0)
#   "warmed_flag"      : String  — this NPC's first-quest flag name
#   "renown_threshold" : int     — gate for `high_renown` (default 100)
#   "low_hp_below"     : float   — gate for `low_health_player` (default 0.30)
static func choose_line(npc_name: String, ctx: Dictionary) -> String:
	var tree: Dictionary = load_for(npc_name)
	if tree.is_empty():
		return ""

	var world_node: Node = ctx.get("world", null) as Node
	var tod: float = float(ctx.get("tod", 11.0))
	var hp_ratio: float = float(ctx.get("hp_ratio", 1.0))
	var warmed_flag: String = String(ctx.get("warmed_flag", ""))
	var renown_threshold: int = int(ctx.get("renown_threshold", 100))
	var low_hp_below: float = float(ctx.get("low_hp_below", 0.30))

	# 1. low_health_player — fires whenever HP is genuinely low, regardless of
	#    other context. Maeve and Edda both define this beat with mentor warmth.
	if hp_ratio < low_hp_below and tree.has("low_health_player"):
		return String(tree["low_health_player"])

	# 2. boss_slain — keyed on the canonical Goblin Warlord kill flag.
	if world_node != null and world_node.has_method("has_world_flag") and tree.has("boss_slain"):
		if world_node.has_world_flag("warlord_dead"):
			return String(tree["boss_slain"])

	# 3. boss_alive — fires only after the player has *encountered* the boss.
	#    Fail-soft: if no flag yet, this just doesn't fire — default / mood
	#    take over, no jank.
	if world_node != null and world_node.has_method("has_world_flag") and tree.has("boss_alive"):
		if world_node.has_world_flag("seen_warlord"):
			return String(tree["boss_alive"])

	# 4. high_renown — fail-soft. World doesn't track renown today; the day it
	#    does, this fires automatically.
	if world_node != null and "player_renown" in world_node and tree.has("high_renown"):
		var renown: int = int(world_node.get("player_renown"))
		if renown >= renown_threshold:
			return String(tree["high_renown"])

	# 5. stranger — fail-soft. World doesn't track first-interact today; the
	#    day it does, this fires for every first encounter.
	if world_node != null and "npc_seen" in world_node and tree.has("stranger"):
		var seen: Dictionary = world_node.get("npc_seen")
		if not bool(seen.get(npc_name, false)):
			return String(tree["stranger"])

	# 6. festival keys — fail-soft. The JSONs already define longnight_vigil /
	#    honeysong_eve / spring_first_warm_day. The day World grows a calendar,
	#    the matching key fires automatically.
	if world_node != null and "current_festival" in world_node:
		var festival: String = String(world_node.get("current_festival"))
		if festival != "" and tree.has(festival):
			return String(tree[festival])

	# 7. after_first_quest_complete — NPC-specific flag wins; otherwise any
	#    "first_quest_done" world flag also warms.
	var first_quest_warm: bool = false
	if world_node != null and warmed_flag != "" and world_node.has_method("npc_has_flag"):
		if world_node.npc_has_flag(npc_name, warmed_flag):
			first_quest_warm = true
	if not first_quest_warm and world_node != null and world_node.has_method("has_world_flag"):
		if world_node.has_world_flag("first_quest_done"):
			first_quest_warm = true
	if first_quest_warm and tree.has("after_first_quest_complete"):
		return String(tree["after_first_quest_complete"])

	# 8. time-of-day mood bucket
	var mood: String = _mood_key_for_tod(tod)
	if tree.has(mood):
		return String(tree[mood])

	# 9. default fallback
	if tree.has("default"):
		return String(tree["default"])

	return ""

# Test-only / debug: clear the cache. Not used at runtime; lets QA force a
# reload after editing a JSON without restarting the game.
static func _clear_cache() -> void:
	_cache.clear()
