extends StaticBody3D
class_name NPC

@export var npc_name: String = "Villager"
@export var npc_role: String = "villager"
@export var dialogue: String = "Hail, traveler. Stay close to the village walls."
# REFINE: mood-dependent variants by time-of-day (morning / midday / evening / night).
# Falls back to single `dialogue` line above if this array is empty. WorldBuilder.gd
# populates these per-NPC so each villager has a small personality detail.
@export var dialogue_variants: PackedStringArray = PackedStringArray()
# INTEGRATE (pattern A): when this NPC has earned a memory flag from a quest
# consequence (Maeve→first_quest_done, Lyra→trusts_player, Mara→good_customer),
# their lines should warm. `warmed_flag` names the flag to consult on World;
# `warmed_dialogue_variants` is the same morning/midday/evening/night structure
# as `dialogue_variants`, used only when the flag is set. Empty = no change.
@export var warmed_flag: String = ""
@export var warmed_dialogue_variants: PackedStringArray = PackedStringArray()
# COMPOUND (run 3 follow-up): a SECOND warmed tier keyed on a *world* flag
# rather than an NPC flag. Lower priority than `warmed_flag` — used only when
# the NPC-flag warm doesn't fire. Lets villagers react to global story beats
# (e.g. Lyra → `lyra_potion_brew`: "the greater salve recipe is loose in the
# village") even before the player has personally helped them. Reuses pattern
# A's mood-bucket array shape; consumes `World.world_flags` (run 2) which had
# no other readers until now.
@export var warmed_world_flag: String = ""
@export var warmed_world_dialogue_variants: PackedStringArray = PackedStringArray()
# COMPOUND (run 4): a THIRD warmed tier keyed on a *faction*'s pressure scalar
# rather than a flag. Lower priority than `warmed_world_flag` — used only when
# neither flag tier fires. Lets villagers react to the SHAPE of the world ("the
# Whisperwood is forgetting the goblins") at any pressure level the author
# chooses. Closes the consequence-resolver loop: faction_pressure() is written
# by 3 quests since run 2 and had ZERO readers until now. Reuses pattern A's
# mood-bucket array shape; consumes `World.faction_pressure(id)`.
@export var warmed_faction_id: String = ""
@export var warmed_faction_below: float = 1.0
@export var warmed_faction_dialogue_variants: PackedStringArray = PackedStringArray()
# COMPOUND (run 16 — Builder): a FOURTH warmed tier keyed on visit count.
# Lower priority than `warmed_faction_id` — used only when none of the
# personal-flag / world-flag / faction-pressure tiers fired. Lets a villager
# react to "we've spoken many times" even when the world hasn't moved and the
# player hasn't completed any specific deed for them. World.npc_memory
# tracks the visit ledger (run-16 Builder); NPC.gd reads it via
# `World.npc_visits(npc_name)`. Threshold of 0 = tier disabled (default).
# Author's threshold convention: 3 = "you again, friend" cadence — third
# visit triggers the warm bucket so a player who comes by twice still gets
# fresh-eyes greetings the first two times.
@export var warmed_memory_visits_min: int = 0
@export var warmed_memory_dialogue_variants: PackedStringArray = PackedStringArray()
# COMPOUND (run 9 — JSON dialogue tree): when set true, this NPC's lines are
# resolved by `DialogueDB.choose_line(npc_name, ctx)` from a JSON tree at
# `res://data/dialogue/<npc_slug>.json` BEFORE falling back to the
# variants/warmed_* pipeline. JSON trees support a richer predicate set
# (low_health_player, boss_slain, boss_alive, high_renown, stranger, festival
# keys, after_first_quest_complete, time-of-day mood, default). On JSON miss
# (no file, parse error, or no matching predicate) the existing variants
# pipeline below is used unchanged. Defaults false so legacy NPCs are
# untouched. WorldBuilder.gd opts NPCs in via `"use_json_dialogue": true`.
@export var use_dialogue_json: bool = false

# COMPOUND (run 11 — NPC SCHEDULES): each visible villager moves between
# role-specific anchor positions throughout the day, keyed off
# `World.time_of_day` (24-hour cycle, 6 real-minute period). Closes the
# §12 MOTION & LIFE gap for static-foot NPCs and gives every existing
# 4-bucket dialogue tier a matching 4-bucket *physical* tier.
#
# `schedule_anchors` — Array of up to 4 Vector3, indexed by ToD bucket:
#     [0] morning  (5.0  ≤ tod < 11.0)
#     [1] midday   (11.0 ≤ tod < 17.0)
#     [2] evening  (17.0 ≤ tod < 21.0)
#     [3] night    (tod < 5.0  OR  tod ≥ 21.0)
# Empty array = legacy behavior (NPC stays at WorldBuilder spawn pos).
# Shorter arrays clamp to last entry (so a 1-element array means "always
# at this anchor" — useful for sleepers like Hala who move only slightly).
#
# `schedule_speed` — m/s walk speed when traversing between anchors.
# `schedule_arrival_radius` — within this distance of target, snap & idle.
# THEME §13 GROUND CONTACT: y is forced to `_spawn_y` (cached at _ready)
# on every tick — even if an anchor is authored with a nonzero y, the
# NPC's xz-walk preserves the spawn-time y.
@export var schedule_anchors: Array = []
# REFINE: character — schedule_speed 0.8 → 0.55 m/s. 0.8 read as 'rushing to anchor'; 0.55 reads as a dignified, lived-in walk per THEME §1 ('lived-in') and §12 (motion that doesn't feel like skating). Compounds on run 11 schedule anchors.
@export var schedule_speed: float = 0.55
# REFINE: character — schedule_arrival_radius 0.5 → 0.35 m. The 0.5m slop produced a visible 'almost-there hover' before the snap; 0.35m tightens the arrival beat without inducing jitter (well above the per-frame step at speed 0.55 × 1/60s ≈ 0.009m).
@export var schedule_arrival_radius: float = 0.35

# Cached state for the schedule walker. `_last_bucket` is reserved for
# future bucket-change hooks (e.g. trigger a one-shot anim on transition);
# the walker recomputes target each tick from live `time_of_day`, so a
# one-frame mismatch on `_last_bucket` is harmless.
var _last_bucket: int = -1
var _spawn_y: float = 0.0
# REFINE: character — animation timing. Cache the AnimationPlayer's idle/walk
# anim names at _ready so the schedule walker (below) can swap between them
# WITHOUT re-scanning each tick. Empty string = anim not found (graceful no-op).
# THEME §12 MOTION & LIFE: a body that slides between anchors with a static
# Idle anim looking forward is "skating". Caching Walk lets us actually swing
# legs when walking, then settle into Idle when arriving. Sourced GLBs name
# the walk clip variously (Walk / Walking / Run / WalkForward / mixamo.com),
# so we scan a handful of common spellings.
var _walk_anim_name: String = ""
var _idle_anim_name: String = ""
# REFINE: character — animation timing. Random per-NPC phase so when several
# villagers stand in shot together (e.g. Bram + Mara at the well at midday)
# their breathing doesn't sync into one mechanical rise-fall. THEME §12 calls
# for "subtle Y-bob breathing" specifically when a sourced GLB lacks anims;
# we apply this fallback only when no AnimationPlayer is found, so animated
# NPCs keep their authored skeleton motion intact and never double-bob.
var _breathe_phase: float = 0.0
# REFINE: character — animation timing. Whether the schedule walker is
# currently in transit (true) vs idling at an anchor (false). Toggled by
# _tick_schedule so the anim swap fires ON THE TRANSITION rather than
# every frame, which would constantly restart the AnimationPlayer (visible
# as a stiff first-frame snap) and waste the playback queue.
var _is_walking_schedule: bool = false

@onready var label_3d: Label3D = get_node_or_null("Label3D") as Label3D
@onready var interact_area: Area3D = get_node_or_null("InteractArea") as Area3D
# RIGGING_STANDARD §Required animations — shared humanoid library so NPCs
# can play wave / yes / no / idle / walk regardless of source-GLB.
const HUMANOID_BASE_LIB := "res://assets/animations/humanoid_base.glb"

@onready var anim: AnimationPlayer = get_node_or_null("AnimationPlayer")

var player_in_range: bool = false
# COMPOUND (run 9): cached Player ref captured on body_entered so that
# DialogueDB ctx can carry an accurate hp_ratio without a fresh group lookup.
# Cleared on body_exited.
var _player_ref: Player = null

func _ready() -> void:
	if label_3d:
		label_3d.text = npc_name
		label_3d.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	# Idle anim if available — prefer canonical humanoid/idle when the merged
	# library brought one in; otherwise fall back to the source-GLB clip.
	if anim:
		if anim.has_animation("humanoid/idle"):
			anim.play("humanoid/idle")
		elif anim.has_animation("Idle"):
			anim.play("Idle")
	# REFINE: character — animation timing. Resolve and cache idle/walk
	# clip names from whichever AnimationPlayer this NPC actually owns
	# (the @onready `anim` only sees a *direct* child named "AnimationPlayer";
	# GLB-imported NPCs hide theirs deeper in the rig). Falls back to
	# scanning the full subtree via _find_first_anim_player() so authored
	# Walk/Idle clips survive the import-path lottery.
	var ap_resolved: AnimationPlayer = anim if anim != null else _find_first_anim_player(self)
	# Merge humanoid_base.tres so the shared library is available — NPCs can
	# play wave/yes/no on dialogue regardless of their source GLB. Graceful
	# no-op if the .tres hasn't been built yet.
	if ap_resolved != null and ResourceLoader.exists(HUMANOID_BASE_LIB):
		var _packed := load(HUMANOID_BASE_LIB) as PackedScene
		if _packed != null:
			var _inst: Node = _packed.instantiate()
			var _src_ap: AnimationPlayer = _inst.find_child("AnimationPlayer", true, false) as AnimationPlayer if _inst else null
			if _src_ap != null:
				var _lib := AnimationLibrary.new()
				for _an in _src_ap.get_animation_list():
					_lib.add_animation(_an, _src_ap.get_animation(_an))
				if ap_resolved.has_animation_library("humanoid"):
					ap_resolved.remove_animation_library("humanoid")
				ap_resolved.add_animation_library("humanoid", _lib)
			if _inst: _inst.queue_free()
	if ap_resolved != null:
		var names := ap_resolved.get_animation_list()
		# Prefer common spellings in order of likelihood, then fall back to
		# the first list entry for "Idle" so even unusually-named clips like
		# "ArmatureAction.001" (Mixamo default) still pin something.
		for n in ["Idle", "idle", "IdleAnimation", "Standing", "ArmatureAction.001", "Take 001", "mixamo.com"]:
			if ap_resolved.has_animation(n):
				_idle_anim_name = n
				break
		if _idle_anim_name == "" and names.size() > 0:
			# Prefix scan: some GLBs use "Prefix|AnimName" convention
			for n in names:
				var ns := String(n).to_lower()
				if ns.contains("idle") or ns.contains("stand") or ns.contains("rest"):
					_idle_anim_name = String(n)
					break
			# Final fallback: just use first animation
			if _idle_anim_name == "":
				_idle_anim_name = String(names[0])
		for n in ["Walk", "walk", "Walking", "WalkForward", "Run", "run", "WalkAnimation", "RunAnimation"]:
			if ap_resolved.has_animation(n):
				_walk_anim_name = n
				break
		# Prefix scan for walk/run if not found yet
		if _walk_anim_name == "":
			for n in names:
				var ns := String(n).to_lower()
				if ns.contains("walk") or ns.contains("run") or ns.contains("locomot"):
					_walk_anim_name = String(n)
					break
	# REFINE: character — animation timing. Per-NPC breathe phase prevents
	# group-sync "rise/fall in unison" effect when multiple anim-less NPCs
	# share frame (THEME §12 — life should look incidental, not metronomic).
	_breathe_phase = randf() * TAU
	# COMPOUND (run 11): cache spawn-time y so schedule walker preserves it.
	# WorldBuilder spawns NPCs at y=0 with the collision capsule's y-offset
	# of 0.9 putting feet on ground — schedule must not re-base y or the
	# NPC sinks/floats.
	_spawn_y = global_position.y

func _process(delta: float) -> void:
	# Show name label only when player is in range
	if label_3d:
		label_3d.visible = player_in_range
	# COMPOUND (run 11): walk the schedule. Halts during dialogue range so
	# the player can actually catch them. Free op when schedule_anchors is
	# empty (legacy NPCs).
	if not schedule_anchors.is_empty() and not player_in_range:
		_tick_schedule(delta)
	else:
		# REFINE: character — animation timing. When the schedule walker isn't
		# driving motion (no anchors, OR player is mid-conversation), make sure
		# the anim state is "Idle" rather than whatever Walk frame we left mid-
		# stride. Without this, an NPC interrupted at mid-step holds a weird
		# T-lean until the next bucket flip. Guard on the toggle so we don't
		# re-issue play() every frame.
		if _is_walking_schedule:
			_is_walking_schedule = false
			if anim != null and _idle_anim_name != "" and anim.current_animation != _idle_anim_name:
				anim.play(_idle_anim_name)
	# REFINE: character — animation timing. THEME §12 fallback: NPCs sourced
	# from GLBs that ship without animations would otherwise be perfectly
	# static (hard-banned by §12). Apply a subtle Y-bob (~2cm amplitude,
	# ~2.5s period — exactly the spec) layered on top of `_spawn_y` so feet
	# never lift more than a sock-thickness off the cobble. Skip when an
	# AnimationPlayer is present (authored skeleton anims handle breathing)
	# and skip while the schedule walker is moving us (it overwrites .y
	# anyway and we'd just be fighting it for a frame).
	if anim == null and not _is_walking_schedule:
		var t: float = float(Time.get_ticks_msec()) / 1000.0
		var bob: float = sin(t * 2.513 + _breathe_phase) * 0.018
		global_position.y = _spawn_y + bob

func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_in_range = true
		_player_ref = body as Player
		(body as Player).interact_pressed.connect(_on_interact)

func _on_body_exited(body: Node) -> void:
	if body is Player:
		player_in_range = false
		if (body as Player).interact_pressed.is_connected(_on_interact):
			(body as Player).interact_pressed.disconnect(_on_interact)
		if _player_ref == body:
			_player_ref = null

func _on_interact() -> void:
	if not player_in_range:
		return
	# Voice line 2026-05-05: play the NPC's greeting MP3 (Workers AI Aura-2 TTS).
	# Looks for assets/audio/voices/{npc_name_lower}_greeting.mp3 — if absent,
	# silently skip. Per-NPC variants (e.g. maeve_quest, maeve_thanks) can be
	# triggered later from quest hooks.
	_play_voice_line(npc_name.to_lower() + "_greeting")
	# REFINE: choose a mood-dependent line by time-of-day when variants exist;
	# otherwise emit the single fallback `dialogue` line as before.
	# INTEGRATE (pattern A): if a `warmed_flag` is set and the World records
	# that this NPC carries it, prefer the warmed variants of the same shape.
	# Quest consequences write these flags via World.apply_consequence().
	var line: String = dialogue
	var w = get_tree().get_first_node_in_group("world")
	# COMPOUND (run 16 — Builder): record this interaction in World.npc_memory
	# BEFORE tier resolution. Visit count includes the current call, so a
	# `warmed_memory_visits_min: 3` predicate fires on the third hello (not
	# the fourth). Fail-soft: older World autoloads without the accessor
	# (e.g. saved games loaded under a stale version) skip recording silently.
	if w and w.has_method("record_npc_visit"):
		w.record_npc_visit(npc_name)
	# COMPOUND (run 9): JSON-tree dialogue resolves FIRST when opted-in. The
	# tree supports a richer predicate set (HP, boss state, festival, etc.)
	# than the four time-of-day mood buckets below. Misses fall through to the
	# legacy variants/warmed_* pipeline so opt-in is purely additive.
	if use_dialogue_json:
		var hp_ratio: float = 1.0
		if _player_ref != null and _player_ref.max_hp > 0:
			hp_ratio = float(_player_ref.hp) / float(_player_ref.max_hp)
		var tod: float = 11.0
		if w and ("time_of_day" in w):
			tod = float(w.time_of_day)
		var ctx: Dictionary = {
			"world": w,
			"tod": tod,
			"hp_ratio": hp_ratio,
			"warmed_flag": warmed_flag,
		}
		var json_line: String = DialogueDB.choose_line(npc_name, ctx)
		if json_line != "":
			get_tree().call_group("world", "show_dialogue", npc_name, json_line, npc_role)
			return
	var variants: PackedStringArray = dialogue_variants
	if warmed_flag != "" and not warmed_dialogue_variants.is_empty() and w and w.has_method("npc_has_flag"):
		if w.npc_has_flag(npc_name, warmed_flag):
			variants = warmed_dialogue_variants
	# COMPOUND: only consult the world-flag tier if the NPC-flag tier didn't
	# already promote the variants. This keeps "you helped me personally" louder
	# than "you helped the world" when both are true.
	if variants == dialogue_variants and warmed_world_flag != "" and not warmed_world_dialogue_variants.is_empty() and w and w.has_method("has_world_flag"):
		if w.has_world_flag(warmed_world_flag):
			variants = warmed_world_dialogue_variants
	# COMPOUND (run 4): only consult the faction-pressure tier if neither flag
	# tier already promoted variants. Pressure thresholds are author-set, so a
	# threshold of 1.0 always fires (use 0.7 / 0.5 / 0.3 for "lightly safer" /
	# "noticeably safer" / "definitively safer"). Runtime guard on
	# `has_method("faction_pressure")` keeps older World autoloads safe.
	if variants == dialogue_variants and warmed_faction_id != "" and not warmed_faction_dialogue_variants.is_empty() and w and w.has_method("faction_pressure"):
		var fp: float = float(w.faction_pressure(warmed_faction_id))
		if fp < warmed_faction_below:
			variants = warmed_faction_dialogue_variants
	# COMPOUND (run 16 — Builder): memory tier fires only when no higher tier
	# already promoted variants. Reads `World.npc_visits(npc_name)` (the
	# accessor wraps the internal `npc_memory` dict so future schema changes
	# don't break this callsite). Threshold of 0 disables the tier — the
	# default for every NPC, so this is purely additive. The tier sits below
	# faction-pressure on the assumption that a villager reacts to the SHAPE
	# of the world before they react to the cadence of their relationship
	# with the player; tune by reordering if play-testing disagrees.
	if variants == dialogue_variants and warmed_memory_visits_min > 0 and not warmed_memory_dialogue_variants.is_empty() and w and w.has_method("npc_visits"):
		var visits: int = int(w.npc_visits(npc_name))
		if visits >= warmed_memory_visits_min:
			variants = warmed_memory_dialogue_variants
	if not variants.is_empty():
		var tod: float = 11.0
		if w and ("time_of_day" in w):
			tod = float(w.time_of_day)
		var bucket: int = 0
		if tod >= 5.0 and tod < 11.0:
			bucket = 0   # dawn / morning
		elif tod >= 11.0 and tod < 17.0:
			bucket = 1   # midday
		elif tod >= 17.0 and tod < 21.0:
			bucket = 2   # evening
		else:
			bucket = 3   # night
		bucket = min(bucket, variants.size() - 1)
		line = variants[bucket]
	# Emit a dialog signal that the World scene picks up to show UI
	get_tree().call_group("world", "show_dialogue", npc_name, line, npc_role)

func _npc_play_idle_anim_if_any() -> void:
	# Walks this NPC's child subtree for an AnimationPlayer and plays a likely
	# idle animation. NPCs sourced from third-party GLBs ship anims under varied
	# names (Idle / idle / ArmatureAction.001 / Take 001 / Scene). We try common
	# spellings, then fall back to the first available animation if any.
	var ap: AnimationPlayer = _find_first_anim_player(self)
	if ap == null:
		return
	for n in ["Idle", "idle", "IdleAnimation", "ArmatureAction.001", "Take 001", "Scene"]:
		if ap.has_animation(n):
			ap.play(n)
			return
	var names := ap.get_animation_list()
	if names.size() > 0:
		ap.play(names[0])

func _find_first_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_first_anim_player(c)
		if found != null:
			return found
	return null
# ────────────────────────────────────────────────────────────────────────
# COMPOUND (run 11): schedule walker — moves NPC between time-of-day
# anchors. See @export-block doc for shape & buckets.
# ────────────────────────────────────────────────────────────────────────
func _tick_schedule(delta: float) -> void:
	var w: Node = get_tree().get_first_node_in_group("world")
	var tod: float = 11.0
	if w and ("time_of_day" in w):
		tod = float(w.time_of_day)
	var bucket: int = _bucket_for_tod(tod)
	var n: int = schedule_anchors.size()
	if n <= 0:
		return
	var idx: int = min(bucket, n - 1)
	var anchor_var = schedule_anchors[idx]
	if not (anchor_var is Vector3):
		return
	var target: Vector3 = anchor_var
	target.y = _spawn_y  # THEME §13: never re-base ground contact

	if bucket != _last_bucket:
		_last_bucket = bucket  # reserved for future bucket-change hooks

	var here: Vector3 = global_position
	var to_target: Vector3 = Vector3(target.x - here.x, 0.0, target.z - here.z)
	var dist: float = to_target.length()
	if dist <= schedule_arrival_radius:
		global_position = Vector3(target.x, _spawn_y, target.z)
		# REFINE: character — animation timing. Arriving at an anchor: settle
		# into the idle clip. Edge-trigger via `_is_walking_schedule` so we
		# only call play() once per arrival, not every frame the NPC is
		# parked. THEME §12: each role has a specific idle (Maeve sweeps,
		# Smith hammers) — those role-anims are still authored externally;
		# this just makes sure we're playing whatever idle the rig owns.
		if _is_walking_schedule:
			_is_walking_schedule = false
			if anim != null and _idle_anim_name != "" and anim.current_animation != _idle_anim_name:
				anim.play(_idle_anim_name)
		return
	var step: float = min(schedule_speed * delta, dist)
	var dir: Vector3 = to_target / dist
	var new_pos: Vector3 = here + dir * step
	new_pos.y = _spawn_y
	global_position = new_pos
	# REFINE: character — animation timing. We're traversing: prefer the Walk
	# clip if the rig has one, else stay on Idle (better than nothing). Edge-
	# triggered: only re-play() on the transition idle→walk, not every tick.
	if not _is_walking_schedule:
		_is_walking_schedule = true
		if anim != null:
			var want: String = _walk_anim_name if _walk_anim_name != "" else _idle_anim_name
			if want != "" and anim.current_animation != want:
				anim.play(want)
	# REFINE: character — animation timing. Smooth yaw instead of snap.
	# The original `look_at(face_at, UP)` re-aimed the NPC every frame to
	# the live motion direction — which during diagonal turns produced a
	# visible jolt as the heading vector rotated. lerp_angle (5 rad/s
	# convergence) lets the body lead with shoulders rather than flick like
	# a turret, matching THEME §1's "lived-in" pacing. Singularity guard
	# preserved: we still skip when motion magnitude is sub-mm.
	if to_target.length() > 0.001:
		var desired_yaw: float = atan2(dir.x, dir.z)
		var current_yaw: float = rotation.y
		var smoothed: float = lerp_angle(current_yaw, desired_yaw, clamp(delta * 5.0, 0.0, 1.0))
		rotation.y = smoothed

func _bucket_for_tod(tod: float) -> int:
	if tod >= 5.0 and tod < 11.0:
		return 0   # morning
	if tod >= 11.0 and tod < 17.0:
		return 1   # midday
	if tod >= 17.0 and tod < 21.0:
		return 2   # evening
	return 3       # night


# Plays an NPC voice line MP3 from assets/audio/voices/. No-op if the file
# doesn't exist or AudioStreamPlayer3D can't load it. Each NPC instance
# manages its own player so two NPCs talking won't talk over each other.
func _play_voice_line(line_id: String) -> void:
	var path := "res://assets/audio/voices/" + line_id + ".mp3"
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_size = 12.0
	player.max_distance = 25.0
	player.bus = "Master"
	player.autoplay = true
	player.position = Vector3(0, 1.7, 0)
	add_child(player)
	player.finished.connect(player.queue_free)

	# 2026-05-06: lift visible mesh so feet sit at body-local y=0 (THEME §13).
	# NPCs were rendering half-buried because their GLB pivot is at center.
	call_deferred("_lift_npc_to_ground")

func _lift_npc_to_ground() -> void:
	# Walk children, find lowest VisualInstance3D y, lift everything up by that amount.
	var lowest: float = INF
	var found := false
	for v in find_children("*", "VisualInstance3D", true):
		var vi := v as VisualInstance3D
		if vi == null: continue
		var a: AABB = vi.global_transform * vi.get_aabb()
		if not found or a.position.y < lowest:
			lowest = a.position.y
			found = true
	if not found: return
	# If lowest visible point is below current global Y, lift the NPC root.
	var floor_y := global_position.y
	if lowest < floor_y - 0.05:
		var lift := floor_y - lowest
		global_position.y += lift

