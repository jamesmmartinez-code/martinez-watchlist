extends StaticBody3D
class_name Chest

# Realm of Eldoria — Treasure Chest.
# Procedurally built (no external GLB required). Approach within 2.5m and press
# E to open. Drops 2-4 items rolled from chest_common or chest_rare loot pool.
# Once opened, the lid stays raised and the chest cannot be opened again.

@export var loot_pool: String = "chest_common"   # "chest_common" | "chest_rare"
@export var item_count: int = 3                  # number of items to roll
# REFINE: visual — default glow_color (1.0, 0.85, 0.30) → (1.0, 0.86, 0.42).
# THEME §3 sunset-gold accent (#FFD86B family) — was a slightly muddy mustard.
# Affects common chests only; WorldBuilder overrides for rare (purple) and spot chests.
@export var glow_color: Color = Color(1.0, 0.86, 0.42)

var _opened: bool = false
var _lid: Node3D
var _glow_light: OmniLight3D
var _player_in_range: bool = false
var _player: Node = null


func _ready() -> void:
	add_to_group("chests")
	collision_layer = 1
	collision_mask = 0
	_build_visuals()
	_build_interact_area()

func _build_visuals() -> void:
	# Wooden body — box with slight bevel via two stacked boxes
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.8, 0.8)
	body.mesh = bm
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.26, 0.14)
	# REFINE: visual — wood roughness 0.85 → 0.92. THEME §1 painterly + §10 rule 9
	# (weathered/hand-made). Less specular sheen reads more hand-painted.
	wood.roughness = 0.92
	body.material_override = wood
	body.position = Vector3(0, 0.4, 0)
	add_child(body)

	# Iron banding (3 vertical strips)
	var iron := StandardMaterial3D.new()
	# REFINE: visual — iron banding warmed + weathered. albedo (0.30,0.27,0.25)→
	# (0.28,0.24,0.22), metallic 0.7→0.6, roughness 0.4→0.55. THEME §3 hammered
	# bronze adjacency + §10 rule 9 weathered hand-made; less mirror-shiny.
	iron.albedo_color = Color(0.28, 0.24, 0.22)
	iron.metallic = 0.6
	iron.roughness = 0.55
	for x in [-0.5, 0.0, 0.5]:
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.06, 0.82, 0.82)
		strip.mesh = sm
		strip.material_override = iron
		strip.position = Vector3(x, 0.4, 0)
		add_child(strip)

	# Lid (tilts up when opened)
	_lid = Node3D.new()
	_lid.name = "Lid"
	_lid.position = Vector3(0, 0.8, -0.4)
	add_child(_lid)
	var lid_mesh := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(1.22, 0.18, 0.85)
	lid_mesh.mesh = lm
	lid_mesh.material_override = wood
	lid_mesh.position = Vector3(0, 0.09, 0.4)
	_lid.add_child(lid_mesh)
	# Lock plate
	var lock := MeshInstance3D.new()
	var lkm := BoxMesh.new()
	lkm.size = Vector3(0.18, 0.20, 0.05)
	lock.mesh = lkm
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.25)
	gold_mat.metallic = 0.85; gold_mat.roughness = 0.25
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.7, 0.2)
	# REFINE: visual — lock plate emission_energy_multiplier 0.4 → 0.7.
	# THEME §3 hammered bronze; brass lock now reads warm-glowing at distance
	# instead of merely emissive. Alden's "ooh shiny" Collection beat.
	gold_mat.emission_energy_multiplier = 0.7
	lock.material_override = gold_mat
	lock.position = Vector3(0, 0.40, 0.43)
	add_child(lock)

	# Glow (subtle, until opened)
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = glow_color
	# REFINE: visual — resting glow light_energy 1.2 → 1.5 + omni_range 4.5 → 6.0.
	# Common chests now beacon visibly through Whisperwood foliage at camera
	# distance. Alden's Exploration affinity — clearer "go look at this" cue.
	_glow_light.light_energy = 1.5
	_glow_light.omni_range = 6.0
	_glow_light.position = Vector3(0, 0.7, 0)
	add_child(_glow_light)

	# Collision (so player can't walk through it)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 0.85, 0.85)
	col.shape = box
	col.position.y = 0.42
	add_child(col)


func _build_interact_area() -> void:
	var area := Area3D.new()
	area.name = "InteractArea"
	area.collision_layer = 0
	area.collision_mask = 2  # detect player layer
	add_child(area)
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.5
	col.shape = sph
	col.position.y = 0.5
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	# Floating "Press E to open" label, hidden until in range
	var label := Label3D.new()
	label.name = "Hint"
	label.text = "Press E to open"
	label.font_size = 24
	label.outline_size = 5
	label.outline_modulate = Color(0, 0, 0)
	label.modulate = glow_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 1.6, 0)
	label.visible = false
	add_child(label)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not _opened:
		_player_in_range = true
		_player = body
		var hint := get_node_or_null("Hint") as Label3D
		if hint: hint.visible = true
		# Connect E key
		if body.has_signal("interact_pressed") and not body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.connect(_on_interact)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		var hint := get_node_or_null("Hint") as Label3D
		if hint: hint.visible = false
		if body.has_signal("interact_pressed") and body.interact_pressed.is_connected(_on_interact):
			body.interact_pressed.disconnect(_on_interact)

func _on_interact() -> void:
	if _opened or not _player_in_range or _player == null:
		return
	_open_chest()


func _open_chest() -> void:
	_opened = true
	get_tree().call_group("world", "play_sfx", "chest_open")
	# Animate lid opening
	var t := create_tween()
	# REFINE: combat-feel — lid open tween 0.55 → 0.50s. Snappier reveal for Owen's
	# mastery loop; TRANS_BACK overshoot preserved (the satisfying part).
	t.tween_property(_lid, "rotation:x", -1.4, 0.50).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Burst of light
	var burst := OmniLight3D.new()
	burst.light_color = glow_color
	# REFINE: visual — open-burst light_energy 6.0 → 8.0, omni_range 8.0 → 11.0.
	# Bigger "treasure!" pulse — readable from across a chamber, so a co-op
	# partner across the room reads "they opened a chest!" without seeing the
	# chest itself. THEME §1 cooperative-play priority.
	burst.light_energy = 8.0
	burst.omni_range = 11.0
	burst.position = Vector3(0, 1.0, 0)
	add_child(burst)
	var t2 := create_tween()
	# REFINE: visual — burst fade 1.6 → 1.4s. Snappier resolve, ambient takes over.
	t2.tween_property(burst, "light_energy", 0.0, 1.4)
	t2.tween_callback(burst.queue_free)

	# Hide hint
	var hint := get_node_or_null("Hint") as Label3D
	if hint: hint.visible = false

	# Roll loot
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var rolls = Items.roll_chest_loot(loot_pool, rng, item_count)
	var world = get_tree().current_scene
	var inv = _player.get("inventory")
	if inv == null:
		return
	for r in rolls:
		# Affix-generated items carry their registry payload alongside the id
		if r.has("registry") and world and world.has_method("register_runtime_item"):
			world.register_runtime_item(r.registry)
		inv.add_item(r.id, r.qty)
		var item = Items.get_item(r.id)
		if item.is_empty() and world and world.has_method("get_runtime_item"):
			item = world.get_runtime_item(r.id)
		_spawn_loot_popup(item, r.qty)

	# Soft glow fades
	if _glow_light:
		var t3 := create_tween()
		# REFINE: visual — spent-glow fade light_energy 0.25 → 0.18, duration 1.2 → 1.5s.
		# "This chest is done" reads cleaner at lower energy; longer fade lets the
		# "you got it!" beat linger a beat before the chest resigns to spent state.
		t3.tween_property(_glow_light, "light_energy", 0.18, 1.5)

	# Toast
	if world and world.has_method("_show_toast"):
		world._show_toast("✨ Treasure!")

func _spawn_loot_popup(item: Dictionary, qty: int) -> void:
	if item.is_empty():
		return
	var color: Color = Items.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	UITheme.spawn_damage_popup(get_tree().current_scene, global_position + Vector3(randf_range(-0.5, 0.5), 1.6, randf_range(-0.3, 0.3)), "+ %s%s" % [item.get("name", "?"), (" x%d" % qty) if qty > 1 else ""], color, 30, 5)

# Subtle idle bob when not opened
func _process(delta: float) -> void:
	if _opened or _glow_light == null: return
	var t = Time.get_ticks_msec() / 1000.0
	# REFINE: visual — idle bob period sin(t*2.4) → sin(t*2.2) and amplitude
	# 0.25 → 0.32. THEME §12 motion-&-life: more visible "alive" pulse at
	# distance, period slightly lazier than character breathing (2.86s vs 2.5s).
	# Baseline lifted to 1.5 to match the new resting light_energy above.
	_glow_light.light_energy = 1.5 + sin(t * 2.2) * 0.32
