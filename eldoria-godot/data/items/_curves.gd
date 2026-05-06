extends RefCounted
class_name ItemCurves
# Realm of Eldoria — stat budget curve.
#
# Budget rule (skill task, item-designer):
#   total = base(tier) + 0.6 × rarity_bonus(rarity)
# Items exceeding the budget MUST carry a downside (move_penalty < 0,
# attunement_cost > 0, or weight). No free lunches.
#
# Categories that opt OUT of the combat budget:
#   - consumable: economy-priced (gold cost), single-use is the downside
#   - material:   no combat stats, gold-priced for vendor use only
#
# Calibration (2026-05-05 bootstrap): the legacy Items.gd dict was sampled
# and existing items fit within ±15% of these numbers, so the curve is
# locked to this shape for the bootstrap. Tweaks should land here, not in
# individual .tres files.

const BASE_BY_TIER = {
    1: 5,  2: 10, 3: 15, 4: 20, 5: 25,
    6: 30, 7: 35, 8: 40, 9: 45, 10: 50,
}

const RARITY_BONUS = {
    "common":    0,
    "uncommon":  5,
    "rare":      12,
    "epic":      22,
    "legendary": 40,
}

# How many "budget points" each stat costs.
# Anchored to dragonfang/guardian_core/frost_saber so the legacy items
# all land near (≤) their tier+rarity budget.
const STAT_COST = {
    "damage":     1.0,
    "armor":      0.7,
    "hp_bonus":   0.5,
    "mp_bonus":   0.4,
    "crit_bonus": 40.0,    # 0.05 crit ≈ 2 budget points
    "heal":       0.2,     # consumables only — not budget-checked
    "mana":       0.25,    # consumables only — not budget-checked
}

const SLACK = 0.15  # ±15% wiggle for design flavor

# Categories that bypass the combat budget check.
const NON_COMBAT_CATEGORIES = ["consumable", "material"]

static func budget(tier: int, rarity: String) -> float:
    var b = BASE_BY_TIER.get(tier, tier * 5)
    var r = RARITY_BONUS.get(rarity, 0)
    return b + 0.6 * r

static func stat_total(stats: Dictionary) -> float:
    var total = 0.0
    for k in stats.keys():
        var cost = STAT_COST.get(k, 1.0)
        total += float(stats[k]) * cost
    return total

static func is_within_budget(category: String, tier: int, rarity: String, stats: Dictionary, has_downside: bool) -> bool:
    if category in NON_COMBAT_CATEGORIES:
        return true
    var spent = stat_total(stats)
    var allowed = budget(tier, rarity) * (1.0 + SLACK)
    if has_downside:
        allowed *= 1.25
    return spent <= allowed

static func budget_for(category: String, tier: int, rarity: String, stats: Dictionary, has_downside := false) -> Dictionary:
    return {
        "category": category,
        "tier": tier,
        "rarity": rarity,
        "budget": budget(tier, rarity),
        "spent": stat_total(stats),
        "has_downside": has_downside,
        "within": is_within_budget(category, tier, rarity, stats, has_downside),
    }
