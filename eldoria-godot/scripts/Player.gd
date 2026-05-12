extends CharacterBody3D
class_name Player

# Realm of Eldoria — Player controller (third-person)
# WASD or Arrow keys to move, Space to jump, E to interact, left-click to attack

@export var walk_speed: float = 5.5
@export var run_speed: float = 9.0
@export var jump_velocity: float = 5.5
@export var rotation_speed: float = 12.0
@export var camera_pivot: Node3D
@export var animation_player: AnimationPlayer
# "vanguard" | "pathfinder" | "mage" | "knight" — controls which class animation
# library (.tres) is loaded at _ready and which slot candidates _play_anim checks first.
@export var player_class: String = "vanguard"

# ── State machine ────────────────────────────────────────────────────────────
# One authoritative state drives animations — no scattered if/else chains.
enum PlayerState { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }
var _player_state: PlayerState = PlayerState.IDLE

var gravity: float = 20.0
var current_speed: float
var is_attacking: bool = false
var is_dead: bool = false
# Last enemy to land a hit — used by NemesisSystem to mark the killer
var _last_attacker: Node = null
# Set by Juice.player_cinematic() for boss intros / cutscene moments
var cinematic_lock: bool = false
# World-feel tick: low-HP tint + corruption shake throttled to not spam every frame
var _world_feel_timer: float = 0.0
# Stuck-recovery timers (kids need this to never feel locked out)
var _attack_timeout: float = 0.0
var _dead_timer: float = 0.0
var _jam_timer: float = 0.0
# Teleport-snap guard: floor_snap_length is zeroed at teleport time, restored
# after _snap_restore_frames physics frames so overlap resolution runs first.
var _just_teleported: bool = false
var _snap_restore_frames: int = 0
# Skill system
var _skill_timers: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _dash_vel:     Vector3      = Vector3.ZERO
# Combo chain (Slash only — auto-resets after COMBO_WINDOW seconds)
var _combo_step:  int   = 0
var _combo_timer: float = 0.0
const COMBO_WINDOW: float = 1.1   # seconds before chain resets
var last_position: Vector3 = Vector3.ZERO  # Physics: track for stuck-detection auto-recovery

# ── Jump feel constants (tuned for 9-11yo: forgiving but not floaty) ─────────
const JUMP_CUT:        float = 0.42   # tap jump → short hop; hold → full arc
const COYOTE_TIME:     float = 0.12   # seconds after leaving ledge to still jump
const JUMP_BUFFER_TIME: float = 0.14  # press-before-landing forgiveness window
var _coyote_timer:  float = 0.0
var _jump_buffer:   float = 0.0

# ── Attack input buffer ───────────────────────────────────────────────────────
# Players press attack at the wrong time constantly. Buffer the press and replay
# it automatically as soon as the current attack's recovery ends.
# Works for both LMB (skill 0) and number keys — whichever fires last wins.
const ATTACK_BUFFER_TIME: float = 0.20
var _attack_buffered_idx: int   = -1   # -1 = nothing buffered
var _attack_buffer_timer: float = 0.0

# Stats
var hp: int = 120
var max_hp: int = 120
var mp: int = 30
var max_mp: int = 30
var xp: int = 0
var level: int = 1
var gold: int = 50
var skill_points: int = 0   # earned on level-up; spent via SkillTree.try_unlock()

# Combat parameters
@export var attack_range: float = 2.6
@export var attack_arc_deg: float = 110.0
@export var attack_damage_base: int = 14
@export var crit_chance: float = 0.12
@export var crit_multiplier: float = 2.0

# ── Skill roster (keys 1 / 2 / 3 — also left-click fires skill 0) ──────────
# damage_mult applies on top of _roll_damage(); arc_bonus in degrees.
# dash_speed launches the player forward during windup so Dash Attack
# actually covers ground before the hit frame fires.
const SKILLS: Array = [
	{   # ── 0: LMB / key 1 ───────────────────────────────────────────────
		"name":       "Slash",
		"damage_mult": 1.0,  "cooldown": 0.55,
		"animation":  "attack",       # _play_anim upgrades to attack_1/2/3 for combo
		"windup":     0.12,  "recovery": 0.22,
		"mp_cost":    0,     "dash_speed": 0.0,
		"range_bonus": 0.0,  "arc_bonus": 0.0,
		"projectile": false, "combo": true,         # 3-hit chain on repeated press
	},
	{   # ── 1: key 2 ─────────────────────────────────────────────────────
		"name":       "Heavy Strike",
		"damage_mult": 2.6,  "cooldown": 2.8,
		"animation":  "attack",
		"windup":     0.42,  "recovery": 0.55,
		"mp_cost":    5,     "dash_speed": 0.0,
		"range_bonus": 0.5,  "arc_bonus": -35.0,   # precise narrow cone
		"projectile": false, "combo": false,
	},
	{   # ── 2: key 3 ─────────────────────────────────────────────────────
		"name":       "Dash Attack",
		"damage_mult": 1.6,  "cooldown": 4.5,
		"animation":  "run",
		"windup":     0.08,  "recovery": 0.32,
		"mp_cost":    8,     "dash_speed": 9.0,
		"range_bonus": 1.2,  "arc_bonus": 40.0,    # wide sweep after dash
		"projectile": false, "combo": false,
	},
	{   # ── 3: key 4 ─────────────────────────────────────────────────────
		"name":       "Fireball",
		"damage_mult": 1.8,  "cooldown": 5.0,
		"animation":  "attack",
		"windup":     0.28,  "recovery": 0.35,
		"mp_cost":    12,    "dash_speed": 0.0,
		"range_bonus": 0.0,  "arc_bonus": 0.0,
		"projectile": true,  "combo": false,        # spawns Fireball.gd projectile
	},
]

# Skills unlock progressively — index matches SKILLS above.
# Keeps early game simple: Alden only has Slash until level 3.
const SKILL_UNLOCK_LEVELS: Array[int] = [1, 3, 5, 7]

# Inventory + equipment (managed by Inventory child node)
var inventory: Node = null

# Quest tracking
var kills_by_kind: Dictionary = {}   # e.g. {"goblin": 3}
var active_quest: Dictionary = {}    # {"target":"goblin", "needed":5, "killed":0, "giver":"Maeve"}

# ── Adaptive Playstyle Tracker ─────────────────────────────────────────────
# Counters accumulate every time the matching action fires in real gameplay.
var playstyle: Dictionary = {
	"aggressive": 0,   # attacks used
	"defensive":  0,   # times taking damage
	"airborne":   0,   # jumps executed
	"dash_heavy": 0,   # Dash Attack / dash skill fires
}
# Per-skill usage counters (parallel to SKILLS array)
var _skill_use_counts: Array = [0, 0, 0, 0]
# Ability mutations unlocked through play — never cleared (saved with game)
var _mutations: Dictionary = {}
# Early-unlock overrides — skills whose level gate has been bypassed via play
var _early_unlocks: Array = []
# Adaptation tick — we check unlocks/mutations every ADAPT_INTERVAL seconds
var _adapt_timer: float = 0.0
const ADAPT_INTERVAL: float = 10.0

# Mounted state
var mounted: bool = false
var mount_node: Node3D = null

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")
const FIREBALL_SCRIPT      = preload("res://scripts/Fireball.gd")
const SAFE_SPAWN := Vector3(0, 0.5, 0)   # Plaza centre — Briarwood village crossroads.
# Scale fix 2026-05-11: buildings grew from 3.6 m to 6.0 m footprint.
#   Old (10,2,3): building (10,0,0) north wall is now at z=+3.0 exactly — capsule
#   radius 0.4 put the player INSIDE the wall → physics ejection → stuck on roof. WRONG.
# (0, 2, 0) building clearances (all buildings are 6m footprint, half-extent 3m):
#   (10,0,0):  x=[7,13]  — player x=0 is 7m west.  ✓
#   (-10,0,0): x=[-13,-7]— player x=0 is 7m east.  ✓
#   (6,0,6):   z=[3,9]   — player z=0 is 3m south. ✓
#   (-6,0,6):  z=[3,9]   — same.                    ✓
#   (6,0,-8):  z=[-11,-5]— player z=0 is 5m north.  ✓
#   HOME(0,14): z=[11,17] — player z=0 is 11m south. ✓
# Y=2.0: capsule bottom 2 m above terrain so floor seams can't read it as "inside".
#   Gravity settles the player in ≤ 0.5 s.  _find_free_spawn adds 0.5 m extra lift.
const INVENTORY_SCRIPT    = preload("res://scripts/Inventory.gd")

# Visible weapon attached to the player's body (re-built when equipment changes)
var weapon_visual: Node3D = null

# Floating title above the player's head — drawn as a Label3D so it
# tracks the player in 3D space and reads from the cooperative camera at
# any orbit angle. Hidden until World assigns a title via set_title().
# THEME §12 motion-and-life: the label has a tiny Y-bob tween so it
# breathes instead of standing dead. THEME §3 palette: gold-leaf font,
# black outline (matches HUD numbers + toast text).
var title_label: Label3D = null

# Procedural fantasy gear (helm, cape, pauldrons, tabard, belt) bolted onto
# the Vanguard body to make it read as a fantasy hero rather than a soldier.
signal stats_changed
signal interact_pressed

func _ready() -> void:
	# Panic keys must work even when the scene tree is paused (e.g. death overlay).
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_speed = walk_speed
	add_to_group("player")
	add_to_group("quest_listeners")
	collision_layer = 2  # player layer
	collision_mask = 1 | 4  # collide with world (1) and enemies (4)
	# CHECK 10 — floor physics: snap keeps character glued to ramps;
	# max_angle 46° lets them climb gentle slopes without sliding off.
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(65.0)  # allow walking on roof slopes (~40°) and steep ramps
	# Auto-wire camera_pivot if the editor didn't assign it.
	# CameraController calls _ready later and wires itself via p.camera_pivot = self,
	# so this fallback handles scenes where the node is named differently.
	if not camera_pivot:
		var root := get_tree().current_scene
		if root:
			if root.get_node_or_null("CameraController") != null:
				camera_pivot = root.get_node_or_null("CameraController")
			elif root.get_node_or_null("CameraPivot") != null:
				camera_pivot = root.get_node_or_null("CameraPivot")
			elif root.get_node_or_null("Camera") != null:
				camera_pivot = root.get_node_or_null("Camera")
	# Auto-wire animation_player — search any child for an AnimationPlayer.
	# Works regardless of model name (Hero, Soldier, CesiumMan, etc.).
	if not animation_player:
		animation_player = _find_animation_player(self)
	# Load class-specific animation library (.tres) if it exists.
	# Graceful no-op when the file hasn't been built — game still works via fallback names.
	if animation_player:
		call_deferred("_load_class_anim_library")
	# Auto-play idle on first frame so character doesn't stand T-pose
	if animation_player:
		await get_tree().process_frame
		_play_anim("idle")
	# Floating title (hidden until World assigns one). Anchored at y=2.4
	# above feet, billboard-mode so it always faces camera. Two-frame
	# defer so it spawns AFTER the model exists (CharacterDress.gd may
	# still be wiring helms / capes on first frame).
	title_label = Label3D.new()
	title_label.name = "TitleLabel"
	title_label.text = ""
	title_label.visible = false
	title_label.position = Vector3(0, 2.4, 0)
	title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title_label.no_depth_test = true
	title_label.fixed_size = false
	title_label.pixel_size = 0.0035
	title_label.modulate = Color(1.0, 0.85, 0.4)         # palette §3 burnt gold
	title_label.outline_modulate = Color(0, 0, 0, 1)
	title_label.outline_size = 8
	title_label.font_size = 28
	add_child(title_label)
	# THEME §12: tiny Y-bob so the label breathes. Amplitude 0.04m, period 3s.
	var bob: Tween = create_tween().set_loops()
	bob.tween_property(title_label, "position:y", 2.46, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(title_label, "position:y", 2.4, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Inventory
	inventory = Node.new()
	inventory.set_script(INVENTORY_SCRIPT)
	inventory.name = "Inventory"
	add_child(inventory)
	inventory.equipment_changed.connect(_on_equipment_changed)
	inventory.inventory_changed.connect(_on_inventory_changed)
	# Build initial visible weapon
	call_deferred("_rebuild_weapon_visual")
	# Load save on first frame (after inventory wires up)
	call_deferred("load_game")
	# Register all skills in the SkillTree singleton
	call_deferred("_setup_skill_tree")
	# Char-spec: normalize hero to 0.85m (kid Alden/Owen) — SIZE_STANDARDS.md §1.
	# [CANON-APPROVED: 2026-05-10] 1.10 → 0.85 — user feedback "still too big";
	# 0.85m reads as a child character against 3m+ buildings.
	# Three deferred retries absorb the Godot 4 deferred-AABB update lag on GLB import.
	call_deferred("_normalize_player_model", 0.85)
	get_tree().create_timer(0.5).timeout.connect(func(): _normalize_player_model(0.85))
	get_tree().create_timer(1.5).timeout.connect(func(): _normalize_player_model(0.85))
	get_tree().create_timer(3.0).timeout.connect(func(): _force_hero_height_cap(0.90))
	# Teleport to a validated free spawn after the first physics frame.
	get_tree().create_timer(0.05).timeout.connect(func(): teleport_to_safe_spawn())

func _physics_process(delta: float) -> void:
	# Restore floor_snap_length after teleport once physics has had time to
	# resolve any overlap at the new position (see teleport_to_safe_spawn).
	if _snap_restore_frames > 0:
		_snap_restore_frames -= 1
		if _snap_restore_frames == 0:
			floor_snap_length = 0.3
			_just_teleported = false

	# Stuck-recovery #1: if we've fallen out of the world or punched through the
	# top, snap back to a safe spawn so the kids never lose control.
	if global_position.y < -50.0 or global_position.y > 500.0:
		teleport_to_safe_spawn()

	# Stuck-recovery #2: is_attacking should never stay true longer than ~1s.
	# If it does, the attack callback was lost — force-clear it.
	if is_attacking:
		_attack_timeout += delta
		if _attack_timeout > 1.2:
			is_attacking = false
			_attack_timeout = 0.0
	else:
		_attack_timeout = 0.0

	# Autosave every N seconds
	_save_timer += delta
	if _save_timer >= _save_interval:
		_save_timer = 0.0
		save_game()

	# Dynamic skill-tree adaptation tick — checks playstyle-gated unlocks
	_tick_adapt(delta)

	# Skill cooldown countdown
	for i: int in _skill_timers.size():
		if _skill_timers[i] > 0.0:
			_skill_timers[i] = maxf(0.0, _skill_timers[i] - delta)

	# Attack input buffer — if not currently attacking, flush any buffered press
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer = maxf(0.0, _attack_buffer_timer - delta)
		if _attack_buffer_timer <= 0.0:
			_attack_buffered_idx = -1
	if _attack_buffered_idx >= 0 and not is_attacking and not is_dead:
		var bid: int = _attack_buffered_idx
		_attack_buffered_idx = -1
		_attack_buffer_timer = 0.0
		use_skill(bid)

	# Combo window decay — reset chain if player waits too long between hits
	if _combo_timer > 0.0:
		_combo_timer = maxf(0.0, _combo_timer - delta)
	if _combo_timer <= 0.0 and not is_attacking:
		_combo_step = 0

	# Stuck-recovery #3: if dead but somehow still in physics for >5s, auto-revive.
	if is_dead:
		_dead_timer += delta
		if _dead_timer > 5.0:
			is_dead = false
			hp = max(1, hp)
			_dead_timer = 0.0
		return
	else:
		_dead_timer = 0.0

	# ── World-feel ticks (low HP tint + corruption shake) ────────────────────
	_world_feel_timer -= delta
	if _world_feel_timer <= 0.0:
		_world_feel_timer = 0.5   # update twice per second (not every frame)
		_apply_world_feel()

	# Cinematic lock: block movement but allow physics (gravity, move_and_slide)
	# so the player doesn't float during boss intros.
	if cinematic_lock:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Camera-relative movement — MMORPG style:
	# extract forward/right from the camera yaw (Y-rotation) so strafing and
	# reversing always feel correct regardless of where the camera is pointing.
	# Fix: get_vector maps "move_forward" (W) to negative_y → input_dir.y = -1.
	# Swapping the order makes W = positive_y = +1, so forward*input_dir.y = forward. ✓
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	# Re-acquire camera_pivot if it was lost (e.g. scene reload, camera swap)
	if not camera_pivot or not is_instance_valid(camera_pivot):
		var root := get_tree().current_scene
		if root:
			if root.get_node_or_null("CameraController") != null:
				camera_pivot = root.get_node_or_null("CameraController")
			elif root.get_node_or_null("CameraPivot") != null:
				camera_pivot = root.get_node_or_null("CameraPivot")
			elif root.get_node_or_null("Camera") != null:
				camera_pivot = root.get_node_or_null("Camera")
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		if camera_pivot and is_instance_valid(camera_pivot):
			var forward := -camera_pivot.global_transform.basis.z
			var right   :=  camera_pivot.global_transform.basis.x
			forward.y = 0
			right.y   = 0
			var cam_dir := (forward * input_dir.y + right * input_dir.x)
			if cam_dir.length_squared() > 0.0001:
				direction = cam_dir.normalized()
			else:
				# Camera basis degenerate — fall back to world-space movement
				direction = Vector3(-input_dir.x, 0, -input_dir.y).normalized()
		else:
			# No camera pivot — world-space fallback so WASD always works
			direction = Vector3(-input_dir.x, 0, -input_dir.y).normalized()

	# Run modifier (left shift); halved during attack so player can't kite freely
	current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	if is_attacking:
		current_speed *= 0.40

	# Stuck-recovery #4: if input is being pressed but we haven't moved horizontally for >2s,
	# something is jamming us (collision wedge, frozen state).
	# FIX: was doing y += 1.5 which accumulated and launched player into the sky.
	# Now: raycast downward to find the actual floor and snap to it; fall back to SAFE_SPAWN.
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	last_position = global_position  # Physics: track position each frame for stuck-detection
	if input_dir.length() > 0.1 and horiz_speed < 0.05:
		_jam_timer += delta
		if _jam_timer > 2.0:
			_do_floor_snap_unstick()
			_jam_timer = 0.0
	else:
		_jam_timer = 0.0

	if direction.length() > 0.01:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		# Rotate player to face movement direction (standard MMORPG behaviour).
		# look_at guard: skip if direction is degenerate
		var look_pos := global_position + direction
		if global_position.distance_squared_to(look_pos) > 0.0001:
			# alden_pathfinder.glb faces +Z; looking_at makes -Z point at target, so negate direction
			var target_basis := Basis.looking_at(-direction, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 4 * delta)
		velocity.z = move_toward(velocity.z, 0, current_speed * 4 * delta)

	# Dash Attack: override horizontal velocity while _dash_vel is live,
	# then decelerate so the slide feels physical rather than instant-stop.
	if _dash_vel.length() > 0.1:
		velocity.x = _dash_vel.x
		velocity.z = _dash_vel.z
		_dash_vel = _dash_vel.lerp(Vector3.ZERO, 14.0 * delta)

	# ── Coyote time ─────────────────────────────────────────────────────────
	# Reset timer while grounded; tick down while airborne so the player has a
	# COYOTE_TIME-second window to jump after stepping off a ledge.
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# ── Jump buffer ──────────────────────────────────────────────────────────
	# Remember the press even if it arrives slightly before landing.
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER_TIME
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	# ── Commit the jump ──────────────────────────────────────────────────────
	if _jump_buffer > 0.0 and _coyote_timer > 0.0 and not is_attacking:
		velocity.y   = jump_velocity
		_jump_buffer = 0.0
		_coyote_timer = 0.0   # prevent double-jump via coyote window
		GameBrain.record_action("airborne")

	# ── Variable height: short hop on tap, full arc on hold ─────────────────
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= JUMP_CUT

	move_and_slide()

	# ── State machine update → drives all animation ──────────────────────────
	_update_player_state(delta)

# ────────────────────────────────────────────────────────────────────────
# Floor-snap unstick (internal) — raycast downward, land on actual floor.
# Falls back to SAFE_SPAWN if nothing is below us.
# ────────────────────────────────────────────────────────────────────────
func _do_floor_snap_unstick() -> void:
	# Don't fight teleport_to_safe_spawn() — it already placed us in free space;
	# let physics settle the position before we try to snap to a floor.
	if _just_teleported:
		return
	velocity = Vector3.ZERO
	var space := get_world_3d().direct_space_state
	# Cast from 2m above to 8m below current position to find the floor.
	var origin: Vector3 = global_position + Vector3(0, 2.0, 0)
	var target: Vector3 = global_position + Vector3(0, -8.0, 0)
	var query  := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude   = [self]
	query.collision_mask = 1   # terrain / static bodies only
	var hit := space.intersect_ray(query)
	if hit:
		# BUG-FIX 2026-05-10: was +0.5m, which systematically placed the player
		# 0.5m ABOVE every surface the ray hit — visible as floating / elevated.
		# With CollisionShape3D offset = 0.9 and capsule half-height = 0.9, the
		# CharacterBody3D origin IS the capsule bottom, so hit.position alone puts
		# the capsule flush on the surface.  Add 0.02m so floor_snap_length (0.3m)
		# and move_and_slide() latch immediately without a one-frame free-fall gap.
		global_position = hit.position + Vector3(0, 0.02, 0)
		print("[Player] auto-unstick: snapped to floor at y=%.2f" % global_position.y)
	else:
		global_position = _find_free_spawn(SAFE_SPAWN)
		print("[Player] auto-unstick: no floor found — using safe spawn")

# ────────────────────────────────────────────────────────────────────────
# Dynamic spawn validator — probes candidate positions around `desired`
# using the player's real collision shape.  Spirals outward with a small
# Y-lift per ring so uneven terrain edges and mesh seams don't false-block.
#
# Returns a clear character-origin position (capsule bottom).
# Always call via teleport_to_safe_spawn() so floor_snap_length is
# disabled for a few frames and physics can resolve overlaps first.
# ────────────────────────────────────────────────────────────────────────
func _find_free_spawn(desired: Vector3, max_tries: int = 24, radius_step: float = 0.75) -> Vector3:
	var space := get_world_3d().direct_space_state
	# Prefer the actual player collider; fall back to a matching capsule.
	var shape: Shape3D
	var col_node := get_node_or_null("CollisionShape3D")
	if col_node is CollisionShape3D and col_node.shape != null:
		shape = col_node.shape
	else:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.8
		shape = cap
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape        = shape
	params.collision_mask = collision_mask   # full player mask, not just layer 1
	params.exclude      = [self]
	for i in range(max_tries):
		# Golden-angle-ish spread; ring grows slowly so nearby spots are tried first.
		var ring   := float(i / 6)
		var angle  := float(i) * 1.7
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * ring * radius_step
		# Lift rises with ring — clears sloped edges and terrain-mesh seams.
		var lift: Vector3 = Vector3(0, 0.5 + ring * 0.25, 0)
		var candidate := desired + offset
		# Shape centre = candidate + capsule half-height (0.9) + lift.
		params.transform = Transform3D(Basis.IDENTITY, candidate + Vector3(0, 0.9, 0) + lift)
		if space.intersect_shape(params, 1).is_empty():
			if i > 0:
				print("[Player] _find_free_spawn: try %d → clear at %s (lift +%.2fm)" % [
					i, candidate + lift, lift.y])
			return candidate + lift   # character origin: clear and above ground
	push_warning("[Player] _find_free_spawn: no clear spot after %d tries — using %s+0.5" % [max_tries, desired])
	return desired + Vector3(0, 0.5, 0)

# ────────────────────────────────────────────────────────────────────────
# teleport_to_safe_spawn — the ONE function that moves the player to spawn.
# Disables floor_snap_length for 3 physics frames so Godot's overlap
# resolver runs without immediately snapping into terrain.  _just_teleported
# gates _do_floor_snap_unstick() for the same window.
# ────────────────────────────────────────────────────────────────────────
func teleport_to_safe_spawn() -> void:
	var target := _find_free_spawn(SAFE_SPAWN)
	velocity = Vector3.ZERO
	# Zero floor snap so the engine resolves any remaining overlap first.
	floor_snap_length   = 0.0
	_just_teleported    = true
	_snap_restore_frames = 3          # restored in _physics_process after 3 frames
	global_position = target

# ────────────────────────────────────────────────────────────────────────
# Public unstuck — called by the SOS Unstuck button in the HUD.
# Clears every transient lock, snaps to floor, notifies the player.
# ────────────────────────────────────────────────────────────────────────
func do_unstuck() -> void:
	cinematic_lock  = false
	is_attacking    = false
	is_dead         = false
	_jam_timer      = 0.0
	_attack_timeout = 0.0
	get_tree().paused = false
	teleport_to_safe_spawn()
	if is_instance_valid(Juice):
		Juice.show_notification("Teleported to safety!", Color(0.50, 1.0, 0.72))

# ────────────────────────────────────────────────────────────────────────
# Panic-key pipeline — runs BEFORE any is_dead guard so kids can always
# escape a stuck/frozen/dead state. Called from BOTH _input AND
# _unhandled_key_input so UI elements cannot swallow these keys.
# ────────────────────────────────────────────────────────────────────────
func _panic_unstick(keycode: int) -> bool:
	match keycode:
		KEY_BACKSPACE:
			# Full unstick: clear all transient state, unpause, teleport to spawn.
			print("[Player] BACKSPACE — full unstick")
			get_tree().paused = false
			is_dead = false
			is_attacking = false
			mounted = false
			mount_node = null
			hp = max(1, hp)
			_attack_timeout = 0.0
			_dead_timer = 0.0
			_jam_timer = 0.0
			teleport_to_safe_spawn()
			return true
		KEY_F1:
			# Soft unstick: unpause + reset position to spawn.
			print("[Player] F1 — teleport to spawn")
			get_tree().paused = false
			teleport_to_safe_spawn()
			return true
		KEY_F2:
			# Nuclear option: unpause, wipe save and reload scene.
			print("[Player] F2 — wiping save")
			get_tree().paused = false
			reset_save()
			get_tree().reload_current_scene()
			return true
		KEY_BRACKETRIGHT:
			# Alias for F1 — useful on keyboards where function keys are locked.
			print("[Player] ] — teleport to spawn")
			get_tree().paused = false
			teleport_to_safe_spawn()
			return true
	return false

func _unhandled_key_input(event: InputEvent) -> void:
	# Catches panic keys even when a UI control has focus and consumed _input.
	if event is InputEventKey and event.pressed and not event.echo:
		_panic_unstick(event.keycode)

func _input(event: InputEvent) -> void:
	# Panic keys fire BEFORE the is_dead guard — kids must always be able to escape.
	if event is InputEventKey and event.pressed and not event.echo:
		if _panic_unstick(event.keycode):
			get_viewport().set_input_as_handled()
			return
	if is_dead:
		return
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	if event.is_action_pressed("attack"):
		_buffer_attack(0)   # LMB / default = Slash
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		match k:
			KEY_1: _buffer_attack(0)
			KEY_2: _buffer_attack(1)
			KEY_3: _buffer_attack(2)
			KEY_4: _buffer_attack(3)
		if k == KEY_I:
			get_tree().call_group("world", "toggle_inventory")
		elif k == KEY_Q:
			# Quaff health potion (the first hp_potion_s/l in bag)
			_quick_use_potion()
		elif k == KEY_M:
			# Mount/dismount toggle
			get_tree().call_group("world", "toggle_mount")

# ────────────────────────────────────────────────────────────────────────────
# Skill system — three abilities on 1/2/3 (also left-click fires skill 0)
# All timing, range, and damage is driven by the SKILLS table above so new
# skills can be added by editing that array without touching this function.
# ────────────────────────────────────────────────────────────────────────────
func _buffer_attack(idx: int) -> void:
	# Try to fire immediately; if locked (attacking), buffer for up to ATTACK_BUFFER_TIME.
	if not is_attacking and not is_dead:
		use_skill(idx)
	else:
		_attack_buffered_idx = idx
		_attack_buffer_timer = ATTACK_BUFFER_TIME

func _is_skill_unlocked(idx: int) -> bool:
	# Early-unlock overrides come first — playstyle-driven dynamic skills
	# bypass the level gate, so always check _early_unlocks before level.
	if idx in _early_unlocks:
		return true
	return idx < SKILL_UNLOCK_LEVELS.size() and level >= SKILL_UNLOCK_LEVELS[idx]

func use_skill(idx: int) -> void:
	if is_attacking or is_dead:
		return
	if idx < 0 or idx >= SKILLS.size():
		return

	# Unlock gate — skills learned as you level up
	if not _is_skill_unlocked(idx):
		# Spawn a small "Lv.X required" hint above the player
		var hint := Label3D.new()
		hint.text = "Lv.%d required" % SKILL_UNLOCK_LEVELS[idx]
		hint.font_size = 30
		hint.modulate = Color(0.7, 0.7, 1.0)
		hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		hint.no_depth_test = true
		hint.position = global_position + Vector3(0, 2.2, 0)
		get_tree().current_scene.add_child(hint)
		get_tree().create_timer(1.5).timeout.connect(func(): if is_instance_valid(hint): hint.queue_free())
		return

	var sk: Dictionary = SKILLS[idx]

	# Cooldown gate
	if _skill_timers[idx] > 0.0:
		return

	# MP gate
	if mp < int(sk["mp_cost"]):
		return

	# Pay cost + start cooldown + lock
	mp = max(0, mp - int(sk["mp_cost"]))
	_skill_timers[idx] = float(sk["cooldown"])
	is_attacking = true
	stats_changed.emit()

	# ── Playstyle tracking ───────────────────────────────────────────────────
	# Record every skill use as "aggressive" so GameBrain adapts enemies and
	# bosses to the player's combat habits.  Dash Attack additionally records
	# "dash_heavy" because it's the canonical mobile/evasive playstyle marker.
	GameBrain.record_action("aggressive")
	if idx == 2:  # Dash Attack
		GameBrain.record_action("dash_heavy")
	_skill_use_counts[idx] += 1
	_check_ability_mutations(idx)

	# ── Combo chain (Slash only) ─────────────────────────────────────────────
	if sk.get("combo", false):
		_combo_step = (_combo_step % 3) + 1
		_combo_timer = COMBO_WINDOW
		_play_anim("attack_" + str(_combo_step))   # _play_anim falls back to "attack"
	else:
		_play_anim(sk["animation"])

	get_tree().call_group("world", "play_sfx", "sword_swing")

	# Dash: launch forward immediately so the body covers ground during windup
	if float(sk["dash_speed"]) > 0.0:
		var fwd_d := -global_transform.basis.z
		fwd_d.y = 0
		_dash_vel = fwd_d.normalized() * float(sk["dash_speed"])

	# ── Attack anticipation squash (windup body language) ─────────────────────
	# Stretch vertically — body "coils" before releasing force.
	# Juice.stretch is already guard-checked for null node.
	if is_instance_valid(Juice):
		Juice.stretch(self, 0.10)

	# ── Wind-up pause ────────────────────────────────────────────────────────
	await get_tree().create_timer(float(sk["windup"])).timeout
	if is_dead:
		is_attacking = false
		_dash_vel = Vector3.ZERO
		return

	# ── Damage dispatch ──────────────────────────────────────────────────────
	var dmg: Dictionary = _roll_damage()
	var final_dmg: int  = int(float(dmg.amount) * float(sk["damage_mult"]))
	# Armor Break mutation: Heavy Strike (idx 1) deals +40% once unlocked.
	if idx == 1 and GameBrain.has_evolution("heavy_armor_break"):
		final_dmg = int(float(final_dmg) * 1.40)
	var hit_count := 0

	if sk.get("projectile", false):
		# Spawn projectile — it handles its own hit detection async
		_spawn_fireball(final_dmg)
		if dmg.is_crit:
			_spawn_crit_flash()
		hit_count = 1   # optimistic — feedback fires immediately

	else:
		# Arc sweep
		var eff_range := attack_range + float(sk["range_bonus"])
		var eff_arc   := attack_arc_deg + float(sk["arc_bonus"])
		var arc_rad   := deg_to_rad(eff_arc) * 0.5
		var fwd := -global_transform.basis.z
		fwd.y = 0
		fwd = fwd.normalized()

		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy):
				continue
			var to_enemy: Vector3 = enemy.global_position - global_position
			to_enemy.y = 0
			var dist: float = to_enemy.length()
			if dist > eff_range or dist < 0.001:
				continue
			if fwd.angle_to(to_enemy.normalized()) > arc_rad:
				continue
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_dmg, self)
				get_tree().call_group("world", "play_sfx", "sword_hit")
				if dmg.is_crit:
					_spawn_crit_flash()
				hit_count += 1

	# ── Mutation secondary effects ───────────────────────────────────────────
	# Echo Strike: Slash (idx 0) resonates — a second arc fires 0.14s later
	# at 50% damage.  Triggered only when hits landed this swing.
	if idx == 0 and hit_count > 0 and GameBrain.has_evolution("slash_multihit"):
		_echo_strike_secondary(final_dmg)
	# Inferno Spread: Fireball (idx 3) splits into two flanking projectiles
	# at ±22° — launched 0.18s after the main ball clears windup.
	if idx == 3 and hit_count > 0 and GameBrain.has_evolution("fireball_pyro"):
		_inferno_spread_extra(final_dmg)

	# ── Hit-stop — frame-precise freeze on contact ───────────────────────────
	# Delegates to Juice (Engine.time_scale, re-entrant, wall-clock safe).
	# DO NOT manual-set Engine.time_scale here — that bypasses the priority
	# queue in Juice and causes overlapping freezes to fight each other.
	if hit_count > 0:
		Juice.hit_stop_tier(final_dmg)
		# ── Impact squash — body compresses on contact (force transfer read)
		if is_instance_valid(Juice):
			Juice.squash(self, 0.16 + float(idx) * 0.04)
		# ── Combo finisher (step 3) — extra punch for the finishing blow ─────────
		if _combo_step == 3 and is_instance_valid(Juice):
			Juice.camera_fov_punch(10.0, 0.25)
			Juice.screen_shake(0.20, 0.25)
			Juice.screen_flash(Color(1.0, 0.90, 0.50, 0.18), 0.18)
		# ── FOV punch on every heavy skill (idx ≥ 1) ─────────────────────────
		elif idx >= 1 and is_instance_valid(Juice):
			Juice.camera_fov_punch(5.0 + float(idx) * 2.0, 0.18)

	# ── Camera shake on heavy-impact skills (index ≥ 1) ─────────────────────
	if hit_count > 0 and idx >= 1:
		var shake_amt: float = 0.015 + idx * 0.008   # scales with skill power
		if camera_pivot and camera_pivot.has_method("shake"):
			camera_pivot.shake(shake_amt, 0.18)
		elif is_instance_valid(Juice):
			Juice.screen_shake(shake_amt, 0.18)   # fallback: use Juice shake directly

	# ── Recovery lockout ─────────────────────────────────────────────────────
	await get_tree().create_timer(float(sk["recovery"])).timeout
	is_attacking = false
	_dash_vel = Vector3.ZERO

func _spawn_fireball(dmg: int) -> void:
	var fb := Area3D.new()
	fb.set_script(FIREBALL_SCRIPT)
	fb.position = global_position + Vector3(0, 1.0, 0)  # guard: was global_position (orphan crash fix)
	get_tree().current_scene.add_child(fb)
	# Direction = player's facing (forward axis)
	var fire_dir := -global_transform.basis.z
	fire_dir.y = 0
	fire_dir = fire_dir.normalized()
	fb.launch(fire_dir, dmg, self)

# ────────────────────────────────────────────────────────────────────────────
# State machine — ONE function decides what animation plays each frame.
# Physics drives state; state drives animation — never the other way around.
# ────────────────────────────────────────────────────────────────────────────
func _update_player_state(delta: float) -> void:
	# Determine target state from physics truth
	var next: PlayerState
	if is_dead:
		next = PlayerState.DEAD
	elif is_attacking:
		next = PlayerState.ATTACK
	elif not is_on_floor():
		next = PlayerState.JUMP if velocity.y > 0.0 else PlayerState.FALL
	elif Vector2(velocity.x, velocity.z).length() > 0.3:
		next = PlayerState.RUN
	else:
		next = PlayerState.IDLE

	if next == _player_state:
		# Same state — scale run animation speed to actual movement speed
		if _player_state == PlayerState.RUN and animation_player:
			var horiz: float = Vector2(velocity.x, velocity.z).length()
			animation_player.speed_scale = clamp(horiz / run_speed, 0.4, 2.0)
		return

	_player_state = next
	if animation_player:
		animation_player.speed_scale = 1.0   # reset on every state change

	match _player_state:
		PlayerState.IDLE:   _play_anim("idle")
		PlayerState.RUN:    _play_anim("walk" if current_speed == walk_speed else "run")
		PlayerState.JUMP:   _play_anim("jump")
		PlayerState.FALL:   _play_anim("fall")
		PlayerState.ATTACK: pass   # use_skill() drives attack animation
		PlayerState.DEAD:   _play_anim("die")

# Kept for any external callers that still reference _attack() directly.
func _attack() -> void:
	use_skill(0)

# ── Adaptive system — tick + organic unlocks + ability mutations ──────────
func _setup_skill_tree() -> void:
	# Register all Eldoria skills with the SkillTree singleton.
	# Static slots (level-gated) and dynamic (playstyle-driven) both live here
	# so the full unlock picture is in one place instead of scattered across files.
	SkillTree.register_batch({
		# ── Combat ability slots (static, level-gated) ────────────────────────
		"slash": {
			"name": "Slash", "slot": 0, "level": 1,
			"description": "Basic melee combo.",
		},
		"heavy_strike": {
			"name": "Heavy Strike", "slot": 1, "level": 3,
			"description": "Slow powerful blow.",
		},
		"dash_attack": {
			"name": "Dash Attack", "slot": 2, "level": 5,
			"description": "Dash forward and sweep.",
		},
		"fireball": {
			"name": "Fireball", "slot": 3, "level": 7,
			"description": "Lobbed fire projectile with AoE.",
		},
		# ── Dynamic unlocks (playstyle-driven, bypass level gate) ─────────────
		"fireball_early": {
			"name": "Aerial Intuition", "slot": 3, "dynamic": true,
			"ratio_key": "airborne", "ratio_threshold": 0.22,
			"description": "Aerial mastery unlocks Fireball before Lv.7.",
			"effect": func(p: Node) -> void:
				if p and not 3 in p._early_unlocks:
					p._early_unlocks.append(3)
					p._show_mutation_popup("🔥 Aerial mastery — Fireball unlocked early!"),
		},
		"heavy_early": {
			"name": "Battle Hardening", "slot": 1, "dynamic": true,
			"raw_key": "aggressive", "raw_threshold": 40,
			"description": "Relentless aggression unlocks Heavy Strike before Lv.3.",
			"effect": func(p: Node) -> void:
				if p and not 1 in p._early_unlocks:
					p._early_unlocks.append(1)
					p._show_mutation_popup("⚔️ Relentless — Heavy Strike unlocked early!"),
		},
		# ── Passive perks (purchased with skill_points on level-up) ──────────
		"hp_boost": {
			"name": "+20 Max HP", "cost": 1, "level": 2,
			"description": "Permanently raise max HP by 20.",
			"effect": func(p: Node) -> void:
				if p: p.max_hp += 20; p.hp = min(p.hp + 20, p.max_hp); p.stats_changed.emit(),
		},
		"crit_boost": {
			"name": "+5% Crit Chance", "cost": 1, "level": 4,
			"description": "More frequent critical strikes.",
			"effect": func(p: Node) -> void:
				if p: p.crit_chance += 0.05,
		},
		"mp_boost": {
			"name": "+10 Max MP", "cost": 1, "level": 3,
			"description": "Larger mana pool for skill spam.",
			"effect": func(p: Node) -> void:
				if p: p.max_mp += 10; p.mp = min(p.mp + 10, p.max_mp); p.stats_changed.emit(),
		},
	})
	# Connect signal so the tree announces unlocks via world toast automatically
	if not SkillTree.skill_unlocked.is_connected(_on_skill_unlocked):
		SkillTree.skill_unlocked.connect(_on_skill_unlocked)

func _on_skill_unlocked(id: String, sk: Dictionary) -> void:
	if sk.get("dynamic", false):
		return  # dynamic skills show their own popup inside the effect callable
	get_tree().call_group("world", "_show_toast", "✦ %s unlocked!" % sk.get("name", id))

func _tick_adapt(delta: float) -> void:
	_adapt_timer += delta
	if _adapt_timer >= ADAPT_INTERVAL:
		_adapt_timer = 0.0
		SkillTree.update_dynamic(self)   # check playstyle-driven unlocks

func _check_ability_mutations(idx: int) -> void:
	# Called after every successful skill use. Routes through GameBrain so
	# mutations persist across sessions and are readable by all systems.
	match idx:
		0:  # Slash → Echo Strike at 50 uses
			if _skill_use_counts[0] == 50 and not GameBrain.has_evolution("slash_multihit"):
				GameBrain.set_evolution("slash_multihit")
				_show_mutation_popup("⚡ Slash evolved: Echo Strike!")
		1:  # Heavy Strike → Armor Break at 30 uses (+40% damage)
			if _skill_use_counts[1] == 30 and not GameBrain.has_evolution("heavy_armor_break"):
				GameBrain.set_evolution("heavy_armor_break")
				_show_mutation_popup("⚡ Heavy Strike evolved: Armor Break!")
		2:  # Dash Attack → (reserved for future mutation)
			pass
		3:  # Fireball → Inferno Spread at 25 uses
			if _skill_use_counts[3] == 25 and not GameBrain.has_evolution("fireball_pyro"):
				GameBrain.set_evolution("fireball_pyro")
				_show_mutation_popup("⚡ Fireball evolved: Inferno Spread!")

func _show_mutation_popup(text: String) -> void:
	# Big centred popup — bigger than a toast, smaller than a death screen.
	# Uses UITheme.spawn_damage_popup so it floats up and fades automatically.
	UITheme.spawn_damage_popup(
		get_tree().current_scene,
		global_position + Vector3(0, 3.2, 0),
		text,
		Color(1.0, 0.85, 0.25),   # warm gold — feels like a level-up moment
		44, 6
	)
	get_tree().call_group("world", "_show_toast", text)

func _echo_strike_secondary(base_dmg: int) -> void:
	# Echo Strike mutation: second arc fires 0.14s after the primary slash.
	# Uses the same range/arc as Slash (idx 0) at 50% damage so it hits
	# whatever was already in the swing cone — no aiming required.
	await get_tree().create_timer(0.14).timeout
	if is_dead:
		return
	var echo_dmg   := int(float(base_dmg) * 0.50)
	var eff_range  := attack_range + float(SKILLS[0]["range_bonus"])
	var eff_arc    := attack_arc_deg + float(SKILLS[0]["arc_bonus"])
	var arc_rad    := deg_to_rad(eff_arc) * 0.5
	var fwd        := -global_transform.basis.z
	fwd.y = 0; fwd = fwd.normalized()
	var secondary_hits := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_e: Vector3 = enemy.global_position - global_position
		to_e.y = 0
		if to_e.length() <= eff_range and fwd.angle_to(to_e.normalized()) <= arc_rad:
			if enemy.has_method("take_damage"):
				enemy.take_damage(echo_dmg, self)
				secondary_hits += 1
	if secondary_hits > 0 and is_instance_valid(Juice):
		Juice.hit_stop(0.03)   # light echo-stop so the resonance is felt

func _inferno_spread_extra(base_dmg: int) -> void:
	# Inferno Spread mutation: two flanking fireballs branch off ±22°
	# from the main fireball's path at 75% damage each, fired 0.18s later
	# so they visually chase the primary ball.
	await get_tree().create_timer(0.18).timeout
	if is_dead:
		return
	var spread_dmg := int(float(base_dmg) * 0.75)
	var base_dir   := -global_transform.basis.z
	base_dir.y = 0; base_dir = base_dir.normalized()
	for angle_deg: float in [-22.0, 22.0]:
		var spread_dir: Vector3 = base_dir.rotated(Vector3.UP, deg_to_rad(angle_deg))
		var fb := Area3D.new()
		fb.set_script(FIREBALL_SCRIPT)
		fb.position = global_position + Vector3(0, 1.0, 0)  # guard: was global_position (orphan crash fix)
		get_tree().current_scene.add_child(fb)
		fb.launch(spread_dir, spread_dmg, self)

func _roll_damage() -> Dictionary:
	var base := attack_damage_base + int(level * 1.5)
	# Add weapon bonus damage
	if inventory:
		base += inventory.bonus_damage()
	var variance: int = randi_range(-2, 4)
	var amount: int = max(1, base + variance)
	var current_crit_chance: float = crit_chance
	if inventory:
		current_crit_chance += inventory.bonus_crit()
	var crit: bool = randf() < current_crit_chance
	if crit:
		amount = int(amount * crit_multiplier)
	return {"amount": amount, "is_crit": crit}

func _spawn_crit_flash() -> void:
	# A quick screen-edge flash via a Label3D popup at the player
	var crit := Label3D.new()
	crit.set_script(DAMAGE_NUMBER_SCRIPT)
	crit.text = "CRIT!"
	crit.font_size = 48
	crit.outline_size = 6
	crit.outline_modulate = Color(0, 0, 0)
	crit.modulate = Color(1.0, 0.85, 0.20)
	crit.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	crit.no_depth_test = true
	crit.position = global_position + Vector3(0, 2.6, 0)
	get_tree().current_scene.add_child(crit)

func _play_anim(name: String) -> void:
	if not animation_player:
		return
	# Class library prefix — animations loaded from humanoid_CLASSNAME.tres live in
	# a named library "cls" so they're referenced as "cls/slot_name".
	# Falls back gracefully if the library wasn't built/available.
	var cp := "cls/"   # class library prefix
	var candidates := {
		"idle":     [cp+"idle", "Idle", "idle", "ANIM_idle", "humanoid/Idle", "humanoid/idle"],
		"walk":     [cp+"walk", "Walk", "walk", "Walking", "ANIM_walk", "humanoid/Walk", "humanoid/walk"],
		"run":      [cp+"run", "Run", "run", "Running", "ANIM_run", "humanoid/Run", "humanoid/run"],
		"jump":     [cp+"jump", "Jump", "jump", "JumpUp", "humanoid/Jump", "run", "Run"],
		"fall":     [cp+"fall", "Fall", "fall", "Falling", "humanoid/Fall", "idle", "Idle"],
		"land":     [cp+"hard_landing", "Land", "land", "Landing", "humanoid/Land", "idle", "Idle"],
		"attack":   [cp+"attack_1", "Attack", "Punch", "Slash", "humanoid/Attack"],
		"attack_1": [cp+"attack_1", "Attack1", "attack_1", "Slash1", "Attack", "attack", "humanoid/Attack"],
		"attack_2": [cp+"attack_2", "Attack2", "attack_2", "Slash2", "Punch", "Attack", "humanoid/Attack"],
		"attack_3": [cp+"attack_3", "Attack3", "attack_3", "Slash3", "Spin", "Attack", "humanoid/Attack"],
		"die":      [cp+"die", "Death", "Die", "ANIM_death", "humanoid/Death"],
		"dodge":    [cp+"dodge", cp+"roll", "dodge", "roll", "Dodge", "Roll"],
		"roll":     [cp+"roll", cp+"dodge", "roll", "dodge"],
		"block":    [cp+"block", "block", "Block", "humanoid/idle", "idle"],
		"sneak":    [cp+"sneak_idle", cp+"sneak_left", "crouch", "Crouch", "idle", "Idle"],
		"draw":     [cp+"draw_sword", cp+"bow_equip", "Draw", "draw", "idle"],
		"bow_draw": [cp+"bow_draw", cp+"attack_1", "Draw", "draw"],
		"roar":     [cp+"roar", cp+"flex", cp+"power_up", "Attack", "attack"],
		"victory":  ["humanoid/victory", "victory", "Victory", cp+"idle", "idle"],
		"wave":     ["humanoid/wave", "wave", "Wave", cp+"idle", "idle"],
	}
	var possible = candidates.get(name, [cp + name, name])
	for c in possible:
		if animation_player.has_animation(c):
			if animation_player.current_animation != c:
				animation_player.play(c)
			return

# ────────────────────────────────────────────────────────────────────────
# Damage / death / respawn
# ────────────────────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if source != null:
		_last_attacker = source
	if is_dead:
		return
	# Armor reduction (formula: armor / (armor + 50))
	var armor_value: int = 0
	if inventory:
		armor_value = inventory.bonus_armor()
	var reduction: float = float(armor_value) / float(armor_value + 50)
	var actual: int = max(1, int(amount * (1.0 - reduction)))
	hp = max(0, hp - actual)
	stats_changed.emit()
	get_tree().call_group("world", "play_sfx", "damage_taken")
	# Track defensive playstyle — enemies and bosses use this to detect passive
	# or tanky players and tighten their pressure accordingly.
	GameBrain.record_action("defensive")
	# Juice feedback — screen reddens proportionally to hit weight
	if is_instance_valid(Juice):
		var red_alpha: float = clampf(float(actual) / 40.0, 0.05, 0.30)
		Juice.screen_flash(Color(1.0, 0.10, 0.10, red_alpha), 0.18)
	# Damage number above player
	var dn := Label3D.new()
	dn.set_script(DAMAGE_NUMBER_SCRIPT)
	dn.text = "-%d" % actual
	# REFINE: combat-feel — hit weight readable at a glance: light/medium/heavy each
	# have distinct size, color, and spawn height. Deepens run-28 HP-bar coloring
	# into the moment-of-impact feedback loop. THEME §12: temporal motion cues.
	if actual <= 5:
		# Light graze — muted dusty-rose, small, low spawn
		dn.font_size = 30
		dn.outline_size = 4
		dn.modulate = Color(0.92, 0.52, 0.52)
		dn.position = global_position + Vector3(0, 2.2, 0)
	elif actual <= 13:
		# Medium hit — warm red, readable size, standard height
		dn.font_size = 40
		dn.outline_size = 5
		dn.modulate = Color(1.0, 0.28, 0.22)
		dn.position = global_position + Vector3(0, 2.4, 0)
	else:
		# Heavy blow — deep crimson, large, high spawn for max airtime
		dn.font_size = 54
		dn.outline_size = 7
		dn.modulate = Color(1.0, 0.10, 0.06)
		dn.position = global_position + Vector3(0, 2.8, 0)
	dn.outline_modulate = Color(0, 0, 0)
	dn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dn.no_depth_test = true
	get_tree().current_scene.add_child(dn)
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	_play_anim("die")
	call_deferred("save_game")  # save just before respawn
	get_tree().call_group("world", "play_sfx", "player_death")
	# ── EventBus broadcast ────────────────────────────────────────────────────
	if is_instance_valid(EventBus):
		EventBus.player_died.emit(self)
	# ── Nemesis + narrative hooks ─────────────────────────────────────────────
	if is_instance_valid(NemesisSystem) and is_instance_valid(_last_attacker):
		NemesisSystem.on_player_killed_by(_last_attacker)
	if is_instance_valid(NarrativeSystem):
		var attacker_data := {}
		if is_instance_valid(_last_attacker):
			attacker_data["attacker"] = _last_attacker
		NarrativeSystem.record_event("player_died", attacker_data)
	# Death overlay
	get_tree().call_group("world", "show_death_overlay")
	await get_tree().create_timer(2.5).timeout
	_respawn_at_well()

func _respawn_at_well() -> void:
	teleport_to_safe_spawn()
	hp = max_hp
	mp = max_mp
	is_dead = false
	stats_changed.emit()
	get_tree().call_group("world", "hide_death_overlay")
	# Clear any lingering danger tint on respawn
	if is_instance_valid(Juice):
		Juice.clear_ambient_tint()

# ── World-feel environmental feedback ─────────────────────────────────────

func _apply_world_feel() -> void:
	if not is_instance_valid(Juice):
		return
	var hp_ratio: float = float(hp) / float(max_hp)
	var corruption: float = WorldState.corruption_level if is_instance_valid(WorldState) else 0.0

	# Low HP → red danger tint (fades in below 35%)
	if hp_ratio < 0.35:
		var danger := clampf((0.35 - hp_ratio) / 0.35, 0.0, 1.0)
		Juice.set_ambient_tint(Color(1.0, 0.05, 0.05, danger * 0.22))
	elif hp_ratio >= 0.50:
		# Back to safe — clear tint
		Juice.clear_ambient_tint(0.8)

	# High corruption → passive micro-shake (world itself trembles)
	if corruption > 0.65:
		var shake_amt := (corruption - 0.65) / 0.35 * 0.04   # 0 → 0.04 max
		Juice.screen_shake(shake_amt, 0.6)

	# Critical corruption (>0.85) → sickly green tint overrides danger red
	if corruption > 0.85:
		Juice.set_ambient_tint(Color(0.20, 0.50, 0.10, 0.18))

func set_cinematic_lock(locked: bool) -> void:
	cinematic_lock = locked

# ────────────────────────────────────────────────────────────────────────
# Quest hooks (called by Enemy via group)
# ────────────────────────────────────────────────────────────────────────
func on_enemy_killed(kind: String) -> void:
	kills_by_kind[kind] = kills_by_kind.get(kind, 0) + 1
	if active_quest.size() > 0 and active_quest.get("kind", "kill") == "kill" and active_quest.get("target", "") == kind:
		active_quest["killed"] = active_quest.get("killed", 0) + 1
		stats_changed.emit()
		# Notify world of progress
		get_tree().call_group("world", "on_quest_progress", active_quest)

func _on_inventory_changed() -> void:
	# Fetch quests track item counts via the bag
	if active_quest.size() > 0 and active_quest.get("kind", "kill") == "fetch" and inventory:
		var have: int = inventory.count_item(active_quest.get("item", ""))
		active_quest["have"] = have
		stats_changed.emit()
		get_tree().call_group("world", "on_quest_progress", active_quest)

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		# REFINE: balance — HP grant per level-up 18 → 22. At base 120 HP, +18 was
		# +15%/level — readable but thin for Alden (9yo) who reads the HP bar more
		# than the number. +22 = +18%/level: each ding fills the bar noticeably further
		# without breaking the TTK band (goblin 6 dmg → 20+ hits to kill at level 5).
		# Compounds on the existing stat-grant system — no new field, no schema change.
		max_hp += 22
		hp = max_hp
		# REFINE: balance — MP grant per level-up 10 → 14. Base 30 MP is very tight;
		# +10 left level-5 players at 70 MP — one or two spells per fight. +14 reaches
		# 86 MP at level 5, enough for 3–4 skill uses before the fight ends. Encourages
		# Owen (11yo mastery axis) to weave skills rather than hoarding mana.
		max_mp += 14
		mp = max_mp
		skill_points += 1   # one point per level to spend in SkillTree
		get_tree().call_group("world", "play_sfx", "level_up")
		var pop := Label3D.new()
		pop.set_script(DAMAGE_NUMBER_SCRIPT)
		pop.text = "LEVEL UP!"
		pop.font_size = 56
		pop.outline_size = 7
		pop.outline_modulate = Color(0, 0, 0)
		pop.modulate = Color(1.0, 0.85, 0.30)
		pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pop.no_depth_test = true
		pop.position = global_position + Vector3(0, 3.0, 0)
		get_tree().current_scene.add_child(pop)
		# REFINE: balance — stat-delta popup. THEME §12 MOTION & LIFE: the LEVEL UP
		# shout already fires but kids never SEE what they gained — the number lives
		# silently in the stats panel. A second floater speaks the grant: "+22 HP +14 MP"
		# spawns 0.35s after the main pop, offset slightly right so they don't overlap.
		# Reuses DAMAGE_NUMBER_SCRIPT (same billboard/fade pipeline). Zero new nodes
		# or scene edits — purely deepens what gain_xp() already does.
		var stat_pop := Label3D.new()
		stat_pop.set_script(DAMAGE_NUMBER_SCRIPT)
		stat_pop.text = "+%d HP  +%d MP" % [22, 14]
		stat_pop.font_size = 28
		stat_pop.outline_size = 5
		stat_pop.outline_modulate = Color(0, 0, 0)
		stat_pop.modulate = Color(0.55, 0.95, 0.65)
		stat_pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stat_pop.no_depth_test = true
		stat_pop.position = global_position + Vector3(0.6, 2.5, 0)
		get_tree().current_scene.add_child(stat_pop)
	if level > 1:
		call_deferred("save_game")
	stats_changed.emit()

func xp_for_next_level() -> int:
	# REFINE: balance — eased curve (100→85, level*60→*55, level²*8→*7).
	# Cuts ~12% off every gate so the first 4 level-ups arrive faster and a
	# 30-mixed-kill grind reliably lands at level 3-4. Late-game still scales
	# (quadratic term preserved, just gentler).
	return 85 + level * 55 + level * level * 7

func accept_quest(quest: Dictionary) -> void:
	active_quest = quest.duplicate()
	if not active_quest.has("kind"):
		active_quest["kind"] = "kill"
	if active_quest.kind == "kill" and not active_quest.has("killed"):
		active_quest["killed"] = 0
	if active_quest.kind == "fetch":
		# Initialize current count from bag
		var have := 0
		if inventory:
			have = inventory.count_item(active_quest.get("item", ""))
		active_quest["have"] = have
	stats_changed.emit()
	get_tree().call_group("world", "on_quest_accepted", active_quest)

func is_quest_ready_to_turn_in() -> bool:
	if active_quest.size() == 0:
		return false
	match active_quest.get("kind", "kill"):
		"kill":
			return active_quest.get("killed", 0) >= active_quest.get("needed", 9999)
		"fetch":
			if inventory == null: return false
			return inventory.count_item(active_quest.get("item", "")) >= active_quest.get("needed", 9999)
	return false

func complete_quest_if_done() -> bool:
	if not is_quest_ready_to_turn_in():
		return false
	# Consume fetch items
	if active_quest.get("kind", "kill") == "fetch" and inventory:
		inventory.consume_item(active_quest.get("item", ""), active_quest.get("needed", 0))
	# Reward
	gold += active_quest.get("gold_reward", 50)
	gain_xp(active_quest.get("xp_reward", 60))
	# If a follow-up reward item is specified, hand it over
	if active_quest.has("reward_item") and inventory:
		inventory.add_item(active_quest.reward_item, active_quest.get("reward_item_qty", 1))
	active_quest = {}
	stats_changed.emit()
	call_deferred("save_game")  # save on quest completion
	return true

# ────────────────────────────────────────────────────────────────────────
# Visible gear — rebuild the weapon mesh in the player's right hand area
# whenever equipment changes. This is a positional approximation (not bone-
# attached) so it works on any GLB without needing a known skeleton path.
# ────────────────────────────────────────────────────────────────────────
func _on_equipment_changed() -> void:
	_rebuild_weapon_visual()
	# Update HP/MP caps based on equipment bonuses
	stats_changed.emit()

func _rebuild_weapon_visual() -> void:
	# Procedural sword disabled — needs bone-attachment to new Hero.glb skeleton.
	# TODO: attach a sword GLB to a hand bone via BoneAttachment3D.
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	weapon_visual = null

func _build_sword(blade_color: Color, glow: bool, glow_color: Color = Color(1, 1, 1)) -> void:
	# Hilt
	var hilt := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.04; hcm.bottom_radius = 0.04; hcm.height = 0.2
	hilt.mesh = hcm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.30, 0.18, 0.10)
	hm.roughness = 0.9
	hilt.material_override = hm
	weapon_visual.add_child(hilt)
	# Crossguard
	var cg := MeshInstance3D.new()
	var cgm := BoxMesh.new()
	cgm.size = Vector3(0.20, 0.04, 0.04)
	cg.mesh = cgm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.85, 0.65, 0.20)
	cmat.metallic = 0.7
	cmat.roughness = 0.3
	cg.material_override = cmat
	cg.position.y = 0.13
	weapon_visual.add_child(cg)
	# Blade
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.65, 0.015)
	blade.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = blade_color
	bmat.metallic = 0.85
	bmat.roughness = 0.15
	if glow:
		bmat.emission_enabled = true
		bmat.emission = glow_color
		bmat.emission_energy_multiplier = 0.9
	blade.material_override = bmat
	blade.position.y = 0.45
	weapon_visual.add_child(blade)
	# Pommel
	var pom := MeshInstance3D.new()
	var pcm := SphereMesh.new()
	pcm.radius = 0.05; pcm.height = 0.08
	pom.mesh = pcm
	pom.material_override = cmat
	pom.position.y = -0.13
	weapon_visual.add_child(pom)

func _build_axe(blade_color: Color, glow: bool) -> void:
	# Haft
	var haft := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.04; hcm.bottom_radius = 0.05; hcm.height = 0.7
	haft.mesh = hcm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.30, 0.18, 0.10)
	hm.roughness = 0.9
	haft.material_override = hm
	weapon_visual.add_child(haft)
	# Axe head — wedge made of a couple boxes
	var head := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.26, 0.08)
	head.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = blade_color
	bmat.metallic = 0.7
	bmat.roughness = 0.25
	if glow:
		bmat.emission_enabled = true
		bmat.emission = blade_color
		bmat.emission_energy_multiplier = 0.7
	head.material_override = bmat
	head.position = Vector3(0.18, 0.30, 0)
	weapon_visual.add_child(head)

func _build_dagger(blade_color: Color, glow: bool) -> void:
	# Hilt
	var hilt := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.035; hcm.bottom_radius = 0.035; hcm.height = 0.14
	hilt.mesh = hcm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.20, 0.10, 0.05)
	hm.roughness = 0.95
	hilt.material_override = hm
	weapon_visual.add_child(hilt)
	# Blade
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.30, 0.01)
	blade.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = blade_color
	bmat.metallic = 0.9
	bmat.roughness = 0.10
	if glow:
		bmat.emission_enabled = true
		bmat.emission = Color(0.85, 0.30, 1.0)
		bmat.emission_energy_multiplier = 1.4
	blade.material_override = bmat
	blade.position.y = 0.22
	weapon_visual.add_child(blade)

func _quick_use_potion() -> void:
	if not inventory: return
	for i in inventory.bag.size():
		var slot = inventory.bag[i]
		if slot.id.begins_with("hp_potion"):
			inventory.use_item(i, self)
			# Heal popup
			var pop := Label3D.new()
			pop.set_script(DAMAGE_NUMBER_SCRIPT)
			pop.text = "+HEAL"
			pop.font_size = 36
			pop.outline_size = 5
			pop.outline_modulate = Color(0, 0, 0)
			pop.modulate = Color(0.30, 0.95, 0.45)
			pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			pop.no_depth_test = true
			pop.position = global_position + Vector3(0, 2.6, 0)
			get_tree().current_scene.add_child(pop)
			return


# Recursive: walk all descendants until we find an AnimationPlayer.
func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var found := _find_animation_player(c)
		if found:
			return found
	return null

# ── Class animation library ──────────────────────────────────────────────────
# Loads humanoid_CLASSNAME.tres (built by build_anim_library.gd from slot_mapping.json)
# and adds it to the AnimationPlayer under the library name "cls" so every class-
# specific slot is addressable as "cls/slot_name" in _play_anim() candidates.
# Graceful no-op when the .tres hasn't been built yet — _play_anim() falls back
# to the generic animation names that come embedded in the Hero.glb.
func _load_class_anim_library() -> void:
	if not animation_player:
		return
	if player_class.is_empty():
		return
	var lib_path := "res://assets/animations/humanoid_%s.tres" % player_class
	if not ResourceLoader.exists(lib_path):
		return
	var lib := load(lib_path) as AnimationLibrary
	if lib == null:
		return
	if animation_player.has_animation_library("cls"):
		animation_player.remove_animation_library("cls")
	animation_player.add_animation_library("cls", lib)


# ════════════════════════════════════════════════════════════════════════
# SAVE / LOAD — persists to user://eldoria_save.json which Godot Web maps
# to browser localStorage. Survives refresh, tab close, browser restart.
# Saves on: level-up, quest complete, gold/inventory change, every 30s
# Loads on: _ready before any other init
# ════════════════════════════════════════════════════════════════════════

const SAVE_PATH := "user://eldoria_save.json"
var _save_timer: float = 0.0
var _save_interval: float = 30.0  # autosave every 30 seconds
var _loaded_save: bool = false

func _gather_save_data() -> Dictionary:
	var data := {
		"version": 1,
		"saved_at": Time.get_unix_time_from_system(),
		"level": level,
		"xp": xp,
		"hp": hp,
		"max_hp": max_hp,
		"mp": mp,
		"max_mp": max_mp,
		"gold": gold,
		"position": [global_position.x, global_position.y, global_position.z],
		"kills_by_kind": kills_by_kind,
		"active_quest": active_quest,
		"is_dead": is_dead,
	}
	# Inventory state
	if inventory:
		data["inventory_bag"] = inventory.bag.duplicate(true)
		data["inventory_equipped"] = inventory.equipped.duplicate(true)
	return data

func _apply_save_data(data: Dictionary) -> void:
	level = data.get("level", 1)
	xp = data.get("xp", 0)
	max_hp = data.get("max_hp", 120)
	hp = clamp(data.get("hp", max_hp), 1, max_hp)  # can't load dead
	max_mp = data.get("max_mp", 30)
	mp = clamp(data.get("mp", max_mp), 0, max_mp)
	gold = data.get("gold", 50)
	# NOTE: deliberately do NOT restore position — saves can put the player
	# inside terrain or a tree if the world layout changes. Always spawn at
	# the scene's default spawn point.
	kills_by_kind = data.get("kills_by_kind", {})
	active_quest = data.get("active_quest", {})
	# Inventory
	if inventory:
		var bag = data.get("inventory_bag", [])
		var equipped = data.get("inventory_equipped", {})
		if bag is Array:
			inventory.bag = bag.duplicate(true)
		if equipped is Dictionary:
			inventory.equipped = equipped.duplicate(true)
		inventory.inventory_changed.emit()
		inventory.equipment_changed.emit()
	is_dead = false  # never load dead — auto-revive on respawn
	is_attacking = false
	mounted = false
	mount_node = null
	velocity = Vector3.ZERO
	stats_changed.emit()
	_loaded_save = true

func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		push_warning("[Save] could not open " + SAVE_PATH + " for write")
		return false
	f.store_string(JSON.stringify(_gather_save_data(), "	"))
	f.close()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false  # first run, no save yet
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var raw := f.get_as_text()
	f.close()
	var data = JSON.parse_string(raw)
	if not (data is Dictionary):
		push_warning("[Load] save file corrupted, starting fresh")
		return false
	_apply_save_data(data)
	return true

# Title setter — called by World._apply_title_to_player when an
# achievement unlocks a higher-priority title. Empty string hides.
# Safe to call before _ready (no-op until title_label exists).
func set_title(t: String) -> void:
	if title_label == null:
		return
	title_label.text = t
	title_label.visible = (t != "")

func _is_under_bone_attachment(n: Node) -> bool:
	var p := n.get_parent()
	while p and p != self:
		if p is BoneAttachment3D:
			return true
		p = p.get_parent()
	return false

# ────────────────────────────────────────────────────────────────────────
# Char-spec 2026-05-08: Player model height normalization — SIZE_STANDARDS.md §1
# _normalize_player_model(target_height): measures the body-mesh AABB (excluding
#   BoneAttachment3D gear subtrees) and corrects the root model's scale so the
#   visible height ≈ target_height. LOCKED: target_height = 1.10m.
# _force_hero_height_cap(cap): hard ceiling applied after all retries — clamps
#   to cap (1.30m §1 hard cap) if bone-rest AABB underestimates live skin AABB.
# NEVER CHANGE these values without [CANON-APPROVED: reason] in commit message.
# ────────────────────────────────────────────────────────────────────────
func _normalize_player_model(target_height: float) -> void:
	await get_tree().process_frame
	# Pre-reset: if model child is at a wildly large scale (GLB in cm units),
	# bring it to (1,1,1) first so the AABB measurement reflects true unit size.
	for c in get_children():
		if c is BoneAttachment3D: continue
		if c.find_children("*", "VisualInstance3D", true, false).size() > 0:
			var cs: Vector3 = (c as Node3D).scale
			if cs.x > 5.0 or cs.x < 0.01:
				c.scale = Vector3.ONE
			break
	var aabb := AABB()
	var has: bool = false
	for c in find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		# Skip gear on BoneAttachment3D subtrees — measure body mesh only.
		if _is_under_bone_attachment(v): continue
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	var correction: float = clamp(target_height / aabb.size.y, 0.001, 100.0)
	for c in get_children():
		if c is BoneAttachment3D: continue
		if c.find_children("*", "VisualInstance3D", true, false).size() > 0:
			c.scale = c.scale * Vector3(correction, correction, correction)
			break

func _force_hero_height_cap(cap: float) -> void:
	# Hard ceiling: shrink if live-skin AABB still exceeds cap after normalization.
	# cap = 1.30m = SIZE_STANDARDS.md §1 hard cap for kid Player.
	await get_tree().process_frame
	var aabb := AABB()
	var has: bool = false
	for c in find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		if _is_under_bone_attachment(v): continue
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	if aabb.size.y > cap:
		var shrink: float = cap / aabb.size.y
		for c in get_children():
			if c is BoneAttachment3D: continue
			if c.find_children("*", "VisualInstance3D", true, false).size() > 0:
				c.scale = c.scale * Vector3(shrink, shrink, shrink)
				break

func reset_save() -> void:
	# For "New Game" button later
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
