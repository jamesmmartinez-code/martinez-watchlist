extends CharacterBody3D
class_name Enemy

# Realm of Eldoria — Goblin / Wolf / Bandit enemy.
# Wanders idly until player enters aggro_range, then chases and melees.
# On death drops XP + gold, respawns after respawn_delay seconds.

@export var enemy_name: String = "Goblin Scout"
@export var enemy_kind: String = "goblin"   # "goblin" | "wolf" | "bandit"
@export var max_hp: int = 28
@export var damage: int = 6
@export var move_speed: float = 2.6
@export var chase_speed: float = 4.6
# REFINE: combat-feel — aggro pulled in from 9.0 → 8.0; kid-friendly for Alden, still tense in clusters.
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.6
# REFINE: combat-feel — longer recovery (1.2 → 1.45) so kids have a clean window to reposition between hits.
@export var attack_cooldown: float = 1.45
@export var xp_reward: int = 18
@export var gold_reward: int = 4
@export var respawn_delay: float = 35.0
@export var tint: Color = Color(0.45, 0.85, 0.30)
@export var enemy_model: PackedScene = preload("res://assets/models/RobotExpressive.glb")

var hp: int
var _state: String = "idle"  # idle | wander | chase | attack | dead
var _player: CharacterBody3D = null
var _attack_timer: float = 0.0
var _wander_timer: float = 0.0
var _wander_target: Vector3
var _spawn_pos: Vector3
var _gravity: float = 20.0
var _model: Node3D
var _hp_bar: Node3D
var _label: Label3D

const DAMAGE_NUMBER_SCRIPT = preload("res://scripts/DamageNumber.gd")

signal died(enemy)

func _ready() -> void:
	hp = max_hp
	_spawn_pos = global_position
	add_to_group("enemies")
	collision_layer = 4    # enemy layer
	collision_mask = 1 | 4 # collide with world (1) and other enemies (4)

	# Capsule collider
	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.40; caps.height = 1.6
	cs.shape = caps
	cs.position.y = 0.9
	add_child(cs)

	# Hit area for player attacks (a slightly larger area than the body)
	var hit_area := Area3D.new()
	hit_area.name = "HitArea"
	hit_area.collision_layer = 8
	hit_area.collision_mask = 0
	add_child(hit_area)
	var hac := CollisionShape3D.new()
	var hcaps := CapsuleShape3D.new()
	hcaps.radius = 0.55; hcaps.height = 1.8
	hac.shape = hcaps
	hac.position.y = 0.9
	hit_area.add_child(hac)

	# Visual model
	_spawn_model()

	# Floating name label
	_label = Label3D.new()
	_label.text = enemy_name
	_label.font_size = 22
	_label.outline_size = 4
	_label.outline_modulate = Color(0, 0, 0)
	_label.modulate = Color(1.0, 0.55, 0.45) if enemy_kind == "goblin" else Color(0.85, 0.85, 1.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.1, 0)
	_label.no_depth_test = true
	add_child(_label)

	# Floating HP bar (a billboard plane that scales)
	_hp_bar = _make_hp_bar()
	add_child(_hp_bar)

	_pick_wander_target()

func _spawn_model() -> void:
	if _model:
		_model.queue_free()
	_model = enemy_model.instantiate()
	# Scale by kind
	match enemy_kind:
		"goblin":
			_model.scale = Vector3(0.85, 0.85, 0.85)
		"wolf":
			_model.scale = Vector3(0.70, 0.70, 1.05)
			_model.rotation.x = -PI / 2  # quadruped
		"bandit":
			_model.scale = Vector3(1.05, 1.05, 1.05)
		"skeleton":
			_model.scale = Vector3(1.00, 1.05, 1.00)
		"crystal_elemental":
			_model.scale = Vector3(1.10, 1.20, 1.10)
		"crystal_guardian":
			_model.scale = Vector3(1.55, 1.65, 1.55)
		_:
			_model.scale = Vector3(1.0, 1.0, 1.0)
	add_child(_model)
	_model.call_deferred("propagate_call", "set", ["modulate", tint])

func _make_hp_bar() -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(0, 2.4, 0)
	# Background (red)
	var bg := MeshInstance3D.new()
	var bgm := StandardMaterial3D.new()
	bgm.albedo_color = Color(0.5, 0.06, 0.06)
	bgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bgm.no_depth_test = true
	bgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qm := QuadMesh.new()
	qm.size = Vector2(1.4, 0.14)
	bg.mesh = qm
	bg.material_override = bgm
	root.add_child(bg)
	# Foreground (green)
	var fg := MeshInstance3D.new()
	var fgm := StandardMaterial3D.new()
	fgm.albedo_color = Color(0.30, 0.85, 0.35)
	fgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fgm.no_depth_test = true
	fgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var qmf := QuadMesh.new()
	qmf.size = Vector2(1.36, 0.10)
	fg.mesh = qmf
	fg.material_override = fgm
	fg.name = "HPFill"
	fg.position.z = 0.001
	root.add_child(fg)
	return root

func _update_hp_bar() -> void:
	if not _hp_bar: return
	var fill := _hp_bar.get_node_or_null("HPFill")
	if not fill: return
	var ratio := float(hp) / float(max_hp)
	fill.scale.x = max(0.001, ratio)
	# Hide HP bar at full HP for cleaner look
	_hp_bar.visible = (hp < max_hp and hp > 0)

func _physics_process(delta: float) -> void:
	if _state == "dead":
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

	# Find player
	if not _player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
		else:
			# Fallback: search for the Player node
			_player = get_tree().current_scene.get_node_or_null("Player")
	if not _player:
		_idle_drift(delta)
		move_and_slide()
		return

	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()

	_attack_timer = max(0.0, _attack_timer - delta)

	if dist < attack_range:
		_state = "attack"
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _attack_timer <= 0:
			_do_attack()
	elif dist < aggro_range:
		_state = "chase"
		var dir := to_player.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_target(to_player, delta)
	else:
		_idle_drift(delta)

	move_and_slide()

func _face_target(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001:
		return
	var target_basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	global_transform.basis = global_transform.basis.slerp(target_basis, 8.0 * delta)

func _idle_drift(delta: float) -> void:
	_state = "wander"
	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_wander_target()
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0
	if to_target.length() < 0.5:
		velocity.x = 0; velocity.z = 0
		return
	var dir := to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face_target(to_target, delta)

func _pick_wander_target() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var ang := rng.randf() * TAU
	var dist := rng.randf_range(2.0, 7.0)
	_wander_target = _spawn_pos + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
	_wander_timer = rng.randf_range(2.0, 5.0)

func _do_attack() -> void:
	_attack_timer = attack_cooldown
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)
		# REFINE: combat-feel — heavier knockback (3.0 → 4.5) for a more readable "hit" beat. Adds breathing space too.
		var dir := (_player.global_position - global_position).normalized()
		_player.velocity += dir * 4.5

# ──────────────────────────────────────────────────────────────────────────
# Take damage from player
# ──────────────────────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead":
		return
	hp = max(0, hp - amount)
	_update_hp_bar()
	_spawn_damage_number(amount, false)
	# Aggro the attacker if not already chasing
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var dn := Label3D.new()
	dn.set_script(DAMAGE_NUMBER_SCRIPT)
	dn.text = ("%d!" % amount) if is_crit else str(amount)
	# REFINE: combat-feel — chunkier font + warmer crit gold + brighter normal hit so damage reads at a glance.
	dn.font_size = 62 if is_crit else 44
	dn.outline_size = 7
	dn.outline_modulate = Color(0, 0, 0)
	dn.modulate = Color(1.0, 0.88, 0.22) if is_crit else Color(1.0, 0.72, 0.32)
	dn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dn.no_depth_test = true
	dn.position = global_position + Vector3(randf_range(-0.3, 0.3), 1.8, randf_range(-0.3, 0.3))
	get_tree().current_scene.add_child(dn)

func _die(source: Node) -> void:
	_state = "dead"
	get_tree().call_group("world", "play_sfx", "enemy_death")
	# Hide model + bars
	if _model: _model.visible = false
	if _hp_bar: _hp_bar.visible = false
	if _label: _label.visible = false
	# Drop loot — XP/gold to player
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	# Roll item loot from drop table — equipment may roll affix variants
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var drops = Items.roll_loot(enemy_kind, rng)
	var world = get_tree().current_scene
	for d in drops:
		if source and source.get("inventory"):
			# 35% chance equipment becomes an affix variant for richer loot
			var base = Items.get_item(d.id)
			if base.has("slot") and base.slot != "" and rng.randf() < 0.35:
				var affix = Items.generate_affix_item(d.id, rng)
				if not affix.is_empty():
					if world and world.has_method("register_runtime_item"):
						world.register_runtime_item(affix)
					source.inventory.add_item(affix.runtime_id, 1)
					_spawn_loot_popup(affix, 1)
					continue
			source.inventory.add_item(d.id, d.qty)
			get_tree().call_group("world", "play_sfx", "loot_pickup")
			var item = Items.get_item(d.id)
			_spawn_loot_popup(item, d.qty)
	# Floating "+XP" popup
	var xp_pop := Label3D.new()
	xp_pop.set_script(DAMAGE_NUMBER_SCRIPT)
	xp_pop.text = "+%d XP" % xp_reward
	xp_pop.font_size = 36
	xp_pop.outline_size = 5
	xp_pop.outline_modulate = Color(0, 0, 0)
	xp_pop.modulate = Color(0.55, 0.95, 0.45)
	xp_pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	xp_pop.no_depth_test = true
	xp_pop.position = global_position + Vector3(0, 2.0, 0)
	get_tree().current_scene.add_child(xp_pop)
	died.emit(self)
	# Notify quest system
	get_tree().call_group("quest_listeners", "on_enemy_killed", enemy_kind)
	# Schedule respawn
	await get_tree().create_timer(respawn_delay).timeout
	_respawn()

func _respawn() -> void:
	hp = max_hp
	global_position = _spawn_pos
	if _model: _model.visible = true
	if _label: _label.visible = true
	_state = "idle"
	_player = null
	_update_hp_bar()

func _spawn_loot_popup(item: Dictionary, qty: int) -> void:
	if item.is_empty():
		return
	var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	var pop := Label3D.new()
	pop.set_script(DAMAGE_NUMBER_SCRIPT)
	pop.text = "+ %s%s" % [item.get("name", "?"), (" x%d" % qty) if qty > 1 else ""]
	pop.font_size = 28
	pop.outline_size = 5
	pop.outline_modulate = Color(0, 0, 0)
	pop.modulate = color
	pop.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pop.no_depth_test = true
	pop.position = global_position + Vector3(0, 2.4, 0)
	get_tree().current_scene.add_child(pop)
