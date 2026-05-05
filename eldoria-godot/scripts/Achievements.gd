extends RefCounted
class_name Achievements

# Realm of Eldoria — Achievement & Title schema.
#
# Reads the existing world state primitives (factions, world_flags, npc_flags)
# and names compositions of them as unlockable "achievements". Each achievement
# also grants a TITLE — a short descriptive phrase that floats above the
# player's head as a Label3D ("the Wolf-Friend").
#
# This script adds NO new world primitive. It only consumes what the
# consequence resolver (World.apply_consequence) already writes. That makes
# achievements a FIFTH reader of `World.faction_pressure()` and the FIRST
# reader of arbitrary npc_flag combinations across multiple NPCs.
#
# ── Predicate language (queryable schema) ────────────────────────────────
# {"kind": "world_flag",     "flag": String}                       — has_world_flag
# {"kind": "faction_below",  "faction": String, "value": float}    — pressure < value
# {"kind": "faction_above",  "faction": String, "value": float}    — pressure > value
# {"kind": "all_npc_flags",  "flags": Array[[name, flag]]}          — every entry npc_has_flag
# {"kind": "all_of",         "preds": Array[Dictionary]}            — every nested predicate true
# {"kind": "any_of",         "preds": Array[Dictionary]}            — at least one nested predicate true
#
# ── Schema (one entry per achievement) ───────────────────────────────────
# id            : String        (Dictionary key)
# name          : String        (display label, shown in toast and future panel)
# desc          : String        (one-sentence flavor)
# icon          : String        (emoji glyph, child-readable; legacy fallback)
# icon_path     : String        (res:// path to 128x128 painterly PNG crest;
#                                preferred over `icon` when present)
# title_text    : String        (granted title; "" means no title is granted)
# title_priority: int           (higher = preferred when multiple titles unlocked)
# predicate     : Dictionary    (above)
#
# Authoring rules:
#   1. NEVER add a new world primitive in this file. If a predicate cannot
#      be expressed against existing world state, ADD THE NEW READER first
#      and only then write the achievement.
#   2. Keep title_text short — it has to fit above the player's head at
#      camera distance ~6m. Aim for <= 18 characters.
#   3. Use unique title_priority across achievements that can co-unlock; the
#      auto-equipper picks the highest. Keeps Owen from having to fiddle.
#   4. Predicate evaluation must be PURE — no world mutation. Predicates run
#      on every apply_consequence call AND on World._ready, so side effects
#      would cascade.

const ACHIEVEMENTS: Dictionary = {
	# Tier 1 — first quest completed (any of three starter quests trip this).
	"first_steps": {
		"name": "First Steps",
		"desc": "Complete your first quest in the realm.",
		"icon": "🌱",
		"icon_path": "res://assets/icons/achievements/first_steps.png",
		"title_text": "the Apprentice",
		"title_priority": 10,
		"predicate": {
			"kind": "any_of",
			"preds": [
				{"kind": "world_flag", "flag": "whisperwood_safer"},
				{"kind": "world_flag", "flag": "lyra_potion_brew"},
				{"kind": "world_flag", "flag": "mara_bounty_paid"},
			],
		},
	},
	# Tier 2 — wolves driven below the run-6 first cliff (4 -> 3 wolves).
	"pack_thinner": {
		"name": "Pack Thinner",
		"desc": "Drive the dire wolves below their first threshold.",
		"icon": "🐺",
		"icon_path": "res://assets/icons/achievements/pack_thinner.png",
		"title_text": "Wolf-Friend",
		"title_priority": 30,
		"predicate": {"kind": "faction_below", "faction": "dire_wolves", "value": 0.5},
	},
	# Tier 2 — goblins driven below the run-5 second cliff (cleansing landed).
	"goblin_bane": {
		"name": "Bane of the Whisperwood",
		"desc": "Push the Whisperwood goblins back from the village.",
		"icon": "⚔",
		"icon_path": "res://assets/icons/achievements/goblin_bane.png",
		"title_text": "Goblin-Bane",
		"title_priority": 40,
		"predicate": {"kind": "faction_below", "faction": "whisperwood_goblins", "value": 0.7},
	},
	# Tier 3 — earned trust of three core villager NPCs.
	"trusted_three": {
		"name": "Trusted by Three",
		"desc": "Earn the warm regard of Maeve, Lyra, and Mara.",
		"icon": "🤝",
		"icon_path": "res://assets/icons/achievements/trusted_three.png",
		"title_text": "the Trusted",
		"title_priority": 50,
		"predicate": {
			"kind": "all_npc_flags",
			"flags": [
				["Elder Maeve", "first_quest_done"],
				["Herbalist Lyra", "trusts_player"],
				["Mara the Merchant", "good_customer"],
			],
		},
	},
	# Tier 4 — both factions humbled AND three trusts. Mastery rung. Title is
	# the most prestigious so the auto-equipper picks it once Owen gets here.
	"realm_warden": {
		"name": "Warden of the Realm",
		"desc": "Both factions humbled, three villagers' trust earned.",
		"icon": "🏰",
		"icon_path": "res://assets/icons/achievements/realm_warden.png",
		"title_text": "Warden of Eldoria",
		"title_priority": 100,
		"predicate": {
			"kind": "all_of",
			"preds": [
				{"kind": "faction_below", "faction": "dire_wolves", "value": 0.5},
				{"kind": "faction_below", "faction": "whisperwood_goblins", "value": 0.7},
				{"kind": "all_npc_flags", "flags": [
					["Elder Maeve", "first_quest_done"],
					["Herbalist Lyra", "trusts_player"],
					["Mara the Merchant", "good_customer"],
				]},
			],
		},
	},
}

# Pure evaluator — returns the IDs of every achievement whose predicate is
# currently satisfied by the given world. Caller is responsible for
# diffing against already_unlocked to detect newly-unlocked entries.
#
# `world` is duck-typed: it must respond to `faction_pressure(String) -> float`,
# `has_world_flag(String) -> bool`, and `npc_has_flag(String, String) -> bool`.
# Same fail-soft contract used by the spawn-density helpers — if the world
# object is malformed, return an empty array rather than crashing.
static func evaluate(world: Object) -> Array:
	var result: Array = []
	if world == null:
		return result
	if not (world.has_method("faction_pressure")
			and world.has_method("has_world_flag")
			and world.has_method("npc_has_flag")):
		return result
	for id in ACHIEVEMENTS.keys():
		var entry: Dictionary = ACHIEVEMENTS[id]
		var pred: Dictionary = entry.get("predicate", {})
		if _eval_predicate(pred, world):
			result.append(id)
	return result

# Picks the title_text of the highest-priority unlocked achievement. Returns
# "" if no unlocked achievement grants a title. Stable: ties broken by ID
# alphabetical so Owen never sees the title flicker between two equal entries.
static func best_title(unlocked_ids: Array) -> String:
	var best_priority: int = -1
	var best_title_text: String = ""
	var best_id: String = ""
	for id_variant in unlocked_ids:
		var id: String = String(id_variant)
		if not ACHIEVEMENTS.has(id):
			continue
		var entry: Dictionary = ACHIEVEMENTS[id]
		var t: String = String(entry.get("title_text", ""))
		if t == "":
			continue
		var p: int = int(entry.get("title_priority", 0))
		if p > best_priority or (p == best_priority and id < best_id):
			best_priority = p
			best_title_text = t
			best_id = id
	return best_title_text

# ─── Internal: recursive predicate walker ────────────────────────────────
static func _eval_predicate(pred: Dictionary, world: Object) -> bool:
	if pred.is_empty():
		return false
	var kind: String = String(pred.get("kind", ""))
	match kind:
		"world_flag":
			return world.has_world_flag(String(pred.get("flag", "")))
		"faction_below":
			var fid: String = String(pred.get("faction", ""))
			var threshold: float = float(pred.get("value", 0.0))
			return world.faction_pressure(fid) < threshold
		"faction_above":
			var fid2: String = String(pred.get("faction", ""))
			var threshold2: float = float(pred.get("value", 1.0))
			return world.faction_pressure(fid2) > threshold2
		"all_npc_flags":
			var flags: Array = pred.get("flags", [])
			for pair_variant in flags:
				if not (pair_variant is Array) or pair_variant.size() < 2:
					return false
				var nname: String = String(pair_variant[0])
				var fname: String = String(pair_variant[1])
				if not world.npc_has_flag(nname, fname):
					return false
			return true
		"all_of":
			var preds_a: Array = pred.get("preds", [])
			for sub in preds_a:
				if not (sub is Dictionary):
					return false
				if not _eval_predicate(sub, world):
					return false
			return true
		"any_of":
			var preds_b: Array = pred.get("preds", [])
			for sub2 in preds_b:
				if not (sub2 is Dictionary):
					continue
				if _eval_predicate(sub2, world):
					return true
			return false
		_:
			return false
