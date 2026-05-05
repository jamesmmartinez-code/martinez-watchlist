extends Node
class_name Inventory

# Realm of Eldoria — player inventory + equipment slots.
# Owns the bag (array of {id, qty}) and equipped slots (weapon/armor/trinket).
# Computes derived stats and notifies the player when gear changes.

signal inventory_changed
signal equipment_changed

const MAX_SLOTS: int = 24

var bag: Array = []   # [{id, qty}]
var equipped: Dictionary = {
	"weapon":  "iron_sword",
	"armor":   "leather",
	"trinket": "",
}

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
	equipped[slot_name] = item_id
	equipment_changed.emit()
	inventory_changed.emit()

func unequip(slot_name: String) -> void:
	var was = equipped.get(slot_name, "")
	if was == "": return
	equipped[slot_name] = ""
	add_item(was, 1)
	equipment_changed.emit()

# ── Derived stats ──────────────────────────────────────────────────────────
func bonus_damage() -> int:
	var w := Items.get_item(equipped.get("weapon", ""))
	return w.get("damage", 0)

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
