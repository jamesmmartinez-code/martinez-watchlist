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

	# ── Helmets (head slot — Equipment Visualizer 2026-05-05) ────────────
	# These ride the player's head bone via Player._make_head_attachment.
	# Iron / steel / silver are common→uncommon→rare tints of one base GLB
	# (assets/gear/head/iron_helm.glb). Crown of Eldoria is a unique mesh.
	"iron_helm":     {"name":"Iron Helm",     "type":"helmet", "slot":"helmet","rarity":"common",
	"icon":"⛑", "icon_path":"res://assets/icons/iron_helm.png", "color":Color(0.78,0.78,0.82), "armor":3,  "value":22},
	"steel_helm":    {"name":"Steel Helm",    "type":"helmet", "slot":"helmet","rarity":"uncommon",
	"icon":"⛑", "icon_path":"res://assets/icons/steel_helm.png", "color":Color(0.85,0.88,0.92), "armor":7,  "value":75},
	"silver_helm":   {"name":"Silver Helm",   "type":"helmet", "slot":"helmet","rarity":"rare",
	"icon":"⛑", "icon_path":"res://assets/icons/silver_helm.png", "color":Color(0.92,0.92,0.95), "armor":12, "value":210},
	"ranger_hood":   {"name":"Ranger Hood",   "type":"helmet", "slot":"helmet","rarity":"uncommon",
	"icon":"🪖", "icon_path":"res://assets/icons/ranger_hood.png", "color":Color(0.40,0.55,0.30), "armor":5, "crit_bonus":0.04, "value":85},
	"crown_eldoria": {"name":"Crown of Eldoria","type":"helmet","slot":"helmet","rarity":"legendary",
	"icon":"👑", "icon_path":"res://assets/icons/crown_eldoria.png", "color":Color(1.0,0.85,0.30), "armor":18, "hp_bonus":40, "mp_bonus":20, "value":2400},

	# ── Capes (chest_back slot — Equipment Visualizer 2026-05-05) ────────
	# Hangs off the player's spine bone. Tier-tinted from a single base GLB
	# (assets/gear/chest_back/traveller_cape.glb) for the common variants.
	"traveller_cape":{"name":"Traveller's Cape","type":"cape","slot":"cape","rarity":"common",
	"icon":"🧣", "icon_path":"res://assets/icons/traveller_cape.png", "color":Color(0.65,0.30,0.25), "armor":1, "value":18},
	"mage_cape":     {"name":"Mage Cape",      "type":"cape", "slot":"cape", "rarity":"uncommon",
	"icon":"🧣", "icon_path":"res://assets/icons/mage_cape.png", "color":Color(0.30,0.35,0.85), "mp_bonus":15, "value":85},
	"ranger_cape":   {"name":"Ranger Cape",    "type":"cape", "slot":"cape", "rarity":"uncommon",
	"icon":"🧣", "icon_path":"res://assets/icons/ranger_cape.png", "color":Color(0.35,0.55,0.30), "crit_bonus":0.05, "value":80},
	"royal_cloak":   {"name":"Royal Cloak",    "type":"cape", "slot":"cape", "rarity":"rare",
	"icon":"🧣", "icon_path":"res://assets/icons/royal_cloak.png", "color":Color(0.55,0.20,0.55), "armor":4, "hp_bonus":20, "value":290},
	"dragonscale_cape":{"name":"Dragonscale Cape","type":"cape","slot":"cape","rarity":"epic",
	"icon":"🧣", "icon_path":"res://assets/icons/dragonscale_cape.png", "color":Color(0.20,0.55,0.30), "armor":8, "hp_bonus":35, "value":820},

	# ── Shields (left_hand slot — Equipment Visualizer 2026-05-05) ───────
	# Bolted to the off-hand bone. Note that equipping a shield doesn't yet
	# disable two-handed weapons — Combat Specialist owns that interaction.
	"wooden_shield": {"name":"Wooden Shield",  "type":"shield","slot":"shield","rarity":"common",
	"icon":"🛡", "icon_path":"res://assets/icons/wooden_shield.png", "color":Color(0.55,0.40,0.25), "armor":4,  "value":20},
	"iron_shield":   {"name":"Iron Shield",    "type":"shield","slot":"shield","rarity":"uncommon",
	"icon":"🛡", "icon_path":"res://assets/icons/iron_shield.png", "color":Color(0.75,0.75,0.78), "armor":9,  "value":75},
	"kite_shield":   {"name":"Kite Shield",    "type":"shield","slot":"shield","rarity":"rare",
	"icon":"🛡", "icon_path":"res://assets/icons/kite_shield.png", "color":Color(0.60,0.70,0.85), "armor":15, "value":260},
	"runed_shield":  {"name":"Runed Shield",   "type":"shield","slot":"shield","rarity":"epic",
	"icon":"🛡", "icon_path":"res://assets/icons/runed_shield.png", "color":Color(0.50,0.85,1.00), "armor":24, "hp_bonus":30, "value":720},

	# ── Consumables ───────────────────────────────────────────────────────
	"hp_potion_s":   {"name":"Lesser Health Potion","type":"consumable","slot":"","rarity":"common",
	"icon":"🧪", "icon_path":"res://assets/icons/hp_potion_s.png","color":Color(0.95,0.30,0.25),"heal":40, "stack":true,"value":12},
	# REFINE: balance — Greater Health Potion heal 120 → 130 (+8.3%). Mid-tier
	# consumable was untouched in run-2 while max_hp grew per-level (run-2 +18/lvl).
	# At level 5 (max_hp ≈ 210) a single greater pot now heals ~62% of bar instead
	# of ~57% — restores the "this is the BIG potion" feel Owen's boss-prep stockpile
	# leans on. value held at 40 (Mara's economy unchanged).
	"hp_potion_l":   {"name":"Greater Health Potion","type":"consumable","slot":"","rarity":"uncommon",
	"icon":"🧪", "icon_path":"res://assets/icons/hp_potion_l.png","color":Color(0.95,0.30,0.25),"heal":130,"stack":true,"value":40},
	# REFINE: balance — Mana Draught mana 40 → 45 (+12.5%). Per-level max_mp grew
	# +10 in run-2 (was +8) so the flat 40 mana pot was eroding into a smaller
	# fraction of total bar. 45 keeps it at ~45% of bar at level 5 (mp ≈ 100),
	# which is the "useful caster top-up" target. Pairs with the crystal_elemental
	# table tilt above (more mp_potions to find means each one needs to feel worth
	# the bag slot).
	"mp_potion":     {"name":"Mana Draught", "type":"consumable","slot":"","rarity":"common",
	"icon":"🍶", "icon_path":"res://assets/icons/mp_potion.png","color":Color(0.30,0.55,1.00),"mana":45, "stack":true,"value":15},

	# ── Materials (drop from enemies, used in fetch quests) ───────────────
	"wolf_pelt":     {"name":"Wolf Pelt",       "type":"material","slot":"","rarity":"common",
	"icon":"🦊", "icon_path":"res://assets/icons/wolf_pelt.png","color":Color(0.65,0.55,0.40),"stack":true,"value":8},
	"wolf_fang":     {"name":"Wolf Fang",       "type":"material","slot":"","rarity":"common",
	"icon":"🦷", "icon_path":"res://assets/icons/wolf_fang.png","color":Color(0.92,0.88,0.78),"stack":true,"value":6},
	# COMPOUND (run 19): wolf_heart — RARE wolf trophy, fetch material for
	# `wolf_heart_for_bram` (Bram's Heartwood Mead bounty, 4th `dire_wolves`
	# reducer). Rarity bumped to "rare" so the inventory tooltip shows the
	# blue chip the moment the player rolls one — a different visual beat from
	# the common 🦊 pelt and 🦷 fang sitting alongside it. value 32 sits
	# between wolf_pelt (8) and crystal_shard (35) — heart is rarer-than-pelt
	# but the player should already have crystal_shards by Bram-pacing time.
	# 🫀 emoji as legacy fallback; icon_path lights up if `wolf_heart.png`
	# painterly icon ships from the artist agent (same fail-soft as wolf_fang).
	"wolf_heart":    {"name":"Wolf Heart",      "type":"material","slot":"","rarity":"rare",
	"icon":"🫀", "icon_path":"res://assets/icons/wolf_heart.png","color":Color(0.65,0.18,0.22),"stack":true,"value":32},
	"goblin_ear":    {"name":"Goblin Ear",      "type":"material","slot":"","rarity":"common",
	"icon":"👂", "icon_path":"res://assets/icons/goblin_ear.png","color":Color(0.45,0.65,0.30),"stack":true,"value":3},
	"crystal_shard": {"name":"Crystal Shard",   "type":"material","slot":"","rarity":"uncommon",
	"icon":"💎", "icon_path":"res://assets/icons/crystal_shard.png","color":Color(0.55,0.85,1.00),"stack":true,"value":35},
	# COMPOUND (run 24 — Builder): captain_seal — RARE bandit-captain trophy,
	# fetch material for `captain_seal_for_maeve` (Maeve's SECOND quest, the
	# first cross-NPC application of run-23's `prerequisite_npc_flag` schema).
	# An iron-cast hand-stamp the south-road captain wore on a leather thong;
	# Maeve keeps it on her hut mantle once the player turns it in. Rarity
	# "rare" so the inventory tooltip shows the blue chip the moment it
	# drops — silhouette beat distinct from the bandit pocket-lint floor
	# (cloth/leather/rusty_sword) and the captain's mid-tier weapon roll
	# (steel_blade/chainmail). value 60 sits ABOVE wolf_heart (32) but
	# BELOW warlord_horn (250) — captain is a mid-boss-tier kill, not a
	# faction warlord. 🕯 emoji as legacy fallback; icon_path lights up
	# if `captain_seal.png` painterly icon ships from the Artist agent
	# (same fail-soft as wolf_fang / wolf_heart).
	# THEME §2: iron-cast seals are period-correct (late medieval / early
	# Renaissance). THEME §1: lived-in / weathered — meant to sit on a
	# mantle, not be polished.
	"captain_seal":  {"name":"Captain's Seal",  "type":"material","slot":"","rarity":"rare",
	"icon":"🕯", "icon_path":"res://assets/icons/captain_seal.png","color":Color(0.55,0.45,0.30),"stack":true,"value":60},
	"warlord_horn":  {"name":"Warlord's Horn",  "type":"material","slot":"","rarity":"epic",
	"icon":"🐃", "icon_path":"res://assets/icons/warlord_horn.png","color":Color(0.85,0.30,0.20),"stack":true,"value":250},

	# ── CQ-S2-02 (Builder run 32): .tres-defined items missing from ITEMS dict ─
	# briar_shortbow, mossbound_buckler, roan_woodbow were defined as .tres
	# resources but absent from the legacy ITEMS dict — Items.get_item() returned
	# {} for all three, breaking any UI that called it (forge sell, shop display,
	# loot popup name, drop table label). Stats mirrored from each .tres file.
	# THEME §1: all three are period-correct — a carved-briar hunting bow,
	# a moss-lashed buckler from Whisperwood oakwood, a stable master's gift bow.
	"briar_shortbow": {"name":"Briar Shortbow",  "type":"weapon", "slot":"weapon", "rarity":"uncommon",
	"icon":"🏹", "icon_path":"res://assets/icons/briar_shortbow.png",
	"color":Color(0.55, 0.35, 0.18), "damage":8, "crit_bonus":0.04, "value":65},
	"mossbound_buckler": {"name":"Mossbound Buckler", "type":"armor", "slot":"shield", "rarity":"common",
	"icon":"🛡", "icon_path":"res://assets/icons/mossbound_buckler.png",
	"color":Color(0.35, 0.55, 0.25), "armor":4, "value":18},
	"roan_woodbow":   {"name":"Roan Woodbow",    "type":"weapon", "slot":"weapon", "rarity":"common",
	"icon":"🏹", "icon_path":"res://assets/icons/roan_woodbow.png",
	"color":Color(0.60, 0.42, 0.20), "damage":3, "value":10},

	# ── CQ-S2-03 (Builder run 32): practice_cudgel — Hala's after_first_quest_complete gift ─
	# Trainer Hala's dialogue tree references this item but it had no ITEMS entry,
	# no .tres, and no icon. "Mara stocks them; I make them." — a hand-bound
	# training weapon from Hala's workshop row. Common rarity, low damage —
	# it's a teaching tool, not a combat weapon. Sets world_flag cudgel_acknowledged.
	# THEME §1: wrapped leather grip, bound briar-wood haft — no metal.
	"practice_cudgel": {"name":"Practice Cudgel", "type":"weapon", "slot":"weapon", "rarity":"common",
	"icon":"🪵", "icon_path":"res://assets/icons/practice_cudgel.png",
	"color":Color(0.52, 0.38, 0.22), "damage":4, "value":8},

	# ── CQ-S2-04 (Builder run 32): roan_steppe_halter — Roan's gift item ────────
	# Stablemaster Roan's dialogue sets `roan_halter_gifted` on after_first_quest_
	# complete but the item itself was undefined — no ITEMS entry, no .tres.
	# A steppe-patterned decorative halter for Pippin (Roan's horse); the player
	# receives it as a keepsake. It has no combat stats — it's a friendship token.
	# Trinket slot so it can sit in the inventory paperdoll. THEME §1: woven
	# hemp with geometric step-dye pattern — nomadic steppe craft, period-correct.
	"roan_steppe_halter": {"name":"Steppe-Patterned Halter", "type":"trinket", "slot":"trinket", "rarity":"uncommon",
	"icon":"🐎", "icon_path":"res://assets/icons/roan_steppe_halter.png",
	"color":Color(0.65, 0.45, 0.20), "value":22},
	# ── Giftable items (Builder run 35 — NPC memory/gift mechanic) ─────────────
	# Player can give these to NPCs via the "Give Gift" dialogue button.
	# type="gift" flags them as giftable. stack=true for the cheap ones.
	# THEME §1: period-correct foraged/crafted goods — no modern items.
	"wildflower_bunch": {"name":"Wildflower Bunch",  "type":"gift", "slot":"", "rarity":"common",
	"icon":"\U0001f490", "icon_path":"res://assets/icons/wildflower_bunch.png",
	"color":Color(0.95,0.65,0.85), "stack":true, "value":5,
	"gift_flavor":"A few bright blossoms from the meadow."},
	"herb_bundle":      {"name":"Herb Bundle",        "type":"gift", "slot":"", "rarity":"common",
	"icon":"\U0001f33f", "icon_path":"res://assets/icons/herb_bundle.png",
	"color":Color(0.30,0.70,0.35), "stack":true, "value":8,
	"gift_flavor":"Dried herbs tied with twine — useful and fragrant."},
	"sweet_roll":       {"name":"Sweet Roll",          "type":"gift", "slot":"", "rarity":"common",
	"icon":"\U0001f950", "icon_path":"res://assets/icons/sweet_roll.png",
	"color":Color(0.90,0.72,0.45), "stack":true, "value":6,
	"gift_flavor":"Freshly baked, still warm."},
	"painted_stone":    {"name":"Painted River Stone", "type":"gift", "slot":"", "rarity":"uncommon",
	"icon":"\U0001faa8", "icon_path":"res://assets/icons/painted_stone.png",
	"color":Color(0.55,0.72,0.90), "stack":false, "value":14,
	"gift_flavor":"River-smoothed, painted with warding runes."},

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
		# steel_blade) since they're the mid-tier challenge enemy.
		# COMPOUND (run 17): added wolf_fang material (Roan-bounty fetch item).
		# Pulled wolf_pelt 48 → 38 and added wolf_fang at weight 18 to keep the
		# wolf table tilted toward materials (now 56% combined vs 52% pelt-only)
		# without making fang harder to roll than ear. A 4-kill wolf grind
		# averages ≥1 fang AND ≥1 pelt, so the Lyra and Roan quests can be run
		# in parallel without re-grinding. Total weight: 92 → 100.
		# COMPOUND (run 19): added wolf_heart material (Bram-bounty fetch item,
		# 4th `dire_wolves` reducer). Pulled -3 from wolf_pelt (38 → 35), -3
		# from wolf_fang (18 → 15), -2 from leather (12 → 10) to fund weight 8
		# for wolf_heart. Total stays at 100, so the weighted-roll math is
		# byte-identical to run 17 (each id's relative odds drift by < 4%).
		# wolf_heart at weight 8 is RARER than fang (15) and pelt (35) — Bram
		# wants 3, so a ~12-kill grind averages 0.96 hearts (just under quota).
		# That mirrors Roan's 5-fang grind (~5/0.18 ≈ 13.9 kills): both Roan
		# and Bram bounties take the same wolf-time to clear, so the player
		# can run them in parallel. Lyra's pelt grind is fastest (4/0.35 ≈
		# 11.4 kills), Hala's kill quest (4 wolves) is fastest of all — kid-
		# tuned curve preserved.
		{"id":"hp_potion_s", "weight":22, "qty":[1,2]},
		{"id":"wolf_pelt",   "weight":35, "qty":[1,1]},
		{"id":"wolf_fang",   "weight":15, "qty":[1,1]},
		{"id":"wolf_heart",  "weight":8,  "qty":[1,1]},
		{"id":"leather",     "weight":10, "qty":[1,1]},
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
		# REFINE: balance — bring skeletons up to par with the run-2 goblin/wolf
		# treatment. Crystal-cave undead should feel like the next gear tier above
		# Whisperwood goblins: trim rusty_sword junk (15 → 12), lift steel_blade
		# (3 → 5) so a 30-kill cave grind reliably rolls one real upgrade. Nudge
		# mp_potion (12 → 14) since skeletons live near mana-themed bosses and a
		# small draught stockpile preps the player for elemental fights. Lift
		# iron_sword (10 → 11) — same "less duplicate junk at pickup, the player
		# is past iron_sword by cave-time" reasoning that drove run-2 goblin tuning.
		# chainmail trimmed (8 → 6) so it reads as the OCCASIONAL upgrade, not
		# the default skeleton drop. Total weight preserved at 96.
		# REFINE: balance — late-game loot tier lift to match Run-10's +20% xp
		# band on agitated (⚡) skeletons (24 → 29 xp on tamed-faction kills). The
		# mastery loop only closes if "harder fight = bigger reward" reads on BOTH
		# axes — xp AND loot. Five knobs tuned in the same direction: rusty_sword
		# 12 → 10 (-17%, junk pull — by skeleton-depth the player is two tiers past
		# it); iron_sword 11 → 10 (-9%, same reasoning, smaller pull since iron is
		# still a sidegrade for some kits); chainmail 6 → 7 (+17%, the cave-tier
		# intermediate armor lift); steel_blade 5 → 6 (+20%, mirrors the Run-10
		# agitated xp band exactly — a tamed-faction skeleton kill now rolls the
		# real-upgrade weapon at 6/97 ≈ 6.2% per kill vs the prior 5/96 ≈ 5.2%, a
		# +19% relative chance lift); crystal_shard 18 → 20 (+11%, modest pull
		# toward cave-mana-economy, freed from the junk-tier weight). Total weight
		# 96 → 97 (+1.0%, rounding-noise inflation — same band shape, just tilted
		# up-tier).
		{"id":"hp_potion_s",  "weight":30, "qty":[1,1]},
		{"id":"crystal_shard","weight":20, "qty":[1,1]},
		{"id":"rusty_sword",  "weight":10, "qty":[1,1]},
		{"id":"iron_sword",   "weight":10, "qty":[1,1]},
		{"id":"chainmail",    "weight":7,  "qty":[1,1]},
		{"id":"steel_blade",  "weight":6,  "qty":[1,1]},
		{"id":"mp_potion",    "weight":14, "qty":[1,1]},
	],
	"crystal_elemental": [
		# REFINE: balance — crystal elementals are the mana-themed mid-boss enemy,
		# so the table tilts further toward MP economy + caster trinkets. mp_potion
		# (20 → 22) and ring_focus (8 → 10) lift in tandem — Owen's "I notice the
		# mana bar dropping less between fights" mastery beat. crystal_shard pulled
		# slightly (60 → 58) to make room without breaking the dominant material drop.
		# hp_potion_l up (12 → 13) — caves are long, Alden's HP economy needs the
		# extra greater-pot every ~7 elementals. frost_saber preserved at 3 (legendary
		# rarity tease intact). Total weight 103 → 106 (~3% inflation, acceptable
		# since these are the dedicated mp-economy enemy and players need the draught
		# stockpile to engage caster builds at all).
		# REFINE: balance — late-game loot tier lift to match Run-10's +20% xp
		# band on agitated (⚡) crystal elementals (55 → 66 xp on tamed-faction
		# kills). Same "harder fight = bigger reward on BOTH xp and loot axes"
		# play as the parallel skeleton edit this run. Four knobs lifted, all on
		# the trinket / legendary tier (the part of the table the run-10 xp band
		# actually wants to reward — common pots stay flat): crystal_shard 58 → 60
		# (+3%, minimal — the dominant baseline drop is already huge in absolute
		# terms); mp_potion 22 → 23 (+5%, gentle continuation of the previous run's
		# caster-economy tilt without re-litigating it); ring_focus 10 → 12 (+20%,
		# matches the Run-10 agitated xp band EXACTLY — a tamed-faction crystal
		# kill now rolls the caster trinket at 12/112 ≈ 10.7% vs the prior 10/106
		# ≈ 9.4%, a +14% relative chance lift, bigger band ceiling); frost_saber
		# 3 → 4 (+33% relative, but still tiny absolute — 4/112 ≈ 3.6% vs prior
		# 3/106 ≈ 2.83%, the legendary tease lifts at the rare end so a tamed-
		# faction crystal grind has a slightly higher chance of the chase weapon).
		# hp_potion_l preserved at 13 (already lifted in the previous run, no need
		# to relitigate). Total weight 106 → 112 (+5.7%, intentional — the run-10
		# xp band was +20% so the loot ceiling lifts at the trinket+legendary band
		# specifically, not uniformly).
		{"id":"crystal_shard","weight":60, "qty":[1,2]},
		{"id":"mp_potion",    "weight":23, "qty":[1,2]},
		{"id":"hp_potion_l",  "weight":13, "qty":[1,1]},
		{"id":"ring_focus",   "weight":12, "qty":[1,1]},
		{"id":"frost_saber",  "weight":4,  "qty":[1,1]},
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
		# REFINE: balance — chest_common is Alden's "ooh shiny" tier (Collection
		# affinity, PLAYER_MODEL §Players). Bumped hp_potion_s qty ceiling (2,4 →
		# 2,5) so a lucky chest stockpiles a real stash, not just a top-up. iron_sword
		# pulled (10 → 8) — like goblin run-2, the player spawns equipped with one;
		# real upgrade chance shifts to chainmail (6 → 8) and steel_blade (4 → 5).
		# Trinket band lifted (ring_focus 3 → 4, talisman_oak 3 → 4) so first-hour
		# chests have a meaningful chance of producing a HP/MP-boost trinket — the
		# "I found a magic ring!" beat Alden's collection ladder rewards. Total
		# weight 101 → 104 (~3% inflation, acceptable since common chests respawn).
		{"id":"hp_potion_s", "weight":35, "qty":[2,5]},
		{"id":"hp_potion_l", "weight":15, "qty":[1,2]},
		{"id":"mp_potion",   "weight":15, "qty":[1,2]},
		{"id":"iron_sword",  "weight":8,  "qty":[1,1]},
		{"id":"leather",     "weight":10, "qty":[1,1]},
		{"id":"chainmail",   "weight":8,  "qty":[1,1]},
		{"id":"steel_blade", "weight":5,  "qty":[1,1]},
		{"id":"ring_focus",  "weight":4,  "qty":[1,1]},
		{"id":"talisman_oak","weight":4,  "qty":[1,1]},
	],
	"chest_rare": [
		# REFINE: balance — chest_rare is Owen's mastery loot tier (Challenge +
		# Mastery affinity, PLAYER_MODEL §Players). The rare/epic gear band lifts
		# uniformly so finding one of the 2 rare chests on the map produces a
		# memorable "this changes my build" moment, not just a sidegrade. frost_saber
		# 8 → 10 and ember_axe 8 → 10 (Owen's two preferred hard-fight weapons,
		# Crit and Damage flavors). shadow_dagger 5 → 6 (epic crit-stacker stays
		# rare-feeling). emberforge 4 → 5 (epic armor with hp_bonus — chunky beat).
		# steel_blade pulled 15 → 13 since by the time Owen unlocks rare chests he's
		# already past steel; the freed weight band moves up a tier. Total weight
		# 84 → 88 (~5% inflation, but rare chests don't respawn so absolute drops
		# stay bounded).
		{"id":"hp_potion_l", "weight":25, "qty":[2,3]},
		{"id":"steel_blade", "weight":13, "qty":[1,1]},
		{"id":"steel_plate", "weight":12, "qty":[1,1]},
		{"id":"frost_saber", "weight":10, "qty":[1,1]},
		{"id":"ember_axe",   "weight":10, "qty":[1,1]},
		{"id":"shadow_dagger","weight":6, "qty":[1,1]},
		{"id":"crit_amulet", "weight":7,  "qty":[1,1]},
		{"id":"emberforge",  "weight":5,  "qty":[1,1]},
	],
	"bandit": [
		# COMPOUND (run 21 — Builder): bandit drop table. Bandits are road-
		# ambushers — they DON'T drop monster materials (no ears/pelts/fangs);
		# they drop ill-gotten human goods. Tilt: gold-equivalents (small
		# coin pouch via hp_potion_s clones not yet a thing — we re-use
		# leather/cloth as the "looted from a traveler" material), cheap
		# weapons, and the occasional cloak (steel_blade tier proxy).
		# Total weight 100 to mirror wolf/goblin's ratio-based math; future
		# runs adding `coin_pouch` or `lockpick` materials should pull from
		# `cloth` (at 22) since that's the "junk-tier" floor most likely to
		# tolerate weight rebalancing without breaking the existing entries.
		# Drop table SHIPS BEFORE bandit enemies actually spawn (those come
		# next Builder run with the warrior.glb wiring + road spawn pattern)
		# — the same fail-soft contract Items.gd already uses for skeleton/
		# crystal_elemental tables that pre-existed their spawn paths.
		{"id":"hp_potion_s",  "weight":28, "qty":[1,2]},
		{"id":"cloth",        "weight":22, "qty":[1,2]},
		{"id":"leather",      "weight":18, "qty":[1,1]},
		{"id":"rusty_sword",  "weight":12, "qty":[1,1]},
		{"id":"iron_sword",   "weight":10, "qty":[1,1]},
		{"id":"chainmail",    "weight":6,  "qty":[1,1]},
		{"id":"steel_blade",  "weight":4,  "qty":[1,1]},
	],
	# COMPOUND (run 23 — Builder): Bandit Captain drop table. Spawns at the
	# south-road camp ONLY when bandits faction pressure ≥ 0.70 (the same
	# threshold that maxes regular bandit_count to 4 — see WorldBuilder
	# `_bandit_camp_size`). Captain is a mini-boss: ~3.0× HP of a regular
	# bandit, +60% damage, ~5× xp, ~6× gold. Loot tilts AWAY from the
	# bandit table's "pocket lint" floor (rusty_sword/cloth) and toward
	# steel_blade / chainmail / ember_axe — gear a captain would actually
	# carry. Drop weights total 100 to match wolf/goblin/bandit ratio math.
	# `crystal_shard` slot (12 weight) is the bridge to the forge economy:
	# captain kills feed Edda's anvil without forcing a Crystal Caves run,
	# which closes a long-standing onboarding hole for players who tame
	# the road before they explore the dungeon. `crit_amulet` (8 weight)
	# is the only run-7+ rare: a captain dropping a hawk-eye amulet reads
	# as "they were a real threat, not a costume." Future Lore Keeper
	# runs may add a `captain_seal` material here for a Maeve fetch quest;
	# pull it from `cloth` (the lowest-weight floor) to preserve the 100
	# total without breaking other entries. Same fail-soft contract as
	# the existing tables — drop_table is consulted by Enemy.gd's
	# DROP_TABLE.get(enemy_kind, []) so missing/typo'd kinds drop nothing
	# rather than crash.
	"bandit_captain": [
		# COMPOUND (run 24 — Builder): captain_seal added at weight 16 — the
		# headline drop on every captain kill (~16% per roll, ~1 seal per 6
		# kills on average; captains spawn at bandit pressure ≥ 0.70 so a
		# fresh emergent camp typically yields the seal in 1–2 captain kills,
		# matching the run-24 quest needed:1 economy). Funded by trimming
		# non-essential slots: ember_axe 12→8 (-4), hp_potion_l 12→10 (-2),
		# leather 8→4 (-4), shadow_dagger 6→0 (-6). Total still 100;
		# shadow_dagger remains in the ITEMS catalog and still drops from
		# the wolf and crystal_elemental tables (Items.gd lines for those
		# entries unchanged) so removing its 6 from this single table does
		# not orphan the item.
		{"id":"steel_blade",  "weight":24, "qty":[1,1]},
		{"id":"chainmail",    "weight":18, "qty":[1,1]},
		{"id":"captain_seal", "weight":16, "qty":[1,1]},
		{"id":"crystal_shard","weight":12, "qty":[2,4]},
		{"id":"hp_potion_l",  "weight":10, "qty":[1,2]},
		{"id":"ember_axe",    "weight": 8, "qty":[1,1]},
		{"id":"crit_amulet",  "weight": 8, "qty":[1,1]},
		{"id":"leather",      "weight": 4, "qty":[1,2]},
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
	"Gleaming":  {"weight":12, "rarity":"uncommon", "affix_icon_path":"res://assets/icons/affix/prefix/gleaming.png", "tint":Color(0.65,0.85,0.55), "damage_pct":0.20, "armor_pct":0.20},
	"Sharpened": {"weight":10, "rarity":"uncommon", "affix_icon_path":"res://assets/icons/affix/prefix/sharpened.png", "tint":Color(0.78,0.85,0.55), "damage_pct":0.30},
	"Sturdy":    {"weight":10, "rarity":"uncommon", "affix_icon_path":"res://assets/icons/affix/prefix/sturdy.png", "tint":Color(0.55,0.75,0.45), "armor_pct":0.30, "hp_bonus":15},
	"Fierce":    {"weight":8,  "rarity":"rare", "affix_icon_path":"res://assets/icons/affix/prefix/fierce.png", "tint":Color(0.78,0.82,0.92),     "damage_pct":0.45, "crit_bonus":0.05},
	"Heroic":    {"weight":6,  "rarity":"rare", "affix_icon_path":"res://assets/icons/affix/prefix/heroic.png", "tint":Color(0.85,0.72,0.45),     "damage_pct":0.25, "armor_pct":0.25, "hp_bonus":25},
	"Mythic":    {"weight":3,  "rarity":"epic", "affix_icon_path":"res://assets/icons/affix/prefix/mythic.png", "tint":Color(0.78,0.55,0.95),     "damage_pct":0.60, "crit_bonus":0.08, "hp_bonus":40},
	"Ancient":   {"weight":2,  "rarity":"legendary", "affix_icon_path":"res://assets/icons/affix/prefix/ancient.png", "tint":Color(1.00,0.85,0.35),"damage_pct":0.80, "armor_pct":0.40, "hp_bonus":60, "crit_bonus":0.10},
	# ── Giftable items (Builder run 35 — NPC memory/gift mechanic) ─────────────
	# type="gift" flags them for the Give Gift dialogue button.
	# THEME §1: period-correct foraged/crafted goods only.
	"wildflower_bunch": {"name":"Wildflower Bunch",  "type":"gift", "slot":"", "rarity":"common",
	"icon":"💐", "icon_path":"res://assets/icons/wildflower_bunch.png",
	"color":Color(0.95,0.65,0.85), "stack":true, "value":5,
	"gift_flavor":"A few bright blossoms from the meadow."},
	"herb_bundle":      {"name":"Herb Bundle",        "type":"gift", "slot":"", "rarity":"common",
	"icon":"🌿", "icon_path":"res://assets/icons/herb_bundle.png",
	"color":Color(0.30,0.70,0.35), "stack":true, "value":8,
	"gift_flavor":"Dried herbs tied with twine — useful and fragrant."},
	"sweet_roll":       {"name":"Sweet Roll",          "type":"gift", "slot":"", "rarity":"common",
	"icon":"🥐", "icon_path":"res://assets/icons/sweet_roll.png",
	"color":Color(0.90,0.72,0.45), "stack":true, "value":6,
	"gift_flavor":"Freshly baked, still warm."},
	"painted_stone":    {"name":"Painted River Stone", "type":"gift", "slot":"", "rarity":"uncommon",
	"icon":"🪨", "icon_path":"res://assets/icons/painted_stone.png",
	"color":Color(0.55,0.72,0.90), "stack":false, "value":14,
	"gift_flavor":"River-smoothed, painted with warding runes."},

}
const AFFIX_SUFFIXES = {
	"of Frost":       {"weight":10, "icon_overlay":"❄", "affix_icon_path":"res://assets/icons/affix/frost.png",     "tint":Color(0.55,0.85,1.00),"crit_bonus":0.05},
	"of Embers":      {"weight":10, "icon_overlay":"🔥","affix_icon_path":"res://assets/icons/affix/embers.png",    "tint":Color(1.00,0.55,0.20),"damage_pct":0.15},
	"of the Bear":    {"weight":10, "icon_overlay":"🐻","affix_icon_path":"res://assets/icons/affix/bear.png",      "tint":Color(0.65,0.45,0.25),"hp_bonus":30},
	"of Swiftness":   {"weight":8,  "icon_overlay":"💨","affix_icon_path":"res://assets/icons/affix/swiftness.png", "tint":Color(0.65,0.95,0.65),"crit_bonus":0.10},
	"of the Dragon":  {"weight":3,  "icon_overlay":"🐉","affix_icon_path":"res://assets/icons/affix/dragon.png",    "tint":Color(1.00,0.85,0.20),"damage_pct":0.40, "hp_bonus":40},
	"of Stars":       {"weight":4,  "icon_overlay":"✨","affix_icon_path":"res://assets/icons/affix/stars.png",     "tint":Color(0.85,0.85,1.00),"mp_bonus":25, "crit_bonus":0.05},
}

static func _pick_weighted(table: Dictionary, rng: RandomNumberGenerator) -> String:
	var total: int = 0
	for k in table:
		total += table[k].weight
	var r: float = rng.randi_range(1, total)
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
	# REFINE: balance — odds tilted toward "both prefix+suffix" for chunkier
	# Owen-mastery moments. 60/25/15 → 56/24/20: a +5pp bump on the most exciting
	# affix outcome (e.g. "Sharpened Steel Blade of the Bear") and -4pp on the
	# plainer prefix-only tier. Solo-prefix is still the modal outcome so the
	# rarity pyramid reads correctly; the rare "both" rolls now hit ~1-in-5
	# instead of ~1-in-7, which is about one extra "wow" item per Owen's typical
	# 25-item chest haul. Suffix-only band held flat — it's the silhouette that
	# carries icon overlays (❄ 🔥 🐻) which Alden notices in the bag grid.
	var roll: float = rng.randf()
	var prefix_name := ""
	var suffix_name := ""
	if roll < 0.56:
		prefix_name = _pick_weighted(AFFIX_PREFIXES, rng)
	elif roll < 0.80:
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
	var stamp: String = str(rng.randi_range(1000, 9999))
	var slug := (prefix_name + "_" + suffix_name).replace(" ", "_").replace("of_the_", "").replace("of_", "")
	item["base_id"] = base_id
	item["runtime_id"] = "@%s#%s_%s" % [base_id, slug, stamp]
	# REFINE: balance — affix value mult 2.5 → 2.75. Affixed gear is the SHAPE of
	# Owen's mastery loop (he notices "the Sharpened version sells for triple")
	# and a slightly fatter sell value tightens that mastery beat. 10% bump is
	# small enough Alden's casual-sell economy isn't disrupted (his typical sale
	# is a goblin_ear at 3g, not an affix steel_blade at 150+g).
	item["value"] = int(item.get("value", 1) * 2.75)
	return item

# Roll loot from a chest pool, with chance to upgrade equipment to affix variants.
static func roll_chest_loot(pool: String, rng: RandomNumberGenerator, count: int) -> Array:
	var results: Array = []
	for _i in count:
		var rolls = roll_loot(pool, rng)
		for r in rolls:
			var base = get_item(r.id)
			# REFINE: balance — chest affix upgrade chance 0.55 → 0.58. Marginal +3pp
			# bump in "the chest dropped a magic-named item" beat. Compounds with
			# the affix-odds tilt above (more "both" affixes when an upgrade does fire).
			# Stays well under 0.60 so plain base items still appear regularly — keeps
			# the rarity pyramid legible to Alden ("the gold-named ones are special").
			if base.has("slot") and base.slot != "" and rng.randf() < 0.58:
				var affix = generate_affix_item(r.id, rng)
				if not affix.is_empty():
					results.append({"id": affix.runtime_id, "qty": 1, "registry": affix})
					continue
			results.append(r)
	return results

# ── Smith Edda forge upgrade ladder (run 12 — Builder) ──────────────────
# The Crystal-Cave-shard sink. Player brings shards to Smith Edda; she
# reforges the currently-equipped weapon, adding a flat damage bonus and
# stamping a "+N" suffix on the display name. Tier is per-weapon-id so
# swapping weapons doesn't burn progress (Iron Sword +2 stays +2 even if
# you grab a frost_saber for one fight, then swap back).
#
# Capped at +3:
#   tier 0 → 1 :  5 💎  (+2 dmg)   first reforge reachable in ~1 elemental kill
#   tier 1 → 2 : 10 💎  (+4 dmg)   second tier ~3-4 kills
#   tier 2 → 3 : 18 💎  (+6 dmg)   max tier ~7-9 kills
# Total to fully reforge a weapon: 33 shards (~3 Crystal Caves runs at the
# table-tuned drop rates set in run 11). 60% damage uplift on iron_sword,
# ~14% on dragonfang — kid-friendly progression curve, never overpowers
# the loot pyramid (a forged iron_sword is a steel_blade-tier weapon, NOT
# a frost_saber-tier one).
const REFORGE_MAX_TIER: int = 3

# Per-step crystal_shard cost to upgrade FROM tier i to tier i+1.
# COSTS[0] = first +1, COSTS[1] = second, COSTS[2] = max tier.
const REFORGE_COSTS: Array[int] = [5, 10, 18]

# Cumulative damage bonus per tier — flat int that adds to weapon.damage.
# REFINE: balance — damage steps +2/+4/+6 → +3/+6/+10. Original per-tier steps
# read as thin in the hit-number feedback (+2 on T1 was nearly invisible).
# New steps keep the loot-pyramid ceiling intact (dragonfang 42→52 dmg at T3,
# +24% — safely below the next loot tier) while making EACH STEP a chunky read.
# T1 +3 means Alden's first reforge (5 shards, first cave session) is felt
# immediately — his short-session-win affinity beat. Compounds with enchant
# cost 8→6 and Mara shard price 55→45g in this polish run.
const REFORGE_DAMAGE_BONUS: Array[int] = [3, 6, 10]

# Per-tier suffix for HUD/UI display.
const REFORGE_SUFFIXES: Array[String] = ["+1", "+2", "+3"]

# THEME §3 palette — bronze (T1), brass (T2), crystal-cyan accent (T3).
# Used by future paperdoll polish to tint the weapon slot border so the
# tier reads at a glance without reading text.
const REFORGE_TIER_COLORS: Array[Color] = [
	Color(0.85, 0.65, 0.30),  # bronze
	Color(1.00, 0.78, 0.32),  # brass
	Color(0.55, 0.85, 1.00),  # crystal-tinged
]

# Pure helper — returns the forged display name for a weapon at a given
# tier. Tier 0 returns the base name unchanged. Used by Inventory's
# weapon_display_name() and by the Smith Edda dialogue button label.
static func forged_name(base_id: String, tier: int) -> String:
	var base: Dictionary = get_item(base_id)
	var bn: String = String(base.get("name", base_id))
	if tier <= 0:
		return bn
	var t: int = clampi(tier, 1, REFORGE_MAX_TIER)
	return "%s %s" % [bn, REFORGE_SUFFIXES[t - 1]]

# Pure helper — flat damage bonus added on top of the base weapon damage.
# Tier 0 returns 0; reads cleanly inside Inventory.bonus_damage() with no
# branching at the callsite.
static func forge_damage_bonus(tier: int) -> int:
	if tier <= 0:
		return 0
	var t: int = clampi(tier, 1, REFORGE_MAX_TIER)
	return REFORGE_DAMAGE_BONUS[t - 1]

# Pure helper — crystal_shard cost to upgrade FROM `tier` to `tier+1`.
# Returns 0 if already at max tier (the dialogue button uses this to print
# either "→ +N (M 💎)" or "already +3 — peerless work" without needing to
# duplicate the cap logic).
static func forge_next_tier_cost(tier: int) -> int:
	if tier >= REFORGE_MAX_TIER:
		return 0
	return REFORGE_COSTS[clampi(tier, 0, REFORGE_MAX_TIER - 1)]
