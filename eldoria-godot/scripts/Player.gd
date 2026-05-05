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

var gravity: float = 20.0
var current_speed: float
var is_attacking: bool = false
var is_dead: bool = false

# Stats
var hp: int = 120
var max_hp: int = 120
var mp: int = 30
var max_mp: int = 30
var xp: int = 0
var level: int = 1
var gold: int = 50

# Combat parameters
@export var attack_range: float = 2.6
@export var attack_arc_deg: float = 110.0
@export var attack_damage_base: int = 14
@export var crit_chance: float = 0.12
@export var crit_multiplier: float = 2.0

# Inventory + equipment (managed by Inventory child node)
var inventory: Node = null

# Quest tracking
var kills_by_kind: Dictionary = {}   # e.g. {"goblin": 3}
var active_quest: Dictionary = {}    # {"target":"goblin", "needed":5, "killed":0, "giver":"Maeve"}

# Mounted state
var mounted: bool = false
var mount_node: Node3D = null

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")
const INVENTORY_SCRIPT    = preload("res://scripts/Inventory.gd")

# Visible weapon attached to the player's body (re-built when equipment changes)
var weapon_visual: Node3D = null

# Procedural fantasy gear (helm, cape, pauldrons, tabard, belt) bolted onto
# the Vanguard body to make it read as a fantasy hero rather than a soldier.
var fantasy_gear: Node3D = null

signal stats_changed
signal interact_pressed

func _ready() -> void:
	current_speed = walk_speed
	add_to_group("player")
	add_to_group("quest_listeners")
	collision_layer = 2  # player layer
	collision_mask = 1 | 4  # collide with world (1) and enemies (4)
	# Auto-wire camera_pivot if the editor didn't assign it
	if not camera_pivot:
		var root := get_tree().current_scene
		if root:
			camera_pivot = root.get_node_or_null("CameraPivot")
	# Auto-wire animation_player to the imported Soldier model's AnimationPlayer
	if not animation_player:
		var soldier := get_node_or_null("Soldier")
		if soldier:
			animation_player = soldier.get_node_or_null("AnimationPlayer")
	# Inventory
	inventory = Node.new()
	inventory.set_script(INVENTORY_SCRIPT)
	inventory.name = "Inventory"
	add_child(inventory)
	inventory.equipment_changed.connect(_on_equipment_changed)
	inventory.inventory_changed.connect(_on_inventory_changed)
	# Build initial visible weapon
	call_deferred("_rebuild_weapon_visual")
	call_deferred("_apply_fantasy_makeover")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Camera-relative input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_pivot.global_transform.basis if camera_pivot else Basis.IDENTITY
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0

	# Run modifier (left shift)
	current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

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
		elif k == KEY_Q:
			# Quaff health potion (the first hp_potion_s/l in bag)
			_quick_use_potion()
		elif k == KEY_M:
			# Mount/dismount toggle
			get_tree().call_group("world", "toggle_mount")

func _attack() -> void:
	if is_attacking or is_dead:
		return
	is_attacking = true
	_play_anim("attack")
	get_tree().call_group("world", "play_sfx", "sword_swing")

	# Hit window — small delay to match the swing
	await get_tree().create_timer(0.18).timeout

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
	await get_tree().create_timer(0.32).timeout
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
	var candidates := {
		"idle":   ["Idle", "idle", "ANIM_idle"],
		"walk":   ["Walk", "walk", "Walking", "ANIM_walk"],
		"run":    ["Run", "run", "Running", "ANIM_run"],
		"attack": ["Attack", "Punch", "Slash"],
		"die":    ["Death", "Die", "ANIM_death"],
	}
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
	var dn := Label3D.new()
	dn.set_script(DAMAGE_NUMBER_SCRIPT)
	dn.text = "-%d" % actual
	dn.font_size = 32
	dn.outline_size = 5
	dn.outline_modulate = Color(0, 0, 0)
	dn.modulate = Color(1.0, 0.30, 0.30)
	dn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dn.no_depth_test = true
	dn.position = global_position + Vector3(0, 2.4, 0)
	get_tree().current_scene.add_child(dn)
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	_play_anim("die")
	get_tree().call_group("world", "play_sfx", "player_death")
	# Death overlay
	get_tree().call_group("world", "show_death_overlay")
	await get_tree().create_timer(2.5).timeout
	_respawn_at_well()

func _respawn_at_well() -> void:
	# Well is at (0, 0, 6) per WorldBuilder
	global_position = Vector3(0, 1.0, 6.5)
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
	if weapon_visual and is_instance_valid(weapon_visual):
		weapon_visual.queue_free()
	if not inventory:
		return
	var weapon_id = inventory.equipped_weapon_id()
	if weapon_id == "":
		return
	var item := Items.get_item(weapon_id)
	if item.is_empty():
		return

	weapon_visual = Node3D.new()
	weapon_visual.name = "WeaponVisual"
	# Position near the right hand of the soldier model
	weapon_visual.position = Vector3(0.45, 1.05, 0.1)
	weapon_visual.rotation = Vector3(0, 0, deg_to_rad(35))
	add_child(weapon_visual)

	var color: Color = item.get("color", Color(0.85, 0.85, 0.85))
	var glow: bool = item.rarity in ["epic", "legendary"]

	# Build a sword-like or axe-like or dagger-like shape based on icon
	var icon: String = item.get("icon", "⚔")
	if icon == "🪓":
		_build_axe(color, glow)
	elif icon == "🗡":
		_build_dagger(color, glow)
	elif icon == "❄":
		_build_sword(color, glow, Color(0.6, 0.85, 1.0))
	elif icon == "🐉":
		_build_sword(color, true, Color(1.0, 0.55, 0.10))
	else:
		_build_sword(color, glow)

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


# ────────────────────────────────────────────────────────────────────────
# Fantasy hero makeover — Soldier.glb is the Mixamo Vanguard (body mesh
# `vanguard_Mesh` + sci-fi visor `vanguard_visor`). We hide the visor and
# any rifle/gun-named meshes, then bolt on procedural fantasy gear so the
# player reads as a knight/adventurer rather than a soldier.
# Gear is parented to the Player root (not animated bones), so it stays
# rigid in player-space — fine for torso/head pieces; we deliberately
# avoid arm/leg gear that would pop during walk animations.
# ────────────────────────────────────────────────────────────────────────
func _apply_fantasy_makeover() -> void:
	var soldier := get_node_or_null("Soldier")
	if soldier:
		_hide_modern_bits(soldier)
	_build_fantasy_gear()

func _hide_modern_bits(node: Node) -> void:
	var lname: String = String(node.name).to_lower()
	var hide_words: Array[String] = ["visor", "rifle", "gun", "barrel", "magazine", "scope", "muzzle", "ammo", "bullet", "pistol", "trigger"]
	if node is MeshInstance3D:
		for w: String in hide_words:
			if w in lname:
				node.visible = false
				break
	for child in node.get_children():
		_hide_modern_bits(child)

func _build_fantasy_gear() -> void:
	if fantasy_gear and is_instance_valid(fantasy_gear):
		return
	fantasy_gear = Node3D.new()
	fantasy_gear.name = "FantasyGear"
	add_child(fantasy_gear)

	# Materials
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.78, 0.55, 0.18)
	bronze.metallic = 0.85
	bronze.roughness = 0.30

	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.82, 0.30)
	gold.metallic = 0.95
	gold.roughness = 0.20
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.7, 0.20)
	gold.emission_energy_multiplier = 0.18

	var crimson := StandardMaterial3D.new()
	crimson.albedo_color = Color(0.55, 0.10, 0.12)
	crimson.roughness = 0.85
	crimson.metallic = 0.05

	var dark_leather := StandardMaterial3D.new()
	dark_leather.albedo_color = Color(0.18, 0.12, 0.08)
	dark_leather.roughness = 0.95

	# Helmet cap that covers head & visor
	var helm := MeshInstance3D.new()
	var hcyl := CylinderMesh.new()
	hcyl.top_radius = 0.16
	hcyl.bottom_radius = 0.21
	hcyl.height = 0.24
	helm.mesh = hcyl
	helm.material_override = bronze
	helm.position = Vector3(0, 1.78, 0)
	fantasy_gear.add_child(helm)

	# Crown spikes around the helm rim — 5 gold prisms ringing the head
	for i in 5:
		var spike := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.05, 0.13, 0.05)
		spike.mesh = pm
		spike.material_override = gold
		var ang: float = TAU * (float(i) / 5.0) - PI / 2.0
		spike.position = Vector3(cos(ang) * 0.17, 1.95, sin(ang) * 0.17)
		fantasy_gear.add_child(spike)

	# Forehead band — thin gold ring around the helm
	var band := MeshInstance3D.new()
	var btm := CylinderMesh.new()
	btm.top_radius = 0.215
	btm.bottom_radius = 0.215
	btm.height = 0.04
	band.mesh = btm
	band.material_override = gold
	band.position = Vector3(0, 1.69, 0)
	fantasy_gear.add_child(band)

	# Cape — hangs behind the player (player faces -Z, so back is +Z)
	var cape := MeshInstance3D.new()
	var cape_mesh := BoxMesh.new()
	cape_mesh.size = Vector3(0.60, 1.05, 0.04)
	cape.mesh = cape_mesh
	cape.material_override = crimson
	cape.position = Vector3(0, 1.18, 0.22)
	cape.rotation = Vector3(deg_to_rad(8), 0, 0)
	fantasy_gear.add_child(cape)

	# Cape collar (gold trim) at the top of the cape
	var collar := MeshInstance3D.new()
	var collar_mesh := BoxMesh.new()
	collar_mesh.size = Vector3(0.60, 0.08, 0.06)
	collar.mesh = collar_mesh
	collar.material_override = gold
	collar.position = Vector3(0, 1.66, 0.22)
	fantasy_gear.add_child(collar)

	# Pauldrons — bronze hemispheres on the shoulders, with gold studs
	var sides: Array[float] = [-0.28, 0.28]
	for sx in sides:
		var p := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.14
		sm.height = 0.22
		p.mesh = sm
		p.material_override = bronze
		p.position = Vector3(sx, 1.55, 0)
		fantasy_gear.add_child(p)
		var stud := MeshInstance3D.new()
		var studm := SphereMesh.new()
		studm.radius = 0.04
		studm.height = 0.06
		stud.mesh = studm
		stud.material_override = gold
		stud.position = Vector3(sx, 1.65, 0)
		fantasy_gear.add_child(stud)

	# Tabard front (chest panel) — front is -Z
	var tabard := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.34, 0.72, 0.03)
	tabard.mesh = tm
	tabard.material_override = crimson
	tabard.position = Vector3(0, 1.05, -0.19)
	fantasy_gear.add_child(tabard)

	# Tabard emblem — gold star/diamond on chest
	var emblem := MeshInstance3D.new()
	var em := PrismMesh.new()
	em.size = Vector3(0.18, 0.18, 0.03)
	emblem.mesh = em
	emblem.material_override = gold
	emblem.position = Vector3(0, 1.20, -0.21)
	fantasy_gear.add_child(emblem)

	# Belt — dark leather ring around waist
	var belt := MeshInstance3D.new()
	var blt := BoxMesh.new()
	blt.size = Vector3(0.58, 0.10, 0.44)
	belt.mesh = blt
	belt.material_override = dark_leather
	belt.position = Vector3(0, 0.85, 0)
	fantasy_gear.add_child(belt)

	# Belt buckle — gold square on front
	var buckle := MeshInstance3D.new()
	var bkm := BoxMesh.new()
	bkm.size = Vector3(0.11, 0.08, 0.05)
	buckle.mesh = bkm
	buckle.material_override = gold
	buckle.position = Vector3(0, 0.85, -0.21)
	fantasy_gear.add_child(buckle)
