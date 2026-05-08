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
	# REFINE: character — desc warmed from imperative ("Complete your first quest…")
	# to a Ghibli-mentor observation per THEME §7 ("warm gravitas"). One sentence,
	# child-readable (Alden 9), no mechanical "first quest" phrasing.
	"first_steps": {
		"name": "First Steps",
		"desc": "A first errand done. The road has begun to know your step.",
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
	# Tier 1.5 — first reforge. Run 12: Smith Edda's Crystal-Cave-shard sink
	# closes the cave→village gameplay loop. Title slots between Apprentice
	# (10) and Wolf-Friend (30) so the auto-equipper picks it up early but
	# yields cleanly when the player earns a faction-driven title.
	"first_enchant": {
		"name": "Rune Singer",
		"desc": "Edda's whisper holds. The first enchantment settles into the steel.",
		"icon": "E",
		"icon_path": "res://assets/icons/achievements/first_enchant.png",
		"title_text": "the Rune-Touched",
		"title_priority": 28,
		"predicate": {"kind": "world_flag", "flag": "first_enchant_done"},
	},
	"first_forge": {
		"name": "First Forge",
		# REFINE: character — desc made specific to Edda's soot and spark
		# (THEME §4 — Smith Edda silhouette: "soot-streaked, leather apron, hammer").
		"desc": "Edda's hammer, your spark. The first reforge holds.",
		"icon": "🔨",
		"icon_path": "res://assets/icons/achievements/first_forge.png",
		"title_text": "the Forged",
		"title_priority": 25,
		"predicate": {"kind": "world_flag", "flag": "first_reforge_done"},
	},
	# Tier 2 — wolves driven below the run-6 first cliff (4 -> 3 wolves).
	"pack_thinner": {
		"name": "Pack Thinner",
		# REFINE: character — desc swapped from threshold-jargon to a painterly
		# observation per THEME §1 ("painterly", "lived-in"). The number stays in
		# the predicate; the toast no longer leaks designer vocabulary at the player.
		"desc": "The pack grows wary. The Whisperwood breathes a little easier.",
		"icon": "🐺",
		"icon_path": "res://assets/icons/achievements/pack_thinner.png",
		"title_text": "Wolf-Friend",
		"title_priority": 30,
		"predicate": {"kind": "faction_below", "faction": "dire_wolves", "value": 0.5},
	},
	# Tier 2.5 — Run 18: FIRST consumer of three quest-completion npc_flags
	# under the `dire_wolves` faction. Lyra (alchemy fetch), Roan (stable
	# fetch), and Hala (trainer kill) — each NPC's role is unique, so this
	# is the first achievement keyed on roles 1+2+4 rather than just NPC
	# names. Title slots between Wolf-Friend (30, faction-only) and Goblin-
	# Bane (40, big-pressure-cliff) so the auto-equipper picks it AFTER
	# the player feels the wolf threat thinning AND has actually trained
	# alongside three different villagers — a deeper claim than just
	# pressure dropping. Predicate uses the existing `all_npc_flags`
	# evaluator — zero new schema. Same icon-path fail-soft as the others
	# (artist agent ships the painterly crest later).
	"wolf_tamer": {
		"name": "Tamer of the Wolfwoods",
		"desc": "Lyra, Roan, and Hala — three trades, one wolf-quiet road.",
		"icon": "🐺",
		"icon_path": "res://assets/icons/achievements/wolf_tamer.png",
		"title_text": "the Wolf-Tamer",
		"title_priority": 35,
		"predicate": {
			"kind": "all_npc_flags",
			"flags": [
				["Herbalist Lyra", "trusts_player"],
				["Stablemaster Roan", "first_bounty_done"],
				["Trainer Hala", "wolf_form_taught"],
			],
		},
	},
	# Tier 2 — goblins driven below the run-5 second cliff (cleansing landed).
	"goblin_bane": {
		"name": "Bane of the Whisperwood",
		# REFINE: character — desc warmed from "push back" to drums-and-quiet
		# imagery per THEME §6 ("distant goblin drums" is in the canonical SFX set)
		# and §8 (Briarwood as lived-in hamlet). Still one sentence.
		"desc": "The drums fall quiet. Briarwood's nights stretch longer in peace.",
		"icon": "⚔",
		"icon_path": "res://assets/icons/achievements/goblin_bane.png",
		"title_text": "Goblin-Bane",
		"title_priority": 40,
		"predicate": {"kind": "faction_below", "faction": "whisperwood_goblins", "value": 0.7},
	},
	# Tier 3 — earned trust of three core villager NPCs.
	"trusted_three": {
		"name": "Trusted by Three",
		# REFINE: character — desc warmed; "warm regard" is correct but flat.
		# Names them as people who *speak* the player's name (THEME §7 "old
		# promises, mended trust"; PLAYER_MODEL Alden affinity for being
		# named-by-NPCs). Stays under 90 chars to fit a toast.
		"desc": "Maeve, Lyra, and Mara say your name without caution.",
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
	# Tier 3 (run 23 — Builder) — Roan's bandit-clear quest landed. THIRD
	# achievement keyed on a single quest-issued world flag (joins
	# `first_steps` at the entry tier and `first_forge` at the smith tier).
	# The new run-23 quest `bandit_road_for_roan` is the SOLE writer of
	# `roan_bandit_road_clear`, so this predicate is unambiguous. Title
	# slots BETWEEN Goblin-Bane (40, faction-quiet beat) and Trusted (50,
	# three-villager NPC-flag beat) — clearing the south road sits below
	# "trusted by your neighbors" but above "goblin-quiet woods" because
	# bandits are a player-AGENCY beat (you reduced them in one quest)
	# whereas goblin-quiet is a multi-quest accumulation. Auto-equipper
	# picks Road-Warden the moment the quest turns in, then yields to
	# Trusted once the third villager flag flips. Painterly crest icon
	# pipeline matches the rest — Artist Agent ships the PNG later;
	# emoji `🛡️` is the legacy fallback.
	"road_warden": {
		"name": "Warden of the South Road",
		"desc": "The hooded camp goes cold. The road belongs to travelers again.",
		"icon": "🛡",
		"icon_path": "res://assets/icons/achievements/road_warden.png",
		"title_text": "Road-Warden",
		"title_priority": 45,
		"predicate": {"kind": "world_flag", "flag": "roan_bandit_road_clear"},
	},
	# COMPOUND (run 24 — Builder): seal_keeper — the political beat that
	# follows road_warden. The new run-24 quest `captain_seal_for_maeve` is
	# the SOLE writer of `maeve_seal_kept` (cross-NPC sequenced fetch quest,
	# gated on `road_warden`). Title slots BETWEEN Road-Warden (45, the
	# bandit-clear beat) and Trusted (50, the three-villager NPC-flag beat).
	# Auto-equipper picks Seal-Keeper the moment Maeve takes the seal, then
	# yields to Trusted once the third villager flag flips. The captain's
	# seal is a deeper political act than road clearing — the player isn't
	# just clearing bandits, they're handing the captain's authority to a
	# Warden of the Mark to keep (canon: Maeve = the keeping-vigil; the
	# Wardens have no enemy, they have memory). THEME §1 painterly + §7
	# Ghibli mentor cadence in the desc. Painterly crest icon pipeline
	# matches the rest — Artist Agent ships the PNG later; emoji `🕯`
	# (a vigil candle) is the legacy fallback, the same glyph as the
	# quest-completion toast for visual continuity.
	"seal_keeper": {
		"name": "Keeper of the Captain's Seal",
		"desc": "The seal lies on Maeve's mantle. The road's name is remembered.",
		"icon": "🕯",
		"icon_path": "res://assets/icons/achievements/seal_keeper.png",
		"title_text": "Seal-Keeper",
		"title_priority": 47,
		"predicate": {"kind": "world_flag", "flag": "maeve_seal_kept"},
	},
	# Tier 4 — both factions humbled AND three trusts. Mastery rung. Title is
	# the most prestigious so the auto-equipper picks it once Owen gets here.
	"realm_warden": {
		"name": "Warden of the Realm",
		# REFINE: character — desc gathers the prior beats into one warm
		# closing line per THEME §1 ("hopeful — the world is wounded but
		# worth saving") and §7 (Ghibli mentor cadence). Owen's mastery
		# rung deserves the most evocative copy in the file.
		"desc": "Two factions stilled, three trusts kept. The realm rests easier with you in it.",
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

	# Builder run 24 — Hearthkeeper: player has visited their home after
	# completing the first quest. Closes the housing loop: first_quest_done
	# (Maeve) + player_home_visited (PlayerHome._on_player_interact).
	# title_priority 22 — between "the Rune-Touched" (25) and "Friend of Eldoria" (20).
	"hearthkeeper": {
		"name": "Hearthkeeper",
		"desc": "The cottage north of the plaza has a fire in its hearth — and you put it there.",
		"icon": "🏠",
		"title_text": "the Hearthkeeper",
		"title_priority": 22,
		"predicate": {
			"kind": "all_of",
			"preds": [
				{"kind": "world_flag", "flag": "first_quest_done"},
				{"kind": "world_flag", "flag": "player_home_visited"},
			],
		},
	},
	# run 29 (Builder) — villager_friend: player earned relationship score >= 3
	# with any NPC. title_priority 18 — below hearthkeeper (22). Uses new
	# npc_relationship_min predicate kind added to _eval_predicate below.
	"villager_friend": {
		"name": "Beloved of Briarwood",
		"desc": "A villager's eyes light up when you walk through the gate.",
		"icon": "\U0001f49b",
		"title_text": "the Beloved",
		"title_priority": 18,
		"predicate": {
			"kind": "npc_relationship_min",
			"min_score": 3,
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
		"npc_relationship_min":
			var min_rel: int = int(pred.get("min_score", 3))
			if world.has_method("npc_any_relationship_above"):
				return world.npc_any_relationship_above(min_rel)
			return false
		_:
			return false
