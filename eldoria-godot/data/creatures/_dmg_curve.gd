extends RefCounted
class_name DmgCurve

# Realm of Eldoria — expected effective player DPS by level band.  Used by
# the Bestiary Designer agent ONLY for TTK math; the live game does not read
# this at runtime (Player.gd handles real damage from equipped weapons).
#
# Numbers are derived from:
#   - Player.gd: max_hp = 120 + 18*(level-1)
#   - Items.gd weapon damage curve: rusty(3) → iron(6) → steel(12) → frost(22)
#   - Observed swing cadence ~0.85s with weapon equipped
#   - Crit assumed 5% × 1.5x = +2.5% effective
#
# TTK targets (must hit per agent spec):
#   - Trash mob at level-band entry: 5–9s
#   - Elite: 18–30s
#   - Boss: 90–180s
#
# Formula: ttk_seconds = creature.hp / EFFECTIVE_DPS[level_band]

const EFFECTIVE_DPS = {
	1:  4.5,    # rusty_sword, no upgrades
	2:  6.0,
	3:  8.5,    # iron_sword by now
	4: 10.5,
	5: 13.0,    # steel_blade equipped
	6: 14.0,    # cave-tier — Whisperwood completed
	7: 15.5,
	8: 17.0,    # crystal_caves elite band
	9: 19.0,
	10: 21.0,
	# Frost Saber tier and beyond (rarely sampled by Eldoria, gated to other realms)
	12: 26.0,
	15: 32.0,
}

# Player HP at level (defensive sanity check for boss damage budgeting).
const PLAYER_MAX_HP = {
	1: 120, 2: 138, 3: 156, 4: 174, 5: 192, 6: 210, 7: 228, 8: 246,
	9: 264, 10: 282, 12: 318, 15: 372,
}

static func ttk_seconds(creature_hp: int, level_band: int) -> float:
	var dps: float = EFFECTIVE_DPS.get(level_band, 14.0)
	if dps <= 0.0:
		return INF
	return float(creature_hp) / dps

static func ttk_band_check(creature_hp: int, level_band: int, target_min: float, target_max: float) -> bool:
	var t: float = ttk_seconds(creature_hp, level_band)
	return t >= target_min and t <= target_max
