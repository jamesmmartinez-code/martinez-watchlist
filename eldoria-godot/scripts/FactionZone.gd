extends Area3D
# Realm of Eldoria — FactionZone
#
# Attach to any Area3D in the world that represents a named territory.
# The zone accumulates influence for each faction whose enemies are inside it.
# When one faction's influence crosses the CAPTURE_THRESHOLD the zone flips
# ownership and notifies FactionSystem, which fires the war event engine.
#
# ── Scene setup ───────────────────────────────────────────────────────────────
# 1. Create an Area3D node, attach this script.
# 2. Add a CollisionShape3D child (Box/Cylinder — cover the zone footprint).
# 3. Set zone_id and initial_faction in the Inspector.
# 4. Optionally attach a MeshInstance3D child named "GroundPlane" — its
#    modulate will be tinted by corruption level as a visual cue.
#
# ── How capture works ─────────────────────────────────────────────────────────
# Influence ticks up at INFLUENCE_RATE per second per body of that faction
# inside the zone.  Other factions' influence decays at INFLUENCE_DECAY_RATE.
# The zone flips when the leading faction's influence reaches CAPTURE_THRESHOLD.
# A freshly captured zone has a HOLD_LOCK_TIME grace period before it can flip
# again (prevents rapid ping-pong).

@export var zone_id: String         = "zone_default"
@export var initial_faction: String = ""   # empty = unclaimed ("neutral")
@export var capture_threshold: float = 60.0   # influence units to flip zone
@export var hold_lock_time: float    = 20.0   # seconds after capture before re-capture allowed

# ==========================================================================
# State
# ==========================================================================
var controlling_faction: String = ""   # who owns this zone right now
var _influence: Dictionary     = {}    # faction_id → float influence accumulation
var _hold_timer: float         = 0.0   # counts up to hold_lock_time after capture
var _locked: bool              = false # true during hold lock

const INFLUENCE_RATE:       float = 1.5   # per body per second inside zone
const INFLUENCE_DECAY_RATE: float = 0.8   # per second for non-leading factions
const INFLUENCE_MAX:        float = 100.0

# ==========================================================================
# Signals
# ==========================================================================
signal zone_control_changed(zone_id: String, new_faction: String, old_faction: String)

# ==========================================================================
# Lifecycle
# ==========================================================================
func _ready() -> void:
	controlling_faction = initial_faction
	FactionSystem.register_zone(self)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	monitorable = false   # zone doesn't need to be detected by others

func _exit_tree() -> void:
	if is_instance_valid(FactionSystem):
		FactionSystem.unregister_zone(self)

func _process(delta: float) -> void:
	_tick_influence(delta)
	_check_capture()
	_update_visuals()

	if _locked:
		_hold_timer += delta
		if _hold_timer >= hold_lock_time:
			_locked     = false
			_hold_timer = 0.0

# ==========================================================================
# Influence tracking
# ==========================================================================
var _bodies_inside: Dictionary = {}   # body → faction_id (cached at enter)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	var fid := _get_faction(body)
	if fid.is_empty():
		return
	_bodies_inside[body] = fid

func _on_body_exited(body: Node3D) -> void:
	_bodies_inside.erase(body)

func _get_faction(body: Node) -> String:
	# Read faction_id from enemy (set by Enemy._ready from FactionSystem.KIND_TO_FACTION_ID)
	if body.get("faction_id") != null:
		var fid: String = str(body.get("faction_id"))
		if not fid.is_empty():
			return fid
	# Fallback: look up via enemy_kind
	var kind: String = str(body.get("enemy_kind") if body.get("enemy_kind") != null else "")
	return FactionSystem.get_faction_for_kind(kind)

func _tick_influence(delta: float) -> void:
	# Build a count of active bodies per faction this frame.
	var active_factions: Dictionary = {}
	for body: Node in _bodies_inside.keys():
		if not is_instance_valid(body):
			_bodies_inside.erase(body)
			continue
		var fid: String = _bodies_inside[body]
		active_factions[fid] = int(active_factions.get(fid, 0)) + 1

	# Tick influence for factions present; decay others.
	var all_factions: Array = _influence.keys()
	for f: String in active_factions:
		if not _influence.has(f):
			_influence[f] = 0.0
		var count: int = int(active_factions[f])
		_influence[f] = minf(INFLUENCE_MAX, float(_influence[f]) + INFLUENCE_RATE * float(count) * delta)
		if f not in all_factions:
			all_factions.append(f)

	for f: String in all_factions:
		if not active_factions.has(f):
			_influence[f] = maxf(0.0, float(_influence[f]) - INFLUENCE_DECAY_RATE * delta)

func _check_capture() -> void:
	if _locked:
		return
	var best_faction := ""
	var best_score   := 0.0
	for f: String in _influence:
		if float(_influence[f]) > best_score:
			best_score  = float(_influence[f])
			best_faction = f
	if best_score >= capture_threshold and best_faction != controlling_faction:
		_capture(best_faction)

func _capture(new_faction: String) -> void:
	var old_faction := controlling_faction
	controlling_faction = new_faction

	# Reset influence so the winner doesn't immediately re-flip to themselves.
	_influence.clear()
	_influence[new_faction] = capture_threshold * 0.5   # headstart for defender

	_locked     = true
	_hold_timer = 0.0

	emit_signal("zone_control_changed", zone_id, new_faction, old_faction)
	if is_instance_valid(FactionSystem):
		FactionSystem.on_zone_captured(zone_id, new_faction, old_faction)

	# Corruption hook: undead capturing a zone spreads corruption
	if new_faction == "undead" and is_instance_valid(WorldState):
		WorldState.corrupt_zone(zone_id)
	elif old_faction == "undead" and is_instance_valid(WorldState):
		WorldState.cleanse_zone(zone_id)

# ==========================================================================
# Visuals
# ==========================================================================
const FACTION_ZONE_COLORS: Dictionary = {
	"watchers":      Color(0.38, 0.60, 0.92, 0.22),
	"drifters":      Color(0.62, 0.52, 0.38, 0.20),
	"bandits":       Color(0.75, 0.30, 0.20, 0.22),
	"goblins":       Color(0.20, 0.78, 0.25, 0.20),
	"undead":        Color(0.55, 0.70, 0.50, 0.25),
	"crystal_order": Color(0.30, 0.70, 0.95, 0.22),
	"wolves":        Color(0.70, 0.55, 0.30, 0.18),
	"player":        Color(0.90, 0.85, 0.30, 0.20),
}

func _update_visuals() -> void:
	var plane := get_node_or_null("GroundPlane")
	if not plane:
		return
	var base_col: Color = FACTION_ZONE_COLORS.get(controlling_faction, Color(0.5, 0.5, 0.5, 0.15))
	# Corruption tints zone toward sickly green-grey
	if is_instance_valid(WorldState):
		var c := WorldState.corruption_level
		base_col = base_col.lerp(Color(0.45, 0.55, 0.40, base_col.a + 0.1 * c), c * 0.6)
	plane.modulate = base_col

# ==========================================================================
# Public API
# ==========================================================================
func get_influence(faction_id: String) -> float:
	return float(_influence.get(faction_id, 0.0))

func force_capture(faction_id: String) -> void:
	# Called by scripts / quests to hard-assign a zone without influence buildup.
	_capture(faction_id)
