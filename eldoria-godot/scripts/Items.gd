extends Node
class_name Items

# Realm of Eldoria — item catalog. Static lookup of every item the kids can
# pick up, equip, drink, or sell. Each entry has display info + stats.
# Rarity colors map to the standard MMORPG palette (white→common, green→
# uncommon, blue→rare, purple→epic, orange→legendary).

const RARITY_COLORS = {
	"common":     Color(0.95, 0.95, 0.95),
	"uncommon":   Color(0.30, 0.85, 0.30),
	"rare":       Color(0.30, 0.55, 1.00),
	"epic":       Color(0.75, 0.35, 1.00),
	"legendary":  Color(1.00, 0.55, 0.10),
}

const ITEMS = {
	# ── Weapons ───────────────────────────────────────────────────────────
	"rusty_sword":   {"name":"Rusty Sword",   "type":"weapon", "slot":"weapon", "rarity":"common",
	                  "icon":"⚔", "icon_path":"res://assets/icons/rusty_sword.png",  "color":Color(0.65,0.65,0.65), "damage":3,  "value":4},
	"iron_sword":    {"name":"Iron Sword",    "type":"weapon", "slot":"weapon", "rarity":"common",
	                  "icon":"⚔", "icon_path":"res://assets/icons/iron_sword.png",  "color":Color(0.85,0.85,0.85), "damage":6,  "value":18},
	"steel_blade":   {"name":"Steel Blade",   "type":"weapon", "slot":"weapon", "rarity":"uncommon",
	                  "icon":"⚔", "icon_path":"res://assets/icons/steel_blade.png",  "color":Color(0.78,0.85,0.95), "damage":12, "value":55},
	"frost_saber":   {"name":"Frost Saber",   "type":"weapon", "slot":"weapon", "rarity":"rare",
	                  "icon":"❄", "icon_path":"res://assets/icons/frost_saber.png",  "color":Color(0.45,0.78,1.00), "damage":22, "crit_bonus":0.06, "value":210},
	"ember_axe":     {"name":"Ember Axe",     "type":"weapon", "slot":"weapon", "rarity":"rare",
	                  "icon":"🪓", "icon_path":"res://assets/icons/ember_axe.png","color":Color(1.0,0.55,0.20),  "damage":26, "value":260},
	"shadow_dagger": {"name":"Shadow Dagger", "type":"weapon", "slot":"weapon", "rarity":"epic",
	                  "icon":"🗡", "icon_path":"res://assets/icons/shadow_dagger.png","color":Color(0.55,0.20,0.85), "damage":18, "crit_bonus":0.18, "value":420},
	"dragonfang":    {"name":"Dragonfang",    "type":"weapon", "slot":"weapon", "rarity":"legendary",
	                  "icon":"🐉", "icon_path":"res://assets/icons/dragonfang.png","color":Color(1.0,0.85,0.20),  "damage":42, "crit_bonus":0.10, "value":1500},

	# ── Armor ─────────────────────────────────────────────────────────────
	"cloth":         {"name":"Cloth Tunic",   "type":"armor",  "slot":"armor",  "rarity":"common",
	                  "icon":"🧵", "icon_path":"res://assets/icons/cloth.png","color":Color(0.85,0.75,0.55), "armor":2,  "value":6},
	"leather":       {"name":"Leather Vest",  "type":"armor",  "slot":"armor",  "rarity":"common",
	                  "icon":"🛡", "icon_path":"res://assets/icons/leather.png","color":Color(0.55,0.40,0.25), "armor":6,  "value":24},
	"chainmail":     {"name":"Chainmail",     "type":"armor",  "slot":"armor",  "rarity":"uncommon",
	                  "icon":"🛡", "icon_path":"res://assets/icons/chainmail.png","color":Color(0.65,0.65,0.70), "armor":12, "value":80},
	"steel_plate":   {"name":"Steel Plate",   "type":"armor",  "slot":"armor",  "rarity":"rare",
	                  "icon":"🛡", "icon_path":"res://assets/icons/steel_plate.png","color":Color(0.80,0.80,0.85), "armor":22, "value":280},
	"emberforge":    {"name":"Emberforge Plate","type":"armor","slot":"armor","rarity":"epic",
	                  "icon":"🛡", "icon_path":"res://assets/icons/emberforge.png","color":Color(1.0,0.45,0.15),  "armor":34, "hp_bonus":35, "value":620},
	"dragonscale":   {"name":"Dragonscale",   "type":"armor",  "slot":"armor",  "rarity":"legendary",
	                  "icon":"🐲", "icon_path":"res://assets/icons/dragonscale.png","color":Color(0.20,0.65,0.30), "armor":52, "hp_bonus":80, "value":2200},

	# ── Trinkets ──────────────────────────────────────────────────────────
	"ring_focus":    {"name":"Ring of Focus", "type":"trinket","slot":"trinket","rarity":"uncommon",
	                  "icon":"💍", "icon_path":"res://assets/icons/ring_focus.png","color":Color(0.85,0.85,0.45), "mp_bonus":15, "value":85},
	"talisman_oak":  {"name":"Oak Talisman",  "type":"trinket","slot":"trinket","rarity":"uncommon",
	                  "icon":"🌳", "icon_path":"res://assets/icons/talisman_oak.png","color":Color(0.40,0.65,0.20), "hp_bonus":18, "value":75},
	"crit_amulet":   {"name":"Hawk's Amulet", "type":"trinket","slot":"trinket","rarity":"rare",
	                  "icon":"🦅", "icon_path":"res://assets/icons/crit_amulet.png","color":Color(0.80,0.55,0.20), "crit_bonus":0.10, "value":190},
	"guardian_core": {"name":"Guardian's Core","type":"trinket","slot":"trinket","rarity":"legendary",
	                  "icon":"💠", "icon_path":"res://assets/icons/guardian_core.png","color":Color(0.50,0.90,1.00), "hp_bonus":60, "mp_bonus":40, "crit_bonus":0.08, "value":1800},

	# ── Consumables ───────────────────────────────────────────────────────
	"hp_potion_s":   {"name":"Lesser Health Potion","type":"consumable","slot":"","rarity":"common",
	                  "icon":"🧪", "icon_path":"res://assets/icons/hp_potion_s.png","color":Color(0.95,0.30,0.25),"heal":40, "stack":true,"value":12},
	"hp_potion_l":   {"name":"Greater Health Potion","type":"consumable","slot":"","rarity":"uncommon",
	                  "icon":"🧪", "icon_path":"res://assets/icons/hp_potion_l.png","color":Color(0.95,0.30,0.25),"heal":120,"stack":true,"value":40},
	"mp_potion":     {"name":"Mana Draught", "type":"consumable","slot":"","rarity":"common",
	                  "icon":"🍶", "icon_path":"res://assets/icons/mp_potion.png","color":Color(0.30,0.55,1.00),"mana":40, "stack":true,"value":15},

	# ── Materials (drop from enemies, used in fetch quests) ───────────────
	"wolf_pelt":     {"name":"Wolf Pelt",       "type":"material","slot":"","rarity":"common",
	                  "icon":"🦊", "icon_path":"res://assets/icons/wolf_pelt.png","color":Color(0.65,0.55,0.40),"stack":true,"value":8},
	"goblin_ear":    {"name":"Goblin Ear",      "type":"material","slot":"","rarity":"common",
	                  "icon":"👂", "icon_path":"res://assets/icons/goblin_ear.png","color":Color(0.45,0.65,0.30),"stack":true,"value":3},
	"crystal_shard": {"name":"Crystal Shard",   "type":"material","slot":"","rarity":"uncommon",
	                  "icon":"💎", "icon_path":"res://assets/icons/crystal_shard.png","color":Color(0.55,0.85,1.00),"stack":true,"value":35},
	"warlord_horn":  {"name":"Warlord's Horn",  "type":"material","slot":"","rarity":"epic",
	                  "icon":"🐃", "icon_path":"res://assets/icons/warlord_horn.png","color":Color(0.85,0.30,0.20),"stack":true,"value":250},
}

# Drop tables — used by Enemy on death to roll loot
const DROP_TABLE = {
	"goblin": [
		# REFINE: balance — drop table tuned for upgrade momentum across a 30-kill
		# grind. Trimmed pots/junk slightly, doubled steel_blade chance from 2 → 4.
		{"id":"hp_potion_s", "weight":36, "qty":[1,1]},
		{"id":"goblin_ear",  "weight":38, "qty":[1,1]},
		{"id":"rusty_sword", "weight":8,  "qty":[1,1]},
		{"id":"iron_sword",  "weight":9,  "qty":[1,1]},
		{"id":"cloth",       "weight":8,  "qty":[1,1]},
		{"id":"leather",     "weight":4,  "qty":[1,1]},
		{"id":"steel_blade", "weight":4,  "qty":[1,1]},
	],
	"wolf": [
		# REFINE: balance — wolf table tilted slightly toward gear (chainmail/
		# steel_blade) since they're the mid-tier challenge enemy. Total weight
		# unchanged at 92.
		{"id":"hp_potion_s", "weight":22, "qty":[1,2]},
		{"id":"wolf_pelt",   "weight":48, "qty":[1,1]},
		{"id":"leather",     "weight":12, "qty":[1,1]},
		{"id":"chainmail",   "weight":6,  "qty":[1,1]},
		{"id":"steel_blade", "weight":4,  "qty":[1,1]},
	],
	"goblin_warlord": [
		{"id":"frost_saber",   "weight":15, "qty":[1,1]},
		{"id":"ember_axe",     "weight":15, "qty":[1,1]},
		{"id":"shadow_dagger", "weight":8,  "qty":[1,1]},
		{"id":"emberforge",    "weight":10, "qty":[1,1]},
		{"id":"crit_amulet",   "weight":12, "qty":[1,1]},
		{"id":"hp_potion_l",   "weight":25, "qty":[2,4]},
		{"id":"warlord_horn",  "weight":80, "qty":[1,1]},
		{"id":"dragonfang",    "weight":2,  "qty":[1,1]},
		{"id":"dragonscale",   "weight":2,  "qty":[1,1]},
	],
	"skeleton": [
		{"id":"hp_potion_s",  "weight":30, "qty":[1,1]},
		{"id":"crystal_shard","weight":18, "qty":[1,1]},
		{"id":"rusty_sword",  "weight":15, "qty":[1,1]},
		{"id":"iron_sword",   "weight":10, "qty":[1,1]},
		{"id":"chainmail",    "weight":8,  "qty":[1,1]},
		{"id":"steel_blade",  "weight":3,  "qty":[1,1]},
		{"id":"mp_potion",    "weight":12, "qty":[1,1]},
	],
	"crystal_elemental": [
		{"id":"crystal_shard","weight":60, "qty":[1,2]},
		{"id":"mp_potion",    "weight":20, "qty":[1,2]},
		{"id":"hp_potion_l",  "weight":12, "qty":[1,1]},
		{"id":"ring_focus",   "weight":8,  "qty":[1,1]},
		{"id":"frost_saber",  "weight":3,  "qty":[1,1]},
	],
	"crystal_guardian": [
		{"id":"crystal_shard", "weight":80, "qty":[3,5]},
		{"id":"guardian_core", "weight":80, "qty":[1,1]},
		{"id":"frost_saber",   "weight":18, "qty":[1,1]},
		{"id":"steel_plate",   "weight":15, "qty":[1,1]},
		{"id":"emberforge",    "weight":8,  "qty":[1,1]},
		{"id":"ring_focus",    "weight":15, "qty":[1,1]},
		{"id":"hp_potion_l",   "weight":25, "qty":[2,3]},
		{"id":"dragonscale",   "weight":2,  "qty":[1,1]},
	],
	"chest_common": [
		{"id":"hp_potion_s", "weight":35, "qty":[2,4]},
		{"id":"hp_potion_l", "weight":15, "qty":[1,2]},
		{"id":"mp_potion",   "weight":15, "qty":[1,2]},
		{"id":"iron_sword",  "weight":10, "qty":[1,1]},
		{"id":"leather",     "weight":10, "qty":[1,1]},
		{"id":"chainmail",   "weight":6,  "qty":[1,1]},
		{"id":"steel_blade", "weight":4,  "qty":[1,1]},
		{"id":"ring_focus",  "weight":3,  "qty":[1,1]},
		{"id":"talisman_oak","weight":3,  "qty":[1,1]},
	],
	"chest_rare": [
		{"id":"hp_potion_l", "weight":25, "qty":[2,3]},
		{"id":"steel_blade", "weight":15, "qty":[1,1]},
		{"id":"steel_plate", "weight":12, "qty":[1,1]},
		{"id":"frost_saber", "weight":8,  "qty":[1,1]},
		{"id":"ember_axe",   "weight":8,  "qty":[1,1]},
		{"id":"shadow_dagger","weight":5, "qty":[1,1]},
		{"id":"crit_amulet", "weight":7,  "qty":[1,1]},
		{"id":"emberforge",  "weight":4,  "qty":[1,1]},
	],
}

static func get_item(id: String) -> Dictionary:
	# Allow runtime-generated affix items (id begins with "@") to look up via World registry
	if id.begins_with("@"):
		var w = Engine.get_main_loop().current_scene
		if w and w.has_method("get_runtime_item"):
			return w.get_runtime_item(id)
		return {}
	return ITEMS.get(id, {})

static func roll_loot(kind: String, rng: RandomNumberGenerator) -> Array:
	# Returns an array of {id, qty}
	var table = DROP_TABLE.get(kind, [])
	if table.is_empty():
		return []
	var total: int = 0
	for entry in table:
		total += entry.weight
	var r: int = rng.randi_range(1, total)
	var pick = table[0]
	var acc: int = 0
	for entry in table:
		acc += entry.weight
		if r <= acc:
			pick = entry
			break
	var qty: int = rng.randi_range(pick.qty[0], pick.qty[1])
	return [{"id": pick.id, "qty": qty}]

# ── Procedural affix system ──────────────────────────────────────────────
# Layered onto base equipment items. Affixes upgrade rarity and mutate stats.
# Generated affix items are registered at runtime in the World scene under
# IDs like "@steel_blade#frost_42" so they can be saved in the bag and looked
# up later via Items.get_item().
const AFFIX_PREFIXES = {
	"Gleaming":  {"weight":12, "rarity":"uncommon", "damage_pct":0.20, "armor_pct":0.20},
	"Sharpened": {"weight":10, "rarity":"uncommon", "damage_pct":0.30},
	"Sturdy":    {"weight":10, "rarity":"uncommon", "armor_pct":0.30, "hp_bonus":15},
	"Fierce":    {"weight":8,  "rarity":"rare",     "damage_pct":0.45, "crit_bonus":0.05},
	"Heroic":    {"weight":6,  "rarity":"rare",     "damage_pct":0.25, "armor_pct":0.25, "hp_bonus":25},
	"Mythic":    {"weight":3,  "rarity":"epic",     "damage_pct":0.60, "crit_bonus":0.08, "hp_bonus":40},
	"Ancient":   {"weight":2,  "rarity":"legendary","damage_pct":0.80, "armor_pct":0.40, "hp_bonus":60, "crit_bonus":0.10},
}
const AFFIX_SUFFIXES = {
	"of Frost":       {"weight":10, "icon_overlay":"❄", "tint":Color(0.55,0.85,1.00),"crit_bonus":0.05},
	"of Embers":      {"weight":10, "icon_overlay":"🔥","tint":Color(1.00,0.55,0.20),"damage_pct":0.15},
	"of the Bear":    {"weight":10, "icon_overlay":"🐻","tint":Color(0.65,0.45,0.25),"hp_bonus":30},
	"of Swiftness":   {"weight":8,  "icon_overlay":"💨","tint":Color(0.65,0.95,0.65),"crit_bonus":0.10},
	"of the Dragon":  {"weight":3,  "icon_overlay":"🐉","tint":Color(1.00,0.85,0.20),"damage_pct":0.40, "hp_bonus":40},
	"of Stars":       {"weight":4,  "icon_overlay":"✨","tint":Color(0.85,0.85,1.00),"mp_bonus":25, "crit_bonus":0.05},
}

static func _pick_weighted(table: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: int = 0
	for k in table:
		total += table[k].weight
	var r := rng.randi_range(1, total)
	var acc := 0
	for k in table:
		acc += table[k].weight
		if r <= acc:
			return k
	return table.keys()[0]

const RARITY_ORDER = ["common", "uncommon", "rare", "epic", "legendary"]

static func _bump_rarity(a: String, b: String) -> String:
	var ai = RARITY_ORDER.find(a); if ai < 0: ai = 0
	var bi = RARITY_ORDER.find(b); if bi < 0: bi = 0
	return RARITY_ORDER[max(ai, bi)]

# Build a runtime-generated affix variant of a base equipment item.
# Returns a Dictionary that can be registered with the World scene's
# runtime item registry (key starting with "@").
static func generate_affix_item(base_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var base = ITEMS.get(base_id, {})
	if base.is_empty() or not base.has("slot") or base.slot == "":
		return {}
	# 60% just prefix, 25% just suffix, 15% both
	var roll := rng.randf()
	var prefix_name := ""
	var suffix_name := ""
	if roll < 0.60:
		prefix_name = _pick_weighted(AFFIX_PREFIXES, rng)
	elif roll < 0.85:
		suffix_name = _pick_weighted(AFFIX_SUFFIXES, rng)
	else:
		prefix_name = _pick_weighted(AFFIX_PREFIXES, rng)
		suffix_name = _pick_weighted(AFFIX_SUFFIXES, rng)
	var item: Dictionary = base.duplicate(true)
	var name_parts: Array = []
	if prefix_name != "": name_parts.append(prefix_name)
	name_parts.append(base.get("name", base_id))
	if suffix_name != "": name_parts.append(suffix_name)
	item["name"] = " ".join(name_parts)
	item["affix"] = true
	# Apply stat modifiers
	for k in [prefix_name, suffix_name]:
		if k == "": continue
		var mods = AFFIX_PREFIXES.get(k, AFFIX_SUFFIXES.get(k, {}))
		if mods.has("damage_pct") and item.has("damage"):
			item["damage"] = int(item.damage * (1.0 + mods.damage_pct))
		if mods.has("armor_pct") and item.has("armor"):
			item["armor"] = int(item.armor * (1.0 + mods.armor_pct))
		if mods.has("hp_bonus"):
			item["hp_bonus"] = item.get("hp_bonus", 0) + mods.hp_bonus
		if mods.has("mp_bonus"):
			item["mp_bonus"] = item.get("mp_bonus", 0) + mods.mp_bonus
		if mods.has("crit_bonus"):
			item["crit_bonus"] = item.get("crit_bonus", 0.0) + mods.crit_bonus
		if mods.has("rarity"):
			item["rarity"] = _bump_rarity(item.get("rarity", "common"), mods.rarity)
		if mods.has("tint"):
			item["color"] = mods.tint
	# Generate a unique runtime id so multiple affix variants can co-exist
	var stamp := str(rng.randi_range(1000, 9999))
	var slug := (prefix_name + "_" + suffix_name).replace(" ", "_").replace("of_the_", "").replace("of_", "")
	item["base_id"] = base_id
	item["runtime_id"] = "@%s#%s_%s" % [base_id, slug, stamp]
	# Boost value: better gear is worth more gold
	item["value"] = int(item.get("value", 1) * 2.5)
	return item

# Roll loot from a chest pool, with chance to upgrade equipment to affix variants.
static func roll_chest_loot(pool: String, rng: RandomNumberGenerator, count: int) -> Array:
	var results: Array = []
	for _i in count:
		var rolls = roll_loot(pool, rng)
		for r in rolls:
			var base = get_item(r.id)
			# 55% chance equipment becomes an affix variant
			if base.has("slot") and base.slot != "" and rng.randf() < 0.55:
				var affix = generate_affix_item(r.id, rng)
				if not affix.is_empty():
					results.append({"id": affix.runtime_id, "qty": 1, "registry": affix})
					continue
			results.append(r)
	return results
