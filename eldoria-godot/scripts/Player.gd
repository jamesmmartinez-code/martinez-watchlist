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

# RIGGING_STANDARD §Required animations — every humanoid loads this shared
# library so _play_anim("humanoid/<slot>") works regardless of what the
# source GLB happened to ship with. Built by scripts/dev/build_anim_library.gd
# from Mixamo packs in assets/animations/source/. Missing file = graceful
# no-op (we fall back to the candidates dict in _play_anim like before).
const HUMANOID_BASE_LIB := "res://assets/animations/humanoid_base.tres"


var gravity: float = 20.0
var current_speed: float
var is_attacking: bool = false
var is_dead: bool = false
# Stuck-recovery timers (kids need this to never feel locked out)
var _attack_timeout: float = 0.0
var _dead_timer: float = 0.0
var _jam_timer: float = 0.0
var _input_log_t: float = 0.0  # PX: throttle input-state log

# Stats
var hp: int = 120
var max_hp: int = 120
var mp: int = 30
var max_mp: int = 30
var xp: int = 0
var level: int = 1
var gold: int = 50

# Combat parameters
# REFINE: combat-feel — attack_range 2.6 → 2.7 (+0.1m). Alden's "I was a fingertip away" frustration valve. Still well under a typical 3.0m sword reach so Owen's positioning still matters.
@export var attack_range: float = 2.7
# REFINE: combat-feel — attack_arc_deg 110.0 → 118.0 (+8°). Slightly wider forgiveness cone for Alden's imprecise aim. Owen still picks his target; this only saves wide-angle near-miss frames.
@export var attack_arc_deg: float = 118.0
@export var attack_damage_base: int = 14
# REFINE: combat-feel — crit_chance 0.12 → 0.14 (+2pp). One extra crit every ~5 minutes for Owen's mastery affinity; small enough Alden's HP economy is unchanged. THEME §3 sunset-gold accent already paints the CRIT! flash.
@export var crit_chance: float = 0.14
# REFINE: combat-feel — crit_multiplier 2.0 → 2.15 (+7.5%). Chunkier crit punch reads as "I earned that one" without breaking the kid-friendly damage band. Mirror of the Enemy.gd damage-number polish on the player-output side.
@export var crit_multiplier: float = 2.15

# Inventory + equipment (managed by Inventory child node)
var inventory: Node = null

# Quest tracking
var kills_by_kind: Dictionary = {}   # e.g. {"goblin": 3}
var active_quest: Dictionary = {}    # {"target":"goblin", "needed":5, "killed":0, "giver":"Maeve"}

# Mounted state
var mounted: bool = false
var mount_node: Node3D = null

const INVENTORY_SCRIPT    = preload("res://scripts/Inventory.gd")

# Visible weapon attached to the player's body (re-built when equipment changes)
var weapon_visual: Node3D = null

# Equipment Visualizer agent — multi-slot gear visuals.
# Keyed by slot name (right_hand, left_hand, head, chest_back, hip). The
# right_hand entry mirrors `weapon_visual` for backwards-compat. Each value
# is a Node3D parented under the matching BoneAttachment3D; rebuilt whenever
# Inventory.equipment_changed fires. See assets/gear/README.md.
var gear_visuals: Dictionary = {}

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
	# PX hardening 2026-05-05: run input handler even if World pauses or scene gets paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_speed = walk_speed
	add_to_group("player")
	# Character Select 2026-05-05: if the kid picked a non-default hero, swap the
	# Hero subtree with their pick BEFORE _normalize_player_model fires. The
	# choice was stashed by CharacterSelect.gd in Engine meta.
	call_deferred("_apply_character_choice")
	# PX 2026-05-05: force initial spawn (scene file may have player at village center)
	call_deferred("set", "global_position", Vector3(15, 3, 15))  # PX initial spawn override
	add_to_group("quest_listeners")
	collision_layer = 2  # player layer
	collision_mask = 1 | 4  # collide with world (1) and enemies (4)
	# PX hardening 2026-05-06 (CHECK 10 from eldoria-physics-engineer):
	# CharacterBody3D defaults leave floor_snap_length = 0.0, which makes the
	# kid characters bounce/lift off stairs and small terrain bumps — losing
	# ground contact reads as "I can't move!!" because is_on_floor() flickers
	# and gravity pumps velocity.y mid-stride. Fixes:
	#   - floor_snap_length 0.35 keeps feet glued through 0.35m descents
	#     (covers village stair risers + cobble-path lip without trapping)
	#   - floor_max_angle 46° (≈ deg_to_rad) blocks scaling steep cliffs but
	#     leaves gentle ramps climbable — matches THEME §13 ground-contact rule
	#   - up_direction is explicit Vector3.UP (default, but explicit = lockable)
	# These are CharacterBody3D core movement params; setting once in _ready
	# is sufficient (engine doesn't reset them).
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(46.0)
	up_direction = Vector3.UP
	# Auto-wire camera_pivot if the editor didn't assign it
	if not camera_pivot:
		var root := get_tree().current_scene
		if root:
			camera_pivot = root.get_node_or_null("CameraPivot")
	# Auto-wire animation_player — search any child for an AnimationPlayer.
	# Works regardless of model name (Hero, Soldier, CesiumMan, etc.).
	if not animation_player:
		animation_player = _find_animation_player(self)
	# Merge the shared humanoid AnimationLibrary into the AnimationPlayer
	# the model came with. After this, _play_anim() can resolve
	# "humanoid/idle" / "humanoid/walk" / "humanoid/attack_1" etc. on
	# every character — even Trainer / NPCs whose source GLB shipped with
	# only one anim. Per RIGGING_STANDARD: bones must match mixamorig:*.
	if animation_player:
		_merge_humanoid_library(animation_player)
	# THEME §13 ground contact + size discipline — Owen.glb / hero_lange.glb are
	# Meshy/Sketchfab exports at native units (often cm), so they spawn 3-4×
	# normal size if not normalized. Walks the visible AABB and uniformly
	# scales the Hero subtree to ~1.8m, then lifts so feet sit at body-local
	# y=0. Mirrors the Enemy.gd / Boss.gd pattern. No-op if the model is
	# already in the right range.
	call_deferred("_normalize_player_model", 1.1)
	# Repeat at 0.5/1.5/3s — Meshy biped finishes loading skinning data over multiple frames,
	# so a single deferred call sometimes catches the model before the AABB stabilizes.
	_schedule_normalize_retry(0.5)
	_schedule_normalize_retry(1.5)
	_schedule_normalize_retry(3.0)
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
	# REFINE: visual — title_label pixel_size 0.0035 → 0.0040 lifts billboard size for at-distance readability at the camera-polish-run wider rest frame (default cam dist 8.0m). +14% billboard area helps Alden read his earned title from the back of the room without enlarging the underlying font (font_size lifts separately).
	title_label.pixel_size = 0.0040
	# REFINE: visual — modulate B channel 0.40 → 0.42 = exact §3 #FFD86B sunset-gold. Same drift the recent UITheme polish run fixed on its GOLD const, the WorldMap polish run fixed on COL_TITLE, and the Chest.gd polish run already had on glow_color. Title now reads in the same gold as every other §3 'this matters' beat in the project (NPC nameplates, achievement toasts, level-up popup).
	title_label.modulate = Color(1.0, 0.85, 0.42)        # palette §3 sunset-gold (#FFD86B exact)
	title_label.outline_modulate = Color(0, 0, 0, 1)
	# REFINE: visual — outline_size 8 → 7 matches the UITheme polish run's OL_TOAST 7 convention (the §3-bloom-era outline weight that title-tier text converged on). 8 was authored before the recent post-processing pass lifted background luminance; 7 reads cleaner on the new bright sky-band without losing legibility against grass.
	title_label.outline_size = 7
	# REFINE: visual — font_size 28 → 30 matches the boss Label3D font_size 30 — title and boss-tag now share the same painterly weight tier. +2pt makes the player's earned title readable from camera dist 8.0m (camera polish run authored). Owen's mastery-affinity title beat (Warden of Eldoria, Goblin-Bane) now reads at the same scale as the boss it was earned against.
	title_label.font_size = 30
	add_child(title_label)
	# THEME §12: tiny Y-bob so the label breathes. Amplitude 0.04m, period 2.5s.
	# REFINE: visual — period 3.0s → 2.5s syncs the title bob with the THEME §12 canonical breathing cadence (the procedural-Y-bob spec) — matches the Minimap polish run's 2.5 rad/s player pulse, the WorldMap pulse rate slowdown to 2.6 rad/s, the camera follow smooth_lerp rhythm, and the body-bob period §12 calls for. Amplitude 0.06m (2.40↔2.46) → 0.04m (2.40↔2.44) brings the title closer to §12 spec amplitude (0.02m for body) while staying visible at billboard scale. Cross-system rhythm: five surfaces (player title, body bob, minimap, worldmap, camera) now beat on the same painterly heartbeat instead of four-against-one.
	var bob: Tween = create_tween().set_loops()
	bob.tween_property(title_label, "position:y", 2.44, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(title_label, "position:y", 2.4, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Inventory
	inventory = Node.new()
	inventory.set_script(INVENTORY_SCRIPT)
	inventory.name = "Inventory"
	add_child(inventory)
	inventory.equipment_changed.connect(_on_equipment_changed)
	inventory.inventory_changed.connect(_on_inventory_changed)
	# Equipment Visualizer (Pillar 1 — Combat) — granular per-slot signals
	# let us do partial rebuilds (swap helmet without re-instancing the sword).
	# The aggregate equipment_changed connection above stays wired for any
	# code that needs a full refresh; these route to slot-specific rebuilders.
	inventory.item_equipped.connect(_on_item_equipped)
	inventory.item_unequipped.connect(_on_item_unequipped)
	# Build initial visible weapon
	call_deferred("_rebuild_weapon_visual")
	# Load save on first frame (after inventory wires up)
	call_deferred("load_game")

func _physics_process(delta: float) -> void:
	var __forced_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    __forced_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  __forced_dir.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  __forced_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): __forced_dir.x += 1.0
	if __forced_dir.length() > 0.05:
		var basis := global_transform.basis
		if camera_pivot and is_instance_valid(camera_pivot):
			basis = camera_pivot.global_transform.basis
		var fwd := -basis.z; fwd.y = 0; fwd = fwd.normalized()
		var rgt := basis.x;  rgt.y = 0; rgt = rgt.normalized()
		var move_dir := (rgt * __forced_dir.x + fwd * __forced_dir.z).normalized()
		var spd: float = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		if move_dir.length_squared() > 0.0001:
			var yaw := atan2(move_dir.x, move_dir.z)
			rotation.y = lerp_angle(rotation.y, yaw, clamp(rotation_speed * delta, 0.0, 1.0))
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
	else:
		velocity.y = 0.0
	move_and_slide()
	# Belt-and-suspenders ground snap — runs every 4th frame to keep cost low.
	# Only snaps when the body is >0.6m above terrain (i.e. visibly floating).
	_input_log_t += delta
	if int(_input_log_t * 60.0) % 8 == 0:
		_snap_to_ground(6.0)
	if Input.is_key_pressed(KEY_BRACKETRIGHT) or Input.is_key_pressed(KEY_BACKSPACE):
		global_position = Vector3(15, 3, 15)
		velocity = Vector3.ZERO
		is_dead = false
		is_attacking = false
		if hp <= 0: hp = max_hp
		return
	if global_position.y < -50.0 or global_position.y > 500.0:
		global_position = Vector3(15, 3, 15)
		velocity = Vector3.ZERO
		return
	return  # FORCED-MOVE: bypass legacy state machine below
	# Stuck-recovery #1: if we've fallen out of the world or punched through the
	# top, snap back to a safe spawn so the kids never lose control.
	if global_position.y < -50.0 or global_position.y > 500.0:
		global_position = Vector3(15, 3, 15)  # PX SAFE_SPAWN — clear of village
		velocity = Vector3.ZERO

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

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Camera-relative input
	# Primary input via action map
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# PX 2026-05-05 fallback: if action map didn't fire (input map missing or broken),
	# poll raw keys directly. Saves us if project.godot bindings ever drift.
	if input_dir.length() < 0.01:
		var rx: float = 0.0
		var ry: float = 0.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): rx -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): rx += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): ry -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): ry += 1.0
		if rx != 0.0 or ry != 0.0:
			input_dir = Vector2(rx, ry).normalized()
	# Periodic input-state log (every ~2s @ 60fps) so DevTools shows whether keys are arriving
	_input_log_t += delta
	if _input_log_t > 2.0:
		_input_log_t = 0.0
		print("[Player] input state: dir=", input_dir, " W=", Input.is_physical_key_pressed(KEY_W),
		      " A=", Input.is_physical_key_pressed(KEY_A),
		      " S=", Input.is_physical_key_pressed(KEY_S),
		      " D=", Input.is_physical_key_pressed(KEY_D),
		      " pos=", global_position)
	var cam_basis := camera_pivot.global_transform.basis if camera_pivot else Basis.IDENTITY
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0

	# Run modifier (left shift)
	current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	# Stuck-recovery #4: if input is being pressed but we haven't moved horizontally for >1s,
	# something is jamming us (collision wedge, frozen state). Teleport up 1m and clear velocity.
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if input_dir.length() > 0.1 and horiz_speed < 0.05:
		_jam_timer += delta
		if _jam_timer > 1.0:
			global_position.y += 1.5
			velocity = Vector3.ZERO
			_jam_timer = 0.0
			print("[Player] auto-unstick: teleported up 1.5m")
	else:
		_jam_timer = 0.0

	if direction.length() > 0.01:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)
		_play_anim("walk" if current_speed == walk_speed else "run")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 4 * delta)
		velocity.z = move_toward(velocity.z, 0, current_speed * 4 * delta)
		if not is_attacking:
			_play_anim("idle")

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func _input(event: InputEvent) -> void:
	# ─── PANIC KEYS — fire BEFORE is_dead early-return AND before any other gating ───
	# PX hardening 2026-05-05: kids reported "nothing works when stuck". Root cause:
	#   (a) is_dead early-return below blocked Backspace/F1/F2 if dead-stuck,
	#   (b) UI panels (DialoguePanel, WorldMap, Achievements) with focus could
	#       call accept_event() and silently eat the keys.
	# Fix: handle panic keys at the very top, force-close every UI panel, and
	# also re-handle them in _unhandled_key_input as a belt-and-suspenders.
	if event is InputEventKey and event.pressed and not event.echo:
		var pk: int = event.keycode
		if pk == KEY_BACKSPACE or pk == KEY_F1 or pk == KEY_F2 or pk == KEY_BRACKETRIGHT:
			_panic_unstick(pk)
			return
	if is_dead:
		return
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	if event.is_action_pressed("attack"):
		_attack()
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_I:
			get_tree().call_group("world", "toggle_inventory")
		elif k == KEY_J:
			# Journal / Achievements panel
			get_tree().call_group("world", "toggle_achievements")
		elif k == KEY_Q:
			_quick_use_potion()
		elif k == KEY_N:
			get_tree().call_group("world", "toggle_world_map")
		elif k == KEY_M:
			get_tree().call_group("world", "toggle_mount")

# ─── PANIC KEY HANDLER ──────────────────────────────────────────────────────
# Centralized so we can call it from BOTH _input (high priority) and
# _unhandled_key_input (catches whatever a UI panel didn't handle).
func _panic_unstick(keycode: int) -> void:
	# Force-close every panel that could be stealing focus
	get_tree().call_group("world", "_force_close_all_panels")
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		print("[Player] panic: scene was PAUSED — un-paused")
	if keycode == KEY_BACKSPACE or keycode == KEY_BRACKETRIGHT:
		print("[Player] PANIC (Backspace/']') — full unstick")
		is_dead = false
		is_attacking = false
		mounted = false
		mount_node = null
		velocity = Vector3.ZERO
		global_position = Vector3(15, 3, 15)  # PX SAFE_SPAWN — clear of village
		hp = max(1, hp)
		_attack_timeout = 0.0
		_dead_timer = 0.0
		_jam_timer = 0.0
	elif keycode == KEY_F1:
		print("[Player] PANIC F1 — teleport to spawn")
		velocity = Vector3.ZERO
		global_position = Vector3(15, 3, 15)  # PX SAFE_SPAWN — clear of village
		is_attacking = false
		is_dead = false
		hp = max(1, hp)
	elif keycode == KEY_F2:
		print("[Player] PANIC F2 — wiping save + reload")
		reset_save()
		get_tree().reload_current_scene()

# Belt-and-suspenders: if a focused UI Control swallowed the key,
# _unhandled_key_input still fires after _input + UI had their pass.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k2: int = event.keycode
		if k2 == KEY_BACKSPACE or k2 == KEY_F1 or k2 == KEY_F2 or k2 == KEY_BRACKETRIGHT:
			_panic_unstick(k2)

func _attack() -> void:
	if is_attacking or is_dead:
		return
	is_attacking = true
	_play_anim("attack")
	get_tree().call_group("world", "play_sfx", "sword_swing")

	# Hit window — small delay to match the swing
	# REFINE: combat-feel — hit-window 0.18 → 0.16. Snappier register, closer to swing-peak. Owen's "speed affinity" rung; Alden still has the visible windup.
	await get_tree().create_timer(0.16).timeout

	# Find enemies in front of player within range + arc
	var arc_rad := deg_to_rad(attack_arc_deg) * 0.5
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var hit_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0
		var dist := to_enemy.length()
		if dist > attack_range:
			continue
		if dist < 0.001:
			continue
		var ang := fwd.angle_to(to_enemy.normalized())
		if ang > arc_rad:
			continue
		# Roll for crit
		var dmg: Dictionary = _roll_damage()
		var is_crit: bool = dmg.is_crit
		if enemy.has_method("take_damage"):
			enemy.take_damage(dmg.amount, self)
			get_tree().call_group("world", "play_sfx", "sword_hit")
			# Override the damage number color/style if crit
			if is_crit:
				_spawn_crit_flash()
			hit_count += 1
	# Whiff feedback if nothing hit (nothing to do, just a flat swing)

	# Lockout window for the rest of the swing
	# REFINE: combat-feel — lockout 0.32 → 0.28. Total swing 0.50s → 0.44s. Faster recovery between swings (Owen). Telegraph + register still readable for Alden — the LOCKOUT shrinks, not the WINDUP.
	await get_tree().create_timer(0.28).timeout
	is_attacking = false

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
	# REFINE: combat-feel — crit flash chunkier & warmer. font 48 → 56, outline 6 → 8 reads from camera distance (Alden); modulate (1.0,0.92,0.28) → (1.00,0.85,0.42). The prior run claimed §3 sunset-gold #FFD86B alignment but B=0.28 (≈#47) was still a half-step off the canonical (1.00,0.85,0.42) (= #FFD86B exact) the rest of the project converged on: UITheme.GOLD, Chest.gd glow_color, WorldMap COL_TITLE, NPC nameplate modulate, Player.gd title_label modulate, the LEVEL UP! popup directly above this on line 585, and the Boss.gd crown emission. CRIT! is the loudest mastery-tier flash Owen reads (per PLAYER_MODEL.md — visible mastery, damage numbers); shouldn't be the lone outlier in the §3 'this matters' gold family. Now eight surfaces beat on one painterly hue. THEME §3 palette discipline.
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 2.6, 0), "CRIT!", Color(1.00, 0.85, 0.42), 56, 8)

func _play_anim(name: String) -> void:
	if not animation_player:
		return
	# RIGGING_STANDARD §Required animations: prefer the canonical "humanoid/<slot>"
	# clip from humanoid_base.tres if it was merged in _ready. Falls back to the
	# legacy per-source-GLB candidate names so characters whose GLB was wired
	# pre-library still animate correctly.
	var canonical_map := {
		"idle":    "humanoid/idle",
		"walk":    "humanoid/walk",
		"run":     "humanoid/run",
		"attack":  "humanoid/attack_1",
		"hurt":    "humanoid/hurt",
		"die":     "humanoid/die",
		"victory": "humanoid/victory",
		"wave":    "humanoid/wave",
		"yes":     "humanoid/yes",
		"no":      "humanoid/no",
		"jump":    "humanoid/jump",
	}
	var canonical: String = canonical_map.get(name, "")
	if canonical != "" and animation_player.has_animation(canonical):
		if animation_player.current_animation != canonical:
			animation_player.play(canonical)
		return
	var candidates := {
		"idle":   ["Idle", "idle", "ANIM_idle", "Armature|walking_man|baselayer", "rest"],
		"walk":   ["Walk", "walk", "Walking", "ANIM_walk", "walk_forward"],
		"run":    ["Run", "run", "Running", "ANIM_run", "run_1", "run_fast", "run_forward"],
		"attack": ["Attack", "Punch", "Slash", "attack_1", "attack_2", "attack_3", "Lunge_Spin_Kick", "sword_slash"],
		"die":    ["Death", "Die", "ANIM_death", "die"],
		"hurt":   ["Hurt", "hurt", "React", "react"],
		"victory":["Victory", "victory", "Cheering", "cheer"],
		"wave":   ["Wave", "wave", "Waving"],
		"yes":    ["Yes", "yes", "Nod", "Agree_Gesture"],
		"no":     ["No", "no", "ShakeHead"],
		"jump":   ["Jump", "jump", "Jumping_Up"],
	}
	# Animation Wire 2026-05-05: also fall back to ANY animation matching by
	# substring (case-insensitive) so a Meshy export named "walking" or
	# "Idle_Loop" or whatever still plays. Last-resort match — if none of the
	# explicit candidates hit, try to find one whose name contains the slot name.
	if true:
		var lc := name.to_lower()
		for a in animation_player.get_animation_list():
			if lc in a.to_lower():
				if animation_player.current_animation != a:
					animation_player.play(a)
				return
	var possible = candidates.get(name, [name])
	for c in possible:
		if animation_player.has_animation(c):
			if animation_player.current_animation != c:
				animation_player.play(c)
			return

# ────────────────────────────────────────────────────────────────────────
# Damage / death / respawn
# ────────────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
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
	# Damage number above player
	# REFINE: combat-feel — take_damage popup completes the §3 threat-red family convergence. Color (1.00, 0.32, 0.20) → (1.00, 0.30, 0.10). The prior polish moved candy-red toward stag-blood; this run snaps it onto the canonical threat-red the rest of the boss arena already converged on: BossAura light_color (1.0, 0.30, 0.10), telegraph ring emission (1.0, 0.30, 0.10), telegraph line emission (1.0, 0.30, 0.10), boss nameplate modulate (1.0, 0.30, 0.10), and the _show_boss_msg popup (1.0, 0.30, 0.10) — see Boss.gd:97 family note. With this change the SIXTH "threat is happening" surface joins the same hue: aura + ring + line + nameplate + boss msg + the player's own "-N" hurt-readback. One painterly red beat across the whole danger register — Alden reads "I'm being hit" in the SAME color his eye is already trained on for "telegraph is firing", reinforcing the §12 MOTION cue chain rather than splitting it. Luminance drop is ~4.5% relative (still well-lit on screen); legibility is carried by the chunkier font 36 + outline 6 the prior run pinned, not by the raw color value, so HURT readback stays clean for Alden's low-to-medium combat tolerance. Stays warm and well off the §3 banned-color list, mirrors the Boss.gd:97 convergence pattern (§3 palette discipline + family resonance > per-surface luminance optimization). Sixth surface in, no mechanic added.
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 2.4, 0), "-%d" % actual, Color(1.00, 0.30, 0.10), 36, 6)
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	_play_anim("die")
	call_deferred("save_game")  # save just before respawn
	get_tree().call_group("world", "play_sfx", "player_death")
	# Death overlay
	get_tree().call_group("world", "show_death_overlay")
	await get_tree().create_timer(2.5).timeout
	_respawn_at_well()

func _respawn_at_well() -> void:
	# Well is at (0, 0, 6) per WorldBuilder
	global_position = Vector3(15, 3, 15)  # PX SAFE_SPAWN — was inside well
	hp = max_hp
	mp = max_mp
	is_dead = false
	stats_changed.emit()
	get_tree().call_group("world", "hide_death_overlay")

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
		# REFINE: balance — chunkier per-level HP gain (14 → 18) so Alden has more
		# survivability headroom across a 30-kill session, and Owen's "I just leveled"
		# beat reads as a meaningful step rather than a sliver.
		max_hp += 18
		hp = max_hp
		# REFINE: balance — slightly bigger MP step (8 → 10) so caster-curious play
		# doesn't run dry mid-fight after a few level-ups.
		max_mp += 10
		mp = max_mp
		get_tree().call_group("world", "play_sfx", "level_up")
		# Level-up celebration popup
		# REFINE: visual — LEVEL UP! popup gold pulled to exact §3 #FFD86B. Color (1.0, 0.85, 0.30) was off-palette mustard (B=0.30 ≈ #4D) → (1.00, 0.85, 0.42) (B=0.42 = #6B) now matches UITheme GOLD, title_label modulate, WorldMap COL_TITLE, Chest.gd glow_color, and the NPC nameplate modulate the recent polish runs converged on. Owen's mastery-affinity LEVEL UP! beat now reads in the same sunset-gold as every other §3 'this matters' surface — visual continuity across mastery rungs.
		UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 3.0, 0), "LEVEL UP!", Color(1.00, 0.85, 0.42), 56, 7)
	call_deferred("save_game")  # save after all level-ups (QA: re-fix indent regression from 031f9bb0)
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
	# Equipment Visualizer (Pillar 1 — Combat) — refresh every visible gear
	# slot, not just the right hand. Each rebuilder prefers an authored GLB
	# at assets/gear/<slot>/<item_id>.glb and falls back to legacy procedural
	# primitives ONLY for the right_hand/weapon slot (see README in that dir).
	_rebuild_weapon_visual()
	_rebuild_shield_visual()
	_rebuild_helmet_visual()
	_rebuild_cape_visual()
	call_deferred("_clamp_all_attachments_scale")
	# Update HP/MP caps based on equipment bonuses
	stats_changed.emit()

# Granular per-slot handlers — Inventory.gd emits these alongside the
# aggregate equipment_changed signal. We only re-run the rebuilder for the
# slot that actually changed, which is cheaper than the full refresh and
# avoids briefly de-spawning the sword when the player swaps a helmet.
# Slot strings come from Items.gd::ITEMS[*].slot — keep this dispatch in
# sync if Item Designer adds a new slot type.
func _on_item_equipped(slot: String, _item_id: String) -> void:
	_rebuild_slot(slot)

func _on_item_unequipped(slot: String, _item_id: String) -> void:
	_rebuild_slot(slot)

func _rebuild_slot(slot: String) -> void:
	match slot:
		"weapon":
			_rebuild_weapon_visual()
		"shield":
			_rebuild_shield_visual()
		"helmet":
			_rebuild_helmet_visual()
		"cape":
			_rebuild_cape_visual()
		_:
			# armor / trinket / future slots have no dedicated 3D visual yet
			# (armor is baked into the hero GLB). Stats refresh still flows
			# through the aggregate equipment_changed connection.
			pass
	call_deferred("_clamp_all_attachments_scale")
	stats_changed.emit()

func _rebuild_weapon_visual() -> void:
	# Free any old weapon node — fresh build each equipment_changed.
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	weapon_visual = null
	if inventory == null:
		return
	var weapon_id: String = ""
	if inventory.has_method("equipped_weapon_id"):
		weapon_id = inventory.equipped_weapon_id()
	if weapon_id == "":
		return
	var item: Dictionary = Items.get_item(weapon_id)
	if item.is_empty():
		return

	# THEME §12 — bone-attach the sword to the right-hand bone so it
	# tracks idle / walk / attack animations instead of floating beside
	# the body. Falls back to the legacy body-relative offset if the
	# active player GLB has no skeleton or no recognizable hand bone.
	var attach_parent: Node = self
	var local_origin: Vector3 = Vector3(0.45, 1.05, 0.1)
	var local_rot: Vector3 = Vector3(0, 0, deg_to_rad(35))
	var bone_attach: BoneAttachment3D = _make_right_hand_bone_attachment()
	if bone_attach != null:
		attach_parent = bone_attach
		# Bone-local: hand grip points along the bone's +Y, sword runs
		# down the palm. Tuned values that read correctly on both
		# Owen.glb (Sketchfab "RightHand") and Hero.glb (Mixamo
		# "mixamorigRightHand_021"). Slight forward offset so the
		# hilt doesn't intersect fingers.
		local_origin = Vector3(0.0, 0.04, 0.10)
		local_rot = Vector3(deg_to_rad(90), 0, 0)

	weapon_visual = Node3D.new()
	weapon_visual.name = "WeaponVisual"
	weapon_visual.position = local_origin
	weapon_visual.rotation = local_rot
	attach_parent.add_child(weapon_visual)
	gear_visuals["right_hand"] = weapon_visual

	# Equipment Visualizer — prefer authored GLB at
	# res://assets/gear/right_hand/<weapon_id>.glb. Procedural primitives
	# below are STOP-GAP only (THEME.md flagged) and run only when no asset
	# has shipped yet for this weapon.
	var glb_node: Node3D = _try_load_gear_glb("right_hand", weapon_id)
	if glb_node != null:
		weapon_visual.add_child(glb_node)
		_apply_tier_tint(glb_node, item.get("rarity", "common"))
		return

	var color: Color = item.get("color", Color(0.85, 0.85, 0.85))
	var glow: bool = item.get("rarity", "common") in ["epic", "legendary"]

	# Build a weapon-shape primitive. We dispatch by item_id first (so
	# frost_saber can get a curved blade and dragonfang can get a
	# greatsword silhouette), then fall back to icon-based shape for any
	# weapon Item Designer adds without an explicit shape route. This is
	# all STOP-GAP: the moment assets/gear/right_hand/<id>.glb ships, the
	# loader above intercepts before we ever reach this block.
	#
	# Equipment Visualizer (Pillar 1 — Combat) — varying silhouette by id
	# means even the procedural fallback gives kids a visual cue that
	# their epic/legendary weapon is BIGGER than a common iron sword.
	var icon: String = item.get("icon", "⚔")
	match weapon_id:
		"frost_saber":
			# Saber: longer + curved, frost-cyan glow.
			_build_saber(color, glow, Color(0.55, 0.85, 1.0))
		"dragonfang":
			# Legendary 2H greatsword: oversized, ember-orange glow.
			_build_greatsword(color, true, Color(1.0, 0.55, 0.10))
		"shadow_dagger":
			_build_dagger(color, glow)
		"ember_axe":
			_build_axe(color, glow)
		_:
			# Icon-based dispatch (legacy fallback for unknown ids).
			if icon == "🪓":
				_build_axe(color, glow)
			elif icon == "🗡":
				_build_dagger(color, glow)
			elif icon == "❄":
				_build_saber(color, glow, Color(0.55, 0.85, 1.0))
			elif icon == "🐉":
				_build_greatsword(color, true, Color(1.0, 0.55, 0.10))
			else:
				_build_sword(color, glow)

# ════════════════════════════════════════════════════════════════════════
# Equipment Visualizer — slot-aware GLB loader + tier-tint helper.
# ════════════════════════════════════════════════════════════════════════

# Try to load an authored GLB at res://assets/gear/<slot>/<item_id>.glb.
# Returns an INSTANCED Node3D ready to be parented to a BoneAttachment3D,
# or null if the file doesn't exist. Caller is responsible for parenting +
# applying tier tint.
func _try_load_gear_glb(slot: String, item_id: String) -> Node3D:
	if slot == "" or item_id == "":
		return null
	var path := "res://assets/gear/%s/%s.glb" % [slot, item_id]
	if not ResourceLoader.exists(path):
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var inst: Node = packed.instantiate()
	if inst is Node3D:
		return inst as Node3D
	# GLBs always import as Node3D root; if not, bail safely.
	inst.queue_free()
	return null

# Apply the rarity-tier tint as an albedo modulate on every MeshInstance3D
# under `root`. Lets one base GLB serve common/uncommon/rare/epic/legendary
# variants without shipping five copies of the asset (see README §"Tier
# variants are a runtime tint, not a separate file").
const TIER_TINT := {
	"common":    Color(1.00, 1.00, 1.00),
	"uncommon":  Color(0.75, 1.00, 0.75),
	"rare":      Color(0.70, 0.85, 1.00),
	"epic":      Color(0.95, 0.70, 1.00),
	"legendary": Color(1.00, 0.85, 0.55),
}

func _apply_tier_tint(root: Node, tier: String) -> void:
	if root == null:
		return
	var tint: Color = TIER_TINT.get(tier, Color.WHITE)
	if tint == Color.WHITE:
		return
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			# Don't clobber the source material — wrap it.
			var surf_count: int = 0
			if mi.mesh != null:
				surf_count = mi.mesh.get_surface_count()
			for i in range(surf_count):
				var mat: Material = mi.get_active_material(i)
				var sm: StandardMaterial3D = null
				if mat is StandardMaterial3D:
					sm = (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				else:
					sm = StandardMaterial3D.new()
				sm.albedo_color = sm.albedo_color * tint
				if tier in ["epic", "legendary"]:
					sm.emission_enabled = true
					sm.emission = tint
					sm.emission_energy_multiplier = 0.55 if tier == "epic" else 0.85
				mi.set_surface_override_material(i, sm)
		for c in n.get_children():
			stack.append(c)

# ── Bone attachment helpers for non-weapon slots ────────────────────────
# These mirror _make_right_hand_bone_attachment but target other bones.
# Returns the attachment node parented under the player's Skeleton3D, or
# null if no matching bone was found.
func _make_bone_attachment(att_name: String, candidates: Array) -> BoneAttachment3D:
	var skel: Skeleton3D = _find_first_skeleton(self)
	if skel == null:
		return null
	var bone_idx: int = -1
	for cand in candidates:
		bone_idx = skel.find_bone(cand)
		if bone_idx >= 0:
			break
	# Fuzzy match (Mixamo suffixes "_021" etc.)
	if bone_idx < 0:
		var wanted: Array = []
		for cand in candidates:
			wanted.append(cand.to_lower())
		for i in range(skel.get_bone_count()):
			var bn: String = skel.get_bone_name(i).to_lower()
			for w in wanted:
				if bn.find(w) >= 0:
					bone_idx = i
					break
			if bone_idx >= 0:
				break
	if bone_idx < 0:
		return null
	for c in skel.get_children():
		if c is BoneAttachment3D and c.name == att_name:
			(c as BoneAttachment3D).bone_idx = bone_idx
			return c
	var ba := BoneAttachment3D.new()
	ba.name = att_name
	ba.bone_idx = bone_idx
	skel.add_child(ba)
	return ba

func _make_left_hand_attachment() -> BoneAttachment3D:
	return _make_bone_attachment("LeftHandShieldAttach",
		["LeftHand", "Left_Hand", "left_hand", "Hand_L", "HandL", "hand.L", "hand_l", "mixamorigLeftHand", "mixamorig:LeftHand"])

func _make_head_attachment() -> BoneAttachment3D:
	return _make_bone_attachment("HeadGearAttach",
		["Head", "head", "mixamorigHead", "mixamorig:Head", "head.001", "Bip01_Head"])

func _make_chest_back_attachment() -> BoneAttachment3D:
	return _make_bone_attachment("ChestBackAttach",
		["Spine2", "Spine1", "Spine", "spine", "spine.002", "spine.001", "mixamorigSpine2", "mixamorig:Spine2", "mixamorig:Spine1"])

func _make_hip_attachment() -> BoneAttachment3D:
	return _make_bone_attachment("HipAttach",
		["Hips", "hip", "Hip", "hips", "mixamorigHips", "mixamorig:Hips", "Bip01_Pelvis"])

# ── Slot rebuilders ──────────────────────────────────────────────────────
# Common pattern: free old visual, look up equipped item, find bone, prefer
# GLB asset, apply tier tint, parent under bone attachment with a tuned
# local origin/rotation. Each rebuilder no-ops cleanly if no GLB is shipped
# yet for that slot — empty hands/head/back is correct, NOT a procedural
# fallback (per assets/gear/README.md "Fallback behavior").

func _free_gear_slot(slot: String) -> void:
	var prev: Node = gear_visuals.get(slot)
	if prev != null and is_instance_valid(prev):
		prev.queue_free()
	gear_visuals.erase(slot)

func _rebuild_shield_visual() -> void:
	_free_gear_slot("left_hand")
	if inventory == null:
		return
	# Inventory currently uses a single "armor" slot; a future "shield" slot
	# will route here. For now, only equip a shield if Items.gd defines an
	# item with slot == "shield" AND it's equipped.
	var shield_id: String = ""
	if inventory.equipped.has("shield"):
		shield_id = inventory.equipped.get("shield", "")
	if shield_id == "":
		return
	var item: Dictionary = Items.get_item(shield_id)
	if item.is_empty():
		return
	var glb: Node3D = _try_load_gear_glb("left_hand", shield_id)
	if glb == null:
		return  # No procedural fallback for shields — wait for asset.
	var parent_node: Node = self
	var local_origin: Vector3 = Vector3(-0.45, 1.05, 0.05)
	var local_rot: Vector3 = Vector3(0, 0, deg_to_rad(-25))
	var att: BoneAttachment3D = _make_left_hand_attachment()
	if att != null:
		parent_node = att
		local_origin = Vector3(0.0, 0.04, 0.08)
		local_rot = Vector3(deg_to_rad(90), 0, 0)
	var holder := Node3D.new()
	holder.name = "ShieldVisual"
	holder.position = local_origin
	holder.rotation = local_rot
	parent_node.add_child(holder)
	holder.add_child(glb)
	_apply_tier_tint(glb, item.get("rarity", "common"))
	gear_visuals["left_hand"] = holder

func _rebuild_helmet_visual() -> void:
	_free_gear_slot("head")
	if inventory == null:
		return
	var helmet_id: String = ""
	if inventory.equipped.has("helmet"):
		helmet_id = inventory.equipped.get("helmet", "")
	if helmet_id == "":
		return
	var item: Dictionary = Items.get_item(helmet_id)
	if item.is_empty():
		return
	var glb: Node3D = _try_load_gear_glb("head", helmet_id)
	if glb == null:
		return
	var parent_node: Node = self
	var local_origin: Vector3 = Vector3(0, 1.75, 0)
	var local_rot: Vector3 = Vector3.ZERO
	var att: BoneAttachment3D = _make_head_attachment()
	if att != null:
		parent_node = att
		# Hat sits on top of skull bone; small forward offset for brim
		local_origin = Vector3(0, 0.10, 0.0)
		local_rot = Vector3.ZERO
	var holder := Node3D.new()
	holder.name = "HelmetVisual"
	holder.position = local_origin
	holder.rotation = local_rot
	parent_node.add_child(holder)
	holder.add_child(glb)
	_apply_tier_tint(glb, item.get("rarity", "common"))
	gear_visuals["head"] = holder

func _rebuild_cape_visual() -> void:
	_free_gear_slot("chest_back")
	if inventory == null:
		return
	var cape_id: String = ""
	if inventory.equipped.has("cape"):
		cape_id = inventory.equipped.get("cape", "")
	if cape_id == "":
		return
	var item: Dictionary = Items.get_item(cape_id)
	if item.is_empty():
		return
	var glb: Node3D = _try_load_gear_glb("chest_back", cape_id)
	if glb == null:
		return
	var parent_node: Node = self
	var local_origin: Vector3 = Vector3(0, 1.30, -0.18)
	var local_rot: Vector3 = Vector3.ZERO
	var att: BoneAttachment3D = _make_chest_back_attachment()
	if att != null:
		parent_node = att
		local_origin = Vector3(0, 0, -0.12)
		local_rot = Vector3.ZERO
	var holder := Node3D.new()
	holder.name = "CapeVisual"
	holder.position = local_origin
	holder.rotation = local_rot
	parent_node.add_child(holder)
	holder.add_child(glb)
	_apply_tier_tint(glb, item.get("rarity", "common"))
	gear_visuals["chest_back"] = holder


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

# Saber — single-edged curved blade. Visually distinct from a sword via
# (a) longer reach (0.85 vs 0.65), (b) thinner profile, and (c) three
# slightly-offset blade segments that fake a gentle curve. Used by
# frost_saber and any future "saber"-like weapon. Procedural stop-gap —
# replace with an authored GLB at assets/gear/right_hand/frost_saber.glb.
func _build_saber(blade_color: Color, glow: bool, glow_color: Color = Color(1, 1, 1)) -> void:
	# Hilt
	var hilt := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.038; hcm.bottom_radius = 0.038; hcm.height = 0.18
	hilt.mesh = hcm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.18, 0.10, 0.06)
	hm.roughness = 0.92
	hilt.material_override = hm
	weapon_visual.add_child(hilt)
	# Knuckle-guard (single curved bar — approximated as a tilted box)
	var guard := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(0.04, 0.18, 0.025)
	guard.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.85, 0.85, 0.90)
	gmat.metallic = 0.85
	gmat.roughness = 0.20
	guard.material_override = gmat
	guard.position = Vector3(0.05, 0.10, 0)
	guard.rotation = Vector3(0, 0, deg_to_rad(-25))
	weapon_visual.add_child(guard)
	# Blade — three stacked segments, each rotated a few degrees relative
	# to the previous, to fake a curved silhouette without a custom mesh.
	var seg_color := blade_color.lerp(Color(0.95, 0.98, 1.0), 0.15)
	for i in range(3):
		var seg := MeshInstance3D.new()
		var sm_box := BoxMesh.new()
		sm_box.size = Vector3(0.045, 0.30, 0.012)
		seg.mesh = sm_box
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = seg_color
		bmat.metallic = 0.90
		bmat.roughness = 0.12
		if glow:
			bmat.emission_enabled = true
			bmat.emission = glow_color
			bmat.emission_energy_multiplier = 0.9 + 0.1 * i
		seg.material_override = bmat
		# Stack along +Y, each slightly offset along +X to curve the blade.
		seg.position = Vector3(0.012 * i, 0.20 + 0.27 * i, 0)
		seg.rotation = Vector3(0, 0, deg_to_rad(-3.0 * i))
		weapon_visual.add_child(seg)
	# Pommel — small dome
	var pom := MeshInstance3D.new()
	var pcm := SphereMesh.new()
	pcm.radius = 0.045; pcm.height = 0.07
	pom.mesh = pcm
	pom.material_override = gmat
	pom.position.y = -0.11
	weapon_visual.add_child(pom)


# Greatsword — oversized 2H blade for legendary weapons. Visually 1.5×
# larger than a common sword, with an ornate dragon-scale crossguard
# (multiple stacked ridges) and dual-point fuller (two blade slabs side-
# by-side). Used by dragonfang. Stop-gap procedural — replace with a real
# authored asset at assets/gear/right_hand/dragonfang.glb.
func _build_greatsword(blade_color: Color, glow: bool, glow_color: Color = Color(1, 1, 1)) -> void:
	# Long wrapped hilt (two-hand grip)
	var hilt := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.045; hcm.bottom_radius = 0.05; hcm.height = 0.32
	hilt.mesh = hcm
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.25, 0.12, 0.08)
	hm.roughness = 0.88
	hilt.material_override = hm
	weapon_visual.add_child(hilt)
	# Ornate cross-guard — three stacked ridges of decreasing size for a
	# "dragon scale" silhouette (still procedural but more interesting
	# than a single bar).
	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.95, 0.78, 0.30)
	guard_mat.metallic = 0.85
	guard_mat.roughness = 0.22
	if glow:
		guard_mat.emission_enabled = true
		guard_mat.emission = Color(1.0, 0.55, 0.10)
		guard_mat.emission_energy_multiplier = 0.6
	for i in range(3):
		var ridge := MeshInstance3D.new()
		var rm := BoxMesh.new()
		var w: float = 0.32 - 0.06 * i
		rm.size = Vector3(w, 0.05, 0.05 + 0.01 * i)
		ridge.mesh = rm
		ridge.material_override = guard_mat
		ridge.position.y = 0.18 + 0.05 * i
		weapon_visual.add_child(ridge)
	# Dual-slab blade — two box meshes side by side with a 0.01 gap so it
	# reads as a fullered greatsword.
	for slab_i in range(2):
		var blade := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.95, 0.018)
		blade.mesh = bm
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = blade_color
		bmat.metallic = 0.92
		bmat.roughness = 0.10
		if glow:
			bmat.emission_enabled = true
			bmat.emission = glow_color
			bmat.emission_energy_multiplier = 1.1
		blade.material_override = bmat
		blade.position = Vector3(-0.03 + 0.06 * slab_i, 0.78, 0)
		weapon_visual.add_child(blade)
	# Pommel — large fang-shaped sphere
	var pom := MeshInstance3D.new()
	var pcm := SphereMesh.new()
	pcm.radius = 0.07; pcm.height = 0.11
	pom.mesh = pcm
	pom.material_override = guard_mat
	pom.position.y = -0.20
	weapon_visual.add_child(pom)

func _quick_use_potion() -> void:
	if not inventory: return
	for i in inventory.bag.size():
		var slot = inventory.bag[i]
		if slot.id.begins_with("hp_potion"):
			inventory.use_item(i, self)
			# Heal popup
			UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 2.6, 0), "+HEAL", Color(0.30, 0.95, 0.45), 36, 5)
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


# THEME §12 — locate the player's Skeleton3D (deep search) so the weapon
# visual can ride a real hand bone rather than a hard-coded body offset.
func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for c in node.get_children():
		var s := _find_first_skeleton(c)
		if s:
			return s
	return null


# Build (or reuse) a BoneAttachment3D parented under the player skeleton's
# right-hand bone. Returns null if the active GLB has no skeleton or no
# recognizable right-hand bone — caller should then fall back to the
# legacy body-relative weapon offset.
func _make_right_hand_bone_attachment() -> BoneAttachment3D:
	var skel: Skeleton3D = _find_first_skeleton(self)
	if skel == null:
		return null
	var bone_idx: int = -1
	# Owen.glb uses bare "RightHand"; Hero.glb (Mixamo) uses suffixed names
	# like "mixamorigRightHand_021"; Blender rigs use "hand.R" / "hand_r";
	# UE5/MetaHuman uses "Hand_R". Try them in priority order.
	var candidates: Array[String] = [
		"RightHand", "Right_Hand", "right_hand",
		"Hand_R", "HandR", "hand.R", "hand_r",
		"mixamorigRightHand", "mixamorig:RightHand"
	]
	for cand in candidates:
		bone_idx = skel.find_bone(cand)
		if bone_idx >= 0:
			break
	# Mixamo names get suffixed when imported (e.g. "_021"). Fuzzy match the
	# palm bone, excluding finger / thumb / index / pinky / middle / ring
	# bones so we don't end up attached to a fingertip.
	if bone_idx < 0:
		for i in range(skel.get_bone_count()):
			var bn: String = skel.get_bone_name(i).to_lower()
			if bn.find("righthand") >= 0:
				var exclude := ["index", "thumb", "pinky", "middle", "ring", "finger", "_end"]
				var skip := false
				for ex in exclude:
					if bn.find(ex) >= 0:
						skip = true; break
				if not skip:
					bone_idx = i; break
	if bone_idx < 0:
		return null
	# Reuse an existing attachment node if we made one earlier.
	for c in skel.get_children():
		if c is BoneAttachment3D and c.name == "RightHandSwordAttach":
			(c as BoneAttachment3D).bone_idx = bone_idx
			return c
	var ba := BoneAttachment3D.new()
	ba.name = "RightHandSwordAttach"
	ba.bone_idx = bone_idx
	skel.add_child(ba)
	return ba


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
	var data := _gather_save_data()
	data["ts"] = int(Time.get_unix_time_from_system())
	f.store_string(JSON.stringify(data, "	"))
	f.close()
	# KV cloud sync 2026-05-05: mirror to Cloudflare Worker so saves follow
	# the kid across devices. Fire-and-forget — local is source of truth.
	if OS.has_feature("web"):
		_kv_push_save(data)
	return true

func load_game() -> bool:
	# KV cloud sync 2026-05-05: try cloud first if web build (kid may be on a
	# device where they've never played before). Falls through to local on miss.
	if OS.has_feature("web"):
		_kv_pull_save()  # async; non-blocking. Fills in if newer than local.
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

# Cloudflare KV save sync — uses the per-kid char_choice as user key so
# Alden's save and Owen's save never overwrite each other. Fire-and-forget.
const KV_BASE := "https://eldoria-api.james-m-martinez.workers.dev"

func _kv_user_key() -> String:
	var id: String = "alden"
	if Engine.has_meta("char_choice"):
		id = str(Engine.get_meta("char_choice", "alden"))
	return id.to_lower().strip_edges()

func _kv_push_save(data: Dictionary) -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 5.0
	var body := JSON.stringify({
		"user": _kv_user_key(),
		"slot": "main",
		"data": data,
	})
	req.request(KV_BASE + "/api/save", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, body)
	# auto-cleanup after request finishes (fire-and-forget)
	req.request_completed.connect(func(_r,_c,_h,_b): req.queue_free())

func _kv_pull_save() -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 5.0
	req.request_completed.connect(func(_result, code, _headers, body):
		if code == 200:
			var parsed = JSON.parse_string(body.get_string_from_utf8())
			if parsed is Dictionary and parsed.get("ok", false) and parsed.has("data"):
				var cloud_data = parsed["data"]
				if cloud_data is Dictionary:
					# Only adopt cloud save if there's no local OR cloud is newer
					var adopt := true
					if FileAccess.file_exists(SAVE_PATH):
						var local_t := int(FileAccess.get_modified_time(SAVE_PATH))
						var cloud_t := int(cloud_data.get("ts", 0))
						adopt = cloud_t > local_t
					if adopt:
						var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
						if f:
							f.store_string(JSON.stringify(cloud_data, "\t"))
							f.close()
							_apply_save_data(cloud_data)
		req.queue_free())
	var url := KV_BASE + "/api/load?user=" + _kv_user_key().uri_encode() + "&slot=main"
	req.request(url)

# Title setter — called by World._apply_title_to_player when an
# achievement unlocks a higher-priority title. Empty string hides.
# Safe to call before _ready (no-op until title_label exists).
func set_title(t: String) -> void:
	if title_label == null:
		return
	title_label.text = t
	title_label.visible = (t != "")

func reset_save() -> void:
	# For "New Game" button later
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# THEME §13 ground contact / SIZE_STANDARDS — normalize the visible Hero subtree
# (the GLB instanced under the Player CharacterBody3D) so its AABB height is
# `target_height` meters and its bottom sits at body-local y=0. Two-pass:
# (1) uniform-scale to hit the height,
# (2) lift to plant the feet.
# Skip if the AABB is already within ±20% of target (the model was authored
# at a sane height — most likely a hand-tuned KayKit/Quaternius hero).

# Schedule a deferred re-run of _normalize_player_model after `delay` seconds.
# Multiple re-runs are CHEAP — the function is a no-op when AABB is already in
# tolerance — and they catch the case where Meshy biped GLBs finish loading
# their skin/anim data over several frames after instantiate.
func _schedule_normalize_retry(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(self):
		_normalize_player_model(1.1)

# Ground-snap raycast — fired every physics tick. If the visual character is
# floating above the collider (which happens after a Meshy GLB rescale lifts
# the mesh by `lift` to put feet at y=0), snap the body down so it sits on
# the floor instead of hovering. Belt-and-suspenders for the "I walk through
# terrain" report — the actual collision is what move_and_slide enforces;
# this is just a visual safety net.
func _snap_to_ground(max_drop: float = 4.0) -> void:
	var space := get_world_3d().direct_space_state
	var from_v := global_position + Vector3(0, 0.5, 0)
	var to_v := global_position - Vector3(0, max_drop, 0)
	var query := PhysicsRayQueryParameters3D.create(from_v, to_v)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var floor_y: float = float(hit.get("position", Vector3.ZERO).y)
	if global_position.y - floor_y > 0.6:
		global_position.y = floor_y + 0.05  # rest just above the floor


# Reads Engine meta "char_choice" set by CharacterSelect.gd. Maps choice id to
# a hero GLB path; if the file exists and isn't the current Hero subtree, swaps
# it. Falls back silently if the choice is missing or the GLB isn't loadable —
# the default Hero.glb already in Main.tscn keeps working.
func _apply_character_choice() -> void:
	if not Engine.has_meta("char_choice"):
		return
	var choice: String = str(Engine.get_meta("char_choice", "")).to_lower().strip_edges()
	var hero_paths := {
		"alden":  "res://assets/models/heroes/alden_pathfinder.glb",     # Sketchfab "Adventurer Boy" by monosapiens, CC-BY-4.0 (2.0 MiB, 1 anim, mixamorig:* rig)
		"owen":   "res://assets/models/heroes/owen_vanguard.glb",       # Sketchfab "Crimson Guardian" CC-BY (0.43 MiB, 5 anims)
	}
	var new_path: String = hero_paths.get(choice, "")
	if new_path == "" or not ResourceLoader.exists(new_path):
		return
	var packed: PackedScene = load(new_path) as PackedScene
	if packed == null:
		return
	var old_hero: Node = get_node_or_null("Hero")
	if old_hero:
		old_hero.queue_free()
	var new_hero: Node = packed.instantiate()
	new_hero.name = "Hero"
	add_child(new_hero)
	# _normalize_player_model + the deferred retries already running will dial
	# the new hero in to 1.8m on the next frame.

func _normalize_player_model(target_height: float) -> void:
	await get_tree().process_frame
	# Find the visible Hero node (any Node3D child of self with mesh content).
	# Falls back to scanning all children if the conventional name is missing.
	var hero: Node3D = get_node_or_null("Hero") as Node3D
	if hero == null:
		for c in get_children():
			if c is Node3D and not (c is CollisionShape3D) and c != camera_pivot:
				if (c as Node).find_children("*", "VisualInstance3D", true).size() > 0:
					hero = c
					break
	if hero == null:
		return
	# Pass 1: world-space AABB → uniform scale to target height.
	var aabb := AABB()
	var has := false
	for v in hero.find_children("*", "VisualInstance3D", true):
		var vi := v as VisualInstance3D
		if not vi: continue
		var a := vi.global_transform * vi.get_aabb()
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	# Skip the rescale if already in tolerance band — preserves authored-correct
	# models from being subtly resized.
	if aabb.size.y >= target_height * 0.90 and aabb.size.y <= target_height * 1.10:
		# Still run pass 2 to fix ground contact even if size is fine.
		pass
	else:
		# scale-eng 2026-05-05: floor 0.05 → 0.001 + iterative re-measure. Sketchfab/Meshy
		# GLBs in cm or mm units (100×–1000× off) hit the old 0.05 floor and
		# stranded at ~5% of source — i.e. a 120m hero at ~6m. Loop up to 6 times.
		var pass_n: int = 0
		while pass_n < 6 and aabb.size.y > 0.001 and (aabb.size.y < target_height * 0.90 or aabb.size.y > target_height * 1.10):
			var s: float = clamp(target_height / aabb.size.y, 0.001, 5.0)
			hero.scale = hero.scale * s
			await get_tree().process_frame
			if not is_instance_valid(hero): break
			aabb = AABB(); has = false
			for v_re in hero.find_children("*", "VisualInstance3D", true):
				var vi_re := v_re as VisualInstance3D
				if not vi_re: continue
				var a_re := vi_re.global_transform * vi_re.get_aabb()
				if not has: aabb = a_re; has = true
				else: aabb = aabb.merge(a_re)
			pass_n += 1
	# Pass 2: lift so visible bottom sits at body-local y=0 (THEME §13).
	if not is_instance_valid(hero):
		return
	var local_min_y: float = INF
	var local_has := false
	var inv_xform: Transform3D = hero.global_transform.affine_inverse()
	for v2 in hero.find_children("*", "VisualInstance3D", true):
		var vi2 := v2 as VisualInstance3D
		if not vi2: continue
		var a2 := (inv_xform * vi2.global_transform) * vi2.get_aabb()
		if not local_has:
			local_min_y = a2.position.y
			local_has = true
		else:
			local_min_y = min(local_min_y, a2.position.y)
	# scale-eng 2026-05-05: SYMMETRIC ground-snap. Was only LIFTING when model
	# bottom sat below pivot (local_min_y < -0.05). The current Hero.glb (run
	# d408a39, Meshy merge) has feet AT y=+4 in body-local frame — pivot at
	# crotch instead of feet — so the old branch never fired and the camera
	# (at body+1.6m) sat looking UP into the boots. Now: snap feet to body-local
	# y=0 in EITHER direction. Cap downward shift to -10m so a pathological
	# measurement can't yeet the model into the floor.
	if local_has and abs(local_min_y) > 0.05:
		var shift: float = clamp(-local_min_y, -10.0, 2.0)
		hero.position.y = hero.position.y + shift

# ────────────────────────────────────────────────────────────────────────
# Animation library merge — RIGGING_STANDARD §Required animations
# ────────────────────────────────────────────────────────────────────────
# Loads humanoid_base.tres and registers it under the "humanoid" key so
# anim_player.play("humanoid/<slot>") works regardless of source GLB.
# Subclasses (Pathfinder/Vanguard) can layer humanoid_pathfinder.tres or
# humanoid_vanguard.tres on top under the same key — keys collide, last
# write wins, so class flair overrides base where it exists.
func _merge_humanoid_library(ap: AnimationPlayer) -> void:
	if ap == null:
		return
	if not ResourceLoader.exists(HUMANOID_BASE_LIB):
		return  # not built yet — fallback path in _play_anim still works
	var lib := load(HUMANOID_BASE_LIB) as AnimationLibrary
	if lib == null:
		return
	if ap.has_animation_library("humanoid"):
		ap.remove_animation_library("humanoid")
	ap.add_animation_library("humanoid", lib)

# === SCALE GUARD 2026-05-06 (self-contained, defensive) ===
# Walks the player tree, finds any MeshInstance3D whose world-space height
# exceeds 1.5m, and shrinks its parent uniformly to fit. Catches the giant
# boot/helmet/cape bug where Equipment Visualizer attached gear at the
# natural-GLB scale while the body was normalized to 1.1m.
#
# Idempotent + self-contained: walk logic is inlined so partial overwrites
# by other agents can't break it. Safe to call repeatedly. Skips meshes
# with names starting with "Body" or "Hero" so we never shrink the player
# body itself.
func _clamp_all_attachments_scale() -> void:
	# 2026-05-06 v2: scope strictly to BoneAttachment3D descendants (gear).
	# Earlier name-based exemption (Body/Hero/Alpha) was unreliable — Meshy
	# GLBs name their mesh things like "Beta_Surface" or just "Mesh", so my
	# function shrunk the body mesh on every equipment_changed, eventually
	# making the player invisible. BoneAttachment3D is the canonical Godot
	# parent for equipment items (helmets, capes, shields, boots), so we
	# only walk those subtrees.
	var MAX_GEAR_M: float = 1.5
	var attachments: Array = []
	_collect_bone_attachments(self, attachments)
	for att in attachments:
		if not (att is Node3D): continue
		var att3: Node3D = att
		# Find the largest mesh under this BoneAttachment subtree
		var max_h: float = 0.0
		var stack: Array = [att3]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for child in n.get_children():
				stack.push_back(child)
				if child is MeshInstance3D:
					var mi: MeshInstance3D = child
					if mi.mesh == null: continue
					var aabb: AABB = mi.global_transform * mi.get_aabb()
					if aabb.size.y > max_h: max_h = aabb.size.y
		if max_h <= MAX_GEAR_M: continue
		var shrink: float = MAX_GEAR_M / max(max_h, 0.001)
		att3.scale = att3.scale * shrink

func _collect_bone_attachments(root: Node, out: Array) -> void:
	for child in root.get_children():
		if child is BoneAttachment3D:
			out.append(child)
		_collect_bone_attachments(child, out)

