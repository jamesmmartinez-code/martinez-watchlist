extends Node
class_name Inventory

# Realm of Eldoria — player inventory + equipment slots.
# Owns the bag (array of {id, qty}) and equipped slots (weapon/armor/trinket).
# Computes derived stats and notifies the player when gear changes.

signal inventory_changed
signal equipment_changed
# Equipment Visualizer (Pillar 1 — Combat) — granular per-slot signals so
# Player.gd can do partial visual rebuilds (e.g. swap helmet without re-
# instancing the whole sword). Both signals fire alongside equipment_changed
# for backwards-compat with code that watches the legacy aggregate signal.
signal item_equipped(slot, item_id)
signal item_unequipped(slot, item_id)

const MAX_SLOTS: int = 24

var bag: Array = []   # [{id, qty}]
# Equipment Visualizer added helmet/cape/shield slots (2026-05-05) so the
# kid's hero can visually layer gear, not just brandish a weapon. Default
# values are empty strings — Items.gd entries with the matching `slot`
# string will route through equip()/unequip() into these keys, and Player.gd
# rebuilds the matching bone-attached GLB on each equipment_changed.
var equipped: Dictionary = {
	"weapon":  "iron_sword",
	"armor":   "leather",
	"trinket": "",
	"helmet":  "",
	"cape":    "",
	"shield":  "",
}

# ── Smith Edda forge upgrade state (run 12 — Builder) ───────────────────
# Per-weapon-id forge tier (1..3, missing key = 0). Persisting per-id means
# swapping weapons doesn't burn upgrade progress: Iron Sword +2 stays +2 even
# if the player picks up and equips a frost_saber for one fight, then swaps
# back to the iron blade. Mutated only by `attempt_reforge(world)`; read by
# `bonus_damage()` (adds the flat tier bonus) and `weapon_display_name()`
# (stamps the "+N" suffix). Save-safe — pure Dict[String, int] of base IDs
# already in `Items.ITEMS`, no runtime registry pollution.
var forge_tiers: Dictionary = {}

func _ready() -> void:
	# Starter inventory
	add_item("hp_potion_s", 3)

# Returns total quantity of `id` across all bag slots
func count_item(id: String) -> int:
	var total := 0
	for slot in bag:
		if slot.id == id:
			total += slot.qty
	return total

func has_item(id: String, qty: int = 1) -> bool:
	return count_item(id) >= qty

# Consume `qty` of `id` from anywhere in the bag. Returns true if successful.
func consume_item(id: String, qty: int = 1) -> bool:
	if count_item(id) < qty:
		return false
	var remaining := qty
	var i := 0
	while i < bag.size() and remaining > 0:
		if bag[i].id == id:
			var take = min(remaining, bag[i].qty)
			bag[i].qty -= take
			remaining -= take
			if bag[i].qty <= 0:
				bag.remove_at(i)
				continue
		i += 1
	inventory_changed.emit()
	return true

# ── Bag operations ─────────────────────────────────────────────────────────
func add_item(id: String, qty: int = 1) -> void:
	if qty <= 0: return
	var item := Items.get_item(id)
	if item.is_empty(): return
	# Stack if stackable
	if item.get("stack", false):
		for slot in bag:
			if slot.id == id:
				slot.qty += qty
				inventory_changed.emit()
				return
	if bag.size() >= MAX_SLOTS:
		return  # bag full
	bag.append({"id": id, "qty": qty})
	inventory_changed.emit()

func remove_item(index: int, qty: int = 1) -> void:
	if index < 0 or index >= bag.size(): return
	bag[index].qty -= qty
	if bag[index].qty <= 0:
		bag.remove_at(index)
	inventory_changed.emit()

func use_item(index: int, player) -> void:
	if index < 0 or index >= bag.size(): return
	var slot = bag[index]
	var item := Items.get_item(slot.id)
	if item.is_empty(): return
	if item.type == "consumable":
		if item.has("heal"):
			player.hp = min(player.max_hp, player.hp + item.heal)
		if item.has("mana"):
			player.mp = min(player.max_mp, player.mp + item.mana)
		remove_item(index, 1)
		player.stats_changed.emit()
	elif item.has("slot") and item.slot != "":
		equip(slot.id)
		remove_item(index, 1)

# ── Equipment ──────────────────────────────────────────────────────────────
func equip(item_id: String) -> void:
	var item := Items.get_item(item_id)
	if item.is_empty() or not item.has("slot") or item.slot == "":
		return
	var slot_name = item.slot
	# Move currently equipped back to bag
	var was = equipped.get(slot_name, "")
	if was != "":
		add_item(was, 1)
		item_unequipped.emit(slot_name, was)
	equipped[slot_name] = item_id
	item_equipped.emit(slot_name, item_id)
	equipment_changed.emit()
	inventory_changed.emit()

func unequip(slot_name: String) -> void:
	var was = equipped.get(slot_name, "")
	if was == "": return
	equipped[slot_name] = ""
	add_item(was, 1)
	item_unequipped.emit(slot_name, was)
	equipment_changed.emit()
	inventory_changed.emit()

# ── Derived stats ──────────────────────────────────────────────────────────
func bonus_damage() -> int:
	# COMPOUND (run 12): adds the Smith Edda forge tier bonus on top of the
	# base weapon damage. Pure read of `forge_tiers[weapon_id]` (defaults 0
	# when never reforged), so untouched weapons return identical values to
	# pre-run-12 behaviour.
	var weapon_id: String = equipped.get("weapon", "")
	var w: Dictionary = Items.get_item(weapon_id)
	return int(w.get("damage", 0)) + Items.forge_damage_bonus(weapon_forge_tier(weapon_id))

func bonus_armor() -> int:
	var a := Items.get_item(equipped.get("armor", ""))
	return a.get("armor", 0)

func bonus_hp() -> int:
	var total := 0
	for slot_name in equipped:
		var it := Items.get_item(equipped[slot_name])
		total += it.get("hp_bonus", 0)
	return total

func bonus_mp() -> int:
	var total := 0
	for slot_name in equipped:
		var it := Items.get_item(equipped[slot_name])
		total += it.get("mp_bonus", 0)
	return total

func bonus_crit() -> float:
	var total := 0.0
	for slot_name in equipped:
		var it := Items.get_item(equipped[slot_name])
		total += it.get("crit_bonus", 0.0)
	return total

func equipped_weapon_id() -> String:
	return equipped.get("weapon", "")

func equipped_armor_id() -> String:
	return equipped.get("armor", "")

# Equipment Visualizer — generic accessor so Player.gd doesn't need to grow
# a per-slot helper for every new gear category we add.
func equipped_id(slot: String) -> String:
	return equipped.get(slot, "")

# ── Smith Edda forge methods (run 12 — Builder) ─────────────────────────
# Public API for the reforge UI in NPC dialogue.

# Returns 0 if untouched, 1..3 if reforged. Defaults the weapon_id arg to
# the currently-equipped weapon so the dialogue UI reads cleanly.
func weapon_forge_tier(weapon_id: String = "") -> int:
	var wid: String = weapon_id
	if wid == "":
		wid = String(equipped.get("weapon", ""))
	return int(forge_tiers.get(wid, 0))

# Display name with "+N" suffix when reforged. Tier 0 returns the base name.
# Used by HUD readouts and the reforge button label so the kids see the
# tier without reading damage numbers.
func weapon_display_name(weapon_id: String = "") -> String:
	var wid: String = weapon_id
	if wid == "":
		wid = String(equipped.get("weapon", ""))
	if wid == "":
		return ""
	return Items.forged_name(wid, weapon_forge_tier(wid))

# Attempt to reforge the currently-equipped weapon. Returns a structured
# Dictionary so the caller (World._on_reforge_pressed) can pretty-print
# success or each failure mode without re-validating.
#
# Success shape:
#   {"ok": true, "weapon_id": String, "new_tier": int,
#    "new_damage": int, "shards_spent": int}
#
# Failure shapes:
#   {"ok": false, "reason": "no_weapon"}
#   {"ok": false, "reason": "max_tier", "tier": int}
#   {"ok": false, "reason": "not_enough_shards", "have": int, "need": int}
#   {"ok": false, "reason": "consume_failed"}   # defensive; should never fire
#
# On success: consumes the shard cost, bumps `forge_tiers[weapon_id]` by 1,
# sets the world flag `first_reforge_done` (drives the "first_forge" achievement
# added in Achievements.gd this same run), and emits both `equipment_changed`
# and `inventory_changed` so the HUD damage readout and shard-count refresh
# without the caller having to re-emit.
func attempt_reforge(world: Object) -> Dictionary:
	var weapon_id: String = String(equipped.get("weapon", ""))
	if weapon_id == "":
		return {"ok": false, "reason": "no_weapon"}
	var tier: int = weapon_forge_tier(weapon_id)
	if tier >= Items.REFORGE_MAX_TIER:
		return {"ok": false, "reason": "max_tier", "tier": tier}
	var cost: int = Items.forge_next_tier_cost(tier)
	if not has_item("crystal_shard", cost):
		return {
			"ok": false, "reason": "not_enough_shards",
			"have": count_item("crystal_shard"), "need": cost,
		}
	if not consume_item("crystal_shard", cost):
		# Defensive — has_item said yes but consume failed. Don't mutate tier.
		return {"ok": false, "reason": "consume_failed"}
	var new_tier: int = tier + 1
	forge_tiers[weapon_id] = new_tier
	# Public side-effects: world flag for achievement chain (re-runs
	# `_check_achievements()` on the same tick; "first_forge" unlocks +25
	# renown via the run-11 ladder), then HUD/inventory refresh.
	if world and world.has_method("set_world_flag"):
		world.set_world_flag("first_reforge_done", true)
	equipment_changed.emit()
	inventory_changed.emit()
	var base_dmg: int = int(Items.get_item(weapon_id).get("damage", 0))
	return {
		"ok": true, "weapon_id": weapon_id,
		"new_tier": new_tier,
		"new_damage": base_dmg + Items.forge_damage_bonus(new_tier),
		"shards_spent": cost,
	}
