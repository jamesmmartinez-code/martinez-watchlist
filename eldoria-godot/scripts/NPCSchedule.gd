extends Resource
class_name NPCSchedule

# Realm of Eldoria — NPCSchedule
# Time-of-day schedule component for village NPCs.
#
# Usage: Attach to any NPC node via WorldBuilder._make_npc(). The NPC's
# _tick_schedule() already walks schedule_anchors; this resource adds a
# RICHER per-entry schema that names the activity + location so other
# systems (Dialogue, Quest, Minimap) can query what an NPC is doing *right
# now* without re-deriving it from raw Vector3 anchors.
#
# DESIGN RULES (canon):
#   - Uses World.time_of_day (float, 0..24, 24h clock) — READ ONLY.
#     Never writes to World; never emits signals of its own.
#   - Array[String] — NOT PackedStringArray (per AGENT_CANON_PREAMBLE §4).
#   - All explicit type annotations (Godot 4.6 strict mode).
#   - No const using constructor calls (PackedStringArray/PackedColorArray etc.).
#   - SIZE_STANDARDS: character y=0 ground contact enforced by NPC._tick_schedule.
#     NPCSchedule does not touch world-space transforms.
#
# SCHEDULE ENTRY SCHEMA (each element of `entries`):
#   {
#     "tod_start":  float,   # start of window (0..24, inclusive)
#     "tod_end":    float,   # end of window (exclusive). May wrap midnight if
#                            # tod_end < tod_start (e.g. 22.0 → 5.0 = night).
#     "anchor":     Vector3, # world-space XZ target (y clamped to spawn-y by NPC)
#     "activity":   String,  # human-readable label, e.g. "forging", "sleeping"
#     "location":   String,  # named place, e.g. "smithy", "market stall", "inn"
#   }
# Overlapping windows are resolved first-match (lowest index wins).
# Entries with no matching window fall through to the last entry as a default.
#
# THEME CITATIONS:
#   §1  LIVED-IN WORLD  — each NPC has a believable daily rhythm
#   §12 MOTION & LIFE   — village feels inhabited; NPCs are never static props
#   §13 GROUND CONTACT  — anchor y is always overridden to spawn-y by NPC.gd

# ─── Constants ───────────────────────────────────────────────────────────────

# ToD bucket boundaries — mirrors NPC._bucket_for_tod() for documentation
# clarity.  Not used for bucket math here; entries carry explicit tod_start/end.
const TOD_MORNING_START: float = 5.0
const TOD_MIDDAY_START: float  = 11.0
const TOD_EVENING_START: float = 17.0
const TOD_NIGHT_START: float   = 21.0

# Maximum entries per schedule — guard against runaway authoring.
const MAX_ENTRIES: int = 16

# ─── Exports ─────────────────────────────────────────────────────────────────

## Human-readable name for this schedule (e.g. "Elder Maeve daily routine").
## Used in debug output and future Minimap tooltips.
@export var schedule_name: String = ""

## Ordered list of schedule entries (see header for dict schema).
## Shorter schedules (2–4 entries) are fine — the resolver falls through to the
## last entry as its catch-all, so a 4-bucket schedule covers the whole day.
@export var entries: Array = []

# ─── Public API ──────────────────────────────────────────────────────────────

## Returns the active entry dict for the given time_of_day, or {} if entries is
## empty.  Evaluation is first-match; the LAST entry acts as a default/catch-all.
func get_active_entry(tod: float) -> Dictionary:
	var n: int = entries.size()
	if n <= 0:
		return {}
	for i: int in range(n - 1):
		var e: Dictionary = entries[i]
		if _is_in_window(tod, float(e.get("tod_start", 0.0)), float(e.get("tod_end", 24.0))):
			return e
	# Last entry is the catch-all.
	return entries[n - 1]

## Returns the anchor Vector3 for the given time_of_day, or Vector3.ZERO if
## entries is empty.  Callers (NPC._tick_schedule) override y to spawn-y.
func get_anchor(tod: float) -> Vector3:
	var e: Dictionary = get_active_entry(tod)
	if e.is_empty():
		return Vector3.ZERO
	var raw: Variant = e.get("anchor", Vector3.ZERO)
	if raw is Vector3:
		return raw
	return Vector3.ZERO

## Returns the activity label for the given time_of_day (e.g. "forging").
## Empty string if no entry or no activity key.
func get_activity(tod: float) -> String:
	var e: Dictionary = get_active_entry(tod)
	return e.get("activity", "")

## Returns the location label for the given time_of_day (e.g. "smithy").
## Empty string if no entry or no location key.
func get_location(tod: float) -> String:
	var e: Dictionary = get_active_entry(tod)
	return e.get("location", "")

## Returns true when the schedule has at least one valid entry.
func is_valid() -> bool:
	return entries.size() > 0

## Validates all entries, printing errors to the Godot debugger. Returns true
## if all entries pass.  Called by WorldBuilder after building a schedule so
## authoring bugs surface at spawn-time, not mid-session.
func validate() -> bool:
	if entries.size() > MAX_ENTRIES:
		push_error("NPCSchedule '%s': too many entries (%d > %d)" % [schedule_name, entries.size(), MAX_ENTRIES])
		return false
	var ok: bool = true
	for i: int in range(entries.size()):
		var e: Variant = entries[i]
		if not (e is Dictionary):
			push_error("NPCSchedule '%s' entry[%d]: not a Dictionary" % [schedule_name, i])
			ok = false
			continue
		var entry: Dictionary = e
		if not entry.has("anchor"):
			push_error("NPCSchedule '%s' entry[%d]: missing 'anchor'" % [schedule_name, i])
			ok = false
		elif not (entry["anchor"] is Vector3):
			push_error("NPCSchedule '%s' entry[%d]: 'anchor' must be Vector3" % [schedule_name, i])
			ok = false
		if not entry.has("activity"):
			push_warning("NPCSchedule '%s' entry[%d]: missing 'activity' (optional but recommended)" % [schedule_name, i])
		if not entry.has("location"):
			push_warning("NPCSchedule '%s' entry[%d]: missing 'location' (optional but recommended)" % [schedule_name, i])
	return ok

# ─── Factory helpers (static) ─────────────────────────────────────────────────

## Build a canonical 4-bucket schedule from parallel arrays.
## Each array must have exactly 4 elements corresponding to:
##   [0] morning (5–11)   [1] midday (11–17)
##   [2] evening (17–21)  [3] night  (21–5 next day)
## `anchors`    — Array of Vector3, one per bucket
## `activities` — Array[String], one per bucket
## `locations`  — Array[String], one per bucket
## Returns a new NPCSchedule resource, or null on validation failure.
static func make_4bucket(
	name_str: String,
	anchors: Array,
	activities: Array[String],
	locations: Array[String]
) -> NPCSchedule:
	if anchors.size() != 4 or activities.size() != 4 or locations.size() != 4:
		push_error("NPCSchedule.make_4bucket: all arrays must have exactly 4 elements")
		return null

	var sched: NPCSchedule = NPCSchedule.new()
	sched.schedule_name = name_str

	# Window boundaries: [morning, midday, evening, night-wrap]
	var starts: Array[float] = [5.0, 11.0, 17.0, 21.0]
	var ends: Array[float]   = [11.0, 17.0, 21.0, 5.0]   # night wraps midnight

	for i: int in range(4):
		sched.entries.append({
			"tod_start": starts[i],
			"tod_end":   ends[i],
			"anchor":    anchors[i],
			"activity":  activities[i],
			"location":  locations[i],
		})

	if not sched.validate():
		return null
	return sched

# ─── Predefined village schedules ────────────────────────────────────────────
# These are convenience constructors used by WorldBuilder._make_npc().
# Adding a new NPC schedule: define a static func here + call it in
# WorldBuilder.NPCS[n]'s "schedule_resource_func" key (future wiring).
# All Vector3 y-values are 0.0 — NPC._tick_schedule overrides y to _spawn_y.

## Elder Maeve — herbalist + village elder.
## Morning: herb garden (NW). Midday: village well. Evening: great tree.
## Night: elder's hut.
static func make_maeve() -> NPCSchedule:
	return make_4bucket(
		"Elder Maeve",
		[
			Vector3(-8.0, 0.0, -6.0),   # morning  — herb garden (NW of plaza)
			Vector3(0.0,  0.0,  0.0),   # midday   — village well / plaza center
			Vector3(-4.0, 0.0, -10.0),  # evening  — great tree base
			Vector3(-10.0, 0.0, -4.0),  # night    — elder's hut porch
		],
		["tending herbs", "at the well", "resting by the great tree", "in her hut"],
		["herb garden", "village well", "great tree", "elder's hut"]
	)

## Smith Edda — forge.
## Morning: forge (stoking). Midday: forge (active work). Evening: forge (cooling).
## Night: smithy rear (sleeping loft).
static func make_edda() -> NPCSchedule:
	return make_4bucket(
		"Smith Edda",
		[
			Vector3(10.0, 0.0, -2.0),   # morning  — smithy entrance (stoking)
			Vector3(10.0, 0.0, -2.0),   # midday   — forge anvil (same spot, active)
			Vector3(10.0, 0.0,  0.0),   # evening  — smithy doorway (cooling)
			Vector3(9.0,  0.0, -3.0),   # night    — smithy rear / loft
		],
		["stoking the forge", "working the anvil", "cooling the forge", "resting"],
		["smithy entrance", "forge anvil", "smithy doorway", "smithy loft"]
	)

## Mara the Merchant — market stall.
## Morning: stall set-up. Midday: open stall. Evening: packing down. Night: inn.
static func make_mara() -> NPCSchedule:
	return make_4bucket(
		"Mara the Merchant",
		[
			Vector3(6.0,  0.0,  4.0),   # morning  — market stall (setting up)
			Vector3(6.0,  0.0,  4.0),   # midday   — market stall (trading)
			Vector3(6.0,  0.0,  4.0),   # evening  — market stall (closing)
			Vector3(2.0,  0.0,  6.0),   # night    — inn common room
		],
		["setting up her stall", "trading at the market", "packing her stall", "at the inn"],
		["market stall", "market stall", "market stall", "inn"]
	)

## Herbalist Lyra — apothecary.
## Morning: forest edge (gathering). Midday: apothecary table. Evening: plaza walk.
## Night: apothecary (studying).
static func make_lyra() -> NPCSchedule:
	return make_4bucket(
		"Herbalist Lyra",
		[
			Vector3(-12.0, 0.0, -8.0),  # morning  — forest edge (gathering)
			Vector3(-6.0,  0.0,  2.0),  # midday   — apothecary table
			Vector3(-2.0,  0.0,  2.0),  # evening  — plaza walk
			Vector3(-6.0,  0.0,  2.0),  # night    — apothecary (studying)
		],
		["gathering herbs", "mixing remedies", "walking the plaza", "studying recipes"],
		["forest edge", "apothecary", "village plaza", "apothecary"]
	)

## Innkeeper Bram — inn.
## Morning: inn courtyard (airing). Midday: inn common room. Evening: inn (busy hour).
## Night: inn bar.
static func make_bram() -> NPCSchedule:
	return make_4bucket(
		"Innkeeper Bram",
		[
			Vector3(2.0,  0.0,  8.0),   # morning  — inn courtyard
			Vector3(2.0,  0.0,  6.0),   # midday   — common room
			Vector3(2.0,  0.0,  6.0),   # evening  — inn (busy hour)
			Vector3(2.0,  0.0,  6.0),   # night    — inn bar
		],
		["airing the inn", "tending the common room", "serving the evening crowd", "manning the bar"],
		["inn courtyard", "inn common room", "inn common room", "inn bar"]
	)

## Stablemaster Roan — stables (east edge).
## Morning: stables (feeding). Midday: south road (scouting). Evening: stables (brushing).
## Night: stable loft.
static func make_roan() -> NPCSchedule:
	return make_4bucket(
		"Stablemaster Roan",
		[
			Vector3(14.0, 0.0,  2.0),   # morning  — stables
			Vector3(8.0,  0.0, 10.0),   # midday   — south road
			Vector3(14.0, 0.0,  2.0),   # evening  — stables
			Vector3(14.0, 0.0,  0.0),   # night    — stable loft entrance
		],
		["feeding the horses", "watching the road", "brushing the horses", "in the stable loft"],
		["stables", "south road", "stables", "stable loft"]
	)

## Trainer Hala — training ground (south plaza edge).
## Morning: drills. Midday: teaching. Evening: cooldown stretches. Night: barracks.
static func make_hala() -> NPCSchedule:
	return make_4bucket(
		"Trainer Hala",
		[
			Vector3(0.0,  0.0, 14.0),   # morning  — training ground
			Vector3(0.0,  0.0, 14.0),   # midday   — training ground (teaching)
			Vector3(2.0,  0.0, 12.0),   # evening  — training ground edge (cooldown)
			Vector3(4.0,  0.0, 16.0),   # night    — barracks
		],
		["running drills", "teaching combat", "stretching after drills", "in the barracks"],
		["training ground", "training ground", "training ground edge", "barracks"]
	)

# ─── Internal helpers ─────────────────────────────────────────────────────────

## Returns true if `tod` falls inside [tod_start, tod_end).
## Handles midnight wrap: when tod_end < tod_start (e.g. night window 21→5)
## the window spans midnight.
func _is_in_window(tod: float, tod_start: float, tod_end: float) -> bool:
	if tod_end > tod_start:
		# Normal window (no midnight wrap)
		return tod >= tod_start and tod < tod_end
	else:
		# Midnight-wrapping window (e.g. night: 21.0 → 5.0)
		return tod >= tod_start or tod < tod_end
