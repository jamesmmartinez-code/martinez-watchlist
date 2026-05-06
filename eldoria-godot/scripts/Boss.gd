extends CharacterBody3D
class_name Boss

# Goblin Warlord — boss enemy in the deep Whisperwood. Three attack patterns:
#   1. Charge (telegraphed line attack — heavy damage, knockback)
#   2. AoE Slam (radial damage at his feet, wide ring)
#   3. Summon Adds (spawns 2 Goblin Scouts when at 50% HP and 25% HP)
# Boss HP bar pinned to the top-center of the screen while in combat.

@export var enemy_name: String = "Goblin Warlord"
@export var enemy_kind: String = "goblin_warlord"
@export var max_hp: int = 600
@export var damage: int = 22
@export var move_speed: float = 3.0
@export var chase_speed: float = 6.0
@export var aggro_range: float = 16.0
@export var attack_range: float = 2.6
@export var charge_distance: float = 12.0
@export var xp_reward: int = 600
@export var gold_reward: int = 250
@export var tint: Color = Color(0.30, 0.55, 0.20)
@export var enemy_model: PackedScene = preload("res://assets/models/Boss.glb")

var hp: int
var _state: String = "idle"
var _player: CharacterBody3D = null
var _gravity: float = 20.0
var _model: Node3D
var _label: Label3D
var _next_pattern_t: float = 0.0
var _spawn_pos: Vector3
var _phase: int = 0  # 0 = full, 1 = past 50%, 2 = past 25%
var _adds_spawned: Array = []
var _intro_watch: bool = false
var _intro_played: bool = false

const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")

func _ready() -> void:
	hp = max_hp
	_spawn_pos = global_position
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer = 4
	collision_mask = 1 | 4

	var cs := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.radius = 0.7; caps.height = 2.4
	cs.shape = caps
	cs.position.y = 1.4
	add_child(cs)

	# Visual model — bigger, glowing.
	# THEME §4 — Boss.glb is a hand-painted Mountain Ogre with its own painterly
	# textures. The legacy goblin-green modulate (0.5, 0.85, 0.30) muddied those
	# textures and made the boss read as plastic. The red BossAura OmniLight3D
	# below already supplies the warlord's threat color via lighting, which
	# preserves the model's original albedo. Tint removed.
	_model = enemy_model.instantiate()
	call_deferred("_normalize_to_height", _model, 3.0)  # boss ~3m, imposing
	_model.scale = Vector3(1.6, 1.6, 1.6)
	add_child(_model)
	# Auto-play idle animation if Boss.glb (or whatever PackedScene replaces it)
	# carries one. Boss.glb ships with 13 animations including an idle — without
	# this call the warlord stands T-posed before combat (banned by THEME §12).
	call_deferred("_play_model_idle_anim")

	# Crown
	var crown := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.30; cm.bottom_radius = 0.34; cm.height = 0.18
	crown.mesh = cm
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.85, 0.65, 0.20)
	crown_mat.metallic = 0.8
	crown_mat.roughness = 0.2
	crown_mat.emission_enabled = true
	crown_mat.emission = Color(1.0, 0.55, 0.10)
	crown_mat.emission_energy_multiplier = 0.5
	crown.material_override = crown_mat
	crown.position = Vector3(0, 3.1, 0)
	add_child(crown)

	# Floating name
	_label = Label3D.new()
	_label.text = "✦ %s ✦" % enemy_name
	_label.font_size = 30
	_label.outline_size = 6
	_label.outline_modulate = Color(0, 0, 0)
	_label.modulate = Color(1.0, 0.30, 0.20)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 3.6, 0)
	_label.no_depth_test = true
	add_child(_label)

	# Aura — glowing red/orange light
	var light := OmniLight3D.new()
	light.name = "BossAura"
	light.light_color = Color(1.0, 0.30, 0.10)
	# REFINE: combat — boss feel: aura energy 2.5→2.9, range 14.0→15.5 for cinematic presence on first-encounter (helps Alden read the threat early; Owen still gets the same fight).
	light.light_energy = 2.9
	light.omni_range = 15.5
	light.position.y = 1.8
	light.shadow_enabled = false
	add_child(light)

	# Watch for player approach to play boss intro sting
	_intro_watch = true

func _physics_process(delta: float) -> void:
	if _state == "dead":
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0

	if not _player:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
	if not _player:
		move_and_slide()
		return

	# Boss intro sting when player first comes within 30m
	if _intro_watch and not _intro_played:
		if _player.global_position.distance_to(global_position) < 30.0:
			_intro_played = true
			get_tree().call_group("world", "play_sfx", "boss_intro")
			_show_boss_msg("✦ %s appears! ✦" % enemy_name)
			# COMPOUND (run 10): mark `seen_warlord` so DialogueDB's `boss_alive`
			# JSON keys (Edda's "The Warlord rides a blade I'd recognize anywhere",
			# Bram's "Some folk who walked into the Whisperwood I still set a place
			# for at supper") fire when the player next visits Briarwood. Maeve also
			# has a `boss_alive` JSON line ("The Warlord is no chieftain. He is a
			# wound the Whisperwood is still bleeding from") that's been authored
			# but unreachable until this flag wire. Failsafe: if World ever lacks
			# `set_world_flag` (older save / partial scene), the call_group is a
			# no-op and dialogue silently falls through to mood/default tier.
			var w_intro: Node = get_tree().get_first_node_in_group("world")
			if w_intro and w_intro.has_method("set_world_flag"):
				w_intro.set_world_flag("seen_warlord", true)

	# Phase transitions
	var hp_ratio := float(hp) / float(max_hp)
	if _phase == 0 and hp_ratio < 0.5:
		_phase = 1
		_summon_adds(2)
		_show_boss_msg("RAAAGH! To me, my kin!")
	elif _phase == 1 and hp_ratio < 0.25:
		_phase = 2
		_summon_adds(2)
		_show_boss_msg("YOU WILL FALL!")

	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0
	var dist := to_player.length()

	_next_pattern_t -= delta

	if dist < attack_range:
		_state = "melee"
		velocity.x = 0; velocity.z = 0
		_face_target(to_player, delta)
		if _next_pattern_t <= 0:
			# Pick a random pattern
			var pick = randi() % 3
			if pick == 0:
				_attack_melee()
			elif pick == 1:
				_attack_slam()
			else:
				_attack_charge()
	elif dist < aggro_range:
		_state = "chase"
		var dir := to_player.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_target(to_player, delta)
		if _next_pattern_t <= 0 and dist < charge_distance:
			_attack_charge()

	move_and_slide()

func _face_target(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001: return
	var target_basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	# REFINE: combat — boss feel: slerp gain 6.0→7.5 so the Warlord visibly LOCKS ONTO the player a beat before each telegraph fires. Pairs with the existing slam (0.9s) and charge (0.78s) windups — Alden now reads "he's looking at me" as the FIRST telegraph, then the colored ring/line as the second. Two layered warnings, same total wind-up, no new mechanic added. THEME §12 MOTION — the rotation itself becomes expressive intent rather than ambient drift.
	global_transform.basis = global_transform.basis.slerp(target_basis, 7.5 * delta)

# ── Attack patterns ────────────────────────────────────────────────────────
func _attack_melee() -> void:
	_next_pattern_t = 1.4
	if _player and _player.has_method("take_damage"):
		_player.take_damage(damage)
		var d = (_player.global_position - global_position).normalized()
		# REFINE: combat — boss feel: melee knockback gains a small upward arc (UP * 2.0) so a Warlord swing visibly LIFTS the player off the ground a beat — matches slam's launch shape and THEME §12 MOTION (impact = visible reaction, not a flat slide). Horizontal nudged 5.0→5.5 to keep the arc trajectory's horizontal reach proportional. Slam still 8.0+UP*4.0, charge gets UP*3.5 below — three patterns now read as one kinetic family.
		_player.velocity += d * 5.5 + Vector3.UP * 2.0

func _attack_slam() -> void:
	_next_pattern_t = 3.5
	_show_boss_msg("⚒ SLAM!")
	# REFINE: combat — boss feel: slam telegraph dur 0.7→0.9 + matching await; gives Alden ~0.2s more reaction time without softening damage.
	_show_telegraph_ring(global_position, 5.0, 0.9)
	await get_tree().create_timer(0.9).timeout
	if _state == "dead": return
	# Hit anyone within 5m
	for p in get_tree().get_nodes_in_group("player"):
		if p.global_position.distance_to(global_position) < 5.0:
			if p.has_method("take_damage"):
				p.take_damage(int(damage * 1.4))
				var d = (p.global_position - global_position).normalized()
				p.velocity += d * 8.0 + Vector3.UP * 4.0

func _attack_charge() -> void:
	_next_pattern_t = 4.2
	_show_boss_msg("⚡ CHARGE!")
	# Telegraph: flash red line forward
	var start_pos := global_position
	var dir := (_player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	# REFINE: combat — boss feel: charge telegraph dur 0.6→0.78 + matching await; charge speed (18.0) preserved so Owen still feels the punch.
	_show_telegraph_line(start_pos, dir, charge_distance, 0.78)
	await get_tree().create_timer(0.78).timeout
	if _state == "dead": return
	# Charge — sprint forward, damaging anyone in path
	var t := 0.0
	while t < 0.7 and _state != "dead":
		velocity = dir * 18.0
		velocity.y = -2.0
		move_and_slide()
		# Damage player if hit
		for p in get_tree().get_nodes_in_group("player"):
			if p.global_position.distance_to(global_position) < 1.6:
				if p.has_method("take_damage"):
					p.take_damage(int(damage * 1.6))
					var pd = (p.global_position - global_position).normalized()
					# REFINE: combat — boss feel: charge contact now adds Vector3.UP * 3.5 (slam: UP*4.0, melee now: UP*2.0 — charge sits in between, matching its kinetic identity as a horizontal-dominant launcher). The Warlord rams you and you are visibly AIRBORNE for a beat before recovery — THEME §12 MOTION applies to the player too (impact = launch, not a flat skid). Horizontal pd*10.0 preserved so total damage-of-momentum only GROWS in the readable upward axis Owen interprets as cinematic mastery feedback.
					p.velocity += pd * 10.0 + Vector3.UP * 3.5
		await get_tree().create_timer(0.05).timeout
		t += 0.05

func _summon_adds(count: int) -> void:
	for i in count:
		var ang := (float(i) / float(count)) * TAU
		var pos := global_position + Vector3(cos(ang) * 4.0, 0, sin(ang) * 4.0)
		var add := CharacterBody3D.new()
		add.set_script(ENEMY_SCRIPT)
		add.position = pos + Vector3(0, 1.0, 0)
		add.enemy_kind = "goblin"
		add.enemy_name = "Warlord's Guard"
		add.max_hp = 32
		add.damage = 7
		add.xp_reward = 22
		add.gold_reward = 5
		add.tint = Color(0.45, 0.85, 0.30)
		add.move_speed = 3.0
		add.chase_speed = 5.5
		get_tree().current_scene.add_child(add)
		_adds_spawned.append(add)

# ── Visual telegraphs ──────────────────────────────────────────────────────
func _show_telegraph_ring(center: Vector3, radius: float, dur: float) -> void:
	# REFINE: combat — boss feel: ring alpha 0.55→0.72 and emission energy 1.6→2.6 so the danger zone reads instantly even in dappled forest light (helps Alden see and dodge).
	var ring := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 2.0)
	ring.mesh = pm
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(1.0, 0.20, 0.10, 0.72)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.30, 0.10)
	rm.emission_energy_multiplier = 2.6
	rm.no_depth_test = false
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm
	ring.position = center + Vector3(0, 0.05, 0)
	get_tree().current_scene.add_child(ring)
	var t = create_tween()
	t.tween_interval(dur)
	t.tween_callback(ring.queue_free)

func _show_telegraph_line(start: Vector3, dir: Vector3, length: float, dur: float) -> void:
	# REFINE: combat — boss feel: charge-line alpha 0.55→0.72, emission energy 1.6→2.6 so the lane to dodge out of is unmistakable (Alden) while Owen still has to actually move.
	var line := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.0, length)
	line.mesh = pm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(1.0, 0.20, 0.10, 0.72)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.30, 0.10)
	lm.emission_energy_multiplier = 2.6
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = lm
	line.position = start + dir * (length * 0.5) + Vector3(0, 0.05, 0)
	line.rotation.y = atan2(dir.x, dir.z)
	get_tree().current_scene.add_child(line)
	var t = create_tween()
	t.tween_interval(dur)
	t.tween_callback(line.queue_free)

func _show_boss_msg(text: String) -> void:
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(0, 4.4, 0), text, Color(1.0, 0.30, 0.10), 56, 7)
	# Also flash a screen toast
	get_tree().call_group("world", "_show_toast", text)

# ── Damage / death ─────────────────────────────────────────────────────────
func take_damage(amount: int, source: Node = null) -> void:
	if _state == "dead": return
	hp = max(0, hp - amount)
	get_tree().call_group("world", "update_boss_hp_bar", hp, max_hp, enemy_name)
	_spawn_damage_number(amount)
	if source and not _player:
		_player = source
	if hp <= 0:
		_die(source)

func _spawn_damage_number(amount: int) -> void:
	# REFINE: combat — boss feel: boss damage numbers font 44→50 + warmer/punchier modulate (1.0,0.65,0.30)→(1.0,0.74,0.32); reads as a meatier hit and gives Owen sharper mastery feedback.
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(randf_range(-0.3, 0.3), 2.6, randf_range(-0.3, 0.3)), str(amount), Color(1.0, 0.74, 0.32), 50, 7)

func _die(source: Node) -> void:
	_state = "dead"
	if _model: _model.visible = false
	if _label: _label.visible = false
	# Aura off
	var aura = get_node_or_null("BossAura")
	if aura: aura.visible = false
	# Big rewards
	if source and source.has_method("gain_xp"):
		source.gain_xp(xp_reward)
	if source and "gold" in source:
		source.gold += gold_reward
		if source.has_signal("stats_changed"):
			source.stats_changed.emit()
	# Roll boss loot — guaranteed multiple drops
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in 3:
		var drops = Items.roll_loot(enemy_kind, rng)
		for d in drops:
			if source and source.get("inventory"):
				source.inventory.add_item(d.id, d.qty)
				var item = Items.get_item(d.id)
				var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
				UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(randf_range(-1.5, 1.5), 2.2, randf_range(-1.5, 1.5)), "✦ %s%s" % [item.get("name", d.id), (" x%d" % d.qty) if d.qty > 1 else ""], color, 32, 5)
	# Hide boss bar
	get_tree().call_group("world", "hide_boss_hp_bar")
	get_tree().call_group("world", "_show_toast", "✦ %s slain! ✦" % enemy_name)
	# COMPOUND (run 10): write `warlord_dead` so DialogueDB's `boss_slain`
	# JSON keys (Maeve's "*long pause* — *Ai-velin*, traveler. The Whisperwood
	# will sleep tonight", Edda's "*long silence* — You unmade my mistake.
	# *one hard hammer-strike*", Bram's "*sets the mug down very carefully*
	# — Some debts get paid in iron, friend") become the next line each NPC
	# speaks. The flag also drives the achievements re-evaluation pass inside
	# `set_world_flag` so any future "Warlord Slain" achievement unlocks on
	# kill without an additional callsite. Permanent — never cleared, even on
	# player respawn (a slain boss stays slain). Same fail-soft contract as
	# `seen_warlord` above; older World autoloads degrade gracefully.
	var w_die: Node = get_tree().get_first_node_in_group("world")
	if w_die and w_die.has_method("set_world_flag"):
		w_die.set_world_flag("warlord_dead", true)
	# Quest hook
	get_tree().call_group("quest_listeners", "on_enemy_killed", "goblin_warlord")
	get_tree().call_group("quest_listeners", "on_enemy_killed", "goblin")  # also counts as a goblin for the basic quest

# Normalize 3D model scale so it ends up ~target_height tall.
# Prevents giants from Sketchfab GLBs with mixed units.
func _normalize_to_height(model: Node, target_height: float) -> void:
	await get_tree().process_frame
	var aabb := AABB()
	var has := false
	for c in model.find_children("*", "VisualInstance3D", true):
		var v := c as VisualInstance3D
		if not v: continue
		var a := v.get_aabb()
		a = v.global_transform * a
		if not has:
			aabb = a; has = true
		else:
			aabb = aabb.merge(a)
	if not has or aabb.size.y <= 0.001:
		return
	var s: float = clamp(target_height / aabb.size.y, 0.05, 5.0)
	model.scale = Vector3(s, s, s)


# THEME §12 — every visible character must be in motion. Walks the spawned
# model subtree for an AnimationPlayer and plays an idle animation if one
# exists. Boss.glb (Mountain Ogre) ships 13 anims; pick the first idle-shaped
# name we find, fall back to whatever's first.
func _play_model_idle_anim() -> void:
	# Boss.glb (Mountain Ogre) ships with 13 anims — best of any character — so
	# library merge is mostly belt-and-braces for future bosses sourced with
	# fewer clips. RIGGING_STANDARD §Required animations.
	if not is_instance_valid(_model):
		return
	var ap: AnimationPlayer = _find_animation_player(_model)
	if ap == null:
		return
	const HUMANOID_BASE_LIB := "res://assets/animations/humanoid_base.tres"
	if ResourceLoader.exists(HUMANOID_BASE_LIB):
		var _lib := load(HUMANOID_BASE_LIB) as AnimationLibrary
		if _lib != null:
			if ap.has_animation_library("humanoid"):
				ap.remove_animation_library("humanoid")
			ap.add_animation_library("humanoid", _lib)
	for n in ["IdleAnimation", "Idle", "idle", "ANIM_Idle", "Armature|Idle", "Idle_A", "idle_loop", "humanoid/idle"]:
		if ap.has_animation(n):
			ap.play(n)
			return
	var names := ap.get_animation_list()
	if names.size() > 0:
		ap.play(names[0])

func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var found := _find_animation_player(c)
		if found != null:
			return found
	return null
